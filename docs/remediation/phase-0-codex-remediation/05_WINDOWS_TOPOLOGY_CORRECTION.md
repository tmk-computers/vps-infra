# WINDOWS SERVER 2022 TOPOLOGY CORRECTION (C1-03 RESOLUTION)

**Document ID**: `REMED-P0-CDX-05`  
**Phase**: Phase 0 — Codex Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C1-03`)  
**Status**: COMPLETE ARCHITECTURAL SPECIFICATION  

---

## 1. Context & Problem Statement

The Codex Phase 0 Audit Gate flagged finding `C1-03` as a **Significant Defect (C1)**. The audited baseline suffered from critical ambiguities in its Windows Server 2022 architecture:
1. **Unsupported Docker Runtime**: `setup.ps1:61` prescribed installing WSL2 and Docker Desktop on Windows Server. Docker's official documentation explicitly states that Docker Desktop is **not supported on Windows Server** (including Windows Server 2022).
2. **Undefined Database Location**: The Gate A database profile required PostgreSQL 16, but never specified where PostgreSQL executes when the application runs on Windows Server 2022. It silently implied running PostgreSQL inside WSL2 or an unsupported Docker container on Windows.
3. **Ingress Conflict**: Baseline documents described running Traefik alongside IIS on Windows, leading `setup.ps1` to stop the World Wide Web Publishing Service (`W3SVC`) so Traefik could bind to ports 80 and 443. This created a contradictory topology where IIS hosting required disabling IIS!
4. **Agent Communication & Upgrade Ambiguity**: The communication contract between DevOps Manager and `TMK.Agent.Windows`, the service identity, and agent self-update mechanisms were undefined.

This document freezes the authoritative, supported **Windows Server 2022 Gate-A Topology**.

---

## 2. Frozen Gate-A Windows Architecture

The Gate A Windows profile is defined as a **Native Windows IIS Application Host** managed remotely by the Shared Control Plane, backed by an isolated **Remote PostgreSQL 16 Endpoint**.

```
+-----------------------------------------------------------------------------------+
|                           LINUX HOST / VM (CONTROL PLANE)                         |
|                                                                                   |
|   +---------------------------------------------------------------------------+   |
|   |   DevOps Manager API (Shared Platform Core)                               |   |
|   +---------------------------------------------------------------------------+   |
|         |                                                             |           |
+---------|-------------------------------------------------------------|-----------+
          |                                                             |
   (mTLS / HTTPS :5055)                                         (TLS / TCP :5432)
          |                                                             |
          v                                                             v
+------------------------------------+        +-------------------------------------+
|    WINDOWS SERVER 2022 HOST        |        |    REMOTE POSTGRESQL 16 INSTANCE    |
|                                    |        |    (Dedicated Linux VM or Managed)  |
|  +------------------------------+  |        |                                     |
|  | TMK.Agent.Windows            |  |        |  +-------------------------------+  |
|  | (.NET Worker Windows Service)|  |        |  | PostgreSQL 16.2 Database      |  |
|  | Runs as: LocalService        |  |        |  | Enforces SSL/TLS Required     |  |
|  | Listens on: 0.0.0.0:5055     |  |        |  | Bound to private VPC / IP     |  |
|  +--------------+---------------+  |        |  +-------------------------------+  |
|                 |                  |        +-------------------------------------+
|                 | (Local API)      |                                  ^
|                 v                  |                                  |
|  +------------------------------+  |                                  |
|  | IIS 10 Web Server (HTTP.sys) |  |                                  |
|  | - Listens on: :80 & :443     |  |                                  |
|  | - Manages AppPools & Sites   |  |                                  |
|  | - SNI SSL Certificates       |  |                                  |
|  |                              |  |                                  |
|  |  +------------------------+  |  |                                  |
|  |  | Customer App (ASP.NET) |----------------------------------------+
|  |  | Connects via TLS to DB |  |  | (Encrypted DB Connection)
|  |  +------------------------+  |  |
|  +------------------------------+  |
+------------------------------------+
```

---

## 3. Explicit Topology Decisions (Gate A Freeze)

### 3.1 Host Operating System
- **Supported Target**: Windows Server 2022 Standard / Datacenter (x64), fully patched.
- **Explicitly Excluded / Prohibited for Gate A**:
  - WSL2 (Windows Subsystem for Linux);
  - Docker Desktop on Windows Server (unsupported by Docker Inc.);
  - Windows Server Containers (deferred to post-Gate-A evaluation).

### 3.2 Application Runtime
- Native Windows **IIS 10.0** with ASP.NET Core Module v2 (ANCM) and .NET 8 Hosting Bundle.
- Applications run in dedicated IIS Application Pools configured with `ApplicationPoolIdentity` (least privilege sandbox).

### 3.3 Database Location & Connectivity
- **Certified Gate-A Profile**: PostgreSQL 16 executes on a **Dedicated Remote Linux VM** or managed PostgreSQL 16 service within the private network.
- **Application Connection**: The IIS-hosted application connects to PostgreSQL over TCP port 5432 using authenticated TLS connections (`SSL Mode=VerifyFull` or `SSL Mode=Require;Trust Server Certificate=false` with validated CA; unauthenticated `Trust Server Certificate=true` is strictly prohibited).
- **Prohibited**: Running PostgreSQL natively on Windows Server via ad-hoc Windows service binaries or running PostgreSQL inside WSL2.

### 3.4 Ingress & Port Architecture (Zero Conflict)
- **Elimination of Traefik on Windows Host**: Traefik is **NOT deployed** on the Windows Server host.
- **Ingress Layer**: Native Windows kernel driver **`HTTP.sys`** and IIS 10 own ports 80 and 443 directly.
- **Port Sharing**: `HTTP.sys` provides native kernel-level port sharing and URL reservation (`netsh http add urlacl`).
- **TLS / Certificates**: TLS certificates are bound directly in IIS using Server Name Indication (SNI) and stored securely in the Windows `LocalMachine\My` Certificate Store.
- **Elimination of `setup.ps1` W3SVC Stop**: The legacy setup step stopping `W3SVC` is formally removed. IIS runs continuously.

---

## 4. Control Plane to Windows Agent (`TMK.Agent.Windows`) Contract

The legacy PowerShell script agent (`tmk-iis-agent.ps1`) is strictly designated as bootstrap/diagnostic tooling. For production Gate A, the agent is implemented as a compiled .NET Worker Windows Service (`TMK.Agent.Windows`).

### 4.1 Agent Architecture & Communication Contract

| Dimension | Specification |
|---|---|
| **Service Name** | `TMK.Agent.Windows` (Display: *TMK Infrastructure Agent for Windows*) |
| **Runtime Binary** | Self-contained compiled .NET 8 executable (`TMK.Agent.Windows.exe`). |
| **Service Account** | **Dedicated least-privilege Windows service identity** (e.g. `NT SERVICE\TMKAgent`) with explicitly granted rights: IIS administration / AppPool control, deployment filesystem rights (`C:\inetpub\staging\` and `C:\inetpub\wwwroot\apps\`), and SCM inspection; restricted from unrelated OS directories and LocalSystem privileges. |
| **Communication Direction** | **Bidirectional**: <br>1. **Inbound**: DevOps Manager issues deployment commands to Agent via HTTPS on port 5055.<br>2. **Outbound**: Agent pushes health and telemetry heartbeats to DevOps Manager via HTTPS on port 5001. |
| **Transport Security** | Mutual TLS (mTLS) with client certificate authentication. Both DevOps Manager and `TMK.Agent.Windows` validate each other's certificate thumbprints against a pinned root CA. |
| **Authorization** | Every incoming request must provide an HTTP Authorization header containing a cryptographically signed Windows Agent Bearer Token (`aud: "tmk-agent-windows"`). |
| **Deployment Root Sandbox** | The agent is strictly restricted to operations within `C:\inetpub\wwwroot\apps\{tenant}\` and `C:\inetpub\staging\`. Normalized segment-boundary containment rejects any path escaping these roots. |
| **Concurrency** | The agent executes a single deployment operation at a time using an internal C# `SemaphoreSlim(1, 1)`. Concurrent requests receive HTTP 423 Locked. |

---

## 5. Independent Windows Upgrade & Rollback Lifecycle

The platform distinguishes three separate upgrade targets on Windows:
1. **Application Workload Upgrade**;
2. **Windows Agent Upgrade (`TMK.Agent.Windows`)**;
3. **Host OS Windows Updates**.

### 5.1 Application Workload Upgrade (Zero Disruption)
1. DevOps Manager sends signed deployment package (`.zip`) and release manifest to `TMK.Agent.Windows` via `POST https://windows-host:5055/api/v1/deploy`.
2. Agent extracts files to isolated staging path: `C:\inetpub\staging\{ServiceName}_{ReleaseVersion}\`.
3. Agent configures staging IIS Application Pool and bindings on private loopback port (`127.0.0.1:508x`).
4. Agent executes internal health check (`GET http://127.0.0.1:508x/health`).
5. Upon successful health probe, Agent atomically swaps IIS bindings / URL rewrite rules to point live domain traffic to the new Application Pool.
6. The previous Application Pool is placed in standby for a 10-minute observation window.
7. If health fails, Agent immediately reverts IIS bindings to the previous Application Pool.

### 5.2 Agent Self-Update Lifecycle (Atomic Swap, Health Verification & Reboot Recovery)
An agent replacing its own executable binary while running is hazardous. `TMK.Agent.Windows` implements a robust two-stage update wrapper:
1. **Download & Verify**: New agent binary (`TMK.Agent.Windows.new.exe`) is downloaded to `C:\Program Files\TMK\Agent\staging\` and verified against its cryptographic SHA-256 digest.
2. **Update Helper Invocation**: The agent launches a lightweight, detached Windows helper executable (`TMK.Agent.Updater.exe`) and signals its own termination.
3. **Execution Swap**:
   - `TMK.Agent.Updater.exe` waits for the main agent service process to exit (timeout 15s).
   - Backs up current binary: `TMK.Agent.Windows.exe` → `TMK.Agent.Windows.bak.exe`.
   - Copies new binary: `TMK.Agent.Windows.new.exe` → `TMK.Agent.Windows.exe`.
   - Starts the Windows Service: `sc.exe start TMK.Agent.Windows`.
4. **Functional Health Verification & Rollback**:
   - The helper monitors service start status and actively probes the agent's local functional health endpoint: `GET http://127.0.0.1:5055/health` (polling every 3s for 30s).
   - If the service fails to enter `SERVICE_RUNNING`, crashes, or returns non-200 from `/health`:
     - The helper stops the broken service.
     - Restores `TMK.Agent.Windows.bak.exe` → `TMK.Agent.Windows.exe`.
     - Restarts the previous known-good service binary.
     - Logs critical error to Windows Event Log (`Application` log, Source: `TMK.Agent.Updater`).
5. **Reboot / Power Loss Recovery**:
   - On Windows system startup, `TMK.Agent.Updater.exe` runs a startup integrity check before service launch. If a pending or interrupted update is detected (e.g. `.bak` exists but `/health` was never verified), it executes deterministic recovery: rolls back to `.bak` binary, cleans staging files, and resumes known-good service.

---

## 6. Windows Gate-A Certification Boundary

In accordance with the Dual-OS mandate:
- **Independent Windows Gate A (Phase 12B)**: Windows Server 2022 certification is evaluated independently against this frozen topology.
- **Zero Inherited Evidence**: Linux test passes cannot be substituted for Windows test passes.
- **Acceptance Scope**: Windows Gate A requires successful execution of:
  - Agent installation and mTLS pairing;
  - Native IIS application deployment, health probing, and atomic cutover;
  - Automated IIS rollback drill;
  - Agent self-update and simulated failure rollback drill;
  - Remote PostgreSQL 16 encrypted connectivity and schema migration.

---

## 7. Conclusion

This architecture resolves finding `C1-03`. It eliminates unsupported Docker Desktop and WSL2 configurations on Windows Server 2022, defines an explicit remote PostgreSQL 16 database location, removes port 80/443 ingress conflicts by standardizing on native `HTTP.sys` / IIS 10, and establishes a robust compiled .NET Worker agent lifecycle.
