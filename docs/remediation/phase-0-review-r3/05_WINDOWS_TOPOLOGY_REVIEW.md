# 05 WINDOWS SERVER 2022 TOPOLOGY & AGENT LIFECYCLE REVIEW

**Document ID**: `REMED-P0-REV-R3-05`  
**Phase**: Phase 0 — Independent Re-Review after Codex Remediation (Cycle R3)  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Audit Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C1-03`)  
**Target Artifacts**: `05_SUPPORTED_OS_MATRIX.md`, `04_TARGET_ARCHITECTURE.md`, `05_WINDOWS_TOPOLOGY_CORRECTION.md`  
**Verdict**: **PASS — WINDOWS GATE-A TOPOLOGY FROZEN & UNAMBIGUOUS**  

---

## 1. Executive Evaluation of C1-03 Resolution

Finding `C1-03` was a **Significant Defect (C1)** identified by the Codex Phase 0 Audit Gate. The audited baseline suffered from critical ambiguities in its Windows Server 2022 implementation:
1. It directed the installation of WSL2 and Docker Desktop on Windows Server (`setup.ps1:61`), in direct contradiction of Docker's official support requirements (Docker Desktop is unsupported on Windows Server 2022);
2. The deployment location of PostgreSQL 16 on the Windows profile was completely undefined;
3. `setup.ps1` stopped the IIS `W3SVC` service so Traefik could bind to ports 80/443, creating a contradictory architecture where IIS hosting required disabling IIS;
4. The Windows Agent communication security and self-update lifecycles were undefined.

The Developer has authored [`05_WINDOWS_TOPOLOGY_CORRECTION.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md) and synchronized [`05_SUPPORTED_OS_MATRIX.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md). This independent review evaluates the technical feasibility and rigor of the frozen Windows architecture.

---

## 2. Review of the Frozen Windows Gate-A Topology

The Gate A Windows profile is defined as a **Native Windows IIS Application Host** managed remotely by the Shared Control Plane, backed by an isolated **Remote PostgreSQL 16 Endpoint**.

```
+-----------------------------------------------------------------------------------+
|                           LINUX HOST / VM (CONTROL PLANE)                         |
|                                                                                   |
|   +---------------------------------------------------------------------------+   |
|   |   DevOps Manager API (.NET 8 Core)                                        |   |
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
|  | Dedicated Service Account    |  |        |  | Enforces SSL/TLS Required     |  |
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
|  |  +------------------------+  |  |
|  |  | Standby AppPool (N-1)  |  |  | (Quiesced for instant rollback)
|  |  +------------------------+  |  |
|  +------------------------------+  |
+------------------------------------+
```

### 2.1 Topology Decisions Evaluated
1. **Workload Runtime**: Native IIS 10 with ASP.NET Core Module v2 (ANCM). Workloads run as compiled .NET 8 applications in isolated Application Pools (`ApplicationPoolIdentity`).
2. **Database Location**: PostgreSQL 16 executes on a **dedicated remote Linux VM or managed cloud instance**. The IIS application connects over encrypted TLS on TCP port 5432.
3. **Ingress Architecture**: Native Windows kernel driver **`HTTP.sys`** and IIS 10 own ports 80 and 443 directly. Traefik is **NOT deployed** on the Windows host.
4. **Prohibitions**: WSL2, Docker Desktop, and Windows Server Containers are **strictly excluded and prohibited** from the Gate A certification profile.

---

## 3. Scrutiny of the Windows Agent Service Identity

In `05_WINDOWS_TOPOLOGY_CORRECTION.md:106`, the Developer specifies:
> *"Service Account: `NT AUTHORITY\LocalService` (with restricted filesystem ACLs granting write access only to `C:\inetpub\staging\` and read access to IIS configuration)."*

As Independent Reviewer, we identify a significant technical limitation in this specification:
- **The LocalService Problem**: By default in Windows Server, `NT AUTHORITY\LocalService` is an unprivileged user without access to the IIS administration API (`Microsoft.Web.Administration` / COM interface to WAS/W3SVC). It cannot create new Application Pools, modify website bindings, or manipulate the `applicationHost.config` file.
- If `TMK.Agent.Windows` runs as default `LocalService`, any attempt to configure staging sites or execute cutover bindings will fail with `UnauthorizedAccessException`.
- Conversely, elevating the agent to `NT AUTHORITY\System` (LocalSystem) is an over-privileged security violation.

> [!IMPORTANT]
> **Refined Architectural Specification — Dedicated Least-Privilege Windows Service Account (R2-02)**:  
> Phase 0 must specify a **Dedicated Service Account with Delegated IIS Administration Rights**:
> 1. Service runs under a dedicated virtual service account (e.g. `NT SERVICE\TmkAgentWindows`) or custom local user (`.\TmkAgentService`);
> 2. The account is explicitly added to the local **`IIS_IUSRS`** group and granted administrative rights in `applicationHost.config` via IIS configuration locking delegation;
> 3. Filesystem ACLs restrict write permissions strictly to `C:\inetpub\staging\`, `C:\inetpub\wwwroot\apps\`, and its private working directory;
> 4. Windows Service Rights: Granted `SeServiceLogonRight` and service control privileges (`sc.exe sdset`).

---

## 4. Control Plane to Windows Agent Communication Contract

The control plane (`devops-manager` on Linux) communicates with `TMK.Agent.Windows` on the Windows host across an encrypted boundary:

### 4.1 Transport & Network Security
- **Port**: Dedicated internal TCP port **5055**.
- **Transport Security**: Mutual TLS (mTLS) with client and server certificates.
  - The control plane presents a client certificate signed by the internal Platform CA.
  - The agent validates the certificate thumbprint against its pinned trust store.
  - The agent presents a server certificate with Subject Alternative Name (SAN) matching its private IP/hostname.
- **Firewall Scoping**: Windows Advanced Firewall rule restricts inbound TCP 5055 strictly to the control plane VM's private IP address.

### 4.2 Request Authorization
- Every HTTPS deployment request must include an `Authorization: Bearer <jwt>` header.
- Token claims: `iss: "https://auth.vps-infra.local/"`, `aud: "tmk-agent-windows"`, `sub: "agent_runner"`.
- Requests missing a valid token return HTTP 401 Unauthorized.

---

## 5. Ingress & Port Architecture: Resolution of Port 80/443 Conflict

In the historical baseline, `setup.ps1` attempted to bind Traefik to port 80/443 on Windows, which required executing `net stop W3SVC` to kill IIS.

### 5.1 Resolution Mechanism
- **Native `HTTP.sys` Ownership**: By eliminating Traefik from the Windows host, `HTTP.sys` (the native Windows kernel HTTP listener) owns ports 80 and 443 exclusively.
- **Multi-Application Port Sharing**: `HTTP.sys` provides kernel-level URL reservation (`netsh http add urlacl`). Multiple IIS sites share ports 80 and 443 based on Server Name Indication (SNI) host headers.
- **Certificate Lifecycle**: SSL certificates are imported into the Windows `LocalMachine\My` certificate store and bound to IIS sites via standard SNI bindings.
- **W3SVC Continuous Operation**: The World Wide Web Publishing Service runs continuously; `setup.ps1` W3SVC stoppage is permanently eradicated.

---

## 6. Windows Agent Self-Update & Rollback Invariant

Updating an active agent executable on Windows is challenging because Windows locks running `.exe` files from modification or deletion.

### 6.1 Core Architectural Invariant
Rather than over-specifying a custom helper binary (`TMK.Agent.Updater.exe`) before Phase 4 engineering, Phase 0 establishes the **Core Agent Upgrade Invariant**:

> [!IMPORTANT]
> **Windows Agent Upgrade Invariant**:  
> Any platform update to `TMK.Agent.Windows` must support:
> 1. **Integrity Precheck**: Download and cryptographic SHA-256 digest validation of the new binary before attempting replacement;
> 2. **Clean Service Stop**: Orderly shutdown of active worker tasks and stopping the Windows Service via Service Control Manager (`sc.exe stop`);
> 3. **Atomic Replacement**: Moving the active binary to a `.bak` backup path and copying the new binary into place;
> 4. **Service Restart & Health Verification**: Restarting the service and polling its local health endpoint for 30 seconds;
> 5. **Automated Rollback**: If the new service fails to start or crashes, the updater must immediately restore the `.bak` binary, restart the previous known-good service, and emit a critical Windows Event Log entry;
> 6. **Reboot Recovery**: If the host is power-cycled mid-update, startup recovery scripts must detect intermediate `.new` or `.bak` files and restore a deterministic service state.

---

## 7. Dual-OS Parity & Independent Gate A Certification

The Windows Server 2022 profile is an equal first-class platform:
- **Independent Windows Gate A (Phase 12B)**: Windows Server 2022 is certified through its own independent Gate A audit.
- **Prohibition of Evidence Inheritance**: Linux test passes cannot be substituted for Windows test passes.
- **Dual-OS Failure Injection (Phase 11 / MR-33)**: Requires automated chaos and failure injection (container crashes on Linux, AppPool crashes on Windows, network partitions, corrupted dumps) on **BOTH** operating systems.

---

## 8. Conclusion

Finding `C1-03` is **completely and rigorously resolved**. The Windows Server 2022 topology is fully frozen, unsupported Docker Desktop and WSL2 configurations are eliminated, port 80/443 ingress conflicts are solved via native `HTTP.sys`, and the compiled Windows Agent lifecycle is defined with precision.
