# 05 SUPPORTED OPERATING SYSTEM CERTIFICATION MATRIX

**Document ID**: `REMED-P0-05`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Status**: Authoritative OS Support Matrix Frozen (Codex C1-03 & C2-04 Remediation Applied)  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Findings `C1-03`, `C2-04`)  

---

## 1. Dual-OS Non-Negotiable Governance Policy

> [!IMPORTANT]
> ### 🚨 DUAL-OS NON-NEGOTIABLE MANDATE
> 1. **Equal First-Class Target Platforms**: Linux (Ubuntu 24.04 LTS) and Windows Server (Windows Server 2022) are **equal first-class target platforms** for this remediation program. Both operating systems must be analyzed independently, remediated rigorously, and held to strict outcome parity.
> 2. **No False Equivalences**: Linux success MUST NOT be used as evidence of Windows success, and Windows deficiencies MUST NOT be deferred merely to simplify a Linux-only launch.
> 3. **No Conversion to Linux-Only MVP**: This remediation program must NOT be converted into a Linux-only MVP or pilot roadmap. While an operational Linux pilot may commence earlier if Linux reaches its independent Gate A first, Windows remediation and certification remain an integral, active part of the same active program and must proceed concurrently to **Windows Gate A (Phase 12B)** and the final **Dual-OS Commercial Gate B (Phase 15)**.
> 4. **Independent Certification Gates**: Linux Gate A and Windows Gate A are completely independent evaluation gates. Neither platform inherits certification from the other.

---

## 2. Operating System Lifecycle Classification Tiers

To eliminate documentation drift and false product readiness claims, all evaluated operating systems are classified into five explicit lifecycle tiers:
1. **CLAIMED**: Mentioned in README, marketing collateral, or pre-sales documentation.
2. **IMPLEMENTED**: Code, manifests, or bootstrap scripts exist in the repository for this OS.
3. **TESTED**: Automated integration or manual validation has been executed in CI or lab.
4. **CERTIFIED FOR PILOT (Gate A)**: Formally validated under single-VM failure injection for controlled pilot customers.
5. **CERTIFIED FOR COMMERCIAL (Gate B)**: Multi-tenant, hardened, enterprise disaster recovery certified.

---

## 3. Explicit Operating System Matrix

| Operating System | Distribution / Edition | Architecture | Claimed in Docs? | Implemented in Scripts? | Tested in Lab? | Gate A Certified (Pilot)? | Gate B Certified (Commercial)? | Production Role / Target Workload | Technical Constraints & Notes |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **Ubuntu Linux** | **24.04 LTS (Noble Numbat)** | `x86_64` | **YES** | **YES** (`setup.sh`) | Target (Static Verified; Live Run in Phase 12A) | **PRIMARY TARGET (Linux Gate A)** | **PENDING PHASE 15** | Core Linux Host (Docker, Traefik, PostgreSQL, CI Runner) | Primary reference platform for Linux Gate A certification. |
| **Ubuntu Linux** | 22.04 LTS (Jammy Jellyfish) | `x86_64` | **YES** | **YES** (`setup.sh`) | Target (Unverified; Live Run in Phase 12A) | SECONDARY TARGET | PENDING PHASE 15 | Core Linux Host | Backward-compatible tier; requires Docker Engine 24+. |
| **Debian Linux** | 12 (Bookworm) | `x86_64` | **YES** | **YES** (`setup.sh`) | Unverified | DEFERRED | PENDING EVAL | Linux Host | Debian packaging matches Ubuntu; requires verification. |
| **Windows Server** | **2022 Datacenter / Standard**| `x86_64` | **YES** | **PARTIAL** (`setup.ps1`)| Target (Static Verified; Live Run in Phase 12B) | **PRIMARY TARGET (Windows Gate A)** | **PENDING PHASE 15** | Windows Native Host (IIS 10, .NET 8, TMK.Agent.Windows) | Primary reference platform for Windows Gate A certification. Equal first-class priority. |
| **Windows Server** | 2019 Datacenter / Standard| `x86_64` | **YES** | **PARTIAL** (`setup.ps1`)| Unverified | SECONDARY TARGET | PENDING PHASE 15 | Windows Native Host | SCM service support; requires PowerShell 5.1+. |
| **Windows Server** | 2025 Datacenter | `x86_64` | **YES** | **PARTIAL** (`setup.ps1`)| Unverified | DEFERRED | PENDING EVAL | Windows Native Host | Experimental tier; pending lab hardware availability. |
| **Windows Desktop**| Windows 10 / 11 Pro / Ent | `x86_64` | **YES** (Dev) | **PARTIAL** (`setup.ps1`)| Unverified | **NOT SUPPORTED** | **NOT SUPPORTED** | Developer Workstations Only | Desktop editions lack SCM production IIS stability guarantees. |
| **RHEL / Rocky Linux**| 9.x Enterprise | `x86_64` | NO | NO | NO | **NOT SUPPORTED** | DEFERRED | Future Linux Enterprise | Deferred until customer demand warrants SELinux qualification. |
| **macOS** | Sonoma / Sequoia (Apple Silicon)| `ARM64` | NO | NO | NO | **NOT SUPPORTED** | **NOT SUPPORTED** | Developer Laptop Only | Not targeted for production control plane hosting. |

---

## 4. Independent Gate A Pilot Scope Boundaries

### 4.1 Linux Gate A Pilot Scope (Ubuntu 24.04 LTS)
- **Target OS**: Ubuntu 24.04 LTS (`x86_64`)
- **Prerequisites**: Minimum 4 vCPUs, 8 GB RAM, 50 GB NVMe/SSD, Docker Engine 26+, Docker Compose v2.27+.
- **Scope Contract**:
  - Containerized deployment of Web, API, and Worker applications via Docker Compose.
  - PostgreSQL 16 containerized database with automated local and verified offsite backup (MR-14).
  - Traefik reverse proxy with Let's Encrypt automated TLS.
  - Outbound email alerting for critical container failures (MR-18).
  - Least-privilege PostgreSQL roles (MR-05) and loopback network binding (MR-06).

### 4.2 Windows Gate A Pilot Scope (Windows Server 2022)
- **Target OS**: Windows Server 2022 Datacenter / Standard (`x86_64`)
- **Prerequisites**: Minimum 4 vCPUs, 16 GB RAM, 100 GB NVMe/SSD, IIS 10.0, ASP.NET Core Hosting Bundle 8.0, .NET 8 Runtime.
- **Frozen Windows Gate-A Topology**:
  - **Workload Host**: Native Windows IIS 10 hosting ASP.NET Core applications via ANCM.
  - **Agent Service**: Compiled `.NET Worker` Windows Service (`TMK.Agent.Windows`) running under a **dedicated least-privilege Windows service identity** (e.g. `NT SERVICE\TMKAgent`) with explicitly granted required rights: IIS administration / AppPool control, deployment filesystem rights (`C:\inetpub\staging\` and `C:\inetpub\wwwroot\`), and SCM inspection (MR-22, MR-24); explicitly restricted from unrelated OS directories and LocalSystem privileges.
  - **Control Plane Connection**: DevOps Manager on Linux connects to `TMK.Agent.Windows` via mutual TLS (mTLS) over HTTPS on dedicated port 5055 (MR-23), paired with scoped short-lived operation authorization tokens.
  - **Database Endpoint**: Workloads connect to a **Remote PostgreSQL 16 Endpoint** (dedicated Linux VM or managed instance) over authenticated TLS port 5432 (`SSL Mode=VerifyFull` or `SSL Mode=Require;Trust Server Certificate=false` with validated CA/pinning; unauthenticated server certificate trust or validation bypass is strictly prohibited). WSL2 and Docker Desktop on Windows Server are explicitly uncertified and prohibited for Gate A.
  - **Ingress & Port Architecture**: Traefik is **NOT deployed** on the Windows host. Native Windows `HTTP.sys` driver and IIS 10 own ports 80 and 443 with SNI SSL bindings, completely eliminating port conflicts and `setup.ps1` W3SVC stoppage (MR-27).
  - **Filesystem Security**: Sandboxed deployment filesystem (`C:\inetpub\staging` and `C:\inetpub\wwwroot\apps\{tenant}\`) with NTFS ACL enforcement, normalized segment-boundary containment, and path traversal validation (MR-24).
  - **Telemetry**: Per-AppPool PID telemetry mapping, eliminating the all-w3wp summation defect (MR-25).
  - **Agent Upgrades**: Safe binary replacement with automated rollback on service failure, post-restart functional health verification (`/health`), and deterministic recovery across interrupted updates or host reboot events.

### 4.3 Staggered Operational Execution Policy
- If Linux remediation reaches its independent Gate A criteria before Windows Server reaches Windows Gate A, an operational pilot for Linux may commence under Phase 13A.
- **Strict Constraint**: Under no circumstances does a Linux pilot pause, cancel, or defer Windows remediation. Phase 4 (`TMK.Agent.Windows`), Phase 10 (Windows upgrade engine), Phase 11 (Dual-OS failure injection), and Phase 12B (Windows Gate A) proceed actively within the same program to ensure both platforms achieve full commercial certification at Phase 15.
