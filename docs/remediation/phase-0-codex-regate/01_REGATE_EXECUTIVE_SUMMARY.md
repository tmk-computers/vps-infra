# Phase 0 focused re-gate — executive summary

Audit date: 2026-09-30. Independent Codex architecture-contract review. **PHASE 0 CODEX RE-GATE: FAIL**.

The remediation makes real progress: success follows cutover and public verification, roles are separated, backup encryption and off-host custody are specified, the Windows topology is selected, pilot prerequisites are explicit, and review history is restored. The R3 PASS is not sufficient to close the gate because the committed authoritative documents still contain conflicting instructions and missing original acceptance obligations.

## Baseline

| Repository | Frozen implementation SHA | Current documentation/audit HEAD on local main |
|---|---|---|
| vps-infra | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `0d13afa7488fe1d8662f19578d96c1c8d1c39b9f` |
| vps-infra-server | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `69fa124d591f659f8423ab026a12916054bfd86f` |

Both repositories were clean on local `main` before this report set was written. The new commits record the remediation/review dossiers and two governance scripts. A full tracked diff from each implementation baseline, excluding `docs/remediation`, contains only `scripts/verify-baseline-integrity.ps1` and `scripts/mirror-to-infra.ps1`. No runtime, product, database, configuration or test implementation drift was found.

Previous documentation HEADs `72758f6c23fc76e62e059e382cf61106567668ab` and `dba08c63a37eb8d2c851f637d8a02a85cbab4604` remain historical review context, not current HEADs. This assessment is of the committed local-main candidates above; it does not assert a freshly fetched remote state. Git warned that the ignored server `.pytest_cache/` directory was inaccessible; tracked diff/history and dossier verification completed.

## Original and new findings

| Original severity | Resolved | Unresolved |
|---|---:|---:|
| C0 | 0 | 1 |
| C1 | 0 | 4 |
| C2 | 2 | 2 |
| C3 | 0 | 1 |
| Total | 2 | 8 |

New findings: **C0 0; C1 3; C2 2; C3 1**. Retained original findings and new findings are tracked separately; a failed recheck is not a newly discovered finding. RG-C1-02 describes the newly invented schema inventory; C2-01 retains the distinct pre-existing schema-authority issue.

The strongest remaining blocker is explicit: [12_UPGRADE_CURRENT_STATE.md:125](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md:125) still directs automatic restoration of the pre-upgrade database after a health failure, while the corrected release contract prohibits that action. This can overwrite writes made after the snapshot.

Two other direct contradictions are the mandatory Redis denylist despite Redis exclusion and the Phase 0.5 migration inventory for maintenance entities absent from the source. A read-only evaluation also demonstrates that the new path-containment pseudocode accepts a sibling tenant path.

## Domain results

| Contract/domain | Result | Reason |
|---|---|---|
| Release Contract | FAIL | Automatic DB restore remains in upgrade instructions; recovery/fencing/schema compatibility gaps remain (C0-01). |
| Security Contract | FAIL | Inconsistent service-token issuer/negative acceptance; new excluded Redis dependency (C1-01, RG-C1-01). |
| Backup/Recovery | FAIL | Overstated archive validation, incomplete recovery-kit/failure acceptance (C1-02). |
| Windows Architecture | FAIL | Selected topology conflicts with Phase 4 instructions; DB peer trust and upgrade recovery need correction (C1-03). |
| Traceability | FAIL | Missing F15/F16/F22 child obligations; unsafe new path example (C1-04, RG-C1-03). |
| Phase 0.5 Contract | FAIL | Competing seeder schema path and incorrect new field inventory (C2-01, RG-C1-02). |
| Dual-OS | PASS | Equal targets, independent 12A/12B, staggered Linux pilot, unified Phase 15 preserved. |
| Evidence Integrity | FAIL | Historical preservation/mirror/count checks pass; material claim/source precision remains unresolved (C2-04, C3-01). |

## Scope and proportionality

OPEN MRs are not reasons for this FAIL. No implementation, live deployment, migration, recovery drill or infrastructure certification is required in Phase 0. Corrections required here are internally consistent, source-grounded contracts and later-phase acceptance criteria.

Exact health thresholds, a particular atomic cutover mechanism, a named Windows updater executable, BIP-39 as the chosen key-recovery mechanism, and a preferred DEF-15 MR label are not gate conditions. LocalService permission precision and break-glass governance remain C2; application health parameterization remains C3. The Windows verdict is not failed solely on those refinements.

## Decision

**PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER**

Only the eight new documents in this directory were created by this re-gate. Prior reports, authoritative contracts, tooling and implementation were preserved. Phase 0.5 and Phase 1 were not begun.
