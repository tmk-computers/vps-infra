# Host CLI & Orchestration Module Specification

> **Document ID:** `V2-INFRA-MOD-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Module Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md), [CLI_REFERENCE.md](../10-reference/CLI_REFERENCE.md)

---

## 1. CLI Architecture & Entry Points

The platform provides dual-OS host management CLI scripts:
- **Linux:** `/var/www/vps-infra/infra` (Bash script, `BASE_DIR="/var/www/vps-infra"`).
- **Windows:** `.\infra.ps1` (PowerShell 5.1+ / 7+ script).

Both scripts wrap Docker Compose and platform maintenance into standardized administrative commands.

---

## 2. Core CLI Commands & Implementation

| Command Verb | Bash Syntax | PowerShell Syntax | Action Taken |
|---|---|---|---|
| **`up`** | `./infra up` / `./infra up --vps` | `.\infra.ps1 up` | Deploys and starts all core platform services via `setup.sh` / `setup.ps1`. |
| **`down`** | `./infra down` | `.\infra.ps1 down` | Stops all platform containers across core, registry, postgres, and traefik compose files. |
| **`restart`** | `./infra restart` | `.\infra.ps1 restart` | Restarts the ENTIRE platform by executing `down` followed by `up`. *(Note: Does not accept an isolated service argument).* |
| **`status` / `ps`** | `./infra status` / `./infra ps` | `.\infra.ps1 status` / `ps` | Displays live container health, status, and ports for devops, ci, shared, registry, and traefik containers. |
| **`logs`** | `./infra logs <service>` | `.\infra.ps1 logs <service>` | Streams live container logs with 100-line trailing buffer (`docker logs -f --tail=100 <service>`). |
| **`backup`** | `./infra backup` | `.\infra.ps1 backup` | Triggers immediate plain SQL database dump of `devops_prod` from `shared_postgres` into `docker/volumes/db/postgres/backups/devops_prod_<timestamp>.sql`. |
| **`help`** | `./infra help` | `.\infra.ps1 help` | Displays the help menu with supported verbs. |

### Standalone Operational Scripts
- **Client Upgrades:** Handled by `scripts/upgrade-client.sh` (supports `--check` to query release updates without mutating containers; uses python3/curl/jq fallbacks).
- **Database Restoration:** Handled via manual Docker execution into disposable or target database: `docker exec -i shared_postgres psql -U postgres devops_prod < <backup.sql>`.

---

## 3. Automated Error Handling & Root Sudo Invariants

In commit `834f934` (`fix(setup): avoid sudo invocation when running as root`):
- Both `setup.sh` and `infra` were updated to inspect effective user ID (`id -u`).
- If running as `root` (UID 0), the scripts bypass `sudo` invocations, preventing command execution failures on minimal Docker base images or VPS distributions that lack `sudo` installed.
