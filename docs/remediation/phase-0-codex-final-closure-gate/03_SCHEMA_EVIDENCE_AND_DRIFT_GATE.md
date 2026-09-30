# Schema, evidence and infrastructure drift gate

## Schema contract — PASS

Actual source inspected:

- [Product.cs:15](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/Product.cs:15): eight maintenance properties.
- [ProjectService.cs:36](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/ProjectService.cs:36): five maintenance properties.
- [ApplicationDbContext.cs:44](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/ApplicationDbContext.cs:44): DateTime pre-convention uses `timestamp without time zone`.

| Entity | Property | CLR type | CLR initializer | Configured relational type |
|---|---|---|---|---|
| Product | IsMaintenance | bool | false | boolean |
| Product | MaintenanceMessage | string? | All systems operational. | text |
| Product | MaintenanceVersion | string? | 1.0.0 | text |
| Product | MinSupportedVersion | string? | 1.0.0 | text |
| Product | ShowMaintenanceForMobile | bool | true | boolean |
| Product | ShowMaintenanceForWeb | bool | true | boolean |
| Product | MaintenanceStartedAt | DateTime? | null | timestamp without time zone |
| Product | MaintenanceEstimatedEndAt | DateTime? | null | timestamp without time zone |
| ProjectService | IsMaintenanceOverride | bool | false | boolean |
| ProjectService | IsMaintenance | bool? | null | boolean |
| ProjectService | MaintenanceMessage | string? | null | text |
| ProjectService | ShowMaintenanceForMobile | bool | true | boolean |
| ProjectService | ShowMaintenanceForWeb | bool | true | boolean |

No maintenance-property HasDefaultValue/HasDefaultValueSql override was found. CLR initialization and database defaults are now separated in the corrected contract. Required migration backfills are prospective decisions. Nullable DateTime properties receive the non-nullable type's pre-convention; see [EF Core pre-convention configuration](https://learn.microsoft.com/en-us/ef/core/modeling/bulk-configuration).

Repository migration/snapshot search found none of the thirteen maintenance fields. This is source evidence, not a query of deployed __EFMigrationsHistory. Product redeclares IsActive; ProjectService inherits it. Existing active/inactive rows must be preserved; IsActive is not a new maintenance field.

Canonical phase-0 documents contain zero MaintenanceWindow/ServiceMaintenance matches. Their mentions in correction narratives explicitly describe nonexistent, rejected entities; they are not active migration targets. Canonical final report:170 now matches the real two entities and AddMaintenanceModeFields.

## Schema evolution authority — PASS

[PHASE_0_FINAL_REPORT.md:170](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md:170), [10_MAINTENANCE_MODE_CURRENT_STATE.md:92](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md:92), [16_PHASEWISE_REMEDIATION_PLAN.md:73](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md:73) and [17_PHASE_1_ENTRY_CRITERIA.md:41](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md:41) mandate sole versioned EF migration authority and neutralization of schema-changing DataSeeder SQL before Phase 0.5 acceptance.

Current DataSeeder still alters Projects/ProjectServices and creates DR/AI tables inside a try with swallowed catch; it does not add these thirteen fields. Disabling that competing authority is sufficient before certification; later removal/refactoring of already-disabled legacy code does not create dual authority. Existing/fresh PostgreSQL, column/type/history, entity-query and zero-DDL repeat-startup acceptance remains required. No migration generation or execution was performed.

## Infrastructure drift and credential disposition — PASS

Against historical implementation SHAs, the only non-document additions remain both governance scripts in each repository and the infrastructure analyst helper. The exact frozen candidate includes the helper, and [04_INFRA_DATABASE_PROVISIONING_DISPOSITION.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/04_INFRA_DATABASE_PROVISIONING_DISPOSITION.md) explicitly adopts Option A.

The script creates/alters a login, changes grants/default privileges and uses postgres through docker exec. It is database-access provisioning, not a read-only audit operation. Its fallback password remains in source, but active policy:

1. Classifies it as compromised.
2. Does not reproduce its actual value.
3. Prohibits default/fallback production credentials.
4. Requires rotation/revocation in any environment where used.
5. Assigns structural remediation to Phase 1 MR-02/MR-05/MR-07.

An in-memory literal scan of the five active/review dossier trees found zero occurrences of the actual fallback value; the value was not printed. Execution and rotation remain unverified, correctly distinguished from policy. The helper was not run.

R2-01 parameter validation/dynamic injection is valid Phase 1 follow-up. Later testing must cover authorized use and rejected missing/invalid inputs; its absence as runtime code does not invalidate the Phase 0 disposition.

The closure baseline table still contains earlier candidate HEADs and an unfinished re-freeze placeholder. The user's exact frozen SHA instruction and actual Git verification disambiguate the audited candidate; this metadata imprecision is recorded under C2-04, not treated as unauthorized drift.

## TLS contract — FAIL for residual FR-C2-01 (C2)

The canonical portion passes: 04/05/06/16 now require `SSL Mode=VerifyFull` with trusted CA and hostname verification. The prior misleading Require alternative is absent from active canonical instructions; occurrences in corrective explanations reject it. The Windows reconciliation §5 agrees.

This is a contract check, not a live TLS test. Later acceptance must demonstrate the required peer validation, including rejection of untrusted/wrong-host certificates. [Npgsql security documentation](https://www.npgsql.org/doc/security.html) distinguishes encrypted Require from certificate/hostname-verifying VerifyFull.

Complete closure nevertheless fails: [first remediation Windows:84](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:84) and [re-gate consistency scan:91](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md:91) still positively permit the Require alternative. The final closure consistency scan explicitly treats these dossiers as active. Reconcile or explicitly supersede those instructions; preserve genuinely historical independent reports. The stale examples do not override canonical VerifyFull, so severity remains C2.
