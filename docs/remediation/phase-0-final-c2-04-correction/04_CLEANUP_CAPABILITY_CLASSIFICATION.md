# Cleanup Capability Epistemic Classification

**Document ID**: `FINAL-C2-04-04-CLASSIFICATION`  
**Phase**: Phase 0 — Final C2-04 Evidence Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: COMPLETE — AUTHORITATIVE  

---

## 1. Epistemic Separation Framework

To prevent any future conflation of diagnostic suggestions, on-demand API endpoints, background scheduling, and future target capabilities, all cleanup-related functionality is classified into four distinct epistemic tiers:

```
+---------------------------------------------------------------------------------------+
|                               CLEANUP CAPABILITY TAXONOMY                              |
+---------------------------------------------------------------------------------------+
| 1. Current Evidenced Behavior      | 2. Diagnostic Recommendation                     |
|    - Truncates logs > 50MB          |    - Returns "docker system prune -f" string     |
|    - Deletes DB logs older than 14d |    - AI / CI build failure diagnosis (OOM)       |
|    - On-demand CLI prune endpoints  |    - NEVER automatically executed by engine      |
+------------------------------------+--------------------------------------------------+
| 3. Target Future Behavior (MR-17)  | 4. Historical Marketing Assertion                |
|    - Digest-preserving mark/sweep  |    - "Intelligent automated Docker storage       |
|    - Preserves >= 3 rollback images |      cleanup preserving rollback caches"          |
|    - Concurrency locking vs deploy  |    - Cites nonexistent scripts/cleanup-docker.sh |
+---------------------------------------------------------------------------------------+
```

---

## 2. Detailed Capability Breakdown

### 2.1 Current Evidenced Behavior (Static Source Reality)
Only behavior actually verified in tracked source code:
- **Database Log Retention**: `DockerCleanupBackgroundService.cs:171-227` runs daily at 3:00 AM IST and executes parameterized SQL to delete rows older than 14 days from `SystemLogs`, `DeploymentLogs`, and `ci_build_logs`, and older than 30 days from `DisasterRecoveryLogs`, `JobExecutionLogs`, and `ExceptionLogs`.
- **Filesystem Artifact Pruning**: `DockerCleanupBackgroundService.cs:228-245` deletes CI build artifacts older than 7 days, application log files older than 7 days, mobile intermediate build directories older than 3 days, and crash dumps (`*.hprof`, `core.*`).
- **Container Log Truncation**: `DockerCleanupBackgroundService.cs:233` and `MonitoringService.cs:262` execute an ephemeral Alpine container (`docker run --rm -v /var/lib/docker/containers:/containers alpine ... truncate -s 0`) targeting JSON log files over 50MB. (Note: As identified in `08_OBSERVABILITY_RESOURCE_GOVERNANCE.md`, this bypasses Docker logging accounting, which is a known architectural debt item).
- **On-Demand Docker Pruning Endpoints**: `MonitoringService.CleanupDockerAsync` (lines 234–315) exposes an administrative API method for `docker container prune -f`, `docker image prune -f [-a]`, `docker network prune -f`, `docker volume prune -f`, and `docker builder prune -f`.
- **Automatic Docker Pruning Execution**: **NOT evidenced**. No background job executes `docker system prune` or coordinated, safe Docker image pruning.

### 2.2 Diagnostic Recommendation (Operator Advice String)
- **Component**: `CiDiagnosticsAgentService.cs:238-242`.
- **Trigger**: Regular expression match on CI build logs matching `JavaScript heap out of memory`, `exit code: 137`, `Killed`, `out of memory`, or `OOMKilled`.
- **Payload**: Returns a structured diagnostic tuple containing suggested shell commands:
  ```csharp
  new List<string>
  {
      "export NODE_OPTIONS=--max-old-space-size=2048",
      "docker system prune -f"
  }
  ```
- **Execution Boundary**: This command string is purely returned for UI display or operator troubleshooting. It is **NEVER executed automatically** by `CiDiagnosticsAgentService` or any agent runner.

### 2.3 Target Future Behavior (Remediation Master Register MR-17)
- **Owner**: **`MR-17`** (Safe Cleanup & Retention, Linux, P1, Phase 6).
- **Secondary Dependencies**: **`MR-12`** (Atomic Deployment Rollback), **`MR-10`** (Rolling Deployment & Health Gates).
- **Architectural Requirements**:
  1. Safe cleanup must preserve local cache digests for the active release and a minimum of three (3) prior verified releases to enable immediate, zero-network rollback.
  2. Implement an execution mutex preventing cleanup routines from running concurrently with deployment, build push, or rollback operations.
  3. Replace indiscriminate pruning with deployment-aware mark-and-sweep retention via Docker/Registry APIs.
  4. Aggressive automatic `docker system prune` is strictly prohibited because it unconditionally destroys rollback image caches.

### 2.4 Historical Marketing Assertion
- **Claim**: *"Intelligent automated Docker storage cleanup preserving deployment rollback caches."*
- **Cited Path**: `scripts/cleanup-docker.sh`.
- **Status**: **MISLEADING / UNVERIFIED HISTORICAL PROMOTIONAL ASSERTION**.
- **Evidence**:
  1. `scripts/cleanup-docker.sh` does not exist on disk.
  2. Inspected source confirms no automatic Docker pruning execution exists.
  3. The scheduled background service (`DockerCleanupBackgroundService.cs`) calls indiscriminate image pruning with `RemoveAllUnusedImages = true`, which directly destroys rollback capability rather than preserving it.

---

## 3. Master Remediation Register (MR-17) Status Alignment

- **MR-17 Classification**: `PARTIALLY_IMPLEMENTED`.
- **Rationale**:
  - `DockerCleanupBackgroundService.cs` implements real, working database log pruning, application log rotation, and container log truncation.
  - Safe Docker image retention with rollback image protection remains completely unimplemented (`OPEN`).
  - Therefore, the baseline classification `PARTIALLY_IMPLEMENTED` remains accurate and is not changed.
  - The diagnostic suggestion in `CiDiagnosticsAgentService.cs:241` does NOT constitute implementation of MR-17.
