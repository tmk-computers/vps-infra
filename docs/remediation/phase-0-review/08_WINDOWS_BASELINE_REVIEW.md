# 08 WINDOWS PRODUCTION BASELINE INDEPENDENT REVIEW

**Document ID**: `REMED-P0-REV-08`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Windows Server 2022 Baseline Evaluation Overview

In strict accordance with the **Dual-OS Non-Negotiable Mandate**, Windows Server 2022 is evaluated as an equal, first-class target platform. Windows deficiencies are not deferred to ease a Linux-only launch.

The Reviewer independently audited the Windows baseline across [`setup.ps1`](file:///d:/company/products/vps-infra/vps-infra/setup.ps1), [`tmk-iis-agent.ps1`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1), [`IisClientService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs), and related documentation.

---

## 2. Individual Forensic Audit of Windows Items (MR-22 through MR-29)

### 2.1 MR-22: Windows Agent Executable Architecture & SCM Integration (P0)
- **Code Reality**:
  - In `vps-infra`, [`scripts/tmk-iis-agent.ps1:345`](file:///d:/company/products/vps-infra/vps-infra/scripts/tmk-iis-agent.ps1#L345) contains a **fatal AST syntax error** (`Try statement missing Catch/Finally`). The PowerShell parser fails immediately.
  - In documentation ([`04-iis-hosted-apps.md:28`](file:///d:/company/products/vps-infra/vps-infra/docs/02-deploying-applications/04-iis-hosted-apps.md#L28)), the agent is registered via `New-Service -BinaryPathName "powershell.exe -File tmk-iis-agent.ps1"`. This fails on Windows Server with **SCM Error 1053** ("The service did not respond to the start or control request in a timely fashion") because raw PowerShell does not implement the Windows Service Control Manager protocol.
  - Health probe failures are caught and swallowed (lines 290-295), declaring `Success = true` even when the target IIS site returns errors.
- **Reviewer Assessment**: **CONFIRMED P0 DEFECT**. PowerShell is fundamentally flawed for long-running Windows services. Transition to a compiled `.NET Worker` Windows Service (`TMK.Agent.Windows`) is mandatory.

### 2.2 MR-23: Windows Control-Plane Connectivity (P0)
- **Code Reality**:
  - In `tmk-iis-agent.ps1:32`, the HTTP listener binds strictly to `$prefix = "http://127.0.0.1:$Port/"`.
  - When the DevOps Manager API runs inside a container (e.g. Docker Desktop, Hyper-V, or WSL2), requests originating from the container network to `host.docker.internal:5055` are rejected with HTTP 400 Bad Request because `HttpListener` rejects host headers that do not match the registered prefix.
- **Reviewer Assessment**: **CONFIRMED P0 DEFECT**. Prefix must be configured as `http://+:$Port/` with appropriate `netsh http add urlacl` permissions or explicit network binding.

### 2.3 MR-24: Windows Deployment Filesystem Sandbox (P1)
- **Code Reality**:
  - In `tmk-iis-agent.ps1:232-235`, `$targetDir = $deployReq.PhysicalPath`. The script passes this unvalidated string directly to `Expand-Archive`.
  - An attacker or misconfigured payload can supply `C:\Windows\System32` or `C:\Program Files`, extracting arbitrary files into protected operating system directories.
- **Reviewer Assessment**: **CONFIRMED P1 DEFECT**. Requires strict sandboxing to `C:\inetpub\wwwroot\apps\{App}` with `Path.GetFullPath` prefix validation and least-privilege NTFS ACLs.

### 2.4 MR-25: Windows Telemetry Correctness (P1)
- **Code Reality**:
  - In [`IisClientService.cs:395-404`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs#L395-L404), memory usage is computed by executing `Process.GetProcessesByName("w3wp")` and **summing the WorkingSet64 of ALL worker processes on the host**.
  - A single low-traffic IIS site is reported as consuming the cumulative memory of every IIS site on the entire Windows server.
- **Reviewer Assessment**: **CONFIRMED P1 DEFECT**. Must query the specific Application Pool's worker process PID via WMI / `Microsoft.Web.Administration` to report accurate per-application telemetry.

### 2.5 MR-26: Windows Agent Concurrency & Request Blocking (P1)
- **Code Reality**:
  - In `tmk-iis-agent.ps1:114-115`, the request processing loop executes `$listener.GetContext()`.
  - This is a synchronous, blocking single-threaded API. While a 100MB application archive is being decompressed and deployed (which takes 15–45 seconds), the entire agent blocks. Concurrently incoming health checks, telemetry requests, or restart signals time out.
- **Reviewer Assessment**: **CONFIRMED P1 DEFECT**. Asynchronous request handling via Kestrel in a compiled daemon is required.

### 2.6 MR-27: Windows IIS / Ingress Coexistence (P0)
- **Code Reality**:
  - In [`setup.ps1:440-459`](file:///d:/company/products/vps-infra/vps-infra/setup.ps1#L440-L459), when setup detects port 80/443 contention, it explicitly prompts:  
    `Would you like to stop W3SVC (IIS) to free ports 80/443 for Traefik? [y/N]`  
    and executes `Stop-Service W3SVC -Force`.
  - This stops the entire Windows native IIS web server, killing existing enterprise .NET applications to make way for Traefik.
- **Reviewer Assessment**: **CONFIRMED P0 DEFECT**. Coexistence must be supported out of the box: either Traefik binds dedicated non-conflicting ports (e.g. 8080/8443) or binds a secondary IP address, while IIS retains its native HTTP.sys bindings.

### 2.7 MR-28: Windows Agent Authentication & Dynamic Secret Generation (P0)
- **Code Reality**:
  - In `tmk-iis-agent.ps1:21` and `IisClientService.cs:42`, both caller and receiver default to:  
    `$Secret = "[REDACTED_COMPROMISED_DEFAULT]"`
  - Any network caller possessing this known static string can invoke the `/api/iis/deploy` endpoint and extract arbitrary code onto the Windows host.
- **Reviewer Assessment**: **CONFIRMED P0 DEFECT**. Setup must generate a cryptographically strong installation secret and reject static fallbacks on boot.

### 2.8 MR-29: Windows Artifact Compilation & Packaging Pipeline (P1)
- **Code Reality**:
  - Inspection of `ci-server/api/build-runner.js` confirmed zero support for Windows compilation targets (`win-x64`).
  - The CI server can build only Linux Docker containers. Operators deploying .NET Framework or IIS applications are forced to manually compile and zip binaries on their local laptops before uploading.
- **Reviewer Assessment**: **CONFIRMED P1 DEFECT**. Requires a Windows build worker or cross-compilation pipeline (`dotnet publish -r win-x64`) producing verified release zip archives.

---

## 3. Windows Gate A Certification Policy

1. **Independent Windows Gate**: Windows Server 2022 cannot be certified today due to 8 active blockers (`MR-22` through `MR-29`).
2. **Concurrent Remediation Track**: Windows remediation will execute in **Phase 4** (`TMK.Agent.Windows` compilation and setup rewrite) and **Phase 11** (dual-OS chaos testing), culminating in **Windows Gate A (Phase 12)**.
3. **No Dilution**: Windows certification will not be bypassed or compromised.
