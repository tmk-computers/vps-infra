# Disaster Recovery, Backups & Rollback Runbook

> **Document ID:** `V2-INFRA-OPS-002`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Disaster Recovery Standard  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [OPERATOR_RUNBOOK.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/OPERATOR_RUNBOOK.md), [PILOT_RELEASE_GATES.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/PILOT_RELEASE_GATES.md)

---

## 1. Database Backup & Restore Runbook

### 1.1 Generating a Backup
The host CLI creates a compressed PostgreSQL custom format (`.dump`) file under `/opt/vps-infra/backups/`:
```bash
./infra backup-db
```
The output file is named `db_YYYYMMDD_HHMMSS.dump`.

### 1.2 Restoring from a Backup
In the event of database corruption or a failed deployment:
```bash
# Restore specific backup file
./infra restore-db /opt/vps-infra/backups/db_20261019_120000.dump
```
*(Verified against live drill evidence in `docs/audits/backup-restore-drill-evidence.json`).*

---

## 2. In-Flight Request Handling & Rollback Drills

During automated application rollbacks, the CI Server and Nginx reverse proxy preserve in-flight requests:
- **Rolling Swap:** The old container is not stopped until the new container passes health checks.
- **Immediate Revert:** If health checks fail, Nginx routes are immediately redirected back to the previous container.
- **Drill Evidence:** `docs/audits/rollback-inflight-evidence.json` confirms zero HTTP 502/504 errors during simulated mid-flight rollbacks.
