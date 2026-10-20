# VPS Infrastructure — Start Here

> **Document ID:** `V2-INFRA-START-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Orientation Guide  
> **Target Audience:** DevOps Engineers, System Administrators & Operators  
> **Related Documents:** [INDEX.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/INDEX.md), [06-operations/OPERATOR_RUNBOOK.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/OPERATOR_RUNBOOK.md)

---

## 1. What is `vps-infra`?

The **`vps-infra`** repository contains everything required to turn a clean, unconfigured Linux virtual server into a fully managed, secure hosting platform.

It provides:
- **`setup.sh` / `setup.ps1`:** Automated host bootstrapping scripts that install Docker, configure firewall rules, create system directories, and launch the platform.
- **`docker-compose.yml`:** The primary multi-container orchestration definition running the control plane API, web dashboard, CI server, agent runtime, PostgreSQL, and Redis.
- **`infra` CLI Tool:** A unified host management utility for starting, stopping, restarting, inspecting, backing up, and upgrading services.
- **`templates/`:** Pre-built application stack definitions allowing tenants to deploy customer web apps in Docker with automated Nginx reverse proxying.

---

## 2. Directory Hierarchy on Target VPS

When installed on a target server, `vps-infra` establishes the following standardized directory structure under `/opt/vps-infra/`:

```
/opt/vps-infra/
├── docker-compose.yml       # Production container orchestration stack
├── .env                     # Production environment configuration & secrets
├── infra                    # Executable host CLI script
├── backups/                 # Pre-deployment database snapshots (.dump)
├── apps/                    # Customer application deployment workspaces
├── data/                    # Persistent volume mounts
│   ├── postgres/            # PostgreSQL 16 relational data
│   ├── redis/               # Redis in-memory cache data
│   └── caddy_data/          # Automated SSL/TLS certificates
└── logs/                    # Host and container operational logs
```

---

## 3. Quick Start: Bootstrapping a Fresh VPS

To install the platform on a fresh Ubuntu 22.04 or 24.04 server:

```bash
# Step 1: Connect to server as root or sudo user
ssh root@your-vps-ip

# Step 2: Clone this repository to /opt/vps-infra
git clone git@github.com:tmk-computers/vps-infra.git /opt/vps-infra
cd /opt/vps-infra

# Step 3: Run the automated setup script
chmod +x setup.sh infra
./setup.sh --install

# Step 4: Verify platform status
./infra status
```

For complete operational procedures, consult the [Operator Runbook](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/OPERATOR_RUNBOOK.md).
