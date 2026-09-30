# Evidence and consistency final gate

Date: 2026-09-30. **Evidence integrity: FAIL.** The failures concern actual baseline accounting and technical/evidentiary accuracy, not the absence of later-phase implementation.

## Candidate and change accounting

| Repository | Expected implementation baseline | Audited main HEAD |
|---|---|---|
| vps-infra | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `174869490596c1eee07366590dbd8e1c46df5b71` |
| vps-infra-server | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `76b4bcb97dda098ff15a4fc9be4844746b6989be` |

These are the local main candidates inspected on 2026-09-30. HEAD advanced during the audit; the final decision uses the above commits, not the older HEADs quoted in R4. No fetch, deployment, database connection, migration, or production test was performed.

Compared with the frozen implementation SHAs, the only non-document changes are:

| Repository | Added path | Classification |
|---|---|---|
| Both | scripts/verify-baseline-integrity.ps1 | Audit/governance tooling |
| Both | scripts/mirror-to-infra.ps1 | Audit/governance tooling |
| vps-infra | db/postgres/create-readonly-analyst.sh | Database/security provisioning implementation |

Infrastructure commit `10a2e77` creates/updates a login and grants database/schema/table/sequence access in `clever_farmer_uat`. It embeds a fallback password; the value is deliberately omitted from this report. “Read-only analyst” describes intended account privileges, not whether executing the script mutates the database.

No matching exception/disposition was found in the remediation dossiers. R4's zero-implementation-drift statement refers to older HEADs and cannot certify the final candidate. This is new FR-C1-01. No claim is made that the script has been executed or that authorization could not exist outside the supplied evidence.

Both worktrees showed no listed changes before audit outputs. Git warned that the server .pytest_cache directory could not be opened; no claim is made about unreadable ignored cache contents. Tracked implementation comparison is unaffected. No runtime command or the provisioning/mirroring script was executed.

## History, authority and mirror evidence

Historical Codex/reviewer verdicts are retained as dated evidence, current phase-0 documents define the contract, and reconciliation dossiers explain edits. A dossier saying “resolved” does not override conflicting active canonical text.

Git comparison from the immediately prior documentation HEADs shows no modifications to the already tracked original gate, initial review or R3 reports. Prior Codex re-gate reports enter Git as additions in the latest commits, so Git alone cannot prove their content before first tracking. This audit leaves all input files untouched and records their SHA-256 hashes.

The independently captured manifest covers **94 Markdown input artifacts** across eight dossiers. **76 pairs are byte-identical; 18 differ only in CRLF/LF normalization** (the eight prior re-gate and ten R4 files). All 94 have equal newline-normalized text across repositories. This is not 94-file bit-for-bit equality. The 59 files in the verifier's four selected directories are byte-identical.

The immutable input manifest is included in README. Existing correction dossiers are current explanatory material; changes to them must not be confused with rewriting historical independent verdicts.

## Retained C2-04: concrete evidence errors

1. [15_DOCUMENTATION_TRUTH_MATRIX.md:31](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md:31) still presents rollback/S3/R2 quotations against `D:/company/products/vps-infra/README.md`, a nonexistent wrapper-level file. Correct the exact source/quote or label the wording as an unverified paraphrase.
2. R4 backup/Windows review §6.1 says the static fallback is completely eliminated from architecture and code. [tmk-iis-agent.ps1:21](D:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1:21) still contains it. The canonical roadmap correctly leaves replacement as Phase 1 work. Append a correction distinguishing target architecture from present source; do not edit historical R4.
3. The schema inventory misstates migration extent, seeder maintenance coverage, timestamp mapping and relational defaults. Repository inspection does not query deployed migration history.
4. The trace reconciliation substitutes committed-cloud-key remediation for F02 and MR-18 scheduling for F15; canonical rows retain the correct findings.
5. The recovery reconciliation still overstates detection of any truncated dump through listing. Listing is not full-payload validation.
6. The evidence dossier claims a LocalService stale-pattern check, but the script has only four other patterns. R4 also relabels the original C2-02/C2-03 criteria and carries a stale “14 findings” heading despite sixteen rows.

Targets for rollback/RPO/RTO are not credited as measured outcomes. Documentary failure walkthroughs are not execution tests. No later-phase test has been represented here as passed.

## Integrity tooling: actual execution and fault injection

The actual unmodified verifier ran successfully, **exit 0**:

- 37 exact MR IDs; 33 OPEN + 3 PARTIALLY_IMPLEMENTED + 1 IMPLEMENTED_NOT_VERIFIED.
- 22 exact F IDs and 37 exact DEF IDs.
- Historical-row MR references within the expected set.
- Forward/reverse SHA-256 comparison of 59 files in four configured directories.
- Four exact stale-pattern checks.

Fault injection was read-only: PowerShell command overrides changed returned strings/metadata in memory, not repository fixtures. A multi-case harness changed only the terminal `exit 0` to `return` in its in-memory script copy to collect outcomes. Duplicate-MR and reverse-orphan cases were additionally executed against the actual unmodified script and independently exited 1.

| Injected condition | Observed result |
|---|---|
| Replace MR-02 by duplicate MR-01, preserving count | Rejected: missing MR-02; actual script exit 1 |
| Replace F02 by duplicate F01 | Rejected: missing F02 |
| MR-99 reference in F01 row | Rejected: invalid target |
| Replace OPEN statuses by CLOSED | Rejected: status distribution |
| Different mirrored hash | Rejected: mirror mismatch |
| Missing mirrored file | Rejected: mirror mismatch |
| Extra infra mirror file | Rejected: reverse orphan; actual script exit 1 |
| Forbidden auto-restore phrase in release text | Rejected: stale phrase |
| Missing entire server phase-0-codex-remediation directory | **Accepted**: silently skipped |
| MR-99 added to current-main MR-34 discovery row | **Accepted**: those rows are outside the scan |

The four directories are phase-0, phase-0-codex-remediation, phase-0-codex-regate-remediation and phase-0-review. R3, R4, original Codex gate and prior Codex re-gate are not included. An empty target cell would also escape existence scanning; that limitation is static inspection, not an additional executed fault case.

The script cannot establish obligation preservation, safe architecture or absence of semantically equivalent stale instructions. No test was credited merely because counts matched. Retained C3-01 remains advisory, with substantial improvements acknowledged.

## Verification limits

No EF build/model instantiation, live PostgreSQL inventory, restore drill, Windows lab, deploy/fencing failure injection or secret rotation was performed. Static source/model and documentary contract evidence are sufficient for this Phase 0 re-gate but do not certify runtime behavior. The new analyst script was inspected for baseline accounting only, not comprehensively security-tested.
