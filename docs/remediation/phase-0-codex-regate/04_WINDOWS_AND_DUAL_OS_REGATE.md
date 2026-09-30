# Windows architecture and Dual-OS re-gate

Audit date: 2026-09-30. **Windows Architecture FAIL; Dual-OS governance PASS.**

## Selected topology: substantially resolved

| Component | Gate-A target | Re-gate |
|---|---|---|
| Control plane | Shared management stack on Linux host/VM | Location now explicit. |
| Windows workload host | Windows Server 2022, native IIS 10, HTTP.sys, ANCM | Supported-profile decision explicit. |
| Deployment agent | Compiled .NET Worker TMK.Agent.Windows, SCM lifecycle | Phase 4 work; not claimed implemented. |
| Database | Remote PostgreSQL 16 on Linux VM/managed endpoint, TLS 5432 | Location resolved; peer-trust rule still needs correction. |
| Ingress/TLS | IIS/HTTP.sys 80/443, SNI and Windows certificate store | Traefik excluded on Windows host in architecture/OS matrix. |
| Agent connection | Private 5055 HTTPS/mTLS plus scoped request token | Distinct transport and authorization concepts preserved. |
| Excluded dependencies | Docker Desktop and WSL2 PostgreSQL on Windows Server; host Traefik | Explicit exclusions, not silently required components. |

The original topology ambiguity is not being re-raised as though nothing changed. The remaining C1-03 failure concerns conflicting operative instructions and incomplete independent lifecycle/security acceptance.

## Remaining C1-03 closure requirements

1. **Propagate ingress decision.** [16_PHASEWISE_REMEDIATION_PLAN.md:113](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md:113) still instructs Traefik/IIS coexistence. DEF-35 trace acceptance also asks for both, despite the selected no-host-Traefik profile. Record the original coexistence remedy as superseded by native ingress and update MR-27/Phase 4 acceptance accordingly.
2. **Authenticate the remote database endpoint.** [05_WINDOWS_TOPOLOGY_CORRECTION.md:84](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:84) permits `SSL Mode=Require;Trust Server Certificate=true` or a validated CA. Encryption without endpoint authentication is not an equivalent secure alternative. Require peer/hostname validation or an explicitly trusted pinning scheme. Npgsql's SSL matrix distinguishes Require from VerifyFull on man-in-the-middle protection. [Npgsql security documentation](https://www.npgsql.org/doc/security.html).
3. **Adopt independent update/recovery acceptance.** The Developer supplement checks SCM SERVICE_RUNNING/crash and backup binary restoration. The R3 Windows report adds functional health and deterministic reboot recovery, but these have not been adopted consistently into the frozen roadmap/contract. The Phase 10 upgrade specification remains Docker/Linux-specific and retains the unsafe DB restore rule discussed under C0-01.

## Agent update invariants

| Invariant | Current evidence | Required closure |
|---|---|---|
| Pinned artifact/integrity | Shared immutable release rule and downloaded SHA-256 | Bind to trusted release identity; preserve exact prior artifact. |
| Stop and safe replacement | Stop, backup old executable, replace, restart | Specify interrupted replacement reconciliation. |
| Restart | SCM start specified | Retain. |
| Functional health | Developer checks running/crash; R3 proposes endpoint health | Require authenticated/appropriate functional readiness before update success. |
| Rollback | Previous binary restoration on failure specified | Verify old agent health after restoration. |
| Reboot during update | R3 describes deterministic intermediate-file recovery | Adopt as authoritative Phase 4/10 acceptance and independent Windows failure test. |

This gate does not require `TMK.Agent.Updater.exe` by name. A safe implementation may use another mechanism. Nor does it require a live Windows test in Phase 0: the later-phase test contract must be explicit.

## Service identity: RG-C2-01, not a standalone blocker

The authoritative documents still name LocalService. The supplement grants staging write and IIS-config read access, while agent duties require IIS mutations. R3's proposed dedicated least-privilege account has not been integrated.

State the invariant: a dedicated service identity with explicit required filesystem, IIS administration and service-control grants, plus negative tests against unrelated resources. Do not assume a group membership automatically confers every required IIS privilege. The precise account and tested grants belong to Phase 4.

## Authentication phase separation

Phase 1 establishes dynamic trust material/default-key rejection and the reusable issuer/audience/scope contract, with minimal legacy containment. Phase 4 implements the compiled agent's full mTLS and scoped-token behavior. A valid transport certificate alone is not operation authorization, and a bearer token alone does not replace transport peer verification.

## Equal first-class program targets: PASS

Ubuntu 24.04 LTS and Windows Server 2022 remain equal targets. Phase 12A is Linux Gate A; Phase 12B is Windows Gate A. Linux evidence cannot certify Windows. The explicit staggered rule permits a Linux pilot after Linux Gate A while Windows work continues. Phase 15 remains the unified Dual-OS Commercial Gate.

The roadmap's schematic sequencing should be read with this explicit override. No Linux-only MVP conversion or indefinite Windows deferral is authorized. This governance PASS is not a Windows runtime readiness certificate.
