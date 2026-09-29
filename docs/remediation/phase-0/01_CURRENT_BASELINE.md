# 01 CURRENT REPOSITORY & AUDIT BASELINE

**Document ID**: `REMED-P0-01`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Baseline Date**: 2026-09-29  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Executive Summary

This document establishes the authoritative, frozen engineering baseline across both repositories composing the `VPS-INFRA` platform:
1. `vps-infra` (Infrastructure templates, provisioning scripts, database manifests, deployment scripts)
2. `vps-infra-server` (DevOps Manager .NET API, React Web UI, CI Node.js Server, audit registers)

All historical audit baselines, post-audit commits, git branches, remote tracking states, and working tree statuses have been verified locally without modifying repository history or runtime behavior.

---

## 2. Repository Git State Freeze & State Distinctions

To ensure complete reproducibility and audit traceability (satisfying Codex finding C2-03), three repository states are formally distinguished:
1. **Implementation Baseline (Product Code Frozen)**: The clean git commit of product, runtime, test, and infrastructure files prior to any Phase 0 documentation additions. This code is 100% frozen and untouched.
2. **Documentation Candidate Git HEAD**: The git commit recording the initial Phase 0 engineering dossier and review records.
3. **Working-Tree Candidate**: The working tree containing Developer R0–R3 remediation updates and the authoritative Codex Gate Remediation dossier.

### 2.1 Repository 1: `vps-infra`

- **Workspace Path**: `D:\company\products\vps-infra\vps-infra`
- **Active Branch**: `main`
- **Implementation Baseline SHA (Product Code Frozen)**: `780e8b4f152e039e9ee31ed46c71811e04947f7b` (short: `780e8b4`)
- **Documentation Candidate Git HEAD**: `72758f6c23fc76e62e059e382cf61106567668ab` (short: `72758f6`)
- **Remote Origin**: `git@github.com:tmk-computers/vps-infra.git`
- **Product Code State**: Clean & untouched (0 runtime/product files modified)
- **Working Tree Documentation State**: Phase 0 baseline documents updated; Codex remediation dossier added in `docs/remediation/phase-0-codex-remediation/`
- **Historical Audited Baseline**: `eab8df65aaf708875a922cf87c655d86156f402a` (short: `eab8df6`)
- **Commit Delta Since Historical Baseline**: 6 product commits (`eab8df6..780e8b4`) + 1 documentation commit (`72758f6`)

#### Product Commit Log Since Historical Baseline (`eab8df6..780e8b4`):
1. `780e8b4` — `chore(release): bump version to v2.2.0`
2. `9d119bf` — `fix: mount SSH config in devops-api-prod and pull images on upgrade`
3. `3d876e4` — `docs: document DevOps Manager UI navigation for Application Modernization Score (AMS)`
4. `6fbe5a1` — `docs: add developer integration guide for Centralized Maintenance Mode across APIs, SPAs, and Mobile apps`
5. `f38d787` — `docs(ops): add Application Modernization Score (AMS) operations and architecture guide`
6. `cd2e796` — `docs(maintenance): add Centralized Maintenance Mode Guide with Kaksha+ end-to-end walkthrough`

---

### 2.2 Repository 2: `vps-infra-server`

- **Workspace Path**: `D:\company\products\vps-infra\vps-infra-server`
- **Active Branch**: `main`
- **Implementation Baseline SHA (Product Code Frozen)**: `36354a32884fd0c03470d2b3f5333776f7aed6c9` (short: `36354a3`)
- **Documentation Candidate Git HEAD**: `dba08c63a37eb8d2c851f637d8a02a85cbab4604` (short: `dba08c6`)
- **Remote Origin**: `git@github.com:tmk-computers/vps-infra-server.git`
- **Product Code State**: Clean & untouched (0 runtime/product files modified)
- **Working Tree Documentation State**: Phase 0 baseline documents updated; Codex remediation dossier added in `docs/remediation/phase-0-codex-remediation/`
- **Historical Audited Baseline**: `a1f4a51ed3fb9e9751f83ec191a29f04e6971d32` (short: `a1f4a51`)
- **Commit Delta Since Historical Baseline**: 10 product commits (`a1f4a51..36354a3`) + 1 documentation commit (`dba08c6`)

#### Product Commit Log Since Historical Baseline (`a1f4a51..36354a3`):
1. `36354a3` — `feat(release): support SemVer release versioning and increment to v2.2.0`
2. `9097c59` — `feat: implement UI platform release check and decoupled upgrade runner`
3. `3078a13` — `fix(services): immediately recreate containers when toggling service maintenance mode`
4. `9469671` — `fix(tests): isolate backup test directory and allow configurable backup base path`
5. `f4fec2b` — `feat(devops): surface Application Modernization Score (AMS) directly in DevOps Manager Products UI`
6. `feea40a` — `Pin DevOps API .NET 10 base images`
7. `fd9bf54` — `feat(ci): implement Application Modernization Score (AMS) engine, REST APIs, and dashboard`
8. `4c40800` — `feat(maintenance): add centralized maintenance mode with granular overrides, UI modals, and E2E test suite`
9. `a5f5768` — `Added linux-windows audits`
10. `83fefed` — `Added Codex Audit reports`

---

## 3. Previous Audit Inputs Reconciled

The baseline integrates and resolves findings from all four prior audit bodies:

| Audit Body | Scope | Date | Primary Register | Primary Artifact Location |
| :--- | :--- | :---: | :--- | :--- |
| **Codex Forensic Audit** | Main branch security, host isolation, DR, release | 2026-09-29 | Findings `F01`–`F22` | [`docs/audit/2026-09-29-main/evidence/findings.json`](file:///d:/company/products/vps-infra/vps-infra-server/docs/audit/2026-09-29-main/evidence/findings.json) |
| **Codex Startup GTM Audit** | Sellable product boundary, deferred scope, single-VM | 2026-09-29 | GTM Checklist `M1`–`M10` | [`docs/audit/2026-09-29-startup-gtm/`](file:///d:/company/products/vps-infra/vps-infra-server/docs/audit/2026-09-29-startup-gtm/) |
| **Antigravity Linux Audit** | Linux container deployment, storage, network, CI | 2026-09-29 | Defects `DEF-01`–`DEF-27` | [`docs/audit/2026-09-29-linux-windows-readiness/02_LINUX_IMPLEMENTATION_MAP.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/audit/2026-09-29-linux-windows-readiness/02_LINUX_IMPLEMENTATION_MAP.md) |
| **Antigravity Windows/IIS Audit**| Windows Server, IIS Agent, SCM, port coexistence | 2026-09-29 | Defects `DEF-28`–`DEF-37` | [`docs/audit/2026-09-29-linux-windows-readiness/16_LINUX_WINDOWS_BUG_REGISTER.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/audit/2026-09-29-linux-windows-readiness/16_LINUX_WINDOWS_BUG_REGISTER.md) |

---

## 4. Key Discovery Findings on Post-Audit Commits

Four major functional components were introduced in the commit delta between historical baselines and current HEADs:

1. **Centralized Maintenance Mode (`4c40800`, `3078a13`)**:
   - Added persistent fields to `Product` and `ProjectService` entities.
   - **Critical Gap Identified (MR-34)**: No EF Core migration or `DataSeeder.cs` DDL was generated. Existing PostgreSQL schemas lack the newly required Maintenance Mode columns. Queries against affected entities fail with PostgreSQL SQLSTATE 42703 column-missing errors, propagating as HTTP 500 responses in the application. The PostgreSQL server itself does not crash.
   - **Isolation Defect Identified (MR-35)**: Compose regex replacement mutates environment variables across all services in `docker-compose.yml`.

2. **Application Modernization Score (AMS) (`fd9bf54`, `f4fec2b`)**:
   - Added static AST/regex analyzer in `ci-server/api/modernization-engine.js`.
   - **Auth Defect Identified (MR-36)**: Anonymous endpoints configured in `ci-server` (`optionalAuth`), while backend C# proxy fails with HTTP 401 when calling `/calculate/:productId` due to missing Bearer token.
   - **Truthfulness Defect Identified (MR-37)**: Pure static regex analysis marketed as production readiness.

3. **Platform Upgrade System (`9097c59`, `36354a3`, `780e8b4`)**:
   - Added UI Platform Upgrade Card and background Docker runner for `upgrade-client.sh`.
   - **Safety Defect Preserved (MR-19)**: The underlying script `scripts/upgrade-client.sh` still performs `git reset --hard origin/main`, takes no database backup, lacks health verification in the execution path resulting in unverified success declarations, and has zero automated rollback.

4. **Test & Image Pinning (`feea40a`, `9469671`)**:
   - Pinned `.NET 10` base images in Dockerfile.
   - Isolated backup test directory in unit test mocks.
