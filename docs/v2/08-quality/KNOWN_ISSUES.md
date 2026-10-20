# Infrastructure Known Issues & Defect Register

> **Document ID:** `V2-INFRA-QUAL-002`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Register  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [PILOT_RELEASE_GATES.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/PILOT_RELEASE_GATES.md), [SOURCE_BASELINE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/SOURCE_BASELINE.md)

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
  - **However:** Inside the API image, `DataSeeder.cs:21-28` still calls `await db.Database.MigrateAsync()`, bypassing this environment variable.
  - **Operational Workaround:** Until `vps-infra-server` merges Phase GH-1, operators must verify that the database schema has been manually migrated before launching the API container.

### INFRA-02 — Minimal Docker Base Images Lacking Sudo
- **Severity:** `MEDIUM`
- **Status:** `VERIFIED_FIXED`
- **Component:** `setup.sh` and `infra`
- **Fix Details:** Commit `834f934` checks `[ "$(id -u)" -eq 0 ]` and avoids calling `sudo` when running as root, eliminating installation crashes on Alpine or minimal container runners.

### INFRA-03 — Windows Disposable VM Test Runner Prerequisite
- **Severity:** `MEDIUM`
- **Status:** `OPEN`
- **Component:** `scripts/test-windows-w0.ps1`
- **Observed Behavior:** The Windows preservation test runner requires an active Hyper-V or cloud VM provider configured in environment variables. Running locally on workstations without Hyper-V skips VM execution.
