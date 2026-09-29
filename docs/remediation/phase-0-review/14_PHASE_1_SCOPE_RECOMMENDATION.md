# 14 PHASE 1 SCOPE INDEPENDENT EVALUATION & RECOMMENDATION

**Document ID**: `REMED-P0-REV-14`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Developer Proposed Phase 1 Scope

In [`17_PHASE_1_ENTRY_CRITERIA.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md) and [`PHASE_0_FINAL_REPORT.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md), the Developer proposed that **Phase 1 (Shared Security Foundation)** implement the following 8 items:
1. `MR-02`: Signing / Authentication Defaults
2. `MR-03`: Leaked / Committed Credentials (`google-drive-credentials.json`)
3. `MR-04`: Git Tokens & Secret Disclosure in DTOs
4. `MR-07`: Secure Secret Provisioning in Setup
5. `MR-08`: RBAC / Customer Roles & Tenancy
6. `MR-34`: Maintenance Schema Migration Safety
7. `MR-36`: AMS Authorization & CI Authentication
8. `MR-37`: AMS Semantics & Commercial Truthfulness

---

## 2. Independent Evaluation of Proposed Scope (Finding R1-02)

The Reviewer evaluated the technical cohesion and security rigor of the proposed Phase 1 scope against four specific criteria:

### 2.1 Should MR-34 (Maintenance Schema Migration) Belong in Shared Security?
- **Reviewer Analysis**: Categorically, database schema migrations belong to **Data & Schema Integrity** (Phase 2 / MR-13), not security. The Developer included `MR-34` because `Product` and `ProjectService` tables are queried during authentication, tenant scoping, and authorization checks. If the database schema is missing these columns, integration tests in Phase 1 would encounter SQLSTATE 42703 errors.
- **Evaluation**: Including MR-34 in Phase 1 as an *isolated prerequisite migration* is pragmatically acceptable to ensure database tests pass, but it should be formally tagged as a schema prerequisite, not a security control.

### 2.2 Should MR-36 (AMS Authentication) Belong in Shared Security?
- **Reviewer Analysis**: `MR-36` represents an unauthenticated API endpoint (`optionalAuth` in `server.js`) leaking architectural structure to anonymous network callers, and an internal proxy call lacking Bearer tokens.
- **Evaluation**: **YES**. Securing API routes, enforcing JWT verification (`authenticateToken`), and injecting service-to-service Bearer credentials directly align with the core theme of Phase 1 (API Authentication & Authorization).

### 2.3 Should MR-37 (AMS Truthfulness) Belong in Shared Security?
- **Reviewer Analysis**: `MR-37` is purely documentation and UI copywriting (relabeling "Application Modernization Score" to "Static Architectural Modernization").
- **Evaluation**: **NO**. Including UI copywriting and marketing doc revisions inside a critical security phase dilutes engineering focus. Documentation and marketing truth remediation is formally allocated to **Phase 9 (MR-21, Supportability & Truthfulness)**. `MR-37` should be deferred to Phase 9.

### 2.4 Are Any Critical Security Findings Missing from Proposed Phase 1?
- **Reviewer Analysis**:
  1. **MR-28 (Windows Agent Authentication & Static Fallback Secret - P0)**: The Developer scheduled `MR-02` (Linux JWT secrets) and `MR-07` (Linux setup secrets) for Phase 1, but deferred `MR-28` (`"SuperCiSecretKey123!"` hardcoded in `tmk-iis-agent.ps1` and `IisClientService.cs`) to Phase 4! Leaving a hardcoded static bearer token in the Windows deployment agent violates the Dual-OS Non-Negotiable Mandate requiring equal security outcomes.
  2. **MR-06 (Database Network Exposure - P0)**: Ports 5432 and 5050 are exposed to `0.0.0.0`, accessible to the public internet with default credentials. Deferring public port exposure to Phase 3 while fixing JWT tokens in Phase 1 leaves the master database vulnerable.

---

## 3. Recommended Corrected Phase 1 Scope

The Reviewer recommends that Conversation 1 restructure Phase 1 into a tightly focused, cross-platform **Security, Authentication & Credential Hardening** work package:

| Master ID | Item Title | Scope | Severity | Remediation Action in Phase 1 |
| :--- | :--- | :---: | :---: | :--- |
| **MR-03** | Leaked / Committed Credentials | Shared | **P0** | Revoke GCP service account key in Cloud IAM; purge tracked JSON from git. |
| **MR-02** | Signing & Auth Defaults | Shared | **P0** | Enforce startup halt on default JWT secrets; generate random signing keys. |
| **MR-07** | Secure Secret Provisioning | Shared | **P1** | Implement cryptographically random password generation in setup scripts. |
| **MR-28** | Windows Agent Authentication | Windows | **P0** | Eliminate `"SuperCiSecretKey123!"`; generate random Windows agent token on setup. |
| **MR-04** | Secret Disclosure & Log Redaction | Shared | **P1** | Strip Git tokens from read DTOs; encrypt in DB; sanitize webhook logging. |
| **MR-08** | Multi-Tenant RBAC & BOLA | Shared | **P1** | Derivate TenantId from JWT; enforce tenant scoping on all queries and CI actions. |
| **MR-36** | AMS API Authorization | Shared | **P1** | Protect AMS routes with `authenticateToken`; inject Bearer token in proxy client. |
| **MR-34** | Maintenance Schema Migration | Shared | **P0** | Generate versioned EF Core migration adding maintenance fields (Prerequisite). |

### Explicitly Excluded from Phase 1:
- **MR-37**: Deferred to **Phase 9** (Truthful Documentation & UI Labeling).
- **MR-06**: Managed in **Phase 3** (Linux Adapter / Network Binding) or accelerated to Phase 1 setup scripts.
