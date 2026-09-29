# Phase 0 Codex gate — executive summary

Audit date: 2026-09-29. Independent final audit; implementation read-only. Only this new gate dossier is authored.

# PHASE 0 CODEX GATE: FAIL

PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER

The candidate preserves both first-class OS targets and fixes the previous arithmetic inconsistencies. Its 37 open/partial/unverified implementation findings are not themselves a reason to reject Phase 0. Rejection is based on defects in the proposed authoritative baseline: unsafe/ambiguous release transitions, incomplete recovery safeguards, contradictory security acceptance, undefined Windows component topology, and loss of obligations within otherwise complete ID mappings.

| Gate | Verdict | Basis |
|---|---|---|
| Implementation baseline | PASS | Only expected documentation changed |
| ID coverage | PASS | F01–F22: 22/22; DEF-01–DEF-37: 37/37; current-main: 4/4; MR: 37/37 |
| Substantive traceability | CORRECTION REQUIRED | IDs exist, but some source obligations are lost or conflated (C1-04) |
| Register mathematics | PASS | All requested status, severity and blocker totals reproduce |
| Dual-OS mandate | PASS | Equal targets and independent Gate A retained; no runtime certification |
| Architecture freeze | FAIL | Release/recovery/security contracts and Windows topology need correction |
| Phase 0.5 | CORRECTION REQUIRED | Sequencing justified; schema authority/temporary exception needs clarity |
| Phase 1 scope | CORRECTION REQUIRED | Nine-item security scope is coherent; acceptance contracts need correction |
| Product runtime readiness | NOT CERTIFIED | Outside this documentary acceptance gate |

## Evidence and baseline

Reviewed 59 historical audit Markdown files (reviewed earlier in this conversation and reused as historical evidence), all 20 current Developer artifacts, and all 17 Reviewer artifacts. The 37 Developer/Reviewer files are mirrored byte-for-byte across repositories. Full historical reconstruction was not repeated; disputed claims and current-main deltas were checked against source. The 96 canonical document hashes are recorded in report 02.

| Repository | Branch | Implementation baseline | Local documentation HEAD |
|---|---|---|---|
| vps-infra | main | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `72758f6c23fc76e62e059e382cf61106567668ab` |
| vps-infra-server | main | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `dba08c63a37eb8d2c851f637d8a02a85cbab4604` |

Historical audited SHAs: infra `eab8df65aaf708875a922cf87c655d86156f402a`; server `a1f4a51ed3fb9e9751f83ec191a29f04e6971d32`.

Each local HEAD adds one documentation-only commit after the implementation baseline. Each repository also has 12 modified Phase 0 Markdown files. The gate evaluates those working-tree corrections, not just committed documents. Baseline-to-working-tree tracked diffs outside `docs/remediation/` are empty in both repositories. No runtime/product/configuration/test drift was found. No fresh remote HEAD claim is made by this gate; remote-tracking refs are not live remote proof. The server status command warns that `.pytest_cache/` is inaccessible; ignored cache contents were not inspected.

## Counts

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

## Codex findings

C0: **1**. C1: **4**. C2: **4**. C3: **1**. Total: **10**. Full claim, evidence, impact, correction and acceptance for every finding are in [06_CODEX_FINDINGS_REGISTER.md](06_CODEX_FINDINGS_REGISTER.md).

| ID | Severity | Finding |
|---|---|---|
| C0-01 | C0 | Release contract permits unsafe completion and database rollback |
| C1-01 | C1 | Security acceptance contradicts platform/tenant role separation and omits token trust rules |
| C1-02 | C1 | Recovery contract is incomplete and mixes incompatible archive verification rules |
| C1-03 | C1 | Windows Server control-plane and PostgreSQL topology is not frozen |
| C1-04 | C1 | Complete ID coverage hides lost or conflated remediation obligations |
| C2-01 | C2 | Phase 0.5 is justified, but its schema-authority exception is undefined |
| C2-02 | C2 | Blocker labels and roadmap dependencies describe different pilot boundaries |
| C2-03 | C2 | Repository dossier does not contain the reported final reviewer PASS |
| C2-04 | C2 | Some evidence wording and citations still overstate what was verified |
| C3-01 | C3 | Generate register summaries and candidate manifests mechanically |

The supplied task reports an independent reviewer PASS. The local reviewer dossier still contains its original FAIL with conditional future PASS language. This evidence mismatch is recorded as C2-03, not treated as proof that no external re-review occurred and not used as the sole failure reason.

## Required next action

Return the documented baseline corrections to the Developer, then obtain independent re-review and rerun this gate against a hash-identified candidate. No code fixes, Phase 0.5 work, Phase 1 work, migrations, deployments, credential revocations, history rewrites or live restore tests were performed.
