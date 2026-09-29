# 06 HISTORICAL TRACEABILITY, SCHEMA AUTHORITY & PILOT BOUNDARIES REVIEW

**Document ID**: `REMED-P0-REV-R3-06`  
**Phase**: Phase 0 — Independent Re-Review after Codex Remediation (Cycle R3)  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Audit Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Findings `C1-04`, `C2-01`, `C2-02`)  
**Target Artifacts**: `03_HISTORICAL_FINDING_TRACEABILITY.md`, `10_MAINTENANCE_MODE_CURRENT_STATE.md`, `06_HISTORICAL_OBLIGATION_RECONCILIATION.md`, `07_PHASE_0_5_SCHEMA_AUTHORITY.md`  
**Verdict**: **PASS — OBLIGATIONS PRESERVED, SCHEMA AUTHORITY UNIFIED**  

---

## 1. Executive Evaluation of C1-04, C2-01, and C2-02

The Codex Phase 0 Audit Gate identified three key structural defects across historical traceability, schema evolution authority, and roadmap pilot boundaries:
1. **`C1-04`**: Complete 37-item ID coverage obscured lost underlying obligations: F16 sub-obligations (privacy precedence, fallback checks, admission controls) were omitted; DEF-08 (privileged control-plane socket mount) was merged into F01 (untrusted CI test runner); DEF-15 path traversal was omitted from Phase 1 scope.
2. **`C2-01`**: Phase 0.5 specified both a versioned EF Core migration and raw DDL statements in `DataSeeder.cs`, creating competing schema authorities; MR-34 was labeled Phase 1 in document 10; PostgreSQL acceptance tests were not detailed.
3. **`C2-02`**: Five items were labeled "Non-Blockers / Post-Pilot Work", yet their phases preceded Phase 13 pilot deployment. Gantt chart contradicted prose allowing staggered Linux qualification.

This independent review evaluates the resolution of these findings and confirms the integrity of the underlying contracts.

---

## 2. Review of Historical Obligation Traceability (C1-04)

### 2.1 Granular F16 Disaggregation & Gating
Historical finding `F16` addressed AI Model Gateway security, spend, and privacy controls. The Developer has disaggregated F16 into five distinct sub-obligations:

| Sub-Obligation | Description | Gate A Profile Status | Assigned MR & Target Phase |
|---|---|---|---|
| **F16.1** | API Key Encryption at Rest (AES-256-GCM) | Active Remediation Target | **MR-07** (Phase 1) |
| **F16.2** | Monotonic Streaming Spend Budget Hard Cap | Active Remediation Target | **MR-07** (Phase 1) |
| **F16.3** | `LocalOnly` Privacy Precedence (Block Cloud Leakage) | Feature Disabled for Gate A | **MR-07** (Phase 1 disable) / **MR-31** (Phase 9 re-enable) |
| **F16.4** | Cloud Fallback Authorization & Spend Rechecks | Feature Disabled for Gate A | **MR-07** (Phase 1 disable) / **MR-31** (Phase 9 re-enable) |
| **F16.5** | Local LLM Inference Admission & Resource Governor | Infrastructure Scope | **MR-16 / MR-17** (Phase 6 Governor) |

> [!NOTE]
> **Traceability Precision Note (R2-01)**:  
> In `06_HISTORICAL_OBLIGATION_RECONCILIATION.md:34`, sub-obligation F16.5 is mapped to `MR-17` ("Safe Cleanup & Retention"). Semantically, admission control and resource capping belong to **`MR-16` ("Resource Admission & Limits")**. While both items reside within Phase 6 ("Resource Safety & Admission"), mapping an admission governor to a disk cleanup MR is a minor documentary misalignment. It is recorded as precision finding **R2-01**.

### 2.2 Architectural Separation of F01 vs. DEF-08
In the previous baseline, DEF-08 was labeled a "Duplicate of Codex F01". The Developer has cleanly decoupled these two trust boundaries:
- **F01 (External CI Runner Execution Boundary)**: Addresses the threat of malicious tenant code running arbitrary builds with access to `/var/run/docker.sock`. Remediation: Untrusted build code is completely removed from the production host to External Isolated CI runners on ephemeral VMs (Phase 3).
- **DEF-08 (DevOps Manager Control Plane Boundary)**: Addresses the threat of a compromised management API container mounting the host root filesystem (`/:/host`) and Docker socket. Remediation: Hardens the API container via non-root execution (UID 10001), Linux capability dropping (`cap_drop: ALL`), read-only root filesystem (`read_only: true`), removal of host root mounts, and an unprivileged Unix domain socket proxy restricting Docker daemon commands (Phase 1).

### 2.3 Reconciliation of DEF-15 (Path Traversal Containment)
Path traversal containment is explicitly assigned to **`MR-04`** in Phase 1:
- Enforces strict canonicalization via `Path.GetFullPath(Path.Combine(tenantRoot, userPath))`.
- Mandates prefix validation asserting that the canonical path starts with `tenantRoot`.
- Rejects any path containing `..` or null bytes (`%00`) with HTTP 400 Bad Request.

---

## 3. Review of Phase 0.5 Schema Evolution Authority (C2-01)

### 3.1 Single Schema Authority: Versioned EF Core Migrations
The Developer has resolved the dual-authority conflict identified in C2-01:
- **Sole Authoritative Mechanism**: Versioned EF Core Migrations (`20261001000000_AddMaintenanceModeEntities.cs`).
- **Bounded Seeder Exception**: `DataSeeder.cs` is strictly restricted to **Data Population** (inserting initial records after schema creation). **Zero new raw DDL statements** (`ALTER TABLE`, `CREATE TABLE`) may be added to `DataSeeder.cs` during Phase 0.5.
- **Mandatory Removal Milestone**: In Phase 2, under Master Remediation item **`MR-13`** (Schema Evolution & Seeder Decoupling), all existing legacy raw DDL statements in `DataSeeder.cs` will be permanently excised.

### 3.2 Evaluation of Legacy Raw DDL During Phase 0.5 / Phase 1
As Independent Reviewer, we specifically analyzed whether existing legacy raw DDL in `DataSeeder.cs` can safely remain during Phase 0.5 and Phase 1:
- The legacy raw DDL creates baseline historical tables (`Projects`, `Deployments`).
- Because these statements use idempotent `CREATE TABLE IF NOT EXISTS` and do NOT mutate the 13 new Maintenance Mode properties, they will not collide with the Phase 0.5 migration.
- **The Golden Rule is Preserved**: There are zero competing schema mutation mechanisms for the Phase 0.5 change.

### 3.3 Validation of the Phase 0.5 Acceptance Test Contract
The Developer's 5-scenario PostgreSQL test suite covers the complete spectrum of schema evolution:
1. **P05-TC01 (Existing Schema Upgrade)**: Database lacking maintenance columns applies migration cleanly; all 13 columns verified.
2. **P05-TC02 (Fresh Database Install)**: Empty PostgreSQL database updates from baseline to `20261001000000` via EF Core migration runner.
3. **P05-TC03 (Zero Data Loss Verification)**: Pre-existing records in `Products` and `ProjectServices` retain row counts and receive default values (`IsActive = true`).
4. **P05-TC04 (Entity Query Regression)**: Application executes EF Core LINQ queries (`Products.Where(p => p.IsActive)`) with zero PostgreSQL error `42703 (undefined_column)` and HTTP 200 return.
5. **P05-TC05 (Migration Idempotency)**: Re-running migrations detects `__EFMigrationsHistory` entries and executes zero duplicate DDL.

All phase labels for `MR-34` have been normalized to **Phase 0.5** across the baseline.

---

## 4. Review of Pilot Boundaries & Staggered Qualification (C2-02)

### 4.1 Reclassification of Non-Blocker Terminology
The ambiguous label *"Non-Blockers / Post-Pilot Work"* has been eliminated. The five items are now classified as **"Scope-Governed Mandatory Pilot Prerequisites (Pre-Phase 13)"**:
1. **`MR-17` (Safe Cleanup Automation / Phase 6)**: Prior to Phase 13 pilot, aggressive automated Docker cleanup is disabled or bounded with strict volume protection; Gate A operates with manual cleanup runbooks.
2. **`MR-20` (Unsupported Feature Enforcement / Phase 3)**: Multi-engine database configurations are blocked in API/UI; PostgreSQL 16 is enforced.
3. **`MR-21` (Documentation Overhaul / Phase 9)**: Pre-pilot operational disclosures are provided to pilot customers; unfinished features are clearly labeled as experimental.
4. **`MR-30` (Infra Doctor Diagnostics / Phase 8)**: Standard diagnostic triage runbook completed for pilot operational support.
5. **`MR-31` (Support Bundles & Runbooks / Phase 9)**: Assisted pilot operational runbook finalized.

### 4.2 Staggered Pilot Qualification Rules
The roadmap formally codifies the staggered pilot execution model:
- **Phase 12A (Linux Gate A)** leads directly to **Phase 13A (Linux Pilot Deployment)** if Linux certification is achieved first.
- **Strict Mandate**: Windows Server 2022 remediation (Phase 4, Phase 10, Phase 11, Phase 12B) proceeds actively in parallel and is NEVER paused or canceled.
- **Phase 15 (Commercial Gate B)** remains the unified Dual-OS Commercial Gate, requiring successful certification of BOTH Linux and Windows Server.

---

## 5. Conclusion

Findings `C1-04`, `C2-01`, and `C2-02` are **completely and rigorously resolved**. All historical obligations are preserved without conflation, schema authority is unified under EF Core Migrations, and pilot boundaries are mathematically and operationally reconciled.
