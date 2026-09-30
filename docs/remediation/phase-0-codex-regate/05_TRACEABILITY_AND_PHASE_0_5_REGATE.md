# Traceability, schema authority and pilot prerequisites

Audit date: 2026-09-30. **Traceability FAIL; Phase 0.5 Contract FAIL.** Pilot-prerequisite classification passes.

## Mechanical coverage versus substantive obligations

Independent parsing confirms 37 unique MR IDs, exactly MR-01 through MR-37; 33 OPEN, 3 PARTIALLY_IMPLEMENTED and 1 IMPLEMENTED_NOT_VERIFIED; 14 P0, 21 P1 and 2 P2. The trace table has 63 unique rows: 22 F findings, 37 DEF findings and 4 current-main discoveries. No invalid MR targets were found.

Those facts establish identifier coverage, not full preservation of each source obligation. The original [findings.json](D:/company/products/vps-infra/vps-infra-server/docs/audit/2026-09-29-main/evidence/findings.json) remains the comparison source.

| Source obligation | Credited correction | Remaining issue |
|---|---|---|
| F02 | Token trust matrix now includes issuer/audience/algorithm and revocation concepts | Inconsistent issuer rule and incomplete negative acceptance (C1-01). |
| F15 | Resource state hashes/concurrency, experimental exclusion and idempotency before enabling | No complete re-enable acceptance for execution-time reauthorization, crash reconciliation, or unchanged target across a clock-hour boundary. |
| F16.1 | Encrypted provider keys | Retain original key-rotation acceptance explicitly. |
| F16.2 | Monotonic streaming cap | Preserve atomic reservation/accounting and simultaneous-call acceptance, not only single-stream termination. |
| F16.3 | LocalOnly precedence and Gate-A disablement | Broad obligation preserved. |
| F16.4 | Cloud-fallback authorization/spend recheck | Broad obligation preserved; every provider path remains in scope before enabling. |
| F16.5 | Local model resource-governor admission | Authoritative trace still targets MR-17, not MR-16; preserve missing-telemetry behavior and tests. Mapping precision alone is not a blocker. |
| F22 | Authoritative row preserves tenant cache isolation and actual memory | Original resource-keying, TTL/session bounds and unknown-telemetry fail-closed behavior are incomplete; supplement replaces the source with an unrelated I/O-buffer description. |
| F01 / DEF-08 | External untrusted CI versus privileged management control plane are now distinct | Retain separate completion criteria; external CI does not close management authority. |
| DEF-15 | MR-04, Phase 1, traversal rejection test now explicit | Ownership is adequate; new prefix-check example is unsafe (RG-C1-03). |

A parent MR must not close while applicable child obligations remain omitted. Feature disablement is acceptable for Gate A when all original safety requirements remain explicit re-enable conditions. No extra feature implementation is required now.

## RG-C1-03: reproducible path-containment counterexample

The new example in [06_HISTORICAL_OBLIGATION_RECONCILIATION.md:78](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/06_HISTORICAL_OBLIGATION_RECONCILIATION.md:78) performs GetFullPath/Combine then a case-insensitive string prefix check.

Read-only evaluation using .NET path/string APIs on this Windows host:

| Input/result | Value |
|---|---|
| Tenant root | `C:\inetpub\wwwroot\apps\tenant-a` |
| Supplied absolute path | `C:\inetpub\wwwroot\apps\tenant-ab\artifact.zip` |
| Resolved path | Same sibling-tenant path |
| StartsWith(root, OrdinalIgnoreCase) | **True** |
| Contains '..' | **False** |

No files were opened/written at those example paths. This proves the specified prefix/no-dot-dot check is insufficient, not that a production request was exploited. Use normalized path-segment containment with OS-appropriate comparison and explicit link/reparse policy. Negative acceptance must include sibling prefixes and rooted paths. Existing MR-04/Phase 1 and MR-24/Phase 4 can own the controls.

## RG-C1-02: Phase 0.5 inventory is factually wrong

The new schema document points to `Infrastructure/Entities/MaintenanceWindow.cs` and `ServiceMaintenance.cs`, lists MaintenanceWindows/ServiceMaintenances columns, and treats Products.IsActive/ProjectServices.IsActive as two of the 13 missing fields. Those maintenance entity files are absent. The actual entities are under `Data/Entities`; Product.IsActive already exists and ProjectService inherits IsActive from its base.

The authoritative current-state investigation correctly identifies the real 13 maintenance properties, but roadmap §Phase 0.5, entry criteria §3.1 and Phase 0 final §8.1 repeat the invented MaintenanceWindow scope and point to the faulty acceptance contract.

### Actual source-derived inventory

C# initializers below are observed model behavior, **not proof that matching PostgreSQL defaults already exist**. The migration design must explicitly define backfill/default/nullability semantics and preserve existing data.

| Entity | Property | Source type | C# initial value |
|---|---|---|---|
| Product | IsMaintenance | bool | false |
| Product | MaintenanceMessage | string? | All systems operational. |
| Product | MaintenanceVersion | string? | 1.0.0 |
| Product | MinSupportedVersion | string? | 1.0.0 |
| Product | ShowMaintenanceForMobile | bool | true |
| Product | ShowMaintenanceForWeb | bool | true |
| Product | MaintenanceStartedAt | DateTime? | null |
| Product | MaintenanceEstimatedEndAt | DateTime? | null |
| ProjectService | IsMaintenanceOverride | bool | false |
| ProjectService | IsMaintenance | bool? | null |
| ProjectService | MaintenanceMessage | string? | null |
| ProjectService | ShowMaintenanceForMobile | bool | true |
| ProjectService | ShowMaintenanceForWeb | bool | true |

Sources: [Product.cs:15](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/Product.cs:15) and [ProjectService.cs:36](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/ProjectService.cs:36).

P05-TC03's comparison of all prior row count to `WHERE IsActive = true` is also invalid when inactive rows already exist. Preserve their values; a maintenance migration must not reactivate them.

## C2-01: EF sole authority must be true at acceptance

[Program.cs:417](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Program.cs:417) calls MigrateAsync then DataSeeder. [DataSeeder.cs:46](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs:46) executes ALTER TABLE on Projects and ProjectServices plus CREATE TABLE statements; its own migration block catches errors. R3's description of only idempotent CREATE for Projects/Deployments is inaccurate.

The existing DDL is in the same startup/schema path during Phase 0.5/1. Deferring removal to Phase 2 while calling the seeder data-only does not establish sole authority. Before Phase 0.5 acceptance, remove or disable schema-changing seeder behavior and move any needed legacy responsibility into versioned migration handling for supported starting states. This is a bounded prerequisite; it does not require all MR-13 release-engine work in Phase 0.5.

### Required acceptance contract

| Case | Required proof |
|---|---|
| Supported existing PostgreSQL schema upgrade | Apply versioned migration; inspect all actual 13 columns, types, nullability and intended defaults/backfills. |
| Data preservation | Row identities, values and relationships survive, including inactive rows and existing maintenance values if present. |
| Migration history/model snapshot | Correct history entry and snapshot match actual schema; no fabricated maintenance entities. |
| Product query | Hydrate actual Product entity including maintenance fields without missing-column errors. |
| ProjectService query | Hydrate actual ProjectService entity including maintenance fields without missing-column errors. |
| Fresh install | Migration chain alone creates the supported schema on real PostgreSQL; seeder supplies data only. |
| Repeat migration and startup | No competing DDL or schema changes; history and data remain stable. |

These are future acceptance specifications, not tests executed by Codex in Phase 0.

## C2-02: scope-governed pilot prerequisites — PASS

| MR | Minimum before relevant pilot | Delivery phase retained |
|---|---|---|
| MR-17 | Disable/bound aggressive cleanup; preserve volumes and rollback set | 6 |
| MR-20 | Reject unsupported database engines; Gate-A PostgreSQL profile | 3 |
| MR-21 | Truthful operational disclosure and feature labels | 9 |
| MR-30 | Diagnostic triage runbook/tooling available to pilot support | 8 |
| MR-31 | Assisted support/log collection and operational runbooks | 9 |

The explicit staggered Linux pilot rule and active Windows program remain compatible with these prerequisites. No item is optional forever; Phase 15 requires both operating systems.
