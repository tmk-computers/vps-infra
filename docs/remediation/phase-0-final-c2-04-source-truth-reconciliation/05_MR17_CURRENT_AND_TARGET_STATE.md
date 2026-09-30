# 05 MR-17: Current State, Target Contract, and Safety Risk Analysis

**Document ID**: `RECON-C2-04-05-MR17-CONTRACT`  
**Phase**: Phase 0 — C2-04 Final Source-Truth Reconciliation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: COMPLETE — AUTHORITATIVE  

---

## 1. Governance & Master Remediation Item Classification

- **Master Remediation ID**: **`MR-17`**
- **Title**: Safe Cleanup & Retention
- **Target OS**: Linux
- **Priority**: **P1**
- **Target Phase**: Phase 6
- **Current Baseline Status**: **`PARTIALLY_IMPLEMENTED`**
- **Related Historical Findings**: Codex **F13**, Antigravity **DEF-16**, **DEF-21**

### Invariant Status Rule:
MR-17 must **NOT** be marked:
- `OPEN` (because automated daily cleanup, database pruning, container log truncation, and Docker CLI pruning already exist);
- `IMPLEMENTED` or `VERIFIED` (because safe rollback-aware retention and deployment concurrency locking are missing).

Its canonical classification strictly remains:

# `PARTIALLY_IMPLEMENTED`

The Master Remediation register item count strictly remains **37** (`33 OPEN + 3 PARTIALLY_IMPLEMENTED + 1 IMPLEMENTED_NOT_VERIFIED = 37`).

---

## 2. Current-State Implementation vs. Missing Gaps

```
+-----------------------------------------------------------------------------------------+
|                                    MR-17 SCOPE BOUNDARY                                  |
+-----------------------------------------------------------------------------------------+
| IMPLEMENTED PORTIONS (Current Source)    | MISSING PORTIONS (Phase 6 Remediation Target) |
+------------------------------------------+-----------------------------------------------+
| 1. ASP.NET Core IHostedService Engine    | 1. Release Manifest Image Digest Awareness     |
| 2. Daily Cron Scheduler (03:00 AM IST)   | 2. Active Release Protection                  |
| 3. Database Log Pruning (14-30 days)     | 3. Minimum 3 Prior Verified Release Retention |
| 4. Filesystem Artifact Pruning (7 days)  | 4. Deployment Concurrency Mutex Lock          |
| 5. Container JSON Log Truncation (>50MB) | 5. API-Driven Mark-and-Sweep Garbage Collect  |
| 6. Docker CLI Container/Image/Net Prune  | 6. Failure-Safe Rollback Cache Verification   |
+-----------------------------------------------------------------------------------------+
```

---

## 3. Important Current-State Safety Risk Disclosure

In accordance with Section 13 of the mandate, the following operational risk is formally documented in the Phase 0 baseline:

> ### ⚠️ SAFETY ADVISORY: Aggressive Unused-Image Pruning Destroys Rollback Caches
>
> In the current implementation ([`DockerCleanupBackgroundService.cs:271`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs#L271)), the background cleanup service unconditionally passes:
> ```csharp
> RemoveAllUnusedImages = true
> ```
> This causes `MonitoringService.CleanupDockerAsync` to append the `-a` argument when executing `docker image prune -f -a` and `docker system prune -f -a`.
>
> **Consequences**:
> 1. Under Docker CLI rules, any image not associated with an actively running container is considered "unused."
> 2. The immediate prior release and historical rollback targets are non-running images.
> 3. Consequently, the daily 03:00 AM cleanup deletes all inactive release images from the host.
> 4. If a newly deployed release fails after 03:00 AM, an operator attempting an atomic local rollback will find the cached layers destroyed, forcing an emergency network pull from the external registry or failing outright if external connectivity is impaired.
> 5. Furthermore, there is zero concurrency protection: if `RunDockerCleanupAsync` triggers while `DeployService.cs` is pulling or creating containers, layers can be pruned mid-deployment.

**Governance Directive**: Do NOT modify runtime code during Phase 0 (`Runtime product code changes: NONE`). This defect is properly owned and tracked by **MR-17** for remediation during Phase 6.

---

## 4. MR-17 Target Architectural Contract (Phase 6 Implementation Scope)

When MR-17 is implemented in Phase 6, it shall satisfy the following comprehensive specification:

### 4.1 Release-Aware Image Retention Contract
1. **Active Release Protection**: The container image digest currently running in production must never be pruned under any circumstances.
2. **Rollback Set Retention**: A minimum of three (3) prior successfully verified release image digests must be explicitly protected from pruning.
3. **Registry Digest Querying**: Cleanup routines must query the internal deployment metadata repository or local registry to determine the protected set of image SHA-256 digests before issuing any deletion commands.

### 4.2 Mark-and-Sweep Garbage Collection
1. Pruning must be executed via structured Docker Engine APIs or selective digest-based CLI calls (`docker image rm <digest>`) targeting only verified stale images.
2. Blanket invocation of `docker image prune -a` and `docker system prune -a` in automated background services is strictly prohibited.

### 4.3 Concurrency Coordination & Locking
1. Implement a distributed or in-process execution mutex (`CleanupDeploymentLock`).
2. The cleanup service must acquire the mutex before initiating storage reclamation.
3. If an active deployment, build push, or rollback is in progress, the cleanup run must be safely deferred.
4. Active deployments must acquire the same lock to prevent background cleanup from running mid-deploy.

### 4.4 Observability, Auditability, and Failure-Safe Execution
1. Every pruned image, container, and volume must be recorded in `AuditLogs` with exact digest, tag, and reclaimed byte count.
2. Cleanup failure must never crash the service or corrupt state.
3. If free disk space remains above 20%, aggressive pruning must be avoided.
