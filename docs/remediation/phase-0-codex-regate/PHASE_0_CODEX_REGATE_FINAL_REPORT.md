# Phase 0 Codex focused re-gate — final report

Audit date: 2026-09-30. Scope: original ten acceptance criteria, corrected authoritative Phase 0 contracts, Developer remediation dossier, R3 review, and material defects introduced by remediation. Implementation remained read-only.

## Baseline

| Repository | Frozen implementation SHA | Current documentation/audit HEAD on local main |
|---|---|---|
| vps-infra | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `0d13afa7488fe1d8662f19578d96c1c8d1c39b9f` |
| vps-infra-server | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `69fa124d591f659f8423ab026a12916054bfd86f` |

Both repositories were clean on local `main` before this report set was written. The new commits record the remediation/review dossiers and two governance scripts. A full tracked diff from each implementation baseline, excluding `docs/remediation`, contains only `scripts/verify-baseline-integrity.ps1` and `scripts/mirror-to-infra.ps1`. No runtime, product, database, configuration or test implementation drift was found.

Previous documentation HEADs `72758f6c23fc76e62e059e382cf61106567668ab` and `dba08c63a37eb8d2c851f637d8a02a85cbab4604` remain historical review context, not current HEADs. This assessment is of the committed local-main candidates above; it does not assert a freshly fetched remote state. Git warned that the ignored server `.pytest_cache/` directory was inaccessible; tracked diff/history and dossier verification completed.

Both audit scripts are tracked in both current commits. The verifier was inspected and executed read-only; it exited 0. The mirror script copies/overwrites governance documents and was inspected only. Their existence is authorized tooling, not product implementation drift.

## Original Codex Findings

| Original severity | Resolved | Unresolved |
|---|---:|---:|
| C0 | 0 | 1 |
| C1 | 0 | 4 |
| C2 | 2 | 2 |
| C3 | 0 | 1 |
| Total | 2 | 8 |

New findings: **C0 0; C1 3; C2 2; C3 1**. Retained original findings and new findings are tracked separately; a failed recheck is not a newly discovered finding. RG-C1-02 describes the newly invented schema inventory; C2-01 retains the distinct pre-existing schema-authority issue.

Resolved: **C2-02, C2-03**.

Unresolved: **C0-01; C1-01, C1-02, C1-03, C1-04; C2-01, C2-04; C3-01**. Original severities are preserved. Full original acceptance criteria, current evidence and results appear in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md).

## New Findings

| Severity | Count | IDs |
|---|---:|---|
| C0 | 0 | None |
| C1 | 3 | RG-C1-01 Redis dependency; RG-C1-02 wrong schema inventory; RG-C1-03 unsafe path-prefix check |
| C2 | 2 | RG-C2-01 Windows identity permissions; RG-C2-02 privileged break-glass precision |
| C3 | 1 | RG-C3-01 application health parameterization |

The new C1 findings concern concrete newly introduced instructions, not architectural preferences. C2/C3 entries track R3 refinements and do not independently fail the gate.

## Release Contract

**FAIL.** Cutover and public verification now precede SUCCEEDED. Idempotency, immutable identity and standby retention are credited. However, the authoritative upgrade specification still automatically restores the pre-upgrade database on health failure. Pre-cutover crash rules conflict with irreversible migration handling, schema contraction can invalidate the rollback binary, and database optimistic concurrency alone does not specify physical stale-worker exclusion.

Required closure is one coherent deployment/upgrade/recovery contract with documented safe outcomes. No new implementation, exact probe thresholds or particular cutover technology is required in Phase 0.

## Security Contract

**FAIL.** PlatformSuperAdmin and TenantAdmin separation is corrected; token trust fields and negative tests are substantially improved. The universal issuer rule conflicts with the CI/AMS issuer matrix, original wrong-issuer/retired-key/wrong-scope negative criteria are incomplete, and the authoritative token table requires Redis despite Gate-A exclusion.

Transport mTLS and scoped request authorization are correctly distinct. Final compiled Windows authentication remains Phase 4; Phase 1 is reusable contract/minimal containment work. Break-glass wording is a C2 refinement, not independently a blocker.

## Backup/Recovery

**FAIL.** Encryption, off-host custody intent, remote digests, catalog and retention are now specified. The contract still overstates pg_restore --list, leaves recoverable key-derivation/complete recovery dependencies insufficiently documented, and lacks the original complete failure acceptance matrix. BIP-39 itself is neither required nor rejected by this gate. The required invariant is tested recovery after total source-host loss.

RPO 24h/1h and RTO 30 minutes are later-validation targets. Actual restore and both-OS failure drills remain mandatory later; none were run here.

## Windows Architecture

**FAIL.** Native Windows Server 2022/IIS 10/HTTP.sys/ANCM, compiled agent, remote PostgreSQL 16 and Linux control-plane placement are now explicit. Remaining conflicts are host-Traefik coexistence in Phase 4 acceptance, an unauthenticated database TLS option, and unincorporated functional-health/reboot-update recovery acceptance.

The LocalService permission refinement remains C2. A particular named updater executable is not required.

## Traceability

**FAIL.** All 37 MRs and all historical finding IDs exist. Broad F16 child obligations, separate F01/DEF-08 controls, and DEF-15 owner/phase/test are credited. F15/F16/F22 source acceptance obligations remain incompletely preserved, and the new path example demonstrably accepts a sibling tenant prefix. F16.5 still maps to MR-17 in the authoritative trace, but mapping precision alone is not the reason for FAIL.

## Phase 0.5 Contract

**FAIL.** The new 13-field inventory describes nonexistent maintenance entities and unrelated fields; the authoritative roadmap/entry criteria repeat this scope. Correct it to the actual eight Product and five ProjectService maintenance properties. EF migrations must be the sole schema authority at acceptance; the existing seeder DDL cannot remain an active competing schema path while being described as data-only.

Require real PostgreSQL existing/fresh/repeat-startup verification, actual entity hydration, all field/default/nullability checks, snapshot/history consistency and preservation of existing values. This is a specification correction; Phase 0.5 was not started.

## Dual-OS

**PASS.** Ubuntu 24.04 LTS and Windows Server 2022 remain equal first-class targets. Phase 12A and 12B certify independently. Linux pilot may proceed after Linux Gate A while Windows continues. Phase 15 remains the unified Dual-OS Commercial Gate.

## Evidence Integrity

**FAIL for complete evidentiary acceptance; preservation and mechanical candidate identity pass.**

- All eight original Codex gate reports retain their content; original Reviewer report hashes match the prior gate manifest. R2 PASS and R3 PASS are separately committed.
- All **65 dossier files** have equal SHA-256 hashes in the two repositories; the candidate input manifest is in [README.md](README.md).
- Independent parsing confirms **37 unique MR IDs**, **33 OPEN / 3 PARTIAL / 1 IMPLEMENTED_NOT_VERIFIED**, **14 P0 / 21 P1 / 2 P2**, and **63 unique trace rows** with valid MR targets.
- The provided verifier exits 0 and checks 48 mirrored Markdown files, but lacks distinct-ID/target/reverse-file-set checks. It does not establish full source-obligation completeness.
- Incorrect source descriptions, unsupported timing assertions and misleading verification claims remain. Static inspection is not live certification.

## Required correction order

1. Reconcile release/upgrade restore, ownership and migration compatibility rules.
2. Correct token issuer/negative-test contracts and remove the unapproved Redis dependency.
3. Complete recovery-kit and verification/failure-acceptance contracts.
4. Propagate Windows topology, authenticated DB trust and update/reboot recovery acceptance.
5. Restore historical child obligations and fix path-containment guidance.
6. Correct Phase 0.5 inventory/schema-authority acceptance; incorporate C2 precision fixes.
7. Append independent review and resubmit the exact corrected candidate for focused re-gate.

## Final Verdict

# PHASE 0 CODEX RE-GATE: FAIL

**PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER**

The original C0/C1 acceptance criteria are not all resolved, and three new C1 material contradictions remain. OPEN implementation MRs are not themselves grounds for this verdict. Only eight new re-gate reports were created; historical reports and implementation were preserved. Phase 0.5 and Phase 1 were not begun.
