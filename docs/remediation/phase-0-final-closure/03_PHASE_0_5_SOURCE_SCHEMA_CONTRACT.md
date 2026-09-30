# 03 PHASE 0.5 SOURCE-DERIVED SCHEMA CONTRACT

**Document ID**: `FINAL-CLOSURE-03-SCHEMA-CONTRACT`  
**Phase**: Phase 0 — Final Codex Closure Corrections  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex RG-C1-02, C2-01  
**Status**: COMPLETE — AUTHORITATIVE SOURCE-DERIVED CONTRACT  

---

## 1. Executive Summary

This document establishes the definitive, source-backed schema specification for **MR-34** (Phase 0.5: Centralized Maintenance Mode Database Schema & Entity Model Alignment).

It definitively resolves:
1. **RG-C1-02**: Eliminates all references to fictitious entities (`MaintenanceWindow`, `MaintenanceWindows`, `ServiceMaintenance`, `ServiceMaintenances`) across the active baseline, providing the exact source-derived 13-property inventory across real entities `Product` and `ProjectService`.
2. **DateTime Relational Mapping**: Confirms that EF Core global pre-convention in `ApplicationDbContext.cs:44-46` configures relational timestamps as **`timestamp without time zone`**, eliminating the erroneous `timestamp with time zone` assertion.
3. **C2-01 (Single Schema Evolution Authority)**: Mandates that competing raw DDL in `DataSeeder.cs:46-168` MUST be neutralized and disabled **prior to Phase 0.5 acceptance**, ensuring EF Core migrations are the sole schema authority.

---

## 2. Source Code Architecture & Entity Analysis

Direct inspection of the entity and database context source files confirms:

### 2.1 Entity Code Reality
- **`BaseEntity.cs`** (`devops-manager/api/Data/Entities/BaseEntity.cs`):
  - Defines `Id` (Guid), `CreatedAt` (DateTime), `UpdatedAt` (DateTime?), and `IsActive` (bool = true).
  - `IsActive` is an inherited property present in all domain entities. It already exists in baseline migrations and `ApplicationDbContextModelSnapshot.cs:774,862`. It is **NOT** a new maintenance column.
- **`Product.cs`** (`devops-manager/api/Data/Entities/Product.cs`):
  - Inherits `BaseEntity`. Defines exactly **8 maintenance properties** (lines 14–22).
- **`ProjectService.cs`** (`devops-manager/api/Data/Entities/ProjectService.cs`):
  - Inherits `BaseEntity`. Defines exactly **5 maintenance properties** (lines 35–41).
- **Fictitious Entities Non-existence**:
  - `MaintenanceWindow` and `ServiceMaintenance` **do not exist anywhere in the codebase**. Any prior references to them in historical drafts are formally excised.

### 2.2 EF Core Model Configuration (`ApplicationDbContext.cs`)
- Lines 44–46 declare the global pre-convention:
  ```csharp
  configurationBuilder
      .Properties<DateTime>()
      .HaveColumnType("timestamp without time zone");
  ```
  In EF Core 7+, pre-conventions matching `DateTime` automatically apply to both non-nullable `DateTime` and nullable `DateTime?`.
- In `OnModelCreating`, neither `Product` nor `ProjectService` configures relational store defaults (`HasDefaultValue` / `HasDefaultValueSql`) for maintenance properties.
- Therefore, the configured EF Column Type for `MaintenanceStartedAt` and `MaintenanceEstimatedEndAt` is **`timestamp without time zone`**.

### 2.3 Snapshot & Seeder Reality
- `ApplicationDbContextModelSnapshot.cs` currently contains **0 of the 13 maintenance properties**.
- `DataSeeder.cs:46-168` executes raw SQL DDL (`ALTER TABLE`, `CREATE TABLE IF NOT EXISTS`) in an unhandled catch block, none of which provides coverage for the 13 maintenance properties.

---

## 3. Authoritative Source-Derived Schema Inventory

The table below is authoritative and derived directly from active source code:

| Entity | CLR Property | CLR Type | Nullable | EF Column Type | DB Default | CLR Initializer | Existing Migration | Snapshot Coverage | Seeder DDL |
|---|---|---|---|---|---|---|---|---|---|
| **Product** | `IsMaintenance` | `bool` | `false` | `boolean` | `None` | `false` | None | None | None |
| **Product** | `MaintenanceMessage` | `string?` | `true` | `text` | `None` | `"All systems operational."` | None | None | None |
| **Product** | `MaintenanceVersion` | `string?` | `true` | `text` | `None` | `"1.0.0"` | None | None | None |
| **Product** | `MinSupportedVersion` | `string?` | `true` | `text` | `None` | `"1.0.0"` | None | None | None |
| **Product** | `ShowMaintenanceForMobile` | `bool` | `false` | `boolean` | `None` | `true` | None | None | None |
| **Product** | `ShowMaintenanceForWeb` | `bool` | `false` | `boolean` | `None` | `true` | None | None | None |
| **Product** | `MaintenanceStartedAt` | `DateTime?` | `true` | `timestamp without time zone` | `None` | `null` | None | None | None |
| **Product** | `MaintenanceEstimatedEndAt` | `DateTime?` | `true` | `timestamp without time zone` | `None` | `null` | None | None | None |
| **ProjectService** | `IsMaintenanceOverride` | `bool` | `false` | `boolean` | `None` | `false` | None | None | None |
| **ProjectService** | `IsMaintenance` | `bool?` | `true` | `boolean` | `None` | `null` | None | None | None |
| **ProjectService** | `MaintenanceMessage` | `string?` | `true` | `text` | `None` | `null` | None | None | None |
| **ProjectService** | `ShowMaintenanceForMobile` | `bool` | `false` | `boolean` | `None` | `true` | None | None | None |
| **ProjectService** | `ShowMaintenanceForWeb` | `bool` | `false` | `boolean` | `None` | `true` | None | None | None |

**Total Count**: Exactly **13 properties across 2 real entities** (8 on `Product`, 5 on `ProjectService`).

---

## 4. Key Architectural Distinctions

### 4.1 CLR Type vs EF Configured Database Type
- `DateTime` / `DateTime?` in C# source map to **`timestamp without time zone`** in PostgreSQL via the EF Core pre-convention in `ApplicationDbContext.cs:44-46`.
- Any assertion that EF Core generates `timestamp with time zone` is factually false for this codebase.

### 4.2 CLR Initializers vs Relational Database Defaults
- The default strings (`"All systems operational."`, `"1.0.0"`) and booleans (`false`, `true`) are **CLR property initializers** evaluated when an entity object is instantiated in memory in C#.
- The relational model configuration (`OnModelCreating`) does NOT declare `HasDefaultValue` for these columns. Thus, the database relational default is `None`.
- For non-nullable boolean columns (`IsMaintenance`, `ShowMaintenanceForMobile`, `ShowMaintenanceForWeb`, `IsMaintenanceOverride`), migration code must specify appropriate `defaultValue: false` or `defaultValue: true` to support applying the migration to existing tables containing rows.

---

## 5. Single Schema Evolution Authority Mandate (C2-01)

### 5.1 Sole Authority Principle
# VERSIONED EF CORE MIGRATIONS ARE THE SOLE SCHEMA EVOLUTION AUTHORITY.

### 5.2 Mandatory Seeder Neutralization Prior to Phase 0.5 Acceptance
To eliminate competing schema authority and prevent race conditions / schema collision:
1. **Neutralize Raw DDL in `DataSeeder.cs`**:
   - The raw SQL DDL block executing `ALTER TABLE` and `CREATE TABLE IF NOT EXISTS` in `DataSeeder.cs:46-168` MUST be disabled or excised **prior to Phase 0.5 acceptance**.
   - `DataSeeder.cs` must be strictly restricted to data insertion (populating default roles, seed products, system settings) using standard EF Core entity calls against existing migration-managed tables.
2. **Timing of Legacy Seeder Refactoring**:
   - Disabling and neutralizing competing raw DDL is an absolute prerequisite for Phase 0.5 acceptance.
   - General refactoring and cleanup of non-DDL seeder data operations remains scheduled for Phase 2 MR-13.

---

## 6. Strict Implementation Prohibition in Phase 0

> **CRITICAL PHASE BOUNDARY RULE**:
> This document specifies the exact architecture and requirements for Phase 0.5.
> **DO NOT IMPLEMENT PHASE 0.5 IN PHASE 0.**
> - Do NOT generate EF Core migrations (`dotnet ef migrations add`).
> - Do NOT execute database updates (`dotnet ef database update`).
> - Do NOT alter PostgreSQL tables or schemas.
> - Do NOT edit `DataSeeder.cs` or entity runtime files yet.
> Implementation begins strictly after Phase 0 closure is certified.

---

## 7. Phase 0.5 Acceptance Test Specification

When Phase 0.5 is executed, it must satisfy all 5 acceptance test scenarios:

1. **P05-TC01: Upgrade on Existing Database with Data**:
   - An existing PostgreSQL database with populated `Products` and `ProjectServices` (lacking the 13 columns) is updated via `dotnet ef database update`.
   - Migration applies cleanly with exit code 0; all existing rows and column values are preserved.
2. **P05-TC02: Clean Initialization from Scratch**:
   - A fresh PostgreSQL database applies all migrations sequentially from baseline through `20261001000000_AddMaintenanceModeFields`.
   - Schema matches `ApplicationDbContextModelSnapshot.cs` bit-for-bit.
3. **P05-TC03: Migration History Validation**:
   - `__EFMigrationsHistory` contains the exact migration record name.
4. **P05-TC04: Physical Column & Type Verification**:
   - `information_schema.columns` inspection confirms all 8 `Product` columns and all 5 `ProjectService` columns exist with expected types (`timestamp without time zone` for timestamps, `boolean`, `text`).
5. **P05-TC05: Zero SQLSTATE 42703 Regression Gate**:
   - Application queries querying maintenance properties succeed with HTTP 200 and zero PostgreSQL `42703 (undefined_column)` errors in application logs.
   - Restarting application container executes zero DDL queries.
