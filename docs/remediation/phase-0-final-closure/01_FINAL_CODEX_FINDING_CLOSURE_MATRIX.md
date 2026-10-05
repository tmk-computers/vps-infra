# 01 FINAL CODEX FINDING CLOSURE MATRIX

**Document ID**: `FINAL-CLOSURE-01-MATRIX`  
**Phase**: Phase 0 — Final Codex Closure Corrections  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: COMPLETE — ALL FINDINGS RESOLVED  

---

## 1. Executive Summary

This matrix provides the exhaustive resolution accounting for all remaining and new findings returned by the Codex Final Re-Gate (`PHASE_0_CODEX_FINAL_REGATE_REPORT.md` and `06_FINAL_FINDINGS_REGISTER.md`).

Following the strict surgical closure mission directive, the core accepted contracts (Release Contract, Security Contract, Path Containment, Backup/Recovery, Windows Architecture, Traceability, Dual-OS) have remained completely untouched. 

Per executive architectural instruction prior to final independent review, the previous Redis classification was amended under `REDIS_ARCHITECTURE_AMENDMENT.md` to establish Redis 7 as a first-class component of the standard production architecture, while strictly enforcing that PostgreSQL remains the sole durable source of truth for safety-critical platform state. Only the remaining failing domains (**Phase 0.5 Schema Contract** and **Evidence Integrity**) and the newly surfaced items (**Infrastructure Database Provisioning Drift**, **TLS Mode Precision**, and **Compromised Credential Disposition**) have been addressed.

---

## 2. Master Finding Closure Table

| Finding ID | Severity | Domain | Exact Codex Closure Condition | Evidence / Action Taken | Status |
|---|---|---|---|---|:---:|
| **RG-C1-02** | **C1** | Phase 0.5 Schema Contract | "Correct canonical line 171 and all corresponding text to target the real entities/properties, and establish an exact source-derived inventory. Ensure inventory timestamp types do not conflict with EF configuration." | Canonical `PHASE_0_FINAL_REPORT.md:171` updated to remove fictitious `MaintenanceWindow` and target `Product` (8 fields) and `ProjectService` (5 fields). Migration name set to `20261001000000_AddMaintenanceModeFields.cs`. Timestamp type mapped to `timestamp without time zone` per `ApplicationDbContext.cs:44-46`. 10-column source inventory established in `03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md` and `06_PHASE_0_5_SCHEMA_INVENTORY.md`. | **RESOLVED** |
| **FR-C1-01** | **C1** | Database / Security Provisioning Drift | "Account for this commit through an explicit reviewed baseline exception/disposition or present an appropriately scoped candidate. Review and resolve the hardcoded fallback behavior before accepting that implementation as safe; document credential handling and any needed operational follow-up based on actual use. The full frozen-baseline-to-candidate diff is accounted for, independently reviewed, and no unexplained product/database/security delta is labeled governance-only." | Evaluated under **Option A (Include in Phase 0 candidate)**. Inspected line-by-line in `04_INFRA_DATABASE_PROVISIONING_DISPOSITION.md`. Accurately classified as operational database tooling drift in `02_FINAL_CANDIDATE_BASELINE.md`. Mapped to **MR-02** (Secret Storage) and **MR-05** (Least Privilege Database Provisioning). Explicitly mandated Phase 1 remediation to eliminate line 11 fallback password and require dynamic credentials. | **RESOLVED** |
| **C2-01** | **C2** | Schema Evolution Authority | "Make the final summary agree with the prerequisite. Necessary legacy schema responsibility must be versioned before certification; only unrelated data-seeding refactoring remains later. Existing raw source DDL is not itself a Phase 0 failure." | Reconciled `PHASE_0_FINAL_REPORT.md:171` to remove contradictory deferral of raw DDL removal to Phase 2. Mandated that competing raw DDL in `DataSeeder.cs:46-168` must be neutralized and disabled prior to Phase 0.5 acceptance. Bounded seeder strictly to data insertion; full legacy non-DDL seeder cleanup remains in Phase 2 MR-13. | **RESOLVED** |
| **C2-04** | **C2** | Evidence Integrity | "Correct current canonical citations and append a reconciled evidence note for historical R4 errors. Label specification, static code, planned tests, executed checks and measured results distinctly. Preserve historical reports unchanged." | 1. Corrected `15_DOCUMENTATION_TRUTH_MATRIX.md:31-35` citations from nonexistent wrapper path to real repo paths (`vps-infra/README.md`) and labeled early claims as promotional marketing assertions.<br>2. Reconciled Windows Agent fallback secret in `05_EVIDENCE_TRUTH_CORRECTIONS.md`: explicitly distinguished present source reality (`scripts/tmk-iis-agent.ps1:21` retains fallback) from target architecture (Phase 1 MR-28 replaces with dynamic authentication).<br>3. Clarified backup TOC listing (`pg_restore -l`) vs payload validation.<br>4. Reconciled LocalService pattern count and traceability finding descriptions in `05_EVIDENCE_TRUTH_CORRECTIONS.md`. Historical R4 left unchanged. | **RESOLVED** |
| **FR-C2-01** | **C2** | TLS Mode Precision | "Prefer the already specified VerifyFull example, or explicitly describe and test an independently enforced validating/pinning mechanism for any alternative. Test untrusted CA, wrong hostname and wrong pin as applicable. Do not describe a trust-store installation or flag alone as proof." | Standardized on `SSL Mode=VerifyFull` with validated CA and hostname verification across all active artifacts (`04_TARGET_ARCHITECTURE.md:173`, `05_SUPPORTED_OS_MATRIX.md:68`, `06_DATABASE_SUPPORT_MATRIX.md:40`, `05_WINDOWS_ARCHITECTURE_RECONCILIATION.md:136-145`). Excised misleading `SSL Mode=Require;Trust Server Certificate=false` alternative. Documented Npgsql behavior where `Require` lacks peer authentication. | **RESOLVED** |
| **C3-01** | **C3** | Tooling Advisory | "Reject missing required input directories; inspect all mapped target rows; explicitly declare the mirror scope and byte/text-equality policy. Include relevant dossiers or narrow the advertised guarantee. Retain negative tests. Exact four-string scanning must not be advertised as semantic consistency verification." | Hardened `scripts/verify-baseline-integrity.ps1`:<br>1. Aborts with exit 1 if any required source or mirror directory is missing (no silent continue).<br>2. Scans ALL table rows in traceability matrix including `MR-34`..`MR-37` discovery rows, asserting all referenced MRs exist in `{MR-01..MR-37}`.<br>3. Added LocalService pattern to forbidden scan.<br>4. Added `phase-0-final-closure` to mirror and validation scope.<br>5. Explicitly documented mirror scope: bit-for-bit SHA-256 for active dossiers; text-normalized semantic parity for historical reports.<br>6. Executed 7 fault-injection tests with full negative evidence recorded in `06_VERIFIER_HARDENING_RESULTS.md`. | **RESOLVED** |

---

## 3. Detailed Finding Resolution Narratives

### 3.1 RG-C1-02: Phase 0.5 Schema Contract & Nonexistent Entities
- **Source Inspection**: Inspection of `devops-manager/api/Data/Entities/` confirmed that `MaintenanceWindow` and `ServiceMaintenance` do not exist. Only `Product.cs` (8 maintenance properties) and `ProjectService.cs` (5 maintenance properties) exist.
- **Relational Type Mapping**: `ApplicationDbContext.cs:44-46` declares:
  ```csharp
  configurationBuilder.Properties<DateTime>().HaveColumnType("timestamp without time zone");
  ```
  This EF Core pre-convention configures both `DateTime` and `DateTime?` relational columns to `timestamp without time zone`. The prior documentation claiming `timestamp with time zone` was factually contradictory to the EF configuration. This has been corrected across all active documentation.
- **Relational Defaults vs CLR Initializers**: In `ApplicationDbContext.cs`, `OnModelCreating` does not specify `HasDefaultValue` for these maintenance properties. The defaults shown in entity classes (`="All systems operational."`, `="1.0.0"`, `=false`, `=true`) are C# property initializers in memory. The database relational default is `None`. This distinction is now formally documented.
- **Authoritative Baseline Update**: Canonical line 171 of `PHASE_0_FINAL_REPORT.md` was updated to reference `20261001000000_AddMaintenanceModeFields.cs` covering `Product` and `ProjectService`.

### 3.2 FR-C1-01: Database Provisioning Helper Drift
- **Finding**: Commit `10a2e77` in `vps-infra` added `db/postgres/create-readonly-analyst.sh`, which provisions a read-only role (`clever_farmer_analyst`) for `clever_farmer_uat`. It contains a hardcoded fallback password (redacted; treated as compromised) and connects via superuser `docker exec`.
- **Disposition**: Chosen **Option A (Include in Phase 0 candidate baseline)**. It is legitimate operational database tooling authored by repository ownership on `main`. Deleting it or hiding it is rejected as dishonest.
- **Accounting**: The full baseline delta is accounted for in `02_FINAL_CANDIDATE_BASELINE.md`. A comprehensive security and architectural disposition is documented in `04_INFRA_DATABASE_PROVISIONING_DISPOSITION.md`.
- **Compromised Credential Policy & Phase 1 Remediation Mandate**:
  - The exposed hardcoded credential is treated as compromised. It MUST be rotated/revoked.
  - Future provisioning must use dynamically supplied or generated credentials; no default/fallback production credential is permitted.
  - Mapped to **MR-02** (Secret Storage) and **MR-05** (Least-Privilege Roles). In Phase 1, the hardcoded password fallback MUST be removed, dynamic password generation enforced, and invocation restricted to authorized operational execution. Rotation will be evidenced upon execution in Phase 1 (not silently assumed in Phase 0).

### 3.3 C2-01: Schema Evolution Authority & Seeder Neutralization
- **Finding**: `PHASE_0_FINAL_REPORT.md:171` claimed versioned EF Core migrations are the sole schema evolution authority, but parenthetically deferred raw DDL removal in `DataSeeder.cs` to Phase 2 MR-13.
- **Resolution**: Updated `PHASE_0_FINAL_REPORT.md:171`, `06_PHASE_0_5_SCHEMA_INVENTORY.md`, and `03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md` to mandate that competing raw DDL in `DataSeeder.cs:46-168` MUST be neutralized and disabled **prior to Phase 0.5 acceptance**. Seeder execution during Phase 0.5 validation is bounded strictly to data insertion. Only broader legacy non-DDL seeder cleanup remains scheduled for Phase 2 MR-13.

### 3.4 C2-04: Evidence Truth Corrections
- **Nonexistent Wrapper Path**: `15_DOCUMENTATION_TRUTH_MATRIX.md:31-35` cited `d:/company/products/vps-infra/README.md`. Corrected to actual repo paths (`vps-infra/vps-infra/README.md`) and explicitly identified early promotional assertions ("instantaneous rollback", "automated daily offsite backup to AWS S3 and Cloudflare R2") as historical marketing claims.
- **Windows Agent Fallback Secret**: Current source in `scripts/tmk-iis-agent.ps1:21` and `IisClientService.cs:42` contains static fallback `"[REDACTED_COMPROMISED_DEFAULT]"`. Reconciled in `05_EVIDENCE_TRUTH_CORRECTIONS.md` to state:
  - CURRENT IMPLEMENTATION: Fallback secret is currently present in source code.
  - TARGET CONTRACT: Must be eliminated and replaced with dynamic authentication.
  - OWNER: MR-28 (Phase 1 Shared Security Foundation).
  - ACCEPTANCE: Agent and API fail startup if static fallback secret is present.
- **Disaster Recovery Listing**: Clarified that `pg_restore -l` validates TOC archive structure and header integrity, not full payload block verification. Full verification occurs during automated DR drills.

### 3.5 FR-C2-01: Authenticated TLS Mode (`SSL Mode=VerifyFull`)
- **Finding**: Canonical docs permitted `SSL Mode=Require;Trust Server Certificate=false` with validated CA. In Npgsql, `SSL Mode=Require` encrypts the connection but does not authenticate the server certificate or validate hostnames.
- **Resolution**: Replaced the alternative with canonical `SSL Mode=VerifyFull` with validated CA and hostname verification across all active documents. Unauthenticated encryption without server peer verification is strictly prohibited.

### 3.6 C3-01: Verifier Hardening & Negative Testing
- **Hardening Applied**:
  - Missing dossier directories now trigger immediate `Write-Error` and exit 1 (no silent continue).
  - Traceability target parsing now scans all table rows (including discovery rows `MR-34`..`MR-37`), validating that every target reference is a valid member of `{MR-01..MR-37}`.
  - Added forbidden phrase scan for `LocalService` agent identity and stale Redis exclusion wording (`Optional / Not Gate-A Certified Dependency`).
  - Included `phase-0-final-closure` in mirror synchronization and bit-for-bit SHA-256 verification.
- **Negative Testing**: All 7 fault-injection scenarios were executed and confirmed to exit with code 1. Clean baseline exits with code 0.

### 3.7 Executive Architectural Amendment: Redis Architecture & Dual-Store Invariant
- **Architectural Shift**: Amended previous classification (`Redis = Optional / Not Gate-A Certified Dependency`) to: **Redis 7 is a first-class component of the standard production architecture**.
- **Non-Negotiable Durability Invariant**: **Redis SHALL NOT be the sole authoritative durable store for safety-critical platform state**. PostgreSQL 16 remains the durable source of truth for deployment state, release history, tenant config, users, authorization, durable credential/token revocation, audit history, recovery metadata, licensing, critical config, and billing records.
- **Multi-Tiered Revocation Architecture**: Canonical pipeline `Local Cache -> Redis 7 -> PostgreSQL`. Revocation writes MUST commit durably to PostgreSQL first before being considered successful. Invalidation follows. Outages/cache misses fall back safely to PostgreSQL.
- **Failure Model & Degraded Operation**: Redis unavailable MUST NOT cause loss of critical state. Fall back to PostgreSQL where possible; fail safe where not possible.
- **Gate-A Acceptance Testing**: Defined 6 required test scenarios (Normal operation, Redis unavailable, Redis restart, Stale cached security data, Redis data loss, Redis latency/degradation).
- **AI Workforce Forward Compatibility**: Documented Redis as operational primitive for future AI workforce capabilities outside Gate-A critical path.
- **Traceability**: Mapped cleanly to existing MR items (MR-02, MR-05, MR-06, MR-07, MR-10, MR-11, MR-12, MR-16, MR-18, MR-20, MR-36) without increasing MR count above 37.

