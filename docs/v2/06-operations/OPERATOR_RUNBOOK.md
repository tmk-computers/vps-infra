# Infrastructure Operator Runbook & Maintenance

> **Document ID:** `V2-INFRA-OPS-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Operator Runbook  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/HOST_ARCHITECTURE.md), [DISASTER_RECOVERY.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/DISASTER_RECOVERY.md)

---

## 1. Routine Operational Tasks

### 1.1 Checking Platform Health
```bash
# View complete status of all running containers
./infra status

# Inspect real-time host resource metrics (CPU, RAM, Disk)
docker stats --no-stream
```

### 1.2 Inspecting Live Logs
```bash
# Stream API logs
./infra logs devops-api-prod

# Stream Reverse Proxy logs
docker logs -f --tail 100 caddy-prod
```

### 1.3 Restarting Services
```bash
# Restart a single problematic container
./infra restart devops-api-prod

# Gracefully restart the entire platform stack
./infra restart
```

---

## 2. Platform Upgrade Procedure

To upgrade a running VPS to a new platform release:

```bash
# Step 1: Query license server for authoritative release updates
./infra upgrade --check

# Step 2: Create a safety database snapshot before upgrading
./infra backup-db

# Step 3: Pull updated Docker images and restart containers
./infra upgrade

# Step 4: Verify health status after upgrade
./infra status
```
