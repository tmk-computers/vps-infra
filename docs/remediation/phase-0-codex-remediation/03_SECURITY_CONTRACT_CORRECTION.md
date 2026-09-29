# SECURITY CONTRACT CORRECTION (C1-01 RESOLUTION)

**Document ID**: `REMED-P0-CDX-03`  
**Phase**: Phase 0 — Codex Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C1-01`)  
**Status**: COMPLETE ARCHITECTURAL SPECIFICATION  

---

## 1. Context & Problem Statement

The Codex Phase 0 Audit Gate flagged finding `C1-01` as a **Significant Defect (C1)**. The audited baseline suffered from two major security contract flaws:
1. **Platform vs Tenant Role Contradiction**: In `03_HISTORICAL_FINDING_TRACEABILITY.md`, DEF-11 stated: *"New tenant registers organization and receives tenant-scoped SuperAdmin account."* However, `ci-server/api/auth.js:82` grants any user with role `SuperAdmin` global authorization bypass across all tenant boundaries and platform systems. Giving a tenant user `SuperAdmin` allows full cross-tenant data exfiltration and control-plane takeover.
2. **Missing Token Trust Contract**: F02 and MR-36 remediation was reduced to simply generating randomized signing keys and rejecting default keys. It completely omitted token trust criteria: issuer validation, audience validation, cryptographic algorithm enforcement, token expiration, rotation, revocation, tenant binding (`tid`), and service-to-service authentication (such as AMS recalculation or Windows Agent communication).

This document establishes the corrected, authoritative security contract and Phase 1 acceptance criteria.

---

## 2. Platform Administration vs Tenant Administration Role Hierarchy

The platform strictly decouples platform-level infrastructure administration from tenant-level customer administration. There is no concept of a "tenant-scoped SuperAdmin".

```
+--------------------------------------------------------------------------+
|                       PLATFORM TRUST BOUNDARY                            |
|                                                                          |
|   PlatformSuperAdmin (Platform Operator / DevOps Team Only)             |
|   - Global host configuration, node provisioning, system telemetry       |
|   - Zero access to customer data / tenant secrets                        |
|                                                                          |
|   PlatformAuditor (Compliance / Security Auditor)                        |
|   - Read-only access to immutable system audit logs                      |
+--------------------------------------------------------------------------+
                                    |
            =================== BOUNDARY WALL ===================
            (No cross-boundary role inheritance or bypass allowed)
                                    |
+--------------------------------------------------------------------------+
|                        TENANT TRUST BOUNDARY                             |
|                                                                          |
|   TenantAdmin (Customer Organization Administrator)                      |
|   - Scoped strictly to TenantId (@Claim: tid)                            |
|   - Manage tenant users, services, deployment requests, alerts           |
|   - CANNOT access platform settings, docker host, or other tenants       |
|                                                                          |
|   TenantDeveloper (Customer Developer)                                   |
|   - Push code, trigger builds, view logs within TenantId                 |
|                                                                          |
|   TenantViewer (Customer Read-Only User)                                 |
|   - Read-only dashboard view within TenantId                             |
+--------------------------------------------------------------------------+
```

### 2.1 Formal Role & Permission Matrix

| Role | Scope | Tenant Isolated? | Permitted Operations | Explicitly Prohibited Operations |
|---|---|---|---|---|
| **`PlatformSuperAdmin`** | Global (Platform) | No (System-wide) | Configure host runners, manage system certificates, view system health, trigger platform upgrades. | Cannot query customer database tables, cannot read customer API keys, cannot execute commands inside customer containers without explicit customer consent. |
| **`PlatformAuditor`** | Global (Platform) | No (System-wide) | Read platform audit logs, view security telemetry. | Cannot mutate any platform or tenant configuration. |
| **`TenantAdmin`** | Tenant (`tid`) | **Strictly Yes** | Invite tenant users, manage tenant services, view tenant logs, manage tenant environment variables, trigger tenant service deployments. | **STRICTLY CANNOT**: perform platform-global operations, view or modify other tenants' resources, access the Docker socket, access host filesystems, or bypass authorization via `auth.js:82`. |
| **`TenantDeveloper`** | Tenant (`tid`) | **Strictly Yes** | Trigger CI builds for tenant repos, deploy to tenant staging/prod, view service metrics. | Cannot invite/delete users or manage tenant billing/secrets. |
| **`TenantViewer`** | Tenant (`tid`) | **Strictly Yes** | Read-only access to tenant dashboards, release history, and metrics. | Cannot mutate any resource. |

### 2.2 DEF-11 Acceptance Reconciliation
The acceptance criterion for DEF-11 in `03_HISTORICAL_FINDING_TRACEABILITY.md` is formally corrected to:
> *"When a new customer organization registers on the platform, the initial administrative user is assigned the role `TenantAdmin` scoped strictly to that organization's `TenantId`. Under no circumstances is the user assigned `PlatformSuperAdmin` or granted platform-global privileges. Any attempt by `TenantAdmin` to query cross-tenant resources or access platform control endpoints returns HTTP 403 Forbidden."*

---

## 3. Comprehensive Token Trust Contract

A "valid JWT" is NOT sufficient authorization. Every incoming token must satisfy a strict, multi-dimensional trust verification contract before any request is processed.

### 3.1 Token Trust Specification by Credential Type

| Credential Type | Issuer (`iss`) | Audience (`aud`) | Subject (`sub`) | Tenant Context (`tid`) | Roles / Scopes | Lifetime (`exp`) | Signature Algorithm | Storage & Transmission | Revocation & Rotation |
|---|---|---|---|---|---|---|---|---|---|
| **Human User JWT (Platform)** | `https://auth.vps-infra.local/` | `devops-manager-api` | `usr_uuid` | `PLATFORM` | `PlatformSuperAdmin`, `PlatformAuditor` | 15 minutes | `RS256` (RSA 2048+) or `HS256` ($\ge 256$ bits) | In-memory only in browser; transmitted via `Authorization: Bearer <jwt>`. | Refresh token rotation (sliding window, max 8h). Revocation checked via Redis/in-memory token denylist. |
| **Human User JWT (Tenant)** | `https://auth.vps-infra.local/` | `devops-manager-api`, `customer-portal` | `usr_uuid` | `uuid_tenant` | `TenantAdmin`, `TenantDeveloper`, `TenantViewer` | 15 minutes | `RS256` or `HS256` ($\ge 256$ bits) | Transmitted via `Authorization: Bearer <jwt>`. | Immediate revocation on user suspension or password reset via user security stamp check. |
| **External CI Worker Token** | `https://ci.vps-infra.local/` | `devops-manager-api` | `ci_runner_uuid` | `uuid_tenant` (or empty for system) | `ci:artifact:push`, `ci:status:report` | 10 minutes | `RS256` (asymmetric keypair, private key held in CI runner) | Single-use ephemeral token passed via HTTP header. | Explicit run token issued per CI job. Valid only for the duration and scope of that specific build ID. |
| **Windows Agent Token (`TMK.Agent.Windows`)** | `https://auth.vps-infra.local/` | `tmk-agent-windows` | `agent_host_uuid` | `PLATFORM` | `agent:deploy:execute`, `agent:telemetry:push` | 1 hour | `RS256` | Stored in Windows DPAPI / Local Machine Certificate store. | Mutual TLS (mTLS) with client certificate thumbprint validation, backed by rotating bearer tokens. Revoked if host agent is deregistered. |
| **Internal Inter-Service Token (AMS Recalculation)** | `https://devops-manager.vps-infra.local/` | `ams-calculator` | `svc_devops_manager` | Contextual tenant ID | `service:ams:recalculate` | 5 minutes | `RS256` / `HS256` | Transmitted across private Docker network only. | Short lifetime; regenerated on demand. Rejects public caller forwarding. |

### 3.2 Mandatory Token Validation Pipeline
Every API service must execute the following validation sequence on every request:
1. **Algorithm Check**: Strictly enforce approved algorithm (`RS256` or `HS256` with high-entropy secret $\ge 256$ bits). Explicitly reject `alg: "none"` and asymmetric-to-symmetric key confusion attacks.
2. **Issuer & Audience Check**: Validate that `iss == "https://auth.vps-infra.local/"` and `aud` exactly matches the service's designated identifier. Reject tokens intended for other microservices.
3. **Expiration & Clock Skew**: Validate `exp > UtcNow` with a maximum allowed clock skew of 60 seconds. Reject expired tokens with HTTP 401 Unauthorized.
4. **Tenant Context Binding (`tid`)**:
   - For all tenant-scoped endpoints, extract `tid` claim.
   - Verify that `tid` matches the URL route parameter (e.g. `/api/v1/tenants/{tenantId}/services`).
   - If `tid` does not match, return HTTP 403 Forbidden and log a security audit event (`SEC_TENANT_MISMATCH`).
5. **Revocation Check**: Check `jti` (JWT ID) against the distributed revocation cache (Redis or database denylist). If revoked, return HTTP 401 Unauthorized.
6. **Default Key Protection**: At application startup, the service computes the SHA-256 hash of the configured signing secret. If the secret matches any well-known default (e.g. `"YourSecretKeyHere12345"`, `"SuperSecretKey"`, or empty), the application **immediately terminates startup with a fatal configuration error**.

---

## 4. Phase 1 Security Acceptance Criteria (Negative Testing Suite)

Phase 1 covers MR-02, MR-03, MR-04, MR-05, MR-06, MR-07, MR-08, MR-28, and MR-36. To satisfy Codex requirements, every security MR must include explicit **negative test criteria**:

### 4.1 Master Negative Test Matrix

| MR ID | Security Domain | Target Component | Negative Test Scenario | Expected Outcome | Pass/Fail Gate |
|---|---|---|---|---|---|
| **MR-02** | Secure Secret Storage | `devops-manager/api` | Attempt to start API with unencrypted plaintext database password or secret in `appsettings.json`. | Application startup fails with `InvalidConfigurationException`. | Startup halted. |
| **MR-03** | Public Network Isolation | Infrastructure Docker Compose | Attempt to access PostgreSQL (port 5432) or internal Redis (port 6379) from external network interface. | Connection refused / dropped by firewall (ports bound strictly to `127.0.0.1` or internal Docker bridge). | External scan shows port closed. |
| **MR-04** | Secret Disclosure & Path Traversal | `ci-server` & `devops-manager` | 1. Send build log containing injected mock AWS/API secrets.<br>2. Submit deployment request with `ProjectDirectory = "../../../etc/passwd"`. | 1. Secrets are masked with `[REDACTED]` in persisted logs.<br>2. `Path.GetFullPath` validation rejects request with HTTP 400 Bad Request. | Zero secret leakage; zero sandbox escape. |
| **MR-05** | Rate Limiting & DoS | API Gateway / Ingress | Send 100 authentication requests within 10 seconds from single IP. | Requests beyond limit receive HTTP 429 Too Many Requests with `Retry-After` header. | DoS attack throttled. |
| **MR-06** | CORS Misconfiguration | `devops-manager/api` | Send HTTP OPTIONS preflight request with `Origin: http://evil-attacker.com`. | API returns response without `Access-Control-Allow-Origin: *` or unauthorized domain. | Unauthorized CORS rejected. |
| **MR-07** | AI API Key & Spend Controls | `ModelGatewayService` | 1. Request with `LocalOnly = true` sent when cloud model configured.<br>2. Streaming token request that exceeds configured budget cap. | 1. Gateway halts and returns HTTP 403 (cloud fallback strictly blocked).<br>2. Stream terminates immediately upon reaching monotonic cap. | Privacy preserved; budget enforced. |
| **MR-08** | Container Privilege Containment | `devops-manager` Dockerfile | Execute test checking container user ID and capabilities inside `devops-manager`. | Process runs as non-root UID 10001; Linux capabilities dropped; root filesystem is read-only. | Zero root escalation. |
| **MR-28** | Public DB Exposure Prevention | CI Infrastructure | Automated vulnerability scan detects any database listening on `0.0.0.0`. | CI Gate fails immediately with critical security violation. | Gate A blocked if exposed. |
| **MR-36** | JWT Token Trust & Key Randomization | `auth.js` & `Program.cs` | 1. Startup with default secret.<br>2. Token with `alg: "none"`.<br>3. Token with valid signature but wrong `aud`.<br>4. Token with Tenant A `tid` accessing Tenant B endpoint.<br>5. Tenant Admin attempting `POST /api/v1/platform/upgrade`.<br>6. Expired token.<br>7. Revoked token.<br>8. Unauthenticated call to AMS recalculation endpoint.<br>9. Unauthenticated call to `TMK.Agent.Windows`. | 1. Startup FAIL.<br>2. HTTP 401 Unauthorized.<br>3. HTTP 401 Unauthorized.<br>4. HTTP 403 Forbidden.<br>5. HTTP 403 Forbidden.<br>6. HTTP 401 Unauthorized.<br>7. HTTP 401 Unauthorized.<br>8. HTTP 401 Unauthorized.<br>9. HTTP 401 Unauthorized. | All 9 negative tests PASS. |

---

## 5. Conclusion

This security contract removes the conflicting "tenant-scoped SuperAdmin" role, replaces loose JWT validation with a comprehensive Token Trust Contract, and establishes exhaustive negative testing criteria for Phase 1. The boundaries between platform operators, customer tenants, and machine services are now cryptographically and architecturally sealed.
