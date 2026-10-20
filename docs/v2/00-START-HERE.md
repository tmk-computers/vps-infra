# VPS Infrastructure — Start Here

> **Document ID:** `V2-INFRA-START-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Orientation Guide  
> **Target Audience:** DevOps Engineers, System Administrators & Operators  
> **Related Documents:** [INDEX.md](./INDEX.md), [06-operations/OPERATOR_RUNBOOK.md](./06-operations/OPERATOR_RUNBOOK.md)

---

## 1. What is `vps-infra`?

The **`vps-infra`** repository contains everything required to turn a clean, unconfigured Linux virtual server into a fully managed, secure hosting platform.

It provides:
- **`setup.sh` / `setup.ps1`:** Host bootstrapping scripts that install Docker, configure firewall rules, create system directories, and launch the platform.
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
