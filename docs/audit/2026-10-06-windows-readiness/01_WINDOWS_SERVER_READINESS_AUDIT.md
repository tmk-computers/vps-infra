# Windows Server Developer Environment Readiness Audit Report

**Audit Timestamp:** 2026-10-06T17:42:00+05:30  
**Host Operating System:** Microsoft Windows Server 2019 Standard (Version 10.0.17763, Build 17763, 64-bit)  
**PowerShell Version:** 5.1.17763.7434 (Desktop Edition, CLR 4.0.30319.42000)  
**Host Hardware Capacity:** 16 vCPUs, 64 GB Physical RAM (48 GB Free), 800 GB NVMe Storage (286 GB Free)  
**Auditor:** Independent Implementation-Readiness Auditor  
**Audit Scope:** Read-Only Audit of Candidate Repositories and Windows Server Execution Topology  

---

## 1. Safety & Non-Mutation Attestation

> **EXPLICIT STATEMENT:**  
> **No implementation changes, deployments, migrations, container creations, or service changes were performed during this audit.** Both repositories remain strictly unmodified in their pristine post-clone state.

---

## 2. Repository Identification & Version Control State

Both repositories are valid, intended Git clones located at the specified target paths, cloned directly from their official GitHub remotes on `main`.

| Repository Path | Remote Origin URL | Active Branch | HEAD SHA | `origin/main` SHA | Working Tree Status | Sync / Tracking Status |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| `C:\var\www\vps-infra` | `https://github.com/tmk-computers/vps-infra.git` | `main` | `cbe6db11614ff22875ff0af1c7b3b3f3921c8fb3` | `cbe6db11614ff22875ff0af1c7b3b3f3921c8fb3` | Clean (0 staged, 0 unstaged, 0 untracked) | Up to date with `origin/main` |
| `C:\var\www\vps-infra-server` | `https://github.com/tmk-computers/vps-infra-server.git` | `main` | `a7ccb0c6ee0587105a1be67b24b53603db7540b1` | `a7ccb0c6ee0587105a1be67b24b53603db7540b1` | Clean (0 staged, 0 unstaged, 0 untracked) | Up to date with `origin/main` |

*Notes on Checkout Freshness:*
- `vps-infra` was cloned at 17:17 IST on 2026-10-06.
- `vps-infra-server` was cloned at 17:23 IST on 2026-10-06.
- Both repositories have zero unstaged diffs, zero staged diffs, and zero untracked files.

---

## 3. Reconciliation of the Six-Wave Linux Appliance Roadmap

The six-wave roadmap defined in [`COMMERCIAL_CI_CD_WAVED_EXECUTION_ROADMAP.md`](file:///C:/var/www/vps-infra-server/docs/COMMERCIAL_CI_CD_WAVED_EXECUTION_ROADMAP.md) was reconciled against merged source code, automated test executions, live qualification reports, and deployment evidence.

*Scope Clarification:* The roadmap explicitly governs a **Customer-Managed Linux Appliance** (Ubuntu 22.04/24.04/Debian 12 running Linux containers). Dual-topology refers strictly to Direct DB vs REST Sync modes; native Windows Server support is **not** included in the wave progression.

| Wave | Roadmap Stated Status | Audited Verdict | Implementation (Merged Code) | Automated Tests | Live Qualification Evidence | Deployment & Operational Gaps |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| **Wave 1: Bounded Build Execution & Diagnostics** | ✅ CLOSED | **PASS** | `ci-server/api/diagnostics.js`, `build-runner.js`, schema migrations for `diagnostic_details`, `cleanup_status`, `image_digest` | 15/15 passed (`deadlines-and-timeouts.test.js` 8/8, `actionable-diagnostics.test.js` 7/7) | Qualified on Linux VPS `srv1080529` | None. Wave 1 features are merged, tested, and operational on Linux appliances. |
| **Wave 2: Dual-Topology Reliability & Queue Scale** | ✅ CLOSED | **PASS** | `ci-server/api/sync-wal.js`, `ci-server/api/build-queue.js`, `CiSyncController.cs` | 8/8 passed (`queue-and-sync-reliability.test.js`) | Qualified on Linux VPS `srv1080529` (100% sync delivery across partition) | None. WAL buffer and concurrency limiter operate as designed. |
| **Wave 3: Hermetic Host Isolation & Ephemeral Nets** | 🔄 IN PROGRESS | **UNVERIFIED** | Socket mount elimination in `build-runner.js`, `ci-net-${buildId}`, `HostFirewallManager.js`, `scripts/host-firewall-manager.sh` | 13/14 passed (`hermetic-isolation.test.js`); 1 failed on Windows (`spawn bash ENOENT`) | Proposal only. Clean-VM qualification on Ubuntu 22.04/24.04/Debian 12 explicitly deferred per `WAVE_3_HOST_FIREWALL_QUALIFICATION_PLAN.md` | Host firewall enforcement remains proposal-only on customer appliances; CLI script requires bash and cannot run on Windows. |
| **Wave 4: Secure Supply Chain & Signed Provenance** | 🔄 IN PROGRESS | **UNVERIFIED** | `ci-server/api/supply-chain.js`, `DeployService.cs` (Cosign verification, ephemeral Compose override pinning) | Code present; `supply-chain.test.js` requires uninstalled `pg` module; Scenario 12 passed in Wave 5 suite | Implementation verified; clean-VM qualification and customer appliance release deployment pending | Pinned Compose override paths assume Unix `/tmp/vps-infra-pins`. Tag-drift immunity merged, but customer rollout pending. |
| **Wave 5: Production Deployment Gates & Automated Rollback** | 📋 PLANNED (Table) / QUALIFIED (Report) | **PASS (Linux)** / **UNVERIFIED (Windows)** | `DeploymentHealthGate.cs`, `DeployService.cs`, `DatabaseDeploymentLease.cs`, `ReconcileDeploymentSchema` migration | 7/7 passed (`DeploymentHealthGateTests`); 12/12 real Linux scenarios passed; `IisHostingTests` 4/5 passed (1 failed on CRLF) | Formally qualified on Linux (`WAVE_5_LINUX_QUALIFICATION_REPORT.md` on 2026-10-05, commit `cea5ce4`) | **Documentation Drift:** Roadmap Section 8 summary table still lists Wave 5 as "PLANNED" despite being merged to `main`. Blue/green traffic shifting remains unimplemented (in-place restart only). |
| **Wave 6: Enterprise Observability & Compliance Auditing** | ✅ DELIVERED | **PASS (Linux)** / **UNVERIFIED (Windows)** | PostgreSQL `ComplianceAuditEvents` table, triggers, `ComplianceAuditService.cs`, OpenMetrics `/metrics`, log retention | 13/14 passed (`ComplianceObservabilityTests`); 1 failed on Windows due to `# EOF\r\n` vs `# EOF\n` | Qualified and delivered on Linux VPS | Control-plane only (no customer app tracing). OpenMetrics exporter fails strict compliance on Windows due to CRLF line terminators. |

---

## 4. Windows Server Readiness Audit Findings

### A. Blockers (Critical Pre-Implementation Barriers)

1. **Fatal PowerShell AST Syntax Error in Deployed Agent (`DEF-28`):**
   - *File:* [`vps-infra/scripts/tmk-iis-agent.ps1:345-346`](file:///C:/var/www/vps-infra/scripts/tmk-iis-agent.ps1#L345-L346)
   - *Evidence:* PowerShell AST parser reports 2 fatal errors: `MissingCatchOrFinally` at line 345:6 and `UnexpectedToken '}'` at line 346:1.
   - *Root Cause:* Lines 257–279 inserted backup/log pruning logic while accidentally deleting the outer `try {` block. The script cannot even be parsed, loaded, or executed on any Windows host.
2. **Windows Service Control Manager Protocol Failure (`DEF-29` / Error 1053):**
   - *File:* [`vps-infra/docs/02-deploying-applications/04-iis-hosted-apps.md:28-33`](file:///C:/var/www/vps-infra/docs/02-deploying-applications/04-iis-hosted-apps.md#L28-L33)
   - *Evidence:* Instructs registering the agent via `New-Service -BinaryPathName "powershell.exe ... tmk-iis-agent.ps1"`.
   - *Root Cause:* `powershell.exe` does not call `StartServiceCtrlDispatcher()`. SCM terminates the process after 30 seconds with Win32 Error 1053. A PowerShell script cannot run as a native Windows service without a compiled wrapper (WinSW, NSSM) or a compiled C# .NET Worker Service (`Microsoft.Extensions.Hosting.WindowsServices`).
3. **HTTP.sys Loopback Binding Isolation & Host Header Rejection (`DEF-30`):**
   - *Files:* [`vps-infra-server/scripts/tmk-iis-agent.ps1:31-33`](file:///C:/var/www/vps-infra-server/scripts/tmk-iis-agent.ps1#L31-L33), [`IisClientService.cs:38`](file:///C:/var/www/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs#L38)
   - *Evidence:* The agent registers prefix `http://127.0.0.1:5055/`. The containerized control plane connects via `http://host.docker.internal:5055/`.
   - *Root Cause:* HTTP.sys evaluates the `Host` header. Incoming packets with `Host: host.docker.internal:5055` are rejected with `HTTP 400 Bad Request (Invalid Hostname)`. Resolving this requires wildcard prefix registration (`http://+:5055/`) and administrative URL ACL reservation (`netsh http add urlacl`), which are missing.
4. **Faked Health Probe Contract Swallows Broken Deployments (`DEF-31`):**
   - *Files:* [`tmk-iis-agent.ps1:305-316`](file:///C:/var/www/vps-infra/scripts/tmk-iis-agent.ps1#L305-L316), [`IisClientService.cs:350-355`](file:///C:/var/www/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs#L350-L355)
   - *Evidence:* In the health probe catch block, if an application crashes or returns HTTP 500, the agent logs a "site may still be warming up" notice and unconditionally sends `Success = true`.
   - *Impact:* The control plane marks failed, crashing releases as `SUCCESS`, blinding operators to live production outages.
5. **Direct IIS Port Collision with Live Production Sites (`DEF-35`):**
   - *Files:* [`vps-infra/setup.ps1:440-463`](file:///C:/var/www/vps-infra/setup.ps1#L440-L463), [`network/traefik/docker-compose.yml:32-33`](file:///C:/var/www/vps-infra/network/traefik/docker-compose.yml#L32-L33)
   - *Evidence:* Host inspection reveals IIS (W3SVC) is actively running with live production websites (`voterapp panel` on 80/443 for `okvtr.com` and `photo.voterapp.in`; `survey panel` on 80 for `download.voterapp.in`).
   - *Root Cause:* `setup.ps1` prompts to terminate `W3SVC` to assign ports 80/443 to Traefik. Executing setup would immediately take down live customer websites.
6. **Docker Engine Incompatibility (Windows Containers Mode vs Linux Containers):**
   - *Files:* [`vps-infra/setup.ps1:119-128`](file:///C:/var/www/vps-infra/setup.ps1#L119-L128), Host Docker Engine
   - *Evidence:* Host Docker Engine is running in **Windows Containers mode** (`OSType: windows`, Build 17763, process isolation). Neither WSL2 nor Hyper-V is installed.
   - *Impact:* `setup.ps1` explicitly halts at line 125 (`❌ Cannot deploy Linux containers on a Windows-mode Docker daemon`). The control plane containers (`ghcr.io/tmk-computers/tmk-devops-api:latest`, `traefik:latest`, `postgres:16`) are Linux images and cannot execute on this Windows Docker daemon.
7. **Complete Absence of Windows Automated CI Packaging Pipeline (`DEF-37`):**
   - *File:* [`ci-server/api/build-runner.js`](file:///C:/var/www/vps-infra-server/ci-server/api/build-runner.js)
   - *Evidence:* CI runner only contains logic for `docker build`. There is zero automated workflow to compile .NET applications (`dotnet publish`), create versioned zip packages, or transfer them to the Windows host.

### B. High Risks

1. **Non-Atomic Deployment & In-Place File Locking (`DEF-32`):**
   - `tmk-iis-agent.ps1` unzips artifacts directly into the active site directory (`C:\inetpub\wwwroot\...`) after dropping `app_offline.htm` and sleeping 2 seconds.
   - If `w3wp.exe`, Windows Defender, or background logging holds an open handle on a `.dll`, `Expand-Archive` throws an exception, corrupting the production directory.
2. **Zip-Slip & Arbitrary Directory Traversal Vulnerability (`DEF-32`):**
   - `/api/iis/deploy` extracts the zip artifact directly into `$deployReq.PhysicalPath` without canonical path validation or boundary checks. A compromised payload can specify `C:\Windows\System32` or parent path traversals.
3. **Global `w3wp.exe` Host Memory Aggregation Bug (`DEF-33`):**
   - In [`IisClientService.cs:395-404`](file:///C:/var/www/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs#L395-L404), memory harvesting queries `Process.GetProcessesByName("w3wp")` and sums the memory of **every** worker process on the host. Every monitored app reports the total aggregate memory of all hosted applications.
4. **Synchronous Single-Threaded Event Loop Blocker (`DEF-34`):**
   - In `tmk-iis-agent.ps1:114`, the listener uses `$listener.GetContext()`. Long-running deployments block the thread, causing simultaneous health probes, status queries, and metrics to time out.
5. **Static Secret Fallback Vulnerability (`DEF-36`):**
   - Both `tmk-iis-agent.ps1` and `IisClientService.cs` contain fallback references to default secrets if `$env:CI_SECRET` is unset.
6. **Cross-Platform CRLF Test Breakages:**
   - Both `IisHostingTests` (`TraefikDynamicConfigService_Generates_Valid_Yaml_For_Iis_Service`) and `ComplianceObservabilityTests` (`MetricsController_EnforcesBearerAuthentication_AndReturnsValidOpenMetrics`) fail on Windows due to hardcoded `\n` vs `\r\n` assertions.

### C. Unverified Items

1. **Disaster Recovery & IIS Configuration Backup:**
   - Zero code exists to export `applicationHost.config`, AppPool definitions, or Windows certificates (`Cert:\LocalMachine\My`) to offsite storage.
2. **Windows Defender Firewall Automation:**
   - Port 5055 and internal application ports are not automatically configured in Windows Firewall during setup.
3. **Database Native Support:**
   - Host is running native PostgreSQL 18 and SQL Server Express, but platform management scripts only target containerized PostgreSQL.

---

## 5. Prerequisite Decision: Phase 0.5 vs Windows Architecture

### Analysis
- **What Phase 0.5 Actually Is:**  
  Phase 0.5 is an internal database schema migration for the Linux-hosted `devops-manager` PostgreSQL database. It adds 13 Maintenance Mode properties across `Product` (8) and `ProjectService` (5), neutralizes competing raw DDL in `DataSeeder.cs:46-168`, and establishes EF Core versioned migrations as the sole schema authority.
- **Why Phase 0.5 Does NOT Unblock Windows Server:**
  - Phase 0.5 does not fix the fatal PowerShell syntax error in `tmk-iis-agent.ps1`.
  - Phase 0.5 does not solve SCM Error 1053 or provide a compiled Windows Service executable.
  - Phase 0.5 does not resolve HTTP.sys loopback binding isolation or URL ACLs.
  - Phase 0.5 does not resolve the Docker Windows containers vs Linux containers mismatch.
  - Phase 0.5 does not protect active IIS production websites on ports 80/443 from destruction.
- **Architectural Boundary:**  
  The six-wave roadmap is an appliance deployment model designed for Linux hosts. Native Windows Server support represents a completely separate deployment topology (Windows worker host running native IIS/.NET applications, coexisting with existing host services).

### Definitive Recommendation
**DO NOT START PHASE 0.5 TO ACHIEVE WINDOWS SERVER READINESS.**

A dedicated **Windows-Specific Architecture & Readiness Phase (Phase W-0)** must come first. Phase 0.5 should only be executed in its proper context as a database schema maintenance task within the Linux appliance roadmap, completely decoupled from Windows Server platform support.

---

## 6. Proposed Windows Implementation Phase Sequence

To achieve production-grade Windows Server support without disrupting existing workloads, the following ordered phases are recommended:

```
┌────────────────────────────────────────────────────────────────────────┐
│               PROPOSED WINDOWS SERVER IMPLEMENTATION ROADMAP           │
├───────────┬──────────────────────────────────┬─────────────────────────┤
│ Phase     │ Focus                            │ Primary Deliverable     │
├───────────┼──────────────────────────────────┼─────────────────────────┤
│ Phase W-0 │ Architecture & Coexistence Gate  │ Non-Interference ADR    │
│ Phase W-1 │ Compiled Agent & SCM Service     │ TMK.Agent.Windows       │
│ Phase W-2 │ Atomic Swapping & Health Gates   │ Zero-Lock Deployment    │
│ Phase W-3 │ Automated CI Packaging Pipeline  │ Dotnet Publish & Zip CI │
│ Phase W-4 │ End-to-End Live Qualification    │ Dual-OS Production Gate │
└───────────┴──────────────────────────────────┴─────────────────────────┘
```

### Phase W-0: Architecture & Coexistence Gate (Safety & Topology Definition)
- **Goal:** Formally define the deployment topology and enforce non-interference with existing IIS sites.
- **Actions:**
  1. Adopt the **Remote Node Agent Topology**: Windows Server operates exclusively as an application host node running the native agent; the control plane (DevOps API, Traefik, PostgreSQL) runs on a dedicated Linux VPS or separate environment.
  2. Enforce the **Non-Interference Contract**: Prohibit scripts from stopping `W3SVC` or binding Traefik to ports 80/443. Assign distinct internal ports (e.g. 8081–8099) for managed IIS sites.
- **Objective Acceptance Criteria:**
  - Architectural Decision Record (ADR) approved establishing Remote Node Agent topology.
  - Setup validation scripts verify zero modification to existing websites (`okvtr.com`, `photo.voterapp.in`).

### Phase W-1: Compiled Windows Agent & SCM Service Runtime (`TMK.Agent.Windows`)
- **Goal:** Replace fragile PowerShell scripts with a robust, compiled Windows Service.
- **Actions:**
  1. Build `TMK.Agent.Windows` as a compiled C# .NET Worker Service (`Microsoft.Extensions.Hosting.WindowsServices`).
  2. Implement native SCM dispatching, auto-restart on failure, and asynchronous HTTP request handling.
  3. Register HTTP.sys URL ACL prefix (`http://+:5055/`) and configure Windows Defender Firewall rules for port 5055.
  4. Enforce mandatory cryptographic bearer token authentication generated during agent setup.
- **Objective Acceptance Criteria:**
  - Service installs, starts, pauses, and stops cleanly via Windows SCM (`sc.exe`, `Start-Service`) without Error 1053.
  - Authenticated health endpoint `/api/health` responds with HTTP 200 to requests from remote/container IPs.
  - Unauthenticated or invalid token requests return HTTP 401 Unauthorized.

### Phase W-2: Atomic Directory Swapping & Truthful Deployment Health Gates
- **Goal:** Eliminate file locking during deployments and ensure truthful reporting of runtime failures.
- **Actions:**
  1. Implement **Atomic Directory Pointer Swapping**: Extract artifacts to versioned folders (`C:\inetpub\releases\<app>-<timestamp>`), updating IIS Physical Path via `Microsoft.Web.Administration`.
  2. Enforce strict Zip-Slip protection rejecting paths outside designated release directories.
  3. Implement **Truthful Health Gate**: Probe application endpoints; abort and trigger automated rollback on HTTP non-200 or timeout. Eliminate error swallowing.
  4. Reliable Rollback: Revert IIS physical path pointer to the previous release folder within 30 seconds.
- **Objective Acceptance Criteria:**
  - Deployment into a locked directory succeeds without file collision errors.
  - Failure injection test: Intentionally crashing candidate returning HTTP 500 triggers automated rollback within 30 seconds and records `DEPLOY_ERR_HEALTHCHECK_FAILED` in deployment logs.

### Phase W-3: Automated Windows CI Packaging & Transfer Pipeline
- **Goal:** Automate artifact generation and transfer from source repositories.
- **Actions:**
  1. Implement `dotnet publish -c Release -o ...` and zip packaging stage in `ci-server/api/build-runner.js`.
  2. Implement authenticated artifact upload and transfer to the Windows agent over TLS.
- **Objective Acceptance Criteria:**
  - Pushing a commit to a .NET repository automatically produces a signed zip artifact and transfers it to the target Windows host without manual intervention.

### Phase W-4: End-to-End Live Qualification & Observability
- **Goal:** Validate production readiness under real workloads.
- **Actions:**
  1. Update telemetry harvesting in `IisClientService.cs` to match specific `w3wp.exe` PIDs to their corresponding AppPools using WMI.
  2. Implement automated export and offsite backup of `applicationHost.config` and site bindings.
  3. Resolve CRLF line-ending test failures in `IisHostingTests` and `ComplianceObservabilityTests`.
- **Objective Acceptance Criteria:**
  - 100% test pass rate across the full .NET test suite on native Windows Server.
  - Per-AppPool memory telemetry accurately reflects individual process consumption.
  - Disaster recovery test: Clean host rebuild recovers IIS sites from offsite configuration backups.

---

## 7. Audit Evidence: Files Inspected and Safe Checks Run

### Key Documents & Files Inspected
1. `C:\var\www\vps-infra-server\docs\COMMERCIAL_CI_CD_WAVED_EXECUTION_ROADMAP.md`
2. `C:\var\www\vps-infra-server\docs\COMMERCIAL_CI_CD_TRANSFORMATION_PLAN.md`
3. `C:\var\www\vps-infra-server\WAVE_5_LINUX_QUALIFICATION_REPORT.md`
4. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\01_EXECUTIVE_SUMMARY.md`
5. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\03_WINDOWS_IMPLEMENTATION_MAP.md`
6. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\06_WINDOWS_PRODUCTION_READINESS.md`
7. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\07_IIS_AGENT_FORENSIC_AUDIT.md`
8. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\19_WINDOWS_PILOT_GATE.md`
9. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\20_CROSS_PLATFORM_REMEDIATION_ROADMAP.md`
10. `C:\var\www\vps-infra-server\docs\remediation\phase-0-review-r4\06_PHASE_0_5_AND_TRACEABILITY_REVIEW.md`
11. `C:\var\www\vps-infra\scripts\tmk-iis-agent.ps1`
12. `C:\var\www\vps-infra-server\scripts\tmk-iis-agent.ps1`
13. `C:\var\www\vps-infra\setup.ps1`
14. `C:\var\www\vps-infra\docker-compose.yml`
15. `C:\var\www\vps-infra\network\traefik\docker-compose.yml`
16. `C:\var\www\vps-infra-server\devops-manager\api\DevopsPanel.Tests\IisHostingTests.cs`
17. `C:\var\www\vps-infra-server\devops-manager\api\DevopsPanel.Tests\Wave5LinuxRealQualificationTests.cs`

### Safe Read-Only Checks Executed
1. Host & OS discovery via `Get-CimInstance Win32_OperatingSystem` and `$PSVersionTable`.
2. Hardware capacity discovery (16 vCPU, 64 GB RAM, 800 GB SSD) via `Win32_ComputerSystem` and `Win32_LogicalDisk`.
3. Git metadata, remote tracking, branch verification, and status validation via `git remote -v`, `git branch -vv`, `git rev-parse`, and `git status`.
4. PowerShell AST syntax parsing on `tmk-iis-agent.ps1` using `System.Management.Automation.Language.Parser`.
5. Docker engine discovery (`docker version`, `docker info`), confirming Windows Containers mode (`OSType: windows`).
6. Active service and feature enumeration (`W3SVC`, `Web-Server`, `Containers`, `postgresql-x64-18`, `MSSQL$SQLEXP2022`).
7. Listening port discovery confirming IIS owns ports 80/443 and PostgreSQL owns 5432.
8. Active website inspection revealing live production sites (`okvtr.com`, `photo.voterapp.in`, `download.voterapp.in`).
9. Automated read-only test suite executions:
   - `deadlines-and-timeouts.test.js`: 8/8 passed.
   - `actionable-diagnostics.test.js`: 7/7 passed.
   - `queue-and-sync-reliability.test.js`: 8/8 passed.
   - `hermetic-isolation.test.js`: 13/14 passed (1 failure due to missing `bash`).
   - `dotnet test --list-tests`: Build succeeded cleanly.
   - `DeploymentHealthGateTests`: 7/7 passed.
   - `IisHostingTests`: 4/5 passed (1 failure due to CRLF).
   - `ComplianceObservabilityTests`: 13/14 passed (1 failure due to CRLF).
