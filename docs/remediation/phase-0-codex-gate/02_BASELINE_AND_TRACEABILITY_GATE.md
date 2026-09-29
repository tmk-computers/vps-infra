# Baseline and traceability gate

Audit date: 2026-09-29. Canonical report location: vps-infra-server/docs/remediation/phase-0-codex-gate.

## Baseline

| Repository | Branch | Implementation baseline | Local documentation HEAD |
|---|---|---|---|
| vps-infra | main | `780e8b4f152e039e9ee31ed46c71811e04947f7b` | `72758f6c23fc76e62e059e382cf61106567668ab` |
| vps-infra-server | main | `36354a32884fd0c03470d2b3f5333776f7aed6c9` | `dba08c63a37eb8d2c851f637d8a02a85cbab4604` |

Historical audited SHAs: infra `eab8df65aaf708875a922cf87c655d86156f402a`; server `a1f4a51ed3fb9e9751f83ec191a29f04e6971d32`.

Each local HEAD adds one documentation-only commit after the implementation baseline. Each repository also has 12 modified Phase 0 Markdown files. The gate evaluates those working-tree corrections, not just committed documents. Baseline-to-working-tree tracked diffs outside `docs/remediation/` are empty in both repositories. No runtime/product/configuration/test drift was found. No fresh remote HEAD claim is made by this gate; remote-tracking refs are not live remote proof. The server status command warns that `.pytest_cache/` is inaccessible; ignored cache contents were not inspected.

The documentation commits are `72758f6 docs(remediation): add Phase 0 engineering baseline and independent review dossiers` and `dba08c6 docs(remediation): add Phase 0 engineering baseline and independent review dossiers`. Historical-to-implementation deltas were reviewed in the preceding context refresh: maintenance, AMS, upgrade runner, backup test isolation, image versions and release tooling. Those implementations have not changed for this gate.

Read-only verification used per-command Git safe.directory, branch/HEAD/status/log, and `git diff <implementation-SHA> -- . ':!docs/remediation'`. No global Git configuration was changed. Source was inspected without emitting the committed private-key contents.

## Artifact inventory and arithmetic method

59 historical audit Markdown files + 20 Developer files + 17 Reviewer files = **96 distinct canonical inputs**. Mirror verification adds 37 matching copies, not 37 additional independent pieces of evidence. SHA-256 comparisons found zero Developer or Reviewer mirror differences.

Parsed only primary table rows beginning with an explicit MR ID, rather than counting repeated mentions in summaries. Parsed traceability first-column IDs and target-column MR IDs independently. Required ID sets are contiguous and unique; every target resolves to an MR row. The 63 trace rows comprise 22 Codex + 37 Antigravity + 4 current-main entries.

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

These are counts of work packages, not sums of distinct vulnerabilities, proof of severity correctness in every subcase, or readiness percentages. The historical sources use differing severities; merged MR severity may be the highest applicable severity without changing the preserved historical severity.

## Complete mapping inventory

| Source ID | Mapped MR targets |
|---|---|
| F01 | MR-01 |
| F02 | MR-02 |
| F03 | MR-03 |
| F04 | MR-04, MR-08 |
| F05 | MR-08 |
| F06 | MR-05 |
| F07 | MR-06 |
| F08 | MR-10, MR-12 |
| F09 | MR-22 |
| F10 | MR-11, MR-22 |
| F11 | MR-14 |
| F12 | MR-15 |
| F13 | MR-17, MR-12 |
| F14 | MR-16 |
| F15 | MR-08 |
| F16 | MR-07 |
| F17 | MR-13 |
| F18 | MR-19 |
| F19 | MR-15, MR-20 |
| F20 | MR-04 |
| F21 | MR-21 |
| F22 | MR-08, MR-25 |
| DEF-01 | MR-10, MR-12 |
| DEF-02 | MR-14 |
| DEF-03 | MR-06 |
| DEF-04 | MR-02, MR-07 |
| DEF-05 | MR-03 |
| DEF-06 | MR-08 |
| DEF-07 | MR-09 |
| DEF-08 | MR-01 |
| DEF-09 | MR-18 |
| DEF-10 | MR-21 |
| DEF-11 | MR-08 |
| DEF-12 | MR-16 |
| DEF-13 | MR-11, MR-12 |
| DEF-14 | MR-20 |
| DEF-15 | MR-04 |
| DEF-16 | MR-17 |
| DEF-17 | MR-31 |
| DEF-18 | MR-15 |
| DEF-19 | MR-10 |
| DEF-20 | MR-07 |
| DEF-21 | MR-17 |
| DEF-22 | MR-21 |
| DEF-23 | MR-30 |
| DEF-24 | MR-31 |
| DEF-25 | MR-21 |
| DEF-26 | MR-20 |
| DEF-27 | MR-33 |
| DEF-28 | MR-22 |
| DEF-29 | MR-22 |
| DEF-30 | MR-23 |
| DEF-31 | MR-22 |
| DEF-32 | MR-24 |
| DEF-33 | MR-25 |
| DEF-34 | MR-26 |
| DEF-35 | MR-27 |
| DEF-36 | MR-28 |
| DEF-37 | MR-29 |
| MR-34 | MR-34 |
| MR-35 | MR-35 |
| MR-36 | MR-36 |
| MR-37 | MR-37 |

## Independent MR inventory

| MR | Scope | Severity | Status | Blocker label |
|---|---|---|---|---|
| MR-01 | Linux | P0 | OPEN | YES |
| MR-02 | Shared | P0 | OPEN | YES |
| MR-03 | Shared | P0 | OPEN | YES |
| MR-04 | Shared | P1 | OPEN | YES |
| MR-05 | Linux | P1 | OPEN | YES |
| MR-06 | Linux | P0 | OPEN | YES |
| MR-07 | Shared | P1 | OPEN | YES |
| MR-08 | Shared | P1 | OPEN | YES |
| MR-09 | Shared | P1 | OPEN | YES |
| MR-10 | Linux | P0 | OPEN | YES |
| MR-11 | Shared | P1 | OPEN | YES |
| MR-12 | Shared | P0 | OPEN | YES |
| MR-13 | Shared | P1 | OPEN | YES |
| MR-14 | Shared | P0 | PARTIALLY_IMPLEMENTED | YES |
| MR-15 | Shared | P1 | OPEN | YES |
| MR-16 | Linux | P1 | OPEN | YES |
| MR-17 | Linux | P1 | PARTIALLY_IMPLEMENTED | No (Phase 6) |
| MR-18 | Shared | P1 | IMPLEMENTED_NOT_VERIFIED | YES |
| MR-19 | Shared | P0 | OPEN | YES |
| MR-20 | Shared | P1 | OPEN | No (GTM) |
| MR-21 | Shared | P2 | OPEN | No (Phase 9) |
| MR-22 | Windows | P0 | OPEN | YES (Win) |
| MR-23 | Windows | P0 | OPEN | YES (Win) |
| MR-24 | Windows | P1 | OPEN | YES (Win) |
| MR-25 | Windows | P1 | OPEN | YES (Win) |
| MR-26 | Windows | P1 | OPEN | YES (Win) |
| MR-27 | Windows | P0 | OPEN | YES (Win) |
| MR-28 | Windows | P0 | OPEN | YES (Win) |
| MR-29 | Windows | P1 | OPEN | YES (Win) |
| MR-30 | Shared | P1 | PARTIALLY_IMPLEMENTED | No (Pilot) |
| MR-31 | Shared | P2 | OPEN | No (Assisted) |
| MR-32 | Shared | P1 | OPEN | YES |
| MR-33 | Shared | P1 | OPEN | YES (Cert) |
| MR-34 | Shared | P0 | OPEN | YES |
| MR-35 | Linux | P0 | OPEN | YES |
| MR-36 | Shared | P1 | OPEN | YES |
| MR-37 | Shared | P1 | OPEN | YES |

## Semantic coverage assessment

ID coverage passes; obligation preservation needs correction (C1-01/C1-04). In particular, F02 includes token issuer/audience/algorithm requirements; F16 includes privacy precedence, fallback rechecks and resource admission; DEF-08 describes management API authority, which external CI alone cannot resolve. DEF-15's path safety must remain assigned work. F22's memory fallback is shared even though one mapped MR is labeled Windows. F15 approval safety may remain excluded from Gate A but must remain a re-enable prerequisite.

Drive upload and SMTP code existence are correctly reconciled as partial/unverified. Redis absence is correctly recorded; no new Redis support is authorized. All four current-main IDs remain OPEN. No finding is treated as closed merely because it appears in a test suite or a documentation table.

## Verification observations

- PowerShell AST parse only: infra agent has errors at lines 345 and 346; server copy has zero parse errors. Neither agent was executed.
- In-memory use of the exact maintenance replacement regex changed both services in a two-service fixture. This reproduces the text mutation, not Docker deployment behavior.
- Product has eight maintenance properties and ProjectService five; no matching maintenance columns appear in tracked migrations/model snapshot or DataSeeder. Both maintenance suites use EF InMemory. Real PostgreSQL 42703/HTTP500 was not executed here.
- Current auth routes, AMS proxy and upgrade health section remain as described by the source review.
- No live SCM service, container deployment, PostgreSQL migration/restore, cloud-key validity or external alert receipt was tested.
- The original reviewer FAIL dossier was read as historical evidence; it does not prove the reported re-review PASS. Candidate hashes below identify what Codex actually audited.

## Input SHA-256 manifest

Paths are relative to vps-infra-server. The canonical Developer/Reviewer files have matching hashes in vps-infra. This captures uncommitted corrections as part of the audited candidate.

| Input | SHA-256 |
|---|---|
| docs/audit/2026-09-28-main/BUG_DEFECT_REGISTER.md | `99C8AFB185212F647081198C4EAF0E20281665ED894833C3803BEE40C5254547` |
| docs/audit/2026-09-28-main/KNOWN_LIMITATIONS.md | `0D04EC3E48C9A0FD7CB0B3EE50DAFDEDBBEC6475F68E158F1E8CA1C6152055F2` |
| docs/audit/2026-09-28-main/STARTUP_GTM_TECHNICAL_REQUIREMENTS.md | `2917ECC44F486B393DB481B2AB91C4879B2DE5B41B17247430D85CE7A2104EEC` |
| docs/audit/2026-09-29-linux-windows-readiness/01_EXECUTIVE_SUMMARY.md | `D73F1702E35BABEC1358C65D20176EDD63D1AFCC83CE36850D148E1C11136E2C` |
| docs/audit/2026-09-29-linux-windows-readiness/02_LINUX_IMPLEMENTATION_MAP.md | `E2F2DC438412B3F73943293D2C85DF2F52AC0274122803DA035268C31CD3A6D0` |
| docs/audit/2026-09-29-linux-windows-readiness/03_WINDOWS_IMPLEMENTATION_MAP.md | `D84F5B46FE9A40466D7255463F257F130694C1408C2E2BA926186CD7B1156895` |
| docs/audit/2026-09-29-linux-windows-readiness/04_SUPPORTED_OS_MATRIX.md | `CC71C94D49566868AC302DCFED8838485F6EE993D0934F82C39BB09E34734C6F` |
| docs/audit/2026-09-29-linux-windows-readiness/05_LINUX_PRODUCTION_READINESS.md | `500205BFC6A067CE8411E71A5B8779EADFA27B4ADF41B1A10A47C9CFDBB3F6CC` |
| docs/audit/2026-09-29-linux-windows-readiness/06_WINDOWS_PRODUCTION_READINESS.md | `2AFF7CFC17F4DB8E22F279F7F8FDB9B31B971C3EA86C57D36FF85C57F4733BB4` |
| docs/audit/2026-09-29-linux-windows-readiness/07_IIS_AGENT_FORENSIC_AUDIT.md | `913AE559753202F5413FA38C7F866CAAD697B6CEA10BBD485F60D7B8290FFD4C` |
| docs/audit/2026-09-29-linux-windows-readiness/08_DEPLOYMENT_ROLLBACK_PARITY.md | `13C5C911F9A6FD827C7B2C17850777498EC9FB77122602751A54B67F4D49FD9C` |
| docs/audit/2026-09-29-linux-windows-readiness/09_DATABASE_STORAGE_AUDIT.md | `B9DC5387B1363402B0B07FF4A01910C5CC2095EF39C381DA8B7876B9CDD7BE1A` |
| docs/audit/2026-09-29-linux-windows-readiness/10_NETWORK_SECURITY_AUDIT.md | `7F3ED27836D3985A37A0436F24B5D38FFCA36F0698BAA199693722DBECE54113` |
| docs/audit/2026-09-29-linux-windows-readiness/11_CI_BUILD_ISOLATION_AUDIT.md | `BB7CA1B75CE1D15D92EC61A9F9B93F552D69AB2824EE13E3936D003E83B89EC0` |
| docs/audit/2026-09-29-linux-windows-readiness/12_BACKUP_RESTORE_DR_AUDIT.md | `EBDB50AECC1D51B0A28914791D8F011613A97D730DC59878B1F5B1F011584B57` |
| docs/audit/2026-09-29-linux-windows-readiness/13_RESOURCE_CAPACITY_AUDIT.md | `DAFADD1DB206A5B16C284ECF34A9E3ECE2244104693F69543E0E0FC4C9EE6D58` |
| docs/audit/2026-09-29-linux-windows-readiness/14_MONITORING_ALERTING_AUDIT.md | `BBC0D4C075AA74E17357E382EB96B1A4751705EFBF38B21036A2744C307F2FDC` |
| docs/audit/2026-09-29-linux-windows-readiness/15_OS_PARITY_MATRIX.md | `46FA5AACF24FA29CA30F45B9D119EFB21EA98190153C7273C9A4BC64D0A42EF6` |
| docs/audit/2026-09-29-linux-windows-readiness/16_LINUX_WINDOWS_BUG_REGISTER.md | `CE2A9BFE872C447C49BF9193593B4E74791F87A3027259C17B9095CC3F99F6D1` |
| docs/audit/2026-09-29-linux-windows-readiness/17_FAILURE_INJECTION_TEST_PLAN.md | `935AD1E2D3A7C7598EB6BA584CB6C43A259AF289B36B1006FC22AD8620939DF0` |
| docs/audit/2026-09-29-linux-windows-readiness/18_LINUX_PILOT_GATE.md | `DA6554367C7FDF92331ED2D02FA51D757CC86C318C6DAD1D4E90ABCF78FCBFCC` |
| docs/audit/2026-09-29-linux-windows-readiness/19_WINDOWS_PILOT_GATE.md | `B07D22F4BD7683E86E423DBF3F64452C42889797A78D0EFE5A7F1DF2A7D291C9` |
| docs/audit/2026-09-29-linux-windows-readiness/20_CROSS_PLATFORM_REMEDIATION_ROADMAP.md | `1DE4FCD0B0F714243574FAE3E3189FCC38677D57935F4FD90C672FBB7AA57E77` |
| docs/audit/2026-09-29-linux-windows-readiness/21_FINAL_DUAL_OS_GATE.md | `EEAF84615C93EB282CB9AC50974932A05483071A8D3F1CC1276A16B372B27AA2` |
| docs/audit/2026-09-29-linux-windows-readiness/README.md | `74910BED0711895A67E303911AB9D7DBE428E01C77986C209BA086422E43407D` |
| docs/audit/2026-09-29-main/01_EXECUTIVE_AUDIT_SUMMARY.md | `52B3FBEA092C0076AC8ED18416591E20E725C389D2990B6ADE684D98F7B63D07` |
| docs/audit/2026-09-29-main/02_MAIN_BRANCH_CODEBASE_MAP.md | `D620CB39E29A46A10AAEEB973718F9C14E8D383523894654F166F0A9590692C1` |
| docs/audit/2026-09-29-main/03_ARCHITECTURE_AUDIT.md | `30B3338B3B43185B793B2B5408333625D70D429514975A40E68BD4B3BE2684A9` |
| docs/audit/2026-09-29-main/04_SECURITY_AUDIT.md | `FE12BB00F1DD949CB4132339ADDDF3376AF13F17D25666EB676E566469733C1F` |
| docs/audit/2026-09-29-main/05_SINGLE_VM_STARTUP_READINESS.md | `A62A78B684F8F26FEDEF3F7BF4174F1BFBDDFAB19B01C34D65535C8472C41068` |
| docs/audit/2026-09-29-main/06_DEPLOYMENT_RELIABILITY_AUDIT.md | `850F2B47C6BE9B7B36592010105F386CB6DBFD14547127F42AF6414C3225E78D` |
| docs/audit/2026-09-29-main/07_BACKUP_DR_AUDIT.md | `11AC55DEFACE348DDECCE0A6C976FEEA54D966DA016BDBCC3A3539F203FD1C64` |
| docs/audit/2026-09-29-main/08_OBSERVABILITY_RESOURCE_GOVERNANCE.md | `DCB3474F19C0E2A990F33B58FE414F98F7A223DDCD030CDAF1DDCC79A0D818D0` |
| docs/audit/2026-09-29-main/09_AI_AGENT_REALITY_AUDIT.md | `E801B59EDC53073026F3AB3DFA9B7C76AC0E37BC0B875F10A0BFC11E2B9A07D0` |
| docs/audit/2026-09-29-main/10_AI_PLATFORM_TARGET_ARCHITECTURE.md | `0B1131CA12F984EDA14FA5FF65EDB035EF19C58A55772E5630E3E13F104BBFFC` |
| docs/audit/2026-09-29-main/11_STARTUP_PRODUCTIZATION_GAPS.md | `12256A8F5FC0AD360417AACEC62DC21A8D7B051ED41AD0E63ECB15A908B55536` |
| docs/audit/2026-09-29-main/12_REMEDIATION_ROADMAP.md | `12DF12CD5BC978873C0E3149056D27270099E47E3AC3B7965EB156A4F864CE7F` |
| docs/audit/2026-09-29-main/13_TEST_CHAOS_VALIDATION_PLAN.md | `28E668556641BA092502DB7A15517BEDF3D20E55C9C4A80E3749FA43F70733A0` |
| docs/audit/2026-09-29-main/14_DOCUMENTATION_DRIFT_REPORT.md | `D14128E218D1DCC639E4E82C2CAB34F914ADE451172CDD3B7DE7D3ADA1E00D51` |
| docs/audit/2026-09-29-main/15_FINAL_GATE_REPORT.md | `F8AFAC7B6418342E644F694B8B922037E08B19F48939025EF62F258A1D9DBF98` |
| docs/audit/2026-09-29-main/README.md | `7E2A540D438CC0C5FEEE964E92DE15E9ABE8FA63310095AF41DE2822BB82F24A` |
| docs/audit/2026-09-29-startup-gtm/01_STARTUP_READINESS_EXECUTIVE_SUMMARY.md | `553392F335138E7E74D0C9AED3A8631833D5CF7DC61B9E8300AE0747B03A387F` |
| docs/audit/2026-09-29-startup-gtm/02_PHASE1_FINDINGS_GTM_RECLASSIFICATION.md | `0013E2A074DEB35E46E392C725693B67BB767F30013C013989B0DE52E829F172` |
| docs/audit/2026-09-29-startup-gtm/03_MINIMUM_SAFE_SELLABLE_PLATFORM.md | `5469253AEA78E0DB74AD39D59EB0BF8F8481917B1451488035359D82B7331F82` |
| docs/audit/2026-09-29-startup-gtm/04_FIRST_PILOT_PRODUCT_SCOPE.md | `F80A965C239A6E736E3EE6D887D08F6868753CA6FF85355659BBCF00289837EF` |
| docs/audit/2026-09-29-startup-gtm/05_CUSTOMER_JOURNEY_GAP_ANALYSIS.md | `57A74EFB4BC7452681FD1B617E5EBCFE685EA2D9F96E42BEB29975C9B15318B7` |
| docs/audit/2026-09-29-startup-gtm/06_SINGLE_VM_PRODUCT_ARCHITECTURE.md | `3C4E53BD8B6655C84D0064759230C494F09683CA8FB5028D08959816C3EA9447` |
| docs/audit/2026-09-29-startup-gtm/07_SUPPORTABILITY_OPERATIONS.md | `2442FC9D6D2F231F6E2784EA07D2137DA62C2D5AB094A4D2F3C945F9F253C3D4` |
| docs/audit/2026-09-29-startup-gtm/08_AI_PRODUCT_STRATEGY.md | `EC7FBA97B14E0D90AFC475BAE27C674BE35C82BCFAB3E8892ACC61EF22744628` |
| docs/audit/2026-09-29-startup-gtm/09_AI_FOUNDATION_ARCHITECTURE.md | `AEC4B77B1E133CB85B2F73E54263C1159DA02BDA500A62168A536D2F5D809BBF` |
| docs/audit/2026-09-29-startup-gtm/10_PILOT_ACCEPTANCE_CHECKLIST.md | `0F80E39C1AE465D52AFA76C702B53641379FDF416B78D5903AB436E04AB1F0DD` |
| docs/audit/2026-09-29-startup-gtm/11_COMMERCIAL_GTM_ACCEPTANCE_CHECKLIST.md | `ED917FF854A17823BF3390B8E786E28AD66F5839B710E13B5D91BCE982FED3E2` |
| docs/audit/2026-09-29-startup-gtm/12_KNOWN_LIMITATIONS.md | `D7485CBC1381C64C370EE91FDDC3F383616EF8AB682304521458CB54D129A1E1` |
| docs/audit/2026-09-29-startup-gtm/13_DEFERRED_SCOPE.md | `3E20636BA5AB9B3C568F68B75CAF6A0440BAE1B5CDB32EB05EF8E020918DB8D9` |
| docs/audit/2026-09-29-startup-gtm/14_GTM_REMEDIATION_ROADMAP.md | `F1AF9471167AC31CA03663AFCA405A86E7D5C64A04DFBD13237BF65988E49ED3` |
| docs/audit/2026-09-29-startup-gtm/15_FINAL_STARTUP_GTM_GATE.md | `B32BCB3CC515CB08452E6BCD40B1E222D3460F29BD433385E04E7ED7B05DADE8` |
| docs/audit/2026-09-29-startup-gtm/DEFERRED_SCOPE.md | `0D0D797E499EC867A7EBB0954B8FAA8695ED0498C935EE0CF61B6A183D565503` |
| docs/audit/2026-09-29-startup-gtm/EVIDENCE_AND_VALIDATION.md | `C7C52C056C80E4393B700C175FAB6AADE73DA44D3393985C979AD27E1D9058CB` |
| docs/audit/2026-09-29-startup-gtm/README.md | `D0C0A2A347AE40CA2428C112D7910D58DEE1E8DD55F82065975711040EC8EA0E` |
| docs/remediation/phase-0-review/01_REVIEW_EXECUTIVE_SUMMARY.md | `219F1D64C86E2CF57A85A5C9C02EB47912C23FCC00B095DFF207A1E9504BE040` |
| docs/remediation/phase-0-review/02_BASELINE_VERIFICATION.md | `318D45B81283E03E74990004995A8B2FD9A0A0C213C9AFB84666019534370616` |
| docs/remediation/phase-0-review/03_TRACEABILITY_REVIEW.md | `51FE9E2C069C8285C0B67F8EE22345A13CF37325BBEEB1CF19CF1944DFE08E76` |
| docs/remediation/phase-0-review/04_MASTER_REGISTER_REVIEW.md | `50162269C93625939580D8849225AECECF54528F744E7EDE1A0C0FC31975D5A0` |
| docs/remediation/phase-0-review/05_SEVERITY_AND_BLOCKER_REVIEW.md | `E8FADF4EA29D263816FF2F619E8C60A79EFEB26F346810F11BEADF65BD0F2BAF` |
| docs/remediation/phase-0-review/06_DUAL_OS_ARCHITECTURE_REVIEW.md | `93E7C443089C3D5FBD5AAE1FE30E7034DCABB22F814987EAF284B011EB2EE44A` |
| docs/remediation/phase-0-review/07_LINUX_BASELINE_REVIEW.md | `3B042E9A27AEFBE9835EF23F121873341CE91C829B7C798AFDADC2DFBF24D95A` |
| docs/remediation/phase-0-review/08_WINDOWS_BASELINE_REVIEW.md | `22360CEDEB0C65CC2C5A368730AA2487DFBB3D1F1432CCF6A94E2D0FE71FFA59` |
| docs/remediation/phase-0-review/09_MAINTENANCE_AMS_UPGRADE_REVIEW.md | `5ACFBBF1D4ABBF335EAB3DE1128B3131C1BED26AC1C809D7E204C54B43A30ADF` |
| docs/remediation/phase-0-review/10_SECURITY_BOUNDARY_REVIEW.md | `23FBB4C06610E1BB8AFEF10378C342410C7390B5D7A786A6FE530973AFA0EDF6` |
| docs/remediation/phase-0-review/11_BACKUP_ALERTING_RECOVERY_REVIEW.md | `DCF4E372834B08A045479711F090ED2427682C6F9EFF5E7FFBA8401B6594B015` |
| docs/remediation/phase-0-review/12_DOCUMENTATION_TRUTH_REVIEW.md | `519C4C17FAFB55DADC34D6BB45B532483DF21A98B9A57112BB836F20F2CC5BE9` |
| docs/remediation/phase-0-review/13_PHASE_PLAN_REVIEW.md | `6962C2008E7E2708C79616C338D0FFAF799B221DEDF055A689C461F6D478A05B` |
| docs/remediation/phase-0-review/14_PHASE_1_SCOPE_RECOMMENDATION.md | `CD87AA3B1BF3202069C736DE8B40DF4813857CDE0A8027609D9C8A575378464E` |
| docs/remediation/phase-0-review/15_REVIEW_FINDINGS_REGISTER.md | `721772B1EF5229B1C3F4AA2E677C2A755F44FA1C1C0AFBA99339EAACCF01557A` |
| docs/remediation/phase-0-review/PHASE_0_REVIEW_FINAL_REPORT.md | `0DD5256C4EAFA234013643BDBD2F3470B4D34F54EABC2BEBE17B73206F1816B8` |
| docs/remediation/phase-0-review/README.md | `CED0F7F78DEE3CA2740C11DFB4A1CE6B08C7174CE005FB184A983DE52CBBF94C` |
| docs/remediation/phase-0/01_CURRENT_BASELINE.md | `A4FF5DE6173102CA854BFE2FA85D02C269F6CDD2DE64EB4BD86375BF5F538C53` |
| docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md | `21FC3AB33163F8F7CE7102767ADEECEA6C8306D4CA3C80D13FA8C1F0DCF5322D` |
| docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md | `179E76B993879DEA865AFF6F293ADD91A1171EAC6DA5E6AB36FFE4189EDDE1A0` |
| docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md | `88F6E4F4709EEE1799F22AEEFDAC31DB9B347F925D3625B73C62A31292ADEC05` |
| docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md | `73679CE46F04A8D6A94F177BF9D06137B1732798AB5526E415CE1F125C99F418` |
| docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md | `C2C845213946A397A19E6AD157E2F05F0EC5C9D0B2A80FCB5331D2DC3A7AAD2F` |
| docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md | `B1F26B3C5EA944253DAFD757C0B4D5DDA3690015712EC60BB9543F7ADAF5FE36` |
| docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md | `1C77286CBFB3BCE3A014888B46485F7F72F46A58BA3B70A3FB54F606449F5AE7` |
| docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md | `3CE726592A765283D59336CE34F01A962BDAAD45193CEED0F567ECC9AE24DFFA` |
| docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md | `7CEC8FCDD60B84FA8C61C9B0AEC3C87E0A5B9A5B140255429747B33DD8BC0801` |
| docs/remediation/phase-0/11_AMS_CURRENT_STATE.md | `20D4B2482B847A67B8DAFF9CF730EDE85327DA5599ACD1B6F3D35E6D28294B86` |
| docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md | `E162478CB069F1EFA49F0C71582F3FC350D4EC0424EB75E27AA9D9BCD422805B` |
| docs/remediation/phase-0/13_CI_TRUST_MODEL.md | `910F637B0FD4F71A84C28C3F43DBA0AACF22C0AAA3C1B7A67FEEF04F519C7377` |
| docs/remediation/phase-0/14_AI_FEATURE_CLASSIFICATION.md | `ED2363583F5777F4BEF5CAE8703A077E5D9E7615FB345465B69B1170A9D6715B` |
| docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md | `E0460AE452EA46C83CE29555231AB03A82D1F2C20C024342E795F74F8B3A20F4` |
| docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md | `EDAB08CD1D3EF29E54F782D41A9EC7825A84F90A793B2BB92323BFFF5BBB6E4A` |
| docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md | `85A088A68D62E950C30B66473882DE84C5BA803C55C506FAE36C43656FBF278C` |
| docs/remediation/phase-0/18_PHASE_0_EVIDENCE_INDEX.md | `5F31A1DBDFC16CFF78124D11DFAB6E3B071856C0196EDD0DE1B07572C69BCFC1` |
| docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md | `A364CDFA248621F94EB5FA36207D620B8667073B4D57B13E82AF574324A93DC5` |
| docs/remediation/phase-0/README.md | `7025E92AAE7DC14A967C0D14D31D51B91A833B52134A337989DCD6B491BC0F4C` |
