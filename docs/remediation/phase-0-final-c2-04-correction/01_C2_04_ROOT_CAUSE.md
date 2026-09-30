# C2-04 Root Cause Analysis & Historical Reviewer Reconciliation

**Document ID**: `FINAL-C2-04-01-ROOT-CAUSE`  
**Phase**: Phase 0 — Final C2-04 Evidence Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: COMPLETE — RESOLVED  

---

## 1. Executive Summary

During the Phase 0 Targeted Final Re-Gate (`docs/remediation/phase-0-codex-targeted-final-regate/`), Codex verified and approved the closure of:
- **`CG-C1-01`**: Revocation visibility contract, Revocation Effective Point invariant, zero authorization grace period, and deterministic `DENY` semantics (**PASS**);
- **`FR-C2-01`**: Elimination of all supplementary `SSL Mode=Require;Trust Server Certificate=false` connection string references in favor of strict `SSL Mode=VerifyFull` (**PASS**);
- **Architectural Invariants**: Redis 7 first-class status with PostgreSQL sole durable authority, AI Workforce boundary, Dual-OS commercial parity, and verifier mechanics (**PASS**);
- **Runtime Scope**: Zero runtime product code modifications (**PASS**).

However, Codex returned **`PHASE 0 CODEX TARGETED FINAL RE-GATE: FAIL`** citing a single unresolved evidence accuracy defect:
> **Finding `C2-04` (C2 — Unresolved)**:
> In correcting the nonexistent `scripts/cleanup-docker.sh` citation in [`15_DOCUMENTATION_TRUTH_MATRIX.md:38`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md#L38), the Developer attributed active Docker pruning to `MonitoringService.cs:213`, asserting that this location issues `docker system prune -a`.
> Direct inspection of `MonitoringService.cs:213` reveals that it merely logs a warning on Docker status inquiry failure (`_logger.LogWarning("Failed to get docker status for {Container}: {Msg}", service.ServiceName, ex.Message);`).
> Furthermore, the only occurrence of `docker system prune` in tracked source code is at `devops-manager/api/Infrastructure/Services/AI/CiDiagnosticsAgentService.cs:241`, where `"docker system prune -f"` is merely a suggested remediation command string returned to an operator for build Out-Of-Memory (OOM) failures, NOT an actively executed cleanup implementation.

---

## 2. Root Cause Analysis

### 2.1 The Original Citation Flaw
Historically, marketing and early documentation claimed the existence of:
> *"Intelligent automated Docker storage cleanup preserving deployment rollback caches."*

This claim pointed to a shell script at `scripts/cleanup-docker.sh`. During baseline audits, it was discovered that `scripts/cleanup-docker.sh` does not exist in either repository.

### 2.2 The Developer's Erroneous Attribution
In attempting to identify where Docker cleanup actually existed in C# code, the Developer referenced `MonitoringService.cs:213` and asserted:
> `active pruning logic resides in MonitoringService.cs:213 (which issues docker system prune -a)`

This statement contained two distinct factual errors:
1. **Wrong Line Anchor**: Line 213 of `MonitoringService.cs` is inside `GetProjectStatusAsync` and is an exception handler:
   ```csharp
   catch (Exception ex)
   {
       _logger.LogWarning("Failed to get docker status for {Container}: {Msg}", service.ServiceName, ex.Message);
       statusDTO.Status = "Error";
   }
   ```
   It has nothing to do with pruning.
2. **False Attribution to Line 213**: Line 213 does not execute any command. Line 213 was erroneously cited as Docker cleanup implementation. While `MonitoringService.CleanupDockerAsync` (lines 234–323) dynamically constructs and executes Docker CLI prune commands (including `docker system prune -f -a` when `CleanSystem` and `RemoveAllUnusedImages` are true, as invoked daily by `DockerCleanupBackgroundService`), line 213 itself is merely error logging in `GetProjectStatusAsync`.

### 2.3 The Historical Reviewer Error
As required by Section 9 of the prompt, this report explicitly documents the historical Reviewer error:
> **The previous Developer correction and targeted Reviewer report (`docs/remediation/phase-0-final-codex-correction-review/`) incorrectly treated the `MonitoringService` line 213 reference as evidence of active Docker pruning (`docker system prune -a`).**
> **Conversation 2 (Independent Reviewer) failed to independently inspect `MonitoringService.cs:213` against the running candidate and repeated the Developer's incorrect line citation in `03_C2_04_EVIDENCE_ACCURACY_REVIEW.md:42`.**
> **Codex independently inspected the candidate source code, disproved that line attribution, and failed the gate.**
> **Per governance rules, historical Reviewer and Codex audit artifacts remain immutable post-freeze audit records, while the authoritative Phase 0 baseline documentation is now reconciled to reflect actual canonical source truth.**

---

## 3. Authoritative Source Reality

Direct static source inspection across `vps-infra` and `vps-infra-server` establishes the following facts:

1. **Automatic Docker Cleanup Exists**:
   Automatic Docker cleanup **EXISTS** and is executed automatically by `DockerCleanupBackgroundService` (an `IHostedService` registered in `Program.cs:359`) on a scheduled daily cron (default 3:00 AM IST) calling `MonitoringService.CleanupDockerAsync`.
2. **MonitoringService Functionality**:
   - `MonitoringService.cs:195-218`: Gathers container status via `docker ps` and logs a warning on failure at line 213. It does not execute pruning.
   - `MonitoringService.cs:234-323` (`CleanupDockerAsync`): Core cleanup implementation. Constructs and executes Docker CLI commands via `ExecuteCommandWithTimeoutAsync` spawning `System.Diagnostics.Process`. When invoked by `DockerCleanupBackgroundService`, it executes:
     - `docker container prune -f`
     - active container log truncation (`truncate -s 0`)
     - `docker image prune -f -a`
     - `docker network prune -f`
     - `docker system prune -f -a`
     - `docker builder prune -a -f`
     - local registry garbage collection
   - **No explicit `docker volume prune` command was identified in the inspected current C# source.** Neither `docker volume prune` nor a `CleanVolumes` DTO property exists in `MonitoringService.cs` or `DockerCleanupRequestDto.cs`.
3. **Diagnostic Suggestion Only**:
   - `CiDiagnosticsAgentService.cs:241`: Returns a list of suggestion strings to an operator for build OOM diagnosis:
     ```csharp
     return ("DockerBuildOOM", "Build process killed by host OOM killer (Exit 137).", fix, new List<string>
     {
         "export NODE_OPTIONS=--max-old-space-size=2048",
         "docker system prune -f"
     });
     ```
     This string is displayed in diagnostic UI or logs; it is **never executed** by the service.
4. **Current Safety Status (MR-17 / Codex F13)**:
   - The current automatic cleanup is **indiscriminate, aggressive, and not rollback-aware**. Passing `RemoveAllUnusedImages = true` issues `-a` flags that purge all non-running container images, completely wiping local rollback image caches. Safe rollback-aware retention and deployment concurrency locking are **NOT IMPLEMENTED** (owned by **MR-17**).

---

## 4. Resolution Plan

1. Correct [`15_DOCUMENTATION_TRUTH_MATRIX.md:38`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md#L38) to remove all false attributions to `MonitoringService.cs:213` and `docker system prune -a`, classifying automatic cleanup as an unverified promotional assertion.
2. Update [`02_MASTER_REMEDIATION_REGISTER.md:49`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md#L49) and [`03_HISTORICAL_FINDING_TRACEABILITY.md:38`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md#L38) to cite `MonitoringService.cs:234-315` rather than `:213`.
3. Reconcile all secondary references across the `phase-0-final-codex-correction` dossier.
4. Establish clear epistemic boundaries separating Current Evidenced Behavior, Diagnostic Recommendations, Future Target Behavior (MR-17), and Historical Marketing Assertions.
5. Add a dedicated mechanical check to `verify-baseline-integrity.ps1` blocking false pruning attributions.
