# 05 EVIDENCE TRUTH & HISTORICAL RECONCILIATION

**Document ID**: `FINAL-CLOSURE-05-EVIDENCE-TRUTH`  
**Phase**: Phase 0 — Final Codex Closure Corrections  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex C2-04 (`06_FINAL_FINDINGS_REGISTER.md:32-37`, `05_EVIDENCE_AND_CONSISTENCY_FINAL_GATE.md:38-48`)  
**Status**: COMPLETE — EVIDENCE TRUTH RECONCILED  

---

## 1. Executive Summary

This document provides explicit evidentiary reconciliation for historical statements, review remarks, and source citations identified by Codex in finding **C2-04**.

In strict accordance with audit integrity rules:
- **Historical Reports Remain Unchanged**: Historical review reports (`phase-0-review-r4`, `phase-0-review-r3`, `phase-0-codex-gate`, `phase-0-codex-regate`) are immutable historical audit records and are not edited retroactively.
- **Active Authoritative Artifacts Are Corrected**: Current authoritative documents (`docs/remediation/phase-0/`) and reconciliation dossiers are updated to reflect verifiable source reality.
- **Clear Epistemic Distinctions**: Specification contracts, static source code, planned test criteria, executed checks, and measured results are explicitly distinguished.

---

## 2. Reconciled Evidence Items

### 2.1 Truth Matrix Citations & Marketing Paraphrases
- **Historical Defect**: `15_DOCUMENTATION_TRUTH_MATRIX.md:31-35` cited `d:/company/products/vps-infra/README.md`, which was a nonexistent wrapper-level path rather than the repository README (`vps-infra/vps-infra/README.md`).
- **Correction Applied**: Updated all file links in `15_DOCUMENTATION_TRUTH_MATRIX.md` to reference the real repository file at `[vps-infra/README.md](file:///d:/company/products/vps-infra/vps-infra/README.md)`.
- **Marketing Claims**: Phrases such as *"Instantaneous rollback to previous release"* and *"Automated daily offsite backup synchronization to AWS S3 and Cloudflare R2"* are explicitly labeled as **historical promotional assertions / early marketing claims**, contrasting directly with the executable codebase reality.

### 2.2 Windows Agent Static Fallback Secret Status
- **Historical Defect**: Independent Review R4 (`05_BACKUP_WINDOWS_REVIEW.md:119`) erroneously stated that the static fallback secret `"[REDACTED_COMPROMISED_DEFAULT]"` had been completely eliminated from architecture and code.
- **Source Code Reality**: Inspection of the actual codebase confirms that the hardcoded fallback secret **still exists in active source code**:
  - `scripts/tmk-iis-agent.ps1:21`: `$Secret = "[REDACTED_COMPROMISED_DEFAULT]"`
  - `devops-manager/api/Infrastructure/Services/IisClientService.cs:42`: Fallback configuration string.
- **Authoritative Contract Classification**:
  - **CURRENT IMPLEMENTATION**: The static fallback secret is **currently present** in the repository.
  - **TARGET ARCHITECTURE CONTRACT**: The static fallback secret **MUST be completely removed**.
  - **OWNER**: Master Remediation **MR-28** (scheduled for implementation in **Phase 1: Shared Security Foundation**).
  - **ACCEPTANCE CRITERION**: The Windows Agent and DevOps Manager API must fail startup immediately if default or static fallback credentials are detected; authentication must rely exclusively on dynamically generated mutual authentication tokens (Dual-OS parity).

### 2.3 Phase 0.5 Schema Inventory & Relational Mapping
- **Timestamp Type Mapping**: EF Core pre-convention in `ApplicationDbContext.cs:44-46` declares:
  `configurationBuilder.Properties<DateTime>().HaveColumnType("timestamp without time zone");`
  Therefore, the relational column type is explicitly **`timestamp without time zone`**, NOT `timestamp with time zone`.
- **Relational Defaults vs CLR Initializers**: The default values (`"All systems operational."`, `true`, `false`) are C# property initializers in memory. The database relational default in the model snapshot is `None`. Non-nullable boolean columns must receive migration backfill defaults.
- **Migration & Seeder Reality**: The 13 maintenance properties do not exist in current migrations or `ApplicationDbContextModelSnapshot.cs`. `DataSeeder.cs:46-168` raw DDL does not cover them and must be neutralized before Phase 0.5 acceptance.

### 2.4 Traceability Finding Obligations (F02, F03, & F15)
- **Codex F02**: Requires cryptographically generated install secrets, elimination of static signing defaults, and a service-specific token trust contract (algorithm whitelist `RS256`/`HS256`, negative tests for wrong issuer, rotated keys, and invalid scopes). Mapped to **MR-02** and **MR-36**.
- **Codex F03**: Requires revocation of leaked service account RSA private key in Google Cloud IAM and git history purging. Mapped to **MR-03**.
- **Codex F15**: Requires optimistic concurrency tokens, resource state digest snapshots, atomic claims, durable action state/idempotency, and crash recovery for human approval (HITL) workflows. Rollover across clock-hour must not invalidate unchanged state. Mapped to **MR-08**.
- All findings retain their full substantive requirements in active baseline registers (`02_MASTER_REMEDIATION_REGISTER.md` and `03_HISTORICAL_FINDING_TRACEABILITY.md`).

### 2.5 Disaster Recovery TOC Listing vs Payload Validation
- **Clarification**: `pg_restore --list` verifies the custom-format archive header and parses the Table of Contents (TOC). It verifies archive structure and prevents unhandled decompression crashes, but does **not** validate all compressed data blocks or evaluate referential integrity.
- **Validation Contract**: Full data validation is performed during automated Disaster Recovery drills (**MR-15**), which restore the backup to a disposable instance and verify table row counts and referential consistency.

### 2.6 LocalService Stale Pattern Scan
- **Verifier Alignment**: `scripts/verify-baseline-integrity.ps1` has been updated to explicitly scan for `\bLocalService\b` in addition to the 4 previous patterns. Ripgrep confirmed zero occurrences in the authoritative `docs/remediation/phase-0/` baseline.

---

## 3. Epistemic Classification Framework

To eliminate any ambiguity between forward-looking architecture and present implementation, all Phase 0 statements must adhere to the following taxonomy:

| Category | Definition | Current Status in Phase 0 |
|---|---|---|
| **Specification / Target Contract** | What the architecture requires future phases to implement. | Authoritative and frozen. Formulated using `MUST`, `SHALL`, `REQUIRED`. |
| **Static Code Reality** | What exists in repository source files today. | Verified via static inspection. Includes existing deficiencies (e.g. static fallback in `tmk-iis-agent.ps1:21`). |
| **Planned Test Criteria** | Automated gates and scenarios defined for future phases. | Defined (e.g. 5 Phase 0.5 scenarios, 15 Phase 1 negative criteria). |
| **Executed Checks** | Scripts and verifications executed during Phase 0 audit. | `scripts/verify-baseline-integrity.ps1` and mechanical fault-injection tests. |
| **Measured Outcomes** | Runtime benchmarks, RPO/RTO timings, network packet captures. | **None claimed in Phase 0**. All operational timings (e.g. sub-5s rollback) are target SLAs, not measured results. |
