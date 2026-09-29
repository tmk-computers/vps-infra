# 16 PHASEWISE REMEDIATION ROADMAP (PHASE 0 — PHASE 15)

**Document ID**: `REMED-P0-16`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Baseline Date**: 2026-09-29  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Dual-OS Governance Principles & Sequencing Rules

> [!IMPORTANT]
> ### 🚨 DUAL-OS NON-NEGOTIABLE ROADMAP MANDATE
> 1. **Equal First-Class Tracks**: Linux and Windows Server are parallel, equal, first-class target platforms. Windows deficiencies are NOT deferred to simplify a Linux-only launch.
> 2. **Prohibition of Linux-Only MVP Conversion**: This program must NOT be converted into a Linux-only MVP. While Linux may operationally start a controlled pilot earlier under Phase 13 if it passes Linux Gate A first, Windows remediation (Phase 4, Phase 11, Phase 12) remains part of the same active program and must continue until Windows Gate A and the Phase 15 Dual-OS Commercial Gate are achieved.
> 3. **Outcome Parity**: Both operating systems must satisfy identical deployment safety, health verification, rollback integrity, and telemetry truthfulness standards.
> 4. **Deterministic Infrastructure Before AI**: Core deployment safety, database persistence, and disaster recovery take absolute priority over experimental AI features.

---

## 2. Master 16-Phase Execution Roadmap

```mermaid
gantt
    title Master Remediation Execution Roadmap (Equal Dual-OS Tracks)
    dateFormat  X
    axisFormat  Phase %s

    section Foundation & Security
    Phase 0 : Current-State Reconciliation & Baseline Freeze :active, p0, 0, 1
    Phase 0.5 : Maintenance Mode Schema Prerequisite (MR-34) :p05, after p0, 1
    Phase 1 : Shared Security Foundation (MR-02..08, 28, 36) :p1, after p05, 1
    Phase 2 : Shared Release Safety Engine (MR-09..13, 35) :p2, after p1, 1

    section Operating System Adapters (Equal Priority)
    Phase 3 : Linux Production Adapter (MR-01, 20) :p3, after p2, 1
    Phase 4 : Windows Production Agent & IIS Adapter (MR-22..27, 29) :p4, after p3, 1

    section Reliability & Governance
    Phase 5 : Backup, Restore & Disaster Recovery (MR-14, 15) :p5, after p4, 1
    Phase 6 : Resource Safety & Admission (MR-16, 17) :p6, after p5, 1
    Phase 7 : External Monitoring & Outbound Alerting (MR-18) :p7, after p6, 1

    section Operations & Upgrades
    Phase 8 : Infra Doctor Diagnostic Engine (MR-30) :p8, after p7, 1
    Phase 9 : Supportability, Documentation Truth & AMS (MR-21, 31, 37) :p9, after p8, 1
    Phase 10 : Platform Upgrade & Customer Break-Glass (MR-19, 32) :p10, after p9, 1

    section Verification & Pilot Gates
    Phase 11 : Dual-OS Failure Injection & Chaos Testing (MR-33) :p11, after p10, 1
    Phase 12A : Independent Linux Gate A Certification :p12a, after p11, 1
    Phase 12B : Independent Windows Gate A Certification :p12b, after p11, 1
    Phase 13A : Controlled Linux Startup Pilot (Staggered Option) :p13a, after p12a, 1
    Phase 14 : Pilot Hardening & Operational Feedback :p14, after p13a, 1
    Phase 15 : Dual-OS Commercial Enterprise Gate B :p15, after p14, 1
```

*(Note: Staggered Pilot Override: If Linux Gate A (Phase 12A) passes first, Linux Pilot (Phase 13A) can proceed while Windows remediation actively continues through Phase 12B. Phase 15 remains the unified Dual-OS Commercial Gate.)*

---

## 3. Detailed Phase Breakdown & Scope Allocation

### Phase 0 — Current-State Reconciliation & Architecture Freeze (CURRENT)
- **Scope**: Reconcile Codex F01–F22, Antigravity DEF-01–DEF-37, post-audit commits; freeze target architecture and Master Register (MR-01–MR-37); establish the Dual-OS Non-Negotiable mandate; zero runtime code changes.
- **Deliverable**: Complete `docs/remediation/phase-0/` artifact suite.

### Phase 0.5 — Centralized Maintenance Mode Schema Prerequisite
- **Target MR ID**: **MR-34**
- **Rationale & Scope**: Standalone architectural prerequisite preceding Phase 1 runtime testing.
  - **Single Schema Authority**: Author versioned EF Core migration `20261001000000_AddMaintenanceModeEntities.cs` adding all 13 columns to `Products`, `ProjectServices`, and `MaintenanceWindows`.
  - **DataSeeder Rule**: Prohibit adding competing raw `ALTER TABLE` DDL to `DataSeeder.cs`. Seeder is bounded purely to data population; raw DDL removal scheduled for Phase 2 (MR-13).
  - **Acceptance Contract**: Pass all 5 test scenarios (fresh install, upgrade from existing schema, zero data loss, entity query test, idempotency) defined in `docs/remediation/phase-0-codex-remediation/07_PHASE_0_5_SCHEMA_AUTHORITY.md`.

### Phase 1 — Shared Security Foundation
- **Core Security Scope (9 Items)**: **MR-02**, **MR-03**, **MR-04**, **MR-05**, **MR-06**, **MR-07**, **MR-08**, **MR-28**, **MR-36**.
- **Scope & Explicit Sub-Obligation Traceability**:
  - **MR-02 & MR-07** (Dynamic Secrets & Signing Defaults — P0/P1): Eliminate published JWT keys and default passwords across all setup scripts (`setup.sh`, `setup.ps1`); enforce startup failure on default secrets. F16.1: Encrypt AI API keys at rest (AES-256-GCM). F16.2: Enforce monotonic streaming spend budget cap. (F16.3/F16.4 gated under AI disablement for Gate A).
  - **MR-03** (Leaked Service Account Key — P0): Revoke Google Cloud service account RSA private key in Google Cloud IAM; purge `devops-manager/api/google-drive-credentials.json` from git history.
  - **MR-04** (Git Tokens, Secret Disclosure & Path Traversal — P1): Strip Git PATs and sensitive secrets from read DTOs; implement credential protection; sanitize webhook and process logging. DEF-15: Canonicalize `ProjectDirectory` via `Path.GetFullPath` prefix check against tenant sandbox root.
  - **MR-05 & MR-06** (Database Least Privilege & Network Exposure — P1/P0): Bind PostgreSQL, Redis, and admin ports to `127.0.0.1` or internal Docker overlay bridge (MR-06), and provision isolated least-privilege roles per application container (MR-05).
  - **MR-08** (Multi-Tenant RBAC, Role Separation & Container Hardening — P1): DEF-11: Formally separate `PlatformSuperAdmin` from `TenantAdmin`; no tenant SuperAdmin global bypass. DEF-08: Drop Linux capabilities (`cap_drop: ALL`), run API container as non-root UID 10001, remove host root mount, use scoped Unix socket proxy. Enforce JWT tenant context extraction (`tid`) across all routes.
  - **MR-28** (Windows Agent Dynamic Authentication — P0): Replace hardcoded static fallback secret `"SuperCiSecretKey123!"` with dynamically provisioned mutual authentication secrets between `devops-manager` and `tmk-iis-agent`.
  - **MR-36** (Token Trust Contract & Inter-Service Auth — P1): Enforce Token Trust Contract (`iss`, `aud`, `sub`, `tid`, algorithm, rotation, revocation). Secure AMS endpoints in `ci-server`; inject service bearer tokens in inter-service calls. All 9 Phase 1 negative tests must pass.
- **Scope Exclusion**:
  - **MR-37** (AMS Semantics & UI Labeling): Relates to calculation heuristics and marketing truthfulness rather than security boundaries. Relocated to Phase 9 alongside MR-21, with pre-pilot disclosure provided for pilots.

### Phase 2 — Shared Release Safety Engine
- **Target MR IDs**: **MR-09**, **MR-10**, **MR-11**, **MR-12**, **MR-13**, **MR-35**.
- **Scope**:
  - Implement durable Deployment State Machine (`PRECHECK` → `PREPARED` → `APPLYING` → `VERIFYING` → `SUCCEEDED`).
  - Replace unmanaged fire-and-forget tasks with bounded background queue (MR-09).
  - Gated release success on passing HTTP readiness probes (MR-10).
  - Enforce immutable content-addressed release identifiers; ban `main` / `latest` (MR-11).
  - Implement automated pre-deployment snapshots and transactional rollback (MR-12).
  - Replace regex Compose string manipulation with AST-aware YAML parser (MR-35).

### Phase 3 — Linux Production Adapter
- **Target MR IDs**: **MR-01**, **MR-20**.
- **Scope**:
  - Remove production Docker socket and host root from CI test runners; isolate builds to disposable sandbox (MR-01).
  - Enforce unsupported feature gates (block Oracle/MariaDB/Redis in Gate A deployment pipeline) (MR-20).

### Phase 4 — Windows Production Agent & IIS Adapter (Equal First-Class Priority)
- **Target MR IDs**: **MR-22**, **MR-23**, **MR-24**, **MR-25**, **MR-26**, **MR-27**, **MR-29**.
- **Scope**:
  - Implement compiled .NET Worker Windows Service (`TMK.Agent.Windows`) with SCM integration, replacing `tmk-iis-agent.ps1` (MR-22).
  - Configure HttpListener to accept container network requests (MR-23).
  - Constrain extraction to approved application sandbox; enforce NTFS ACLs (MR-24).
  - Fix telemetry to map AppPool names to specific worker process PIDs (MR-25).
  - Implement asynchronous request processing in daemon (MR-26).
  - Establish port coexistence between Traefik and IIS without stopping `W3SVC` (MR-27).
  - Implement cross-compilation pipeline for Windows .NET artifacts (MR-29).
  *(Note: MR-28 Windows Agent Dynamic Authentication is delivered in Phase 1 for dual-OS security parity).*

### Phase 5 — Backup, Restore & Disaster Recovery
- **Target MR IDs**: **MR-14**, **MR-15**.
- **Scope**:
  - Implement 4-stage backup pipeline with independent remote checksum verification (MR-14).
  - Implement automated pre-restore database snapshot (MR-15).
  - Fail restores on non-zero exit codes; validate row-count integrity invariants.
  - Test bare-metal source-host-loss recovery simulation on disposable VM.

### Phase 6 — Resource Safety & Storage Governance
- **Target MR IDs**: **MR-16**, **MR-17**.
- **Scope**:
  - Enforce hard cgroup memory, CPU, and PID limits on builds and containers (MR-16).
  - Implement capacity admission control checking host free RAM and disk headroom.
  - Implement non-destructive storage cleanup preserving minimum 3 rollback digests (MR-17).
  - Add 30-day scheduled retention pruning for `SystemLogs` table.

### Phase 7 — External Monitoring & Outbound Alerting
- **Target MR IDs**: **MR-18**.
- **Scope**:
  - Validate end-to-end SMTP email alert delivery in live test.
  - Add generic outbound Webhook channel for Slack/Discord/custom incident dispatch.
  - Ensure alerting subsystem handles provider failure with local fallback queue.

### Phase 8 — Infra Doctor Diagnostic Engine
- **Target MR IDs**: **MR-30**.
- **Scope**:
  - Consolidate validation scripts into deterministic diagnostic API and CLI tool across Linux and Windows.
  - Validate OS prerequisites, port availability, disk headroom, and Docker daemon connectivity.

### Phase 9 — Supportability, Documentation Truth & AMS
- **Target MR IDs**: **MR-21**, **MR-31**, **MR-37**.
- **Scope**:
  - Implement 1-click sanitized diagnostic support bundle export endpoint (MR-31).
  - Revise documentation and README to eliminate misleading performance and architectural claims (MR-21).
  - Rebrand AMS in UI and documentation to "Static Architectural Modernization" and clarify that AMS does not evaluate runtime production readiness (MR-37).
  *(Note: Prior to Phase 9, pilot participants receive an explicit Pre-Pilot Operational Disclosure Note covering deterministic AI behavior and AMS static analysis scope).*

### Phase 10 — Platform Upgrades & Customer Break-Glass
- **Target MR IDs**: **MR-19**, **MR-32**.
- **Scope**:
  - Implement pre-upgrade database backup, real HTTP health checks, and automated rollback (MR-19).
  - Provide license-independent export tool ensuring customer data recovery if licensing server is offline (MR-32).

### Phase 11 — Dual-OS Failure Injection & Chaos Validation
- **Target MR IDs**: **MR-33**.
- **Scope**:
  - Automated failure-injection test suite on **BOTH Linux and Windows Server**: crashing containers/AppPools, network partition, cold starts, corrupted dumps.
  - Assert state machine transitions and automated rollback under adverse conditions on both platforms.

### Phase 12 — Independent Linux & Windows Gate A Certification
- **Scope**:
  - Execute full compliance audit against Linux Gate A criteria (Ubuntu 24.04).
  - Execute full compliance audit against Windows Gate A criteria (Windows Server 2022).
  - Issue independent Gate A pass/fail verdicts for each OS.

### Phases 13–15 — Pilot & Commercial Enterprise Gate
- **Phase 13**: Controlled deployment with 1–3 friendly startup pilot customers (Linux pilot may start earlier if ready, while Windows remediation actively completes Gate A).
- **Phase 14**: Pilot hardening, telemetry review, and runbook refinement across dual-OS environments.
- **Phase 15**: Formal Gate B dual-OS multi-tenant enterprise certification for BOTH Linux and Windows Server.
