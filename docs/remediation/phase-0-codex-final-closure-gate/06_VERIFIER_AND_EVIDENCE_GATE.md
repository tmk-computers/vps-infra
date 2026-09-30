# Verifier and evidence gate

## Mechanical verifier — PASS within explicit scope

The actual unmodified [verify-baseline-integrity.ps1](D:/company/products/vps-infra/vps-infra-server/scripts/verify-baseline-integrity.ps1) was inspected and executed. It exited **0**, reporting:

- Exact MR-01..MR-37 set; 33 OPEN + 3 PARTIALLY_IMPLEMENTED + 1 IMPLEMENTED_NOT_VERIFIED.
- Exact F01..F22 and DEF-01..DEF-37 sets.
- MR-reference membership across bold-ID historical and current discovery table rows.
- Forward/reverse file-set and byte SHA-256 checks for **69 Markdown artifacts in five named directories**.
- Six literal/regex stale-pattern checks in canonical phase-0 files.

Five mirror directories: phase-0, phase-0-codex-remediation, phase-0-codex-regate-remediation, phase-0-final-closure and phase-0-review. Counts: 20 + 10 + 11 + 10 + 18 = 69.

The script does not validate semantic obligation coverage, arbitrary future Markdown formatting, empty mapping cells, full architecture consistency, or historical normalized parity. The historical parity policy is documented separately; it is not an implemented verifier check. The six patterns do not include every nonexistent entity or TLS variant claimed in the review's master summary.

## Independent read-only fault verification

No repository fixtures were edited. Command overrides injected alternate in-memory read results. A multi-case harness changed only its in-memory terminal exit to return so each exception could be collected.

| Injected condition | Observed outcome |
|---|---|
| Duplicate MR-01 replaces MR-02, count preserved | Rejected: missing MR-02 |
| MR-99 in MR-34 discovery row | Rejected: invalid target |
| Missing required server closure dossier | Rejected: required source directory missing |
| Missing required infra closure dossier | Rejected: required mirror directory missing |
| Mirrored hash mismatch | Rejected: mirror mismatch |
| Forbidden former Redis-optional phrase | Rejected: stale pattern |
| Duplicate F01 replaces F02 | Rejected: missing F02 |
| OPEN changed to CLOSED | Rejected: status arithmetic |

The discovery-target and missing-source-directory cases were additionally run against the actual unmodified script: both processes exited **1**. This independently closes the two previously demonstrated blind spots.

The Developer's recorded seven-case suite was read as prior evidence, not represented as independently rerun verbatim. Mirror reverse-orphan logic was inspected; current exact file sets were independently compared.

## Mirror and external-review evidence

Independent hashes cover **87 pairs**: 69 configured documents, ten authorized external review reports and eight prior Codex final re-gate reports. All 87 pairs are byte-identical at capture. The external review directory contains exactly the ten requested Markdown outputs and no executable/configuration additions. Its untracked status is expressly authorized.

Historical original gate, re-gate, R3/R4 and initial-review files show no modifications in the commit diff from the previous audited HEAD. Prior final re-gate reports are retained as their own dossier; new verdicts do not overwrite them.

## Evidence integrity — FAIL, retained C2-04

Important corrections are credited: wrapper README links now point into the real repository; promotional claims are labelled paraphrases; current Windows fallback reality is explicitly distinguished from Phase 1 removal; current schema types/default columns are corrected; actual live rotation/runtime tests are not claimed.

The following substantive evidence precision defects remain:

| Artifact | Remaining error | Correct reading |
|---|---|---|
| Final closure 05 §2.4 | F02 described as leaked Google key / MR-03; F15 as scheduling / MR-18 | Canonical F02 is signing defaults MR-02/MR-36; F15 is approval drift/replay MR-08 |
| Canonical truth matrix:38 | Links to nonexistent infra scripts/cleanup-docker.sh | Supply an existing source or explicitly identify an unverified claim; no replacement source is invented here |
| Earlier incorporated inventory §2 | Says migrations stop at InitialCreate; DDL is in a catch block; asserts deployed history from source | Later migrations exist; DDL is in a try with swallowed catch; deployed history was not queried |
| Closure schema/reviewer narrative | Product IsActive treated as merely inherited | Product redeclares it; ProjectService inherits it; neither adds a new maintenance IsActive column |
| Closure consistency scan | Retains a row calling Redis uncertified/exclusive PostgreSQL | Superseded by intentional Redis amendment and canonical updated cache profile |
| Closure baseline table | Old candidate SHAs still labelled final, plus re-freeze placeholder | User-specified exact SHAs and observed Git state identify this candidate |
| External review master report | Nonexistent src/* and test/matrix document paths; ProjectService.IsMaintenance shown non-nullable; wrong verifier directory/pattern claims | Actual source is devops-manager/api/Data; IsMaintenance is bool?; verifier scope is the five directories above |
| External review carry-forwards | Wrong analyst fallback label, variable name, DR document/owners and RTO | Do not reproduce the actual credential; use source ANALYST_PASS; DR is canonical 09, MR-14/MR-15, 30-minute target |

The external review's master report also gives a 60-second cache TTL while its detailed Redis review and the amendment specify a five-second revocation propagation bound. It is not authoritative for changing that contract.

These items remain C2-04 rather than newly counted findings. They warrant appended factual corrections and reduce reliance on the review's blanket “all resolved” conclusion, but do not independently make the corrected schema/drift/TLS architecture fail.

## Boundaries of evidence

Source inspection and document diffs are static evidence. Only local mechanical verifier execution, injected verifier failures and file/hash checks were executed. No production database, Redis outage, token replay, TLS endpoint, migration, Windows deployment or DR test was run. The cache authorization counterexample is a documentary consistency analysis, not a demonstrated runtime exploit. No implementation or authoritative document was edited.
