# 07 REPOSITORY-WIDE CONSISTENCY, EVIDENCE INTEGRITY & DUAL-OS REVIEW

**Document ID**: `REMED-R4-07`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Review Cycle**: R4 (Final Independent Review of Codex Re-Gate Remediation)  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Status**: Authoritative Consistency Audit Complete  
**Date**: 2026-09-30  

---

## 1. Evidence Integrity & Baseline Discipline

The Reviewer audited the evidence handling and claims discipline across all remediation artifacts:

1. **Historical Evidence Preservation**: Historical audit reports under `docs/audit/2026-09-29-linux-windows-readiness/` and initial Codex gate records remain completely unmodified. Past findings and defects are accurately represented without revisionism.
2. **Current Baseline Isolation**: Baseline commit SHAs are explicitly documented:
   - `vps-infra`: `780e8b4f152e039e9ee31ed46c71811e04947f7b`
   - `vps-infra-server`: `36354a32884fd0c03470d2b3f5333776f7aed6c9`
   Zero product, runtime, database, configuration, or test code has been altered during Phase 0.
3. **Honest Claim Classification**:
   - Static analysis is explicitly labeled as static code inspection, never conflated with live executable verification.
   - RPO (24h/1h) and RTO (30m) are explicitly classified as **operational targets subject to Phase 5 validation**, not certified performance guarantees.
   - No architectural contract (e.g. Expand/Contract, worker fencing, Token Trust Matrix) is claimed as "implemented" or "verified" in Phase 0; all are tracked as `OPEN` under their respective Master Remediation items.

---

## 2. Independent Spot-Check of 14 Reconciled Consistency Areas

The Developer reported searching 28 documents, identifying 14 cross-document contradictions, and resolving all 14 with 0 remaining contradictions. The Reviewer independently executed targeted searches across all authoritative documents in `docs/remediation/phase-0/`:

| # | Consistency Check Area | Search / Regex Pattern | Authoritative Baseline Status | Reviewer Verification Result |
|---|---|---|---|:---:|
| **1** | **Automatic Database Restore** | `restore pre-upgrade database` / `automatic database restore` | Eradicated; universal invariant `APPLICATION ROLLBACK MUST NOT AUTOMATICALLY RESTORE THE DATABASE` enforced. | **PASS** (Zero matches) |
| **2** | **Mandatory Redis Requirement** | `Redis denylist` / `mandatory Redis` | Eradicated; Redis is consistently `Optional / Not Gate-A Certified Dependency`. | **PASS** (Zero matches) |
| **3** | **Windows Service Account** | `LocalService` | Eradicated; replaced with dedicated least-privilege Windows service identity (e.g. `NT SERVICE\TMKAgent`). | **PASS** (Zero matches) |
| **4** | **Docker Desktop on Windows** | `Docker Desktop` | Excluded from Windows Gate A; native IIS 10 + HTTP.sys used exclusively. | **PASS** (0 uncertified uses) |
| **5** | **WSL2 PostgreSQL Dependency** | `WSL2 PostgreSQL` | Excluded from Gate A; workloads connect to remote PostgreSQL 16 over TLS. | **PASS** (Zero matches) |
| **6** | **Windows Ingress Conflicts** | `Traefik` on Windows | Eradicated; Traefik is NOT deployed on Windows host; HTTP.sys owns ports 80/443. | **PASS** (Zero conflicts) |
| **7** | **Tenant-Scoped SuperAdmin** | `tenant-scoped SuperAdmin` | Eradicated; DEF-11 reconciled: `PlatformSuperAdmin` strictly separated from `TenantAdmin`. | **PASS** (Historical context only) |
| **8** | **F16.5 Stale Mapping** | `MR-17.*F16\.5` / `F16\.5.*MR-17` | Eradicated; F16.5 cleanly mapped to MR-16 (Resource Admission & Limits). | **PASS** (Zero matches) |
| **9** | **Invalid Archive Gzip Testing** | `gzip -t` | Eradicated; prohibited on custom-format `-Fc` archives; `pg_restore --list` used. | **PASS** (Explicitly prohibited only) |
| **10** | **Compression Block Verification** | `compressed data blocks` / `compression-block` | Eradicated; `pg_restore --list` limited to header/TOC parseability; full integrity via restore drill. | **PASS** (Zero false claims) |
| **11** | **Hardcoded Universal Health** | `/health` hardcoded success | Parameterized across path, status codes, timeouts, and observation windows. | **PASS** (Parameterizable profile) |
| **12** | **Unqualified RPO / RTO** | Certified 1h RPO / Instant RTO | Formally classified as operational targets subject to Phase 5 validation. | **PASS** (Operational targets) |
| **13** | **Fictitious Schema Entities** | `MaintenanceWindows` / `ServiceMaintenances` | Eradicated; exactly 8 Product + 5 ProjectService = 13 properties from source code. | **PASS** (Zero matches) |
| **14** | **Naive StartsWith Path Traversal** | `StartsWith\(tenantSandboxRoot` | Eradicated; replaced with normalized segment-boundary containment (trailing separator). | **PASS** (Zero matches) |

**Reviewer Verdict**: **PASS**. All 14 consistency areas are completely resolved with zero remaining active contradictions.

---

## 3. Audit Tooling Inspection (`verify-baseline-integrity.ps1`)

The Reviewer independently inspected the code and execution behavior of [`scripts/verify-baseline-integrity.ps1`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/verify-baseline-integrity.ps1):

1. **Check 1 (MR Item Count & Exact Set)**: Lines 13–45 parse [`02_MASTER_REMEDIATION_REGISTER.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md) and assert the exact set `{MR-01..MR-37}` with zero duplicates and zero missing items.
2. **Check 2 (Status Arithmetic Validation)**: Lines 46–63 extract statuses and assert exact counts: `33 OPEN` + `3 PARTIALLY_IMPLEMENTED` + `1 IMPLEMENTED_NOT_VERIFIED` = `37 Total`.
3. **Check 3 (Traceability Exact Sets & Target Validity)**: Lines 64–114 parse [`03_HISTORICAL_FINDING_TRACEABILITY.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md), asserting exact sets `{F01..F22}` (22 items) and `{DEF-01..DEF-37}` (37 items), and verifying that every referenced MR target is a valid member of `{MR-01..MR-37}`.
4. **Check 4 (Cross-Repository Forward & Reverse Mirror Parity)**: Lines 116–175 compute SHA-256 digests for all markdown files across `phase-0`, `phase-0-codex-remediation`, `phase-0-codex-regate-remediation`, and `phase-0-review`, verifying 100% bit-for-bit equality between `vps-infra-server` and `vps-infra` with zero orphaned or rogue files.
5. **Check 5 (Forbidden Stale Phrases Scan)**: Lines 177–205 scan all authoritative files in `docs/remediation/phase-0/` for forbidden phrases (`restore pre-upgrade database`, `StartsWith(tenantSandboxRoot`, `Trust Server Certificate=true`, `Redis denylist`).
6. **Error Handling & Exit Code**: The script uses `$ErrorActionPreference = "Stop"` and `Write-Error` on assertion failure, guaranteeing a non-zero exit code on failure, and terminates with `exit 0` on complete pass.

**Live Execution Result**:
```text
====================================================
   VPS-INFRA BASELINE INTEGRITY VERIFICATION (C3-01)
====================================================
[Check 1] Master Remediation (MR) Item Count & Exact Set...
  Found MR entries in table: 37
  PASS: Exact set {MR-01..MR-37} verified with zero duplicates and zero missing.
[Check 2] Status Arithmetic Validation...
  OPEN: 33
  PARTIALLY_IMPLEMENTED: 3
  IMPLEMENTED_NOT_VERIFIED: 1
  Total Status Sum: 37
  PASS: Exact status distribution verified (33 + 3 + 1 = 37).
[Check 3] Historical Finding Traceability Exact Sets & Target Validity...
  Historical Codex F-findings: 22 (Expected: 22)
  Historical Antigravity DEF-defects: 37 (Expected: 37)
  PASS: Exact sets {F01..F22} and {DEF-01..DEF-37} verified.
  PASS: All referenced MR targets in traceability are valid members of {MR-01..MR-37}.
[Check 4] Cross-Repository Forward & Reverse Mirror Equality...
  PASS: 59 documentation artifacts verified with 100% bit-for-bit SHA-256 equality across all 4 directories.
[Check 5] Stale Forbidden Phrases Scan in docs/remediation/phase-0...
  PASS: Zero forbidden stale phrases found in authoritative Phase 0 baseline.
====================================================
   ALL MECHANICAL INTEGRITY CHECKS PASSED (EXIT 0)  
====================================================
```

**Reviewer Assessment**: **PASS**. The audit tooling enforces comprehensive mechanical integrity.

---

## 4. Dual-OS Architecture & Certification Gates

The Reviewer verified that no reconciliation action weakened or compromised the Dual-OS Non-Negotiable Mandate:

1. **Equal First-Class Status**: Linux (Ubuntu 24.04 LTS) and Windows Server (Windows Server 2022) are maintained as parallel, first-class target operating systems. Windows Server remediation is actively scheduled across Phase 4, Phase 10, Phase 11, and Phase 12B.
2. **Independent Gate A Certifications**:
   - **Phase 12A**: Independent Linux Gate A Certification (Docker Compose, Traefik, PostgreSQL 16, cgroup limits).
   - **Phase 12B**: Independent Windows Gate A Certification (IIS 10, ANCM, `TMK.Agent.Windows`, remote PostgreSQL 16 over authenticated TLS).
3. **Staggered Pilot Guardrails**:
   - If Linux Gate A passes first, an operational pilot for Linux may commence under Phase 13A.
   - **Mandatory Guardrail**: Starting a Linux pilot under Phase 13A **does not pause, cancel, or defer** Windows remediation. Windows tracks proceed actively within the same master program.
4. **Unified Commercial Gate**:
   - **Phase 15**: Dual-OS Commercial Enterprise Gate B. Commercial release requires full dual-OS certification across both Ubuntu 24.04 LTS and Windows Server 2022.

**Reviewer Verdict**: **PASS**. The Dual-OS mandate is fully preserved.

---

## 5. Reviewer Domain Verdict

- **Evidence Integrity**: **PASS** (Zero historical revisionism, clear baseline isolation).
- **Repository-Wide Consistency**: **PASS** (14 of 14 checked areas resolved; 0 active contradictions).
- **Audit Tooling**: **PASS** (Mechanical checks execute cleanly and exit code 0).
- **Dual-OS Architecture**: **PASS** (Equal tracks, independent Gate A, unified Phase 15 Gate B).
