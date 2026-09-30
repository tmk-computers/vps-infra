# Phase 0 Codex focused re-gate dossier

Audit date: 2026-09-30. **PHASE 0 CODEX RE-GATE: FAIL — PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER.**

## Reports

| File | Purpose |
|---|---|
| [01_REGATE_EXECUTIVE_SUMMARY.md](01_REGATE_EXECUTIVE_SUMMARY.md) | Verdict, baseline, counts and scope |
| [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md) | All ten original acceptance criteria and results |
| [03_RELEASE_SECURITY_RECOVERY_REGATE.md](03_RELEASE_SECURITY_RECOVERY_REGATE.md) | Release counterexamples, security and recovery acceptance |
| [04_WINDOWS_AND_DUAL_OS_REGATE.md](04_WINDOWS_AND_DUAL_OS_REGATE.md) | Windows topology/lifecycle and equal-platform governance |
| [05_TRACEABILITY_AND_PHASE_0_5_REGATE.md](05_TRACEABILITY_AND_PHASE_0_5_REGATE.md) | Source obligations, path demonstration and actual schema inventory |
| [06_REGATE_FINDINGS_REGISTER.md](06_REGATE_FINDINGS_REGISTER.md) | Remaining original and new findings with closure criteria |
| [PHASE_0_CODEX_REGATE_FINAL_REPORT.md](PHASE_0_CODEX_REGATE_FINAL_REPORT.md) | Formal consolidated gate decision |
| [README.md](README.md) | Navigation, method and exact input manifest |

## Candidate and method

| Repository | Frozen implementation SHA | Current documentation/audit HEAD on local main |
|---|---|---|
| vps-infra | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `0d13afa7488fe1d8662f19578d96c1c8d1c39b9f` |
| vps-infra-server | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `69fa124d591f659f8423ab026a12916054bfd86f` |

Both repositories were clean on local `main` before this report set was written. The new commits record the remediation/review dossiers and two governance scripts. A full tracked diff from each implementation baseline, excluding `docs/remediation`, contains only `scripts/verify-baseline-integrity.ps1` and `scripts/mirror-to-infra.ps1`. No runtime, product, database, configuration or test implementation drift was found.

Previous documentation HEADs `72758f6c23fc76e62e059e382cf61106567668ab` and `dba08c63a37eb8d2c851f637d8a02a85cbab4604` remain historical review context, not current HEADs. This assessment is of the committed local-main candidates above; it does not assert a freshly fetched remote state. Git warned that the ignored server `.pytest_cache/` directory was inaccessible; tracked diff/history and dossier verification completed.

Reviewed the prior Codex gate, the ten Developer remediation reports, the nine R3 reports, the corrected authoritative twenty-document baseline, the R2 PASS record, relevant original finding obligations and source anchors. Prior audit/review conclusions were treated as claims requiring comparison to the candidate, not as proof of closure.

Read-only checks:
- Git branch/HEAD/history/status and implementation-baseline diff.
- SHA-256 of 65 existing dossier files on both repositories; no mismatches.
- Preservation of 17 pre-existing Reviewer dossier files against the prior Codex manifest; no mismatches. R2 is the separately added eighteenth file.
- All eight original Codex gate reports compared with prior generated content; unchanged (newline-normalized comparison).
- Independent exact-ID/uniqueness/target parsing: 37 MRs; 63 trace rows; no missing/duplicate IDs or invalid MR targets.
- Inspected both audit PowerShell files; executed verify-baseline-integrity.ps1 with exit 0 (48 MD mirrors in its configured scope); did not run mirror-to-infra.ps1.
- Evaluated only pure .NET path/string operations for the containment counterexample; no filesystem access at the example paths.
- Checked primary PostgreSQL and Npgsql documentation for the specific archive-listing and TLS claims. Links are beside the corresponding technical assessment.

No application test suite, deployment, database migration, live restore, key rotation, external customer action or Windows service update was executed. This is an architecture-contract gate. Product readiness is not inferred from documentation.

## Review history

Original Reviewer FAIL → remediation → separate Reviewer R2 PASS → original Codex FAIL → Codex remediation → separate Reviewer R3 PASS → this Codex re-gate FAIL.

The historical reports were not rewritten. This dossier is new and appears only under the server repository's requested phase-0-codex-regate path; no mirror script was run.

## Input SHA-256 manifest

These 65 existing inputs were fingerprinted before re-gate report creation and rechecked afterward. Each row has the same hash in infra and server. Current Git HEADs above also bind the tracked tooling and implementation source. Paths are relative to each repository.

| Input | SHA-256 |
|---|---|
| `docs/remediation/phase-0/01_CURRENT_BASELINE.md` | `D118E41399235910A5654C649E6EF741BFA9D5091B30846E790C024C766AE26E` |
| `docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md` | `2C3A705189CCB82DC4D4FA8663DE6CA605DF221DD1C854E0E0FA6651882AB088` |
| `docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md` | `E284F7F19FA37060486698FB9C25FCA31E27DEC594B109E635885A0373F06D05` |
| `docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md` | `7A03D3662632B43C68D47A14EAF1E7F30C50C9899624EFC59E073C97DD2FCDB2` |
| `docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md` | `BAE474A22C53F5258B0D21DF5991EB1A31FF5D5E0855CD404979CE52B054FE11` |
| `docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md` | `0C3519578F2FAC0241FE25ADF3E476FC175E6AE40821E232D15FF97FC6828839` |
| `docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md` | `E5C09363B0B764774076C59907BB3D41F425334C323C07D1166775DCEB3FA81B` |
| `docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md` | `53822F8E4A5F233D516E69ED00E2D6109BDB95B341C4D88581F0442491C1B2BA` |
| `docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md` | `5FD4CD1C1BDAD00CAB2967CA4DF1EFCA2DABE1ADD71412C3A4C20861BFEA521A` |
| `docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md` | `9366A1A6F497ECC6ED3E2A062A1911A98A20A8BE1831EB0332D3AB3BDD9B53C0` |
| `docs/remediation/phase-0/11_AMS_CURRENT_STATE.md` | `20D4B2482B847A67B8DAFF9CF730EDE85327DA5599ACD1B6F3D35E6D28294B86` |
| `docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md` | `E162478CB069F1EFA49F0C71582F3FC350D4EC0424EB75E27AA9D9BCD422805B` |
| `docs/remediation/phase-0/13_CI_TRUST_MODEL.md` | `910F637B0FD4F71A84C28C3F43DBA0AACF22C0AAA3C1B7A67FEEF04F519C7377` |
| `docs/remediation/phase-0/14_AI_FEATURE_CLASSIFICATION.md` | `ED2363583F5777F4BEF5CAE8703A077E5D9E7615FB345465B69B1170A9D6715B` |
| `docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md` | `961E5FC7D19D39BA48885A692281302C1546A6746AE4EE508509688ECFA0B839` |
| `docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md` | `B7BEBC1578D3F968E3800CB3C3244654CC8630AAC67971443C76ED711230FAB0` |
| `docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md` | `33070AE5825E70EB2B9F0990DB0E439BC2902B8D072B8D4910B5E84D71716834` |
| `docs/remediation/phase-0/18_PHASE_0_EVIDENCE_INDEX.md` | `FF436D21F9E0840BB2FD8310CAC22AF88ADE0F0E8A8520C021C29641F7A4EF89` |
| `docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md` | `B35D09E7102A2567026B7CF2276D9BA1253726EC4D5325A4D61A9781817F8615` |
| `docs/remediation/phase-0/README.md` | `674F1F02E20CC5D2F3A36DA896B6C34E7F3371E2DEB861B39A124B0916B4CF0E` |
| `docs/remediation/phase-0-codex-gate/01_CODEX_GATE_EXECUTIVE_SUMMARY.md` | `7A9DA625F6A37F8134039E3ED780984192B0278B447230CAA00737D325E44F82` |
| `docs/remediation/phase-0-codex-gate/02_BASELINE_AND_TRACEABILITY_GATE.md` | `C378408A43DB0CE6C658A286E0D81FFF19E57D5C73DFDEC92A30B9F78CE761BF` |
| `docs/remediation/phase-0-codex-gate/03_SECURITY_AND_TRUST_GATE.md` | `E492EF0DC40D601D3C550882A3B61A16D7E90CA7C90E7366148F38640DE4FFEF` |
| `docs/remediation/phase-0-codex-gate/04_DUAL_OS_ARCHITECTURE_GATE.md` | `593184982A842DCCFD26A42837DD601E11546EE0561E794AFDB997169729DE9C` |
| `docs/remediation/phase-0-codex-gate/05_PHASE_SCOPE_AND_DEPENDENCY_GATE.md` | `673B29D4A55880EFE254A86FD12622ED275E00829BD7084B6EDE61C034CBBDB8` |
| `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` | `9F7CA6901D3DC809DE67F05152D8444E84ABF564BBF78B8C3166AA0AC18C9523` |
| `docs/remediation/phase-0-codex-gate/PHASE_0_CODEX_GATE_FINAL_REPORT.md` | `3F2380F3BB690B834E6E3235F3BD8FA1E11C1A3C62173E07D6A34E7BFFA6B269` |
| `docs/remediation/phase-0-codex-gate/README.md` | `37B93004207117B225E1BA242ACF916A5FAC3979E8FB51364C14CB4E30B69E48` |
| `docs/remediation/phase-0-codex-remediation/01_CODEX_FINDING_RESOLUTION_MATRIX.md` | `3FE6A5EB278EB7F1542530972340A409114ECE8D5815B86B92F7CAB92F6F23B6` |
| `docs/remediation/phase-0-codex-remediation/02_RELEASE_CONTRACT_CORRECTION.md` | `F87A16E551EA339887AD9B4D31752C19F64636308AD2B88E8F257D0645FEEADB` |
| `docs/remediation/phase-0-codex-remediation/03_SECURITY_CONTRACT_CORRECTION.md` | `11054EB04494DA9A5291215520C5A6F9618081231A0FD56DD08361BF612EF324` |
| `docs/remediation/phase-0-codex-remediation/04_BACKUP_RECOVERY_CORRECTION.md` | `D4CF0285AB7747F4C712BEDE17A3F60B3DDD84B85590522E21A14E2F3E76A5E1` |
| `docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md` | `E132B472375F7BC6B4BA475AF443CFA6388E26FA24ED733500FC5C9689806DA3` |
| `docs/remediation/phase-0-codex-remediation/06_HISTORICAL_OBLIGATION_RECONCILIATION.md` | `4EA77CCB4DFA4AD0682ABF3F0BE97BDBFDE2BA2831465F7211BEA75CC10CD36E` |
| `docs/remediation/phase-0-codex-remediation/07_PHASE_0_5_SCHEMA_AUTHORITY.md` | `352A4D36A2D2F7A3AA0843779BA1D25D9E6AB299CE0158DFBD21B3A0CD733E80` |
| `docs/remediation/phase-0-codex-remediation/08_C2_C3_RESOLUTION.md` | `27271195A90C6038A2D5F78A0DF800D3A09D90C12ACF5ED81E12322E2F63AFAF` |
| `docs/remediation/phase-0-codex-remediation/PHASE_0_CODEX_REMEDIATION_FINAL_REPORT.md` | `3CC7FC4CD7D0FFA77DAC27974E95451E2A930BB4FE6F20C3AB013FDBD2ED09D4` |
| `docs/remediation/phase-0-codex-remediation/README.md` | `403677364FA7F5C37224B4DA2AB352A3D9513D83CEFF31F95A82094BEA8E6467` |
| `docs/remediation/phase-0-review/01_REVIEW_EXECUTIVE_SUMMARY.md` | `219F1D64C86E2CF57A85A5C9C02EB47912C23FCC00B095DFF207A1E9504BE040` |
| `docs/remediation/phase-0-review/02_BASELINE_VERIFICATION.md` | `318D45B81283E03E74990004995A8B2FD9A0A0C213C9AFB84666019534370616` |
| `docs/remediation/phase-0-review/03_TRACEABILITY_REVIEW.md` | `51FE9E2C069C8285C0B67F8EE22345A13CF37325BBEEB1CF19CF1944DFE08E76` |
| `docs/remediation/phase-0-review/04_MASTER_REGISTER_REVIEW.md` | `50162269C93625939580D8849225AECECF54528F744E7EDE1A0C0FC31975D5A0` |
| `docs/remediation/phase-0-review/05_SEVERITY_AND_BLOCKER_REVIEW.md` | `E8FADF4EA29D263816FF2F619E8C60A79EFEB26F346810F11BEADF65BD0F2BAF` |
| `docs/remediation/phase-0-review/06_DUAL_OS_ARCHITECTURE_REVIEW.md` | `93E7C443089C3D5FBD5AAE1FE30E7034DCABB22F814987EAF284B011EB2EE44A` |
| `docs/remediation/phase-0-review/07_LINUX_BASELINE_REVIEW.md` | `3B042E9A27AEFBE9835EF23F121873341CE91C829B7C798AFDADC2DFBF24D95A` |
| `docs/remediation/phase-0-review/08_WINDOWS_BASELINE_REVIEW.md` | `22360CEDEB0C65CC2C5A368730AA2487DFBB3D1F1432CCF6A94E2D0FE71FFA59` |
| `docs/remediation/phase-0-review/09_MAINTENANCE_AMS_UPGRADE_REVIEW.md` | `5ACFBBF1D4ABBF335EAB3DE1128B3131C1BED26AC1C809D7E204C54B43A30ADF` |
| `docs/remediation/phase-0-review/10_SECURITY_BOUNDARY_REVIEW.md` | `23FBB4C06610E1BB8AFEF10378C342410C7390B5D7A786A6FE530973AFA0EDF6` |
| `docs/remediation/phase-0-review/11_BACKUP_ALERTING_RECOVERY_REVIEW.md` | `DCF4E372834B08A045479711F090ED2427682C6F9EFF5E7FFBA8401B6594B015` |
| `docs/remediation/phase-0-review/12_DOCUMENTATION_TRUTH_REVIEW.md` | `519C4C17FAFB55DADC34D6BB45B532483DF21A98B9A57112BB836F20F2CC5BE9` |
| `docs/remediation/phase-0-review/13_PHASE_PLAN_REVIEW.md` | `6962C2008E7E2708C79616C338D0FFAF799B221DEDF055A689C461F6D478A05B` |
| `docs/remediation/phase-0-review/14_PHASE_1_SCOPE_RECOMMENDATION.md` | `CD87AA3B1BF3202069C736DE8B40DF4813857CDE0A8027609D9C8A575378464E` |
| `docs/remediation/phase-0-review/15_REVIEW_FINDINGS_REGISTER.md` | `721772B1EF5229B1C3F4AA2E677C2A755F44FA1C1C0AFBA99339EAACCF01557A` |
| `docs/remediation/phase-0-review/PHASE_0_REVIEW_FINAL_REPORT.md` | `0DD5256C4EAFA234013643BDBD2F3470B4D34F54EABC2BEBE17B73206F1816B8` |
| `docs/remediation/phase-0-review/PHASE_0_REVIEW_R2_FINAL_REPORT.md` | `A41E5FEC412B8E7F68720913429C4A0ADCECAACD3B543D3AF3034E00307100B2` |
| `docs/remediation/phase-0-review/README.md` | `CED0F7F78DEE3CA2740C11DFB4A1CE6B08C7174CE005FB184A983DE52CBBF94C` |
| `docs/remediation/phase-0-review-r3/01_R3_EXECUTIVE_SUMMARY.md` | `72C0D098B873D1C785C65D2E81F5DE74E1B1D5803AD77E3C461E402AB4502B8D` |
| `docs/remediation/phase-0-review-r3/02_CODEX_FINDING_REVERIFICATION.md` | `73B4B7F87D9A8FCEC4D8BC14454AD036B685A0B1DCD7E631F608FBAE67B00914` |
| `docs/remediation/phase-0-review-r3/03_RELEASE_CONTRACT_REVIEW.md` | `CB9E75BA21B18F08E6863A6C514C4CFCD7E53A0AAC5637C5696E3FE5206197AF` |
| `docs/remediation/phase-0-review-r3/04_SECURITY_AND_CRYPTO_REVIEW.md` | `4150F2C1D756E162917CC461FBF283FAFD2C75819C00C144B30BD5EC13B69319` |
| `docs/remediation/phase-0-review-r3/05_WINDOWS_TOPOLOGY_REVIEW.md` | `7FE67FAF2C2B9C84589E20CD452C9744366C2359675CB24DB81F0A26C4B5D2F1` |
| `docs/remediation/phase-0-review-r3/06_TRACEABILITY_AND_SCHEMA_REVIEW.md` | `64293E44CA218BD0814A2BD7F723E22208965A435686DEF31E57D96D0512D4C6` |
| `docs/remediation/phase-0-review-r3/07_R3_FINDINGS_REGISTER.md` | `12C9C136B7014E91C73C8CCB2DA42C56032B2494DE1BD5365F41C7FD34B93839` |
| `docs/remediation/phase-0-review-r3/PHASE_0_REVIEW_R3_FINAL_REPORT.md` | `951118D471DC752D8538102E50024D9BD87A03360B72EDF1042C438D17672DBC` |
| `docs/remediation/phase-0-review-r3/README.md` | `9E3E78A83958E7028DFF9025E5888D53F9B8F42B0AE5CC6D77A3133A4E3FDF16` |

## Output scope and limitations

Exactly eight Markdown outputs are expected in this directory. Input hashes, output count and local links were checked before handoff. Existing dossiers, scripts and implementation remain unchanged. C2/C3 refinements are recorded proportionally and are not substituted for C0/C1 blocking evidence.
