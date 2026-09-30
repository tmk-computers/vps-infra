# Final closure gate findings register

Date: 2026-09-30. C0: critical architecture/safety blocker. C1: material Phase 0 closure blocker. C2: precision/consistency. C3: advisory.

Six previous findings rechecked: **4 resolved; 2 unresolved (C2-04 and FR-C2-01, both C2)**. New findings: **C0 0; C1 1; C2 0; C3 0**. The new C1 concerns the revocation visibility contract, not the decision to adopt Redis.

## Previous finding disposition

| Finding | Previous severity | Closure condition | Independent evidence | Final verdict |
|---|---|---|---|---|
| RG-C1-02 | C1 | Real 8+5 fields, configured timestamp types/default distinctions; remove invented schema targets. | Product.cs:15–22, ProjectService.cs:36–40, ApplicationDbContext.cs:44–46; canonical final report:170; closure schema §3; revised inventory §3. | PASS |
| C2-01 | C2 | Neutralize competing seeder DDL before Phase 0.5 acceptance; only unrelated work remains later. | Canonical final report:170, maintenance §3, roadmap:73 and entry criteria:41 agree on prior disablement/removal. | PASS |
| C2-04 | C2 | Correct source citations/descriptions, append historical corrections and avoid overclaiming evidence. | Wrapper README and Windows-secret reality corrected; closure evidence §2.4 still misstates F02/F15; truth matrix has a missing cleanup-script citation; reviewer master report has incorrect paths, types and metrics. | FAIL |
| C3-01 | C3 | Fail missing dossiers/discovery targets; explicitly bound mirror and phrase-check coverage. | Verifier exact sets/status/targets; 69 byte-identical files; independent missing-directory/discovery-target injections now fail. | PASS |
| FR-C1-01 | C1 | Account for database helper and credential risks under an explicit candidate disposition. | Option A in closure disposition; helper tracked in exact candidate; compromised fallback redacted from active evidence, rotation/revocation mandated where used, Phase 1 dynamic-credential ownership. | PASS |
| FR-C2-01 | C2 | Use peer-authenticated PostgreSQL TLS; remove misleading Require alternative. | Canonical architecture/OS/database/roadmap require VerifyFull, but active remediation Windows:84 and regate consistency scan:91 retain the misleading Require alternative. | FAIL |

The original IDs and criteria are retained. In particular C2-01 is schema authority, C2-04 is evidence integrity, and C3-01 is tooling; the review master report's relabelled versions are not substituted.

## CG-C1-01 — revocation visibility has conflicting acceptance rules

**Severity:** C1. **Status:** OPEN. **Owner:** Phase 0 architecture/specification correction, with Phase 1 implementation under MR-36 and the shared security owners.

**Evidence:**

- [canonical security:118](../phase-0/08_SECURITY_BOUNDARIES.md) promises immediate tenant revocation.
- [canonical security:147](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:147) requires revoked credentials to return 401.
- [database/cache contract:81](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md:81) prohibits stale cache admission of revoked credentials.
- [Redis amendment:110](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md:110) commits revocation in PostgreSQL before subsequent publication/invalidation.
- [amendment:124](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md:124) allows negative-cache state and up to five seconds of propagation.
- [amendment stale-cache scenario:154](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md:154) uses bounded-window rejection alongside immediate invalidation language.

**Counterexample:** A token is cached as not revoked; PostgreSQL then commits revocation; another process's invalidation is delayed; a request arrives before its negative-cache TTL/propagation bound expires. The documents do not give one consistent observable decision. The canonical rule demands denial, while the bounded-propagation read-cache contract permits an implementation that denies only after convergence.

**Impact:** Two materially different authorization behaviors can claim compliance. Durable truth surviving Redis loss does not prove every authorization decision observes that truth. The issue exists in the specification, independently of whether Redis is implemented yet.

**Required correction:** Define the revocation-effective point and response behavior before/after it. Align PostgreSQL commit, reported revocation success, cached-negative freshness and per-instance enforcement. Specify behavior for missed invalidation, Redis partition, process restart, stale local hits and inability to validate against the durable authority. Fail closed whenever the selected contract cannot be established.

**Acceptance:** One consistent oracle governs the canonical token tests and all six Redis scenarios. A test can present a token before, at and after the effective point, inject stale entries/missed invalidation on another instance, and determine the required HTTP result unambiguously. An explicit bounded model requires explicit reconciliation of immediate/no-stale-admission promises; an immediate model cannot accept stale negatives after its effective point. No specific cache implementation is required during Phase 0.

**Why this blocks:** Safety-critical authorization ambiguity is expressly a Phase 0 failure condition. Redis adoption, future implementation, and selection of a reasonable latency/TTL target are not themselves defects.

## Retained C2-04 — evidence precision not fully closed

The actual canonical source/targets are usable, but supplementary evidence still misidentifies F02/F15, preserves stale candidate/Redis statements, and overclaims corrections. Canonical truth matrix retains a nonexistent cleanup-script citation. The external review master report also contains invented paths, a wrong nullable type and wrong metrics/tool scope.

**Closure:** Correct active source descriptions and append corrections to historical independent evidence. Keep current implementation, target contract, planned tests and executed evidence separate. See report 06 for the exact error/correction table. These are retained C2 issues, not new C1 blockers.

## Retained FR-C2-01 — active TLS alternatives survive

Canonical architecture correctly requires VerifyFull. However, active first-remediation Windows:84 and re-gate consistency scan:91 still permit Require/Trust Server Certificate=false with a CA. The final closure scan includes both dossiers in its active scope.

**Closure:** Reconcile these positive alternative instructions or explicitly supersede them with the canonical VerifyFull rule. Do not rewrite immutable historical review reports. Severity remains C2 because the authoritative security invariant and corrected canonical example are already sound.

## Reviewer carry-forwards

- **R2-01:** Phase 1 analyst-helper input validation and dynamic credentials are appropriate, non-blocking implementation acceptance work. This gate does not certify the current helper as production-safe.
- **R3-01:** Phase 5 periodic synthetic DR drills are appropriate advice. Use canonical backup/recovery owners MR-14/MR-15 and the actual documented RPO/RTO targets; the review register's MR-24/MR-25 and four-hour RTO are inaccurate.

Neither carry-forward is promoted to a new Phase 0 blocker.

## Final decision

**PHASE 0 CODEX FINAL CLOSURE GATE: FAIL**

`PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER`

The remaining C0/C1 blocker is CG-C1-01. The two previous C1 findings are closed. No product fix, migration, Redis rollout, credential rotation or Phase 0.5/1 implementation was performed.
