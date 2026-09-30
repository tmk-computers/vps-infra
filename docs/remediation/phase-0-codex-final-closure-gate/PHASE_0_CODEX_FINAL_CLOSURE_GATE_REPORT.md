# Phase 0 Codex final closure gate report

Date: 2026-09-30. Codex Independent Final Audit Gate. This report supersedes the earlier procedural stop through the user's explicit audit-evidence exception.

**PHASE 0 CODEX FINAL CLOSURE GATE: FAIL**

`PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER`

## Frozen candidate verification

| Repository | Frozen and observed HEAD |
|---|---|
| vps-infra | `dea86733d124877e50cea680e9f4c72ad0bc338c` |
| vps-infra-server | `3862f548c64b33260da5a8b278b47a498ad87ae5` |

Tracked state matches HEAD in both repositories. The ten Markdown files in each `phase-0-final-closure-review/` directory are authorized post-freeze external evidence under the user's audit-evidence exception, not part of the Developer candidate. Their names match the expected ten-file set and their bytes match across repositories. No unauthorized candidate drift was listed.

The server emits an access warning for untracked `.pytest_cache/`. No tracked cache files or product/configuration dependency on that path was found; tracked matches were historical audit mentions. Its inaccessible contents are excluded from evidence, as expressly permitted. No cache cleanup, commit, branch change or implementation work was performed.

## Finding closure

Six previous findings rechecked: **4 resolved; 2 unresolved (C2-04 and FR-C2-01, both C2)**. New findings: **C0 0; C1 1; C2 0; C3 0**. The new C1 concerns the revocation visibility contract, not the decision to adopt Redis.

The corrected thirteen-field inventory, DateTime mapping and pre-acceptance seeder neutralization satisfy the schema closure conditions. The analyst script is explicitly incorporated with a compromised-credential policy and Phase 1 ownership; later implementation is not required now. Verifier blind spots were independently reproduced as closed.

Canonical TLS is corrected, but full active-dossier consistency is not. Several evidence corrections also remain inaccurate. Those retain their C2 severities.

## Domain decisions

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

## Material reason for FAIL

The intentional Redis amendment allows negative caching with revocation convergence up to five seconds; the canonical contract simultaneously requires immediate revocation and forbids stale entries from admitting revoked tokens. The documents do not define one acceptance outcome for a request arriving after durable PostgreSQL revocation but before another process observes invalidation.

This does not challenge Redis's first-class role or PostgreSQL durability. It requires a coherent authorization visibility contract. Resolve the effective point, stale-negative handling and failure/test expectations in the specification before Phase 0 closure. Phase 1 will implement and exercise the selected rule.

## Evidence performed

- Exact HEAD and tracked/index integrity checks; narrow external-review/cache exception.
- Source/model inspection for eight Product plus five ProjectService fields, nullability, CLR initializers, type convention, migration/snapshot absence and current seeder behavior.
- Full closure and independent-review dossier reading with canonical/source cross-checks.
- Targeted canonical diff regression check against the prior audited candidate.
- Actual verifier exit 0; eight read-only in-memory fault cases rejected; missing-directory and discovery-target cases additionally verified with actual script exit 1.
- Independent byte hashes for 69 configured documentation pairs plus ten external review pairs and eight prior final re-gate pairs: 87 pairs equal.
- Actual analyst fallback scanned without printing it: zero literal occurrences in the five active/external-review dossier trees.

No live database, Redis, TLS, restore or deployment tests were run. Runtime readiness and credential rotation are not claimed. Git history and input files were not modified; only this nine-file post-freeze audit dossier was created.

## Review disagreement and next action

The review's six-of-six closure claim is not adopted: four close, two C2 findings remain. Its Redis durability/security conclusions are largely supported, but its pass does not resolve the cache visibility inconsistency.

See [findings register](07_FINAL_FINDINGS_REGISTER.md) for the narrowly bounded CG-C1-01 correction and [Redis assessment](04_REDIS_ARCHITECTURE_GATE.md) for the documentary timeline. No broad product redesign is requested. Do not begin Phase 0.5 on this gate result.
