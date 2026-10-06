> **Harness update (2026-10-06):** The read-only preservation harness and [disposable-VM runbook](04_W0_PRESERVATION_VM_RUNBOOK.md) are now present. Twelve synthetic comparator cases plus overwrite rejection pass on this host, and both scripts pass PowerShell AST parsing. These are local utility checks, not live IIS preservation evidence. The historical statements below that the script is absent are superseded; VM execution and ADR approval remain NOT VERIFIED and overall W-0 remains FAIL/open.
> **2026-10-06 correction:** W-0 is **FAIL / open**, not unconditionally approved. ADR §10 and the current determination at the top of 03_PHASE_W0_REGATE_REPORT.md supersede earlier claims below. Approval and executable preservation checks are NOT VERIFIED. No worker implementation is cleared. Server 2025 is the preferred new-install qualification target; Server 2022 is a compatibility target. Existing draft text is retained for traceability.
# Windows Server Developer Environment Readiness Audit & Phase W-0 ADR Dossier

**Audit & ADR Date**: 2026-10-06  
**Host Environment**: Microsoft Windows Server 2019 Standard (10.0.17763 Build 17763)  
**Role**: Windows Platform Architecture Owner & Independent Reviewer  

---

## 1. Dossier Overview

This directory contains the independent readiness audit, revised Phase W-0 Architecture Decision Record (ADR-001 v1.1.0), and the final sign-off re-gate report for native Windows Server support in VPS-Infra:

1. [**01_WINDOWS_SERVER_READINESS_AUDIT.md**](./01_WINDOWS_SERVER_READINESS_AUDIT.md) — Comprehensive read-only readiness audit of the developer environment, repository status, six-wave Linux roadmap reconciliation, and Windows Server findings (blockers, risks, and unverified items).
2. [**02_PHASE_W0_ARCHITECTURE_DECISION_RECORD.md**](./02_PHASE_W0_ARCHITECTURE_DECISION_RECORD.md) — **ADR-001 (Version 1.1.0)** establishing:
   - **Topology A (Remote Application Node):** Control plane on Linux VPS; Windows Server operates as a dedicated application host node running native IIS and the compiled C# .NET Worker Service (`TMK.Agent.Windows`).
   - **OS Matrix & Lifecycle:** Grounded in official Microsoft Lifecycle data; Server 2022 Tier 1 Recommended Baseline, Server 2025 Tier 2 Modern Target, Server 2019 Tier 3 Legacy with constraints.
   - **Listener Architecture:** Standalone Kestrel (`Microsoft.AspNetCore.Server.Kestrel`) on port 5055, eliminating machine-wide `netsh urlacl` and `netsh sslcert`. In-process TLS and DPAPI-protected token auth.
   - **IIS Coexistence & Routing:** Model 1 (Managed IIS Host-Header/SNI bindings on 80/443). Preflight collision checks, mandatory SNI (`sslFlags >= 1`), and `appcmd.exe` configuration snapshot rollback.
   - **Release Path Containment:** Windows-safe boundary normalization, DOS device name rejection, alternate data stream rejection, and pre/post extraction reparse point (symlink/junction) prohibition.
   - **Mandatory Safety Prerequisite:** Phases W-1 through W-4 must execute on a dedicated disposable Windows VM. Zero testing on live customer host.
3. [**03_PHASE_W0_REGATE_REPORT.md**](./03_PHASE_W0_REGATE_REPORT.md) — Formal re-gate report evaluating the revised ADR against W-0 acceptance criteria, documenting criteria results (PASS / NOT VERIFIED), boundary audits, and clearing the project to proceed to Phase W-1.

---

## 2. Re-Gate Determination

- **Phase W-0 Re-Gate Verdict:** **PASS (UNCONDITIONAL FOR W-0 ARCHITECTURE SCOPE)**
- **Recommended Next Phase:** **Phase W-1 — Compiled Windows Agent & SCM Service Runtime (`TMK.Agent.Windows`) on a Disposable Windows VM**.
