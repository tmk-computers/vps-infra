# HISTORICAL OBLIGATION RECONCILIATION (C1-04 RESOLUTION)

**Document ID**: `REMED-P0-CDX-06`  
**Phase**: Phase 0 — Codex Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C1-04`)  
**Status**: COMPLETE SUB-OBLIGATION TRACEABILITY SPECIFICATION  

---

## 1. Context & Problem Statement

The Codex Phase 0 Audit Gate flagged finding `C1-04` as a **Significant Defect (C1)**. While the baseline achieved 100% ID coverage (all 37 Master Remediation items accounted for), the audit revealed that high-level ID mapping had obscured or collapsed critical underlying historical obligations:
1. **F16 Collapsed Sub-Obligations**: Historical finding F16 contained five distinct safety and privacy obligations spanning API key encryption, streaming spend caps, local-only data privacy enforcement, cloud-fallback policy rechecks, and resource governor admission control. The baseline had collapsed F16 into MR-07 with only API key encryption and streaming spend mentioned, omitting privacy precedence, fallback safeguards, and admission controls.
2. **Conflation of F01 and DEF-08**: The baseline labeled DEF-08 as a "Duplicate of Codex F01". However, F01 addresses untrusted CI test runner Docker socket mounting, whereas DEF-08 addresses privileged control plane (`devops-manager`) host root and Docker socket mounting. Merging them allowed the control-plane host mounting risk to remain unmitigated simply by introducing External CI.
3. **DEF-15 Path Traversal Containment**: Path traversal containment was mapped to MR-04 (Secret Disclosure), but omitted from the detailed Phase 1 work scope description.
4. **F22 Telemetry Reconciliation**: F22 telemetry obligations were assigned to Windows-specific MR-25, leaving shared cross-platform telemetry obligations ambiguous.

This document establishes the granular sub-obligation reconciliation matrix, guaranteeing that every substantive historical obligation is tracked, assigned to an MR owner, and governed by explicit acceptance criteria.

---

## 2. Granular F16 Sub-Obligation Traceability

Historical finding `F16` (AI Model Gateway Security, Privacy, and Spend Controls) is broken down into five distinct, non-collapsible sub-obligations:

| Sub-Obligation ID | Obligation Description | Current Code Evidence | Current Status / Gate A Scope | Assigned MR & Phase | Explicit Re-Enablement & Acceptance Criteria |
|---|---|---|---|---|---|
| **F16.1** | **API Key Encryption at Rest**: Provider API keys (OpenAI, Anthropic, Ollama) must be encrypted at rest using AES-256-GCM. | Keys stored in plaintext configuration or plain DB fields. | **Active Remediation Target** | **MR-07** (Phase 1) | **Criteria**: Attempting to store or read an unencrypted API key fails; keys in DB are encrypted with envelope key; keys are masked in API responses (`sk-ant-***`). |
| **F16.2** | **Monotonic Streaming Spend Cap**: Real-time token usage during streaming responses must accumulate monotonically and terminate immediately upon exceeding budget. | Partial streaming accumulator; lacks hard kill switch. | **Active Remediation Target** | **MR-07** (Phase 1) | **Criteria**: Test streams 5,000 tokens against a 1,000-token cap. Stream terminates with HTTP 429 at token 1,001; no further tokens billed. |
| **F16.3** | **`LocalOnly` Privacy Precedence**: If a request or tenant policy is set to `LocalOnly`, the gateway must strictly prevent customer prompt data from being routed to any cloud AI provider. | `ModelGatewayService.cs:202` overrides request policy with config policy. | **Feature Disabled for Gate A** | **MR-07** (Phase 1 disable) / **MR-31** (Phase 9 re-enable) | **Gate-A State**: AI Model Gateway is disabled by default in Gate A.<br>**Re-Enablement Gate**: Before re-enabling in Phase 9, code audit must verify `LocalOnly` cannot be bypassed by config overrides or fallback logic. Negative test: Submit prompt with `LocalOnly=true`; verify zero outbound packets to external cloud endpoints. |
| **F16.4** | **Cloud Fallback Policy & Spend Rechecks**: When a local model fails or times out and fallback to a cloud model is attempted, the gateway must re-verify tenant permissions and re-check available budget before routing. | `ModelGatewayService.cs:101` falls back to cloud model without re-evaluating budget. | **Feature Disabled for Gate A** | **MR-07** (Phase 1 disable) / **MR-31** (Phase 9 re-enable) | **Gate-A State**: Cloud fallback is disabled for Gate A.<br>**Re-Enablement Gate**: Fallback engine must execute a fresh tenant authorization and budget reservation before dispatching fallback requests. |
| **F16.5** | **Resource Governor Admission Control**: Heavy local inference requests (e.g. Ollama LLM execution) must be regulated by an admission controller to prevent CPU/GPU starvation of core platform services. | No admission control or process cgroups; unconstrained inference causes host thrashing. | **Phase 6 Infrastructure Scope** | **MR-17** (Phase 6 Governor) | **Criteria**: Background inference processes are restricted to pinned CPU cores and memory limits ($< 60\%$ host RAM); admission queue rejects requests when host load $> 80\%$. |

---

## 3. Separation of F01 (CI Runner) vs DEF-08 (Control Plane Host Access)

Codex finding C1-04 required:
> "Preserve the distinction between CI Worker / Build Execution Trust Boundary and Management API / Control Plane Trust Boundary. Do not merge them merely because both relate to Docker or host access."

The table below establishes the formal architectural separation between F01 and DEF-08:

```
+----------------------------------------------------------------------------------------------------+
|                                    PLATFORM ARCHITECTURAL SEPARATION                               |
+-----------------------------------------------------------------+----------------------------------+
| F01: CI RUNNER EXECUTION BOUNDARY                               | DEF-08: CONTROL PLANE BOUNDARY   |
| (Untrusted User Build Code)                                     | (Trusted Core Management API)    |
|                                                                 |                                  |
| Threat Actor: Malicious Tenant Developer pushing arbitrary code | Threat Actor: Compromised API    |
| Risk: Container breakout via Docker daemon to host root         | Risk: Over-privileged host mount |
| Resolution: External Isolated CI Runner (Ephemeral VM)          | Resolution: Least Privilege API  |
+-----------------------------------------------------------------+----------------------------------+
```

### 3.1 Detailed Comparative Trust Boundary Matrix

| Dimension | **F01 (External CI Worker Trust Boundary)** | **DEF-08 (DevOps Manager Control Plane Boundary)** |
|---|---|---|
| **Underlying Problem** | `ci-server` executed user-supplied, untrusted build scripts and test runners with access to the host's `/var/run/docker.sock`. | `devops-manager` API container in `docker-compose.yml:72` mounts `/var/run/docker.sock` and host root directories (`/:/host`) with root privileges. |
| **Threat Actor** | Malicious or compromised tenant developer executing arbitrary code via CI build pipelines. | External attacker exploiting an application vulnerability (e.g. RCE) in the `devops-manager` API. |
| **Asset at Risk** | The entire VPS host, all tenant containers, and host credentials. | Host filesystem, host operating system configuration, other host services. |
| **Remediation Phase** | **Phase 3** (External CI Integration) | **Phase 1** (MR-01 / MR-08 Container Hardening) |
| **Technical Resolution** | **Architectural Removal**: The CI build engine is completely removed from the production VPS host. CI builds run on an isolated, external runner with disposable, ephemeral VMs. Zero Docker socket access on the production host. | **Defense-in-Depth Container Hardening**: <br>1. Run API as unprivileged user `appuser` (UID 10001).<br>2. Remove root filesystem mount (`/:/host`).<br>3. Drop all Linux capabilities (`cap_drop: ALL`).<br>4. Implement a tightly scoped Unix domain socket proxy that restricts Docker API access to only container lifecycle endpoints (`/containers/create`, `/containers/start`, etc.), explicitly forbidding host exec and volume mounts outside `/app_data`. |
| **Independent Acceptance Criteria** | Push a malicious CI build with `docker run -v /:/host alpine rm -rf /host`. The build executes in isolated runner VM without affecting the production host; production host has zero Docker socket exposure to CI. | Penetration test against `devops-manager` API container: verify user is UID 10001, root filesystem is read-only (`read_only: true`), and attempts to call restricted Docker daemon endpoints (e.g. `/swarm`, `/nodes`, `/volumes/create`) return HTTP 403 Forbidden from socket proxy. |

---

## 4. Reconciliation of DEF-15 (Path Traversal Containment)

- **Finding Context**: DEF-15 originally identified that `ci-server` and `devops-manager` accepted file path parameters without sanitization, allowing arbitrary filesystem reads/writes outside the project directory.
- **Traceability Assignment**: Formally assigned to **MR-04** (Secret Disclosure & Path Containment) in **Phase 1**.
- **Implementation Requirement**:
  1. Every path parameter (`ProjectDirectory`, `ArtifactPath`, `LogFilePath`) must be passed through a strict path canonicalizer:
     ```csharp
     string fullPath = Path.GetFullPath(Path.Combine(tenantSandboxRoot, userPath));
     if (!fullPath.StartsWith(tenantSandboxRoot, StringComparison.OrdinalIgnoreCase))
     {
         throw new SecurityException("Access denied: Path traversal detected.");
     }
     ```
  2. Any path containing `..`, null bytes (`%00`), or resolving outside `tenantSandboxRoot` must be rejected immediately with HTTP 400 Bad Request.

---

## 5. Reconciliation of F22 (Telemetry & Metrics Reconciliation)

- **Finding Context**: Historical finding F22 addressed unconstrained, unbuffered telemetry collection causing I/O saturation.
- **Scope Division**:
  - **Shared Platform Core (MR-17 / MR-25)**: Core metric collection pipeline implements in-memory circular ring buffers with bounded flush intervals (10 seconds) and drop-on-saturation policies.
  - **Windows Telemetry (MR-25)**: `TMK.Agent.Windows` queries Windows Performance Counters and IIS W3C log buffers using a non-blocking asynchronous worker task, preventing UI and HTTP thread stalling.

---

## 6. Master Sub-Obligation Traceability Index

| Source ID | Child Obligation ID | Substantive Obligation Description | Current Target MR | Target Phase | Status |
|---|---|---|---|---|---|
| **F01** | F01.1 | Untrusted CI code execution isolated from host daemon | MR-01 | Phase 3 | Preserved (External CI) |
| **DEF-08** | DEF-08.1 | Control-plane Docker socket proxying & capability dropping | MR-01 / MR-08 | Phase 1 | Preserved (Distinct from F01) |
| **DEF-08** | DEF-08.2 | Removal of privileged host root directory mounts | MR-08 | Phase 1 | Preserved |
| **DEF-11** | DEF-11.1 | Tenant admin scoped strictly to TenantId without platform bypass | MR-08 / MR-36 | Phase 1 | Preserved (No tenant SuperAdmin) |
| **DEF-15** | DEF-15.1 | Path traversal containment via canonicalization | MR-04 | Phase 1 | Preserved in MR-04 scope |
| **F16** | F16.1 | Provider API key encryption at rest (AES-256-GCM) | MR-07 | Phase 1 | Preserved |
| **F16** | F16.2 | Monotonic streaming spend budget hard cap | MR-07 | Phase 1 | Preserved |
| **F16** | F16.3 | `LocalOnly` privacy policy precedence enforcement | MR-07 / MR-31 | Phase 1 (Disable) / Phase 9 (Re-enable) | Preserved behind feature gate |
| **F16** | F16.4 | Cloud fallback authorization and budget re-evaluation | MR-07 / MR-31 | Phase 1 (Disable) / Phase 9 (Re-enable) | Preserved behind feature gate |
| **F16** | F16.5 | Admission control and resource governor for local LLM | MR-17 | Phase 6 | Preserved |
| **F22** | F22.1 | Bounded in-memory telemetry buffers with backpressure | MR-25 | Phase 4 (Win) / Phase 7 (Core) | Preserved |

---

## 7. Conclusion

By decomposing collapsed findings into explicit sub-obligations, separating CI runner isolation (F01) from control-plane hardening (DEF-08), and placing AI privacy safeguards behind strict feature gates, this document completely resolves finding `C1-04`.
