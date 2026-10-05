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
- **Working Tree**: Tracked working tree clean (0 modified files; untracked Phase 0 documentation artifacts present in `docs/remediation/`)
- **Delta Commits**: 6 commits ahead of historical audit baseline `eab8df65aaf708875a922cf87c655d86156f402a`.

### Repository 2: `vps-infra-server`
- **Branch**: `main`
- **Local HEAD SHA**: `36354a32884fd0c03470d2b3f5333776f7aed6c9`
- **Remote HEAD SHA**: `36354a32884fd0c03470d2b3f5333776f7aed6c9` (`origin/main`)
- **Working Tree**: Tracked working tree clean (0 modified files; untracked Phase 0 documentation artifacts present in `docs/remediation/`)
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
8. **MR-19**: Upgrade script executes `git reset --hard origin/main`, takes no DB backup, lacks health verification in the execution path resulting in unverified success declarations, and has no rollback (F18).
9. **MR-22**: IIS Agent script in `vps-infra` has fatal AST syntax error (missing catch block); SCM fails with Error 1053 (F09, DEF-28, DEF-29).
10. **MR-23**: Windows Agent binds only to `127.0.0.1:5055`, preventing Docker control-plane connectivity (DEF-30).
11. **MR-27**: `setup.ps1` prompts user to stop IIS (`W3SVC`) to free ports 80/443, breaking native Windows hosting (DEF-35).
12. **MR-28**: Windows Agent uses hardcoded fallback bearer secret `"[REDACTED_COMPROMISED_DEFAULT]"` (DEF-36).
13. **MR-34**: Maintenance Mode fields added to entities without EF Core migration or seeding DDL; existing schemas lack maintenance columns causing PostgreSQL SQLSTATE 42703 errors and HTTP 500 responses on entity queries (PostgreSQL server does not crash) (Current-Main).
14. **MR-35**: Compose regex replacement in `MaintenanceService.cs` contaminates all services in `docker-compose.yml` (Current-Main).

---

## 5. Pilot Gate A Blockers by Operating System

### Shared Pilot Blockers (17 Items):
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

### Cross-Platform Certification Blocker (1 Item):
- `MR-33`: Dual-OS Failure-Injection Certification (Mandatory Phase 11 validation on both Linux and Windows Server prior to Phase 12 Gate A)

### Pilot Gate A Blocker Inventory Summary:
- **Shared Technical Pilot Blockers**: 17 Items (`MR-02`, `MR-03`, `MR-04`, `MR-07`, `MR-08`, `MR-09`, `MR-11`, `MR-12`, `MR-13`, `MR-14`, `MR-15`, `MR-18`, `MR-19`, `MR-32`, `MR-34`, `MR-36`, `MR-37`)
- **Linux-Specific Technical Pilot Blockers**: 6 Items (`MR-01`, `MR-05`, `MR-06`, `MR-10`, `MR-16`, `MR-35`)
- **Windows-Specific Technical Pilot Blockers**: 8 Items (`MR-22`, `MR-23`, `MR-24`, `MR-25`, `MR-26`, `MR-27`, `MR-28`, `MR-29`)
- **Cross-Platform Certification Blocker**: 1 Item (`MR-33`)
- **Total Pilot Gate A Blockers**: **32 Items**
- **Non-Blockers / Scope Governed**: **5 Items** (`MR-17`, `MR-20`, `MR-21`, `MR-30`, `MR-31`)
- **Total Master Remediation Items**: **37 Items**

---

## 6. Newly Discovered Current-Main Findings (MR-34 — MR-37)

1. **MR-34: Maintenance Schema Migration Gap (`Product.cs`, `ProjectService.cs`)**:
   - Commits `4c40800` and `3078a13` introduced 13 new properties across two database entities without an EF Core migration.
   - Tests passed only due to `.UseInMemoryDatabase()`. Existing PostgreSQL schemas lack the newly required Maintenance Mode columns. Queries against affected entities fail with PostgreSQL SQLSTATE 42703 column-missing errors, propagating as HTTP 500 responses in the application. The PostgreSQL server itself does not crash.
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
   - Durable lifecycle: `PENDING` → `PRECHECK` → `PREPARED` → `APPLYING` → `VERIFYING` → `CUTOVER` → `POST_CUTOVER_VERIFY` → `SUCCEEDED`.
   - Single-host per-service atomic locking via PostgreSQL advisory locks and idempotency keys.
   - Separation of stages: Application rollback reverts traffic routing to standby release; does NOT trigger automatic database restore.
   - Expand/Contract schema evolution ensures backward compatibility.
   - Server startup reconciliation replacing blind `INTERRUPTED` database writes without premature promotion.
3. **CI Architecture Bifurcation (ADR-03)**:
   - Gate A certifies External Isolated CI (GitHub Actions).
   - Integrated CI retained for development; requires rootless daemon, cgroups, and network isolation before production qualification.
4. **Database Scope Limitation (ADR-04)**:
   - Gate A certifies PostgreSQL 16 exclusively as the durable relational control-plane store (Linux: containerized; Windows: remote endpoint). Oracle, MariaDB, and SQL Server are explicitly blocked/deferred for customer application database profiles. Redis 7 is included as a first-class standard production caching and acceleration layer (non-authoritative; PostgreSQL remains the sole durable source of truth).

---

## 8. Phase 1 Proposed Scope

### 8.1 Prerequisite Database Alignment (Phase 0.5 / Pre-Validation)
- **MR-34**: Create versioned EF Core migration `20261001000000_AddMaintenanceModeFields.cs` adding exactly 13 maintenance properties across 2 real entities: `Product` (8 fields) and `ProjectService` (5 fields). Versioned EF Core migrations are the SOLE schema evolution authority. Competing raw DDL in `DataSeeder.cs:46-168` MUST be neutralized and disabled prior to Phase 0.5 acceptance (bounding seeder exclusively to seed data insertion; full legacy non-DDL seeder cleanup in Phase 2 MR-13). Pass all 5 PostgreSQL acceptance test scenarios (P05-TC01 to P05-TC05) prior to Phase 1.

### 8.2 Phase 1 Core Security Implementation Scope (9 Items)
Phase 1 (Shared Security Foundation) will implement exclusively:
- **MR-02 & MR-07**: Implement dynamic high-entropy secret generation in setup scripts (`setup.sh`, `setup.ps1`); fail API boot on static fallback keys. F16.1: Encrypt AI API keys at rest. F16.2: Enforce monotonic streaming spend cap. (F16.3/F16.4 gated under Gate-A AI disablement).
- **MR-03**: Revoke leaked service account RSA private key in Google Cloud IAM; purge `devops-manager/api/google-drive-credentials.json` from git history.
- **MR-04**: Strip Git tokens and sensitive secrets from read DTOs; implement credential encryption at rest; sanitize webhook and process logging. DEF-15: Canonicalize `ProjectDirectory` via `Path.GetFullPath` with trailing directory separator / segment-boundary validation against tenant sandbox root.
- **MR-05 & MR-06**: Eliminate public WAN exposure of database and administrative ports (bind to loopback/internal bridge) and provision isolated least-privilege PostgreSQL roles per application container.
- **MR-08**: Multi-tenant RBAC and role separation: formally decouple `PlatformSuperAdmin` from `TenantAdmin` (DEF-11; no tenant SuperAdmin global bypass). DEF-08: Container hardening (UID 10001, drop capabilities, read-only rootfs, scoped socket proxy).
- **MR-28**: Replace hardcoded Windows Agent fallback bearer secret (`"[REDACTED_COMPROMISED_DEFAULT]"` currently present in `scripts/tmk-iis-agent.ps1:21`) with dynamically generated mutual authentication secrets (Dual-OS parity target contract; agent and API fail startup if static fallback secret is present).
- **MR-36**: Comprehensive Token Trust Contract (`iss`, `aud`, `sub`, `tid`, algorithm, rotation, revocation). Pass all 15 Phase 1 negative test criteria (SEC-NEG-01 to SEC-NEG-15).

*(Note: MR-37 is relocated to Phase 9 alongside MR-21; pilot participants receive an explicit Pre-Pilot Operational Disclosure Note).*

---

## 9. Evidence Gaps Requiring Live Infrastructure Validation

The following items cannot be fully proven via static code review and require live disposable infrastructure testing during subsequent phases:
1. End-to-end SMTP email alert delivery from `DockerEventsBackgroundService.cs` to an external mailbox.
2. Complete bare-metal PostgreSQL restoration from Google Drive offsite storage on a freshly provisioned host.
3. Windows Service Control Manager (SCM) lifecycle handling and port coexistence on a live Windows Server 2022 instance.
4. CI build worker resource capping under synthetic memory exhaustion stress tests.

---

## 10. Developer Recommendation

### **`READY FOR PHASE 0 INDEPENDENT RE-REVIEW AFTER CODEX REMEDIATION`**

> [!IMPORTANT]
> In strict accordance with Phase 0 governance:
> 1. All 10 Codex findings (1 C0, 4 C1, 4 C2, 1 C3) have been explicitly remediated.
> 2. Zero runtime, product, configuration, database, or test code was modified (`Runtime/Product/Test/Configuration Code Changed: NO`).
> 3. Zero Phase 0.5 or Phase 1 implementations were initiated.
> 4. Linux (Ubuntu 24.04 LTS) and Windows (Windows Server 2022) remain equal first-class targets with independent Gate A certification tracks.
> - **Zero runtime or production implementation was changed during this phase.**
> - **No database migrations or code fixes were applied.**
> - **Phase 0 PASS cannot be declared by the Developer; acceptance rests exclusively with the independent Reviewer and the Codex Audit Gate.**
