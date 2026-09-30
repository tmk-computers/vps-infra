# Previous Codex findings: independent closure verification

Six previous findings rechecked: **4 resolved; 2 unresolved (C2-04 and FR-C2-01, both C2)**. New findings: **C0 0; C1 1; C2 0; C3 0**. The new C1 concerns the revocation visibility contract, not the decision to adopt Redis.

| Finding | Previous severity | Closure condition | Independent evidence | Final verdict |
|---|---|---|---|---|
| RG-C1-02 | C1 | Real 8+5 fields, configured timestamp types/default distinctions; remove invented schema targets. | Product.cs:15–22, ProjectService.cs:36–40, ApplicationDbContext.cs:44–46; canonical final report:170; closure schema §3; revised inventory §3. | PASS |
| C2-01 | C2 | Neutralize competing seeder DDL before Phase 0.5 acceptance; only unrelated work remains later. | Canonical final report:170, maintenance §3, roadmap:73 and entry criteria:41 agree on prior disablement/removal. | PASS |
| C2-04 | C2 | Correct source citations/descriptions, append historical corrections and avoid overclaiming evidence. | Wrapper README and Windows-secret reality corrected; closure evidence §2.4 still misstates F02/F15; truth matrix has a missing cleanup-script citation; reviewer master report has incorrect paths, types and metrics. | FAIL |
| C3-01 | C3 | Fail missing dossiers/discovery targets; explicitly bound mirror and phrase-check coverage. | Verifier exact sets/status/targets; 69 byte-identical files; independent missing-directory/discovery-target injections now fail. | PASS |
| FR-C1-01 | C1 | Account for database helper and credential risks under an explicit candidate disposition. | Option A in closure disposition; helper tracked in exact candidate; compromised fallback redacted from active evidence, rotation/revocation mandated where used, Phase 1 dynamic-credential ownership. | PASS |
| FR-C2-01 | C2 | Use peer-authenticated PostgreSQL TLS; remove misleading Require alternative. | Canonical architecture/OS/database/roadmap require VerifyFull, but active remediation Windows:84 and regate consistency scan:91 retain the misleading Require alternative. | FAIL |

## Evidence references

- Prior closure conditions: [06_FINAL_FINDINGS_REGISTER.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-final-regate/06_FINAL_FINDINGS_REGISTER.md).
- Corrected canonical schema prerequisite: [PHASE_0_FINAL_REPORT.md:170](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md:170).
- Source-derived contract: [03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/03_PHASE_0_5_SOURCE_SCHEMA_CONTRACT.md).
- Database script inclusion and compromised credential treatment: [04_INFRA_DATABASE_PROVISIONING_DISPOSITION.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/04_INFRA_DATABASE_PROVISIONING_DISPOSITION.md).
- Remaining evidence errors: [05_EVIDENCE_TRUTH_CORRECTIONS.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/05_EVIDENCE_TRUTH_CORRECTIONS.md) §2.4 compared with [03_HISTORICAL_FINDING_TRACEABILITY.md:27](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md:27) and line 40.
- TLS: [05_SUPPORTED_OS_MATRIX.md:68](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md:68).
- Mechanical checks: [verify-baseline-integrity.ps1](D:/company/products/vps-infra/vps-infra-server/scripts/verify-baseline-integrity.ps1) and report 06 in this dossier.

## Interpretation of closure

The Phase 0 schema contract now matches the real fields and model configuration. Existing code still lacks maintenance migrations and retains raw seeder DDL; that is expected work for Phase 0.5, not grounds to fail this gate.

The analyst helper remains unsafe to treat as production-ready, but the user expressly requires specification/disposition closure rather than Phase 1 implementation now. Its inclusion, risk classification, prohibition of production fallback use, conditional rotation obligation and structural remediation ownership satisfy FR-C1-01.

C2-04 is partially corrected, not fully closed. Canonical traceability remains accurate; the false descriptions in supplementary evidence do not silently replace its owners or reopen the historical traceability domain.

The verifier now closes the two demonstrated blind spots and declares its narrower scope. It is not a semantic architecture validator. Missing-reference cells without an MR token are still outside membership checking; no claim of complete traceability semantics is credited.

The previous accepted Redis-optional decision is superseded by the user's authorized amendment. CG-C1-01 is a new consistency issue in the amended read/write/acceptance rules, not a reopening of the former Redis dependency finding.

FR-C2-01 remains open for complete active-document consistency: phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:84 and phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md:91 still permit Require with Trust Server Certificate=false. These are in the closure scan's declared active scope, not immutable independent historical reports. Canonical VerifyFull remains the governing target; this is still C2.
