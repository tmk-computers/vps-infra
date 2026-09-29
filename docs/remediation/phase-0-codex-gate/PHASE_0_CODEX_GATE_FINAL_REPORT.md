# Phase 0 Codex gate final report

Date: 2026-09-29. Role: independent final adversarial audit. Implementation remained read-only.

## Baseline

| Repository | Branch | Implementation baseline | Local documentation HEAD |
|---|---|---|---|
| vps-infra | main | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `72758f6c23fc76e62e059e382cf61106567668ab` |
| vps-infra-server | main | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `dba08c63a37eb8d2c851f637d8a02a85cbab4604` |

Historical audited SHAs: infra `eab8df65aaf708875a922cf87c655d86156f402a`; server `a1f4a51ed3fb9e9751f83ec191a29f04e6971d32`.

Each local HEAD adds one documentation-only commit after the implementation baseline. Each repository also has 12 modified Phase 0 Markdown files. The gate evaluates those working-tree corrections, not just committed documents. Baseline-to-working-tree tracked diffs outside `docs/remediation/` are empty in both repositories. No runtime/product/configuration/test drift was found. No fresh remote HEAD claim is made by this gate; remote-tracking refs are not live remote proof. The server status command warns that `.pytest_cache/` is inaccessible; ignored cache contents were not inspected.

## Evidence Reviewed

**59 audit Markdown files, 20 Developer artifacts, 17 Reviewer artifacts.** Historical audits were reviewed earlier in this conversation and reused; all current Developer/Reviewer inputs were read, with targeted source verification rather than rerunning the whole forensic audit. Their 37 mirrored copies match. [Report 02](02_BASELINE_AND_TRACEABILITY_GATE.md) records the 96 canonical SHA-256 hashes and verification observations.

The supplied request describes an independent re-review PASS, but the local Reviewer final report/README still record FAIL. That absence of a stored PASS is C2-03; the gate proceeds on independently verified corrected content and does not infer that the external re-review never occurred.

## Traceability

- **F01–F22: 22/22 ID coverage.**
- **DEF-01–DEF-37: 37/37 ID coverage.**
- **Current-main MR-34–MR-37: 4/4.**
- **MR-01–MR-37: 37/37 unique rows.**
- No ID silently disappears; however, substantive obligation preservation needs correction. F16's privacy/fallback/resource requirements and the distinction between F01's CI worker and DEF-08's management API are not adequately carried through to phase closure. See C1-04.

## MR Counts

| Measure | Independently counted |
|---|---:|
| OPEN | 33 |
| PARTIALLY_IMPLEMENTED | 3 |
| IMPLEMENTED_NOT_VERIFIED | 1 |
| CLOSED_WITH_EVIDENCE | 0 |
| Total MR rows | 37 |
| P0 | 14 |
| P1 | 21 |
| P2 | 2 |
| Shared technical pilot blockers | 17 |
| Linux-specific technical pilot blockers | 6 |
| Windows-specific technical pilot blockers | 8 |
| Cross-platform certification blocker | 1 |
| Total classified blockers | 32 |
| Scope-governed/later-phase items | 5 |

Partially implemented: MR-14, MR-17, MR-30. Implemented, not verified: MR-18. Scope-governed: MR-17, MR-20, MR-21, MR-30, MR-31. The two incorrect historical assertions are reconciliation metadata, not additional MR rows.

Arithmetic passes. Severity escalation from historical P1 to MR P0 is a current prioritization decision, not evidence of new exploitation. The five scope-governed items retain pre-pilot operational obligations; “post-pilot” terminology must not authorize omission.

## Dual-OS Gate

**PASS — mandate only.** Equal first-class Ubuntu 24.04 LTS and Windows Server 2022 targets, independent Gate A and joint Phase 15 commercial gate are retained. Neither runtime is certified. Windows topology remains an architecture correction.

## Architecture Gate

**FAIL.** One acceptance-blocking release-contract defect and four significant baseline corrections remain:

1. Release success/cutover, persistence/idempotency and database rollback semantics are unsafe or ambiguous.
2. Tenant SuperAdmin acceptance and token trust criteria conflict with the security architecture.
3. Backup encryption/key recovery, recovery points, retention and format-aware verification are incomplete.
4. Windows control-plane/PostgreSQL/ingress/upgrade topology is undefined.
5. ID mappings do not preserve all underlying historical obligations.

The intended core/adapter separation, external CI boundary, PostgreSQL-only Gate-A profile, deterministic safety and compiled Windows service direction are reasonable. They need coherent contracts, not additional platform sophistication.

## Phase 0.5 Assessment

**CORRECTION REQUIRED.** MR-34 legitimately precedes Phase 1 database integration validation. Thirteen properties lack tracked creation coverage; affected queries can produce SQLSTATE 42703 and application errors, not a PostgreSQL server crash. Specify one schema authority or a bounded temporary seeder exception, update stale phase labels and define real PostgreSQL acceptance. No migration was executed.

## Phase 1 Scope Assessment

**CORRECTION REQUIRED.** The nine MR items form a coherent security phase. Preserve token trust and tenant-role boundaries; define Windows/service-to-service authentication for the future agent without substantially productionizing the legacy daemon. Redis hardening is not Redis certification. See [Report 03](03_SECURITY_AND_TRUST_GATE.md).

## Codex Findings

| Classification | Count |
|---|---:|
| C0 | 1 |
| C1 | 4 |
| C2 | 4 |
| C3 | 1 |
| Total | 10 |

All findings, including exact artifacts/claims, source evidence, impact, correction and acceptance criteria, are in [06_CODEX_FINDINGS_REGISTER.md](06_CODEX_FINDINGS_REGISTER.md). Open implementation defects alone did not drive this result.

## Validation and limits

Read-only Git/diff/hash checks; current source and historical evidence comparison; non-executing PowerShell AST parse; in-memory maintenance regex reproduction. No full test-suite pass, live OS certification, SCM/network reproduction, migration/restore, credential validity test or remote infrastructure access is claimed. Two narrow primary documentation checks support PostgreSQL archive-format and Docker Desktop Windows Server support findings; links are in Reports 04 and 06.

Only the eight requested gate Markdown files were created under this new directory. Existing Developer/Reviewer documents, runtime/config/test code and repository history were not modified. The pre-existing 12 modified Developer files in each repository were preserved.

## Final Verdict

# PHASE 0 CODEX GATE: FAIL

PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER

Correct the baseline and resubmit for independent re-review and Codex acceptance. Phase 0.5 and Phase 1 have not begun.
