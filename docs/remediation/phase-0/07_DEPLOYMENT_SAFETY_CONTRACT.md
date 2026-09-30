# 07 DEPLOYMENT SAFETY CONTRACT & RELEASE STATE MACHINE

**Document ID**: `REMED-P0-07`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Status**: Authoritative Cross-Platform Deployment Contract Frozen (Codex C0-01 Remediation Applied)  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C0-01`)  

---

## 1. Release Safety Principles

A deployment is not merely the execution of a script; it is a transactional state transition from one proven immutable release to another.

The deployment engine enforces these fundamental invariants:
1. **`SUCCEEDED` Means Serving Live Traffic**: A release is NEVER marked `SUCCEEDED` until traffic cutover has executed and post-cutover verification affirmatively proves healthy operation.
2. **Separation of Stages**: Artifact preparation, staging deployment, readiness verification, traffic cutover, and finalization are strictly separated. The previous known-good release is never destroyed before the new candidate is verified.
3. **Application Rollback != Database Rollback**: Application rollback reverts container/artifact routing. Database restoration is a separate, destructive disaster recovery operation that is NEVER automatically triggered on deployment failure.
4. **Backward-Compatible Schema Migrations**: All migrations follow the Expand/Contract pattern so that Release $N-1$ remains fully functional if Release $N$ fails.
5. **Durable Persistence & Single-Host Atomic Locking**: Every transition is persisted to PostgreSQL before executing side effects. Deployments acquire per-service advisory locks and validate request idempotency keys.
6. **Fenced Crash & Reboot Reconciliation**: Orphaned or interrupted deployments reconcile deterministically without unverified promotions.

---

## 2. Definitive Release State Machine

```mermaid
stateDiagram-v2
    [*] --> PENDING
    
    PENDING --> PRECHECK : Validate Idempotency & Acquire Service Lock
    
    PRECHECK --> PREPARED : Preflight, Schema Check & Digest Verified
    PRECHECK --> FAILED : Preflight Validation Error (No mutations)
    
    PREPARED --> APPLYING : Start Staging Instance (Isolated Bridge/Port)
    PREPARED --> FAILED : Setup Error (No live traffic touched)
    
    APPLYING --> VERIFYING : Staging Process Running
    APPLYING --> ROLLBACK : Container Crash / Staging Startup Failure
    
    VERIFYING --> CUTOVER : Internal Health & Dependency Probes Pass
    VERIFYING --> ROLLBACK : Internal Probe Timeout or Failure
    
    CUTOVER --> POST_CUTOVER_VERIFY : Ingress Traffic Repointed
    CUTOVER --> ROLLBACK : Ingress Switch Failure
    
    POST_CUTOVER_VERIFY --> SUCCEEDED : External Probes Pass & Stability Window Stable
    POST_CUTOVER_VERIFY --> ROLLBACK : External Failure / Error Rate Spike (>1%)
    
    ROLLBACK --> ROLLED_BACK : Traffic Reverted to Standby Prior Release
    ROLLBACK --> RECOVERY_REQUIRED : Reversion Failed (Manual Intervention)
    
    SUCCEEDED --> [*]
    ROLLED_BACK --> [*]
    FAILED --> [*]
    RECOVERY_REQUIRED --> [*]
```

---

## 3. Explicit State Transition Specification

### State 0: `PENDING`
- **Actions**:
  - Receive deployment request containing client-generated `IdempotencyKey`.
  - Validate caller authorization (`Deployments_Execute` scoped to tenant).
  - Attempt insert into `DeploymentRecord` with unique constraint `(TenantId, ServiceName, IdempotencyKey)`.
  - If duplicate request: return HTTP 409 Conflict with active status or cached terminal result.
- **Transition**: Advance to `PRECHECK`.

### State 1: `PRECHECK`
- **Actions**:
  - Acquire single-host per-service atomic lock via PostgreSQL advisory lock `hashtext(ServiceName)`.
  - Validate release target (must be explicit SemVer tag or content digest; reject `main`, `master`, `latest`).
  - Validate artifact availability (Docker registry manifest exists or artifact ZIP exists on disk).
  - Check disk headroom ($\ge 5\text{ GB}$ free space required).
  - Verify database connectivity and schema migration eligibility (reject destructive migrations without explicit `--allow-irreversible-migration` flag).
- **Failure Condition**: Any check fails → transition to `FAILED`. Zero physical mutations have occurred; lock is released.

### State 2: `PREPARED`
- **Actions**:
  - Persist `DeploymentRecord` state `PREPARED`.
  - Download/pull artifact and verify cryptographic SHA-256 digest.
  - Staging directories / images prepared.
  - Record the proven active release identifier as `RollbackTarget`.
  - Execute pre-deployment database migration preflight.
- **Failure Condition**: Preparation fails → transition to `FAILED` (no changes made to running application).

### State 3: `APPLYING`
- **Actions**:
  - Update `DeploymentRecord` to `APPLYING`.
  - **Linux Topology**: Spawn new container on internal Docker bridge (`${SERVICE}_vNext`), unbound from public ports.
  - **Windows Topology**: Extract files to staging directory `C:\inetpub\staging\${SERVICE}_vNext`; create staging IIS AppPool on loopback port (`127.0.0.1:508x`).
  - **Database Migration**: If migrations are pending, execute additive Expand migrations.
- **Failure Condition**: Process failure, container crash, or exit code != 0 → transition to `ROLLBACK`.

### State 4: `VERIFYING`
- **Actions**:
  - Update `DeploymentRecord` to `VERIFYING`.
  - Poll staging HTTP readiness probe (`GET http://staging-endpoint/health`) every 2 seconds for 3 consecutive successes over a 15-second window.
  - Verify database connectivity and internal dependencies via probe payload.
  - Verify zero crash events on staging instance.
- **Transition**:
  - All probes succeed within 60s timeout → transition to `CUTOVER`.
  - Probe fails or times out → transition to `ROLLBACK`.

### State 5: `CUTOVER`
- **Actions**:
  - Update `DeploymentRecord` to `CUTOVER`.
  - **Linux Topology**: Atomically update Traefik dynamic router YAML to repoint domain traffic to `${SERVICE}_vNext`.
  - **Windows Topology**: Atomically update IIS URL rewrite rules / bindings to repoint incoming traffic to new AppPool.
  - Previous release is kept running in standby (quiesced).
- **Transition**:
  - Routing switch successful → transition to `POST_CUTOVER_VERIFY`.
  - Routing switch fails → transition to `ROLLBACK`.

### State 6: `POST_CUTOVER_VERIFY`
- **Actions**:
  - Update `DeploymentRecord` to `POST_CUTOVER_VERIFY`.
  - Execute synthetic HTTP probes against the public domain endpoint.
  - Monitor live error rates during a mandatory 30-second observation window (5xx error rate must remain $< 1\%$).
- **Transition**:
  - Probes pass and stability window clean → transition to `SUCCEEDED`.
  - Probes fail or error rate spikes → transition to immediate automated `ROLLBACK`.

### State 7: `SUCCEEDED` (Terminal)
- **Actions**:
  - Mark `DeploymentRecord` as `SUCCEEDED` with completion timestamp, probe latency, and active image digest.
  - Release per-service atomic lock.
  - After a 10-minute grace period, decommission previous container / AppPool according to image retention rules.
  - Emit outbound deployment success event (Audit Log, Webhook).

### Failure Branch 1: `FAILED` (Terminal)
- Precheck or preparation failed before mutations. Lock released. No live service touched. Zero recovery needed.

### Failure Branch 2: `ROLLBACK`
- **Actions**:
  - Log root-cause error in `DeploymentRecord`.
  - Revert traffic routing in Traefik / IIS to point back to the previous standby release (`RollbackTarget`).
  - Stop and destroy the failed staging container / AppPool.
  - **Database Policy**: Database snapshot is **NOT** automatically restored. Because migrations follow Expand/Contract, Release $N-1$ remains 100% compatible.
  - Probe restored prior release.
- **Transition**:
  - Prior release responds healthy → transition to `ROLLED_BACK`.
  - Prior release fails to respond healthy → transition to `RECOVERY_REQUIRED`.

### Terminal State: `ROLLED_BACK`
- Traffic safely reverted to prior stable release. Release marked `ROLLED_BACK`. Service lock released. Operator alerted.

### Terminal State: `RECOVERY_REQUIRED`
- Catastrophic condition: Automated rollback failed or split-brain detected. System locked. High-priority P0 alert dispatched. Zero automated destructive actions permitted; requires human operator intervention.

---

## 4. Crash Recovery & Startup Reconciliation

When the DevOps Manager API or host VM restarts:
1. Startup worker queries all `DeploymentRecords` in non-terminal states (`PENDING`, `PRECHECK`, `PREPARED`, `APPLYING`, `VERIFYING`, `CUTOVER`, `POST_CUTOVER_VERIFY`, `ROLLBACK`).
2. For each non-terminal record:
   - Verify worker PID, host assignment, and heartbeat timestamp (`LastHeartbeatUtc`).
   - If heartbeat is expired (> 60s) and state is prior to `CUTOVER`:
     - Inspect whether database migrations were initiated or completed for this deployment.
     - If an irreversible or backward-incompatible migration was applied, or if schema state cannot be deterministically verified as compatible with Release $N-1$, the deployment **MUST NOT** be blindly marked `FAILED`. It must transition to **`RECOVERY_REQUIRED`** to prevent traffic routing to an incompatible previous release.
     - If no migration was applied, or if applied migrations are proven backward-compatible with Release $N-1$: Assert old worker PID termination, prune staging instance, verify previous release is actively serving healthy traffic, and transition record to `FAILED`.
   - If state is `CUTOVER` or `POST_CUTOVER_VERIFY`: Controller probes public endpoint and router configuration. If traffic was not cut over, evaluate migration compatibility before marking `FAILED` or `RECOVERY_REQUIRED`. If traffic cutover was partially applied or failing, initiate automated `ROLLBACK` to restore previous release (if schema-compatible).
   - If state or schema compatibility is unresolvable: Mark `RECOVERY_REQUIRED`, fence mutations, and dispatch high-priority P0 alert.
3. No non-terminal deployment is ever automatically promoted to `SUCCEEDED` without verified live traffic serving.

---

## 5. Database Migration and Rollback Boundaries

### 5.1 Authoritative Invariant: Application Rollback != Database Restoration
- **Application Rollback** is safe, automated, and non-destructive: traffic is redirected back to the previous compatible container/AppPool ($N-1$).
- **Database Restoration** is destructive: restoring a database dump wipes out all data written since the backup.
- **APPLICATION ROLLBACK MUST NOT AUTOMATICALLY RESTORE THE DATABASE.**
- Database recovery is strictly an explicit disaster recovery operation requiring human authorization (`--confirm-destructive-data-loss`), system quiescing, an ad-hoc pre-restore safety dump, and data-loss window assessment.

### 5.2 Expand / Contract Migration Rules Across Rollback Candidates
Schema changes across versions must preserve compatibility for every declared rollback candidate:
1. **Release $N$ (Expand Phase)**:
   - Schema changes must be strictly additive and backward-compatible with Release $N-1$.
   - Permitted: Adding nullable columns, adding new tables, adding views, adding indexes (concurrently).
   - Prohibited in a single step: Renaming existing columns, deleting tables/columns, adding non-nullable columns without defaults, altering data types destructively.
   - If Release $N$ introduces a new column to replace an old column, Release $N$ dual-writes to both old and new columns, and reads from the new column (with fallback to old).
   - Rollback candidate: Release $N-1$ remains 100% operational against the Release $N$ expanded schema.
2. **Release $N+1$ (Transition Phase)**:
   - Application reads exclusively from new column and writes to new column.
   - **Crucial Invariant**: Release $N+1$ **MUST NOT** drop the old column yet, because if Release $N+1$ fails in production and rolls back to Release $N$, Release $N$ still requires the old column for dual-writing.
3. **Release $N+2$ (Contract Finalize Phase)**:
   - Only after Release $N+1$ is verified stable, fully accepted in production, and Release $N$ is no longer an active rollback target, the old column may be safely dropped in Release $N+2$.
   - Any release that drops schema elements must NOT declare an earlier release that depends on those elements as an automated rollback candidate.

---

## 6. Worker Fencing and Ingress Mutation Protection

To prevent split-brain or late writes when a paused or partitioned worker resumes after heartbeat expiry:
1. **Database Fencing**: Every database update uses optimistic concurrency checking `Version = @ExpectedVersion`, incrementing the version atomically. Late writes from stale workers fail with concurrency exceptions.
2. **Physical Process Fencing**: When a recovering supervisor takes over a stale deployment, it must verify the prior worker PID and issue a forced process termination (`kill -9` on Linux, `TerminateProcess` on Windows) and assert process termination before modifying staging directories or router configurations.
3. **Deployment Generation Epochs**: Staging directories and router configurations use generation tokens (e.g. `release-{deployId}-{generation}`). A stale worker writing to an obsolete staging generation cannot alter the active ingress symlink or IIS virtual directory mapping.

---

## 7. Application Health Parameterization

Application health evaluation criteria are configurable profile defaults, not hardcoded platform constants:
1. **Default Profile**: HTTP 200 on `/health` probe, 30-second observation window during `POST_CUTOVER_VERIFY`, 5xx error rate < 1.0%.
2. **Service-Specific Declarations**: Individual services may declare customized health check paths (e.g. `/api/system/status`), expected HTTP status codes (e.g. 200-204), startup timeouts (e.g. 15s to 120s), and observation thresholds in their deployment metadata.
3. **Affirmative Verification Invariant**: Regardless of parameters used, a deployment must collect affirmative evidence of successful serving under the declared contract before transitioning to `SUCCEEDED`.

