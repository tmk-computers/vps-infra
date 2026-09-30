# Cleanup Capability Epistemic Classification

**Document ID**: `FINAL-C2-04-04-CLASSIFICATION`  
**Phase**: Phase 0 — Final C2-04 Evidence Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: COMPLETE — AUTHORITATIVE & RECONCILED  

---

## 1. Epistemic Separation Framework

To prevent any conflation of diagnostic suggestions, on-demand API endpoints, scheduled background automation, and future target capabilities, all cleanup-related functionality is classified into four distinct epistemic tiers:

```
+---------------------------------------------------------------------------------------+
|                               CLEANUP CAPABILITY TAXONOMY                              |
+---------------------------------------------------------------------------------------+
| 1. Current Evidenced Behavior      | 2. Diagnostic Recommendation                     |
|    - Scheduled daily cleanup cron   |    - Returns "docker system prune -f" string     |
|    - Prunes containers/images/etc.  |    - AI / CI build failure diagnosis (OOM)       |
|    - Truncates logs > 50MB          |    - NEVER automatically executed by engine      |
|    - Deletes DB logs older than 14d |                                                 |
+------------------------------------+--------------------------------------------------+
| 3. Target Future Behavior (MR-17)  | 4. Historical Marketing Assertion                |
|    - Digest-preserving mark/sweep  |    - "Intelligent automated Docker storage       |
|    - Preserves >= 3 rollback images |      cleanup preserving rollback caches"          |
|    - Concurrency locking vs deploy  |    - Status: PARTIALLY TRUE BUT MISLEADING       |
+---------------------------------------------------------------------------------------+
```

---

## 2. Canonical Capability Classification

| Capability | Current Status | Source Evidence |
|---|:---:|---|
| **Automated Docker cleanup** | **IMPLEMENTED / EXISTS** | `DockerCleanupBackgroundService.cs:257-275` (runs daily via cron) |
| **Scheduled execution** | **IMPLEMENTED / EXISTS** | `AddHostedService<DockerCleanupBackgroundService>()` in `Program.cs:359` |
| **Docker CLI pruning** | **IMPLEMENTED / EXISTS** | `MonitoringService.cs:234-323` spawns `System.Diagnostics.Process` |
| **Safe deployment-aware cleanup** | **NOT IMPLEMENTED** | Uncoordinated execution; no deployment mutex in source |
| **Rollback-aware image retention** | **NOT IMPLEMENTED** | Wipes unused images with `-a`; zero rollback digest retention |
| **Known-good release preservation** | **NOT IMPLEMENTED** | No release manifest or digest check before pruning |
| **Deployment/cleanup concurrency protection** | **NOT IMPLEMENTED** | Cleanup and deploy can run concurrently without mutual exclusion |
| **Intelligent mark-and-sweep release retention** | **NOT IMPLEMENTED** | Unimplemented (tracked under MR-17) |

---

## 3. Detailed Capability Breakdown

### 3.1 Current Evidenced Behavior (Static Source Reality)
Verified behavior in tracked source code:
- **Scheduled Background Service**: `DockerCleanupBackgroundService.cs` is registered in `Program.cs:359` via `builder.Services.AddHostedService<DockerCleanupBackgroundService>()`. It runs on a scheduled daily cron loop (default `0 0 3 * * ?` at 3:00 AM IST) and invokes `MonitoringService.CleanupDockerAsync(request)` with `RemoveAllUnusedImages = true` and `CleanSystem = true`.
- **Database Log Retention**: `DockerCleanupBackgroundService.cs:171-227` executes parameterized SQL deleting rows older than 14 days from `SystemLogs`, `DeploymentLogs`, and `ci_build_logs`, and older than 30 days from `DisasterRecoveryLogs`, `JobExecutionLogs`, and `ExceptionLogs`.
- **Filesystem Artifact Pruning**: `DockerCleanupBackgroundService.cs:228-245` deletes CI build artifacts older than 7 days, application log files older than 7 days, mobile intermediate build directories older than 3 days, and crash dumps.
- **Container Log Truncation**: `DockerCleanupBackgroundService.cs:233` and `MonitoringService.cs:262` execute an ephemeral Alpine container (`docker run --rm -v /var/lib/docker/containers:/containers alpine ... truncate -s 0`) targeting JSON log files over 50MB.
- **Docker CLI Pruning Execution**: `MonitoringService.CleanupDockerAsync` (lines 234–323) constructs and executes real Docker CLI commands via `ExecuteCommandWithTimeoutAsync`:
  - `docker container prune -f`
  - `docker image prune -f -a` (when `RemoveAllUnusedImages = true`)
  - `docker network prune -f`
  - `docker system prune -f -a` (when `CleanSystem = true` and `RemoveAllUnusedImages = true`)
  - `docker builder prune -a -f` (when `CleanSystem = true`)
  - local registry garbage collection
- **Absence of Volume Prune**: **No explicit `docker volume prune` command was identified in the inspected current C# source.** Neither `docker volume prune` nor a `CleanVolumes` DTO property exists in `MonitoringService.cs` or `DockerCleanupRequestDto.cs`.

### 3.2 Diagnostic Recommendation (Operator Advice String)
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

### 3.3 Target Future Behavior (Remediation Master Register MR-17)
- **Owner**: **`MR-17`** (Safe Cleanup & Retention, Linux, P1, Phase 6).
- **Secondary Dependencies**: **`MR-12`** (Atomic Deployment Rollback), **`MR-10`** (Rolling Deployment & Health Gates).
- **Architectural Requirements**:
  1. Safe cleanup must preserve local cache digests for the active release and a minimum of three (3) prior verified releases to enable immediate, zero-network rollback.
  2. Implement an execution mutex preventing cleanup routines from running concurrently with deployment, build push, or rollback operations.
  3. Replace indiscriminate pruning with deployment-aware mark-and-sweep retention via Docker/Registry APIs.
  4. Indiscriminate automatic `docker system prune -a` / `docker image prune -a` is prohibited without digest preservation.

### 3.4 Historical Marketing Claim Decomposition
- **Claim**: *"Intelligent automated Docker storage cleanup preserving deployment rollback caches."*
- **Decomposition**:
  - **Automated**: **TRUE** (Runs automatically on scheduled daily loop via `DockerCleanupBackgroundService`).
  - **Docker storage cleanup**: **TRUE** (Actively executes real Docker CLI prune commands).
  - **Intelligent / safe**: **FALSE** (Lacks mark-and-sweep intelligence or concurrency safety).
  - **Preserves rollback caches**: **FALSE** (Hardcodes `RemoveAllUnusedImages = true`, purging all non-running images).
- **Verdict**: **PARTIALLY TRUE BUT MATERIALLY MISLEADING**.

---

## 4. Master Remediation Register (MR-17) Status Alignment

- **MR-17 Classification**: `PARTIALLY_IMPLEMENTED`.
- **Rationale**:
  - Implemented: `DockerCleanupBackgroundService.cs` implements real scheduled background execution, database log pruning, application log rotation, container log truncation, and basic Docker CLI prunes.
  - Missing: Safe rollback-aware image retention preserving verified release digests and concurrency locks against active deployments remain completely unimplemented (`OPEN`).
  - Therefore, the baseline classification `PARTIALLY_IMPLEMENTED` is fully supported by source reality. Total MR count remains exactly **37**.
