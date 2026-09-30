# Original Codex findings — focused reverification

Audit date: 2026-09-30. Original IDs and severities are retained. Acceptance text below is carried from the original [06_CODEX_FINDINGS_REGISTER.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md); current evidence is evaluated independently of Developer/R3 resolution labels.

| Codex ID | Original Severity | Original Acceptance Criterion | Current Evidence | PASS/FAIL |
|---|---|---|---|---|
| C0-01 | C0 | A documentary walkthrough of duplicate requests, lock-holder death, crash before/after each side effect, cutover failure, successful incompatible migration plus failed application, and writes after snapshot yields one safe state/action for each scenario. Both Linux and IIS adapters use that same contract. No path marks success before verified serving or overwrites post-snapshot writes without an explicit approved recovery policy. | [12_UPGRADE_CURRENT_STATE.md:125](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md:125) still mandates automatic pre-upgrade DB restore after failed health. [07_DEPLOYMENT_SAFETY_CONTRACT.md:162](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md:162) applies blanket pre-cutover cleanup/FAILED; lines 178–179 drop a column still used by the rollback release. [02_RELEASE_CONTRACT_CORRECTION.md:174](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/02_RELEASE_CONTRACT_CORRECTION.md:174) fences database updates only. | **FAIL** |
| C1-01 | C1 | The baseline includes a role/permission matrix and negative criteria for tenant A accessing tenant B, tenant admin attempting platform actions, wrong issuer/audience/algorithm, old/default/revoked credentials, and improperly scoped AMS/agent requests. Each criterion has an MR owner and implementation phase. | [08_SECURITY_BOUNDARIES.md:104](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:104) and remediation security §3.1 define multiple issuers; [03_SECURITY_CONTRACT_CORRECTION.md:90](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/03_SECURITY_CONTRACT_CORRECTION.md:90) requires the auth issuer for every API. Authoritative §4 and supplementary §4.1 do not cover all original negative cases: wrong issuer, historical signing key, and valid-but-wrongly-scoped agent/AMS credentials. | **FAIL** |
| C1-02 | C1 | A Phase 5 acceptance matrix covers tampering, upload/null failures, key loss/rotation, retention pressure and source-host loss using only the documented recovery kit. It states how both OS profiles recover and how measured RPO/RTO pass or fail. The chosen archive format has a valid verification/restore sequence; no S3-specific requirement is introduced. | [04_BACKUP_RECOVERY_CORRECTION.md:144](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/04_BACKUP_RECOVERY_CORRECTION.md:144) wrongly credits pg_restore --list with checking compression blocks. §4.2 derives a KEK using Salt without locating recoverable derivation metadata in the documented kit; §6 includes secret envelope hashes without specifying recovery of the protected secrets themselves. Authoritative backup §§2–3 and Phase 5 lack the complete original failure matrix. | **FAIL** |
| C1-03 | C1 | A topology diagram and deployment matrix identify every component's OS/runtime, supported installation path, database connection/security model and independent Windows recovery/upgrade tests. Windows certification cannot inherit Linux runtime evidence. | [05_SUPPORTED_OS_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md) selects native IIS/remote PostgreSQL and excludes host Traefik; [16_PHASEWISE_REMEDIATION_PLAN.md:113](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md:113) still requires IIS/Traefik coexistence. [05_WINDOWS_TOPOLOGY_CORRECTION.md:84](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:84) permits Trust Server Certificate=true. Agent update §5 uses service-running/crash checks, while functional-health and reboot-recovery requirements remain in the R3 review proposal rather than the frozen implementation contract. | **FAIL** |
| C1-04 | C1 | A source-to-MR obligation checklist accounts for every original F02/F15/F16/F22 and DEF-08/DEF-15 acceptance requirement, or explicitly records a reasoned superseding/excluded disposition with re-enable criteria. Closing a parent MR requires all applicable child obligations; no extra feature implementation is required in Phase 0. | Original findings.json F15 requires execution-time reauthorization, crash reconciliation and clock-hour stability; authoritative trace F15 retains only concurrency/state-hash acceptance. F22 requires tenant/resource cache keys, TTL/session bounds and unknown-telemetry fail-closed behavior; trace F22 preserves tenant cache isolation/real memory but the new supplement §5 replaces it with an unrelated I/O-buffer story. F16.5 remains MR-17 in the authoritative row, not only the supplement. | **FAIL** |
| C2-01 | C2 | Fresh and existing PostgreSQL schemas are explicit test cases; all 13 fields/defaults and model snapshot are covered. The prerequisite is distinct from security work and does not claim to close the entire historical MR-13. | [10_MAINTENANCE_MODE_CURRENT_STATE.md:92](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md:92) forbids competing DDL but defers existing DDL removal to Phase 2. [Program.cs:417](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Program.cs:417) runs migration then DataSeeder; [DataSeeder.cs:46](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs:46) still has schema-changing ALTER/CREATE and catches migration errors. The referenced acceptance document tests the wrong fields (new RG-C1-02). | **FAIL** |
| C2-02 | C2 | The gate matrix identifies minimum pre-Phase-13 outcomes for all five items; unsafe cleanup is disabled or bounded, unsupported engines are blocked, truthful disclosure and support/recovery runbooks exist. Full tooling remains required by its phase unless explicitly substituted. | Master register §3 and roadmap §2 explicitly bound MR-17/20/21/30/31 before Phase 13, preserve assigned delivery phases, and permit Phase 12A/13A Linux pilot while Windows continues to 12B; Phase 15 requires both OS tracks. | **PASS** |
| C2-03 | C2 | A future reviewer can identify exactly which candidate passed the prior review without treating a conditional PASS sentence as a verdict. | Committed phase-0-review/PHASE_0_REVIEW_R2_FINAL_REPORT.md explicitly records PASS, the previous documentation HEADs and 12-artifact candidate context. Original Reviewer FAIL hashes match the prior audit manifest; all eight original Codex gate reports match prior content. R3 is a separate committed dossier. | **PASS** |
| C2-04 | C2 | Every precise runtime claim has a reproducible run record, or is explicitly marked inferred/unverified; source quotations and locations resolve to the claimed text. | Authoritative truth matrix still quotes S3/rollback claims against the wrapper README path. Remediation release §8 states rollback within 2–5 seconds without a run record. R3 schema §3.2 inaccurately describes the seeder DDL; R3 crypto §6.2 overstates --list guarantees. OS lab status and IIS catch anchors are improved. | **FAIL** |
| C3-01 | C3 | A lightweight check detects duplicate/missing IDs, invalid targets, mismatched counts and divergent mirrors. | verify-baseline-integrity.ps1 executed successfully (exit 0): 37 MR rows; 33/3/1 statuses; 22 F/37 DEF rows; 48 mirrored MD files. Static inspection shows no distinct-ID set check, missing-ID replacement detection, target validation or reverse file-set check; R3/Codex gate directories are excluded. | **FAIL** |

## Result arithmetic

| Original severity | Resolved | Unresolved |
|---|---:|---:|
| C0 | 0 | 1 |
| C1 | 0 | 4 |
| C2 | 2 | 2 |
| C3 | 0 | 1 |
| Total | 2 | 8 |

New findings: **C0 0; C1 3; C2 2; C3 1**. Retained original findings and new findings are tracked separately; a failed recheck is not a newly discovered finding. RG-C1-02 describes the newly invented schema inventory; C2-01 retains the distinct pre-existing schema-authority issue.

## Finding-by-finding disposition

### C0-01 — FAIL

Correct ordering, idempotency, immutable identity and public verification are credited. A database version CAS does not exclude a paused worker that resumes an already-authorized ingress mutation. A crash after irreversible migration must not fall through a generic FAILED branch that assumes the old release still works. The Phase 10 restore instruction alone keeps the original C0 open.

**Required closure:** Make deployment and platform upgrade share the no-automatic-DB-restore rule. Reconcile each crash window using durable schema/effect evidence, fence physical mutations or prove old-worker termination, and retain schema compatibility with every eligible rollback binary. Explicitly route incompatible/uncertain outcomes to RECOVERY_REQUIRED.

### C1-01 — FAIL

PlatformSuperAdmin/TenantAdmin separation and tenant/platform negative tests pass. Revoked and expired tokens appear in the supplement; they are not absent everywhere. The universal issuer rule rejects the dossier's own CI/AMS identities. Missing-token tests are not substitutes for wrong-scope valid-token tests. Redis is separately recorded as new RG-C1-01; break-glass precision is RG-C2-02.

**Required closure:** Use a service-specific issuer/audience/algorithm/key/subject/tenant/scope trust matrix consistently. Bind every original negative case to Phase 1 MR-02/MR-08/MR-28/MR-36 as appropriate, including retired keys and valid but unauthorized service credentials. Correct the supplementary MR ownership table.

### C1-02 — FAIL

The seven-stage pipeline, encryption, off-host custody intent, remote digest verification, retention safeguards and target RPO/RTO are substantial improvements. BIP-39 is not required by the original finding; no particular recovery phrase or KDF is mandated here. This is a completeness/technical-accuracy gap, not a demand for a live Phase 0 recovery implementation.

**Required closure:** State the limited TOC/parse evidence from --list; retain mandatory actual restore drills with exit-code and data checks. Define a self-sufficient, independently recoverable kit/catalog including the nonsecret key-derivation/wrapping metadata and protected configuration/roles/artifact dependencies. Add the original tamper, null/upload, rotation/key-loss, retention, and both-OS host-loss acceptance matrix with measured RPO/RTO pass/fail.

### C1-03 — FAIL

Linux control-plane placement, IIS 10/HTTP.sys/ANCM, compiled agent, remote PostgreSQL 16, and independent Windows Gate A are credited. This FAIL is not based solely on LocalService naming (RG-C2-01) or absent runtime implementation.

**Required closure:** Propagate the chosen topology through MR-27, historical disposition and Phase 4 acceptance. Require authenticated TLS to the remote database. Adopt independent Windows update/restore acceptance covering integrity, safe stop/replacement/restart, functional health, rollback and power loss/reboot. No particular updater binary is required.

### C1-04 — FAIL

All IDs exist. The five broad F16 obligations and disable-until-qualified gate, F01 versus DEF-08 distinction, and DEF-15 owner/Phase 1/negative traversal test are credited. MR-04 is an acceptable explicit owner; no extra MR is required. F16.5's label alone is precision, not the reason for FAIL. Unsafe path pseudocode is new RG-C1-03.

**Required closure:** Complete a source-obligation checklist for F02/F15/F16/F22 and DEF-08/DEF-15 with every applicable criterion or explicit exclusion plus re-enable criteria. Preserve F15 crash/reauthorization/time stability, F16 atomic concurrent spend/key rotation/missing telemetry, and F22 bounded caches/unknown telemetry. Align F16.5 with MR-16 and require child completion before parent closure.

### C2-01 — FAIL

Phase 0.5 labeling is fixed and five PostgreSQL test categories are now present. Existing raw DDL is not only harmless CREATE IF NOT EXISTS for Projects/Deployments as R3 states: it alters Projects/ProjectServices and creates other tables. A pending-migration log alone does not prove repeat startup executes no DDL.

**Required closure:** Make Phase 0.5 acceptance prove the supported existing/fresh schema via EF migrations and matching snapshot, without the seeder repairing or mutating it. Remove/disable the schema-changing seeder path before that acceptance, migrating any necessary legacy schema responsibility through versioned migrations. Keep unrelated MR-13 work in Phase 2.

### C2-02 — PASS

Cleanup must be disabled/bounded with rollback/volume protection; unsupported engines rejected; truthful disclosure, diagnostic triage and assisted support runbooks are mandatory. These items are not optional forever.

**Required closure:** No further original-criterion correction required. Read the explicit staggered-pilot override alongside the schematic Gantt dependencies.

### C2-03 — PASS

History can now be followed as Reviewer FAIL → remediation → R2 PASS → Codex FAIL → remediation → R3 PASS → this re-gate. The prior Codex evidence manifest identifies the contemporaneously inspected candidate; R2 itself is not a new per-file hash attestation. Presence of the R2 signature block is not independent verification of authorship or a retroactive endorsement of its conclusions.

**Required closure:** No further correction required for the requested review-history re-gate. Preserve these reports and append future decisions; do not rewrite their historical HEAD metadata to current HEADs.

### C2-04 — FAIL

The audit does not treat proposed health windows or RPO/RTO targets as measurements. Current HEAD metadata in this re-gate supersedes old candidate metadata for present status, while historical reports remain immutable.

**Required closure:** Correct source quotations/paths and static-code descriptions. Mark estimates as targets, retain unexecuted/live-test distinctions, and remove claims that the inspection or tools prove more than they do.

### C3-01 — FAIL

Both PowerShell files are authorized governance tooling, tracked in both latest commits. mirror-to-infra.ps1 mutates documents and was inspected but not executed. Independent re-gate checks found no current duplicate/missing IDs, invalid MR targets or mirror mismatch.

**Required closure:** Advisory: compare exact expected ID sets and uniqueness, validate each MR reference, check both mirror file sets and relevant dossier scope, and describe the actual checks accurately.


## Review-history interpretation

C2-03 passes the requested history check: an explicit R2 PASS and separate R3 record now exist, and the original FAIL records remain preserved. This does not adopt R2/R3 technical conclusions or invent a review timestamp/hash signature. The exact current candidate is fixed by the two new commit SHAs and the input manifest in this dossier's README.

Original C2/C3 failures are not independently used as substitute C0/C1 blockers. The final FAIL follows the remaining original C0/C1 criteria and the three new material C1 contradictions.
