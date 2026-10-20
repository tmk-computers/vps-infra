# Infrastructure Known Issues & Defect Register

> **Document ID:** `V2-INFRA-QUAL-002`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Register  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [PILOT_RELEASE_GATES.md](./PILOT_RELEASE_GATES.md), [SOURCE_BASELINE.md](./SOURCE_BASELINE.md)

---

## 1. Executive Summary

This register tracks infrastructure-specific configuration quirks, compose file dependencies, and open items affecting host deployments.

---

## 2. Infrastructure Known Issues

### INFRA-01 — Database AutoMigrateOnStartup Bypass Dependency
- **Severity:** `HIGH`
- **Status:** `OPEN` (Waiting for Server Fix GH01)
- **Component:** `docker-compose.yml` (`devops-api-prod`)
- **Observed Behavior:**
  - Commit `6dedfa3` updated `docker-compose.yml` to set `Database__AutoMigrateOnStartup=false`.
  - **Operational Limitation:** Until `vps-infra-server` implements and verifies Phase GH-1 schema reconciliation, launching the API container against a fresh or un-reconciled database will crash with SQLSTATE 23502. Production release remains on CONDITIONAL HOLD pending this fix. Do not attempt out-of-band manual SQL schema modifications.

### INFRA-02 — Minimal Docker Base Images Lacking Sudo
- **Severity:** `MEDIUM`
- **Status:** `VERIFIED_FIXED`
- **Component:** `setup.sh` and `infra`
- **Fix Details:** Commit `834f934` checks `[ "$(id -u)" -eq 0 ]` and avoids calling `sudo` when running as root, eliminating installation crashes on Alpine or minimal container runners.

### INFRA-03 — Windows Server Pre-Qualification & Preservation Harness Status
- **Severity:** `MEDIUM`
- **Status:** `OPEN` (Pre-Qualification Status)
- **Component:** `scripts/windows/Invoke-W0VmPreservationCheck.ps1`
- **Observed Behavior:** The Windows preservation test harness requires running inside an explicitly named disposable Windows Server 2025 VM (Build >= 26100) with `-DisposableVm` and `-ExpectedVmName`. It performs read-only baseline capture and comparison of existing IIS configurations; it does not provision VMs, mutate IIS websites, or exercise installer/worker rollback flows. The overall Phase W-0 ADR (`docs/PHASE_W0_ARCHITECTURE_DECISION_RECORD.md`) remains `PROPOSED & RE-GATED FOR STAKEHOLDER SIGN-OFF` (checked 2026-10-06), and Windows Server hosting is strictly unverified for production.
