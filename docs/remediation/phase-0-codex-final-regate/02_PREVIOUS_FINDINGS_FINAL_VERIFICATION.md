# Previous findings: final verification

Previous findings: **12 resolved, 4 unresolved**, out of 16. Unresolved: **RG-C1-02 (C1), C2-01 (C2), C2-04 (C2), C3-01 (C3)**. Substantial partial corrections are credited below; FAIL means the original acceptance condition is not fully satisfied.

New findings: **C0: 0; C1: 1; C2: 1; C3: 0**. Retained findings are not counted again as new.

The ten original findings and six re-gate findings retain their original IDs/severities. Two findings already passed in the prior re-gate; their actual criteria are rechecked here. R4 incorrectly relabels C2-02 as count arithmetic and C2-03 as source-claim reconciliation. This audit uses the original register's pilot-prerequisite and historical-verdict criteria.

| Finding | Severity | Previous failure reason | Current authoritative evidence | PASS/FAIL |
|---|---|---|---|---|
| C0-01 | C0 | Unsafe automatic database restore, crash recovery and migration rollback. | 07 §§4–7 and 12 §4 now require compatibility checks, physical fencing, affirmative serving evidence and separately authorized database recovery. | PASS |
| C1-01 | C1 | Issuer rules and negative acceptance cases conflicted. | 08 §4 defines per-service issuer/audience/subject/tenant/scope/algorithm trust, durable revocation and 15 negative tests. | PASS |
| C1-02 | C1 | Archive listing overstated; host-loss kit and failure matrix incomplete. | 09 §§2–6 limit listing to structural evidence, require actual restore, off-host metadata/custody and Phase 5 failure drills. | PASS |
| C1-03 | C1 | Windows topology, TLS and updater recovery contradicted selected architecture. | 04 §4, 05 Windows profile and 16 Phase 4 select IIS/HTTP.sys, authenticated TLS, functional health and reboot recovery. | PASS |
| C1-04 | C1 | IDs existed but F15/F16/F22 obligations were lost. | 03 rows F01/F02/F15/F16/F22/DEF-08/DEF-15 retain substantive acceptance; F16.5 is MR-16. | PASS |
| C2-01 | C2 | Competing seeder DDL could survive Phase 0.5 acceptance. | 10:92, 16:73 and 17:41 now require prior neutralization, but active PHASE_0_FINAL_REPORT:171 still defers raw DDL removal to Phase 2. | FAIL |
| C2-02 | C2 | Minimum pilot prerequisites and staggered qualification needed clarification; already passed re-gate. | 16 requires platform-specific Gate A before pilot, continued Windows work and both OS tracks for Phase 15. | PASS |
| C2-03 | C2 | Separate historical review verdicts needed preservation; already passed re-gate. | Historical review/gate directories remain separate; current commit comparison shows no modifications to already tracked initial review, R3 or original gate reports. | PASS |
| C2-04 | C2 | Unsupported quotations, source descriptions and evidence claims. | 15:31–35 still cite a nonexistent wrapper README; R4 claims static agent secret eliminated despite source fallback; supplementary schema/trace descriptions remain inaccurate. | FAIL |
| C3-01 | C3 | Verifier counted rows without exact IDs/target validation/reverse mirrors. | Exact sets and reverse comparisons now work, but four discovery rows and missing source directories escape checks; scope still excludes R3/R4/Codex dossiers. | FAIL |
| RG-C1-01 | C1 | Redis became mandatory despite Gate-A exclusion. | 08 §4 and 06 database profile make PostgreSQL revocation durable across restart; cache is subordinate; Redis optional. | PASS |
| RG-C1-02 | C1 | Invented maintenance entities and fields drove the migration contract. | Actual count is 8+5, but final baseline summary still names MaintenanceWindow and incorporated inventory contradicts DateTime mapping. | FAIL |
| RG-C1-03 | C1 | Naive prefix check accepted sibling tenant roots. | 08:86–88 binds writes to server-registered authorized roots, with segment/cross-drive/UNC/traversal negatives; R4 filesystem refinements remain Phase 1/4 acceptance. | PASS |
| RG-C2-01 | C2 | Bare LocalService assignment lacked necessary delegated permissions. | 05:66 and 08 agent identity specify dedicated identity, required IIS/filesystem/SCM rights and forbidden unrelated access. | PASS |
| RG-C2-02 | C2 | Zero-data-access claim conflicted with emergency support access. | 08:95–99 distinguishes ordinary access from consent/ticket-bound, audited, time-limited and revoked break-glass access. | PASS |
| RG-C3-01 | C3 | Health defaults were treated as universal constants. | 07 §7 makes health paths, status, timing and thresholds configurable while preserving affirmative verification. | PASS |

## Source hierarchy and references

Current specifications: [07_DEPLOYMENT_SAFETY_CONTRACT.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md), [08_SECURITY_BOUNDARIES.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md), [09_BACKUP_RECOVERY_CONTRACT.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md), [05_SUPPORTED_OS_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md), [03_HISTORICAL_FINDING_TRACEABILITY.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md), [10_MAINTENANCE_MODE_CURRENT_STATE.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md), [16_PHASEWISE_REMEDIATION_PLAN.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md), [17_PHASE_1_ENTRY_CRITERIA.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md).

Historical criteria: [06_REGATE_FINDINGS_REGISTER.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate/06_REGATE_FINDINGS_REGISTER.md). Supplementary remediation is explanatory where consistent, not an override of conflicting canonical text.

## Why the four findings remain open

- **RG-C1-02:** count correctness does not establish type/default/configuration correctness or remove the remaining fictitious entity from the active final report.
- **C2-01:** detailed contracts now correctly neutralize DDL before acceptance. The unreconciled final-summary deferral is the remaining precision contradiction; no present seeder implementation change is demanded during Phase 0.
- **C2-04:** inaccurate citations and claims persist, including a claim that a static fallback disappeared from code when it remains in source. This is evidence correction, not a new demand to implement Phase 1 now.
- **C3-01:** the improved core checks were executed and fault-tested, but the earlier full-scope advisory is not completely closed. This finding alone cannot block Phase 0.

C2-01 and RG-C1-02 share one stale summary location but cover distinct original obligations: sole schema authority versus real field inventory. They are retained findings, not two newly counted defects.
