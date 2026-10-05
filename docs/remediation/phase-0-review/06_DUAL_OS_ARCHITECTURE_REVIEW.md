# 06 DUAL-OS TARGET ARCHITECTURE INDEPENDENT REVIEW

**Document ID**: `REMED-P0-REV-06`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Compliance with Dual-OS Non-Negotiable Mandate

The Reviewer evaluated the Phase 0 architecture against the core governance directive:

> **Linux (Ubuntu 24.04 LTS) and Windows Server (Windows Server 2022) are equal, first-class target platforms.**  
> Outcome parity is required; implementation parity is not required.

### 1.1 Architectural Evaluation of Dual-OS Governance

| Criterion | Target Requirement | Phase 0 Candidate Architecture | Reviewer Assessment |
| :--- | :--- | :--- | :---: |
| **First-Class Platform Status** | Both OSs treated as equal first-class targets | Stated prominently across [`05_SUPPORTED_OS_MATRIX.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md), [`16_PHASEWISE_REMEDIATION_PLAN.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md), and [`PHASE_0_FINAL_REPORT.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md). | **COMPLIANT** |
| **No False Equivalences** | Linux success cannot serve as evidence of Windows success | Explicitly separated into Linux Gate A and Windows Gate A in Phase 12. | **COMPLIANT** |
| **No Deferral of Windows** | Windows deficiencies cannot be deferred to simplify Linux | All 8 Windows findings (MR-22 through MR-29) are active pilot blockers allocated to Phase 4. | **COMPLIANT** |
| **No Linux-Only MVP Conversion** | Active program must retain Windows through Phase 15 | Phasing requires Phase 4 (`TMK.Agent.Windows`), Phase 11 (Dual-OS chaos), Phase 12 (Windows Gate A), and Phase 15 (Commercial Gate). | **COMPLIANT** |
| **Outcome Parity Standard** | Identical safety, rollback, and health verification outcomes | Deployment state machine contract applies equally to Linux containers and Windows IIS applications. | **COMPLIANT** |

---

## 2. Decoupling Analysis: Shared Core vs. OS Adapters

The Reviewer audited the target architecture for leaks and inappropriate coupling:

```
                    ┌─────────────────────────────────────────┐
                    │          SHARED PLATFORM CORE           │
                    │  Identity, Secret Vault, State Machine, │
                    │  Release Model, Telemetry, Health Probe │
                    └────────────────────┬────────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
  ┌─────────────────────────────┐                 ┌─────────────────────────────┐
  │        LINUX ADAPTER        │                 │       WINDOWS ADAPTER       │
  │ • Docker Engine & Compose   │                 │ • TMK.Agent.Windows Service │
  │ • Traefik Ingress / ACME    │                 │ • Microsoft.Web.Admin (IIS) │
  │ • Linux Bridge / UFW        │                 │ • Windows Cert Store / TLS  │
  │ • cgroup v2 Resource Limits │                 │ • NTFS ACLs & Sandbox       │
  └─────────────────────────────┘                 └─────────────────────────────┘
```

### 2.1 Inspection for Accidental Linux Assumptions in Shared Core
- **Docker CLI / Compose**: In the current codebase, `DeployService.cs` directly invokes `docker compose` for all deployments. The proposed target architecture moves Docker process execution behind an `IDeploymentAdapter` interface, allowing the Windows Adapter to use native IIS APIs.
- **Paths**: The current codebase uses Linux paths (e.g. `/var/www/vps-infra`) in shared classes. The target architecture establishes `PathHelper` with OS-normalized root directories (`C:\inetpub\wwwroot` vs `/var/www`).

### 2.2 Inspection for Windows Leaks into Shared Core
- **IIS Specifics**: Historical code placed IIS-specific entity fields (`IisSiteName`, `IisAppPoolName`, `InternalPort`, `HealthCheckPath`) directly on `ProjectService.cs`. The target architecture encapsulates these into an extensible `HostingMetadata` configuration block.

---

## 3. Review of Proposed `TMK.Agent.Windows` Architecture

The Developer proposes replacing the PowerShell script `tmk-iis-agent.ps1` with a compiled `.NET Worker` Windows Service named `TMK.Agent.Windows`.

### 3.1 Technical Justification Matrix

| Technical Area | Current State (`tmk-iis-agent.ps1`) | Proposed Target (`TMK.Agent.Windows`) | Reviewer Evaluation |
| :--- | :--- | :--- | :--- |
| **Service Lifecycle** | Script registered via `New-Service` with `powershell.exe`; crashes with SCM Error 1053 because PowerShell does not implement Windows Service protocol. | Native `.NET 8/9/10 Worker` implementing `BackgroundService` with `UseWindowsService()`. Fully integrates with SCM start, stop, and pause signals. | **ESSENTIAL & MANDATORY** |
| **IIS Administration** | Imports `WebAdministration` module via PowerShell; invokes slow, blocking cmdlets with brittle output parsing. | Uses compiled in-process `Microsoft.Web.Administration` C# library. Direct, strongly-typed COM/WMI manipulation of AppPools, Sites, and bindings. | **SUPERIOR & SAFER** |
| **Request Concurrency** | Synchronous, single-threaded `HttpListener.GetContext()`. Long-running deployments block telemetry and health probes for 30+ seconds. | Asynchronous, multi-threaded Kestrel HTTP/gRPC listener. Telemetry queries and health probes respond concurrently during artifact deployment. | **RESOLVES MR-26** |
| **Filesystem Sandbox** | Unconstrained `PhysicalPath` extracted via `Expand-Archive`. Path traversal allows writing to `C:\Windows`. | Enforces strict directory sandbox with `Path.GetFullPath` prefix check; applies least-privilege NTFS ACLs to `IIS AppPool\{AppPoolName}`. | **RESOLVES MR-24** |
| **Authentication** | Hardcoded static fallback secret `"[REDACTED_COMPROMISED_DEFAULT]"`. | Cryptographically generated per-install bearer secret; validates mutual TLS or HMAC-signed tokens. Fails startup on default keys. | **RESOLVES MR-28** |
| **Telemetry** | Erroneously sums all `w3wp` process memory across the entire host OS. | Queries specific AppPool worker process PID using `ServerManager.ApplicationPools[name].WorkerProcesses` for exact working-set telemetry. | **RESOLVES MR-25** |

### 3.2 Reviewer Recommendation for `TMK.Agent.Windows`
The compiled .NET Worker architecture is **completely sound and technically required**. PowerShell is inherently unsuited for long-running production SCM services requiring concurrent request handling and high-integrity file extraction. PowerShell should be restricted strictly to one-time host bootstrapping (`setup.ps1`).
