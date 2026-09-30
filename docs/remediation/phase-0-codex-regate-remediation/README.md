# Phase 0 Codex Re-Gate Remediation Dossier

**Directory**: `docs/remediation/phase-0-codex-regate-remediation/`  
**Phase**: Phase 0 — Focused Codex Re-Gate Final Reconciliation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: `docs/remediation/phase-0-codex-regate/06_REGATE_FINDINGS_REGISTER.md`  
**Status**: COMPLETE — ALL 14 CODEX RE-GATE FINDINGS FULLY RECONCILED  

---

## 1. Overview

This dossier documents the exhaustive, repository-wide architectural and documentary reconciliation executed by Antigravity Conversation 1 (Developer) following the focused Phase 0 re-gate by the Codex Audit Gate (`PHASE 0 CODEX RE-GATE: FAIL`).

### Key Methodological Mandate
In strict accordance with the re-gate directive:
1. **Document-Layer Patching Has Ceased**: Rather than layering another set of correction documents while leaving contradictory authoritative files untouched, all 12 affected documents in the canonical baseline (`docs/remediation/phase-0/`) have been directly updated.
2. **One Single Truth**: All current specifications across deployment, upgrade, backup, security, Windows topology, traceability, and schema evolution are 100% coherent and mutually consistent.
3. **Historical Audit Reports Preserved**: Historical audit files (`findings.json`, `docs/remediation/phase-0-review/`, `docs/remediation/phase-0-codex-gate/`, `docs/remediation/phase-0-review-r3/`, and `docs/remediation/phase-0-codex-regate/`) remain completely unaltered.
4. **Zero Runtime Code Modification**: No production code, configuration, or database structures were modified.

---

## 2. Dossier File Manifest

| # | File Name | Document Title & Scope | Primary Finding Addressed |
|---|---|---|---|
| **01** | [`01_REGATE_FINDING_RESOLUTION_MATRIX.md`](01_REGATE_FINDING_RESOLUTION_MATRIX.md) | **Master Finding Resolution Matrix**<br>Exhaustive 14-finding tracking matrix covering 8 original unresolved findings, 2 resolved findings, and 6 new re-gate findings with exact contradictions, authoritative files, required corrections, and acceptance criteria. | All Findings (C0-01 through RG-C3-01) |
| **02** | [`02_RELEASE_AND_DATABASE_RECOVERY_RECONCILIATION.md`](02_RELEASE_AND_DATABASE_RECOVERY_RECONCILIATION.md) | **Release and Database Recovery Reconciliation**<br>Codification of the core invariant `APPLICATION ROLLBACK MUST NOT AUTOMATICALLY RESTORE THE DATABASE`, Expand/Contract evolution across rollback candidates, multi-layer physical worker fencing, and 10 deterministic failure walkthroughs. | C0-01 |
| **03** | [`03_SECURITY_AND_PATH_CONTAINMENT_RECONCILIATION.md`](03_SECURITY_AND_PATH_CONTAINMENT_RECONCILIATION.md) | **Security and Path Containment Reconciliation**<br>Service-specific Token Trust Matrix, capability-based durable revocation in PostgreSQL without Redis (`RevokedTokens`), 4-point break-glass governance protocol, normalized segment-boundary path containment, and 15-case negative test suite. | C1-01, RG-C1-01, RG-C1-03, RG-C2-02 |
| **04** | [`04_BACKUP_RECOVERY_RECONCILIATION.md`](04_BACKUP_RECOVERY_RECONCILIATION.md) | **Backup and Disaster Recovery Reconciliation**<br>Correction of `pg_restore --list` scope (header and TOC parseability only; data integrity verified via restore drills), self-sufficient envelope key recovery kit with nonsecret derivation metadata, complete Phase 5 failure acceptance matrix, and RPO/RTO operational targets. | C1-02 |
| **05** | [`05_WINDOWS_ARCHITECTURE_RECONCILIATION.md`](05_WINDOWS_ARCHITECTURE_RECONCILIATION.md) | **Windows Architecture Reconciliation**<br>Definitive Windows Server 2022 + native IIS 10 topology (Traefik excluded on host), dedicated least-privilege service identity (`NT SERVICE\TMKAgent`) with explicit IIS/AppPool rights, authenticated remote PostgreSQL TLS, and agent update reboot recovery. | C1-03, RG-C2-01 |
| **06** | [`06_PHASE_0_5_SCHEMA_INVENTORY.md`](06_PHASE_0_5_SCHEMA_INVENTORY.md) | **Phase 0.5 Schema Inventory & Acceptance Specification**<br>Source-backed inventory of exactly 13 maintenance properties across 2 real entities (8 on `Product` + 5 on `ProjectService`), mandatory neutralization of competing raw DDL in `DataSeeder.cs:46-168`, and EF Core single-schema-authority acceptance contract. | RG-C1-02, C2-01 |
| **07** | [`07_TRACEABILITY_RECONCILIATION.md`](07_TRACEABILITY_RECONCILIATION.md) | **Traceability and Substantive Historical Obligations**<br>Deconstruction of compound findings preserving substantive obligations for F01, F02, F15, F16 (F16.1–F16.5 with F16.5 mapped to MR-16), F22, DEF-08, and DEF-15. | C1-04 |
| **08** | [`08_EVIDENCE_INTEGRITY_RECONCILIATION.md`](08_EVIDENCE_INTEGRITY_RECONCILIATION.md) | **Evidence Integrity and Precision Reconciliation**<br>Three-tier documentation boundary, static code citation corrections, operational targets distinction, and mechanical verification script specification. | C2-04, C3-01 |
| **09** | [`09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md`](09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md) | **Repository-Wide Consistency and Semantic Search Scan**<br>Systematic search of all 28 Phase 0 markdown files for 11 critical architectural concepts, verifying 100% resolution of all 14 detected stale contradictions. | Repository Consistency |
| **10** | [`PHASE_0_REGATE_REMEDIATION_FINAL_REPORT.md`](PHASE_0_REGATE_REMEDIATION_FINAL_REPORT.md) | **Final Remediation Report**<br>Executive summary, baseline configuration SHAs, comprehensive finding resolution summaries, and formal certification recommendation. | Final Synthesis |
| **11** | [`README.md`](README.md) | **Dossier Index and Navigation Guide**<br>This directory index and architectural summary. | Navigation |

---

## 3. Core Architectural Invariants Frozen

1. **Database Restore Decoupling**:
   `APPLICATION ROLLBACK MUST NOT AUTOMATICALLY RESTORE THE DATABASE.`
   Application rollback returns code and routing to a compatible release. Database recovery is strictly an explicit disaster recovery operation requiring human authorization (`--confirm-destructive-data-loss`), system quiescing, an ad-hoc safety dump, and loss-window acceptance.
2. **Expand/Contract Across Rollback Candidates**:
   Schema evolution guarantees compatibility across Release $N$ and active rollback candidate $N-1$. Columns required by $N$ are retained during $N+1$ deployment and dropped only in $N+2$.
3. **No-Redis Gate A Profile**:
   Redis is designated `Optional / Not Gate-A Certified Dependency`. Token revocation operates durably via PostgreSQL `RevokedTokens` + in-memory cache, surviving restarts.
4. **Normalized Segment-Boundary Containment**:
   Deployment writes are restricted strictly to server-registered roots assigned to the tenant/service. Client-supplied arbitrary roots are rejected. Normalized segment boundaries prevent sibling-prefix bypasses (`tenant-a` vs `tenant-ab`), UNC shares, cross-drive paths, and Zip Slip escapes.
5. **Windows Native IIS Ingress**:
   Windows Server 2022 hosts run native IIS 10 and `HTTP.sys` owning ports 80/443 directly. Traefik is excluded on Windows hosts. Workloads connect to remote PostgreSQL 16 over authenticated TLS (`Trust Server Certificate=false`). `TMK.Agent.Windows` runs under a dedicated least-privilege service identity (`NT SERVICE\TMKAgent`).
6. **Single Schema Authority**:
   Versioned EF Core migrations are the sole authority for database evolution. Raw DDL in `DataSeeder.cs:46-168` is neutralized/disabled before Phase 0.5 acceptance.

---

## 4. Verification and Governance Tooling

The mechanical verification script validates all register sets, target references, mirror parity, and scans for forbidden stale phrases:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-baseline-integrity.ps1
```
Expected output: **Exit Code 0 (ALL CHECKS PASSED)**.
