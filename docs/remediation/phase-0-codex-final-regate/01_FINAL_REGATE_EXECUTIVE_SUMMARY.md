# Phase 0 final re-gate executive summary

Date: 2026-09-30. Independent audit of specifications and supporting source, not runtime certification.

**PHASE 0 CODEX FINAL RE-GATE: FAIL**

`PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER`

Previous findings: **12 resolved, 4 unresolved**, out of 16. Unresolved: **RG-C1-02 (C1), C2-01 (C2), C2-04 (C2), C3-01 (C3)**. Substantial partial corrections are credited below; FAIL means the original acceptance condition is not fully satisfied.

New findings: **C0: 0; C1: 1; C2: 1; C3: 0**. Retained findings are not counted again as new.

The C0 release blocker and all four original C1 contracts are corrected at the architectural level. This is substantial progress. R4's assertion that all sixteen findings are resolved is not supported by the complete canonical document set.

The remaining acceptance-blocking schema issue is narrow and concrete: [PHASE_0_FINAL_REPORT.md:171](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md:171) still prescribes a migration involving nonexistent `MaintenanceWindow`; the source-derived inventory specifies timezone-aware timestamps despite the EF convention configuring timestamps without time zone. The same summary still places raw DDL removal in Phase 2.

Latest infrastructure main also includes commit `10a2e77`, adding `db/postgres/create-readonly-analyst.sh`. This provisions a database login and grants using a hardcoded fallback password. It is database/security implementation drift, not audit tooling. The submitted reconciliation contains no disposition or authorization evidence for this delta. This audit does not assert that the user never authorized it elsewhere, or that it was executed.

## Baseline

| Repository | Expected implementation baseline | Audited main HEAD |
|---|---|---|
| vps-infra | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `174869490596c1eee07366590dbd8e1c46df5b71` |
| vps-infra-server | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `76b4bcb97dda098ff15a4fc9be4844746b6989be` |

These are the local main candidates inspected on 2026-09-30. HEAD advanced during the audit; the final decision uses the above commits, not the older HEADs quoted in R4. No fetch, deployment, database connection, migration, or production test was performed.

## Domain decisions

| Contract / gate | Decision | Basis |
|---|---|---|
| Release contract | PASS | Durable intent, verification, fencing, schema compatibility and separate database recovery |
| Security contract | PASS | Service-specific trust, tenant boundaries, negative tests and break-glass governance |
| Redis exclusion | PASS | Optional / Not Gate-A Certified Dependency; PostgreSQL-backed revocation |
| Path containment | PASS | Authorized server-registered root; segment checks; later-phase filesystem defenses |
| Backup/recovery contract | PASS | Restore drills, independently recoverable kit, failure matrix and measured targets |
| Windows architecture | PASS | Native IIS/HTTP.sys, least-privilege agent, authenticated database TLS invariant |
| Phase 0.5 schema contract | FAIL | Active summary still contradicts corrected inventory/authority; inventory types are wrong |
| Traceability | PASS | Canonical obligations restored, including F16.5 → MR-16 |
| Evidence integrity | FAIL | Incorrect source claims, incomplete tooling coverage and unaccounted implementation drift |
| Dual-OS | PASS | Independent 12A/12B Gate A; staggered Linux pilot; unified Phase 15 Gate B |

## Required return to Developer

1. Reconcile the active final summary and incorporated inventory with real entity/model configuration; retain neutralization of seeder DDL before Phase 0.5 acceptance.
2. Account for the infrastructure database-script commit through an explicit reviewed baseline exception or a correctly scoped candidate. Review its credential behavior. Do not label the current candidate documentation-only.
3. Append an evidence correction covering inaccurate source quotations, schema/trace descriptions, and R4 implementation claims. Preserve historical reports.
4. Complete or narrow the verifier's claims and scope; C3 remains advisory.

No Phase 0.5 or Phase 1 work was started. Only these eight new audit reports were authored. See [findings register](06_FINAL_FINDINGS_REGISTER.md) for exact closure conditions.
