# Host CLI Flag & Command Reference

> **Document ID:** `V2-INFRA-REF-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative CLI Reference  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [CLI_AND_ORCHESTRATION.md](../04-modules/CLI_AND_ORCHESTRATION.md), [OPERATOR_RUNBOOK.md](../06-operations/OPERATOR_RUNBOOK.md)

---

## 1. Syntax & Invocation

- **Linux:** `/var/www/vps-infra/infra <command> [options]`
- **Windows:** `pwsh -File .\infra.ps1 <command> [options]`

---

## 2. Command Reference

### `up` / `up --vps`
- **Usage:** `./infra up` or `./infra up --vps`
- **Description:** Deploys and starts all core platform services by executing `setup.sh` (or `setup.ps1` on Windows).

### `down`
- **Usage:** `./infra down`
- **Description:** Gracefully stops and tears down platform containers across `docker-compose.yml`, `docker/registry/docker-compose.yml`, `platform/database/postgres/docker-compose.yml`, and `platform/network/traefik/docker-compose.yml`.

### `restart`
- **Usage:** `./infra restart`
- **Description:** Restarts the ENTIRE platform by sequentially executing `infra down` followed by `infra up`.
- **Warning:** This command takes down and restarts all services across the platform stack. It does not accept an isolated single service name. To restart an individual container, use `docker restart <container_name>`.

### `status` / `ps`
- **Usage:** `./infra status` or `./infra ps`
- **Description:** Formats and displays the live container health table via `docker ps`, filtered for `NAMES|devops|ci-|shared_|registry|traefik`.

### `logs`
- **Usage:** `./infra logs <service_name>`
- **Description:** Tails live logs for the specified container with a trailing 100-line buffer (`docker logs -f --tail=100 <service_name>`).
- **Examples:**
  - `./infra logs devops-api-prod`
  - `./infra logs ci-api-prod`
  - `./infra logs traefik_global`
  - `./infra logs shared_postgres`

### `backup`
- **Usage:** `./infra backup`
- **Description:** Triggers an immediate plain SQL dump of the PostgreSQL database (`devops_prod` inside `shared_postgres`).
- **Output:** Stored at `/var/www/vps-infra/docker/volumes/db/postgres/backups/devops_prod_<timestamp>.sql`.

### `help` / `-h` / `--help`
- **Usage:** `./infra help`
- **Description:** Displays the CLI usage help menu.

---

## 3. Standalone Operational Utilities

### Upgrade Client (`scripts/upgrade-client.sh`)
- **Usage:** `bash scripts/upgrade-client.sh [--check]`
- **Description:** Queries repository tags and release distributions for client updates.
- **Flags:**
  - `--check`: Queries for newer release tags without modifying local files or running containers.

### Database Restoration
- **Usage:** `docker exec -i shared_postgres psql -U postgres devops_prod < <backup.sql>`
- **Description:** Restores a plain SQL backup dump into the target database. To test in isolation before restoring over active data, create a temporary database via `docker exec shared_postgres createdb -U postgres devops_restore_test`.
