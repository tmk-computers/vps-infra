# Codex Phase 0 findings register

Audit date: 2026-09-29. These are defects or improvement requests for the baseline documents, not implementation fixes performed by Codex.

C0 = acceptance blocker; C1 = significant correction required; C2 = minor precision/clarity; C3 = advisory. Counts: **1 C0, 4 C1, 4 C2, 1 C3**.

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

## C0-01 — Release contract permits unsafe completion and database rollback

**Severity:** C0

**Exact artifact:** [07_DEPLOYMENT_SAFETY_CONTRACT.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md:54) §§2–4; [04_TARGET_ARCHITECTURE.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md:90); [12_UPGRADE_CURRENT_STATE.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md:119).

**Claim / contract:** “Mark DeploymentRecord as SUCCEEDED” precedes “Switch live traffic routing”; rollback says “If schema migration was executed and failed, restore pre-deploy DB snapshot.” Startup reconciliation promotes a healthy new release to SUCCEEDED without state-specific rules. The shared architecture promises “Zero-downtime rollback”.

**Source/code evidence:** The diagram acquires a lock after PREPARED, while PRECHECK acquires it in the prose; the first specified durable write is PREPARED, yet recovery queries PRECHECK. FAILED is terminal in the diagram, unlike the frozen summary's FAILED → ROLLBACK sequence. There is no deployment request idempotency key, atomic claim/ownership rule, stale-worker exclusion, or migration execution/compatibility decision table. APPLYING already starts/repoints live services, but SUCCEEDED describes a later routing switch. [Program.cs](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Program.cs:417) currently migrates at startup and lines 421–444 mark interrupted work; this is not a substitute for the proposed recovery contract. [upgrade-client.sh](D:/company/products/vps-infra/vps-infra/scripts/upgrade-client.sh:147) resets main and lines 170–178 report success without probing, so this contract is the authority intended to replace known unsafe behavior.

**Impact:** An implementation can comply literally yet record success before a failed cutover, replay side effects after restart, or automatically overwrite writes made after a database snapshot. A successful but backward-incompatible migration followed by application failure has no defined safe branch. This is a baseline defect, not a demand to implement the engine during Phase 0.

**Required correction:** Define one authoritative transition table, persisting intent before side effects; distinguish no-mutation precheck failure from compensating rollback. Define request deduplication, per-service atomic ownership and stale-worker handling using a bounded single-host mechanism where sufficient. Require cutover and post-cutover verification before terminal success. Record exact release/config/schema identities and trusted provenance. Define compatible application rollback, fenced/quiesced database restore with explicit data-loss policy, and RECOVERY_REQUIRED when safe automatic recovery is not proven. Remove unconditional zero-downtime/outage-prevented promises.

**Acceptance criterion:** A documentary walkthrough of duplicate requests, lock-holder death, crash before/after each side effect, cutover failure, successful incompatible migration plus failed application, and writes after snapshot yields one safe state/action for each scenario. Both Linux and IIS adapters use that same contract. No path marks success before verified serving or overwrites post-snapshot writes without an explicit approved recovery policy.

## C1-01 — Security acceptance contradicts platform/tenant role separation and omits token trust rules

**Severity:** C1

**Exact artifact:** [03_HISTORICAL_FINDING_TRACEABILITY.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md:58) DEF-11 and F02; [08_SECURITY_BOUNDARIES.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md) §2.4; [16_PHASEWISE_REMEDIATION_PLAN.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md:69) Phase 1.

**Claim / contract:** DEF-11 acceptance requires “New tenant registers organization and receives tenant-scoped SuperAdmin account.” Architecture §2.1 instead requires strict separation of platform SuperAdmin from tenant roles. F02 remediation reduces the original token trust requirements to generated secrets and default-key rejection.

**Source/code evidence:** [ci-server/api/auth.js](D:/company/products/vps-infra/vps-infra-server/ci-server/api/auth.js:82) explicitly gives SuperAdmin global role bypass. Its jwt.verify call at line 49 has no explicit issuer/audience/algorithm options. [original F02](D:/company/products/vps-infra/vps-infra-server/docs/audit/2026-09-29-main/evidence/findings.json) requires issuer, audience and algorithm validation plus rotation/invalidation and negative tests. [04_TARGET_ARCHITECTURE.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md:65) separates platform SuperAdmin from tenant roles. Merely forwarding a caller token or generating a service token for AMS does not specify its trust audience, delegated tenant authority or resource scope.

**Impact:** A developer following the onboarding acceptance can reuse a platform-wide role for customers. Randomizing a key alone can satisfy the shortened acceptance while leaving token substitution/trust-context issues ungoverned. This does not assert that a future properly scoped role with a similar name is inherently unsafe; the current conflicting contracts must be resolved.

**Required correction:** Use a distinct tenant administrator role or explicitly redefine and test every bypass so tenant administrators never inherit platform authority. Preserve F02 issuer/audience/algorithm, rotation and invalidation obligations. Specify the Windows and service-to-service authentication contract, TLS/peer validation, tenant/resource binding and replay/revocation behavior. Phase 1 establishes this reusable contract; limit legacy PowerShell changes to containment/compatibility and consume it in TMK.Agent.Windows in Phase 4.

**Acceptance criterion:** The baseline includes a role/permission matrix and negative criteria for tenant A accessing tenant B, tenant admin attempting platform actions, wrong issuer/audience/algorithm, old/default/revoked credentials, and improperly scoped AMS/agent requests. Each criterion has an MR owner and implementation phase.

## C1-02 — Recovery contract is incomplete and mixes incompatible archive verification rules

**Severity:** C1

**Exact artifact:** [09_BACKUP_RECOVERY_CONTRACT.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md:40) §§2–3; [06_DATABASE_SUPPORT_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md) §3; roadmap Phase 5.

**Claim / contract:** Stage 1 specifies “pg_dump -Fc” and requires “gzip -t”; Stage 2 specifies TLS transfer; Stage 3 accepts “remote MD5/ETag or SHA-256”; source-host-loss recovery uses “ONLY the remote credentials and the offsite backup archive”. Restore promises an “instantaneous” snapshot and reversion.

**Source/code evidence:** The frozen developer contract has no backup payload encryption/key-recovery stage, recovery-point catalog/manifest, backup retention policy, or explicit recovery-time/recovery-point acceptance target. Secret-vault encryption elsewhere does not define backup encryption or survival of its keys after host loss. The reviewer itself identifies absent local encryption and remote retention in 11_BACKUP_ALERTING_RECOVERY_REVIEW.md. PostgreSQL documents custom archives as pg_restore inputs with internal compression, not necessarily an outer gzip stream: [PostgreSQL 16 pg_dump](https://www.postgresql.org/docs/16/app-pgdump.html). Thus gzip -t cannot be the unconditional test for an unwrapped -Fc archive. Provider ETags must not be assumed to be content hashes without a provider-specific contract.

**Impact:** A conforming implementation could reject valid dumps, treat unsuitable metadata as integrity evidence, retain plaintext customer data, lose the only decryption key with the source host, or claim recoverability without a complete recovery set. A database dump alone cannot rebuild artifacts, uploads, roles, configuration and protected secrets for the entire platform.

**Required correction:** Specify capture → encrypt → transfer → verify → catalog recovery point → retain/expire → alert → restore, with format-aware checks and authenticated manifest metadata. Define recoverable key custody outside the source failure domain, protected artifact/config/upload/role dependencies, usable recovery-point selection, retention safeguards, and explicit RPO/RTO targets to be measured later. Separate application rollback from destructive database restore; remove instantaneous guarantees. Retain provider neutrality.

**Acceptance criterion:** A Phase 5 acceptance matrix covers tampering, upload/null failures, key loss/rotation, retention pressure and source-host loss using only the documented recovery kit. It states how both OS profiles recover and how measured RPO/RTO pass or fail. The chosen archive format has a valid verification/restore sequence; no S3-specific requirement is introduced.

## C1-03 — Windows Server control-plane and PostgreSQL topology is not frozen

**Severity:** C1

**Exact artifact:** [05_SUPPORTED_OS_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md) §4.2; [06_DATABASE_SUPPORT_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md) PostgreSQL topology; [04_TARGET_ARCHITECTURE.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md) Windows adapter.

**Claim / contract:** Windows Gate A requires “Full HTTP/API control-plane connectivity from Docker to Windows host” and Traefik/IIS coexistence. The only Gate-A PostgreSQL profile is “PostgreSQL 16 (Alpine)” on a Docker bridge. The Windows profile does not locate that Linux control plane/database or specify a supported container host.

**Source/code evidence:** [setup.ps1](D:/company/products/vps-infra/vps-infra/setup.ps1:61) directs installation of WSL2 and Docker Desktop in Linux-container mode. Docker states that Docker Desktop is not supported on Windows Server, including Server 2022: [Docker Windows installation requirements](https://docs.docker.com/desktop/setup/install/windows-install/). The frozen Phase 0 documents neither explicitly adopt a supported remote/VM/native topology nor place a topology decision gate before Windows implementation. Windows IIS hosting alone does not qualify WSL2 PostgreSQL or a Linux-only upgrade script.

**Impact:** Agent replacement does not resolve where the management stack, PostgreSQL, ingress and recovery tooling run on the Windows certification profile. Phase 4 can implement against an unsupported or undefined deployment premise; Phase 10 remains described only in Linux/Docker commands despite shared MR-19 scope.

**Required correction:** Choose and document one supported Windows Gate-A topology, or make its resolution a mandatory architecture decision before Phase 4 implementation. Locate control plane, PostgreSQL, agent, ingress/TLS and offsite recovery; specify network trust, reboot/service dependencies, resource accounting and upgrade responsibility. A separate Linux control plane may be valid if explicitly chosen; do not silently require WSL2, Docker Desktop, Kubernetes or additional HA.

**Acceptance criterion:** A topology diagram and deployment matrix identify every component's OS/runtime, supported installation path, database connection/security model and independent Windows recovery/upgrade tests. Windows certification cannot inherit Linux runtime evidence.

## C1-04 — Complete ID coverage hides lost or conflated remediation obligations

**Severity:** C1

**Exact artifact:** [03_HISTORICAL_FINDING_TRACEABILITY.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/03_HISTORICAL_FINDING_TRACEABILITY.md:41) F16, DEF-08, DEF-15; [16_PHASEWISE_REMEDIATION_PLAN.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md:90) Phase 3; [13_CI_TRUST_MODEL.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/13_CI_TRUST_MODEL.md).

**Claim / contract:** The traceability introduction says “No finding has been omitted or silently downgraded.” DEF-08 is labeled “Duplicate of Codex F01.” F16 maps to MR-07 with encryption and streaming-spend acceptance only; DEF-15 maps to secret-disclosure MR-04.

**Source/code evidence:** Original [F16 evidence](D:/company/products/vps-infra/vps-infra-server/docs/audit/2026-09-29-main/evidence/findings.json) includes LocalOnly policy precedence, cloud-fallback policy/spend rechecks and resource-governor admission, as well as plaintext keys/stream accounting. Those obligations have no explicit preserved acceptance or deferred re-enable gate in Phase 0. [ModelGatewayService.cs](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/ModelGatewayService.cs:202) still selects config policy when the request is LocalOnly; fallback begins at line 101. DEF-08 concerns the privileged management API's socket/host mounts ([infra Compose](D:/company/products/vps-infra/vps-infra/docker-compose.yml:72)), while F01 concerns executing untrusted tests with the production daemon. External CI addresses the latter but does not itself remove or govern management API privileges. DEF-15's path containment is present in its trace row but omitted from the Phase 1 MR-04 work description; the mapping needs an explicit owner/subtask rather than an implied secret fix.

**Impact:** The register can be closed by MR title/phase checklist while source obligations remain unaddressed. Disabled AI is acceptable for Gate A, but exclusion cannot erase security prerequisites for later re-enablement. Integrated CI qualification also needs negative evidence against production networks, metadata/credentials and volumes, not only a socket-path check.

**Required correction:** Keep the 37 MR IDs if desired, but add explicit sub-obligation/disposition rows: preserve every F16 safety path behind a disabled-until-qualified gate; distinguish CI-worker isolation from privileged control-plane authority under MR-01/security architecture; assign DEF-15 path containment to a clear phase and acceptance. Distinguish original severity/OS scope from current work-package scope, including shared F22 telemetry under Windows-scoped MR-25.

**Acceptance criterion:** A source-to-MR obligation checklist accounts for every original F02/F15/F16/F22 and DEF-08/DEF-15 acceptance requirement, or explicitly records a reasoned superseding/excluded disposition with re-enable criteria. Closing a parent MR requires all applicable child obligations; no extra feature implementation is required in Phase 0.

## C2-01 — Phase 0.5 is justified, but its schema-authority exception is undefined

**Severity:** C2

**Exact artifact:** [10_MAINTENANCE_MODE_CURRENT_STATE.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md) §3; architecture §2.7; roadmap Phase 0.5.

**Claim / contract:** MR-34 is still labeled Phase 1 in document 10. Phase 0.5 requires both a versioned migration and new raw seeder ALTER TABLE statements, while the frozen architecture prohibits raw seeder DDL.

**Source/code evidence:** MR-13 is assigned to Phase 2, so eventual consolidation is intended. However, neither a temporary compatibility exception nor removal/ownership rules for the newly duplicated DDL are specified.

**Impact:** Two schema authorities can diverge during the prerequisite intended to align schemas.

**Required correction:** Prefer one versioned migration path; if temporary idempotent compatibility DDL is necessary, state the supported starting schema, ordering, identical definitions, failure behavior and mandatory MR-13 removal milestone. Relabel document 10 as Phase 0.5.

**Acceptance criterion:** Fresh and existing PostgreSQL schemas are explicit test cases; all 13 fields/defaults and model snapshot are covered. The prerequisite is distinct from security work and does not claim to close the entire historical MR-13.

## C2-02 — Blocker labels and roadmap dependencies describe different pilot boundaries

**Severity:** C2

**Exact artifact:** [02_MASTER_REMEDIATION_REGISTER.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md:94); roadmap §§2–3; final report §5.

**Claim / contract:** Five items are called “Non-Blockers / Post-Pilot Work”; MR-30 is “Post-Pilot Diagnostic Tooling / Phase 8”. Yet Phases 6, 8 and 9 precede Phase 13. The chart chains Phase 4 after Phase 3 and both-OS Phase 11 before Phase 12, while prose allows staggered Linux qualification.

**Source/code evidence:** The detailed roadmap does retain MR-17 in Phase 6, MR-20 in Phase 3, MR-30 in Phase 8 and MR-21/MR-31 in Phase 9. No item has vanished. MR-37 remains a shared blocker with disclosure/full-labeling distinctions.

**Impact:** Terminology can be mistaken for permission to skip required operational safeguards, or for a requirement that Windows finish before any Linux pilot.

**Required correction:** Use technical-blocker versus mandatory scope/support prerequisite categories. State per-OS Phase 11/12 completion rules and the explicit staggered-pilot override. Any assisted substitute needs documented acceptance, not a blanket post-pilot label.

**Acceptance criterion:** The gate matrix identifies minimum pre-Phase-13 outcomes for all five items; unsafe cleanup is disabled or bounded, unsupported engines are blocked, truthful disclosure and support/recovery runbooks exist. Full tooling remains required by its phase unless explicitly substituted.

## C2-03 — Repository dossier does not contain the reported final reviewer PASS

**Severity:** C2

**Exact artifact:** [review final report](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-review/PHASE_0_REVIEW_FINAL_REPORT.md:7); reviewer README; developer baseline.

**Claim / contract:** The supplied task reports a completed independent re-review PASS. Local reviewer final report and README still state FAIL; PASS mentions are future instructions. Developer baseline describes clean/untracked documentation at the older implementation SHAs.

**Source/code evidence:** Both mirrors match. Current local HEADs are 72758f6c23fc76e62e059e382cf61106567668ab and dba08c63a37eb8d2c851f637d8a02a85cbab4604, with 12 modified Phase 0 documents per repository. Product content is unchanged. The corrected register is independently verifiable despite the stale review dossier.

**Impact:** Review history cannot be reproduced from the repository alone. This is not evidence that the reported external/chat re-review never happened and is not the sole reason for FAIL.

**Required correction:** Preserve the original FAIL review and append/link a signed-off re-review record identifying the corrected document hashes and closure evidence. Distinguish implementation baseline, documentation HEAD and working-tree candidate.

**Acceptance criterion:** A future reviewer can identify exactly which candidate passed the prior review without treating a conditional PASS sentence as a verdict.

## C2-04 — Some evidence wording and citations still overstate what was verified

**Severity:** C2

**Exact artifact:** [15_DOCUMENTATION_TRUTH_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md:31); evidence index §3.6; OS/database matrices; reviewer technical reports.

**Claim / contract:** Truth matrix gives exact 15–45s rollback and 5–20s outage ranges without runtime evidence. It attributes quoted rollback/S3 text to README lines 3/24, whose link resolves to the wrapper path. Evidence index places swallowed IIS health at 105–115. OS matrix marks lab tests YES without identified runs.

**Source/code evidence:** The actual [infra README](D:/company/products/vps-infra/vps-infra/README.md:3) has badges at line 3 onward and a documentation link at line 24; the cited quotations are not those lines. Agent health catch/success is at [server agent](D:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1:294) and 299, not 105–115. AST failures were reproduced without running the agent; SCM1053, exact HTTP400, timing and remote credential validity were not live reproduced here. MR-34's missing columns support a likely 42703 path for affected entity queries; not every query or startup necessarily reaches that path first.

**Impact:** These overstatements weaken an evidence-grounded freeze, although they do not invalidate the underlying open defects. A source hash/checksum proves identity/integrity, not trusted provenance by itself.

**Required correction:** Repair anchors and separate actual source quotes, static inference, historical assertion and live observation. Label test/certification cells as target or unverified unless a run is linked; retain the accurate source-versus-interpretation treatment already added for AMS.

**Acceptance criterion:** Every precise runtime claim has a reproducible run record, or is explicitly marked inferred/unverified; source quotations and locations resolve to the claimed text.

## C3-01 — Generate register summaries and candidate manifests mechanically

**Severity:** C3

**Exact artifact:** Master register, traceability matrix and future gate dossiers.

**Claim / contract:** Counts and mirrored summaries are maintained manually.

**Source/code evidence:** Independent parsing now confirms the corrected arithmetic, while earlier reviewer findings arose from manual drift.

**Impact:** Future document updates can reintroduce counting and mirror inconsistencies.

**Required correction:** Optionally generate count summaries, mapping-completeness checks and input hashes from the authoritative register. Avoid adding infrastructure solely for this purpose.

**Acceptance criterion:** A lightweight check detects duplicate/missing IDs, invalid targets, mismatched counts and divergent mirrors.


## Closure rule

C0-01 and C1-01 through C1-04 require corrected, internally consistent baseline contracts and explicit source-obligation preservation before a PASS. Code implementation is not required to close these Phase 0 documentary defects. C2 clarifications should be incorporated into the resubmitted baseline; C3 is advisory. Do not erase the prior Reviewer FAIL or retroactively rewrite historical evidence.
