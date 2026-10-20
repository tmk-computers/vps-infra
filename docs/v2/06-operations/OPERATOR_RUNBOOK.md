# Infrastructure Operator Runbook & Maintenance

> **Document ID:** `V2-INFRA-OPS-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Operator Runbook  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md), [DISASTER_RECOVERY.md](./DISASTER_RECOVERY.md)

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
# Stream API logs via CLI
./infra logs devops-api-prod

# Stream Traefik Ingress logs
./infra logs traefik_global

# Stream CI Server logs
./infra logs ci-api-prod
```

### 1.3 Restarting Services
```bash
# Restart an individual container (without restarting the entire stack)
docker restart devops-api-prod

# Gracefully restart the entire platform stack (executes down, then up)
./infra restart
```

---

## 2. Platform Upgrade Procedure

To upgrade a running VPS to a new platform release:

```bash
# Step 1: Query release updates without mutating containers
bash scripts/upgrade-client.sh --check

# Step 2: Create a safety database snapshot before upgrading
./infra backup

# Step 3: Pull updated Docker images and execute client upgrade
bash scripts/upgrade-client.sh

# Step 4: Verify health status after upgrade
./infra status
```
