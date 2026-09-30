# Phase 0 Codex final re-gate report

Date: 2026-09-30. Auditor: Codex Independent Final Audit Gate.

**PHASE 0 CODEX FINAL RE-GATE: FAIL**

`PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER`

## Baseline

| Repository | Expected implementation baseline | Audited main HEAD |
|---|---|---|
| vps-infra | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `174869490596c1eee07366590dbd8e1c46df5b71` |
| vps-infra-server | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `76b4bcb97dda098ff15a4fc9be4844746b6989be` |

These are the local main candidates inspected on 2026-09-30. HEAD advanced during the audit; the final decision uses the above commits, not the older HEADs quoted in R4. No fetch, deployment, database connection, migration, or production test was performed.

The server delta remains documentation plus governance tooling. Infrastructure additionally contains database provisioning script commit `10a2e77`; this is new FR-C1-01 and prevents confirming the supplied implementation freeze.

## Previous Codex findings

Previous findings: **12 resolved, 4 unresolved**, out of 16. Unresolved: **RG-C1-02 (C1), C2-01 (C2), C2-04 (C2), C3-01 (C3)**. Substantial partial corrections are credited below; FAIL means the original acceptance condition is not fully satisfied.

New findings: **C0: 0; C1: 1; C2: 1; C3: 0**. Retained findings are not counted again as new.

All sixteen original acceptance conditions were rechecked. The original release C0 and four original C1 contracts now pass. The field inventory remains materially inconsistent; the authority summary, evidence claims and verifier advisory are not fully reconciled. See [all sixteen dispositions](02_PREVIOUS_FINDINGS_FINAL_VERIFICATION.md).

## Contract decisions

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

## Material basis for disagreement with R4

1. Canonical PHASE_0_FINAL_REPORT.md:171 still targets nonexistent MaintenanceWindow and an obsolete migration contract. The incorporated thirteen-field inventory also conflicts with the EF DateTime convention. R4 checked the correct count but overclaimed complete source/model alignment.
2. Latest main contains a database-access provisioning helper outside the frozen implementation baseline. The R4 snapshot predates this delta. No corresponding reviewed exception was found.
3. Evidence errors survive, including nonexistent quote-source paths and a false statement that the static Windows agent fallback was already removed from code.
4. The verifier's improved mechanical checks pass the real inputs and reject several injected faults, but omit current discovery-row targets and silently skip a missing source dossier. This remains advisory, not an independent blocker.

## What is accepted

The contract now separates application rollback from database restore, preserves migration compatibility with rollback candidates, and requires fencing and affirmative post-cutover serving evidence. PostgreSQL revocation removes the Redis contradiction. Backup recovery requires real restore proof and independently recoverable custody. Windows uses native IIS/HTTP.sys with explicit identity permissions and authenticated transport. Canonical historical obligations and separate OS certification gates are preserved.

These PASS decisions certify specification readiness in their domains, not current implementation. No new universal health threshold, mandatory updater binary, BIP-39 choice or early filesystem implementation has been imposed.

## Audit execution and limitations

The actual baseline verifier exited 0 with 37 MR/22 F/37 DEF IDs, 33/3/1 statuses and 59 byte-identical mirrored documents. Read-only fault injection verified rejection paths; two blind spots were reproduced. The independent 94-file manifest shows 76 byte-identical pairs and 18 newline-only differences; all normalized text matches.

Source inspection verified eight Product and five ProjectService maintenance fields, their nullability/initializers, DateTime configuration, absence from repository migrations/snapshot, current seeder DDL and existing IsActive treatment. No live database history, migration execution, restore, Windows lab or deployment test was performed.

Only the eight reports in this new server directory were written. Historical reports and implementation files were not changed. Neither Phase 0.5 nor Phase 1 was started.

## Return package

[Findings and objective closure conditions](06_FINAL_FINDINGS_REGISTER.md), [release/security/recovery](03_RELEASE_SECURITY_RECOVERY_FINAL_GATE.md), [Windows/schema/traceability](04_WINDOWS_SCHEMA_TRACEABILITY_FINAL_GATE.md), [evidence and verifier results](05_EVIDENCE_AND_CONSISTENCY_FINAL_GATE.md), [manifest and navigation](README.md).
