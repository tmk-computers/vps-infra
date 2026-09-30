# Final re-gate findings register

Date: 2026-09-30. C0 = acceptance blocker; C1 = significant correction; C2 = precision/clarity; C3 = advisory.

Previous findings: **12 resolved, 4 unresolved**, out of 16. Unresolved: **RG-C1-02 (C1), C2-01 (C2), C2-04 (C2), C3-01 (C3)**. Substantial partial corrections are credited below; FAIL means the original acceptance condition is not fully satisfied.

New findings: **C0: 0; C1: 1; C2: 1; C3: 0**. Retained findings are not counted again as new.

## Retained unresolved findings

| ID | Severity | Current disposition | Gate impact |
|---|---|---|---|
| RG-C1-02 | C1 | FAIL: wrong active entity/migration inventory and timestamp mapping | Acceptance-blocking |
| C2-01 | C2 | FAIL: summary still defers raw DDL removal despite corrected prerequisite | Reconcile authority wording |
| C2-04 | C2 | FAIL: incorrect source citations/descriptions and overclaimed evidence | Correct evidence record |
| C3-01 | C3 | FAIL: incomplete verifier scope/negative behavior | Advisory; not independently blocking |

### RG-C1-02 — source-derived schema contract remains inconsistent

**Evidence:** [canonical final report:171](../phase-0/PHASE_0_FINAL_REPORT.md) still includes MaintenanceWindow and AddMaintenanceModeEntities. [inventory §3](../phase-0-codex-regate-remediation/06_PHASE_0_5_SCHEMA_INVENTORY.md) specifies timestamp with time zone, while [ApplicationDbContext.cs:44](D:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/ApplicationDbContext.cs:44) configures timestamp without time zone.

**Impact:** An implementer can follow the prescribed inventory and create a migration inconsistent with the actual model or target a nonexistent entity. Correctly counting thirteen properties does not resolve this.

**Required correction / acceptance:** Reconcile all active canonical entry points with Product's eight and ProjectService's five real properties and their configured types/nullability. Distinguish observed C# initialization from explicit future backfill/store-default decisions. Preserve existing IsActive values. Remove or explicitly supersede obsolete entity/migration instructions. Specify later existing/fresh/repeat-startup PostgreSQL acceptance against the actual snapshot/history and both entities, without seeder repair. No migration implementation is requested during this audit.

### C2-01 — residual sole-authority contradiction

**Evidence:** Detailed documents 10:92, 16:73 and 17:41 correctly require neutralization before Phase 0.5 acceptance; the active final report:171 still says raw DDL removal is Phase 2.

**Required correction / acceptance:** Make the final summary agree with the prerequisite. Necessary legacy schema responsibility must be versioned before certification; only unrelated data-seeding refactoring remains later. Existing raw source DDL is not itself a Phase 0 failure.

### C2-04 — unsupported evidence claims remain

**Evidence:** Truth matrix 15:31–35 references a nonexistent wrapper README; R4 says the static agent secret was removed from code but scripts/tmk-iis-agent.ps1:21 retains a fallback. Inventory/trace/backups/tooling descriptions contain the concrete errors listed in [evidence report](05_EVIDENCE_AND_CONSISTENCY_FINAL_GATE.md).

**Required correction / acceptance:** Correct current canonical citations and append a reconciled evidence note for historical R4 errors. Label specification, static code, planned tests, executed checks and measured results distinctly. Preserve historical reports unchanged.

### C3-01 — verifier improvements do not close full-scope advisory

**Evidence:** Core checks now fail on injected duplicate IDs, historical invalid targets and mirror errors. Missing whole source dossier and invalid MR-34 discovery target pass. Four later/historical dossiers are excluded.

**Required correction / acceptance:** Reject missing required input directories; inspect all mapped target rows; explicitly declare the mirror scope and byte/text-equality policy. Include relevant dossiers or narrow the advertised guarantee. Retain negative tests. Exact four-string scanning must not be advertised as semantic consistency verification.

This remains the earlier advisory; it is not counted again as a new C3.

## New findings

| ID | Severity | Title |
|---|---|---|
| FR-C1-01 | C1 | Latest main includes unaccounted database/security provisioning drift |
| FR-C2-01 | C2 | TLS alternative example does not itself establish server authentication |

### FR-C1-01 — unaccounted database/security provisioning drift

**Evidence:** Infrastructure main `174869490596c1eee07366590dbd8e1c46df5b71` includes commit `10a2e77` and added [create-readonly-analyst.sh](D:/company/products/vps-infra/vps-infra/db/postgres/create-readonly-analyst.sh:8). Against expected implementation baseline `780e8b4f152e039e9ee31ed46c71811e04947f7b`, this is an additional non-document/non-audit-tool change. It creates or alters a database login, sets its password, changes grants/default privileges, and supplies a hardcoded fallback credential. The credential is not reproduced here.

**Impact:** R4's earlier zero-runtime/database-drift conclusion does not cover the current candidate. Running the new script mutates access controls and can install/reset a predictable repository-known credential. Its actual execution or deployment is unverified.

**Required correction:** Account for this commit through an explicit reviewed baseline exception/disposition or present an appropriately scoped candidate. Review and resolve the hardcoded fallback behavior before accepting that implementation as safe; document credential handling and any needed operational follow-up based on actual use.

**Acceptance:** The full frozen-baseline-to-candidate diff is accounted for, independently reviewed, and no unexplained product/database/security delta is labeled governance-only. Any approved database helper must have an explicit safe credential contract. An assertion that the script is “read-only” is insufficient because it provisions a read-only account through database writes.

**Scope qualification:** The available dossiers do not establish authorization; this report does not claim the user never authorized the separate commit. No revert, database mutation or credential action was performed by the auditor.

### FR-C2-01 — Require/Trust Server Certificate=false example is misleading

**Evidence:** Canonical 04/05 permit VerifyFull or Require/Trust Server Certificate=false with validated CA/pinning. Reconciliation Windows §5.1 further presents installing a CA in the OS trust store as sufficient for its Require alternative. The API references Npgsql 10.0.1 and EF provider 10.0.0.

**Technical assessment:** Npgsql's documented Require mode encrypts but does not authenticate the server certificate; VerifyFull provides certificate/hostname validation. Trust Server Certificate=false alone does not turn Require into VerifyFull. See [Npgsql security and encryption](https://www.npgsql.org/doc/security.html).

**Impact:** Copying the alternative connection string and installing a CA can leave encryption without the required peer authentication.

**Required correction / acceptance:** Prefer the already specified VerifyFull example, or explicitly describe and test an independently enforced validating/pinning mechanism for any alternative. Test untrusted CA, wrong hostname and wrong pin as applicable. Do not describe a trust-store installation or flag alone as proof.

**Why C2:** The canonical contract already unambiguously requires authenticated TLS and prohibits validation bypass. This is a correction to an example, not missing architecture or a newly demonstrated runtime vulnerability.

## Closure decision

**PHASE 0 CODEX FINAL RE-GATE: FAIL**

`PHASE 0 REMAINS OPEN — RETURN TO DEVELOPER`

Resolve retained RG-C1-02 and new FR-C1-01 before acceptance. Reconcile the C2 precision/evidence items; C3 remains advisory. R4's later-phase archive/link/DACL refinement and periodic DR drill advice remain valid implementation acceptance work, not additional Phase 0 blockers.
