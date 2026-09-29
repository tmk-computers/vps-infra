# PHASE 0.5 SCHEMA AUTHORITY AND ACCEPTANCE CONTRACT (C2-01 RESOLUTION)

**Document ID**: `REMED-P0-CDX-07`  
**Phase**: Phase 0 — Codex Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C2-01`)  
**Status**: COMPLETE ARCHITECTURAL SPECIFICATION  

---

## 1. Context & Problem Statement

The Codex Phase 0 Audit Gate flagged finding `C2-01` as a **Minor Precision & Clarity Defect (C2)**:
1. **Competing Schema Authorities**: In the audited Phase 0 baseline, Phase 0.5 specified both a versioned EF Core migration (`20261001000000_AddMaintenanceModeEntities.cs`) and new raw DDL statements (`ALTER TABLE ADD COLUMN IF NOT EXISTS`) in `DataSeeder.cs`. This created two equal, competing schema evolution mechanisms in direct violation of target architecture principles (§2.7).
2. **Stale Phase Label**: Document `10_MAINTENANCE_MODE_CURRENT_STATE.md` §3 still referred to MR-34 as belonging to Phase 1 rather than Phase 0.5.
3. **Missing Acceptance Specification**: While MR-34 was correctly isolated as an architectural prerequisite, the exact PostgreSQL acceptance test contract (covering existing databases, fresh databases, and idempotency) was not explicitly detailed.

This document establishes the single authoritative schema evolution mechanism, bounds the temporary role of `DataSeeder.cs`, sets the mandatory deprecation milestone, and specifies the complete Phase 0.5 acceptance test contract.

---

## 2. Definitive Schema Evolution Authority

To eliminate schema divergence, the platform establishes a strict single-authority rule:

### 2.1 The Single Authority: Versioned EF Core Migrations
**Versioned EF Core Migrations** are the **SOLE AUTHORITATIVE** schema evolution mechanism for the application database.
- Every schema change must be represented by an immutable C# migration class derived from `Microsoft.EntityFrameworkCore.Migrations.Migration`.
- Migrations are tracked and recorded in the standard EF Core metadata table: `__EFMigrationsHistory`.
- Database schema evolution is executed through the formal migration pipeline:
  ```bash
  dotnet ef database update
  ```
  or via application startup migration runner:
  ```csharp
  await dbContext.Database.MigrateAsync();
  ```

### 2.2 Bounded Temporary Exception for `DataSeeder.cs`
`DataSeeder.cs` has historically contained raw DDL statements (`ALTER TABLE`, `CREATE TABLE IF NOT EXISTS`) alongside data seeding logic. To prevent dual authorities:
1. **Prohibition of New Raw DDL**: Under Phase 0.5, **NO NEW raw DDL statements** may be added to `DataSeeder.cs`. All 13 maintenance-mode columns and table structures must be created exclusively via the versioned EF Core migration.
2. **Strictly Bounded Role**: `DataSeeder.cs` is restricted purely to **Data Population** (inserting default system settings, seed roles, and initial catalog entries) after the schema has been established.
3. **Mandatory Removal Milestone (Phase 2 / MR-13)**: In Phase 2, under Master Remediation item **`MR-13`** (Schema Evolution & Seeder Decoupling), all existing raw DDL statements in `DataSeeder.cs` will be completely deleted. `DataSeeder.cs` will be renamed to `DataPopulator.cs` and will execute only `INSERT` / `UPDATE` queries on pre-existing tables.

---

## 3. Scope of Phase 0.5 (MR-34)

Phase 0.5 is an isolated, single-MR architectural prerequisite:
- **Identifier**: `MR-34`  
- **Title**: *Centralized Maintenance Mode Database Schema & Entity Model Alignment*  
- **Scope**: Align the PostgreSQL database schema with C# entity definitions in `vps-infra-server/devops-manager/api/Infrastructure/Entities/`:
  - `MaintenanceWindow.cs`
  - `ServiceMaintenance.cs`
  - `Product.cs`
  - `ProjectService.cs`
- **Missing Columns to Create**:
  1. `MaintenanceWindows.CreatedAt` (timestamp with time zone, default `NOW()`)
  2. `MaintenanceWindows.CreatedBy` (text, nullable)
  3. `MaintenanceWindows.ScheduledStartTime` (timestamp with time zone, nullable)
  4. `MaintenanceWindows.ScheduledEndTime` (timestamp with time zone, nullable)
  5. `MaintenanceWindows.ActualStartTime` (timestamp with time zone, nullable)
  6. `MaintenanceWindows.ActualEndTime` (timestamp with time zone, nullable)
  7. `MaintenanceWindows.IsActive` (boolean, default `false`)
  8. `ServiceMaintenances.EstimatedDowntimeMinutes` (integer, nullable)
  9. `ServiceMaintenances.CompletedAt` (timestamp with time zone, nullable)
  10. `ServiceMaintenances.ServiceType` (integer, default `0`)
  11. `ServiceMaintenances.RetryCount` (integer, default `0`)
  12. `Products.IsActive` (boolean, default `true`)
  13. `ProjectServices.IsActive` (boolean, default `true`)

---

## 4. Phase 0.5 Acceptance Test Contract

Phase 0.5 implementation (scheduled following baseline approval) must be verified against the following formal acceptance contract prior to declaring entry into Phase 1:

### 4.1 Test Case Matrix

| Test ID | Test Scenario | Baseline State | Execution Action | Expected Outcome | Verification Query |
|---|---|---|---|---|---|
| **P05-TC01** | **Upgrade from Existing Schema** | Pre-MR-34 PostgreSQL database with data in `Products`, `ProjectServices`, and `MaintenanceWindows` tables lacking the 13 columns. | Run `dotnet ef database update`. | Migration `20261001000000_AddMaintenanceModeEntities` applies cleanly. Zero errors. | `SELECT column_name, is_nullable, column_default FROM information_schema.columns WHERE table_name = 'MaintenanceWindows';`<br>All 7 columns verified. |
| **P05-TC02** | **Fresh Database Installation** | Completely empty PostgreSQL database. | Run application startup migration runner. | All migrations apply in sequence from baseline to `20261001000000`. | Schema matches `ApplicationDbContextModelSnapshot.cs` perfectly. |
| **P05-TC03** | **Zero Data Loss Verification** | Existing rows in `Products` and `ProjectServices` prior to migration. | Apply migration. | All pre-existing rows remain intact; existing records receive default values (`IsActive = true`). | `SELECT COUNT(*) FROM "Products" WHERE "IsActive" = true;`<br>Matches pre-migration row count. |
| **P05-TC04** | **Entity Query Regression** | Application starts and executes EF Core queries. | 1. Query `Products.Where(p => p.IsActive)`.<br>2. Query `ProjectServices.Where(s => s.IsActive)`.<br>3. Query `MaintenanceWindows.Where(w => w.IsActive)`. | All queries execute without PostgreSQL error `42703 (undefined_column)`. HTTP 200 returned. | Application logs show zero SQL exceptions during startup entity hydration. |
| **P05-TC05** | **Migration Idempotency** | Migration already applied to database. | Re-run `dotnet ef database update` or restart API container. | Migration runner detects migration is already recorded in `__EFMigrationsHistory`. No DDL is re-executed. Zero errors. | Application logs show: `No pending migrations to apply`. |

---

## 5. Normalization of Phase Labels

All Phase 0 artifacts have been updated to ensure that `MR-34` is consistently and exclusively labeled as **Phase 0.5**:
- `docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md`: Phase column set to `Phase 0.5`.
- `docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md` §3: Corrected from `Phase 1` to `Phase 0.5`.
- `docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md`: Explicit section `Phase 0.5 — Centralized Maintenance Mode Schema Prerequisite`.
- `docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md`: MR-34 completion listed as an explicit prerequisite for Phase 1 entry.
- `docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md`: Summarized under Phase 0.5.

---

## 6. Conclusion

This document resolves finding `C2-01`. It establishes EF Core Migrations as the sole schema authority, bounds `DataSeeder.cs` without competing DDL, mandates its deprecation in Phase 2, defines the exhaustive Phase 0.5 acceptance test contract, and normalizes all phase labels across the baseline.
