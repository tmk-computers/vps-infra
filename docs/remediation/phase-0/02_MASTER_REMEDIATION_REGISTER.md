# 02 MASTER REMEDIATION REGISTER (MR-01 — MR-37)

**Document ID**: `REMED-P0-02`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Status**: Authoritative Register Frozen for Subsequent Phases  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Governance & Classification Rules

In accordance with Phase 0 audit governance:
- **No Finding Closed Merely Because Code Exists**: Code presence without end-to-end executable verification under operational failure modes is classified as `IMPLEMENTED_NOT_VERIFIED` or `PARTIALLY_IMPLEMENTED`.
- **Prohibited Statuses**: Percentages (e.g., "85% complete") and subjective qualifiers (e.g., "mostly ready") are strictly banned.
- **Authority**: Current source code, configuration files, and executable proofs take absolute precedence over historical audit statements.

### Status Definitions:
1. `OPEN`: Required behavior is absent or demonstrably defective.
2. `PARTIALLY_IMPLEMENTED`: Some required code exists, but safety boundaries, edge cases, or rollback contracts are missing.
3. `IMPLEMENTED_NOT_VERIFIED`: Code appears present, but production-grade live executable evidence is lacking.
4. `CLOSED_WITH_EVIDENCE`: Code exists AND reproducible executable evidence demonstrates the full contract.
5. `SUPERSEDED`: Architectural decisions made the finding no longer directly applicable (documented with replacement).
6. `INCORRECT_AUDIT_ASSERTION`: Previous audit statement is contradicted by current verified code/configuration evidence.
7. `NOT_APPLICABLE`: Finding does not apply to the approved supported product profile.

---

## 2. Master Remediation Register (MR-01 — MR-37)

| Master ID | Remediation Category | Scope | Severity | Current Status | Primary Code Anchor | Historical Traces | Pilot Blocker? |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- | :---: |
| **MR-01** | CI / Host Trust Boundary | Linux | **P0** | `OPEN` | [`ci-server/api/build-runner.js`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/build-runner.js) | Codex F01, Antigravity DEF-08 | **YES** |
| **MR-02** | Signing / Authentication Defaults | Shared | **P0** | `OPEN` | [`ci-server/api/auth.js`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/auth.js), [`setup.sh`](file:///d:/company/products/vps-infra/vps-infra/setup.sh) | Codex F02, Antigravity DEF-04 | **YES** |
| **MR-03** | Leaked / Committed Credentials | Shared | **P0** | `OPEN` | [`devops-manager/api/google-drive-credentials.json`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/google-drive-credentials.json) | Codex F03, Antigravity DEF-05 | **YES** |
| **MR-04** | Git Tokens & Secret Disclosure | Shared | **P1** | `OPEN` | [`ProjectService.cs:GetAllAsync`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/ProjectService.cs) | Codex F04, Codex F20, Antigravity DEF-15 | **YES** |
| **MR-05** | Database Least Privilege | Linux | **P1** | `OPEN` | [`templates/docker-compose.dotnet-api.template.yml`](file:///d:/company/products/vps-infra/vps-infra/templates/docker-compose.dotnet-api.template.yml) | Codex F06 | **YES** |
| **MR-06** | Database / Admin Network Exposure | Linux | **P0** | `OPEN` | [`db/postgres/docker-compose.yml`](file:///d:/company/products/vps-infra/vps-infra/db/postgres/docker-compose.yml) | Codex F07, Antigravity DEF-03 | **YES** |
| **MR-07** | Secure Secret Provisioning | Shared | **P1** | `OPEN` | [`setup.sh:176`](file:///d:/company/products/vps-infra/vps-infra/setup.sh#L176), [`setup.ps1`](file:///d:/company/products/vps-infra/vps-infra/setup.ps1) | Codex F02, F03, Antigravity DEF-04, DEF-20 | **YES** |
| **MR-08** | RBAC / Customer Roles & Tenancy | Shared | **P1** | `OPEN` | [`DeployController.cs:58`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers/DeployController.cs#L58), [`ci-server/api/server.js:77`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/server.js#L77) | Codex F04, F05, Antigravity DEF-06, DEF-11 | **YES** |
| **MR-09** | Durable Deployment Execution | Shared | **P1** | `OPEN` | [`DeployController.cs:92`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers/DeployController.cs#L92), [`DeployService.cs:180`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/DeployService.cs#L180) | Antigravity DEF-07 | **YES** |
| **MR-10** | Truthful Deployment Verification | Linux | **P0** | `OPEN` | [`DeployService.cs:602`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/DeployService.cs#L602) | Codex F08, Antigravity DEF-01, DEF-19 | **YES** |
| **MR-11** | Immutable Releases | Shared | **P1** | `OPEN` | [`DeployService.cs:200`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/DeployService.cs#L200) | Codex F10, Antigravity DEF-13 | **YES** |
| **MR-12** | Compatible Rollback | Shared | **P0** | `OPEN` | [`DeployService.cs:245-280`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/DeployService.cs#L245-L280) | Codex F08, F10, F13, Antigravity DEF-01, DEF-13, DEF-18 | **YES** |
| **MR-13** | Schema / Migration Integrity | Shared | **P1** | `OPEN` | [`DataSeeder.cs:48-167`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs#L48-L167) | Codex F17 | **YES** |
| **MR-14** | Offsite Backup Verification | Shared | **P0** | `PARTIALLY_IMPLEMENTED` | [`DatabaseBackupBackgroundService.cs:471`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DatabaseBackupBackgroundService.cs#L471) | Codex F11, Antigravity DEF-02 | **YES** |
| **MR-15** | Strict Restore / Disaster Recovery | Shared | **P1** | `OPEN` | [`DisasterRecoveryService.cs:196`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/DisasterRecoveryService.cs#L196) | Codex F12, F19, Antigravity DEF-18 | **YES** |
| **MR-16** | Resource Admission & Limits | Shared | **P1** | `OPEN` | [`ci-server/api/build-runner.js:230`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/build-runner.js#L230) | Codex F14, F16.5, Antigravity DEF-12 | **YES** |
| **MR-17** | Safe Cleanup & Retention | Linux | **P1** | `PARTIALLY_IMPLEMENTED` | [`MonitoringService.cs:234-315`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs#L234-L315), [`DockerCleanupBackgroundService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs) | Codex F13, Antigravity DEF-16, DEF-21 | No (Phase 6) |
| **MR-18** | External Monitoring & Alerting | Shared | **P1** | `IMPLEMENTED_NOT_VERIFIED` | [`DockerEventsBackgroundService.cs:215`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerEventsBackgroundService.cs#L215) | Antigravity DEF-09 (Reconciled) | **YES** |
| **MR-19** | Upgrade Safety Engine | Shared | **P0** | `OPEN` | [`scripts/upgrade-client.sh:170`](file:///d:/company/products/vps-infra/vps-infra/scripts/upgrade-client.sh#L170), [`SystemController.cs:257`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers/SystemController.cs#L257) | Codex F18 | **YES** |
| **MR-20** | Unsupported Feature Enforcement | Shared | **P1** | `OPEN` | [`DeployService.cs:589`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/DeployService.cs#L589) | Codex Startup M5, Antigravity DEF-14, DEF-26 | No (GTM) |
| **MR-21** | Honest Product Claims / Docs | Shared | **P2** | `OPEN` | [`InteractiveCopilotService.cs:126`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/InteractiveCopilotService.cs#L126), [`README.md`](file:///d:/company/products/vps-infra/vps-infra/README.md) | Codex F21, Antigravity DEF-10, DEF-22, DEF-25 | No (Phase 9) |
| **MR-22** | Windows Agent Executable Architecture | Windows | **P0** | `OPEN` | [`vps-infra/scripts/tmk-iis-agent.ps1:345`](file:///d:/company/products/vps-infra/vps-infra/scripts/tmk-iis-agent.ps1#L345) | Codex F09, Antigravity DEF-28, DEF-29 | **YES (Win)** |
| **MR-23** | Windows Control-Plane Connectivity | Windows | **P0** | `OPEN` | [`scripts/tmk-iis-agent.ps1:32`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1#L32) | Antigravity DEF-30 | **YES (Win)** |
| **MR-24** | Windows Deployment Sandbox | Windows | **P1** | `OPEN` | [`scripts/tmk-iis-agent.ps1:232`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1#L232) | Antigravity DEF-32 | **YES (Win)** |
| **MR-25** | Windows Telemetry Correctness | Windows | **P1** | `OPEN` | [`IisClientService.cs:395-404`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs#L395-L404) | Antigravity DEF-33 | **YES (Win)** |
| **MR-26** | Windows Agent Concurrency | Windows | **P1** | `OPEN` | [`scripts/tmk-iis-agent.ps1:114`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1#L114) | Antigravity DEF-34 | **YES (Win)** |
| **MR-27** | Windows Native Ingress & Binding Management | Windows | **P0** | `OPEN` | [`setup.ps1:440-459`](file:///d:/company/products/vps-infra/vps-infra/setup.ps1#L440-L459) | Antigravity DEF-35 (Superseded by Native IIS Ingress) | **YES (Win)** |
| **MR-28** | Windows Agent Authentication | Windows | **P0** | `OPEN` | [`scripts/tmk-iis-agent.ps1:21`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1#L21), [`IisClientService.cs:42`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs#L42) | Antigravity DEF-36 | **YES (Win)** |
| **MR-29** | Windows Artifact Pipeline | Windows | **P1** | `OPEN` | [`ci-server/api/build-runner.js`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/build-runner.js) | Antigravity DEF-37 | **YES (Win)** |
| **MR-30** | Infra Doctor Diagnostics Engine | Shared | **P1** | `PARTIALLY_IMPLEMENTED` | [`scripts/validate-admin.sh`](file:///d:/company/products/vps-infra/vps-infra/scripts/validate-admin.sh), [`validate-admin.ps1`](file:///d:/company/products/vps-infra/vps-infra/scripts/validate-admin.ps1) | Antigravity DEF-23, Codex Startup GTM | No (Pilot) |
| **MR-31** | Support Bundle & Runbooks | Shared | **P2** | `OPEN` | [`DiagnosticsController.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers) | Antigravity DEF-17, DEF-24 | No (Assisted)|
| **MR-32** | License-Independent Recovery / Export | Shared | **P1** | `OPEN` | [`LicenseHeartbeatBackgroundService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/LicenseHeartbeatBackgroundService.cs) | Codex Startup GTM | **YES** |
| **MR-33** | Dual-OS Failure-Injection Certification | Shared | **P1** | `OPEN` | [`DevopsPanel.Tests/`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/DevopsPanel.Tests/) | Antigravity DEF-27 | **YES (Cert)** |
| **MR-34** | Maintenance Schema Migration Safety | Shared | **P0** | `OPEN` | [`Entities/Product.cs:15`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/Product.cs#L15), [`Entities/ProjectService.cs:36`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/ProjectService.cs#L36) | Current-Main commit `4c40800` | **YES** |
| **MR-35** | Maintenance State & Service Isolation | Linux | **P0** | `OPEN` | [`MaintenanceService.cs:255-295`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MaintenanceService.cs#L255-L295) | Current-Main commits `4c40800`, `3078a13` | **YES** |
| **MR-36** | AMS Authorization & CI Auth | Shared | **P1** | `OPEN` | [`ci-server/api/server.js:623-645`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/server.js#L623-L645), [`ProductController.cs:215-238`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers/ProductController.cs#L215-L238) | Current-Main commit `fd9bf54`, `f4fec2b` | **YES** |
| **MR-37** | AMS Semantics & Truthfulness | Shared | **P1** | `OPEN` | [`modernization-engine.js:48`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/modernization-engine.js#L48), [`APPLICATION_MODERNIZATION_SCORE_GUIDE.md`](file:///d:/company/products/vps-infra/vps-infra/docs/03-OPERATIONS-AND-DEVOPS/APPLICATION_MODERNIZATION_SCORE_GUIDE.md) | Current-Main commit `fd9bf54`, `f38d787` | **YES** |

---

## 3. Register Summary Metrics

- **Total Master Remediation Items**: **37 Items (MR-01 — MR-37)**
- **Status Counts**:
  - `OPEN`: **33 items** (89.2%)
  - `PARTIALLY_IMPLEMENTED`: **3 items** (8.1%) (`MR-14`, `MR-17`, `MR-30`)
  - `IMPLEMENTED_NOT_VERIFIED`: **1 item** (2.7%) (`MR-18`)
  - `CLOSED_WITH_EVIDENCE`: **0 items** (0.0%)
  - `SUPERSEDED`: **0 items**
  - `INCORRECT_AUDIT_ASSERTION`: **0 items** (Captured in Historical Traceability)
  - `NOT_APPLICABLE`: **0 items**
- **Severity Counts**:
  - **P0 (Critical / Pilot Blocker)**: **14 Items** (`MR-01`, `MR-02`, `MR-03`, `MR-06`, `MR-10`, `MR-12`, `MR-14`, `MR-19`, `MR-22`, `MR-23`, `MR-27`, `MR-28`, `MR-34`, `MR-35`)
  - **P1 (High / Major Risk)**: **21 Items** (`MR-04`, `MR-05`, `MR-07`, `MR-08`, `MR-09`, `MR-11`, `MR-13`, `MR-15`, `MR-16`, `MR-17`, `MR-18`, `MR-20`, `MR-24`, `MR-25`, `MR-26`, `MR-29`, `MR-30`, `MR-32`, `MR-33`, `MR-36`, `MR-37`)
  - **P2 (Medium / Truthfulness & Polish)**: **2 Items** (`MR-21`, `MR-31`)
- **Pilot Gate A Classification**:
  - **Shared Pilot Blockers**: 17 Items (`MR-02`, `MR-03`, `MR-04`, `MR-07`, `MR-08`, `MR-09`, `MR-11`, `MR-12`, `MR-13`, `MR-14`, `MR-15`, `MR-18`, `MR-19`, `MR-32`, `MR-34`, `MR-36`, `MR-37`)
  - **Linux-Specific Pilot Blockers**: 6 Items (`MR-01`, `MR-05`, `MR-06`, `MR-10`, `MR-16`, `MR-35`)
  - **Windows-Specific Pilot Blockers**: 8 Items (`MR-22`, `MR-23`, `MR-24`, `MR-25`, `MR-26`, `MR-27`, `MR-28`, `MR-29`)
  - **Cross-Platform Certification Blocker**: 1 Item (`MR-33`)
  - **Total Pilot Gate A Technical Blockers**: **32 Items**
- **Scope-Governed Mandatory Pilot Prerequisites (Pre-Phase 13)**: **5 Items**
  - `MR-17`: Storage Governance & Cleanup (Phase 6; mandatory pre-pilot boundary: aggressive automated cleanup is disabled or bounded, volume mounts preserved, rollback cache protected under MR-12)
  - `MR-20`: Unsupported Feature Enforcement (Phase 3; mandatory pre-pilot boundary: uncertified database engines rejected with HTTP 400; only PostgreSQL 16 permitted)
  - `MR-21`: Honest Product Claims & Documentation (Phase 9; mandatory pre-pilot boundary: pilots receive truthful Operational Disclosure Document; false multi-agent AI claims removed)
  - `MR-30`: Diagnostic Runbook & Tooling (Phase 8; mandatory pre-pilot boundary: standard triage runbook provided to pilot operators prior to pilot cutover)
  - `MR-31`: Support Bundle & Operational Runbooks (Phase 9; mandatory pre-pilot boundary: assisted support runbooks and log collection procedures delivered before pilot deployment)
