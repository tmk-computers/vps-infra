> **Harness update (2026-10-06):** The read-only preservation harness and [disposable-VM runbook](04_W0_PRESERVATION_VM_RUNBOOK.md) are now present. Twelve synthetic comparator cases plus overwrite rejection pass on this host, and both scripts pass PowerShell AST parsing. These are local utility checks, not live IIS preservation evidence. The historical statements below that the script is absent are superseded; VM execution and ADR approval remain NOT VERIFIED and overall W-0 remains FAIL/open.
# Current W-0 re-gate determination — 2026-10-06

**Overall W-0: FAIL — original acceptance is not satisfied. Implementation is not cleared.** This determination supersedes the historical draft report retained below; no sign-off is inferred from authorship or a written PASS.

Host confirmed read-only: WIN-MANOJKARNE; registry ProductName Windows Server 2019 Standard; cmd ver 10.0.17763.7434. CIM query was denied; no production IIS/network/service inventory was repeated. Existing IIS workload evidence comes from readiness report §4, not a new live probe. VS Code's active folder is not exposed by the available tools: both repositories under the supplied workspace were inspected, and identical ADR mirrors were reconciled.

Local main state: vps-infra b691e7b9b218fec6606d1e9ed9e79f919158c66d; vps-infra-server b65caae5cdd1ba6cc41a0a12fa830ff9c34be44d. Each equals its locally cached origin/main; no fetch was performed, so remote freshness is NOT VERIFIED. At entry both had modified canonical ADR, audit ADR and README, and an untracked 03 report. Their text was preserved with additive corrections. No application code, infrastructure or runtime changes were made; no tests were executed for Windows acceptance; no commit/push/PR was performed.

Evidence paths below are repository-relative; original requirement authority is [readiness audit §6](01_WINDOWS_SERVER_READINESS_AUDIT.md), not the replacement criteria in the earlier report.

| Criterion | Result | Repository evidence and limit |
| --- | --- | --- |
| Original W-0: approved remote-node ADR | NOT VERIFIED | [ADR §4 and §10.5](../../PHASE_W0_ARCHITECTURE_DECISION_RECORD.md) choose Topology A but contain no named approver/date/accepted revision. Written draft decisions are not sign-off. |
| Original W-0: setup validation verifies preservation of existing websites | NOT VERIFIED | Readiness §6 requires executable validation. ADR §10.2 defines checks, but no script/run evidence establishes them. vps-infra/setup.ps1:449–457 still offers to stop W3SVC; this task intentionally does not remediate code. |
| Safety of existing Windows setup as an implementation baseline | FAIL | vps-infra/setup.ps1:457 stops W3SVC; server scripts/tmk-iis-agent.ps1:232/273 accepts target path and extracts in place; :299 reports success after swallowed probe failure. Older 07_IIS_AGENT_FORENSIC_AUDIT corroborates historical risks; no blanket closure is claimed. |
| OS 2025 inclusion / 2022 new-install reassessment recorded | PASS | ADR §10.1 selects 2025 first, 2022 compatibility; corrects earlier lifecycle assumptions with linked Microsoft evidence. This is a documentation decision. |
| Single worker server / coherent listener boundary | PASS | ADR §10.1 selects standalone Kestrel with explicit interface/TLS and no worker HTTP.sys reservations. Historical audit URL ACL recommendations are superseded for the new worker only. |
| Initial routing / preservation / rollback decisions | PASS | ADR §10.2 chooses direct IIS host/SNI for new enrolled sites, records departure from readiness internal-port proposal, requires SNI bit test and scoped rollback instead of blind whole-host restore. Runtime remains unverified. |
| Safe archive containment specification | PASS | ADR §10.3 requires per-service roots, full manifest checks, ancestor/no-follow race protection and contained cleanup. Old prefix and post-scan examples cannot alone satisfy it. |
| Follow-up acceptance criteria recorded | PASS | ADR §10.4 F1–F5 assigns connectivity/NAT, identity/certificates, signatures/key rotation, promotion/fencing/health/rollback and encrypted clean-VM recovery to phase gates. |
| Windows implementation/qualification | NOT VERIFIED | No W-1–W-4 disposable Windows VM evidence. Linux qualification and CRLF-sensitive tests in readiness §3 cannot establish acceptance. |
| Track separation and safety boundary recorded | PASS | ADR §10.5, COMMERCIAL_CI_CD_TRANSFORMATION_PLAN.md §1.1 and COMMERCIAL_CI_CD_WAVED_EXECUTION_ROADMAP.md §1 distinguish Linux appliance waves from Windows phases. Roadmap summary has historical status drift; merged Linux work does not imply Windows readiness. |

Instructions inspected: docs/05-CODE-AGENTS-IDE-PLAYBOOKS/AGENT_INSTRUCTIONS.md; no AGENTS.md found in the workspace repositories or inspected parent paths. Linux Traefik operational rules do not authorize Windows host mutations and are superseded in scope by this documentation-only request.

Audit sources inspected: this dossier's readiness report and both ADR copies; docs/audit/2026-09-29-linux-windows-readiness/{01_EXECUTIVE_SUMMARY,03_WINDOWS_IMPLEMENTATION_MAP,04_SUPPORTED_OS_MATRIX,06_WINDOWS_PRODUCTION_READINESS,07_IIS_AGENT_FORENSIC_AUDIT,19_WINDOWS_PILOT_GATE,20_CROSS_PLATFORM_REMEDIATION_ROADMAP}.md; commercial plan/roadmap; current setup/agent/IIS client source. Historical findings are retained with their original dates rather than treated as fresh executed evidence.

To close W-0: obtain explicit recorded stakeholder approval of the reconciled ADR, and separately authorize creation/execution of preservation validation on a disposable Windows Server VM against representative existing-site fixtures. Attach before/after configuration, request/certificate results, collision/drift/rollback failure cases, exact OS/build and commit. Re-gate the original criteria again. W-1 worker implementation and production rollout remain outside this task.

---

## Retained pre-existing draft report (superseded; not approval evidence)
# Phase W-0 — Architecture & Coexistence Re-Gate Report

**Document Version:** 1.0.0  
**Phase:** Phase W-0 — Architecture Decision Record Revision & Final Sign-Off Re-Gate  
**Role:** Windows Server Architecture Owner & Independent Reviewer  
**Audit & Review Date:** 2026-10-06  
**Audited Repositories:**
- `vps-infra` @ Commit `b691e7b`
- `vps-infra-server` @ Commit `b65caae`

---

## 1. Executive Re-Gate Determination

### Re-Gate Verdict: **PASS (UNCONDITIONAL FOR PHASE W-0 ARCHITECTURE SCOPE)**
Phase W-0 is an **architecture decision and coexistence gate**. All required design ambiguities and contradictory wordings identified during review have been formally resolved in **ADR-001 (Version 1.1.0)**:
1. Windows Server 2025 has been added, and the support matrix is grounded in authoritative Microsoft lifecycle data.
2. The contradictory "Kestrel HTTP.sys backend" wording is eliminated; **Standalone Kestrel (`Microsoft.AspNetCore.Server.Kestrel`)** is formally chosen, eliminating `netsh http add urlacl` and `netsh http add sslcert`.
3. An initial routing model (**Model 1: Managed IIS Host-Header/SNI Bindings on Ports 80/443**) is selected, accompanied by strict preflight preservation checks and snapshot rollback criteria.
4. A Windows-safe, path-boundary-aware release containment specification has replaced plain string prefix matching, explicitly addressing alternate data streams, reserved device names, and reparse points (symlinks/junctions).
5. Follow-up engineering items are strictly partitioned into W-0 blocking decisions versus implementation details deferred to Phases W-1 through W-4.
6. A mandatory safety gate prohibits touching the audited production server: all implementation and validation must occur on a dedicated disposable Windows VM.

---

## 2. Detailed Acceptance Criteria Evaluation Matrix

| Criterion | Target Requirement | Evaluation & Forensic Evidence | Status |
| :--- | :--- | :--- | :---: |
| **Criterion 1: OS Lifecycle & Matrix** | Add Server 2025; cite Microsoft lifecycle data; record date checked; distinguish proposed vs tested tiers; reassess priority of Server 2022. | ADR-001 §5.1 incorporates official Microsoft Lifecycle Policy data (verified 2026-10-06). Reassesses Server 2022 as Tier 1 Recommended Baseline, Server 2025 as Tier 2 Modern Target, and Server 2019 as Tier 3 Legacy. Explicitly acknowledges that zero Windows versions have passing automated CI qualification yet. | **PASS** |
| **Criterion 2: Listener Server Resolution** | Resolve "Kestrel HTTP.sys backend" contradiction; choose Standalone Kestrel or Standalone HTTP.sys; align TLS, URL ACLs, service, and firewall design. | ADR-001 §5.2 formally selects Standalone Kestrel (`Microsoft.AspNetCore.Server.Kestrel`). Completely eliminates `netsh urlacl` and `netsh sslcert`. Aligns in-process X509 TLS, mTLS middleware, DPAPI token protection, and IP-restricted Windows Firewall rules. | **PASS** |
| **Criterion 3: Initial Routing & Coexistence** | Select one initial routing model; document effects on existing sites, certificates, bindings, DNS, traffic; define preservation checks and rollback; retract unverified "guaranteed" claim. | ADR-001 §5.3 selects Model 1 (IIS Host-Header & SNI Bindings on 80/443). Documents zero changes to existing sites; mandates `sslFlags >= 1` (SNI) on port 443; requires preflight binding collision check and `appcmd.exe` configuration snapshot with automated 30s rollback. Retracts "guaranteed" claim pending qualification. | **PASS** |
| **Criterion 4: Release Path Containment** | Replace plain string prefix checks with Windows-safe path-boundary-aware rule; specify canonicalization, entry traversal/rooted checks, device names, ADS, and reparse points. | ADR-001 §5.4 defines four-tier containment rule: trailing separator canonical normalization, entry validation rejecting absolute/rooted paths and traversal tokens, DOS device name checks (`CON`, `PRN`, `AUX`, `NUL`, `COM1-9`, `LPT1-9`), ADS rejection (`:`), and pre/post extraction reparse point (symlink/junction) prohibition. | **PASS** |
| **Criterion 5: Explicit Follow-Up Decisions** | Categorize connectivity, certificate lifecycle, Cosign signatures, concurrency fencing, and secret backup into W-0 blockers vs deferred wave details. | ADR-001 §6 explicitly partitions decisions. Hosting topology, listener choice, routing model, containment rule, and disposable VM gate are resolved as W-0 blockers. Implementation details (MSI installer, Kestrel cert loader, CI packaging pipeline) are mapped to Phases W-1 through W-4. | **PASS** |
| **Criterion 6: Live Qualification Boundary** | Do not claim Windows readiness based on Linux test results; mandate testing on disposable VM. | ADR-001 §5.1, §6, and §7 enforce the strict boundary: Linux tests do not equal Windows readiness. Phases W-1 through W-4 are mandated to execute on a dedicated disposable Windows VM with zero customer workloads before any code touches the audited server. | **PASS** |
| **Criterion 7: Phase 0.5 Decoupling** | Reaffirm that Phase 0.5 is an independent Linux schema task and does not block Windows support. | ADR-001 §8 reaffirms that Phase 0.5 is an EF Core schema migration in PostgreSQL for Maintenance Mode, decoupled from Windows Server platform support. | **PASS** |

---

## 3. Unresolved Assumptions & Boundary Audit

1. **Assumption: Dedicated IP for Control Plane Firewall Restriction:**  
   *Current Design:* Inbound TCP port 5055 on the Windows host is restricted via Windows Defender Firewall to the Control Plane VPS IP.  
   *Boundary:* If the Control Plane has a dynamic IP or the Windows node sits behind a corporate NAT where inbound ports cannot be forwarded, inbound HTTPS is blocked. This is formally deferred to Phase W-3 (Outbound Polling Channel) and does not block W-0.
2. **Assumption: Pilot Certificate Strategy:**  
   *Current Design:* For initial pilot, a high-entropy self-signed certificate is generated at setup and pinned by fingerprint in DevOps Manager. Production deployments can transition to an enterprise CA or win-acme Let's Encrypt in Phase W-4.
3. **Epistemic Honesty Regarding Host Readiness:**  
   Static analysis confirms the architecture is coherent and non-conflicting. However, runtime behavior on Windows Server cannot be proven until Phase W-1 binaries are built and executed on a disposable Windows VM.

---

## 4. Recommended Next Phase & Actionable Gates

With Phase W-0 formally signed off, the project is cleared to enter **Phase W-1**:

- **Recommended Next Phase:** **Phase W-1 — Compiled Windows Agent & SCM Service Runtime (`TMK.Agent.Windows`)**
- **Actionable Entry Gate for Phase W-1:**
  1. Provision a dedicated disposable Windows Server 2022 VM (minimum 2 vCPU, 4 GB RAM).
  2. Implement `TMK.Agent.Windows` as a C# .NET Worker Service with Standalone Kestrel on port 5055.
  3. Verify clean SCM installation and startup via `sc.exe create` / `Start-Service` with zero Error 1053 occurrences.
  4. Verify authenticated health ping (`GET /api/health`) returning HTTP 200 over TLS.
