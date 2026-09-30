# Focused re-gate findings register

Audit date: 2026-09-30. C0 acceptance blocker; C1 significant correction; C2 precision/clarity; C3 advisory.

## Original findings

| Original severity | Resolved | Unresolved |
|---|---:|---:|
| C0 | 0 | 1 |
| C1 | 0 | 4 |
| C2 | 2 | 2 |
| C3 | 0 | 1 |
| Total | 2 | 8 |

New findings: **C0 0; C1 3; C2 2; C3 1**. Retained original findings and new findings are tracked separately; a failed recheck is not a newly discovered finding. RG-C1-02 describes the newly invented schema inventory; C2-01 retains the distinct pre-existing schema-authority issue.

| Original ID | Original severity | Re-gate result | Remaining issue / closure |
|---|---|---|---|
| C0-01 | C0 | FAIL | Release and upgrade recovery contracts still permit unsafe actions |
| C1-01 | C1 | FAIL | Role separation is corrected, but token acceptance remains inconsistent |
| C1-02 | C1 | FAIL | Recovery validation and source-host-loss acceptance remain incomplete |
| C1-03 | C1 | FAIL | Windows topology is selected but conflicting implementation and recovery instructions remain |
| C1-04 | C1 | FAIL | Substantive historical obligations still lack complete preservation |
| C2-01 | C2 | FAIL | Phase 0.5 sole-schema-authority acceptance is still contradictory |
| C2-02 | C2 | PASS | Minimum pilot prerequisites and staggered qualification are explicit |
| C2-03 | C2 | PASS | Separate historical review verdicts are now preserved |
| C2-04 | C2 | FAIL | Evidence precision improves but unsupported claims and incorrect source descriptions remain |
| C3-01 | C3 | FAIL | Integrity script checks counts and selected mirrors, not semantic ID integrity |

### C0-01 — C0, unresolved

**Evidence:** [12_UPGRADE_CURRENT_STATE.md:125](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md:125) still mandates automatic pre-upgrade DB restore after failed health. [07_DEPLOYMENT_SAFETY_CONTRACT.md:162](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md:162) applies blanket pre-cutover cleanup/FAILED; lines 178–179 drop a column still used by the rollback release. [02_RELEASE_CONTRACT_CORRECTION.md:174](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/02_RELEASE_CONTRACT_CORRECTION.md:174) fences database updates only.

**Impact / assessment:** Correct ordering, idempotency, immutable identity and public verification are credited. A database version CAS does not exclude a paused worker that resumes an already-authorized ingress mutation. A crash after irreversible migration must not fall through a generic FAILED branch that assumes the old release still works. The Phase 10 restore instruction alone keeps the original C0 open.

**Required correction:** Make deployment and platform upgrade share the no-automatic-DB-restore rule. Reconcile each crash window using durable schema/effect evidence, fence physical mutations or prove old-worker termination, and retain schema compatibility with every eligible rollback binary. Explicitly route incompatible/uncertain outcomes to RECOVERY_REQUIRED.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.

### C1-01 — C1, unresolved

**Evidence:** [08_SECURITY_BOUNDARIES.md:104](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:104) and remediation security §3.1 define multiple issuers; [03_SECURITY_CONTRACT_CORRECTION.md:90](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/03_SECURITY_CONTRACT_CORRECTION.md:90) requires the auth issuer for every API. Authoritative §4 and supplementary §4.1 do not cover all original negative cases: wrong issuer, historical signing key, and valid-but-wrongly-scoped agent/AMS credentials.

**Impact / assessment:** PlatformSuperAdmin/TenantAdmin separation and tenant/platform negative tests pass. Revoked and expired tokens appear in the supplement; they are not absent everywhere. The universal issuer rule rejects the dossier's own CI/AMS identities. Missing-token tests are not substitutes for wrong-scope valid-token tests. Redis is separately recorded as new RG-C1-01; break-glass precision is RG-C2-02.

**Required correction:** Use a service-specific issuer/audience/algorithm/key/subject/tenant/scope trust matrix consistently. Bind every original negative case to Phase 1 MR-02/MR-08/MR-28/MR-36 as appropriate, including retired keys and valid but unauthorized service credentials. Correct the supplementary MR ownership table.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.

### C1-02 — C1, unresolved

**Evidence:** [04_BACKUP_RECOVERY_CORRECTION.md:144](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/04_BACKUP_RECOVERY_CORRECTION.md:144) wrongly credits pg_restore --list with checking compression blocks. §4.2 derives a KEK using Salt without locating recoverable derivation metadata in the documented kit; §6 includes secret envelope hashes without specifying recovery of the protected secrets themselves. Authoritative backup §§2–3 and Phase 5 lack the complete original failure matrix.

**Impact / assessment:** The seven-stage pipeline, encryption, off-host custody intent, remote digest verification, retention safeguards and target RPO/RTO are substantial improvements. BIP-39 is not required by the original finding; no particular recovery phrase or KDF is mandated here. This is a completeness/technical-accuracy gap, not a demand for a live Phase 0 recovery implementation.

**Required correction:** State the limited TOC/parse evidence from --list; retain mandatory actual restore drills with exit-code and data checks. Define a self-sufficient, independently recoverable kit/catalog including the nonsecret key-derivation/wrapping metadata and protected configuration/roles/artifact dependencies. Add the original tamper, null/upload, rotation/key-loss, retention, and both-OS host-loss acceptance matrix with measured RPO/RTO pass/fail.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.

### C1-03 — C1, unresolved

**Evidence:** [05_SUPPORTED_OS_MATRIX.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md) selects native IIS/remote PostgreSQL and excludes host Traefik; [16_PHASEWISE_REMEDIATION_PLAN.md:113](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md:113) still requires IIS/Traefik coexistence. [05_WINDOWS_TOPOLOGY_CORRECTION.md:84](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:84) permits Trust Server Certificate=true. Agent update §5 uses service-running/crash checks, while functional-health and reboot-recovery requirements remain in the R3 review proposal rather than the frozen implementation contract.

**Impact / assessment:** Linux control-plane placement, IIS 10/HTTP.sys/ANCM, compiled agent, remote PostgreSQL 16, and independent Windows Gate A are credited. This FAIL is not based solely on LocalService naming (RG-C2-01) or absent runtime implementation.

**Required correction:** Propagate the chosen topology through MR-27, historical disposition and Phase 4 acceptance. Require authenticated TLS to the remote database. Adopt independent Windows update/restore acceptance covering integrity, safe stop/replacement/restart, functional health, rollback and power loss/reboot. No particular updater binary is required.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.

### C1-04 — C1, unresolved

**Evidence:** Original findings.json F15 requires execution-time reauthorization, crash reconciliation and clock-hour stability; authoritative trace F15 retains only concurrency/state-hash acceptance. F22 requires tenant/resource cache keys, TTL/session bounds and unknown-telemetry fail-closed behavior; trace F22 preserves tenant cache isolation/real memory but the new supplement §5 replaces it with an unrelated I/O-buffer story. F16.5 remains MR-17 in the authoritative row, not only the supplement.

**Impact / assessment:** All IDs exist. The five broad F16 obligations and disable-until-qualified gate, F01 versus DEF-08 distinction, and DEF-15 owner/Phase 1/negative traversal test are credited. MR-04 is an acceptable explicit owner; no extra MR is required. F16.5's label alone is precision, not the reason for FAIL. Unsafe path pseudocode is new RG-C1-03.

**Required correction:** Complete a source-obligation checklist for F02/F15/F16/F22 and DEF-08/DEF-15 with every applicable criterion or explicit exclusion plus re-enable criteria. Preserve F15 crash/reauthorization/time stability, F16 atomic concurrent spend/key rotation/missing telemetry, and F22 bounded caches/unknown telemetry. Align F16.5 with MR-16 and require child completion before parent closure.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.

### C2-01 — C2, unresolved

**Evidence:** [10_MAINTENANCE_MODE_CURRENT_STATE.md:92](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/10_MAINTENANCE_MODE_CURRENT_STATE.md:92) forbids competing DDL but defers existing DDL removal to Phase 2. [Program.cs:417](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Program.cs:417) runs migration then DataSeeder; [DataSeeder.cs:46](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs:46) still has schema-changing ALTER/CREATE and catches migration errors. The referenced acceptance document tests the wrong fields (new RG-C1-02).

**Impact / assessment:** Phase 0.5 labeling is fixed and five PostgreSQL test categories are now present. Existing raw DDL is not only harmless CREATE IF NOT EXISTS for Projects/Deployments as R3 states: it alters Projects/ProjectServices and creates other tables. A pending-migration log alone does not prove repeat startup executes no DDL.

**Required correction:** Make Phase 0.5 acceptance prove the supported existing/fresh schema via EF migrations and matching snapshot, without the seeder repairing or mutating it. Remove/disable the schema-changing seeder path before that acceptance, migrating any necessary legacy schema responsibility through versioned migrations. Keep unrelated MR-13 work in Phase 2.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.

### C2-04 — C2, unresolved

**Evidence:** Authoritative truth matrix still quotes S3/rollback claims against the wrapper README path. Remediation release §8 states rollback within 2–5 seconds without a run record. R3 schema §3.2 inaccurately describes the seeder DDL; R3 crypto §6.2 overstates --list guarantees. OS lab status and IIS catch anchors are improved.

**Impact / assessment:** The audit does not treat proposed health windows or RPO/RTO targets as measurements. Current HEAD metadata in this re-gate supersedes old candidate metadata for present status, while historical reports remain immutable.

**Required correction:** Correct source quotations/paths and static-code descriptions. Mark estimates as targets, retain unexecuted/live-test distinctions, and remove claims that the inspection or tools prove more than they do.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.

### C3-01 — C3, unresolved

**Evidence:** verify-baseline-integrity.ps1 executed successfully (exit 0): 37 MR rows; 33/3/1 statuses; 22 F/37 DEF rows; 48 mirrored MD files. Static inspection shows no distinct-ID set check, missing-ID replacement detection, target validation or reverse file-set check; R3/Codex gate directories are excluded.

**Impact / assessment:** Both PowerShell files are authorized governance tooling, tracked in both latest commits. mirror-to-infra.ps1 mutates documents and was inspected but not executed. Independent re-gate checks found no current duplicate/missing IDs, invalid MR targets or mirror mismatch.

**Required correction:** Advisory: compare exact expected ID sets and uniqueness, validate each MR reference, check both mirror file sets and relevant dossier scope, and describe the actual checks accurately.

**Acceptance:** The original criterion is retained verbatim in [02_ORIGINAL_FINDINGS_REVERIFICATION.md](02_ORIGINAL_FINDINGS_REVERIFICATION.md). The domain reports identify the remaining documentary counterexamples.


## New findings introduced or carried forward for this re-gate

Counts: **0 C0, 3 C1, 2 C2, 1 C3**. The three C1 findings concern materially unsafe/incorrect new remediation instructions. C2/C3 entries carry R3 refinements and are not independently gate-blocking.

| New ID | Severity | Finding |
|---|---|---|
| RG-C1-01 | C1 | New Redis revocation dependency contradicts Gate A |
| RG-C1-02 | C1 | New Phase 0.5 field inventory does not match the actual entities |
| RG-C1-03 | C1 | New containment pseudocode accepts sibling paths with a shared prefix |
| RG-C2-01 | C2 | R3 service-identity correction has not reached the authoritative Windows contract |
| RG-C2-02 | C2 | R3 break-glass refinement remains outside the authoritative security baseline |
| RG-C3-01 | C3 | Parameterize application health defaults in Phase 2 |

### RG-C1-01 — New Redis revocation dependency contradicts Gate A

**Severity:** C1

**Evidence:** [08_SECURITY_BOUNDARIES.md:110](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:110) explicitly requires a Redis denylist, while database matrix §2–3 excludes Redis and R3 security §3.2 says not to introduce it.

**Impact:** A conforming Phase 1 implementation either adds an unapproved runtime dependency or cannot satisfy its revocation contract.

**Required correction:** Define revocation capability without Redis dependence; choose a Gate-A-compatible mechanism with explicit restart/expiry/invalidation behavior. Verify the same policy in architecture, token matrix, scope and tests.

**Acceptance criterion:** Gate A can satisfy all revocation and retired-credential tests on the approved profile without Redis. No authoritative row requires excluded infrastructure.

### RG-C1-02 — New Phase 0.5 field inventory does not match the actual entities

**Severity:** C1

**Evidence:** [07_PHASE_0_5_SCHEMA_AUTHORITY.md:53](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/07_PHASE_0_5_SCHEMA_AUTHORITY.md:53) names nonexistent Infrastructure/Entities maintenance entities and a different 13-column set. Roadmap line 72, entry criteria §3.1 and Phase 0 final §8.1 repeat MaintenanceWindows. Authoritative document 10 §2.1 and actual Data/Entities/Product.cs and ProjectService.cs identify the real eight-plus-five maintenance properties.

**Impact:** The prescribed migration/test contract can target unrelated tables and leave the original missing-column failure unresolved. This newly introduced substantive defect is more than the original C2 schema-authority wording issue.

**Required correction:** Replace invented table/column inventory and acceptance queries with the actual 13 properties, explicit nullability/backfill/default semantics and model snapshot. Preserve existing row values, including inactive rows; do not reinterpret IsActive as a new maintenance default.

**Acceptance criterion:** One consistent source-derived 13-field inventory appears in the schema contract, roadmap and entry criteria. Real PostgreSQL existing/fresh/repeat-startup tests hydrate both actual entities, inspect all fields/history/snapshot and preserve all existing data. Tests do not rely on DataSeeder DDL.

### RG-C1-03 — New containment pseudocode accepts sibling paths with a shared prefix

**Severity:** C1

**Evidence:** [06_HISTORICAL_OBLIGATION_RECONCILIATION.md:78](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/06_HISTORICAL_OBLIGATION_RECONCILIATION.md:78) checks StartsWith(tenantSandboxRoot, OrdinalIgnoreCase). Read-only evaluation: root C:\\inetpub\\wwwroot\\apps\\tenant-a and absolute input C:\\inetpub\\wwwroot\\apps\\tenant-ab\\artifact.zip return PrefixAccepted=true with no '..'.

**Impact:** The supplied implementation rule can approve an outside-tenant destination despite satisfying the prefix/no-dot-dot checks. This is a demonstrated defect in the new specification example, not a claim of a newly executed production exploit.

**Required correction:** Specify containment by normalized path segments and OS-correct comparison; reject rooted escapes, sibling-prefix collisions and link/reparse traversal under the required sandbox policy. Amend the pseudocode before adopting it as Phase 1/4 guidance.

**Acceptance criterion:** Documented negative cases reject sibling-prefix, absolute outside-root and traversal paths on each OS; tenant A cannot target tenant B even when names share a prefix. Owner MR-04/Phase 1 and Windows MR-24/Phase 4 can remain.

### RG-C2-01 — R3 service-identity correction has not reached the authoritative Windows contract

**Severity:** C2

**Evidence:** Architecture §4.1, OS matrix and remediation Windows §4 still specify LocalService, with read-only IIS configuration in the supplement; R3 proposes explicit delegated permissions.

**Impact:** Required IIS mutations need a clear permission contract. This is not independently promoted to a topology blocker solely because an account is named.

**Required correction:** State a dedicated least-privilege service identity with explicitly granted required IIS/filesystem/service permissions and Phase 4 positive/negative tests; choose the concrete identity during implementation.

**Acceptance criterion:** Authoritative contract specifies required grants and forbidden access; Phase 4 must verify both. No reliance on undocumented default LocalService privileges.

### RG-C2-02 — R3 break-glass refinement remains outside the authoritative security baseline

**Severity:** C2

**Evidence:** Architecture §2.1/security §2.4 promise zero customer data access; supplementary role matrix allows customer-consented container execution; R3 security §2.2 proposes governance.

**Impact:** The ordinary permission boundary and exceptional support/DR access are not described consistently. No newly proven tenant-bypass implementation is asserted.

**Required correction:** Either substantiate prevention or define exceptional access: authorized purpose, tenant/ticket context, least privilege, short-lived elevation, immutable audit and revocation/expiry.

**Acceptance criterion:** One coherent normal-access/exception rule is referenced by security and support/DR contracts. This precision issue alone does not fail Phase 0.

### RG-C3-01 — Parameterize application health defaults in Phase 2

**Severity:** C3

**Evidence:** Release contract uses HTTP 200, 30 seconds and 5xx <1%; R3 release §3 correctly distinguishes configurable readiness from universal constants.

**Impact:** Fixed examples do not fit every supported service, but affirmative serving/readiness evidence is now an explicit success prerequisite.

**Required correction:** Treat these as profile defaults; persist and evaluate the declared application health contract with affirmative evidence.

**Acceptance criterion:** Phase 2 acceptance demonstrates that SUCCEEDED means the intended release satisfies its declared contract. Exact threshold selection is not a Phase 0 blocker.


## Closure rule

Resolve the original C0/C1 acceptance gaps and new C1 material contradictions in a consistent authoritative candidate; then obtain a new independent review and focused re-gate. Preserve original review/gate reports and append new decisions. C2 refinements should be incorporated, and C3 remains advisory. No implementation work or new operational infrastructure is required to close Phase 0 documentary findings.
