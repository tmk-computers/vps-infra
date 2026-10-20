# Disaster Recovery, Backups & Rollback Runbook

> **Document ID:** `V2-INFRA-OPS-002`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Disaster Recovery Standard  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [OPERATOR_RUNBOOK.md](./OPERATOR_RUNBOOK.md), [PILOT_RELEASE_GATES.md](../08-quality/PILOT_RELEASE_GATES.md)

---

## 1. Database Backup & Restore Runbook

### 1.1 Generating a Backup
The host CLI creates a plain SQL database dump under `/var/www/vps-infra/docker/volumes/db/postgres/backups/`:
```bash
./infra backup
```
The output file is named `devops_prod_YYYYMMDD_HHMMSS.sql`.

### 1.2 Restoring from a Backup
To restore a plain SQL database dump into PostgreSQL:
```bash
# Restore specific backup file into target database
docker exec -i shared_postgres psql -U postgres devops_prod < /var/www/vps-infra/docker/volumes/db/postgres/backups/devops_prod_YYYYMMDD_HHMMSS.sql
```
*(Verified against staging drill evidence in `docs/audits/backup-restore-drill-evidence.json`).*

---

## 2. In-Flight Request Handling & Rollback Drills

During automated application rollbacks:
- **Health Gate Check:** The CI Server monitors container health probes before switching traffic routing.
- **Rollback Invariant:** If health checks fail, the container image is reverted to the prior verified release digest.
- **Historical Drill Evidence:** Staging audit evidence in `docs/audits/rollback-inflight-evidence.json` documents a specific rollback drill executed on 2026-10-19 on an OMR worker container (`omr-worker:qa`) with 5 in-flight sheets across two genuinely distinct image digests. Zero data loss occurred during the 15.5-second recovery window.
- **Production Scope:** This drill proves worker queue resilience in a staging test; it does not certify zero HTTP 502/504 errors under high-concurrency production web traffic without load balancer connection draining.
