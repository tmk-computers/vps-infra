# Host CLI & Orchestration Module Specification

> **Document ID:** `V2-INFRA-MOD-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Module Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/HOST_ARCHITECTURE.md), [CLI_REFERENCE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/10-reference/CLI_REFERENCE.md)

---

## 1. CLI Architecture & Entry Points

The platform provides dual-OS host management CLI scripts:
- **Linux:** `/opt/vps-infra/infra` (Bash script).
- **Windows:** `/opt/vps-infra/infra.ps1` (PowerShell 7 script) and `infra.cmd` (batch wrapper).

Both scripts wrap Docker Compose and system-level operations into standardized, memorable administrative verbs.

---

## 2. Core CLI Commands & Implementation

| Command Verb | Bash Syntax | PowerShell Syntax | Action Taken |
|---|---|---|---|
| **`start`** | `./infra start` | `.\infra.ps1 start` | Starts all platform containers via `docker compose up -d`. |
| **`stop`** | `./infra stop` | `.\infra.ps1 stop` | Gracefully terminates all containers via `docker compose stop`. |
| **`restart`** | `./infra restart [service]` | `.\infra.ps1 restart [service]` | Restarts specified service or entire platform. |
| **`status`** | `./infra status` | `.\infra.ps1 status` | Displays container state, CPU/RAM utilization, and port bindings. |
| **`logs`** | `./infra logs [service]` | `.\infra.ps1 logs [service]` | Streams logs from `docker compose logs -f --tail 100`. |
| **`backup-db`**| `./infra backup-db` | `.\infra.ps1 backup-db` | Generates a timestamped `.dump` of the PostgreSQL database. |
| **`restore-db`**| `./infra restore-db <file>` | `.\infra.ps1 restore-db <file>` | Restores a database dump using `pg_restore`. |
| **`upgrade`** | `./infra upgrade [--check]` | `.\infra.ps1 upgrade [--check]` | Queries license server for releases and pulls updated images. |
| **`license`** | `./infra license <key>` | `.\infra.ps1 license <key>` | Activates platform license token. |

---

## 3. Automated Error Handling & Root Sudo Invariants

In commit `834f934` (`fix(setup): avoid sudo invocation when running as root`):
- Both `setup.sh` and `infra` were updated to inspect effective user ID (`id -u`).
- If running as `root` (UID 0), the scripts bypass `sudo` invocations, preventing command execution failures on minimal Docker base images or VPS distributions that lack `sudo` installed.
