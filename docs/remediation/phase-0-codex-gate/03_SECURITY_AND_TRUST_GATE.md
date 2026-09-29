# Security and trust gate

## Verdict

**CORRECTION REQUIRED.** The nine-item Phase 1 scope is coherent as a Shared Security Foundation. No critical item in that list has been relegated to cosmetic work. Its implementation acceptance criteria still need C1-01 and C1-04 corrections.

## Security foundation review

| MR | Assessment |
|---|---|
| MR-01 | External isolated CI is the correct Gate-A boundary for untrusted build/test execution. Retain integrated CI code for development. Do not confuse removing build access with constraining the privileged management API itself. |
| MR-02 | Default signing keys are correctly OPEN and Phase 1. Preserve issuer/audience/algorithm validation, key rotation and old-token rejection from original F02. |
| MR-03 | The committed credential requires revocation/rotation verification and removal from distribution. Key validity was not tested; “live key” is an unproven historical assertion. History cleanup alone cannot revoke a copied key. No credential action was performed by this gate. |
| MR-04 | DTO/log/process redaction and protected storage are correctly Phase 1. DEF-15 filesystem containment needs an explicit subtask/owner instead of disappearing inside a secret-disclosure title. |
| MR-05 | Application database least privilege is appropriate. Its Linux origin does not waive database identity isolation for Windows-hosted applications. Acceptance should test denied cross-tenant data access, not categorically prohibit all PostgreSQL catalog visibility needed by normal clients. |
| MR-06 | Public database/admin publications are correctly a security task. Manifest exposure is confirmed; actual WAN reachability depends on deployed network controls and was not port-scanned. Redis references mean hygiene for an encountered historical/external configuration, never creation or certification of Redis. |
| MR-07 | Per-install secrets, protected key storage and failure on unsafe defaults are appropriate. F16 privacy/fallback/resource obligations need explicit preservation even while model inference remains disabled. |
| MR-08 | Tenant/resource-scoped authorization is appropriate. DEF-11's tenant “SuperAdmin” acceptance conflicts with platform-wide bypass semantics. Fix the role contract before implementation. |
| MR-28 | Phase 1 must define authenticated encrypted agent communications, key provisioning/rotation/revocation and caller/resource authority. Phase 4 consumes the contract in TMK.Agent.Windows. Minimal legacy containment is acceptable; do not productionize the old daemon as a parallel product. |
| MR-36 | Mandatory authentication and a valid proxy identity fix the immediate anonymous/401 defects. Authentication alone is not tenant authorization: reads and recalculation require scoped permissions, not an unrestricted service identity. |

The original security scope is **MR-02, MR-03, MR-04, MR-05, MR-06, MR-07, MR-08, MR-28, MR-36**. MR-34 is a schema prerequisite; MR-37 is truthfulness and remains before customer claims, not a security implementation task.

## CI trust boundary and negative evidence

Gate A permits external isolated CI. The production profile must prevent integrated build execution through API, webhook and background paths, rather than merely recommending an external provider. Artifacts arrive with exact identity and trusted provenance. Do not treat a bare checksum as an authenticated producer identity.

Future integrated CI qualification must demonstrate that malicious build/test code cannot obtain production daemon authority, host mounts, platform credentials, cloud metadata, production database/network access or another tenant's artifacts/logs. Test resource exhaustion, concurrent admissions and bypass routes. A rootless tool name, cgroup flag or bridge alone is not certification. The current specification names useful controls but does not carry all negative criteria through to parent-MR closure.

DEF-08's management API mounts and F01's untrusted test socket are related but distinct trust boundaries. The original trace row already demands that API compromise not allow arbitrary host mutation; the phase checklist must either preserve that demand or explicitly document a bounded trusted-controller architecture and its accepted residual authority.

## AI safety scope

The inventory appropriately distinguishes deterministic Copilot, heuristic build diagnosis/digest, deterministic approval/tools, experimental model gateway, and specification-only personas. AMS is deterministic source-pattern scoring, not model inference. Neither AI nor AMS may authorize release, rollback, backup, restore, monitoring success or Gate A.

Gate-A disabled/excluded features must be enforced server-side, not merely hidden in UI. F15 approvals remain disabled until transactional replay/drift/recovery criteria pass; F16 cannot be re-enabled without privacy, fallback, spend and resource controls. No additional AI functionality is required for infrastructure safety.

## Evidence

Primary anchors: ci-server/api/auth.js:49,82,112; ci-server/api/server.js:623,634,645,662; ProductController.cs:231; ModelGatewayService.cs:101,202; infra docker-compose.yml:72–80 and 142–144; original findings.json F01/F02/F15/F16/F22. See [findings register](06_CODEX_FINDINGS_REGISTER.md) for linked exact artifacts and corrections.
