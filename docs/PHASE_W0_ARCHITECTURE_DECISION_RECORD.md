# ADR-001: Native Windows Server Hosting Topology & Coexistence Model

**Document Version:** 1.0.0  
**Phase:** Phase W-0 — Architecture & Coexistence Gate  
**Status:** PROPOSED & READY FOR STAKEHOLDER REVIEW  
**Auditor / Architect:** Independent Windows Platform Architect  
**Date:** 2026-10-06  
**Target Repositories Audited:**
- `vps-infra` @ SHA `cbe6db11614ff22875ff0af1c7b3b3f3921c8fb3` (Clean on `main`)
- `vps-infra-server` @ SHA `a7ccb0c6ee0587105a1be67b24b53603db7540b1` (Clean on `main`)

---

## 1. Safety & Non-Mutation Attestation

> **MANDATORY SAFETY STATEMENT:**  
> **No implementation changes, file modifications, deployments, migrations, container creations, service alterations, or firewall/IIS changes were performed during this task.** Both candidate repositories remain completely unmodified and clean on `main`.

---

## 2. Context & Problem Statement

### 2.1 Background
VPS-Infra was initially conceived as a Linux-first self-hosted appliance running containerized workloads (Traefik, PostgreSQL, DevOps Manager API, CI Server) via Docker Compose. As commercial interest grew, native support for hosting Windows Server IIS and .NET applications was introduced.

### 2.2 Forensic Audit Baseline (2026-10-06)
A comprehensive read-only audit of the codebase and the target developer environment revealed critical structural flaws:
1. **The Audited Host is Live:** The host is Microsoft Windows Server 2019 Standard (Build 17763) with active IIS websites (`voterapp panel`, `survey panel`) listening on ports 80 and 443 with production SSL bindings (`okvtr.com`, `photo.voterapp.in`, `download.voterapp.in`).
2. **Setup Script Port Collision (`DEF-35`):** `vps-infra/setup.ps1` expects Traefik to bind ports 80/443 and actively prompts the user to shut down IIS (`W3SVC`), which would cause immediate outages for live production websites.
3. **Container Runtime Mismatch:** The host's Docker daemon runs in **Windows Containers mode** (`OSType: windows`). Neither WSL2 nor Hyper-V is installed. The platform's Linux container images (`tmk-devops-api`, `traefik`, `postgres`) cannot run on this daemon, causing `setup.ps1` to halt immediately.
4. **Agent Syntax Failure (`DEF-28`):** The deployed script `vps-infra/scripts/tmk-iis-agent.ps1` fails PowerShell AST parsing with fatal syntax errors (`MissingCatchOrFinally` at line 345:6, `UnexpectedToken '}'` at line 346:1) due to an accidental deletion of the outer `try {` block.
5. **Service Control Protocol Incompatibility (`DEF-29`):** Documentation directs users to register the PowerShell agent via `New-Service -BinaryPathName "powershell.exe ..."`. Because `powershell.exe` does not implement `StartServiceCtrlDispatcher`, the Windows Service Control Manager (SCM) terminates the process after 30 seconds with Win32 Error 1053.
6. **HTTP.sys Loopback Network Partition (`DEF-30`):** The agent binds to `http://127.0.0.1:5055/`. When calls arrive from outside the host (or via Docker NAT), HTTP.sys rejects packets with `HTTP 400 Bad Request (Invalid Hostname)` due to unregistered host header prefixes.
7. **Faked Health Probe Contract (`DEF-31`):** In `tmk-iis-agent.ps1`, if an application crashes or returns HTTP 500 during deployment, the error is caught, logged as a notice, and the agent explicitly sends `Success = true`, falsely marking broken deployments as successful.
8. **In-Place File Locking (`DEF-32`):** Deployments extract archives directly over `C:\inetpub\wwwroot\...`. Any locked `.dll` or log file causes `Expand-Archive` to fail, corrupting application directories.
9. **No Automated CI Packaging (`DEF-37`):** The CI runner only executes `docker build`; no pipeline exists for compiling .NET applications or generating signed zip packages.

---

## 3. Evaluation of Architectural Topology Alternatives

Three candidate topologies were evaluated against infrastructure realities, operational stability, and customer safety:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOPOLOGY A: REMOTE APPLICATION NODE (RECOMMENDED)                                      │
│                                                                                        │
│   [ Linux VPS Appliance ]                   [ Windows Server Node ]                    │
│   ┌───────────────────────────┐             ┌──────────────────────────────────────┐   │
│   │ • Traefik Ingress         │             │ • Native IIS 10 (W3SVC)              │   │
│   │ • PostgreSQL 16           │   HTTPS     │   - Existing Sites (80/443 UNTOUCHED)│   │
│   │ • DevOps Manager API      ├────────────►│   - Managed Sites (SNI / High Ports) │   │
│   │ • CI Server & BuildKit    │ (Port 5055) │ • TMK.Agent.Windows (.NET Worker Svc)│   │
│   └───────────────────────────┘             │ • C:\inetpub\releases (Atomic Swaps) │   │
│                                             └──────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOPOLOGY B: FULL CONTROL PLANE ON WINDOWS SERVER                                       │
│                                                                                        │
│   [ Single Windows Server Host ]                                                       │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │ • Native Windows PostgreSQL Service                                            │   │
│   │ • Native Windows YARP / Traefik Binary (COMPETING FOR PORTS 80/443 WITH IIS!)  │   │
│   │ • Native Windows DevOps Manager API Service                                    │   │
│   │ • Native Windows CI Server (Requires full rewrite of bash/Docker proxy scripts)│   │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOPOLOGY C: SINGLE-HOST HYBRID VIA HYPER-V LINUX VM GUEST                              │
│                                                                                        │
│   [ Single Windows Server Host (Requires Nested Virt / Bare-Metal) ]                   │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │ • Windows Host: Native IIS (Ports 80/443)                                      │   │
│   │ • Hyper-V VM (Ubuntu 24.04): Runs full Linux Appliance (Traefik, Postgres, API)│   │
│   │ • Virtual Switch / NAT Network Barrier connecting VM to Host                   │   │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Comparative Analysis Matrix

| Evaluation Dimension | Topology A: Remote App Node (Recommended) | Topology B: Full Windows Control Plane | Topology C: Hyper-V VM Guest on Host |
| :--- | :--- | :--- | :--- |
| **Preservation of Linux Appliance (Waves 1–6)** | **100% Preserved.** Control plane runs unmodified on hardened Linux appliance. | **0% Preserved.** Requires rewriting control plane, scripts, and proxy for Windows. | **Preserved inside VM**, but adds complex VM lifecycle management. |
| **IIS Coexistence on Ports 80/443** | **Guaranteed.** Windows host runs IIS only. No reverse proxy competes for 80/443. | **Severe Conflict.** Reverse proxy (Traefik/YARP) competes directly with IIS for 80/443. | **Complex Port Sharing.** Host IIS owns 80/443; routing traffic to VM requires ARR or NAT. |
| **Hardware & Virtualization Prerequisites** | **Low.** Runs on standard cloud VPS. No nested virtualization or Hyper-V needed. | **Moderate.** Needs Windows services, but no virtualization required. | **High / Blocker.** Requires nested virtualization (disabled on most cloud VPSs). |
| **Footprint on Windows Host** | **Minimal (~50 MB RAM).** Lightweight .NET worker service agent only. | **High (4–8 GB RAM).** Full Postgres, CI Server, APIs, and Web UIs on host. | **Severe (8–16 GB RAM).** Dedicated RAM reservation for Linux VM + Windows OS. |
| **Engineering Time to Pilot** | **2–3 Weeks.** Implement compiled agent, atomic swap, and CI packaging. | **8–12 Weeks.** Porting entire backend stack and tools to native Windows. | **4–6 Weeks.** Hyper-V automation, virtual networking, and VM snapshot orchestration. |
| **Operational Blast Radius** | **Isolated.** Agent crash does not take down control plane or existing websites. | **Coupled.** Control plane crash disrupts all management and monitoring. | **Coupled.** VM resource starvation impacts host IIS performance. |

---

## 4. Decision: Adopt Topology A (Remote Application Node)

We formally select **Topology A (Remote Application Node)** as the authoritative architecture for native Windows Server support in VPS-Infra.

### 4.1 Decision Rationale
1. **Zero Disruption to Existing Linux Investment:** The Linux appliance roadmap (Waves 1–6) delivers a robust, tested control plane (PostgreSQL, Traefik, BuildKit, Cosign, OpenMetrics). Running the control plane on Linux preserves this investment completely.
2. **Absolute Non-Interference on Windows:** By restricting the Windows host to a managed application node, we eliminate the need to run Traefik or Docker on Windows. Ports 80 and 443 remain under 100% control of IIS (W3SVC). Existing production websites are protected from interference.
3. **Hypervisor Independence:** Eliminating the requirement for Docker Desktop / WSL2 on Windows allows VPS-Infra to support standard cloud VPS providers (Hetzner, Linode, DigitalOcean, OVH) where nested virtualization is disabled.
4. **Lightweight Agent Footprint:** A compiled .NET Worker Service consumes under 50 MB of RAM at idle, leaving the full compute capacity of the Windows host available for customer IIS workloads.

---

## 5. Architectural Specifications & Technical Governance

### 5.1 Supported Windows Server Versions & Node Prerequisites
- **Evaluation: Windows Server 2019 vs 2022:**
  - *Windows Server 2019 (Build 17763):* In Extended Support (until Jan 2029). HTTP.sys lacks native TLS 1.3 support (limited to TLS 1.2). However, it represents significant legacy production deployments (including the audited server).
  - *Windows Server 2022 (Build 20348+):* Active mainstream support (until Oct 2026 / Oct 2031). Features native TLS 1.3 in HTTP.sys, AES-256 GCM encryption, and modern container/security baselines.
- **Architectural Policy:**
  - **Tier 1 (Target / Recommended):** **Windows Server 2022 Datacenter / Standard**. Full support for TLS 1.3, modern HTTP.sys, and .NET 8/10.
  - **Tier 2 (Supported with Documented Constraints):** **Windows Server 2019 Standard / Datacenter**. Supported with explicit limitation: TLS 1.2 maximum; requires pre-installation of .NET 8/10 runtime.
  - **Explicitly Excluded / Forbidden:** Windows 10/11 Desktop (EULA forbids multi-user server hosting; client sleep/hibernation kills processes) and Windows Server 2016 and older (EOL).
- **Node Prerequisites:**
  - Role: `Web-Server` (IIS 10) with ASP.NET Core Hosting Bundle installed.
  - PowerShell 5.1+ or PowerShell 7.x.
  - Minimum node resources: 2 vCPU, 4 GB RAM, 20 GB free disk.

### 5.2 Control-Plane Location & Communication Direction
- **Location:** Dedicated Linux VPS appliance running `devops-manager`, `ci-server`, Traefik, and PostgreSQL.
- **Communication Direction:**
  - **Phase W-1 / W-2 (Baseline):** Control Plane pushes deployment commands and status requests inbound to the Windows Agent over **HTTPS on port 5055**.
  - **Firewall Restriction:** Port 5055 is strictly filtered by Windows Defender Firewall, permitting incoming connections **exclusively from the Control Plane VPS IP**.
  - **Phase W-3+ (Outbound Option):** Agent initiates outbound authenticated TLS WebSocket / polling to the Control Plane, eliminating all inbound firewall openings for NATed worker nodes.

### 5.3 IIS Coexistence & Port Ownership Invariant
- **Strict Invariant: ZERO INTERFERENCE WITH W3SVC OR EXISTING SITES.**
- Under no circumstances may any script, agent, or service:
  1. Stop, restart, or disable `W3SVC` globally.
  2. Modify, unbind, or remove existing IIS websites (`Default Web Site`, `voterapp panel`, `survey panel`).
  3. Attempt to bind reverse proxies or services to ports 80 or 443.
- **Managed Application Routing:**
  - *Option 1 (Host Header SNI on 80/443):* New websites managed by VPS-Infra are registered in IIS with unique Host Name bindings (e.g. `http *:80:crm.client.com`, `https *:443:crm.client.com` with SNI enabled). HTTP.sys natively multiplexes multiple websites on 80/443 by Host header without port conflicts.
  - *Option 2 (Dedicated Internal High Ports):* Applications bind to dedicated internal ports (e.g. `8081`–`8099`), routed via Cloudflare Tunnel or an external edge proxy.

### 5.4 Agent Service Model, Identity, & Lifecycle (`TMK.Agent.Windows`)
- **Runtime:** Compiled C# .NET Worker Service using `Microsoft.Extensions.Hosting.WindowsServices` and ASP.NET Core Kestrel with HTTP.sys backend.
- **SCM Protocol Compliance:** Links natively against Win32 service APIs, responding immediately to SCM start/stop commands in < 2 seconds, resolving Error 1053 permanently.
- **Identity & Privilege:** Runs under virtual account `NT SERVICE\TMKIisAgent` with granular NTFS ACLs on `C:\Program Files\TMK\Agent\` and `C:\inetpub\releases\`.
- **Automatic Recovery:** Windows Service configured with automatic restart on failure: 1st failure (restart after 1m), 2nd failure (restart after 2m), subsequent (restart after 5m).

### 5.5 Transport Security, Authentication, & Networking
- **Transport Security:** Strict **HTTPS** (TLS 1.2 on Server 2019, TLS 1.3 on Server 2022). Plaintext HTTP listeners on wildcard prefixes are strictly prohibited.
- **Certificate Binding:** Agent binds a certificate from `Cert:\LocalMachine\My` to port 5055 via `netsh http add sslcert`.
- **Authentication:** Mandatory 256-bit cryptographic Bearer token generated at setup. Verification uses constant-time comparisons (`CryptographicOperations.FixedTimeEquals`). Secrets stored in DPAPI-protected configuration.
- **URL ACL Reservation:** Explicit reservation: `netsh http add urlacl url=https://+:5055/ user="NT SERVICE\TMKIisAgent"`.
- **Narrow Firewall Rule:** Inbound rule `TMK-IIS-Agent-Inbound` created allowing TCP 5055 strictly from the Control Plane IP address.

### 5.6 Artifact Packaging, Cryptographic Provenance, & Transfer
- **Packaging:** Linux CI runner compiles .NET apps via `dotnet publish -c Release -r win-x64 --no-self-contained` and packages output into `<service>-<timestamp>-<sha>.zip`.
- **Cryptographic Signing:** Digest (SHA-256) is computed and signed via Cosign keypair.
- **Pre-Extraction Verification:** Windows Agent downloads archive, computes SHA-256 digest, and verifies cryptographic signature against `cosign.pub`. Corrupted or untrusted archives fail closed before extraction.
- **Retention:** Agent retains the last 3 release archives in `C:\inetpub\_packages\<service>\` for instant local rollback; older packages pruned automatically.

### 5.7 Atomic Directory Swapping & Truthful Deployment Health Gates
- **Zero-Lock Blue/Green Swapping:**
  - Artifact is extracted into a fresh, isolated directory:  
    `C:\inetpub\releases\<service>\<timestamp>-<sha>\`
  - Extraction occurs while the application is not running from that directory, eliminating file lock collisions with `w3wp.exe` or antivirus.
- **Zip-Slip & Path Traversal Prevention:**
  - `destinationPath` is validated: `Path.GetFullPath(dest).StartsWith(Path.GetFullPath(releasesRoot))`. Paths targeting system folders or parent directories throw `DEPLOY_ERR_PATH_TRAVERSAL`.
- **Atomic Promotion:**
  - Update IIS Application `physicalPath` via `Microsoft.Web.Administration`:
    ```csharp
    site.Applications["/"].VirtualDirectories["/"].PhysicalPath = newReleasePath;
    serverManager.CommitChanges();
    ```
- **Truthful Deployment Health Checks:**
  - Probe configured `HealthCheckPath` on the application endpoint over a 30-second observation window.
  - Require at least 3 consecutive HTTP 200 responses.
  - **Strict Contract:** If the endpoint returns HTTP 4xx/5xx, times out, or worker process crashes, mark deployment **FAILED** (`DEPLOY_ERR_HEALTHCHECK_FAILED`). Never swallow errors.
- **Sub-Minute Rollback:**
  - On health check failure, automatically revert `physicalPath` to the previous verified release folder within 30 seconds.

### 5.8 Telemetry, Logging, & Disaster Recovery
- **Telemetry Isolation:** Query `w3wp.exe` processes by matching command line arguments `-ap "<AppPoolName>"` or query `WorkerProcess` collection on the specific `ApplicationPool` via `Microsoft.Web.Administration`. Eliminate global host memory summing.
- **Event Logging:** Emit structured logs to Windows Event Log (`Application` source `TMKIisAgent`) and local rolling files. Forward RFC5424 compliance audit events to DevOps Manager.
- **Disaster Recovery:** Automated daily backup of `applicationHost.config`, site bindings, and certificates; archive offsite to S3/R2.

### 5.9 Roadmap Separation: Linux Waves 1–6 vs Windows Roadmap
- The six-wave Linux roadmap governs the Linux VPS appliance.
- Native Windows Server support is tracked independently under the **Windows Roadmap (Phases W-0 through W-4)**.
- Interfaces between the two systems are strictly defined via standardized REST contracts, DTOs, and event logs.

---

## 6. Phase W-0 Exit Criteria & Architecture Risks

### 6.1 Objective W-0 Exit Checklist
- [x] Baseline audit verified and candidate repository SHAs recorded.
- [x] Live host state documented (Windows Server 2019, IIS on 80/443, PostgreSQL 18 on 5432).
- [x] Architecture Decision Record (ADR) completed evaluating Topologies A, B, and C.
- [x] Topology A (Remote Application Node) selected and fully specified.
- [x] Strict non-interference contract established prohibiting stopping `W3SVC` or taking ports 80/443.
- [x] Operating system support matrix defined (Server 2022 Tier 1, Server 2019 Tier 2).
- [x] Security architecture defined (HTTPS, DPAPI, URL ACL, IP-restricted firewall).
- [x] Deployment engine defined (Atomic folder swap, Zip-Slip guard, truthful health gate).
- [x] **MANDATORY SAFETY GATE:** **All testing and development in Phase W-1 through W-4 MUST take place on a dedicated, disposable Windows VM with zero customer workloads before any software touches the audited host.**

### 6.2 Key Architecture Risks & Open Decisions
1. **Risk: Live Workload Disruption on Audited Host:**  
   *Mitigation:* Strict prohibition against deploying experimental software to the audited server. Phase W-1 through W-4 validation must be performed on a disposable VM.
2. **Decision: TLS Certificate Strategy for Agent Port 5055:**  
   *Options:* Self-signed certificate pinned in DevOps Manager vs internal CA vs Let's Encrypt win-acme.  
   *Recommendation for Pilot:* High-entropy self-signed certificate generated at setup and pinned by fingerprint in DevOps Manager.
3. **Risk: Windows Server 2019 TLS 1.3 Limitation:**  
   *Mitigation:* Agent negotiates TLS 1.2 on Server 2019 and TLS 1.3 on Server 2022.

---

## 7. Recommended Implementation Sequence After W-0

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    POST W-0 WINDOWS IMPLEMENTATION PHASES                    │
├─────────────┬────────────────────────────────────┬───────────────────────────┤
│ Phase       │ Focus                              │ Primary Acceptance Gate   │
├─────────────┼────────────────────────────────────┼───────────────────────────┤
│ **Phase W-0**│ Architecture & Coexistence Gate   │ ADR Approved & Signed-off │
│ **Phase W-1**│ Compiled Agent & SCM Service      │ Service Starts, Health 200│
│ **Phase W-2**│ Atomic Swapping & Health Gates    │ Zero File Locks, Auto-Roll│
│ **Phase W-3**│ Automated CI Packaging & Transfer │ Automated Git -> Zip -> VM│
│ **Phase W-4**│ Live Qualification & Observability│ 100% Tests Pass, DR Valid │
└─────────────┴────────────────────────────────────┴───────────────────────────┘
```

### Phase W-1: Compiled Windows Agent & SCM Service Runtime (`TMK.Agent.Windows`)
- **Scope:** Build compiled C# .NET Worker Service (`TMK.Agent.Windows`), URL ACL reservation, firewall rule, DPAPI secret management.
- **Acceptance Gate G-W1:**
  1. Service installs and starts via Windows SCM (`sc.exe`, `Start-Service`) on disposable VM; responds to SCM dispatcher in < 2 seconds (0 occurrences of Error 1053).
  2. Survives host reboot; recovers from simulated crash within 60 seconds.
  3. `GET https://<node>:5055/api/health` with valid Bearer token returns HTTP 200; requests without token return HTTP 401; requests from unlisted IPs are dropped by firewall.
  4. Zero syntax errors; zero PowerShell script dependencies for core execution.

### Phase W-2: Atomic Directory Swapping & Truthful Deployment Health Gates
- **Scope:** Atomic folder extraction (`C:\inetpub\releases\<service>\<timestamp>`), `Microsoft.Web.Administration` pointer swap, Zip-Slip prevention, truthful health verification, sub-minute rollback.
- **Acceptance Gate G-W2:**
  1. Deployment succeeds while application DLLs are actively loaded and open in `w3wp.exe` (zero file lock collisions).
  2. Path traversal attack payloads (e.g. `..\..\Windows\System32`) are rejected with `DEPLOY_ERR_PATH_TRAVERSAL`.
  3. Injected failure (HTTP 500 return code) fails deployment, captures error logs, and automatically rolls back physical path to previous release within 30 seconds, returning `DEPLOY_ERR_HEALTHCHECK_FAILED`.
  4. Deployment logs truthfully report failure; zero error swallowing.

### Phase W-3: Automated Windows CI Packaging & Transfer Pipeline
- **Scope:** CI runner packaging stage (`dotnet publish`), SHA-256 digest signing, authenticated transfer to agent.
- **Acceptance Gate G-W3:**
  1. Committing to a sample .NET web API repository triggers CI runner to compile, package, and sign a `.zip` artifact.
  2. Agent validates artifact SHA-256 digest and cryptographic signature before extraction; tampered artifacts are rejected with `DEPLOY_ERR_SIGNATURE_INVALID`.
  3. Zero manual zip copying or FTP transfers required.

### Phase W-4: End-to-End Live Qualification & Observability
- **Scope:** Cross-platform test reconciliation (CRLF fixes in `IisHostingTests` and `ComplianceObservabilityTests`), per-AppPool memory telemetry, automated IIS config backup, and qualification report.
- **Acceptance Gate G-W4:**
  1. 100% passing tests in `DevopsPanel.Tests` on native Windows host (0 failures, 0 CRLF errors).
  2. Per-AppPool telemetry accurately isolates target `w3wp.exe` memory from other running AppPools.
  3. Disaster recovery dry run: Restoring from an automated IIS backup successfully recovers site bindings and configuration on a clean VM.

---

## 8. Phase 0.5 Status & Recommendation

- **Disposition:** **Phase 0.5 should proceed independently on the Linux appliance roadmap when scheduled; it is NOT a prerequisite for Windows support.**
- **Rationale:** Phase 0.5 is an EF Core schema migration in PostgreSQL for Maintenance Mode entities in `devops-manager`. It has zero technical intersection with native Windows Service execution, HTTP.sys, IIS AppPools, or atomic directory swapping.
- **Boundary:** Do NOT block Windows architecture on Phase 0.5, and do NOT attempt to perform Phase 0.5 during the Windows track. Keep both tracks distinct and bounded.

---

## 9. Exact Files Inspected & Current SHAs Observed

### Repository SHAs
- `C:\var\www\vps-infra`: `cbe6db11614ff22875ff0af1c7b3b3f3921c8fb3` (Clean on `main`)
- `C:\var\www\vps-infra-server`: `a7ccb0c6ee0587105a1be67b24b53603db7540b1` (Clean on `main`)

### Primary Reference Documents & Code Inspected
1. `C:\var\www\vps-infra-server\docs\COMMERCIAL_CI_CD_WAVED_EXECUTION_ROADMAP.md`
2. `C:\var\www\vps-infra-server\docs\COMMERCIAL_CI_CD_TRANSFORMATION_PLAN.md`
3. `C:\var\www\vps-infra-server\WAVE_5_LINUX_QUALIFICATION_REPORT.md`
4. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\01_EXECUTIVE_SUMMARY.md`
5. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\03_WINDOWS_IMPLEMENTATION_MAP.md`
6. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\04_SUPPORTED_OS_MATRIX.md`
7. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\06_WINDOWS_PRODUCTION_READINESS.md`
8. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\07_IIS_AGENT_FORENSIC_AUDIT.md`
9. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\19_WINDOWS_PILOT_GATE.md`
10. `C:\var\www\vps-infra-server\docs\audit\2026-09-29-linux-windows-readiness\20_CROSS_PLATFORM_REMEDIATION_ROADMAP.md`
11. `C:\var\www\vps-infra\scripts\tmk-iis-agent.ps1` & `C:\var\www\vps-infra-server\scripts\tmk-iis-agent.ps1`
12. `C:\var\www\vps-infra\setup.ps1`
13. `C:\var\www\vps-infra-server\devops-manager\api\Infrastructure\Services\IisClientService.cs`
14. `C:\var\www\vps-infra-server\devops-manager\api\DevopsPanel.Tests\IisHostingTests.cs`
15. `C:\var\www\vps-infra-server\devops-manager\api\DevopsPanel.Tests\Wave5LinuxRealQualificationTests.cs`
