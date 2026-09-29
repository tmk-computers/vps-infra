# 17 PHASE 1 ENTRY CRITERIA & GATE READINESS ASSESSMENT

**Document ID**: `REMED-P0-17`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Baseline Date**: 2026-09-29  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Governance Gate Mandate

Before Phase 1 (Shared Security Foundation) can be entered, all prerequisite engineering foundations, baseline freezes, traceability mappings, and architectural contracts must be verified by the independent Reviewer and Codex Audit Gate.

---

## 2. Gate Verification Checklist

| Prerequisite Criterion | Phase 0 Status | Authoritative Verification Evidence |
| :--- | :---: | :--- |
| **1. Current Repository SHAs Recorded** | **SATISFIED** | `vps-infra`: `780e8b4f152e039e9ee31ed46c71811e04947f7b`<br>`vps-infra-server`: `36354a32884fd0c03470d2b3f5333776f7aed6c9`<br>Documented in [`01_CURRENT_BASELINE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/01_CURRENT_BASELINE.md). |
| **2. All Codex F01–F22 Findings Traced** | **SATISFIED** | All 22 findings mapped to MR IDs with code anchors in [`03_HISTORICAL_FINDING_TRACEABILITY.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md). |
| **3. All Antigravity DEF-01–DEF-37 Traced**| **SATISFIED** | All 37 defects mapped to MR IDs with code anchors in [`03_HISTORICAL_FINDING_TRACEABILITY.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md). |
| **4. Master IDs MR-01–MR-37 Established** | **SATISFIED** | Complete register created with exact statuses (no percentages) in [`02_MASTER_REMEDIATION_REGISTER.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md). |
| **5. Contradictory Audit Claims Reconciled**| **SATISFIED** | Reconciled: (1) Outbound alerting code reality, (2) Google Drive vs S3 offsite backup, (3) Ghost Redis manifest, (4) Interrupted deployment status string vs infrastructure reality in [`03_HISTORICAL_FINDING_TRACEABILITY.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md). |
| **6. Linux & Windows Support Explicit** | **SATISFIED** | Independent matrices for Linux Gate A (Ubuntu 24.04) and Windows Gate A (Windows Server 2022) frozen in [`05_SUPPORTED_OS_MATRIX.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md). |
| **7. Target Architecture Frozen** | **SATISFIED** | Shared Platform Core decoupled from Linux and Windows Adapters specified in [`04_TARGET_ARCHITECTURE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md). |
| **8. CI Trust Boundary Explicit** | **SATISFIED** | External isolated CI specified for Gate A; requirements for integrated CI frozen in [`13_CI_TRUST_MODEL.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/13_CI_TRUST_MODEL.md). |
| **9. Deployment Safety Contract Explicit** | **SATISFIED** | Durable state machine (`PRECHECK` → `PREPARED` → `APPLYING` → `VERIFYING` → `CUTOVER` → `POST_CUTOVER_VERIFY` → `SUCCEEDED`), single-host atomic locking, expand/contract migrations, and decoupled DB restore specified in [`07_DEPLOYMENT_SAFETY_CONTRACT.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md). |
| **10. Backup & Recovery Contract Explicit** | **SATISFIED** | 7-stage backup pipeline, client-side AES-256-GCM encryption, offsite BIP-39 key escrow, format-aware `pg_restore --list`, and recovery manifests specified in [`09_BACKUP_RECOVERY_CONTRACT.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md). |
| **11. Maintenance Mode Findings Captured** | **SATISFIED** | Captured as MR-34 (Schema migration gap) and MR-35 (Service isolation defect) in [`10_MAINTENANCE_MODE_CURRENT_STATE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md). |
| **12. AMS Findings Captured** | **SATISFIED** | Captured as MR-36 (Auth failure & anonymous access) and MR-37 (Static heuristic semantics) in [`11_AMS_CURRENT_STATE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/11_AMS_CURRENT_STATE.md). |
| **13. Upgrade System Findings Captured** | **SATISFIED** | Captured as MR-19 (Absent health verification in execution path & hard reset) in [`12_UPGRADE_CURRENT_STATE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md). |
| **14. Zero Historical Blockers Dropped** | **SATISFIED** | All 26 historical pilot blockers (Codex P0/P1 and Antigravity P0/P1) accounted for with active master IDs and explicit child obligation traceability. |

---

## 3. Scope Specification for Phase 1 (Shared Security Foundation)

### 3.1 Prerequisite Database Alignment (Phase 0.5 / Pre-Validation)
- **MR-34**: Create versioned EF Core migration `20261001000000_AddMaintenanceModeEntities.cs` for Maintenance Mode fields on `Product`, `ProjectService`, and `MaintenanceWindow`. Versioned EF Core migrations are the SOLE schema evolution authority (zero raw DDL in `DataSeeder.cs`; seeder bounded to data population; raw DDL removal in Phase 2 MR-13). Pass all 5 PostgreSQL acceptance test scenarios (P05-TC01 to P05-TC05) prior to Phase 1.

### 3.2 Phase 1 Core Security Implementation Scope (9 Items)
Upon independent sign-off, Phase 1 execution will commence covering exclusively the following security foundation items:
1. **MR-02**: Enforce secure signing/authentication defaults; eliminate hardcoded fallback JWT keys. Default key on startup HALTS application.
2. **MR-03**: Revoke leaked service account RSA private key; purge `devops-manager/api/google-drive-credentials.json` from git history.
3. **MR-04**: Strip Git tokens and sensitive fields from read DTOs; implement credential protection; sanitize logging. DEF-15: Canonicalize `ProjectDirectory` via `Path.GetFullPath` prefix check against tenant sandbox root.
4. **MR-05**: Implement least-privilege PostgreSQL database roles for application containers.
5. **MR-06**: Eliminate public WAN exposure of database and administrative ports (bind to loopback/internal bridge).
6. **MR-07**: Implement dynamic high-entropy secret generation on setup across provisioning scripts (`setup.sh`, `setup.ps1`). F16.1: Encrypt AI keys at rest. F16.2: Enforce monotonic streaming spend cap. (F16.3/F16.4 gated under Gate-A AI disablement).
7. **MR-08**: Multi-tenant RBAC and role separation: formally decouple `PlatformSuperAdmin` from `TenantAdmin` (DEF-11). DEF-08: Container hardening (UID 10001, capability dropping, read-only rootfs, scoped socket proxy).
8. **MR-28**: Replace hardcoded Windows Agent fallback bearer secret with dynamically provisioned mutual authentication secrets (Dual-OS parity).
9. **MR-36**: Comprehensive Token Trust Contract (`iss`, `aud`, `sub`, `tid`, algorithm, rotation, revocation). Pass all 9 negative test criteria.

*(Note: MR-37 UI copywriting and documentation labeling is relocated to Phase 9 alongside MR-21, with pre-pilot disclosure provided for pilots).*
