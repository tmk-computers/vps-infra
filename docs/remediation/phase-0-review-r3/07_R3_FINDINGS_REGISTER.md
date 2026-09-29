# 07 REVIEW FINDINGS REGISTER (CYCLE R3)

**Document ID**: `REMED-P0-REV-R3-07`  
**Phase**: Phase 0 — Independent Re-Review after Codex Remediation (Cycle R3)  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Audit Date**: 2026-09-29  
**Status**: COMPLETE — ALL FINDINGS FORMALLY CLASSIFIED  

---

## 1. Severity Classification Rules

In accordance with Phase 0 Independent Review governance:
- **`R0` (Acceptance Blocker)**: Critical architectural contradiction, unsafe deployment contract, unrecoverable data loss vector, or unverified baseline drift that fundamentally invalidates the Phase 0 baseline freeze. Prevents Phase 0 sign-off.
- **`R1` (Significant Correction Required)**: Material defect, omitted historical obligation, or security boundary flaw requiring formal correction prior to submitting for Codex re-gate.
- **`R2` (Precision / Clarity Correction)**: Minor documentary inconsistency, semantic mapping misalignment, or citation precision repair that should be incorporated into the living baseline without failing the overall architecture review.
- **`R3` (Advisory / Architectural Recommendation)**: Non-blocking engineering guidance, optimization recommendation, or implementation-stage parameterization suggestion.

---

## 2. Findings Summary Counts

| Severity Level | Finding Count |
|---|:---:|
| **R0 (Acceptance Blocker)** | **0** |
| **R1 (Significant Correction)** | **0** |
| **R2 (Precision / Clarity)** | **4** |
| **R3 (Advisory / Improvement)** | **1** |
| **TOTAL REVIEW R3 FINDINGS** | **5** |

---

## 3. Detailed Register of Newly Raised Reviewer Findings

### R2-01: Semantic Misalignment of Sub-Obligation F16.5 Mapping
- **Severity**: **R2** (Precision / Clarity Correction)
- **Target Artifact**: `docs/remediation/phase-0-codex-remediation/06_HISTORICAL_OBLIGATION_RECONCILIATION.md:34,110`
- **Defect Description**: Sub-obligation `F16.5` (*Resource Governor Admission Control: Heavy local inference requests must be regulated by an admission controller to prevent starvation*) is mapped to Master Remediation item **`MR-17`** (*Safe Cleanup & Retention*).
- **Reviewer Analysis**: While both items reside within Phase 6 (*Resource Safety & Admission*), mapping a CPU/memory admission governor to a disk cleanup/retention MR is semantically misaligned. `MR-16` is explicitly titled *Resource Admission & Limits (cgroup Capping)*. F16.5 naturally belongs to `MR-16`.
- **Recommended Correction**: In future Phase 6 planning documents, align F16.5 under MR-16 or treat it as a distinct admission governor component within Phase 6.

### R2-02: Windows Agent Service Account Permissions Under-Specification
- **Severity**: **R2** (Precision / Clarity Correction)
- **Target Artifact**: `docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:106` and `docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md:66`
- **Defect Description**: The Windows Agent (`TMK.Agent.Windows`) is specified to run under `NT AUTHORITY\LocalService`.
- **Reviewer Analysis**: In default Windows Server 2022 installations, `NT AUTHORITY\LocalService` does not have access to the IIS administration API (`Microsoft.Web.Administration` / COM). It cannot create new Application Pools, modify website bindings, or write to `applicationHost.config`. Attempting to manage IIS under default LocalService credentials will result in `UnauthorizedAccessException`.
- **Recommended Correction**: Clarify in Phase 4 architecture specifications that `TMK.Agent.Windows` runs under a dedicated Windows Service Account (e.g. `NT SERVICE\TmkAgentWindows`) explicitly granted IIS administration privileges (via membership in `IIS_IUSRS` and delegated configuration locking), with filesystem write permissions strictly sandboxed to `C:\inetpub\staging\` and `C:\inetpub\wwwroot\apps\`.

### R2-03: Tooling Disclosure & Code Invariant Reporting Precision
- **Severity**: **R2** (Precision / Clarity Correction)
- **Target Artifact**: `docs/remediation/phase-0-codex-remediation/PHASE_0_CODEX_REMEDIATION_FINAL_REPORT.md:104`
- **Defect Description**: The Developer final report asserts: *"Zero .cs, .js, .ps1, .sh, .yml, .json, .sql, or .csproj files were altered."*
- **Reviewer Analysis**: While git diff confirms that zero existing product or runtime `.ps1` files were modified, two new untracked PowerShell tooling scripts were authored in the workspace root: `scripts/verify-baseline-integrity.ps1` and `scripts/mirror-to-infra.ps1`.
- **Recommended Correction**: For audit truthfulness, reports must explicitly characterize these additions as **Authorized Phase 0 Documentation/Audit Verification Tooling**, rather than asserting that zero `.ps1` files were altered or added.

### R2-04: Privileged Break-Glass Customer Data Access Governance
- **Severity**: **R2** (Precision / Clarity Correction)
- **Target Artifact**: `docs/remediation/phase-0-codex-remediation/03_SECURITY_CONTRACT_CORRECTION.md:32,61` and `docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:91`
- **Defect Description**: The baseline states unconditionally: *"PlatformSuperAdmin: Zero access to customer data / tenant secrets."*
- **Reviewer Analysis**: In enterprise multi-tenant operations, absolute zero customer data access is operationally unachievable during emergency support, database restoration drills, and critical security incident triage. Making an absolute promise without operational qualification risks driving support engineers to unlogged out-of-band backdoors.
- **Recommended Correction**: Incorporate explicit governance for **Privileged Break-Glass Customer Access** in Phase 1 / Phase 8 security runbooks: requiring explicit customer ticket authorization, short-lived dual-custody elevation, and streaming of all actions to an immutable audit log (`SEC_BREAK_GLASS_AUDIT`).

### R3-01: Application-Specific Health & Readiness Contract Parameterization
- **Severity**: **R3** (Advisory / Architectural Recommendation)
- **Target Artifact**: `docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md:121-125` and `docs/remediation/phase-0-codex-remediation/02_RELEASE_CONTRACT_CORRECTION.md:123`
- **Defect Description**: The release verification contract hardcodes universal constants: external HTTP 200, 30-second observation window, and 5xx error rate $< 1\%$.
- **Reviewer Analysis**: Rigid universal constants do not fit all enterprise workloads: legitimate web apps issue HTTP 301/302 redirects, secured APIs return HTTP 401 to anonymous probes, non-HTTP workers do not expose HTTP, and 5xx percentages in low-traffic environments lack statistical sample significance.
- **Recommended Guidance**: In Phase 2 engineering, parameterize the health contract per service in its release manifest: allowing configured probe protocols (HTTP, TCP, gRPC, heartbeat), acceptable status codes (including redirects), authentication headers, and tunable stabilization durations.

---

## 4. Evaluation of Acceptance-Blocking Defects

- Are there any remaining **R0** Acceptance Blockers? **NO**.
- Are there any remaining **R1** Significant Baseline Defects? **NO**.
- All 10 Codex findings (`C0-01` through `C3-01`) have been verified as resolved in the frozen baseline contracts.
- The 4 R2 findings and 1 R3 finding represent refinement recommendations for future phases, not barriers to Phase 0 acceptance.

---

## 5. Reviewer Status

The baseline architecture satisfies all acceptance requirements.

# VERDICT: PASS
