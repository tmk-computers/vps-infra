# Phase 0.5 Source-Derived Schema Inventory & Acceptance Specification

**Document ID**: `REGATE-REMED-06-SCHEMA-INVENTORY`  
**Phase**: Phase 0 — Codex Focused Re-Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex Re-Gate RG-C1-02 (`06_REGATE_FINDINGS_REGISTER.md:136-147`), C2-01 (`06_REGATE_FINDINGS_REGISTER.md:80-89`)  
**Status**: COMPLETE — AUTHORITATIVE AND RECONCILED  

---

## 1. Executive Summary

This document establishes the definitive, source-backed schema inventory for Master Remediation item **`MR-34`** (Phase 0.5: Centralized Maintenance Mode Database Schema & Entity Model Alignment). 

It resolves:
- **RG-C1-02**: Complete removal of fictitious entities (`MaintenanceWindows`, `ServiceMaintenances`) and replacement with the actual 13 properties defined in source code across `Product.cs` and `ProjectService.cs`.
- **C2-01**: Neutralization of competing raw DDL in `DataSeeder.cs:46-168`, establishing versioned EF Core migrations as the sole schema evolution authority.

---

## 2. Source Code Evidence & Analysis

Direct source inspection of the entity definitions in `devops-manager/api/Data/Entities/` reveals:
1. **`BaseEntity.cs`**:
   - Defines `Id` (Guid), `CreatedAt` (DateTime), `UpdatedAt` (DateTime?), and `IsActive` (bool, default `true`).
   - `IsActive` already exists across all domain entities and is **NOT** a new maintenance column introduced by MR-34.
2. **`Product.cs`** (`devops-manager/api/Data/Entities/Product.cs`):
   - Inherits `BaseEntity`.
   - Introduces exactly **8 maintenance-mode properties**:
     - `IsMaintenance` (bool)
     - `MaintenanceMessage` (string?)
     - `MaintenanceVersion` (string?)
     - `MinSupportedVersion` (string?)
     - `ShowMaintenanceForMobile` (bool)
     - `ShowMaintenanceForWeb` (bool)
     - `MaintenanceStartedAt` (DateTime?)
     - `MaintenanceEstimatedEndAt` (DateTime?)
3. **`ProjectService.cs`** (`devops-manager/api/Data/Entities/ProjectService.cs`):
   - Inherits `BaseEntity`.
   - Introduces exactly **5 maintenance-mode properties**:
     - `IsMaintenanceOverride` (bool)
     - `IsMaintenance` (bool?)
     - `MaintenanceMessage` (string?)
     - `ShowMaintenanceForMobile` (bool)
     - `ShowMaintenanceForWeb` (bool)
4. **Nonexistent Entities in Codebase**:
   - Entities named `MaintenanceWindow` or `ServiceMaintenance` **DO NOT EXIST** in the C# codebase. References to them in earlier remediation documents were erroneous and are formally excised.
5. **Existing Migrations in Codebase**:
   - `devops-manager/api/Migrations/` contains migrations up to initial baseline (`InitialCreate`).
   - None of the 13 maintenance properties exist in the EF Core migration history (`__EFMigrationsHistory`) or in `ApplicationDbContextModelSnapshot.cs`.
6. **Existing `DataSeeder.cs` Raw DDL Conflict**:
   - `devops-manager/api/Data/DataSeeder.cs` lines 46–168 execute raw SQL `ALTER TABLE` and `CREATE TABLE IF NOT EXISTS` queries in a catch block, which historically masked missing EF migrations and caused PostgreSQL runtime errors (`42703: undefined_column`).

---

## 3. Authoritative Source-Derived Schema Inventory

The table below constitutes the **sole authoritative schema inventory** for Phase 0.5:

| Entity | Property | DB Column | Type | Nullable | Default Value in EF Model | Existing Migration Coverage | Seeder DDL Coverage | Required Phase 0.5 Action |
|---|---|---|---|---|---|---|---|---|
| **Product** | `IsMaintenance` | `"IsMaintenance"` | `boolean` | `false` | `false` | None | Partial / Unreliable | Create column in EF migration; backfill `false` |
| **Product** | `MaintenanceMessage` | `"MaintenanceMessage"` | `text` | `true` | `'All systems operational.'` | None | None | Create nullable column with default string |
| **Product** | `MaintenanceVersion` | `"MaintenanceVersion"` | `text` | `true` | `'1.0.0'` | None | None | Create nullable column with default string |
| **Product** | `MinSupportedVersion` | `"MinSupportedVersion"` | `text` | `true` | `'1.0.0'` | None | None | Create nullable column with default string |
| **Product** | `ShowMaintenanceForMobile` | `"ShowMaintenanceForMobile"` | `boolean` | `false` | `true` | None | None | Create column; backfill `true` |
| **Product** | `ShowMaintenanceForWeb` | `"ShowMaintenanceForWeb"` | `boolean` | `false` | `true` | None | None | Create column; backfill `true` |
| **Product** | `MaintenanceStartedAt` | `"MaintenanceStartedAt"` | `timestamp with time zone` | `true` | `null` | None | None | Create nullable timestamp column |
| **Product** | `MaintenanceEstimatedEndAt` | `"MaintenanceEstimatedEndAt"` | `timestamp with time zone` | `true` | `null` | None | None | Create nullable timestamp column |
| **ProjectService** | `IsMaintenanceOverride` | `"IsMaintenanceOverride"` | `boolean` | `false` | `false` | None | None | Create column; backfill `false` |
| **ProjectService** | `IsMaintenance` | `"IsMaintenance"` | `boolean` | `true` | `null` | None | None | Create nullable boolean column |
| **ProjectService** | `MaintenanceMessage` | `"MaintenanceMessage"` | `text` | `true` | `null` | None | None | Create nullable text column |
| **ProjectService** | `ShowMaintenanceForMobile` | `"ShowMaintenanceForMobile"` | `boolean` | `false` | `true` | None | None | Create column; backfill `true` |
| **ProjectService** | `ShowMaintenanceForWeb` | `"ShowMaintenanceForWeb"` | `boolean` | `false` | `true` | None | None | Create column; backfill `true` |

**Total Count**: Exactly **13 properties across 2 entities** (8 on `Product`, 5 on `ProjectService`).

---

## 4. Single Schema Authority Mandate (C2-01)

### 4.1 Principle
**Versioned EF Core migrations are the sole authoritative schema evolution mechanism.**

### 4.2 Required Phase 0.5 Seeder Neutralization
Before Phase 0.5 can be declared accepted:
1. **Neutralize Raw DDL in `DataSeeder.cs`**:
   - The raw SQL DDL block executing `ALTER TABLE` / `CREATE TABLE` in `DataSeeder.cs` (lines 46–168) must be disabled or removed.
   - `DataSeeder.cs` must be restricted purely to data seeding (populating default roles, seed products, system settings) using standard EF Core entity calls on pre-existing, migration-managed tables.
2. **Elimination of Competing Authority**:
   - `DataSeeder.cs` must never catch migration errors, inspect `information_schema.columns`, or execute fallback `ALTER TABLE` statements.
3. **Model Snapshot Alignment**:
   - `ApplicationDbContextModelSnapshot.cs` must be updated by the EF migration tooling to record all 13 properties with their exact types, nullabilities, and defaults.

---

## 5. Phase 0.5 Acceptance Test Specification

Phase 0.5 implementation (to be executed strictly in Phase 0.5, NOT in Phase 0) will be validated against the following exhaustive acceptance contract:

### 5.1 Acceptance Criteria
1. **Existing Supported Database Upgrade**:
   - An existing PostgreSQL database containing real historical data in `Products` and `ProjectServices` (lacking the 13 columns) is updated via `dotnet ef database update`.
   - The migration applies cleanly without SQL errors.
   - All pre-existing rows remain intact; active and inactive rows are preserved.
2. **Fresh PostgreSQL Installation**:
   - An empty PostgreSQL instance is initialized from scratch.
   - All migrations apply sequentially from initial baseline through `20261001000000_AddMaintenanceModeFields`.
   - The resulting database schema matches `ApplicationDbContextModelSnapshot.cs` bit-for-bit.
3. **Migration History Consistency**:
   - `__EFMigrationsHistory` contains the exact migration record name.
4. **All 13 Maintenance Fields Verified**:
   - `information_schema.columns` inspection confirms all 8 `Product` columns and all 5 `ProjectService` columns exist with correct types and nullabilities.
5. **Zero Competing Raw DDL on Repeat Startup**:
   - Restarting the API container or re-running `dotnet ef database update` produces:
     `"No pending migrations to apply."`
   - `DataSeeder.cs` executes zero DDL queries.
6. **Entity Query Regression Gate (Zero SQLSTATE 42703)**:
   - EF Core executes:
     ```csharp
     var products = await dbContext.Products.Where(p => p.IsMaintenance).ToListAsync();
     var services = await dbContext.ProjectServices.Where(s => s.IsMaintenanceOverride).ToListAsync();
     ```
   - Both queries succeed with HTTP 200; zero PostgreSQL error `42703 (undefined_column)` in application logs.

---

## 6. Implementation Prohibition in Phase 0

> **STRICT RE-GATE REMINDER**: This specification defines the authoritative Phase 0 baseline inventory. **Phase 0.5 implementation must NOT be performed during Phase 0.** The EF Core migration must not be generated, `DataSeeder.cs` must not be modified, and PostgreSQL must not be touched until Phase 0 baseline freeze is approved by Independent Review and Codex Audit Gate.
