# 06 MR-17, Rollback Safety & Marketing Claim Classification

**Document ID**: `REVIEW-R6-06-MR17-MARKETING`  
**Role**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-30  

---

## 1. Rollback Safety Analysis (Section 11 Compliance)

Inspection of the actual Docker prune logic in [`MonitoringService.cs:271-312`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs#L271-L312) when called by `DockerCleanupBackgroundService`:

1. **Running Containers Protected**: Standard Docker behavior prevents running containers and their directly attached images from being removed by `docker image prune -a` or `docker container prune`.
2. **Previous Known-Good Release**: **UNPROTECTED**. Any image not currently associated with an active running container is classified by Docker as "unused".
3. **Rollback Image Digests**: **UNPROTECTED**. Docker CLI prune commands have no awareness of release manifests or rollback targets. Executing `docker image prune -a` and `docker system prune -a` wipes all unattached images.
4. **Minimum Retention Count**: **MISSING**. There is no retention count logic (e.g. keeping $\ge 3$ prior releases).
5. **Concurrent Deploy/Build/Rollback Protection**: **MISSING**. There is no execution mutex between `DockerCleanupBackgroundService` and `DeployService.cs`. A background cleanup executing during a deployment or rollback can delete layers actively needed for container creation.
6. **Defect Characterization**: Codex F13, Antigravity DEF-16, and MR-17 accurately describe this defect:
   > *"Intelligent automated Docker storage cleanup preserving deployment rollback caches is false. Current cleanup indiscriminately removes inactive images, destroying local rollback capability."*

---

## 2. Volume Safety Analysis (Section 12 Compliance)

1. **`docker volume prune` Execution**:
   - As established in document 04, `docker volume prune` does **NOT** exist in `MonitoringService.cs` or `DockerCleanupBackgroundService.cs`.
   - The platform never executes `docker volume prune` automatically or via its API.
2. **Volume Safety Implication**:
   - Because `docker volume prune` is never executed, unattached persistent volumes (e.g. database data volumes, uploaded assets) are **not** wiped by the cleanup service.
   - However, orphaned sandbox databases are explicitly dropped via SQL in `CleanupStaleSandboxDatabasesAsync()` (`DROP DATABASE IF EXISTS`).
3. **Documentation Correction Needed**:
   - Developer documentation asserting that `MonitoringService.CleanupDockerAsync` executes `docker volume prune -f` is inaccurate and should be corrected (Finding R2-01).

---

## 3. Current-State Classification (Section 13 Compliance)

Evaluating the five potential outcomes defined in Section 13:

| Option | Candidate Classification | Source Code Evidence Support |
|:---:|---|---|
| **A** | No automatic Docker cleanup exists. | **REJECTED**: `DockerCleanupBackgroundService` runs automatically on a daily cron loop and calls `CleanupDockerAsync`. |
| **B** | Automatic Docker cleanup exists, but only selected cleanup operations execute. | **PARTIALLY TRUE, BUT INSUFFICIENT**: Does not convey the aggressive nature of the image wipe. |
| **C** | **Automatic Docker cleanup exists and includes aggressive unused-image pruning.** | **CONFIRMED & ADOPTED**: `DockerCleanupBackgroundService` passes `CleanContainers = true`, `CleanImages = true`, `CleanNetworks = true`, `CleanSystem = true`, and `RemoveAllUnusedImages = true`. This executes `docker container prune -f`, `docker image prune -f -a`, `docker network prune -f`, `docker system prune -f -a`, and `docker builder prune -a -f`. |
| **D** | Cleanup exists but is disabled/unreachable by default. | **REJECTED**: Unconditionally registered in `Program.cs:359` via `builder.Services.AddHostedService<DockerCleanupBackgroundService>()`. |
| **E** | Other classification. | **SUPERSEDED** by Option C. |

### Definitive Classification:
# Classification C: Automatic Docker cleanup exists and includes aggressive unused-image pruning.

---

## 4. Deconstruction of Historical Marketing Claim (Section 14 Compliance)

The historical claim states:
> *"Intelligent automated Docker storage cleanup preserving deployment rollback caches"*

Deconstructed into its four component assertions:

| Component | Assessment | Source Reality |
|---|:---:|---|
| **1. Automated** | **TRUE** | Runs automatically on a scheduled daily background loop via `DockerCleanupBackgroundService` registered as an `IHostedService` in `Program.cs:359`. |
| **2. Docker Storage Cleanup** | **TRUE** | Actively executes `docker container prune -f`, `docker image prune -f -a`, `docker network prune -f`, `docker system prune -f -a`, `docker builder prune -a -f`, and container log truncation. |
| **3. Intelligent / Safe** | **FALSE** | Lacks mark-and-sweep intelligence, registry metadata synchronization, concurrency locks against deployments, and volume protection allowlists. |
| **4. Rollback-Cache Preservation** | **FALSE** | Explicitly passes `RemoveAllUnusedImages = true`, causing Docker to purge all non-running images and destroying the local image cache required for fast rollback. |

### Overall Marketing Claim Verdict:
**MISLEADING**. While automation and Docker cleanup commands exist, the claim of "intelligence" and "preserving rollback caches" is completely false. The current implementation does the exact opposite: it indiscriminately destroys rollback caches.

---

## 5. MR-17 Status Verification (Section 16 Compliance)

- **MR Item**: **`MR-17`** (Safe Cleanup & Retention, Linux, P1, Phase 6).
- **Recorded Status**: **`PARTIALLY_IMPLEMENTED`**.
- **Independent Determination**:
  The status **`PARTIALLY_IMPLEMENTED`** is **sound and fully supported by source code**.
  - *Implemented aspects*: Scheduled background host service, database log pruning (SystemLogs, DeploymentLogs, ci_build_logs), container JSON log truncation (>50MB), and basic Docker CLI prune execution.
  - *Missing / Unimplemented aspects*: Digest-preserving mark-and-sweep cleanup, retaining $\ge 3$ verified release image digests, and concurrency protection during deployment/rollback.
- **MR Count**: Remains exactly **37** (`33 OPEN + 3 PARTIALLY_IMPLEMENTED + 1 IMPLEMENTED_NOT_VERIFIED = 37`).
