# 03 PHASE 0.5 SCHEMA CONTRACT, SCHEMA AUTHORITY & EVIDENCE INTEGRITY REVIEW

**Document ID**: `FINAL-REVIEW-03-SCHEMA-EVIDENCE`  
**Phase**: Phase 0 — Final Independent Closure Review  
**Review Cycle**: Final Independent Closure Review  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Status**: Authoritative Schema and Evidence Audit Complete  
**Date**: 2026-09-30  

---

## 1. Independent Verification of Phase 0.5 Source-Derived Schema Contract

### 1.1 Source Code Entity Inspection
The Reviewer independently verified the C# entity source files under `devops-manager/api/Data/Entities/`:

#### 1. Entity: `Product` ([`devops-manager/api/Data/Entities/Product.cs:12-23`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/Product.cs#L12-L23))
- `IsActive`: Inherited existing property from `BaseEntity`. It represents the general product activation state, **NOT** a new maintenance mode property.
- Maintenance Mode properties: **Exactly 8 properties**:
  1. `bool IsMaintenance { get; set; } = false;` (CLR: `bool`, non-nullable)
  2. `string? MaintenanceMessage { get; set; } = "All systems operational.";` (CLR: `string?`, nullable)
  3. `string? MaintenanceVersion { get; set; } = "1.0.0";` (CLR: `string?`, nullable)
  4. `string? MinSupportedVersion { get; set; } = "1.0.0";` (CLR: `string?`, nullable)
  5. `bool ShowMaintenanceForMobile { get; set; } = true;` (CLR: `bool`, non-nullable)
  6. `bool ShowMaintenanceForWeb { get; set; } = true;` (CLR: `bool`, non-nullable)
  7. `DateTime? MaintenanceStartedAt { get; set; }` (CLR: `DateTime?`, nullable)
  8. `DateTime? MaintenanceEstimatedEndAt { get; set; }` (CLR: `DateTime?`, nullable)

#### 2. Entity: `ProjectService` ([`devops-manager/api/Data/Entities/ProjectService.cs:36-41`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/ProjectService.cs#L36-L41))
- Maintenance Mode properties: **Exactly 5 properties**:
  1. `bool IsMaintenanceOverride { get; set; } = false;` (CLR: `bool`, non-nullable)
  2. `bool? IsMaintenance { get; set; }` (CLR: `bool?`, nullable; tri-state: inherits product state when `null`)
  3. `string? MaintenanceMessage { get; set; }` (CLR: `string?`, nullable)
  4. `bool ShowMaintenanceForMobile { get; set; } = true;` (CLR: `bool`, non-nullable)
  5. `bool ShowMaintenanceForWeb { get; set; } = true;` (CLR: `bool`, non-nullable)

**Total Count**: $8 + 5 = 13$ properties across exactly 2 entities.

---

## 2. DateTime Relational Mapping & EF Core Configuration

### 2.1 Configuration Pre-Convention Inspection
In [`devops-manager/api/Data/ApplicationDbContext.cs:43-47`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/ApplicationDbContext.cs#L43-L47):
```csharp
// (Optional) global DateTime conventions
configurationBuilder
    .Properties<DateTime>()
    .HaveColumnType("timestamp without time zone");
```
In Entity Framework Core, calling `configurationBuilder.Properties<DateTime>().HaveColumnType(...)` inside `ConfigureConventions` applies the column type pre-convention to both non-nullable `DateTime` and nullable `DateTime?` properties across the entire model.

### 2.2 Relational Type & Model Snapshot Reality
- **CLR Types**: `DateTime?` (`MaintenanceStartedAt`, `MaintenanceEstimatedEndAt`).
- **PostgreSQL Relational Type**: **`timestamp without time zone`**.
- **Model Snapshot Behavior**: When EF Core generates migrations, it maps these properties to `timestamp without time zone`. The earlier remediation document's assertion of `timestamp with time zone` was technically incorrect and contradicted the active EF configuration.
- **Relational Defaults vs CLR Initializers**: In `ApplicationDbContext.cs`, `OnModelCreating` does not specify `HasDefaultValue` for these maintenance properties. The defaults shown in entity classes (`="All systems operational."`, `="1.0.0"`, `=false`, `=true`) are C# property initializers in memory. The database relational default in the model snapshot is `None`. Non-nullable boolean columns must receive migration backfill defaults.

**Reviewer Assessment**: **PASS**. The authoritative baseline documentation now accurately reflects source reality.

---

## 3. Absence of Nonexistent Entities

The Reviewer performed an automated regex search across all files in `docs/remediation/phase-0/`:
- `MaintenanceWindow`
- `MaintenanceWindows`
- `ServiceMaintenance`
- `ServiceMaintenances`

**Search Results**: **0 matches found**. All active references to these fictitious entities have been completely excised from the authoritative Phase 0 baseline. Historical audit reports referencing earlier drafts are preserved as immutable evidence.

**Reviewer Assessment**: **PASS**.

---

## 4. Sole Schema Authority & DataSeeder DDL Neutralization

### 4.1 Invariant: Versioned EF Core Migrations are the Sole Authority
The platform architecture establishes:
> **Versioned EF Core migrations are the sole schema evolution authority.**

### 4.2 Raw DDL Neutralization Mandate
Inspection of [`DataSeeder.cs:46-168`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs#L46-L168) confirms that the seeder currently executes raw `ExecuteSqlRawAsync` DDL statements creating tables and altering columns, followed by `catch { }` swallowing errors.

In [`PHASE_0_FINAL_REPORT.md:170`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md#L170), [`16_PHASEWISE_REMEDIATION_PLAN.md:73`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md#L73), and [`03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md), the acceptance criteria explicitly mandate:
> Competing raw DDL in `DataSeeder.cs:46-168` **MUST be neutralized and disabled prior to Phase 0.5 acceptance**. Seeder execution during Phase 0.5 validation is bounded strictly to seed data insertion. Only broader legacy non-DDL seeder cleanup remains scheduled for Phase 2 MR-13.

Zero active authoritative documents defer raw DDL neutralization to Phase 2.

**Reviewer Assessment**: **PASS**.

---

## 5. Evidence Integrity & Epistemic Honesty

The Reviewer verified that the Developer has corrected earlier evidence overclaims:

1. **Nonexistent Wrapper Path**: Corrected `15_DOCUMENTATION_TRUTH_MATRIX.md:31-35` to cite real repo paths (`vps-infra/README.md`) and labeled early claims as promotional marketing assertions.
2. **Windows Agent Fallback Secret**: Honestly distinguishes:
   - **Current Implementation**: Hardcoded static fallback secret `"SuperCiSecretKey123!"` is currently present in `scripts/tmk-iis-agent.ps1:21` and `IisClientService.cs:42`.
   - **Target Architecture Contract**: Must be eliminated and dynamically secured under **MR-28** in **Phase 1: Shared Security Foundation**.
3. **Backup TOC Listing vs Payload Validation**: Clarifies that `pg_restore -l` validates TOC archive structure and header integrity, while full payload data validation is performed during automated Disaster Recovery drills (**MR-15**).
4. **Historical Immutability**: Historical audit reports remain unaltered; corrections are applied exclusively to active authoritative documents and reconciliation dossiers.
5. **No Speculative Implementation Claims**: Architectural requirements are tracked as `OPEN` under their respective Master Remediation items; no planned capability is claimed as currently implemented.

---

## 6. Reviewer Domain Verdict

- **Phase 0.5 Schema Contract**: **PASS** (Exact 8 Product + 5 ProjectService properties; `IsActive` existing base property).
- **DateTime Relational Mapping**: **PASS** (`timestamp without time zone` verified against EF pre-convention).
- **Nonexistent Entities**: **PASS** (Zero occurrences of fictitious entities).
- **Sole Schema Authority**: **PASS** (EF Core sole authority; DataSeeder raw DDL neutralization required before Phase 0.5 acceptance).
- **Evidence Integrity**: **PASS** (Honest distinction between current code and target contract).
