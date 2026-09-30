# Release and Database Recovery Reconciliation

**Document ID**: `REGATE-REMED-02-RELEASE-DB`  
**Phase**: Phase 0 — Codex Focused Re-Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex Re-Gate C0-01 (`06_REGATE_FINDINGS_REGISTER.md:30-39`)  
**Status**: COMPLETE — AUTHORITATIVE AND RECONCILED  

---

## 1. Authoritative Core Invariant

The central acceptance blocker identified in `C0-01` is resolved by codifying the following immutable system invariant across all deployment, upgrade, and maintenance specifications:

> # APPLICATION ROLLBACK MUST NOT AUTOMATICALLY RESTORE THE DATABASE.

Reverting an application binary, container, or traffic routing target to a previous release NEVER triggers an automated database restore. 

---

## 2. Definitive Database Failure Model

To eliminate the recurring confusion between code deployment recovery and data disaster recovery, the platform freezes the following architectural distinctions:

```mermaid
flowchart TD
    subgraph OperationalDeployment["Operational Release / Upgrade Lifecycle"]
        Deploy["Deploy Release N"] --> HealthCheck{"Health Probes Passed?"}
        HealthCheck -- YES --> Cutover["Traffic Cutover to N"]
        Cutover --> PostVerify{"Post-Cutover Verification"}
        PostVerify -- PASS --> Success["SUCCEEDED"]
        
        HealthCheck -- NO --> AppRollback1["Application Rollback to N-1"]
        PostVerify -- FAIL --> AppRollback2["Application Rollback to N-1"]
        
        AppRollback1 --> SchemaCheck1["Schema Compatibility Contract (Expand/Contract)"]
        AppRollback2 --> SchemaCheck1
        SchemaCheck1 --> SafeN1["Release N-1 Continues Serving Live Traffic (Zero Data Loss)"]
    end

    subgraph DisasterRecovery["Explicit Disaster Recovery Workflow (Out-of-Band)"]
        Catastrophe["Severe Data Corruption / Hardware Loss"] --> HumanAuth["Explicit Human Operator Authorization (--confirm-destructive-data-loss)"]
        HumanAuth --> Quiesce["Quiesce System (Maintenance Mode / Zero Writes)"]
        Quiesce --> SafetyDump["Ad-Hoc Pre-Restore Safety Dump"]
        SafetyDump --> DBRestore["Execute Database Restore from Selected RecoveryPoint"]
        DBRestore --> VerifyRestore["Verify Referential & Row Integrity"]
        VerifyRestore --> ResumeOps["Audit Record Logged & Resume Operations"]
    end
```

### 2.1 Application Rollback
- **Definition**: Returning application binaries, containers, environment configurations, and traffic ingress routing targets to a compatible, known-good release ($N-1$).
- **Trigger**: Automated response to pre-cutover staging probe failure, router cutover failure, or post-cutover 5xx error spikes during the observation window.
- **Safety Properties**: Non-destructive, idempotent, and automated. Preserves all committed customer transactions, database records, and audit events.

### 2.2 Schema Compatibility Contract Across Rollback Candidates
- **Definition**: The invariant that database schema evolution must guarantee that Release $N$ and every active rollback candidate ($N-1$) remain 100% operational against the live database schema.
- **Two-Phase Expand/Contract Rules Across Active Rollback Targets**:
  1. **Phase 1 — Expand (Release $N$)**:
     - Schema changes must be strictly additive and backward-compatible with Release $N-1$.
     - Allowed: Adding nullable columns, adding new tables, adding views, adding indexes concurrently, dual-writing to new structures.
     - Prohibited: Renaming columns/tables, dropping columns/tables, altering types destructively, adding non-nullable columns without defaults.
  2. **Phase 2 — Transition (Release $N+1$)**:
     - Release $N+1$ reads and writes the new schema structures but **retains legacy columns and tables** utilized by Release $N$ as long as Release $N$ remains an eligible rollback candidate.
  3. **Phase 3 — Contract (Release $N+2$)**:
     - Dropping legacy columns or tables is permitted **only in Release $N+2$**, after Release $N+1$ has proven stable in production and Release $N$ is formally retired as a rollback target.

### 2.3 Database Recovery (Disaster Recovery Only)
- **Definition**: Destructive restoration of database physical/logical state from a previous snapshot or `RecoveryPoint`.
- **Operational Rule**: Database recovery is strictly an explicit disaster recovery operation.
- **Strict Prohibition**: Database recovery **MUST NOT** be an automatic consequence of:
  - Failed application health check;
  - Failed application deployment;
  - Failed traffic cutover;
  - Application rollback;
  - Ordinary platform upgrade failure;
  - Container crash during deployment.

---

## 3. Explicit Database Restore Authorization Workflow

Destructive database restoration requires an explicit, audited operator workflow. The platform forbids automated scripts from executing destructive restoration. The workflow mandates:

1. **Human Authorization**: An authenticated platform administrator (`PlatformSuperAdmin`) must issue an explicit CLI/API command with mandatory confirmation flag:
   ```bash
   devops-manager db restore --tenant-id <id> --recovery-point <RP-UUID> --confirm-destructive-data-loss
   ```
2. **Documented Operational Reason**: The administrator must provide a required text reason (e.g. ticket reference, root-cause description) which is permanently recorded in the immutable audit log.
3. **Recovery Point Selection**: Explicit selection of a verified `RecoveryPointId` from the authenticated backup catalog.
4. **Expected Data-Loss Window Assessment**: The tool calculates and displays the delta between the backup timestamp and current system time, forcing the operator to review and accept the window of lost writes.
5. **System Quiescing**: The application and all background workers must be transitioned to Centralized Maintenance Mode (or stopped) to guarantee zero concurrent writes.
6. **Pre-Restore Safety Capture**: The restore engine automatically executes an immediate physical safety dump of the live database (`pre_restore_safety_dump_{timestamp}.dump`) before overwriting database contents, ensuring that post-snapshot writes are preserved for forensic recovery.
7. **Restore Verification**: The engine verifies the restored database by inspecting table counts, schema integrity, and referential constraints, asserting exit code 0.
8. **Immutable Audit Record**: A cryptographic audit record (`AUDIT_DB_RESTORE_EXECUTED`) containing operator identity, timestamp, source recovery point, and pre-restore dump hash is appended to the audit ledger.

---

## 4. Upgrade Document Reconciliation

In the previous baseline, `docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md` at line 125 contained the contradictory instruction:
> *"5. If health check fails: Restore pre-upgrade database backup... Verify restored platform health before exiting with failure."*

### 4.1 Authoritative Correction Executed
In `docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md`, Phase 10 (Rollback & Failure Recovery) was edited to remove database restoration and freeze the invariant:
```markdown
- **Phase 10: Rollback & Failure Recovery**:
  1. Roll back to previous platform container image tag ($N-1$).
  2. Restore previous environment variable configuration and compose files.
  3. Re-route traffic via Traefik / HTTP.sys to the restored containers.
  4. Verify restored platform health before exiting with failure.
  - **CRITICAL INVARIANT**: Application rollback MUST NOT automatically restore the database. The previous release must remain compatible with the database schema under the Expand/Contract contract. Destructive database restoration is strictly an explicit disaster recovery operation requiring human authorization (`--confirm-destructive-data-loss`), system quiescing, an ad-hoc pre-restore safety dump, and data-loss window assessment.
```

### 4.2 Repository-Wide Alignment
The same invariant was verified and applied across:
- `docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md` (lines 142, 177–178);
- `docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md` (Platform Upgrades row);
- `docs/remediation/phase-0-codex-remediation/02_RELEASE_CONTRACT_CORRECTION.md` (§6.1, §6.3).

---

## 5. Concurrency, Fencing, and Durable State Machine

### 5.1 Release Engine State Transitions
The release engine transitions through durable, persisted states recorded in PostgreSQL:
```
PENDING → PRECHECK → PREPARED → APPLYING → VERIFYING → CUTOVER → POST_CUTOVER_VERIFY → SUCCEEDED
                                    ↓            ↓          ↓              ↓
                                 FAILED        FAILED    ROLLBACK       ROLLBACK
                                                            ↓              ↓
                                                        ROLLED_BACK    ROLLED_BACK
                                                            ↓              ↓
                                                    (if uncertain)  (if uncertain)
                                                    RECOVERY_REQ    RECOVERY_REQ
```

### 5.2 Multi-Layered Worker Process Fencing
A database version CAS alone is insufficient to prevent a paused or partitioned worker process from resuming already-authorized physical mutations (such as router rewrites or filesystem swaps). The platform enforces four complementary fencing barriers:

1. **Worker Process Termination Verification**:
   - Every deployment worker reports its host name and OS Process ID (`WorkerPid`) along with heartbeats (`LastHeartbeatUtc`) every 10 seconds.
   - If a heartbeat expires (TTL 60s), a recovering supervisor verifies whether `WorkerPid` is alive.
   - If alive, the supervisor issues a forceful termination signal (`kill -9` on Linux, `TerminateProcess` on Windows) to guarantee the stale process is dead before any recovery action begins.
2. **Physical Generation Epoch Tokens**:
   - Each deployment step generates a monotonically increasing `DeploymentEpoch` token.
   - All physical router configuration directories and staging extraction roots incorporate this epoch token.
   - Any late-arriving write from a paused worker references an expired epoch and is rejected by the router filesystem/agent.
3. **Database Optimistic Concurrency CAS**:
   - Every database state transition checks `Version = @ExpectedVersion` and increments `Version` atomically.
   - Late database writes from dead or partitioned workers trigger `DbUpdateConcurrencyException` and halt immediately.
4. **Idempotency Key Fencing**:
   - Incoming release requests provide a unique `IdempotencyKey`.
   - Concurrent submissions receive HTTP 409 Conflict with the active deployment status URL. Duplicate submissions after completion return the cached terminal result.

---

## 6. Documentary Walkthroughs: 10 Failure Scenarios

To prove the deterministic safety of the release contract, the 10 critical failure scenarios identified by Codex have been analyzed and verified to terminate in defined safe states without automatic database restore:

| # | Scenario | Active State | Cause / Trigger | State Machine & Supervisor Action | Terminal Safe State | Customer Data Loss? |
|---|---|---|---|---|---|---|
| **1** | **Duplicate Request** | `APPLYING` | Client or CI resends deployment payload with same `IdempotencyKey`. | Idempotency middleware intercepts request; detects existing active deployment; returns HTTP 409 Conflict with stream URL. Zero new containers or locks created. | `APPLYING` (Unchanged) | Zero data loss. |
| **2** | **Lock-Holder Death** | `APPLYING` | Worker process terminated (OOM killer or OS crash) during file extraction. | Heartbeat TTL (60s) expires. Supervisor detects dead `WorkerPid`, cleans up staging directory, verifies no schema migrations ran, releases advisory lock. | `FAILED` | Zero data loss. Previous release unaffected. |
| **3** | **Crash Before Mutation** | `PRECHECK` / `PREPARED` | Power loss or node reboot during dependency check or image pull. | On reboot, recovery scanner detects expired heartbeat in `PRECHECK`. No schema or router mutations occurred. Releases lock and marks failed. | `FAILED` | Zero data loss. Previous release intact. |
| **4** | **Crash After Mutation but Before State Persistence** | `APPLYING` | Worker starts staging container or applies migration, then host reboots before writing `VERIFYING` state. | On reboot, supervisor inspects actual database migration table (`__EFMigrationsHistory`) and container state. If migration ran, verifies compatibility with $N-1$. If compatible, cleans up staging; if incompatible or uncertain, transitions to `RECOVERY_REQUIRED`. | `FAILED` or `RECOVERY_REQUIRED` | Zero data loss. Live traffic never directed to unverified build. |
| **5** | **Verification Failure** | `VERIFYING` | Staging container fails internal health checks (`/health` returns HTTP 500 three consecutive times). | Release engine halts progress. Traffic was never switched (router still points to $N-1$). Staging container stopped and pruned. DB is NOT restored. | `FAILED` | Zero data loss. Previous release continues serving. |
| **6** | **Cutover Failure** | `CUTOVER` | Traefik configuration reload errors or Windows HTTP.sys URL reservation binding fails. | Cutover transaction aborts. Ingress router verified to route 100% of traffic to previous container ($N-1$). Engine initiates `ROLLBACK`. Staging container stopped. DB is NOT restored. | `ROLLED_BACK` | Zero data loss. Router verified pointing to $N-1$. |
| **7** | **Post-Cutover Failure** | `POST_CUTOVER_VERIFY` | 5xx error rate exceeds 1% during 30s observation window on live traffic. | Automated application rollback triggered. Ingress router immediately redirects traffic back to standby container ($N-1$). Staging container stopped. Database snapshot is NOT restored (schema is Expand-compatible). | `ROLLED_BACK` | Zero data loss. All writes committed during observation window are preserved in DB. |
| **8** | **Incompatible Migration** | `PRECHECK` | Candidate release contains destructive migration (e.g. dropping column required by $N-1$). | Pre-deployment migration analyzer detects destructive migration without explicit `--allow-irreversible-migration` flag. Deployment rejected before execution. | `FAILED` | Zero data loss. Migration never executed. |
| **9** | **Application Failure After Compatible Migration** | `APPLYING` / `VERIFYING` | Additive migration succeeds, but new application code throws runtime configuration exception on startup. | Staging health checks fail. System initiates application rollback: router remains on $N-1$. Staging container stopped. Database is NOT restored because $N-1$ is fully compatible with additive schema. | `ROLLED_BACK` | Zero data loss. $N-1$ continues serving against expanded schema. |
| **10** | **Writes Occurring After Pre-Deployment Backup** | `POST_CUTOVER_VERIFY` | Users make purchases or update records after pre-deploy backup was taken. Health subsequently fails. | Application rollback reverts container image and traffic to $N-1$. Database is NOT restored. Post-deploy writes remain in database. Operator investigates application logs. | `ROLLED_BACK` | Zero data loss. Preserves post-snapshot customer transactions. |

---

## 7. Resolution Verification of Original C0-01

With the removal of the stale database restore instruction in `12_UPGRADE_CURRENT_STATE.md:125`, the formalization of Expand/Contract rules across active rollback candidates, multi-layer worker fencing, and the complete 10-scenario safe state walkthroughs, finding **`C0-01` is completely and definitively resolved**.
