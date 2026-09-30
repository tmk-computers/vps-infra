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

### 2.2 Neutralization of Competing DDL in `DataSeeder.cs`
`DataSeeder.cs` has historically contained raw DDL statements (`ALTER TABLE`, `CREATE TABLE IF NOT EXISTS`, lines 46–168) alongside data seeding logic, catching migration errors and acting as a competing schema authority.
To establish EF Core migrations as the sole authority:
1. **Mandatory Neutralization Before Phase 0.5 Acceptance**: Prior to declaring Phase 0.5 complete, all schema-changing raw DDL statements in `DataSeeder.cs` must be disabled or removed.
2. **Sole Migration Authority**: All maintenance-mode columns and structural schema adjustments are created exclusively through versioned EF Core migrations (`20261001000000_AddMaintenanceModeFields.cs`) and tracked in `__EFMigrationsHistory` and `ApplicationDbContextModelSnapshot.cs`.
3. **Strictly Bounded Role**: `DataSeeder.cs` operates strictly as a data populator (inserting initial system records, seed roles, and system settings) only on pre-existing, migration-managed tables.

---

## 3. Authoritative Source-Derived Schema Inventory (MR-34)

Phase 0.5 is an isolated, single-MR architectural prerequisite:
- **Identifier**: `MR-34`  
- **Title**: *Centralized Maintenance Mode Database Schema & Entity Model Alignment*  
- **Scope**: Align the PostgreSQL database schema with C# entity definitions in `vps-infra-server/devops-manager/api/Data/Entities/`:
  - `Product.cs`
  - `ProjectService.cs`
- **Total Properties**: Exactly **13 properties across 2 entities** (8 on `Product`, 5 on `ProjectService`):

### 3.1 Entity: `Product` (8 Properties)

| Property Name | Database Column | Data Type | Nullable | Default Value | Notes |
|---|---|---|---|---|---|
| `IsMaintenance` | `IsMaintenance` | `boolean` | `false` | `false` | Global product maintenance toggle |
| `MaintenanceMessage` | `MaintenanceMessage` | `text` | `true` | `'All systems operational.'` | Display banner message |
| `MaintenanceVersion` | `MaintenanceVersion` | `text` | `true` | `'1.0.0'` | Platform release identifier |
| `MinSupportedVersion` | `MinSupportedVersion` | `text` | `true` | `'1.0.0'` | Client version gate |
| `ShowMaintenanceForMobile` | `ShowMaintenanceForMobile` | `boolean` | `false` | `true` | Mobile client banner visibility |
| `ShowMaintenanceForWeb` | `ShowMaintenanceForWeb` | `boolean` | `false` | `true` | Web client banner visibility |
| `MaintenanceStartedAt` | `MaintenanceStartedAt` | `timestamp with time zone` | `true` | `null` | Maintenance start timestamp |
| `MaintenanceEstimatedEndAt` | `MaintenanceEstimatedEndAt` | `timestamp with time zone` | `true` | `null` | Estimated completion timestamp |

### 3.2 Entity: `ProjectService` (5 Properties)

| Property Name | Database Column | Data Type | Nullable | Default Value | Notes |
|---|---|---|---|---|---|
| `IsMaintenanceOverride` | `IsMaintenanceOverride` | `boolean` | `false` | `false` | Service-specific override toggle |
| `IsMaintenance` | `IsMaintenance` | `boolean` | `true` | `null` | Per-service maintenance status |
| `MaintenanceMessage` | `MaintenanceMessage` | `text` | `true` | `null` | Service-specific override message |
| `ShowMaintenanceForMobile` | `ShowMaintenanceForMobile` | `boolean` | `false` | `true` | Mobile banner override |
| `ShowMaintenanceForWeb` | `ShowMaintenanceForWeb` | `boolean` | `false` | `true` | Web banner override |

*(Note: `IsActive` already exists on `BaseEntity` inherited by both entities and is not a new maintenance property).*

---

## 4. Phase 0.5 Acceptance Test Contract

Phase 0.5 implementation must be verified against the following formal acceptance contract prior to declaring entry into Phase 1:

### 4.1 Test Case Matrix

| Test ID | Test Scenario | Baseline State | Execution Action | Expected Outcome | Verification Query |
|---|---|---|---|---|---|
| **P05-TC01** | **Upgrade from Existing Schema** | Pre-MR-34 PostgreSQL database with data in `Products` and `ProjectServices` tables lacking the 13 columns. | Run `dotnet ef database update`. | Migration `20261001000000_AddMaintenanceModeFields` applies cleanly. Zero errors. | `SELECT column_name, is_nullable, column_default FROM information_schema.columns WHERE table_name = 'Products' AND column_name LIKE 'Maintenance%';`<br>All columns present with exact types and defaults. |
| **P05-TC02** | **Fresh Database Installation** | Completely empty PostgreSQL database. | Run application startup migration runner. | All migrations apply in sequence from baseline to `20261001000000`. | Schema matches `ApplicationDbContextModelSnapshot.cs` perfectly. Zero competing raw DDL executed. |
| **P05-TC03** | **Zero Data Loss Verification** | Existing active and inactive rows in `Products` and `ProjectServices` prior to migration. | Apply migration. | All pre-existing rows remain intact; existing records receive configured defaults. | `SELECT COUNT(*) FROM "Products";`<br>`SELECT COUNT(*) FROM "ProjectServices";`<br>Row counts match pre-migration counts exactly. |
| **P05-TC04** | **Entity Query Regression** | Application starts and executes EF Core queries. | 1. Query `Products.Where(p => p.IsMaintenance)`.<br>2. Query `ProjectServices.Where(s => s.IsMaintenanceOverride)`. | All queries execute without PostgreSQL error `42703 (undefined_column)`. HTTP 200 returned. | Application logs show zero SQL exceptions during startup entity hydration. |
| **P05-TC05** | **Repeat Startup & Idempotency** | Migration already applied to database. | Restart API service or re-run `dotnet ef database update`. | Migration runner detects migration in `__EFMigrationsHistory`. No DDL is re-executed. Zero errors. | Application logs show `No pending migrations to apply`. `DataSeeder.cs` executes zero schema-altering DDL statements. |

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
