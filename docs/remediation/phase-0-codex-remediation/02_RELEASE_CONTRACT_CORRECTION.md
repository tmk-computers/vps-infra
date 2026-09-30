# RELEASE SAFETY CONTRACT CORRECTION (C0-01 RESOLUTION)

**Document ID**: `REMED-P0-CDX-02`  
**Phase**: Phase 0 — Codex Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C0-01`)  
**Status**: COMPLETE ARCHITECTURAL SPECIFICATION  

---

## 1. Context & Problem Statement

The Codex Phase 0 Audit Gate flagged finding `C0-01` as an **Acceptance Blocker (C0)**. The audited baseline suffered from critical safety defects in its release contract:
1. **Premature Success**: The state machine permitted marking a release as `SUCCEEDED` before traffic cutover and post-cutover verification were completed.
2. **Missing Concurrency & Idempotency Guards**: No deployment request idempotency key, single-host per-service atomic lock, or stale-worker fencing was defined.
3. **Dangerous Database Rollback Promises**: Rollback promised automatic restoration of a pre-deploy database snapshot upon application failure, risking catastrophic data loss of post-snapshot database writes.
4. **Ambiguous Recovery & Reconciliation**: Startup reconciliation promoted healthy containers to `SUCCEEDED` without state-specific rules; crashes during intermediate states left the system in an undefined state.
5. **Overstated Promises**: Unconditional claims of "zero-downtime rollback" and "outage prevented" were asserted without qualification.

This document establishes the corrected, authoritative release safety contract that governs both the Linux Adapter (Docker / Traefik) and the Windows Adapter (IIS 10 / HTTP.sys).

---

## 2. Definitive Release State Machine

The release lifecycle is modeled as a strictly ordered, durable state machine. Every state transition is written to durable storage (PostgreSQL `DeploymentRecord` table) **before** executing physical side effects.

```
                      +-------------------+
                      |      PENDING      |
                      +---------+---------+
                                | (Validate request & acquire per-service lock)
                                v
                      +-------------------+
              +------>|     PRECHECK      |-------+
              |       +---------+---------+       |
(Lock/Precheck|                 |                 | (Precheck fails:
 Failed)      |                 v                 |  no mutations occurred)
              |       +-------------------+       |
              |       |     PREPARED      |       |
              |       +---------+---------+       |
              |                 |                 |
              |                 v                 |
              |       +-------------------+       |
              |       |     APPLYING      |       |
              |       +---------+---------+       |
              |                 |                 |
              |                 v                 |
              |       +-------------------+       |
              |       |     VERIFYING     |---+   |
              |       +---------+---------+   |   |
              |                 |             |   |
              |                 v             |   |
              |       +-------------------+   |   |
              |       |      CUTOVER      |---+   |
              |       +---------+---------+   |   |
              |                 |             |   |
              |                 v             |   |
              |       +-------------------+   |   |
              |       |POST_CUTOVER_VERIFY|---+   |
              |       +---------+---------+   |   |
              |                 |             |   |
              |                 v             |   |
              |       +-------------------+   |   |
              |       |     SUCCEEDED     |   |   |
              |       +-------------------+   |   |
              |                               |   |
              |        (Deployment Failure)   |   |
              |                               v   v
              |       +-------------------+ +---+---+
              |       |     ROLLBACK      | |FAILED | (Terminal: No side effects)
              |       +---------+---------+ +-------+
              |                 |
              |                 +--------------------+
              |                 |                    |
              |                 v                    v
              |       +-------------------+ +-------------------+
              |       |    ROLLED_BACK    | | RECOVERY_REQUIRED |
              |       +-------------------+ +-------------------+
```

### 2.1 Authoritative State Transition Table

| State | Durable Write Trigger | Physical Action Performed | Idempotent? | Crash / Reboot Recovery Action |
|---|---|---|---|---|
| **`PENDING`** | Deployment request received with `IdempotencyKey`. | Record inserted into database; caller acknowledged. | Yes | If orphaned in `PENDING`, worker cleans up or cancels on startup. |
| **`PRECHECK`** | Service mutex acquired; preflight started. | Acquire per-service atomic lock; verify disk space ($\ge 5\text{ GB}$), port availability, schema version, and artifact checksums. | Yes | Lock has heartbeats and a 15-minute TTL. On reboot/crash, lock is freed; state transitions to `FAILED` (no physical side effects were initiated). |
| **`PREPARED`** | Preflight passed; artifact digest verified. | Image pulled (Linux) or application package extracted to staging directory (Windows). DB schema migration preflight executed. | Yes | Re-verifies digest. Staging directories are overwritten idempotently. Safe to re-run or abort to `FAILED`. |
| **`APPLYING`** | Preparation verified; container/service creation started. | **Linux**: New container spawned on internal bridge with temporary name (`service_next`), unbound from public ports.<br>**Windows**: New IIS Application Pool / staging site configured on private loopback port. | Yes | Service controller inspects runtime state. If staging container/site exists, verify or destroy staging instance. Previous live release is completely untouched. |
| **`VERIFYING`** | Staging instance started. | Internal health probes polled (`GET http://staging-endpoint/health`) across required observation window (3 consecutive successes at 5s intervals). Dependency readiness verified. | Yes | Resume polling or restart staging instance. If health probes fail within timeout (60s), transition to `ROLLBACK` (or directly destroy staging instance). |
| **`CUTOVER`** | Internal verification passed. | **Linux**: Traefik dynamic routing configuration updated to route live traffic to new container.<br>**Windows**: IIS binding / URL Rewrite rule switched to repoint incoming traffic to new app pool. | Yes | State persistence indicates cutover was attempted. Controller probes public routing. If traffic routes to old instance, retry cutover; if broken, transition to `ROLLBACK`. |
| **`POST_CUTOVER_VERIFY`** | Routing switch executed. | External public health check executed via public domain name/IP. 30-second stability observation window monitored for error rate spikes (5xx > 1%). | Yes | If external probes succeed, advance to `SUCCEEDED`. If external probes fail, initiate immediate automated `ROLLBACK`. |
| **`SUCCEEDED`** | External verification and stability window passed. | **Terminal State**. Previous container/staging files decommissioned (or kept in standby cache for N-1 rollback cache). Release lock released. Release marked authoritative in DB. | Yes | Terminal. On reboot, service starts as authoritative production instance. |
| **`FAILED`** | Precheck or Preparation failure before any mutation. | **Terminal State**. Lock released. Staging scratch files removed. No live service was touched. | Yes | Terminal. Zero recovery needed. |
| **`ROLLBACK`** | Verification or Cutover failure. | Revert traffic routing to previous known-good release (which was maintained active/quiesced). Staging container/site stopped. | Yes | Verify routing repointed to previous release. If previous release is healthy, advance to `ROLLED_BACK`. If previous release fails, transition to `RECOVERY_REQUIRED`. |
| **`ROLLED_BACK`** | Traffic confirmed on previous release. | **Terminal State**. Lock released. Failure incident logged. Release marked `ROLLED_BACK`. | Yes | Terminal. Previous release remains authoritative. |
| **`RECOVERY_REQUIRED`** | Rollback failed or split-brain detected. | **Terminal State Requiring Human Intervention**. Automated operations halt. System locked. High-priority alert triggered. | N/A | Preserves all forensic logs. Rejects all automated deployments until operator resolves incident and resets state. |

---

## 3. Strict Definition of Deployment Success

Under this contract, **`SUCCEEDED` strictly means the intended release is proven to be correctly serving live traffic.**

### 3.1 Prohibited False-Success Criteria
The following conditions are **STRICTLY PROHIBITED** from independently establishing release success:
- Process started (e.g. PID exists);
- Container created or started (e.g. `docker run` or `docker compose up` returned exit code 0);
- PowerShell or bash script exited with code 0;
- IIS deployment command or WebDeploy completed;
- Internal container HTTP 200 without routing verification;
- Successful database migration execution alone.

### 3.2 Mandatory Cross-Platform Success Evidence
To transition to `SUCCEEDED`, the deployment engine must collect and record the following empirical evidence:
1. **Exact Artifact Identity**: Cryptographic SHA-256 digest of the container image or Windows deployment package matches the release manifest.
2. **Configuration Integrity**: Runtime environment variables and configuration files match the cryptographically signed release configuration hash.
3. **Runtime Process/Container State**: Container state is `healthy` (Linux) or IIS Worker Process (`w3wp.exe`) is running under the expected application pool (Windows).
4. **Internal Readiness Probing**: Staging endpoint responds with HTTP 200 and JSON status `{"status":"Healthy"}` on `/health` for 3 consecutive probes over a 15-second window.
5. **Dependency Verification**: Readiness probe internally verifies database connectivity and required external dependencies.
6. **Live Traffic Cutover Evidence**: Ingress proxy (Traefik on Linux, HTTP.sys/IIS on Windows) successfully routes public requests to the new release.
7. **External Reachability & Stability Window**: External synthetic probe to the public endpoint returns HTTP 200, followed by a mandatory 30-second observation window during which error rates remain below threshold (5xx < 1%).
8. **Durable Persistence**: All above verification timestamps, response payloads, and release metadata are committed to the `DeploymentRecord` in PostgreSQL.

---

## 4. Cutover Semantics & Preservation of Known-Good Release

A fundamental defect identified by Codex was that previous releases were destroyed or overwritten before the new candidate was verified.

### 4.1 Strict Separation of Stages
The release engine strictly separates five distinct stages:
1. **Artifact Preparation**: Building or downloading artifacts into an isolated staging location. Live services are 100% unaware and unaffected.
2. **Deployment / Application**: Starting the new release in an isolated staging environment (private bridge network or loopback port). Staging services do NOT receive live user traffic.
3. **Verification**: Probing the staging service in isolation to verify functional correctness, database schema compatibility, and dependencies.
4. **Traffic Cutover**: Atomically switching the routing layer (Traefik dynamic configuration or IIS URL Rewrite / binding) to point incoming traffic to the new instance.
5. **Finalization / Commit**: Only AFTER post-cutover verification and the stability window succeed is the release marked `SUCCEEDED`. The previous release is kept in a cached standby state for immediate rollback during the stabilization period.

### 4.2 Cross-Platform Cutover Parity

| Dimension | Linux (Docker + Traefik) | Windows (IIS 10 + HTTP.sys) |
|---|---|---|
| **Staging Isolation** | Container runs with name `${SERVICE}_vNext` on private Docker bridge network without exposed host ports. | Application files unpacked to `C:\inetpub\staging\${SERVICE}_vNext`. Dedicated AppPool created on loopback port (e.g. `127.0.0.1:5081`). |
| **Pre-Cutover Verification** | DevOps Manager queries staging container IP directly on the bridge network via `/health`. | `TMK.Agent.Windows` queries local loopback staging port via `/health`. |
| **Atomic Cutover** | Traefik file provider: DevOps Manager updates the YAML router service definition atomically using write-to-temp-and-rename. Traefik reloads without dropping connections. | IIS HTTP.sys / Application Request Routing (ARR) or URL rewrite rule repointed to the new AppPool binding. |
| **Rollback Execution** | Revert Traefik YAML router to target the previous container (`${SERVICE}_vCurrent`), which was kept running in standby. | Revert IIS URL rewrite / binding to point back to the previous AppPool, which was kept running. |
| **Decommissioning** | Only after 10-minute stability window: stop previous container and prune old images according to retention policy. | Only after 10-minute stability window: stop previous AppPool and archive old directory. |

---

## 5. Single-Host Concurrency, Locking, and Stale-Worker Handling

To guarantee deterministic operation without introducing complex distributed lock managers (such as Zookeeper or Consul), Gate A establishes a robust **Single-Host Atomic Locking & Idempotency Protocol** implemented directly via PostgreSQL advisory locks and durable database rows.

### 5.1 Request Idempotency Key
1. Every deployment request must supply a client-generated UUID `IdempotencyKey`.
2. The API attempts to insert a record into `DeploymentRecord` with a `UNIQUE` constraint on `(TenantId, ServiceName, IdempotencyKey)`.
3. If a duplicate request arrives with the same `IdempotencyKey`:
   - If the current deployment is active (`PENDING`, `PRECHECK`, `PREPARED`, `APPLYING`, `VERIFYING`, `CUTOVER`, `POST_CUTOVER_VERIFY`), the API returns HTTP 409 Conflict with the current deployment status and stream URL.
   - If the previous deployment completed (`SUCCEEDED`, `FAILED`, `ROLLED_BACK`), the API returns the cached terminal result.

### 5.2 Per-Service Atomic Mutex
1. Only one deployment can be active per `ServiceName` on a host.
2. The deployment worker obtains an exclusive PostgreSQL advisory lock on `hashtext(ServiceName)`.
3. If the lock cannot be acquired immediately, the deployment request is queued or rejected with HTTP 423 Locked.

### 5.3 Stale Worker Fencing & Heartbeats
1. An active deployment worker must write a heartbeat timestamp (`LastHeartbeatUtc`) to `DeploymentRecord` every 10 seconds.
2. If a worker crashes or hangs, the heartbeat expires after a 60-second TTL.
3. Upon detecting an expired heartbeat:
   - The lock is considered stale.
   - A recovering supervisor verifies the process ID (`WorkerPid`) and host name. If the process is still running, it is terminated forcefully (`kill -9` / `TerminateProcess`) to prevent stale workers from resuming already-authorized ingress mutations.
   - **Generation Epoch Tokens**: Every deployment step attaches a monotonically increasing `DeploymentEpoch` token to physical router configs and staging directories. Late writes from stale or partitioned workers are rejected because their epoch is superseded.
   - **Database Fencing**: Every database update checks `Version = @ExpectedVersion`, incrementing the version atomically. Any late write fails with an optimistic concurrency exception.
   - If a crash occurred before cutover, the supervisor inspects whether irreversible migrations ran. If schema was modified and compatibility with $N-1$ is unverified, state transitions to `RECOVERY_REQUIRED`. Otherwise, it safely marks `FAILED` or initiates application rollback.

---

## 6. Database Migration & Rollback Contract

Codex finding `C0-01` emphasized:
> "Do NOT imply that application rollback automatically means database rollback... Do NOT automatically restore a database merely because application deployment failed."

This contract establishes a strict boundary between **Application Rollback**, **Database Compatibility**, and **Database Restoration**.

### 6.1 Fundamental Axiom: Application Rollback != Database Rollback
Reverting an application binary or container NEVER triggers an automatic database restoration. The two operations operate on completely different principles:
- **Application Rollback** is safe, non-destructive, and can be automated because it simply repoints traffic to an existing, valid container/package.
- **Database Restoration** is destructive: restoring a database backup or snapshot wipes out all transactions, user registrations, orders, and state changes written between the snapshot time and the rollback time.

### 6.2 Backward-Compatible "Expand/Contract" Migration Mandate Across Rollback Candidates
For Gate A, all database schema migrations must adhere to the **Expand / Contract (Two-Phase Evolution) Pattern across active rollback candidates**:
1. **Expand Phase (Release $N$)**:
   - Schema changes must be strictly additive and backward-compatible with Release $N-1$.
   - Allowed: Adding nullable columns, adding new tables, adding views, adding indexes (concurrently).
   - Prohibited in a single step: Renaming existing columns, deleting tables/columns, adding non-nullable columns without defaults, altering data types destructively.
   - Release $N$ dual-writes or writes to new schema structures while maintaining old columns.
2. **Contract Phase (Release $N+2$)**:
   - Columns or tables utilized by Release $N$ MUST NOT be dropped during Release $N+1$ deployment if Release $N$ remains an active rollback candidate.
   - Contract migrations (dropping legacy columns/tables) are permitted only in Release $N+2$, after Release $N+1$ has proven stable in production and Release $N$ is no longer an eligible rollback target.

### 6.3 Pre-Deployment Migration Eligibility Evaluation
Before any deployment begins:
1. The release engine inspects the candidate release manifest.
2. If migrations are present, the engine checks whether they contain destructive operations (detected via EF Core migration model differences).
3. If an incompatible/destructive migration is detected, the deployment is flagged as **`IRREVERSIBLE_DB_MIGRATION`**:
   - The operator is warned that automated application rollback will NOT be possible.
   - The deployment requires explicit operator confirmation flag `--allow-irreversible-migration`.
   - If deployment fails after migration execution, the engine halts and enters `RECOVERY_REQUIRED`.

### 6.4 Fenced Database Restoration Rules
Restoring a database snapshot or backup is a **Disaster Recovery Operation**, NOT an automated release rollback. Database restoration is permitted ONLY under the following strict conditions:
1. **Explicit Operator Authorization**: Restoration requires human intervention and a signed administrative request specifying `--confirm-destructive-data-loss`.
2. **Quiesced System**: The application must be put into Maintenance Mode (or stopped) so zero writes are occurring.
3. **Data Loss Assessment**: The operator must review the timestamp delta and acknowledge that all data written after the snapshot will be lost.
4. **Pre-Restore Safety Dump**: An immediate ad-hoc physical dump of the current database state (including the post-snapshot writes) must be taken before the restore is executed, preserving forensic data.

---

## 7. Failure Walkthrough Scenarios

To satisfy the Codex acceptance criteria, the table below documents the deterministic, safe outcome for every failure scenario:

| Failure Scenario | Active State | State Machine Action | Resulting State | Data Loss Risk? |
|---|---|---|---|---|
| **Duplicate Request** | `APPLYING` | Second request matches `IdempotencyKey`; returns HTTP 409 with active deployment stream. | `APPLYING` (Unchanged) | None |
| **Lock-Holder Death / Worker Crash** | `APPLYING` | Heartbeat TTL expires. Recovering supervisor terminates dead PID (`kill -9`), verifies generation epoch. If schema compatibility with $N-1$ is unverified or modified, routes to `RECOVERY_REQUIRED`. Otherwise, cleans up staging container. | `FAILED` or `RECOVERY_REQUIRED` | None |
| **Precheck Disk Space Exhaustion** | `PRECHECK` | Disk space < 5GB detected. No files created, no containers spawned, lock released. | `FAILED` | None |
| **Staging Health Probes Fail (HTTP 500)** | `VERIFYING` | Staging container fails health checks 3 times. Staging container stopped. Live traffic was never switched. Old release intact. | `FAILED` | None |
| **Traffic Cutover Routing Fails** | `CUTOVER` | Traefik configuration reload errors or HTTP.sys binding fails. Cutover aborted; routing verified pointing to old container. | `ROLLBACK` → `ROLLED_BACK` | None |
| **Post-Cutover Spike in 5xx Errors** | `POST_CUTOVER_VERIFY` | Error rate > 1% detected during 30s observation window. Automated rollback triggered: routing switched back to previous standby container. Staging container stopped. DB snapshot is NOT restored. | `ROLLBACK` → `ROLLED_BACK` | None |
| **Migration Succeeded, Application Fails to Start** | `APPLYING` / `VERIFYING` | Migration succeeded. Because migrations follow Expand/Contract, the previous release ($N-1$) is 100% compatible with the expanded schema. Traffic remains on $N-1$. Staging container stopped. DB snapshot is NOT restored. | `ROLLBACK` → `ROLLED_BACK` | Zero data loss. $N-1$ continues serving. |
| **Destructive/Incompatible Migration Failed Mid-Execution** | `APPLYING` | Migration transaction rolls back automatically (PostgreSQL transactional DDL). Application never deployed. System remains on $N-1$. | `FAILED` | None |
| **Rollback Fails (Previous container crashed while standby)** | `ROLLBACK` | Traffic cutover reverted, but previous container fails health checks. Automated recovery cannot safely determine authoritative state. Machine halts. High-priority alert triggered. | `RECOVERY_REQUIRED` | Fenced. Prevents split-brain or data corruption. |
| **Writes Occurring After Pre-Deploy Snapshot** | `POST_CUTOVER_VERIFY` | Production writes committed during and after deployment. Application rollback reverts containers only. Post-deploy writes are preserved in live DB. | `ROLLED_BACK` | Zero data loss (no DB restore). |

---

## 8. Removal of Unqualified "Zero-Downtime" Promises

All unqualified claims of "zero-downtime rollback" and "outage prevented" are formally removed from the baseline documents.

In their place, the contract precisely defines:
- **Target Ingress Latency**: During normal cutover, Traefik and HTTP.sys achieve near-zero connection drop (< 200ms connection handover) for HTTP keep-alive requests (operational target).
- **Target Rollback Latency**: If automated rollback is triggered during `POST_CUTOVER_VERIFY`, traffic is redirected to the standby container within an operational target of 2 to 5 seconds (not a certified measurement until live testing).
- **Maintenance Windows**: Deployments involving major schema refactoring or stateful component upgrades may schedule explicit maintenance windows using Centralized Maintenance Mode (MR-14).

---

## 9. Conclusion

This release safety contract provides an airtight, deterministic, and technically executable specification. It eliminates premature success markings, separates application rollback from database restoration, provides robust single-host locking and idempotency, and guarantees that no live service or customer data is compromised during releases.
