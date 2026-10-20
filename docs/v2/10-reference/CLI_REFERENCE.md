# Host CLI Flag & Command Reference

> **Document ID:** `V2-INFRA-REF-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative CLI Reference  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [CLI_AND_ORCHESTRATION.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/04-modules/CLI_AND_ORCHESTRATION.md), [OPERATOR_RUNBOOK.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/OPERATOR_RUNBOOK.md)

---

## 1. Syntax & Invocation

- **Linux:** `/opt/vps-infra/infra <command> [options]`
- **Windows:** `pwsh -File C:\vps-infra\infra.ps1 <command> [options]` or `infra.cmd <command>`

---

## 2. Command Reference

### `start`
- **Usage:** `./infra start [service_name]`
- **Description:** Starts all platform services in background detached mode (`docker compose up -d`). If a specific service name is provided, only that service is started.

### `stop`
- **Usage:** `./infra stop [service_name]`
- **Description:** Gracefully stops containers (`docker compose stop`).

### `restart`
- **Usage:** `./infra restart [service_name]`
- **Description:** Restarts specified container or entire platform stack.

### `status`
- **Usage:** `./infra status`
- **Description:** Formats and displays:
  - Container health status (Running / Healthy / Exited).
  - Published and internal port mappings.
  - CPU, RAM, and Disk utilization percentages.

### `logs`
- **Usage:** `./infra logs [service_name] [--tail N] [-f]`
- **Description:** Streams live container logs.
- **Flags:**
  - `--tail N`: Number of preceding lines to display (default: 100).
  - `-f`: Follow log output continuously.

### `backup-db`
- **Usage:** `./infra backup-db [output_path]`
- **Description:** Generates a compressed PostgreSQL database dump using `pg_dump -Fc`.

### `restore-db`
- **Usage:** `./infra restore-db <dump_file_path>`
- **Description:** Restores database dump using `pg_restore --clean`.

### `upgrade`
- **Usage:** `./infra upgrade [--check]`
- **Description:** Checks for or executes rolling container image upgrades.
- **Flags:**
  - `--check`: Queries license server for newer release tags without modifying running containers.

### `license`
- **Usage:** `./infra license <activation_token>`
- **Description:** Submits license token to local license verification client.
