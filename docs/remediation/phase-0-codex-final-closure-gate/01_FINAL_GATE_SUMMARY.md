# Final Phase 0 closure gate summary

Date: 2026-09-30. Scope: focused closure verification of the exact frozen candidate and intentional Redis amendment; no broad product audit.

**PHASE 0 CODEX FINAL CLOSURE GATE: FAIL**

`PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER`

Six previous findings rechecked: **4 resolved; 2 unresolved (C2-04 and FR-C2-01, both C2)**. New findings: **C0 0; C1 1; C2 0; C3 0**. The new C1 concerns the revocation visibility contract, not the decision to adopt Redis.

## Frozen candidate verification

| Repository | Frozen and observed HEAD |
|---|---|
| vps-infra | `dea86733d124877e50cea680e9f4c72ad0bc338c` |
| vps-infra-server | `3862f548c64b33260da5a8b278b47a498ad87ae5` |

Tracked state matches HEAD in both repositories. The ten Markdown files in each `phase-0-final-closure-review/` directory are authorized post-freeze external evidence under the user's audit-evidence exception, not part of the Developer candidate. Their names match the expected ten-file set and their bytes match across repositories. No unauthorized candidate drift was listed.

The server emits an access warning for untracked `.pytest_cache/`. No tracked cache files or product/configuration dependency on that path was found; tracked matches were historical audit mentions. Its inaccessible contents are excluded from evidence, as expressly permitted. No cache cleanup, commit, branch change or implementation work was performed.

## Decision

The previous schema and infrastructure-drift blockers are resolved. Redis 7 is accepted as an intentional first-class component, with PostgreSQL retaining durable safety-critical truth. Redis security ownership, failure scenarios, Windows centralized consumption and future AI boundaries are specified.

One material ambiguity prevents closure: the Redis amendment permits negative caching and bounded revocation propagation up to five seconds, while canonical security requires immediate revocation and says stale cache entries must not admit revoked credentials. The acceptance documents do not define one observable rule for requests between durable revocation commit and cache invalidation. This is new **CG-C1-01**, a specification issue rather than a demand for Phase 1 implementation.

C2-04 remains open for inaccurate evidence. FR-C2-01 is partially corrected: canonical VerifyFull is correct, but two active supplementary instructions retain the misleading alternative. Neither C2 is independently promoted to a blocker.

| Gate | Decision |
|---|---|
| Frozen candidate / authorized evidence exception | PASS |
| Phase 0.5 schema contract | PASS |
| Evidence integrity | FAIL — retained C2-04 |
| Infrastructure drift disposition | PASS |
| TLS contract | FAIL — canonical corrected, active supplementary alternatives remain (C2) |
| Redis architecture overall | FAIL — CG-C1-01 |
| Redis durable-state boundary | PASS |
| Redis failure model | FAIL — stale security-cache case ambiguous |
| Redis security specification | PASS |
| Redis Gate-A testability | FAIL — six scenarios exist, but revocation acceptance differs |
| AI Workforce boundary | PASS |
| Verifier / mechanical evidence | PASS within declared scope |
| Regression check | FAIL for revocation semantics; other accepted domains preserved |
| Dual-OS contract | PASS |

## Required closure correction

Define a single revocation-effective point and acceptance behavior across local cache, Redis and PostgreSQL, including lost invalidation and outages. If cache convergence is asynchronous, distinguish it explicitly from the point after which requests must be denied; do not let a stale “not revoked” hit satisfy that denial contract. If a bounded acceptance window is intentionally authorized, reconcile the strict canonical rules and test expectations explicitly.

No particular cache algorithm, lock library or TTL value is mandated by this audit. No Phase 0.5 or Phase 1 implementation was started. See [findings register](07_FINAL_FINDINGS_REGISTER.md).
