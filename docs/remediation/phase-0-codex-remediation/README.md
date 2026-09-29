# Phase 0 Codex Gate Remediation Dossier

**Location**: `docs/remediation/phase-0-codex-remediation/`  
**Phase**: Phase 0 — Codex Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/` (Codex Phase 0 Audit Gate: FAIL — 1 C0, 4 C1, 4 C2, 1 C3)  

---

## 1. Directory Overview

This directory contains the authoritative Phase 0 Codex Gate Remediation Dossier authored by Developer Conversation 1 in response to the adversarial findings returned by the Codex Phase 0 Audit Gate (`docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md`).

All 10 Codex findings (1 C0, 4 C1, 4 C2, 1 C3) have been fully analyzed, reconciled, and architecturally remediated without modifying any runtime, product, configuration, database, or test code.

---

## 2. Dossier Document Index

| Filename | Purpose & Finding Addressed |
|---|---|
| [01_CODEX_FINDING_RESOLUTION_MATRIX.md](01_CODEX_FINDING_RESOLUTION_MATRIX.md) | Exhaustive 10-finding matrix mapping each Codex finding (C0-01 through C3-01) to its affected baseline artifacts, exact claims, required corrections, acceptance criteria, and resolution status. |
| [02_RELEASE_CONTRACT_CORRECTION.md](02_RELEASE_CONTRACT_CORRECTION.md) | **C0-01 Resolution**: Definitive release state machine, cutover semantics, post-cutover verification, single-host per-service atomic locking, stale-worker fencing, expand/contract database migrations, and decoupling application rollback from database restore. |
| [03_SECURITY_CONTRACT_CORRECTION.md](03_SECURITY_CONTRACT_CORRECTION.md) | **C1-01 Resolution**: Platform vs tenant administration role separation (reconciling DEF-11), complete Token Trust Contract (iss, aud, sub, tid, algorithm, rotation, revocation), and 9 Phase 1 negative test acceptance criteria. |
| [04_BACKUP_RECOVERY_CORRECTION.md](04_BACKUP_RECOVERY_CORRECTION.md) | **C1-02 Resolution**: 7-stage backup lifecycle, client-side AES-256-GCM envelope encryption, BIP-39 escrow key custody surviving total host loss, format-aware `pg_restore --list` verification, complete platform recovery set, and realistic RPO/RTO targets. |
| [05_WINDOWS_TOPOLOGY_CORRECTION.md](05_WINDOWS_TOPOLOGY_CORRECTION.md) | **C1-03 Resolution**: Frozen Windows Server 2022 Gate-A topology: native IIS 10 + HTTP.sys (no Traefik on Windows host), compiled `TMK.Agent.Windows` (.NET Worker Windows Service, mTLS on port 5055), and remote PostgreSQL 16 endpoint. |
| [06_HISTORICAL_OBLIGATION_RECONCILIATION.md](06_HISTORICAL_OBLIGATION_RECONCILIATION.md) | **C1-04 Resolution**: Granular F16 sub-obligation matrix (F16.1–F16.5), architectural separation of untrusted CI runner isolation (F01) from control-plane Docker socket hardening (DEF-08), and DEF-15 / F22 reconciliation. |
| [07_PHASE_0_5_SCHEMA_AUTHORITY.md](07_PHASE_0_5_SCHEMA_AUTHORITY.md) | **C2-01 Resolution**: Single schema evolution authority (EF Core Migrations), bounded temporary seeder role without raw DDL, mandatory Phase 2 seeder DDL removal (MR-13), 5-case PostgreSQL acceptance contract, and MR-34 phase label normalization. |
| [08_C2_C3_RESOLUTION.md](08_C2_C3_RESOLUTION.md) | **C2-02, C2-03, C2-04, C3-01 Resolution**: Reclassifying blocker terminology to "Scope-Governed Mandatory Pilot Prerequisites (Pre-Phase 13)", documenting the immutable Reviewer PASS artifact (`PHASE_0_REVIEW_R2_FINAL_REPORT.md`), repairing citation lines and timings, and automating baseline integrity checks. |
| [PHASE_0_CODEX_REMEDIATION_FINAL_REPORT.md](PHASE_0_CODEX_REMEDIATION_FINAL_REPORT.md) | Executive summary, comprehensive findings audit, baseline document synchronization index, Dual-OS confirmation, confirmation of zero code drift, and formal final recommendation. |
| [README.md](README.md) | This navigation guide and master directory index. |

---

## 3. Governance Invariants Maintained

1. **Dual-OS Mandate**: Ubuntu 24.04 LTS and Windows Server 2022 remain equal first-class target platforms. Independent Gate A certification for Linux (Phase 12A) and Windows (Phase 12B); unified Dual-OS Commercial Gate in Phase 15.
2. **Zero Code Drift**: `Runtime/Product/Test/Configuration Code Changed: NO`.
3. **Audit Immutability**: Historical audit artifacts (`docs/remediation/phase-0-codex-gate/` and `docs/remediation/phase-0-review/PHASE_0_REVIEW_FINAL_REPORT.md`) are strictly preserved.
4. **Mirror Equality**: 100% bit-for-bit file parity between `vps-infra-server` and `vps-infra`.
