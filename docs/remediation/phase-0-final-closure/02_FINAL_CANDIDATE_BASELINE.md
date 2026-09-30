# 02 FINAL CANDIDATE BASELINE & DRIFT RECONCILIATION

**Document ID**: `FINAL-CLOSURE-02-CANDIDATE-BASELINE`  
**Phase**: Phase 0 — Final Codex Closure Corrections  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: FROZEN AUDIT CANDIDATE BASELINE  

---

## 1. Executive Summary

This document establishes the definitive candidate baseline decision for Phase 0. 

A process discrepancy occurred during earlier gate reviews where documentation continued to reference historical implementation baseline commits (`780e8b4f` and `36354a32`), while Codex audited the actual HEAD of `main` in both repositories (`17486949` and `76b4bcb9`). 

This document reconciles that difference, accounts for every single file changed between the historical baselines and current candidate HEADs, provides an explicit disposition for all non-documentation additions, and establishes the frozen immutable audit candidate.

---

## 2. Repository Commit Alignment & Freeze Decision

| Repository | Historical Implementation Baseline | Candidate Main HEAD Audited by Codex | Uncommitted Worktree Delta | Final Frozen Phase 0 Candidate SHA |
|---|---|---|---|---|
| **vps-infra** | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `174869490596c1eee07366590dbd8e1c46df5b71` | Clean (0 uncommitted files) | `174869490596c1eee07366590dbd8e1c46df5b71` |
| **vps-infra-server** | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `76b4bcb97dda098ff15a4fc9be4844746b6989be` | Clean (Codex audit reports untracked) | `76b4bcb97dda098ff15a4fc9be4844746b6989be` |

### Candidate Baseline Decision:
The candidate baseline audited by Codex (`17486949` for `vps-infra` and `76b4bcb9` for `vps-infra-server`) is formally adopted as the **Authoritative Phase 0 Candidate Baseline**.

---

## 3. Comprehensive File-by-File Delta Classification

### 3.1 `vps-infra-server` Delta: Historical `36354a32` $\rightarrow$ Candidate HEAD `76b4bcb9`

Every file added or modified between `36354a32` and `76b4bcb9` is accounted for below:

| Path | Category | Classification Details |
|---|---|---|
| `docs/remediation/phase-0/*` | **Documentation** | Authoritative Phase 0 baseline architecture artifacts (17 files + final report). |
| `docs/remediation/phase-0-codex-remediation/*` | **Documentation** | Codex Gate R1 remediation dossier artifacts. |
| `docs/remediation/phase-0-codex-regate-remediation/*` | **Documentation** | Codex Re-Gate R2 remediation dossier artifacts. |
| `docs/remediation/phase-0-review/*` | **Documentation** | Antigravity Conversation 2 review artifacts. |
| `docs/remediation/phase-0-review-r3/*` | **Documentation** | Independent Review R3 audit artifacts. |
| `docs/remediation/phase-0-review-r4/*` | **Documentation** | Independent Review R4 audit artifacts. |
| `docs/remediation/phase-0-codex-gate/*` | **Documentation** | Historical Codex Gate audit artifacts. |
| `docs/remediation/phase-0-codex-regate/*` | **Documentation** | Historical Codex Re-Gate audit artifacts. |
| `scripts/verify-baseline-integrity.ps1` | **Audit/Governance Tooling** | Mechanical cross-repo hash, traceability, and forbidden phrase verifier. |
| `scripts/mirror-to-infra.ps1` | **Audit/Governance Tooling** | Automation script to mirror documentation to `vps-infra`. |

**Summary for `vps-infra-server`**:
- **Product / Runtime Implementation Changes**: Exactly **0 files (0 bytes)**.
- **Database Provisioning Changes**: Exactly **0 files (0 bytes)**.
- **Configuration Changes**: Exactly **0 files (0 bytes)**.
- **Test Code Changes**: Exactly **0 files (0 bytes)**.
- **Audit / Governance & Documentation Changes**: All delta files.

---

### 3.2 `vps-infra` Delta: Historical `780e8b4f` $\rightarrow$ Candidate HEAD `17486949`

Every file added or modified between `780e8b4f` and `17486949` is accounted for below:

| Path | Category | Classification Details |
|---|---|---|
| `docs/remediation/*` | **Documentation** | Mirrored documentation dossiers from `vps-infra-server`. |
| `scripts/verify-baseline-integrity.ps1` | **Audit/Governance Tooling** | Mirrored mechanical verification script. |
| `db/postgres/create-readonly-analyst.sh` | **Database Provisioning Tooling** | Added in commit `10a2e77` (Avadhut Kore). Helper script provisioning read-only analyst account for `clever_farmer_uat`. |

**Summary for `vps-infra`**:
- **Product / Runtime Implementation Changes**: Exactly **0 files (0 bytes)**.
- **Configuration Changes**: Exactly **0 files (0 bytes)**.
- **Test Code Changes**: Exactly **0 files (0 bytes)**.
- **Operational Database Provisioning Tooling**: Exactly **1 file** (`db/postgres/create-readonly-analyst.sh`).
- **Audit / Governance & Documentation Changes**: All other delta files.

---

## 4. Operational Database Provisioning Script Disposition

- **File**: `vps-infra/db/postgres/create-readonly-analyst.sh` (commit `10a2e77c068ef70941d55d14a5e2d560c3fcf6c0`).
- **Disposition Selected**: **Option A — Include in Phase 0 Candidate Baseline**.
- **Justification**:
  1. The script was authored directly by the repository owner (`Avadhut Kore`) on `main` to facilitate UAT read-only database inspection.
  2. Deleting legitimate repository work merely to manufacture an artificial "clean diff" is strictly rejected by governance standards.
  3. Rather than disguising or ignoring the file, it is explicitly classified as **operational database tooling drift relative to historical baseline `780e8b4f`**.
  4. It is formally mapped to **MR-02** (Secret Storage) and **MR-05** (Least-Privilege Database Roles).
  5. Its security risks (embedded fallback password in line 11, execution via superuser `docker exec`) are comprehensively analyzed in `04_INFRA_DATABASE_PROVISIONING_DISPOSITION.md`, and mandatory credential remediation is assigned to Phase 1.

---

## 5. Candidate Immutability Mandate

From this point forward:

1. `PHASE_0_FINAL_CANDIDATE_INFRA_SHA` = `174869490596c1eee07366590dbd8e1c46df5b71`
2. `PHASE_0_FINAL_CANDIDATE_SERVER_SHA` = `76b4bcb97dda098ff15a4fc9be4844746b6989be`

### Freeze Rule:
**DO NOT MODIFY, COMMIT, OR MERGE CHANGES TO MAIN IN EITHER REPOSITORY UNTIL THE INDEPENDENT REVIEWER AND CODEX FINAL AUDIT GATE COMPLETE.**

If ongoing product development occurs, it must take place on dedicated feature branches isolated from `main`.
