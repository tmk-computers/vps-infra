# Host CLI Flag & Command Reference

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server c458c831711ba2e82a382719f76c98551d7d5a70; infra44a5d6a32bf59f50e7c13b663dbd22bac31eb53d. **Last verified:**2026-10-20. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-REF-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
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
- **Description:** Bash up invokes setup.sh and ignores trailing arguments; PowerShell up forwards arguments to setup.ps1. Provisioning mutates the host and may hit GH01.

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
- **Usage:** `bash scripts/upgrade-client.sh [--check|-c]`
- **Description:** The --check/-c path queries the license version-check API; the full upgrade path fetches origin main, resets tracked files and invokes setup.sh. These are distinct modes; a check result does not qualify a deployment.
- **Flags:**
  - `--check` / `-c`: Reads installed VERSION (fallback v2.1), calls ${LICENSE_SERVER_URL:-https://license.tmkcomputers.in}/api/v1/license/version-check, captures/reads/removes a temporary curl-error file, then exits before full-upgrade Git fetch/reset/setup. It does not query remote Git tags; it is not completely filesystem-free. Full upgrade can overwrite tracked changes and recreate services; VERSION success is not independent health, rollback or schema proof.

### Database restoration

There is no root restore command. Backup is plain SQL. Restore only to an independently verified disposable target with ON_ERROR_STOP, verified filename/checksum and schema compatibility; never default to active devops_prod. See [recovery](../06-operations/DISASTER_RECOVERY.md).
