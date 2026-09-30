# Windows, schema and traceability final gate

## Windows architecture — PASS

[04_TARGET_ARCHITECTURE.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md) and [05_SUPPORTED_OS_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md) consistently select Windows Server 2022, native IIS 10/HTTP.sys owning 80/443, ASP.NET Core Module, compiled TMK.Agent.Windows, a dedicated least-privilege identity and remote PostgreSQL 16. Gate A excludes Windows-host Traefik, Docker Desktop and WSL2 PostgreSQL.

Explicit IIS/AppPool, filesystem and SCM permissions replace reliance on bare LocalService. Agent mTLS and scoped bearer authorization are separate controls. The roadmap requires functional update health and reboot/power-loss recovery, not merely a running service. Selecting a particular updater executable is not a Phase 0 acceptance condition.

The canonical database contract requires authenticated TLS with validated CA/pinning and forbids bypass. Its VerifyFull option meets that intent. The alternative Require/Trust Server Certificate=false example needs precision correction (new FR-C2-01); that string alone is insufficient for certificate authentication in the referenced Npgsql generation. The overriding peer-verification invariant is explicit, so this remains a C2 example correction, not a reopened topology blocker.

## Phase 0.5 inventory — FAIL (RG-C1-02)

Independent source inspection confirms exactly eight Product and five ProjectService maintenance properties. This validates the count, not the complete claimed inventory.

| Entity | Property | CLR type / nullable | Observed C# initialization | Relational type from source/configuration |
|---|---|---|---|---|
| Product | IsMaintenance | bool / no | false | boolean |
| Product | MaintenanceMessage | string? / yes | All systems operational. | text |
| Product | MaintenanceVersion | string? / yes | 1.0.0 | text |
| Product | MinSupportedVersion | string? / yes | 1.0.0 | text |
| Product | ShowMaintenanceForMobile | bool / no | true | boolean |
| Product | ShowMaintenanceForWeb | bool / no | true | boolean |
| Product | MaintenanceStartedAt | DateTime? / yes | null | timestamp without time zone |
| Product | MaintenanceEstimatedEndAt | DateTime? / yes | null | timestamp without time zone |
| ProjectService | IsMaintenanceOverride | bool / no | false | boolean |
| ProjectService | IsMaintenance | bool? / yes | null | boolean |
| ProjectService | MaintenanceMessage | string? / yes | null | text |
| ProjectService | ShowMaintenanceForMobile | bool / no | true | boolean |
| ProjectService | ShowMaintenanceForWeb | bool / no | true | boolean |

Evidence: [Product.cs:15](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/Product.cs:15), [ProjectService.cs:36](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/ProjectService.cs:36), [ApplicationDbContext.cs:44](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/ApplicationDbContext.cs:44). The DateTime pre-convention explicitly sets `timestamp without time zone`; no property override was found. EF pre-convention matching includes the non-nullable value type for nullable properties: [EF Core bulk configuration](https://learn.microsoft.com/en-us/ef/core/modeling/bulk-configuration). This table is static model analysis; no migration was generated or database queried.

The incorporated [06_PHASE_0_5_SCHEMA_INVENTORY.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/06_PHASE_0_5_SCHEMA_INVENTORY.md) incorrectly specifies `timestamp with time zone` for both timestamps. Its “Default Value in EF Model” column conflates C# initializers with relational defaults; no HasDefaultValue configuration for these properties exists in the inspected context. Future backfill/store-default choices may be specified deliberately, but must not be described as already observed model defaults.

More decisively, active [PHASE_0_FINAL_REPORT.md:171](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md:171) still calls for `AddMaintenanceModeEntities` on Product, ProjectService and **MaintenanceWindow**. The corrected 10/16/17 documents call for `AddMaintenanceModeFields` on the real two entities. The final report has not been designated historical/superseded and remains inside the current authoritative baseline. This is the same unresolved acceptance defect, not a new preference for naming.

### Migration, seeder and IsActive checks

Repository migration/snapshot searches contain none of the thirteen property names. Migrations extend through `20260831080000_AddDatabaseServerToProjectService.cs`, not merely InitialCreate. A repository inspection cannot establish what an actual deployed `__EFMigrationsHistory` contains.

[DataSeeder.cs:46](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs:46) alters legacy Projects columns and ProjectServices.DatabaseServer, then creates DR/AI tables. It contains no maintenance-column DDL; “Partial / Unreliable” coverage of Product.IsMaintenance is not supported. The DDL sits in a try block with a swallowed catch; earlier migration failure is also caught. “No pending migrations” alone cannot prove zero DDL on repeat startup.

[BaseEntity.cs:12](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/BaseEntity.cs:12) already defines IsActive. Product redeclares IsActive at line 12; ProjectService inherits it. It is not a fourteenth maintenance field and existing inactive rows must remain inactive. The inventory correctly requires preservation, but R4's description that both merely inherit the property is imprecise.

### Schema authority — partial correction, retained C2-01

[10_MAINTENANCE_MODE_CURRENT_STATE.md:92](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md:92), [16_PHASEWISE_REMEDIATION_PLAN.md:73](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md:73) and [17_PHASE_1_ENTRY_CRITERIA.md:41](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md:41) now require removal/disablement of competing DDL **before Phase 0.5 acceptance**. The seeder must not repair schema or swallow migration failures. This is the correct contract.

The final report at line 171 still says raw DDL removal is in Phase 2. Reconcile that statement; unrelated seeding refactoring may remain Phase 2. Current implementation is expected to be unfixed at Phase 0, so this audit does not fail the authority gate merely because raw DDL still exists in source.

The later PostgreSQL acceptance suite must exercise existing/fresh schemas, model/snapshot/history agreement, hydration of both entities/all fields, inactive-data preservation and repeat startup without schema repair. Those tests have not been executed by this audit.

## Substantive traceability — PASS

[03_HISTORICAL_FINDING_TRACEABILITY.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md) preserves:

| Finding | Obligation retained in canonical contract |
|---|---|
| F01 | Untrusted CI code cannot access host Docker administration; MR-01 |
| F02 | Generated secrets, default-key boot rejection, service-specific trust, issuer/key/scope negatives; MR-02/MR-36 |
| F15 | Atomic claim, durable idempotency, execution-time reauthorization, crash reconciliation, unchanged target remains valid across clock hour; MR-08 |
| F16.1 | Key protection including rotation acceptance |
| F16.2 | Streaming spend cap with atomic concurrent reservations and simultaneous-call tests |
| F16.3 | LocalOnly privacy precedence |
| F16.4 | Authorized fallback and budget recheck on all paths |
| F16.5 | Resource admission and missing-telemetry fail-closed behavior; **MR-16**, not MR-17 |
| F22 | Tenant/resource cache keys, bounded TTL/session size, real OS memory and unknown-telemetry rejection |
| DEF-08 | Separate management-plane root/socket/capability hardening, distinct from CI |
| DEF-15 | Assigned-root containment and negative traversal tests; MR-04 Phase 1 with MR-08/MR-24 functional ownership |

AI remains disabled for Gate A; all five F16 conditions must be satisfied before re-enable/parent closure. OPEN MR status is not a Phase 0 failure.

The supplementary trace reconciliation misidentifies F02 as the committed Google key finding and F15 as MR-18 scheduling. Canonical rows preserve the original meanings. Those errors remain C2-04 evidence corrections; they do not override the canonical owners or create a second traceability blocker.

## Dual-OS — PASS

Ubuntu 24.04 LTS and Windows Server 2022 remain equal first-class targets. Phase 12A certifies Linux; Phase 12B independently certifies Windows. Linux pilot may begin after its own certification while Windows work continues. Phase 15 requires unified Dual-OS Commercial Gate B. Linux evidence cannot certify Windows.
