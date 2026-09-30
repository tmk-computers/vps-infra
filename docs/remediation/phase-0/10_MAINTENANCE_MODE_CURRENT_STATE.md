# 10 MAINTENANCE MODE CURRENT-STATE INVESTIGATION & FORENSIC REPORT

**Document ID**: `REMED-P0-10`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Baseline Date**: 2026-09-29  
**Target Master IDs**: **MR-34**, **MR-35**  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Executive Summary

In post-audit commits `4c40800` ("feat(maintenance): add centralized maintenance mode with granular overrides, UI modals, and E2E test suite") and `3078a13`, Centralized Maintenance Mode was introduced.

This forensic investigation confirms two critical defects:
1. **MR-34 (Database Schema Migration Gap — Pilot Blocker)**: Persistent fields were added to `Product` and `ProjectService` C# entities without generating an EF Core migration or executing DDL in `DataSeeder.cs`. Existing PostgreSQL schemas lack the newly required Maintenance Mode columns. Queries against affected entities fail with PostgreSQL SQLSTATE 42703 column-missing errors, propagating as HTTP 500 responses in the application. The PostgreSQL server itself does not crash.
2. **MR-35 (Service Isolation & Compose Mutation Defect — Pilot Blocker)**: The compose synchronization routine uses global regex replacement across `docker-compose.yml`, mutating environment blocks for ALL services in the file and risking YAML corruption.

---

## 2. Forensic Code Analysis by Architectural Dimension

### 2.1 Persistence Model & Database Fields (MR-34)
- **Entities Modified**:
  - [`Product.cs:15-23`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/Product.cs#L15-L23): Added 8 persistent properties:
    - `bool IsMaintenance` (default `false`)
    - `string? MaintenanceMessage`
    - `string? MaintenanceVersion`
    - `string? MinSupportedVersion`
    - `bool ShowMaintenanceForMobile` (default `true`)
    - `bool ShowMaintenanceForWeb` (default `true`)
    - `DateTime? MaintenanceStartedAt`
    - `DateTime? MaintenanceEstimatedEndAt`
  - [`ProjectService.cs:36-40`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/ProjectService.cs#L36-L40): Added 5 persistent properties:
    - `bool IsMaintenanceOverride` (default `false`)
    - `bool? IsMaintenance`
    - `string? MaintenanceMessage`
    - `bool ShowMaintenanceForMobile` (default `true`)
    - `bool ShowMaintenanceForWeb` (default `true`)

### 2.2 EF Migrations & Seeding Analysis (MR-34)
- **Directory Inspected**: [`devops-manager/api/Migrations/`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Migrations/)
- **Latest Migration on Disk**: `20260831080000_AddDatabaseServerToProjectService.cs` (dated 2026-08-31).
- **Finding**: **Zero migrations exist for the Maintenance Mode fields**.
- **Seeder Inspected**: [`devops-manager/api/Data/DataSeeder.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs)
- **Finding**: `DataSeeder.cs` executes raw SQL `ALTER TABLE` statements for legacy columns (`Directory`, `GitAccessToken`, `DatabaseServer`), but has **no statements adding the new maintenance columns**.
- **Why Automated Tests Passed**: Both `MaintenanceServiceTests.cs` and `MaintenanceControllerIntegrationTests.cs` configure EF Core using `.UseInMemoryDatabase()`. The In-Memory provider generates schema dynamically from C# model metadata in memory, completely bypassing EF migrations and PostgreSQL DDL execution.
- **Production Impact**: Any fresh deployment against PostgreSQL or upgrade of an existing database will throw:
  `Npgsql.PostgresException (0x80004005): 42703: column p.IsMaintenance does not exist`.

### 2.3 Compose Mutation Logic & Service Isolation Defect (MR-35)
- **File Inspected**: [`MaintenanceService.cs:255-295`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MaintenanceService.cs#L255-L295)
- **Mutation Logic**:
  ```csharp
  // Line 268 in MaintenanceService.cs:
  content = Regex.Replace(content, @"(SystemStatus__IsMaintenance\s*=\s*)[^\r\n]*", m => $"{m.Groups[1].Value}{isMaintenanceStr}");
  ```
  And when injecting new blocks:
  ```csharp
  // Line 278:
  content = Regex.Replace(content, @"^([ \t]*)environment:\s*$", match => { ... }, RegexOptions.Multiline);
  ```
- **Forensic Findings**:
  1. **Cross-Service Contamination**: If `docker-compose.yml` defines multiple services (e.g. `api`, `web`, `worker`, `db`), toggling maintenance mode for `api` injects or replaces `SystemStatus__IsMaintenance` across **every single service** that contains an `environment:` key.
  2. **YAML Fragility**: String regex manipulation of YAML without AST parsing can break if indentation differs, if environment variables use dictionary mapping (`KEY: VALUE`) rather than array syntax (`- KEY=VALUE`), or if comments exist.
  3. **Silent Failure**: `ExecuteDockerComposeUpAsync` (lines 297–329) catches exceptions, logs a warning, and swallows the failure. If `docker compose up` fails, the API returns HTTP 200 Success to the operator while the container is crashing or un-updated.

### 2.4 API Authorization
- **Endpoints Inspected**:
  - `GET /api/products/{id}/maintenance`: Protected by `[HasPermission(PermissionEnum.Products_Read)]`.
  - `POST /api/products/{id}/maintenance`: Protected by `[HasPermission(PermissionEnum.Products_Update)]`.
  - `GET /api/system/product-status/{productIdOrName}`: Open to `[AllowAnonymous]` (public status circuit breaker for client apps).
- **Finding**: Controller permissions are aligned with Products permissions, but lack tenant-scoping verification (MR-08).

### 2.5 Desired-State vs. Actual-State Reconciliation
- **Desired State**: Stored in PostgreSQL `Products` and `ProjectServices` tables.
- **Actual State**: Running environment variables in Docker container inspected via Docker API.
- **Defect**: No background reconciliation loop exists. If an operator manually restarts a container or deploys via CLI, the container state can diverge from the database desired state indefinitely.

### 2.6 Web, Mobile, and Bypass Behavior
- **Web App**: Checks `SystemStatus__IsMaintenance` via API response; displays full-screen `<MaintenanceOverlay />`.
- **Mobile App**: Evaluates `MinSupportedVersion` against client version string; forces app upgrade if `clientVersion < MinSupportedVersion`.
- **Bypass Rules**: Currently no bypass headers (e.g. `X-Maintenance-Bypass: token`) or role-based bypass is implemented. When enabled, SuperAdmin is locked out of testing the live application through the main domain.

---

## 3. Required Remediation Specifications (Phase 0.5 & Phase 2)

1. **For MR-34 (Phase 0.5 — Isolated Schema Prerequisite)**:
   - **Single Schema Authority**: Create the versioned EF Core migration: `20261001000000_AddMaintenanceModeFields.cs` as the SOLE schema evolution authority, introducing the exact 8 `Product` and 5 `ProjectService` properties.
   - **Neutralization of Existing DataSeeder DDL**: Prior to Phase 0.5 acceptance, the competing raw `ALTER TABLE` and `CREATE TABLE` DDL block in `DataSeeder.cs:46-168` must be disabled or removed. Startup execution of EF Core migrations must be the sole mechanism that establishes and evolves the database schema; the seeder must not execute schema-modifying DDL or catch migration errors. Unrelated data-seeding decoupling logic remains in Phase 2 under MR-13.
   - **Acceptance Verification**: Execute the comprehensive PostgreSQL acceptance suite (fresh database creation, upgrade of existing supported database, data preservation including inactive rows, Product hydration query, ProjectService hydration query, and repeat startup stability) defined in `06_PHASE_0_5_SCHEMA_INVENTORY.md`.

2. **For MR-35 (Phase 2 — Service Isolation & Container Lifecycle)**:
   - Replace regex string replacement with an AST-aware YAML parser (e.g. `YamlDotNet`).
   - Confine environment variable mutation strictly to the target service node in the Compose document.
   - Make container recreation failures fail the API request and initiate state rollback.
