# Evidence Integrity and Precision Reconciliation

**Document ID**: `REGATE-REMED-08-EVIDENCE-INTEGRITY`  
**Phase**: Phase 0 — Codex Focused Re-Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex Re-Gate C2-04 (`06_REGATE_FINDINGS_REGISTER.md:90-98`), C3-01 (`06_REGATE_FINDINGS_REGISTER.md:100-108`)  
**Status**: COMPLETE — AUTHORITATIVE AND RECONCILED  

---

## 1. Executive Summary

This document resolves findings **`C2-04`** and **`C3-01`** by performing a rigorous evidence integrity audit across the repository. It corrects source citations, static code descriptions, unvalidated timing assertions, and establishes the mechanical validation tooling for semantic ID and mirror verification.

---

## 2. Distinction Between Historical Evidence, Authoritative Baseline, and Dossiers

To eliminate confusion between historical audit findings and current architectural specifications, documents are strictly classified into three tiers:

```
┌────────────────────────────────────────────────────────────────────────┐
│ Tier 1: Historical Immutable Audit Evidence (Read-Only)                │
│ - findings.json (Initial Audit Baseline)                               │
│ - docs/remediation/phase-0-review/ (Original Reviewer FAIL)            │
│ - docs/remediation/phase-0-codex-gate/ (Codex Audit Gate FAIL)         │
│ - docs/remediation/phase-0-review-r3/ (Reviewer R3 Audit)               │
│ - docs/remediation/phase-0-codex-regate/ (Codex Focused Re-Gate FAIL)   │
│ RULE: MUST NEVER BE MODIFIED. PRESERVES HISTORICAL RECORD.             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Tier 2: Authoritative Current Phase 0 Architecture Baseline            │
│ - docs/remediation/phase-0/*.md (All 18 Documents)                     │
│ RULE: THE SOLE CURRENT TRUTH. MUST CONTAIN ZERO CONTRADICTIONS.        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Tier 3: Remediation Dossiers & Rationale                               │
│ - docs/remediation/phase-0-codex-remediation/                         │
│ - docs/remediation/phase-0-codex-regate-remediation/                  │
│ RULE: EXPLAINS RATIONALE AND RESOLUTION. FULLY SYNCHRONIZED WITH TIER 2│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Evidence Precision Corrections (C2-04)

### 3.1 Static Code Citations and Path Verification
All citations referencing source code files and scripts have been verified against active workspace files:
1. **`DataSeeder.cs:46-168`**: Correctly described as containing raw SQL `ALTER TABLE` and `CREATE TABLE IF NOT EXISTS` queries in a try/catch block attempting to create missing columns and tables.
2. **`Program.cs:417`**: Correctly cites the startup sequence where `Database.Migrate()` is followed by `DataSeeder.SeedData()`.
3. **`DeployService.cs:602`**: Correctly cites the absence of HTTP readiness verification before marking deployment success.
4. **`scripts/upgrade-client.sh:170`**: Correctly cites upgrade completion declared before running container health checks.
5. **`scripts/tmk-iis-agent.ps1:294-299`**: Correctly cites the IIS deployment error catch block where failures were suppressed.

### 3.2 Time Estimates Labeled as Operational Targets
All time estimates and performance metrics that have not yet been measured in a certified benchmark run have been explicitly reclassified as **operational targets for subsequent qualification**, not certified guarantees:
- **Application Rollback Latency**: Described as an operational target of 2 to 5 seconds, to be measured and validated during Phase 2 live staging tests.
- **Connection Handover Latency**: Described as an operational target of $< 200$ms for HTTP keep-alive requests during cutover.
- **Recovery Time Objective (RTO)**: Described as an operational target of $\le 30$ minutes for full 10 GB database restoration on a replacement VM, to be benchmarked during Phase 5 restore drills.
- **Recovery Point Objective (RPO)**: Described as operational targets of 24 hours (scheduled daily) and 1 hour (pre-deployment).

### 3.3 Removal of Unsupported Cryptographic Claims
- Unsupported claims that `pg_restore --list` decompresses or validates compressed data blocks have been permanently replaced with precise statements of custom archive header and Table of Contents (TOC) parseability.
- Actual database and row-level integrity is explicitly stated as proven exclusively through scheduled restore drills.

---

## 4. Mechanical Validation & Verification Script (C3-01)

Codex finding `C3-01` noted that earlier integrity scripts verified only count totals and selected mirrors, without checking distinct-ID sets, detecting replacement IDs, or performing reverse file checks.

### 4.1 Enhanced Validation Capabilities
The governance script `scripts/verify-baseline-integrity.ps1` has been updated to execute the following mechanical checks:
1. **Exact Set Comparison**:
   - Compares the set of Master Remediation IDs against the exact set $\{\text{MR-01} \dots \text{MR-37}\}$ (asserting count = 37, no duplicates, no missing IDs, and no fabricated IDs).
   - Compares the set of Codex historical findings against $\{\text{F01} \dots \text{F22}\}$ (count = 22).
   - Compares the set of Antigravity historical defects against $\{\text{DEF-01} \dots \text{DEF-37}\}$ (count = 37).
2. **Target MR Reference Validation**:
   - Asserts that every target MR referenced in `03_HISTORICAL_FINDING_TRACEABILITY.md` is a member of the authoritative 37-MR set.
3. **Four-Way Forward and Reverse Mirror Parity**:
   - Validates that every file in `vps-infra-server/docs/remediation/` has an identical byte-for-byte copy in `vps-infra/docs/remediation/` across all four active remediation folders:
     - `docs/remediation/phase-0/`
     - `docs/remediation/phase-0-codex-remediation/`
     - `docs/remediation/phase-0-codex-regate-remediation/`
     - `docs/remediation/phase-0-review/`
   - **Reverse Mirror Check**: Asserts that `vps-infra` contains zero rogue, extra, or orphaned markdown files not present in `vps-infra-server`.
4. **Stale Forbidden Phrases Scan**:
   - Automatically scans all authoritative Phase 0 documents for forbidden stale phrases (e.g. `"restore pre-upgrade database"`, `"StartsWith(tenantSandboxRoot)"`, `"Trust Server Certificate=true"`, `"Redis denylist"`, `"LocalService"` in agent identity).

### 4.2 Script Execution Verification
Running `scripts/verify-baseline-integrity.ps1` executes non-destructively, confirms all checks pass, and returns exit code 0.

---

## 5. Conclusion

By strictly classifying documentation tiers, correcting static code descriptions, labeling operational estimates as targets, and enhancing the mechanical verification script to perform exact set comparisons and reverse mirror checks, findings **`C2-04`** and **`C3-01`** are completely resolved.
