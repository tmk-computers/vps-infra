# VPS Infrastructure — Start Here

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server d7e8df99cb2b099eb8b6290e524af4d01a6c4a4d; infra b84f9d5de8da991cb603d696b94f829f5361e64a. **Last verified:**2026-10-21. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-START-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Target Audience:** DevOps Engineers, System Administrators & Operators  
> **Related Documents:** [INDEX.md](./INDEX.md), [06-operations/OPERATOR_RUNBOOK.md](./06-operations/OPERATOR_RUNBOOK.md)

> **Architecture authority:** [Customer-hosted platform and current packaging limits](../../../vps-infra-server/docs/v2/02-architecture/SELF_HOSTED_PLATFORM.md). Repository ownership is not hosting location; TMK licensing remains separately central.

---

## 1. What is `vps-infra`?

The **`vps-infra`** repository contains host setup, Compose and operator scripts for the hosting platform. Actual security and release qualification depend on the specific environment and independent engineering gates.

It provides:
- **`setup.sh` / `setup.ps1`:** Source installer entry points; Linux scripts/setup-vps.sh provisions prerequisites, while setup.sh requires Docker/Compose and configures support/root services. PowerShell source does not qualify native Windows installation.
- **`docker-compose.yml` & Platform Compose Stacks:** Multi-container orchestration running `devops-api-prod`, `devops-web-prod`, `ci-api-prod`, `ci-web-prod` on `traefik_net`, alongside Traefik edge reverse proxying and `shared_postgres`.
- **`infra` CLI Tool:** Host management dispatch supporting: `up`, `down`, `restart`, `status` / `ps`, `logs`, `backup`, and `help`.
- **`templates/`:** Pre-built application stack definitions allowing tenants to deploy customer web apps in Docker with Traefik edge routing labels.

---

## 2. Directory Hierarchy on Target VPS

When installed on a target server, `vps-infra` resides under `/var/www/vps-infra/`:

```
/var/www/vps-infra/
├── docker-compose.yml       # Production application services stack
├── .env                     # Production environment configuration & secrets
├── infra                    # Executable host CLI script (up/down/restart/status/logs/backup)
├── setup.sh                 # Host installation & bootstrapping script
├── platform/
│   ├── network/traefik/     # Traefik compose, dynamic routing & acme.json
│   └── database/postgres/   # Shared PostgreSQL 16 compose & init scripts
├── docker/volumes/
│   └── db/postgres/
│       ├── data/            # PostgreSQL relational database cluster files
│       └── backups/         # Physical plain SQL backup dumps (devops_prod_*.sql)
├── templates/               # Application stack template compose definitions
└── scripts/                 # Standalone maintenance utilities (upgrade-client.sh)
```

---

## 3. Quick Start: Bootstrapping a Fresh VPS

To install the platform on a fresh Ubuntu 22.04 or 24.04 server:

```bash
# Step 1: Connect to server as root or sudo user
ssh root@your-vps-ip

# Step 2: Clone this repository to /var/www/vps-infra
git clone git@github.com:tmk-computers/vps-infra.git /var/www/vps-infra
cd /var/www/vps-infra

# Step 3: Run the automated setup script
chmod +x setup.sh infra
./setup.sh

# Step 4: Verify platform status
./infra status
```

For complete operational procedures, consult the [Operator Runbook](06-operations/OPERATOR_RUNBOOK.md).
