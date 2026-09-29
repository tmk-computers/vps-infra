# PHASE 0 FINAL FORENSIC AUDIT & RECONCILIATION REPORT

**Document ID**: `REMED-P0-REPORT`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Recommendation Status**: `READY FOR INDEPENDENT PHASE 0 REVIEW`  

---

## 1. Dual-OS Non-Negotiable Mandate

> [!IMPORTANT]
> ### 🚨 DUAL-OS NON-NEGOTIABLE ARCHITECTURAL MANDATE
> - **Equal First-Class Target Platforms**: Linux (Ubuntu 24.04 LTS) and Windows Server (Windows Server 2022) are **equal first-class target platforms** for this remediation program. Both operating systems have been analyzed independently and must achieve strict outcome parity.
> - **No False Equivalences**: Linux success MUST NOT be used as evidence of Windows success, and Windows deficiencies MUST NOT be deferred merely to simplify a Linux-only launch.
> - **No Conversion to Linux-Only MVP**: This program will NOT be converted into a Linux-only MVP. While Linux may operationally start a controlled pilot earlier under Phase 13 if it passes Linux Gate A first, Windows remediation (Phase 4, Phase 11, Phase 12) remains part of the same active program and must continue until Windows Gate A and the Phase 15 Dual-OS Commercial Gate are achieved.
> - **Separate Certification Gates**: Linux Gate A and Windows Gate A are independent certification gates. Neither platform inherits certification from the other.

---

## 2. Repository Baseline

The authoritative engineering baseline has been verified and frozen across both repositories with clean working trees:

### Repository 1: `vps-infra`
- **Branch**: `main`
- **Local HEAD SHA**: `780e8b4f152e039e9ee31ed46c71811e04947f7b`
- **Remote HEAD SHA**: `780e8b4f152e039e9ee31ed46c71811e04947f7b` (`origin/main`)
- **Working Tree**: Clean (`nothing to commit, working tree clean`)
- **Delta Commits**: 6 commits ahead of historical audit baseline `eab8df65aaf708875a922cf87c655d86156f402a`.

### Repository 2: `vps-infra-server`
- **Branch**: `main`
- **Local HEAD SHA**: `36354a32884fd0c03470d2b3f5333776f7aed6c9`
- **Remote HEAD SHA**: `36354a32884fd0c03470d2b3f5333776f7aed6c9` (`origin/main`)
- **Working Tree**: Clean (`nothing to commit, working tree clean`)
- **Delta Commits**: 10 commits ahead of historical audit baseline `a1f4a51ed3fb9e9751f83ec191a29f04e6971d32`.

---

## 3. Audit Reconciliation Summary

Reconciliation of all 59 historical findings (Codex F01–F22, Antigravity DEF-01–DEF-37) and 4 new current-main findings (MR-34–MR-37) yields the following authoritative status distribution across the 37 Master Remediation Register items:

| Status Category | Master Remediation Count | Percentage | Definition |
| :--- | :---: | :---: | :--- |
| **OPEN** | **33 Items** | 89.2% | Required behavior is absent or clearly defective in source code / config. |
| **PARTIALLY_IMPLEMENTED** | **3 Items** | 8.1% | Code exists, but safety boundaries, error handling, or verification missing (`MR-14`, `MR-17`, `MR-30`). |
| **IMPLEMENTED_NOT_VERIFIED** | **1 Item** | 2.7% | Code exists (email alerting in `DockerEventsBackgroundService.cs`), but runtime delivery unverified (`MR-18`). |
| **CLOSED_WITH_EVIDENCE** | **0 Items** | 0.0% | Zero findings closed without executable verification proof. |
| **SUPERSEDED** | **0 Items** | 0.0% | No finding superseded without formal architecture replacement. |
| **INCORRECT_AUDIT_ASSERTION** | **2 Assertions** | — | (1) Antigravity DEF-09 citing non-existent `MonitoringBackgroundService.cs`; (2) Antigravity audit asserting `db/redis` manifest exists. |
| **NOT_APPLICABLE** | **0 Items** | 0.0% | All 37 master items apply to the approved platform roadmap. |

---

## 4. Explicit P0 (Critical / Pilot Blocker) Findings

The following **14 items** represent critical vulnerabilities or fatal defects that must be resolved prior to pilot qualification:

1. **MR-01**: Untrusted CI test runner receives host Docker socket (`/var/run/docker.sock`), allowing arbitrary host root compromise (F01, DEF-08).
2. **MR-02**: Published signing defaults allow forging privileged JWT identities; setup copies static default keys (F02, DEF-04).
3. **MR-03**: Committed Google Cloud Service Account RSA private key tracked in repository (`google-drive-credentials.json`) (F03, DEF-05).
4. **MR-06**: Database ports (`5432`, `3306`) and admin UIs (`5050`, `8082`) published to `0.0.0.0`, bypassing UFW firewall (F07, DEF-03).
5. **MR-10**: Linux deployment reports success without application readiness verification (F08, DEF-01).
6. **MR-12**: Rollback engine lacks immutable digests and restores to mutable branch `main`, re-pulling broken images (F08, F10, DEF-13).
7. **MR-14**: Offsite backup success logged before upload outcome; return status unchecked; local dump only on single host (F11, DEF-02).
8. **MR-19**: Upgrade script executes `git reset --hard origin/main`, takes no DB backup, fakes health verification, and has no rollback (F18).
9. **MR-22**: IIS Agent script in `vps-infra` has fatal AST syntax error (missing catch block); SCM fails with Error 1053 (F09, DEF-28, DEF-29).
10. **MR-23**: Windows Agent binds only to `127.0.0.1:5055`, preventing Docker control-plane connectivity (DEF-30).
11. **MR-27**: `setup.ps1` prompts user to stop IIS (`W3SVC`) to free ports 80/443, breaking native Windows hosting (DEF-35).
12. **MR-28**: Windows Agent uses hardcoded fallback bearer secret `"SuperCiSecretKey123!"` (DEF-36).
13. **MR-34**: Maintenance Mode fields added to entities without EF Core migration or seeding DDL; PostgreSQL instances crash on query (Current-Main).
14. **MR-35**: Compose regex replacement in `MaintenanceService.cs` contaminates all services in `docker-compose.yml` (Current-Main).

---

## 5. Pilot Gate A Blockers by Operating System

### Shared Pilot Blockers (15 Items):
- `MR-02`: Signing / Authentication Defaults
- `MR-03`: Leaked / Committed Credentials
- `MR-04`: Git Tokens & Secret Disclosure
- `MR-07`: Secure Secret Provisioning
- `MR-08`: RBAC / Customer Roles & Tenancy
- `MR-09`: Durable Deployment Execution
- `MR-11`: Immutable Releases
- `MR-12`: Compatible Rollback
- `MR-13`: Schema / Migration Integrity
- `MR-14`: Offsite Backup Verification
- `MR-15`: Strict Restore / Disaster Recovery
- `MR-18`: External Monitoring & Outbound Alerting
- `MR-19`: Upgrade Safety Engine
- `MR-32`: License-Independent Recovery / Export
- `MR-34`: Maintenance Schema Migration Safety
- `MR-36`: AMS Authorization & CI Authentication
- `MR-37`: AMS Semantics & Commercial Truthfulness

### Linux-Specific Pilot Blockers (6 Items):
- `MR-01`: CI / Host Trust Boundary (Docker Socket Isolation)
- `MR-05`: Database Least Privilege
- `MR-06`: Database / Admin Network Exposure (`0.0.0.0` Bindings)
- `MR-10`: Truthful Deployment Verification (Readiness Probes)
- `MR-16`: Resource Admission & Limits (cgroup Capping)
- `MR-35`: Maintenance State Consistency & Service Isolation

### Windows-Specific Pilot Blockers (8 Items):
- `MR-22`: Windows Agent Executable Architecture (`TMK.Agent.Windows` Service)
- `MR-23`: Windows Control-Plane Connectivity
- `MR-24`: Windows Deployment Filesystem Sandbox
- `MR-25`: Windows Telemetry Correctness (Per-AppPool PID Mapping)
- `MR-26`: Windows Agent Concurrency (Async Request Handling)
- `MR-27`: Windows IIS / Ingress Coexistence (Port 80/443 Resolution)
- `MR-28`: Windows Agent Authentication (Dynamic Secrets)
- `MR-29`: Windows Artifact Pipeline (Cross-Compilation / Packaging)

---

## 6. Newly Discovered Current-Main Findings (MR-34 — MR-37)

1. **MR-34: Maintenance Schema Migration Gap (`Product.cs`, `ProjectService.cs`)**:
   - Commits `4c40800` and `3078a13` introduced 13 new properties across two database entities without an EF Core migration.
   - Tests passed only due to `.UseInMemoryDatabase()`. Real PostgreSQL deployments will fail with missing column errors.
2. **MR-35: Compose Mutation Regex Contamination (`MaintenanceService.cs`)**:
   - Global regex replace updates `SystemStatus__IsMaintenance` across all services in `docker-compose.yml`. Toggling one service affects all services in the file.
3. **MR-36: AMS Authorization & CI Auth Breakdown (`server.js`, `ProductController.cs`)**:
   - `optionalAuth` leaves AMS endpoints unauthenticated to external network callers.
   - `ProductController` calls CI server without a Bearer token, causing recalculations to fail with HTTP 401 Unauthorized.
4. **MR-37: AMS Semantics & Commercial Truthfulness (`modernization-engine.js`)**:
   - AMS is a static string/heuristic pattern analyzer; it does not execute tests or verify runtime stability. It must be clearly labeled as static analysis rather than production readiness.

---

## 7. Architecture Decisions Frozen

1. **Equal Dual-OS Platform Parity (ADR-01)**:
   - Shared Platform Core (Identity, Secrets, Deployment State Machine, Backup/DR, Telemetry) decoupled from OS Adapters.
   - Linux Adapter utilizes Docker Compose, Traefik, and cgroup governance.
   - Windows Adapter will transition from `tmk-iis-agent.ps1` to a compiled `.NET Worker` Windows Service (`TMK.Agent.Windows`).
2. **Release State Machine (ADR-02)**:
   - 5-stage contract: `PRECHECK` → `PREPARED` → `APPLYING` → `VERIFYING` → `SUCCEEDED`.
   - Automatic rollback to immutable content-addressed digests on failure.
   - Server startup reconciliation replacing blind `INTERRUPTED` database writes.
3. **CI Architecture Bifurcation (ADR-03)**:
   - Gate A certifies External Isolated CI (GitHub Actions).
   - Integrated CI retained for development; requires rootless daemon, cgroups, and network isolation before production qualification.
4. **Database Scope Limitation (ADR-04)**:
   - Gate A certifies PostgreSQL 16 exclusively.
   - Oracle, MariaDB, SQL Server, and Redis are explicitly blocked/deferred in Gate A profiles.

---

## 8. Phase 1 Proposed Scope

Phase 1 (Shared Security Foundation) will implement exclusively:
- **MR-03**: Revoke leaked service account RSA private key in Google Cloud IAM; purge `devops-manager/api/google-drive-credentials.json` from git tracking.
- **MR-02 & MR-07**: Implement dynamic high-entropy secret generation in setup scripts; fail API boot on static fallback keys.
- **MR-04**: Strip Git tokens and sensitive secrets from read DTOs; implement credential encryption at rest; sanitize webhook logging.
- **MR-08**: Enforce JWT tenant context extraction and tenant-scoped query filtering across all entity queries and CI authorizations.
- **MR-34**: Create versioned EF Core migration for Maintenance Mode fields; update `DataSeeder.cs` with defensive idempotent DDL.
- **MR-36**: Secure AMS routes in `ci-server` with `authenticateToken`; inject Bearer authentication in `ProductController` proxy requests.
- **MR-37**: Update AMS UI labels and documentation to "Static Architectural Modernization".

---

## 9. Evidence Gaps Requiring Live Infrastructure Validation

The following items cannot be fully proven via static code review and require live disposable infrastructure testing during subsequent phases:
1. End-to-end SMTP email alert delivery from `DockerEventsBackgroundService.cs` to an external mailbox.
2. Complete bare-metal PostgreSQL restoration from Google Drive offsite storage on a freshly provisioned host.
3. Windows Service Control Manager (SCM) lifecycle handling and port coexistence on a live Windows Server 2022 instance.
4. CI build worker resource capping under synthetic memory exhaustion stress tests.

---

## 10. Developer Recommendation

### **`READY FOR INDEPENDENT PHASE 0 REVIEW`**

> [!IMPORTANT]
> In strict accordance with Phase 0 governance:
> - **Zero runtime or production implementation was changed during this phase.**
> - **No database migrations or code fixes were applied.**
> - **Phase 0 PASS cannot be declared by the Developer; acceptance rests exclusively with the independent Reviewer and the Codex Audit Gate.**
