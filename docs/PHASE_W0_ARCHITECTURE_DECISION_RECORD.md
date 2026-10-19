# ADR-001: Native Windows Server Hosting Topology, Listener Architecture & Coexistence Model

**Document Version:** 1.1.0 (Revised Post-Review)  
**Phase:** Phase W-0 — Architecture & Coexistence Gate  
**Status:** PROPOSED & RE-GATED FOR STAKEHOLDER SIGN-OFF  
**Role:** Windows Platform Architecture Owner & Independent Reviewer  
**Date Checked / Re-Gated:** 2026-10-06  
**Audited Repositories & Base Commits:**
- `vps-infra` @ SHA `b691e7b` (Base `cbe6db11614ff22875ff0af1c7b3b3f3921c8fb3`)
- `vps-infra-server` @ SHA `b65caae` (Base `a7ccb0c6ee0587105a1be67b24b53603db7540b1`)

---

## 1. Safety & Non-Mutation Attestation

> **EXPLICIT NON-MUTATION STATEMENT:**  
> **This revision is an architecture and documentation task only.** No implementation changes, Windows worker deployments, application code edits, IIS alterations, software installations, container creations, service controls, database migrations, or live firewall mutations were executed. The host server remains completely unmutated.

---

## 2. Context & Forensic Baseline

### 2.1 Background
VPS-Infra was initially built as a Linux-first appliance running containerized workloads (Traefik, PostgreSQL, DevOps Manager API, CI Server) via Docker Compose. Support for native Windows Server IIS and .NET workloads was introduced as a hybrid prototype.

### 2.2 Forensic Audit Baseline (Verified on Host 2026-10-06)
1. **The Audited Host is Live:** Microsoft Windows Server 2019 Standard (10.0.17763 Build 17763) with active IIS websites (`voterapp panel`, `survey panel`) listening on ports 80 and 443 with production SSL bindings (`okvtr.com`, `photo.voterapp.in`, `download.voterapp.in`). Native PostgreSQL 18 is active on port 5432.
2. **Setup Script Port Collision (`DEF-35`):** `vps-infra/setup.ps1` prompts to terminate `W3SVC` to assign ports 80/443 to Traefik, which would take down live customer websites.
3. **Container Runtime Mismatch:** Host Docker Engine is running in **Windows Containers mode** (`OSType: windows`). Neither WSL2 nor Hyper-V is installed. Linux container images cannot run on this daemon.
4. **Agent Syntax Failure (`DEF-28`):** `vps-infra/scripts/tmk-iis-agent.ps1` fails PowerShell AST parsing with fatal syntax errors (`MissingCatchOrFinally` at line 345:6, `UnexpectedToken '}'` at line 346:1).
5. **Service Control Protocol Incompatibility (`DEF-29`):** Registering `tmk-iis-agent.ps1` via `New-Service` with `powershell.exe` fails with SCM Error 1053 because `powershell.exe` does not implement `StartServiceCtrlDispatcher`.
6. **HTTP.sys Loopback Binding Isolation (`DEF-30`):** Agent binds to `http://127.0.0.1:5055/`; HTTP.sys rejects incoming traffic from other hosts or containers with `HTTP 400 Bad Request (Invalid Hostname)`.
7. **Faked Health Probe Contract (`DEF-31`):** In `tmk-iis-agent.ps1`, if an application returns HTTP 500 or crashes during deployment, the catch block logs a warning and unconditionally returns `Success = true`.
8. **In-Place File Locking (`DEF-32`):** Deployments extract archives directly over `C:\inetpub\wwwroot\...`, failing when DLLs are locked by `w3wp.exe` or antivirus.
9. **No Automated CI Packaging (`DEF-37`):** The CI runner only executes `docker build`; no automated pipeline exists for building .NET zip packages.

---

## 3. Evaluation of Architectural Topology Alternatives

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOPOLOGY A: REMOTE APPLICATION NODE (RECOMMENDED)                                      │
│                                                                                        │
│   [ Hardened Linux VPS Appliance ]          [ Windows Server Application Node ]        │
│   ┌───────────────────────────┐             ┌──────────────────────────────────────┐   │
│   │ • Traefik Ingress         │             │ • Native IIS 10 (W3SVC)              │   │
│   │ • PostgreSQL 16           │   HTTPS     │   - Existing Sites (80/443 UNTOUCHED)│   │
│   │ • DevOps Manager API      ├────────────►│   - Managed Sites (SNI on 80/443)    │   │
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
│   │ • Native Windows YARP / Traefik Binary (COLLIDES WITH IIS ON PORTS 80/443)     │   │
│   │ • Native Windows DevOps Manager API & CI Server (.NET Worker Services)         │   │
│   │   (Requires complete rewrite of Linux bash scripts, Docker proxy, and tools)   │   │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOPOLOGY C: SINGLE-HOST HYBRID VIA HYPER-V LINUX VM GUEST                              │
│                                                                                        │
│   [ Single Windows Server Host (Requires Nested Virt / Bare-Metal Hardware) ]          │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │ • Windows Host: Native IIS (Ports 80/443)                                      │   │
│   │ • Hyper-V Linux VM (Ubuntu 24.04): Runs full Linux Appliance (Traefik, Postgres│   │
│   │ • Internal Virtual Switch / NAT Gateway connecting Linux VM to Host IIS        │   │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

| Evaluation Dimension | Topology A: Remote App Node (Recommended) | Topology B: Full Windows Control Plane | Topology C: Single-Host Hyper-V VM |
| :--- | :--- | :--- | :--- |
| **Preservation of Linux Waves 1–6** | **100% Preserved.** Control plane runs unmodified on hardened Linux appliance. | **0% Preserved.** Requires rewriting control plane, scripts, and proxy for Windows. | **Preserved inside VM**, but adds heavy VM lifecycle overhead. |
| **IIS Coexistence on Ports 80/443** | **High Fidelity.** Windows host runs IIS only. No reverse proxy competes for 80/443. | **Severe Conflict.** Reverse proxy competes directly with IIS for 80/443. | **Complex Port Sharing.** Host IIS owns 80/443; routing traffic to VM requires ARR or NAT. |
| **Virtualization Prerequisites** | **Zero.** Runs on standard cloud VPS. No nested virtualization or Hyper-V needed. | **Zero.** Needs Windows services, but no virtualization required. | **Hard Blocker.** Requires nested virtualization (disabled on most cloud VPSs). |
| **Windows Host RAM Footprint** | **Minimal (~50 MB).** Lightweight .NET worker service agent only. | **High (4–8 GB).** Full Postgres, CI Server, APIs, and Web UIs on host. | **Severe (8–16 GB).** Dedicated RAM reservation for Linux VM + Windows OS. |
| **Time to Pilot Readiness** | **2–3 Weeks.** | **8–12 Weeks.** | **4–6 Weeks.** |
| **Blast Radius** | **Isolated.** Agent crash does not affect control plane or existing sites. | **Coupled.** Control plane crash disrupts all management and monitoring. | **Coupled.** VM resource starvation impacts host IIS performance. |

---

## 4. Decision: Adopt Topology A (Remote Application Node)

We formally select **Topology A (Remote Application Node)**:
1. The control plane (`devops-manager`, `ci-server`, Traefik, PostgreSQL) remains exclusively on the Linux VPS appliance per Waves 1–6.
2. The Windows Server host operates as a dedicated remote application node running native IIS and a compiled C# .NET Worker Service (`TMK.Agent.Windows`).
3. Existing IIS sites and ports 80/443 remain untouched by platform edge proxies.

---

## 5. Technical Governance & Architectural Specifications

### 5.1 Authoritative Microsoft Lifecycle Matrix & Support Tiers

Source of lifecycle data: Official Microsoft Lifecycle Policy database (`https://learn.microsoft.com/en-us/lifecycle/products/`), verified on **2026-10-06**:

| Operating System | Release Date | Mainstream Support End | Extended Support End | Current Lifecycle Status (as of 2026-10-06) | Proposed Support Tier | Empirical Qualification Status |
| :--- | :---: | :---: | :---: | :--- | :---: | :---: |
| **Windows Server 2022** (Build 20348+) | 2021-08-18 | 2026-10-13 | 2031-10-14 | **Active Mainstream Support** (through late 2026) | **Tier 1 (Recommended Baseline)** | **NOT TESTED / NOT ACCEPTED** (Target for Phase W-4 qualification) |
| **Windows Server 2025** (Build 26100+) | 2024-11-01 | 2029-10-09 | 2034-10-10 | **Active Mainstream Support** (Current modern release) | **Tier 2 (Emerging Modern Target)** | **NOT TESTED / NOT ACCEPTED** (Target for post-pilot qualification) |
| **Windows Server 2019** (Build 17763+) | 2018-11-13 | 2024-01-09 | 2029-01-09 | **Extended Support Only** (Security fixes only; TLS 1.3 absent) | **Tier 3 (Legacy with Constraints)** | **OBSERVED DEV HOST ONLY** (No automated qualification passing) |
| **Windows 10 / 11** (Desktop) | Various | N/A | N/A | Client OS | **EXCLUDED / FORBIDDEN** | **UNSUPPORTED** (EULA & power-save issues) |
| **Windows Server 2016** & older | 2016-10-15 | 2022-01-11 | 2027-01-12 | Deprecated / Approaching EOL | **EXCLUDED / FORBIDDEN** | **UNSUPPORTED** |

#### Priority Reassessment: Server 2022 vs Server 2025
- **Windows Server 2022 remains the Tier 1 Recommended Baseline for initial implementation (Phases W-1 through W-4):**
  - Universally provisioned across cloud VPS providers (Hetzner, Linode, AWS, Azure, DigitalOcean).
  - Proven IIS 10 stability and native TLS 1.3 support in HTTP.sys/Schannel.
  - Extended support is locked through October 2031 (5+ years remaining).
- **Windows Server 2025 is designated as Tier 2 (Emerging Modern Target):**
  - Planned for compatibility validation once cloud VPS provider image adoption matures.
  - Offers support through October 2034.
- **Empirical Epistemic Boundary:**
  - **Zero Windows versions are currently qualified or accepted in CI.** All existing passing qualification runs (e.g. `Wave5LinuxRealQualificationTests.cs`) were executed on Ubuntu 24.04 Linux. Windows Server readiness is a proposed architecture awaiting Phase W-1 through W-4 qualification on a dedicated Windows VM.

---

### 5.2 Standalone Kestrel Worker Listener Architecture

To resolve the contradiction in earlier drafts ("Kestrel HTTP.sys backend"), we explicitly document that **Kestrel** (`Microsoft.AspNetCore.Server.Kestrel`) and **HTTP.sys** (`Microsoft.AspNetCore.Server.HttpSys`) are distinct, mutually exclusive ASP.NET Core server implementations:

```
┌────────────────────────────────────────────────────────────────────────┐
│ STANDALONE KESTREL WORKER LISTENER (CHOSEN ARCHITECTURE)                │
│                                                                        │
│   Control Plane (Linux VPS)                                            │
│        │                                                               │
│        │ HTTPS Requests (Port 5055)                                    │
│        ▼                                                               │
│   [ Windows Defender Firewall: Inbound TCP 5055 from Control Plane IP] │
│        │                                                               │
│        ▼                                                               │
│   [ WinSock TCP Socket: 0.0.0.0:5055 ]                                 │
│        │                                                               │
│        ▼                                                               │
│   [ Standalone Kestrel Web Server (In-Process in TMK.Agent.Windows) ]   │
│        ├── In-Process TLS Termination (X509Certificate2 via Code)      │
│        ├── In-Process mTLS Client Certificate Validation (Optional)     │
│        └── Constant-Time Cryptographic Bearer Token Authentication     │
│                                                                        │
│   * Note: Windows Kernel HTTP.sys is NOT involved in Port 5055.        │
│   * Zero 'netsh http add urlacl' reservations required.                │
│   * Zero 'netsh http add sslcert' bindings required.                   │
└────────────────────────────────────────────────────────────────────────┘
```

#### Architectural Decisions for Agent Listener:
1. **Server Implementation: Standalone Kestrel (`Microsoft.AspNetCore.Server.Kestrel`):**
   - The worker executes Kestrel in-process inside the `TMK.Agent.Windows` service.
   - Binds directly to TCP socket `0.0.0.0:5055` (configurable).
2. **Elimination of HTTP.sys URL ACLs:**
   - Because Kestrel runs on user-mode WinSock sockets rather than the kernel `http.sys` driver, **`netsh http add urlacl` is completely eliminated**. This avoids machine-level URL reservation conflicts, namespace leaks, and administrative ACL failures.
3. **In-Process TLS Management:**
   - Kestrel manages TLS directly in-process via `X509Certificate2` loaded from the local machine certificate store (`Cert:\LocalMachine\My`) or a secure certificate file.
   - **`netsh http add sslcert` is completely eliminated**.
4. **Authentication & Transport Security:**
   - Protocol: TLS 1.2 minimum on Server 2019; TLS 1.3 on Server 2022/2025.
   - Authentication: Cryptographic Bearer token (minimum 256-bit entropy, 64 hex characters) generated during agent setup and verified via `CryptographicOperations.FixedTimeEquals`.
   - Token storage: Encrypted using the Windows Data Protection API (DPAPI) via `ProtectedData` with `DataProtectionScope.LocalMachine`.
   - Optional mTLS: When configured, Kestrel validates the control-plane client certificate against a pinned CA thumbprint in middleware.
5. **Windows Firewall Rule:**
   - Narrow inbound rule `TMK-IIS-Agent-Inbound`: TCP port 5055, scoped strictly to the Control Plane VPS IP.

---

### 5.3 IIS Coexistence & Initial Traffic Routing Model

#### 5.3.1 Selected Routing Model: Model 1 — Managed IIS Host-Header/SNI Bindings on Ports 80/443
We formally select **Model 1 (IIS Host-Header & SNI Bindings on Ports 80/443 directly within IIS)** as the initial routing architecture.

#### 5.3.2 Technical Effects on the Host:
- **Effect on Existing Sites:** Zero modification to existing website directories, AppPools, or bindings. Existing sites (`Default Web Site`, `voterapp panel`, `survey panel`) remain untouched.
- **Effect on Ports 80 and 443:** Ports 80 and 443 remain exclusively owned and bound by Windows HTTP.sys under IIS (`W3SVC`). No reverse proxy or third-party binary attempts to bind 80/443.
- **Effect on Certificates & SNI:**
  - Every managed HTTPS binding on port 443 **MUST have Server Name Indication enabled (`sslFlags=1` or `sslFlags=3`)**.
  - Non-SNI bindings (`sslFlags=0`) are strictly forbidden for managed sites to prevent overriding default or existing site certificates.
- **Effect on Bindings:**
  - Bindings must include an explicit, non-empty `Host` header (e.g. `*:80:app.customer.com` and `*:443:app.customer.com`).
  - Blank host header bindings (`*:80:` or `*:443:`) are strictly prohibited.
- **Effect on DNS:** Customer creates an A or CNAME DNS record pointing `app.customer.com` to the Windows Server public IP.
- **Effect on Customer Traffic:** Windows HTTP.sys inspects incoming packets, matches the Host header and TLS SNI extension, and dispatches requests to the target site's AppPool without touching other sites.

#### 5.3.3 Verifiable Preservation Checks & Rollback Criteria
Coexistence cannot be declared "guaranteed" without qualification evidence. It is governed as a **Verifiable Design Invariant**:

```
                       IIS MUTATION PREFLIGHT & PRESERVATION GATE
                       
  [ Incoming Deploy Request: Add Site / Update Binding ]
                       │
                       ▼
  1. Capture Configuration Snapshot ────────► appcmd.exe add backup "pre_deploy_<timestamp>"
                       │
                       ▼
  2. Inspect Existing Bindings ─────────────► Check (Host, Port) against all IIS sites
                       │                      IF Host already bound -> ABORT (IIS_ERR_BINDING_CONFLICT)
                       ▼
  3. Validate SNI Invariant ────────────────► Verify sslFlags >= 1 on Port 443
                       │                      IF sslFlags == 0 -> ABORT (IIS_ERR_SNI_MANDATORY)
                       ▼
  4. Apply Additive Site / Binding ─────────► ServerManager.CommitChanges()
                       │
                       ▼
  5. Warm-Up Health Probe ──────────────────► Probe http://127.0.0.1:<port> or https://<host>/health
                       │
                       ├───► SUCCESS: Keep changes; retain backup snapshot.
                       │
                       └───► FAILURE: Trigger Automated Rollback:
                                      appcmd.exe restore backup "pre_deploy_<timestamp>"
                                      Revert to previous verified state within 30 seconds.
```

- **Rollback Criteria:** If any step in binding creation, certificate association, or health verification fails, the agent immediately restores the pre-mutation snapshot via `appcmd.exe restore backup`, ensuring zero leftover state.

---

### 5.4 Windows-Safe Release Path Containment & Reparse Point Handling

Plain string prefix checks (`dest.StartsWith(root)`) are insecure on Windows due to prefix collisions (e.g., `C:\inetpub\releases-evil` matches `C:\inetpub\releases`) and directory junction bypasses.

The release extraction engine must enforce the following **Windows-Safe Path-Boundary Containment Specification**:

#### 1. Canonical Root Normalization
```csharp
string canonicalRoot = Path.GetFullPath(releasesRoot);
if (!canonicalRoot.EndsWith(Path.DirectorySeparatorChar.ToString(), StringComparison.Ordinal))
{
    canonicalRoot += Path.DirectorySeparatorChar;
}
```

#### 2. Entry-Level Pre-Extraction Validation
Before writing any file to disk, inspect each entry in the `.zip` archive:
- **Reject Rooted Entries:** If `Path.IsPathRooted(entry.FullName)` or entry starts with `/` or `\`, throw `DEPLOY_ERR_ABSOLUTE_PATH_REJECTED`.
- **Reject Traversal Tokens:** If entry path contains `..` path segments, throw `DEPLOY_ERR_PATH_TRAVERSAL`.
- **Reject Reserved Windows Device Names:** Check all path segments against DOS reserved names (`CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`, with or without file extensions), throwing `DEPLOY_ERR_RESERVED_DEVICE_NAME`.
- **Reject Alternate Data Streams (ADS):** If entry path contains a colon (`:`), throw `DEPLOY_ERR_INVALID_STREAM_NAME` to prevent NTFS ADS injection.

#### 3. Path-Boundary Containment Check
Compute the destination path using canonical normalization and verify with case-insensitive ordinal comparison:
```csharp
string targetFullPath = Path.GetFullPath(Path.Combine(canonicalRoot, entry.FullName));
if (!targetFullPath.StartsWith(canonicalRoot, StringComparison.OrdinalIgnoreCase))
{
    throw new SecurityException("DEPLOY_ERR_ESCAPE_ATTEMPT: Entry escapes target boundary.");
}
```

#### 4. Reparse Point (Symlinks & Junctions) Prohibition
- **Target Directory Pre-Check:** Verify that the release target directory does not have the `FileAttributes.ReparsePoint` attribute:
  ```csharp
  if ((File.GetAttributes(targetDir) & FileAttributes.ReparsePoint) != 0)
  {
      throw new SecurityException("DEPLOY_ERR_REPARSE_POINT_DETECTED: Destination is a junction/symlink.");
  }
  ```
- **Prohibit Symlink Extraction:** Archive entries marked with Unix symlink attributes or containing reparse point data must be rejected without creating links on disk.
- **Post-Extraction Traversal Verification:** Perform a recursive scan of the extracted files. If any file or folder possesses the `FileAttributes.ReparsePoint` flag, delete the staging folder immediately and abort deployment with `DEPLOY_ERR_UNAUTHORIZED_REPARSE_POINT`.

---

### 5.5 Agent Service Model, Identity, & Lifecycle (`TMK.Agent.Windows`)

- **Worker Implementation:** Standalone C# .NET Worker Service compiled against .NET 8 / .NET 10 LTS using `Microsoft.Extensions.Hosting.WindowsServices`.
- **SCM Protocol Compliance:** Implements Win32 service control dispatcher APIs natively, responding to service start, pause, stop, and shutdown events in < 2 seconds, eliminating Error 1053 permanently.
- **Service Identity & Least Privilege:**
  - Runs under virtual service account `NT SERVICE\TMKIisAgent`.
  - Granted NTFS ACLs strictly on:
    - Installation folder: `C:\Program Files\TMK\Agent\` (Read & Execute)
    - Releases folder: `C:\inetpub\releases\` (Read, Write, Delete)
    - Logging folder: `C:\ProgramData\TMK\Agent\logs\` (Read & Write)
  - Member of `IIS_IUSRS` and granted administrative rights over IIS via Microsoft.Web.Administration API.
- **Automatic Recovery:**
  - SCM recovery settings: 1st failure (restart after 1m), 2nd failure (restart after 2m), subsequent failures (restart after 5m).

---

### 5.6 Artifact Packaging, Cryptographic Provenance, & Transfer

- **Packaging Stage (Linux CI Runner):**
  - Executes `dotnet publish -c Release -r win-x64 --no-self-contained -o <outDir>`.
  - Compresses into `<service>-<timestamp>-<sha>.zip`.
  - Computes SHA-256 digest of the `.zip` archive.
  - Signs the digest using Cosign private key (`cosign.key`).
- **Transfer & Pre-Extraction Verification:**
  - Artifact is streamed to the Windows agent over TLS.
  - Agent recalculates SHA-256 digest of the downloaded `.zip` file.
  - Agent verifies signature against `cosign.pub`.
  - If digest mismatches or signature is invalid, agent rejects the package immediately with `DEPLOY_ERR_SIGNATURE_INVALID` without extracting files.
- **Retention:**
  - Retains the last 3 release archives in `C:\inetpub\_packages\<service>\` for instant local rollback; older packages pruned automatically.

---

### 5.7 Atomic Promotion, Concurrency Fencing, Truthful Health Gates, & Rollback

- **Zero-Lock Blue/Green Swapping:**
  - Artifact is extracted into a fresh directory: `C:\inetpub\releases\<service>\<timestamp>-<sha>\`.
  - Application files are extracted while the site is not running from that directory, eliminating file collisions.
- **Deployment Concurrency Fencing:**
  - Agent uses in-memory and file-based Mutex (`Global\TMK_Deploy_<ServiceName>`) to reject concurrent deployments targeting the same service with `DEPLOY_ERR_CONCURRENCY_LOCKED`.
- **Atomic Promotion:**
  - Updates IIS Application `physicalPath` via `Microsoft.Web.Administration`:
    ```csharp
    site.Applications["/"].VirtualDirectories["/"].PhysicalPath = newReleasePath;
    serverManager.CommitChanges();
    ```
- **Truthful Deployment Health Checks:**
  - Probes configured endpoint over a 30-second observation window (requiring >= 3 consecutive HTTP 200 responses).
  - If endpoint returns HTTP 4xx/5xx or times out: **Deployment Fails Immediately (`DEPLOY_ERR_HEALTHCHECK_FAILED`). Errors are never swallowed.**
- **Sub-Minute Rollback:**
  - On health check failure, agent immediately switches `physicalPath` back to `lastSuccessfulReleasePath` and recycles AppPool.

---

### 5.8 Telemetry Isolation, Logging, & Disaster Recovery

- **Telemetry Isolation:** Query specific `w3wp.exe` worker processes by matching command line arguments `-ap "<AppPoolName>"` or via `WorkerProcess` collection in `Microsoft.Web.Administration`. Eliminate global host memory summing.
- **Audit Logging:** Emit RFC5424 structured events to Windows Event Log and daily local files, streamed to DevOps Manager compliance ledger.
- **Disaster Recovery:** Automated daily export of IIS configuration (`appcmd.exe add backup`) and offsite archive to S3/R2.

---

## 6. Explicit Follow-Up Decisions

To establish clear project governance, we distinguish **W-0 Blocking Architectural Decisions** from **Follow-Up Engineering Decisions Deferred to Later Waves**:

| Domain | Decision Status | Specification & Planned Acceptance Criteria | Delivery Wave |
| :--- | :---: | :--- | :---: |
| **Hosting Topology** | **RESOLVED (W-0 BLOCKER)** | Topology A (Remote Application Node). Control plane on Linux; Windows host runs agent + IIS. | **Phase W-0** |
| **Agent Listener Server** | **RESOLVED (W-0 BLOCKER)** | Standalone Kestrel (`Microsoft.AspNetCore.Server.Kestrel`) on port 5055. Eliminates `netsh urlacl` & `netsh sslcert`. | **Phase W-0** |
| **Initial IIS Routing Model** | **RESOLVED (W-0 BLOCKER)** | Model 1 (IIS Host-Header/SNI bindings on 80/443). Preflight collision checks and configuration backups mandated. | **Phase W-0** |
| **Release Path Containment** | **RESOLVED (W-0 BLOCKER)** | Windows-safe boundary normalization, device name check, ADS rejection, and reparse point prohibition. | **Phase W-0** |
| **Disposable VM Requirement** | **RESOLVED (W-0 BLOCKER)** | Mandatory requirement: Phases W-1 through W-4 must execute on a dedicated disposable Windows VM. Zero testing on live host. | **Phase W-0** |
| **Control-Plane to Worker Connectivity** | *Follow-Up (Engineering)* | Baseline: Inbound HTTPS on 5055 restricted by Windows Firewall. Advanced: Outbound polling channel for NATed nodes. | **Phase W-1 / W-3** |
| **Worker Identity & Certificate Bootstrap** | *Follow-Up (Engineering)* | `NT SERVICE\TMKIisAgent`. Pilot: Self-signed certificate pinned in DevOps Manager. Production: Private CA or win-acme. | **Phase W-1** |
| **Artifact Signature & Cosign Format** | *Follow-Up (Engineering)* | Pushed SHA-256 digest signature verification using Cosign detached signature payload. | **Phase W-3** |
| **Deployment Concurrency & Fencing** | *Follow-Up (Engineering)* | `Global\TMK_Deploy_<Service>` mutex with advisory locking integration in DevOps Manager. | **Phase W-2** |
| **Secret & Key Backup / DR** | *Follow-Up (Engineering)* | Machine DPAPI protection for local tokens; offsite encrypted backup for IIS configs and certificates. | **Phase W-4** |

---

## 7. Recommended Post-W-0 Implementation Phase Sequence

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    POST W-0 WINDOWS IMPLEMENTATION PHASES                    │
├─────────────┬────────────────────────────────────┬───────────────────────────┤
│ Phase       │ Focus                              │ Primary Acceptance Gate   │
├─────────────┼────────────────────────────────────┼───────────────────────────┤
│ **Phase W-0**│ Architecture & Coexistence Gate   │ ADR Approved & Signed-Off │
│ **Phase W-1**│ Compiled Agent & SCM Service      │ Service Starts, Health 200│
│ **Phase W-2**│ Atomic Swapping & Health Gates    │ Zero File Locks, Auto-Roll│
│ **Phase W-3**│ Automated CI Packaging & Transfer │ Automated Git -> Zip -> VM│
│ **Phase W-4**│ Live Qualification & Observability│ 100% Tests Pass, DR Valid │
└─────────────┴────────────────────────────────────┴───────────────────────────┘
```

### Phase W-1: Compiled Windows Agent & SCM Service Runtime (`TMK.Agent.Windows`)
- **Scope:** Build compiled C# .NET Worker Service (`TMK.Agent.Windows`), Kestrel listener, firewall rule, DPAPI secret management.
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
- `C:\var\www\vps-infra`: `b691e7b` (Base `cbe6db11614ff22875ff0af1c7b3b3f3921c8fb3`)
- `C:\var\www\vps-infra-server`: `b65caae` (Base `a7ccb0c6ee0587105a1be67b24b53603db7540b1`)

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

---

## 10. W-0 reconciliation amendment (2026-10-06; authoritative over earlier draft text)

**Status: DRAFT — decisions recorded for review; approval NOT VERIFIED. W-0 remains open.** This amendment supersedes conflicting claims in sections 5–7 and the earlier re-gate report. It does not authorize implementation. Existing working-tree revisions have been retained. No named approver, approval date, or approved revision is recorded. The original readiness report is historical evidence, not a current host certification.

### 10.1 OS priorities and listener decision

Server 2025 is the preferred target for new installations and the first disposable qualification VM. Server 2022 is a secondary compatibility target for existing estates or documented provider/application constraints, not the default for new installations. Server 2019 is a legacy compatibility candidate only. All three remain **NOT VERIFIED** for Windows acceptance. Provider availability, IIS compatibility, resource estimates and delivery estimates in the earlier comparison are assumptions, not qualification evidence.

Microsoft lifecycle pages checked 2026-10-06: [Server 2025](https://learn.microsoft.com/en-us/lifecycle/products/windows-server-2025) and [Server 2022](https://learn.microsoft.com/en-us/lifecycle/products/windows-server-2022). The retrieved pages display timezone-specific timestamps: 2025 mainstream/extended ends 2029-11-14 / 2034-11-15, and 2022 ends 2026-10-14 / 2031-10-15. These supersede the earlier table's dates; preserve the source timezone when interpreting precise end instants. The longer published lifecycle supports the proposed new-install priority; it does not prove compatibility.

**Choose standalone Kestrel** for the worker management API, separate from IIS application ingress. No HTTP.sys backend, worker URL ACL, or worker HTTP.sys TLS binding is part of this design. [Microsoft server implementation guidance](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/?view=aspnetcore-10.0) describes these as alternative servers. Kestrel terminates TLS with a worker-specific certificate and binds only the explicitly configured management interface/port (5055 default) after collision checks; do not default to all interfaces. IIS retains its existing HTTP.sys ownership of application ingress. Installation and any firewall changes are later VM work, never actions in this review.

### 10.2 Initial routing and preservation contract

Retain Model 1: direct IIS host-header/SNI routing for **new, explicitly enrolled managed sites**; Linux Traefik does not take Windows ports 80/443. This explicitly replaces the readiness report's proposed 8081–8099 internal-port model; no automatic fallback or proxy installation is authorized. Existing sites are not adopted or modified. A conflicting host must be rejected rather than moved. DNS, certificates and new managed bindings require a separate deployment change plan after qualification.

Preflight must inventory site IDs/names, physical paths, AppPools and identities, protocol/IP/port/normalized-host binding tuples, wildcard/catch-all behavior, HTTP.sys SSL associations, certificate thumbprints/store/SNI flags, and relevant IIS configuration. Snapshot and hash the configuration; retain baseline request results for every existing site's HTTP host and HTTPS SNI/certificate, with an approved maintenance test policy. Refuse mutation if inventory, baseline or collision analysis is incomplete. Check all overlapping IP scopes and wildcard hosts, not merely (host, port). For HTTPS, test the SNI bit `(sslFlags & 1) != 0`; `sslFlags >= 1` is insufficient. Central certificate store use requires an explicit later decision.

Postflight must compare every non-managed object and baseline response/certificate against preflight. Fail on any unexpected binding, certificate, path, AppPool, service-state or customer-response change, or on managed-site health failure. Roll back only objects changed by this operation, using recorded before-values and ownership/version checks. Never automatically restore the whole IIS snapshot on a shared host: it can erase unrelated concurrent changes. A full restore is permitted only in a separately controlled recovery window with exclusive change control and operator authorization. Drift or rollback failure halts further mutations, records failure and alerts an operator. Target rollback is 30 seconds, pending measured Windows evidence; neither zero downtime nor atomic traffic shifting is claimed.

### 10.3 Archive containment contract

The worker maps authenticated tenant/service IDs to an administrator-enrolled local root; a request cannot supply an arbitrary PhysicalPath, artifact path or UNC location. Create a fresh unpredictable staging directory per release beneath that service root, not merely beneath the global releases root. Canonicalize absolute root/destination paths using Windows semantics and require a separator-bounded descendant with ordinal case-insensitive comparison. Lexical checks alone do not prove filesystem containment.

Before any extraction, normalize both archive separator forms and reject rooted/drive-relative/UNC/device/extended-namespace paths, dot or dot-dot components, NUL/control characters, colons/ADS, reserved device basenames even with extensions, trailing dots/spaces, invalid segments, case-insensitive duplicate destinations and file/directory collisions. Reject symlink, hardlink and reparse entries. Bound compressed/uncompressed sizes, entry count, depth and expansion ratio before writes; enforce actual streamed-byte limits. The complete manifest must pass before file creation.

Validate every existing ancestor from the trusted root through staging, and each destination component, without following reparse points. Protect roots and staging with ACLs denying writes by applications and untrusted principals. Use handle-based no-follow traversal/creation or an equivalent proven race-resistant mechanism; abort if a junction substitution or other containment race cannot be excluded. A pre/post scan alone is insufficient. Revalidate before promotion. On failure leave the active release untouched and quarantine staging; cleanup must itself use no-follow containment checks and must never recursively follow a discovered link. Qualification cases include sibling-prefix escape, mixed separators, ADS, reserved names, duplicate case variants, ancestor junctions, archive links, concurrent junction replacement and decompression bombs. Assert zero writes outside the service staging root.

### 10.4 Required follow-up acceptance evidence

Each item below is a later **phase exit gate**, not an implementation claim. Attach exact commit, OS edition/build, command/test fixture, result and redacted logs from disposable Windows Server VMs. No Linux test may satisfy a Windows gate.

| ID / phase | Acceptance criteria |
| --- | --- |
| F1 — W-1 connectivity; W-3 NAT extension | Initial pilot requires a reachable management address or approved private tunnel and stable allowlisted control-plane source. Nodes behind non-forwardable NAT are unsupported until an outbound authenticated channel is implemented and qualified; no silent fallback or exposure to all IPs. Test from the actual Linux control-plane container: DNS, routing, TLS name/chain, authenticated health, rejected unauthorized source/token, restart, partition/reconnect, timeout and duplicate request delivery. Verify IPv4/IPv6 scope. Record provider/NAT assumptions. |
| F2 — W-1 identity/certificates | Use a dedicated service identity with service-SID ACLs for worker files and private key. IIS_IUSRS membership is not proof of administrative delegation. Prove the minimum scoped mutation rights, or review a narrowly constrained privileged broker before adding rights; reject arbitrary IIS operations. Authenticate enrollment out of band; bind credentials to node and tenant. Test wrong name/chain/EKU, expired/revoked certificates, token replay/revocation, renewal overlap, emergency rotation, uninstall and crash/reboot. No TLS validation bypass, default secrets or logging private material. Machine DPAPI requires restrictive ACLs and does not alone provide tenant isolation or portable recovery. |
| F3 — W-3 signatures/rotation | Freeze a versioned signed manifest/envelope and exact Cosign verification format/tool version before implementing. Bind archive SHA-256, size, tenant/service, release/source commit and monotonic generation to the signature. Worker trust keys are administrator-provisioned, never accepted from the artifact. Verify signature and authorization before extraction. Test tamper, wrong signer/tenant, unsigned input, replay/downgrade, unsupported algorithm and key ID, old/new overlap, revoked-key rejection and emergency compromise. Signed digest alone is not proof of deployment authorization. Key rotation must preserve separately authorized known-good rollback. |
| F4 — W-2 promotion/concurrency/health | Immutable verified staging, scoped per-service lock plus distributed lease with monotonically increasing fencing generation, idempotent operation IDs and durable journal. Reject stale owners after lease expiry/reconnect. Serialize shared IIS configuration commits and detect external drift. Inject concurrent deploys, process kill/reboot at each transition, file locks and partial commits. Health must use correct Host/SNI and expected release identity so a neighboring/old site cannot pass; require three consecutive valid probes within a bounded 30-second window. Inject 500, wrong release, timeout and dependency failure. Restore last verified path and verify restored health; record rollback failure separately, never SUCCESS. Protect active/last-good releases from pruning. Database changes need an explicit compatibility/restore plan; pointer rollback cannot undo schema/data changes. |
| F5 — W-4 secure backup/recovery | Inventory IIS configuration, managed releases, ACLs, app state/data, certificate references and exportability, identity/enrollment and trust-key metadata. Use encrypted authenticated offsite backup, independent key escrow, least-privilege credentials, access audit, retention and integrity checks; never plaintext PFX passwords/tokens. Do not treat appcmd backup as certificate/private-key or database backup. Define RPO <=24h and RTO <=4h as proposed pilot targets for approval. Restore on a clean VM with the original machine/DPAPI keys unavailable; re-enroll and rotate credentials or use approved escrow, including non-exportable-certificate reissuance. Prove site routing, TLS, ACLs, application/data consistency and rollback usability; measure RPO/RTO and alert on missing/corrupt backup. |

### 10.5 Approval and implementation boundary

W-0 original acceptance requires (1) an approved ADR establishing the remote-node topology and (2) executable setup validation proving preservation of existing sites. Documented criteria are not executed checks. Record accountable architecture/security/operations approvers, accepted revision/commit, date and any exceptions before approval can PASS. The preservation script and VM results are absent in the reviewed evidence, so that gate is NOT VERIFIED. W-1 must not begin under this task. Later implementation and qualification must use a disposable Server 2025 VM, with a separate Server 2022 compatibility run before claiming its support. No current production-server experiment is permitted. Phase 0.5 remains an independent Linux schema task; shared release/schema dependencies must still be assessed explicitly.