# 05 EVIDENCE ACCURACY & CITATION CORRECTIONS

**Document ID**: `FINAL-CORRECTION-05-EVIDENCE-ACCURACY`  
**Phase**: Phase 0 — Final Codex Closure Surgical Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex C2-04 (`06_VERIFIER_AND_EVIDENCE_GATE.md:42-62`, `07_FINAL_FINDINGS_REGISTER.md:43-48`)  
**Status**: COMPLETE — ALL EVIDENCE DEFECTS RECONCILED  

---

## 1. Executive Summary

This document addresses all specific evidence accuracy, source citation, and taxonomy defects retained under **`C2-04`** by the Codex Final Closure Gate.

In accordance with Section 19 of the directive:
- Historical immutable audit reports are preserved unchanged.
- All active authoritative and final-closure artifacts have been surgically updated.
- Present static implementation reality, target architecture contracts, planned test criteria, and executed checks are strictly distinguished.

---

## 2. Table of Specific Evidence Corrections

| Item # | Artifact & Location | Retained Error Identified by Codex | Correct Fact / Authoritative Reading | Correction Applied in Active Documentation |
|:---:|---|---|---|---|
| **1** | [`05_EVIDENCE_TRUTH_CORRECTIONS.md:48-52`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/05_EVIDENCE_TRUTH_CORRECTIONS.md#L48-L52) | F02 was described as leaked Google key / MR-03; F15 was described as background service scheduling / MR-18. | Canonical F02 is published signing defaults (MR-02, MR-36); F03 is leaked Google key (MR-03); F15 is human approval (HITL) drift and replay (MR-08). | Updated [`05_EVIDENCE_TRUTH_CORRECTIONS.md:48-52`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/05_EVIDENCE_TRUTH_CORRECTIONS.md#L48-L52) to accurately define F02 as signing defaults (MR-02/MR-36), F03 as leaked key (MR-03), and F15 as HITL drift/replay (MR-08). |
| **2** | [`15_DOCUMENTATION_TRUTH_MATRIX.md:38`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md#L38) | Cites nonexistent repository path `scripts/cleanup-docker.sh` and false attribution of active pruning execution to `MonitoringService.cs:213`. | `scripts/cleanup-docker.sh` does not exist in repository; `MonitoringService.cs:213` logs container status errors, not pruning; actual cleanup implementation resides in `DockerCleanupBackgroundService` calling `MonitoringService.CleanupDockerAsync`, which executes real Docker CLI prune commands. However, because it passes `RemoveAllUnusedImages = true`, it destroys rollback image caches and lacks deployment-aware retention. | Updated [`15_DOCUMENTATION_TRUTH_MATRIX.md:38`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md#L38) to classify automatic cleanup as partially true but materially misleading, documenting that automated cleanup exists but destroys rollback caches. |
| **3** | [`06_PHASE_0_5_SCHEMA_INVENTORY.md:49-54`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/06_PHASE_0_5_SCHEMA_INVENTORY.md#L49-L54) | Asserted migrations stop at `InitialCreate`, raw DDL is in a catch block, and asserted deployed history from source. | 13 versioned migrations exist in `devops-manager/api/Migrations/` up through `20260831080000_AddDatabaseServerToProjectService.cs`. Raw DDL in `DataSeeder.cs:46-168` is inside a `try` block with a swallowed `catch { }` block. Deployed history was not queried. | Updated [`06_PHASE_0_5_SCHEMA_INVENTORY.md:49-54`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/06_PHASE_0_5_SCHEMA_INVENTORY.md#L49-L54) to reflect all 13 migrations and the swallowed catch block. Explicitly noted deployed history was not queried. |
| **4** | [`03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md:30-34`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md#L30-L34) | Stated `IsActive` was merely inherited across entities without noting `Product.cs` redeclaration. | `Product.cs:12` explicitly redeclares `public bool IsActive { get; set; } = true;` while `ProjectService.cs` inherits `IsActive` from `BaseEntity`. Neither entity adds a new maintenance `IsActive` column; `IsActive` pre-exists in baseline migrations. | Updated [`03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md:30-34`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md#L30-L34) to explicitly state `Product.cs` redeclares `IsActive` while `ProjectService.cs` inherits it. |
| **5** | [`07_FINAL_AUTHORITATIVE_CONSISTENCY_SCAN.md:42`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/07_FINAL_AUTHORITATIVE_CONSISTENCY_SCAN.md#L42) | Retained a row stating "Redis is uncertified for Gate A; PostgreSQL 16 is exclusive." | Contradicts the Redis Architecture Amendment establishing Redis 7 as a first-class production caching component. | Updated [`07_FINAL_AUTHORITATIVE_CONSISTENCY_SCAN.md:42`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/07_FINAL_AUTHORITATIVE_CONSISTENCY_SCAN.md#L42) to: `Mandatory Redis denylist is superseded; multi-tiered revocation pipeline (Local Cache -> Redis 7 -> PostgreSQL) enforced with PostgreSQL as sole durable authority and Redis as first-class cache.` |
| **6** | [`02_FINAL_CANDIDATE_BASELINE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/02_FINAL_CANDIDATE_BASELINE.md) | Old candidate SHAs still labeled final alongside re-freeze placeholders. | Previous candidate SHAs were superseded by the Redis Architecture Amendment, and are now superseded by this surgical correction. | Recorded clear commit lineage: Historical Baselines (`780e8b4f` / `36354a32`) $\rightarrow$ Codex Re-Gate Candidate (`17486949` / `76b4bcb9`) $\rightarrow$ Post-Redis-Amendment Candidate (`dea86733` / `3862f548`) $\rightarrow$ New Final Candidate. |

---

## 3. Epistemic Classification Framework Re-Affirmed

All statements across Phase 0 documentation continue to adhere to the four-way epistemic taxonomy:
1. **Target Architecture / Specification**: Forward-looking requirements formulated with `MUST`, `SHALL`, and `REQUIRED`.
2. **Current Static Source Reality**: Existing code in tracked repositories, including static defects (e.g. `"SuperCiSecretKey123!"` in `tmk-iis-agent.ps1:21`).
3. **Planned Test Criteria**: Defined gate acceptance scenarios (e.g. 6 Redis Gate-A scenarios, 15 Phase 1 negative criteria).
4. **Executed Checks**: Verifications executed during Phase 0 audit (`verify-baseline-integrity.ps1`, in-memory fault injections, byte hashes). Zero runtime benchmarks or live database mutations are claimed as executed evidence.
