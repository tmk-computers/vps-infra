# 02 Independent Review: CG-C1-01 Revocation Visibility & Cache Semantics

**Document ID**: `REVIEW-R5-02-CG-C1-01-REVOCATION`  
**Role**: Antigravity Conversation 2 — Independent Reviewer  
**Audit Target**: Codex Finding `CG-C1-01` (`07_FINAL_FINDINGS_REGISTER.md:20-42`)  
**Status**: VERIFIED & RESOLVED (PASS)  

---

## 1. Finding Overview & Defect Analysis

In the Codex Final Closure Gate, finding **`CG-C1-01`** was identified as the sole C1 blocker:
> The canonical security contract promised immediate token revocation and stated that stale cache entries must not admit revoked credentials. The Redis Architecture Amendment introduced multi-tier caching with a stated negative-cache TTL and revocation convergence bound of up to 5 seconds. This created a documentary contradiction: if instance A holds a cached entry that a token is valid, PostgreSQL commits its revocation on instance B, and a request arrives at instance A before invalidation Pub/Sub arrives, does instance A accept or deny the request?

Codex mandated:
1. Define a single, unambiguous **Revocation Effective Point**;
2. Require that authorization decisions initiated after this point receive **`DENY` (HTTP 401)**;
3. Clarify that any 5-second convergence metric is strictly an **operational cache-propagation SLO** and **NEVER an authorization grace period**;
4. Enforce **fail-closed** behavior whenever cache validity is uncertain;
5. Establish a single, deterministic **Gate-A test oracle** with zero post-revocation authorizations allowed.

---

## 2. Independent Verification of Corrections

### 2.1 The Revocation Effective Point (Section 4 Compliance)

Independent inspection of the active Phase 0 documentation confirms the establishment of a single canonical invariant:

> **A credential or token revocation becomes security-effective at the exact instant the authoritative PostgreSQL revocation transaction successfully commits.**

This rule is consistently formulated across all active documents:
- [`08_SECURITY_BOUNDARIES.md:129-131`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md#L129-L131):  
  *"Revocation Effective Point: Revocation is security-effective when the PostgreSQL revocation transaction commits. For any authorization decision initiated after that point, stale cache state MUST NOT authorize the revoked credential. The request MUST be denied (`DENY` / HTTP 401)."*
- [`06_DATABASE_SUPPORT_MATRIX.md:67-70`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md#L67-L70):  
  *"Revocation Effective Point: A credential/token revocation becomes security-effective when the authoritative PostgreSQL revocation transaction commits. For any authorization decision initiated after that effective point, stale cache state MUST NOT authorize the revoked credential; the request MUST be denied (`DENY` / HTTP 401)."*
- [`REDIS_ARCHITECTURE_AMENDMENT.md:114-116`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md#L114-L116):  
  *"Revocation Effective Point: A credential/token revocation becomes security-effective at the exact instant the authoritative PostgreSQL revocation transaction commits."*
- [`02_REVOCATION_VISIBILITY_CONTRACT.md:25-30`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/02_REVOCATION_VISIBILITY_CONTRACT.md#L25-L30):  
  *Dedicated formal invariant specification and timeline.*

**Verification**: No active Phase 0 document defines a later security-effective point.

---

### 2.2 Post-Revocation Request Semantics (Section 5 Compliance)

For any authorization decision initiated after the PostgreSQL revocation transaction commits:
- **Required Observable Outcome**: **`DENY` (HTTP 401 Unauthorized)**.
- **Strict Prohibition**: The request **MUST NOT** be authorized based on:
  1. Stale process-local memory cache;
  2. Stale Redis distributed cache;
  3. Delayed, lost, or pending Pub/Sub invalidation broadcasts;
  4. Local cache negative-cache TTLs that have not yet expired;
  5. Unsynchronized worker node state.

**Verification**: All active documents explicitly prohibit stale cache state from extending credential lifetime or permitting authorization after the durable commit point.

---

### 2.3 The 5-Second Metric: Operational SLO Only (Section 6 Compliance)

A comprehensive search of all active documentation for `5-second`, `five seconds`, `\le 5`, and `convergence` was performed.

Every active reference unambiguously designates this threshold as an **operational cache-convergence SLO only**:
- [`REDIS_ARCHITECTURE_AMENDMENT.md:136`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md#L136):  
  *"Strict Invariant: Cache convergence is an operational SLO only, NEVER an authorization grace period. It does NOT permit revoked tokens to remain valid for up to 5 seconds, and does NOT allow any authorization engine to accept stale cached validity after the durable revocation effective point."*
- [`02_REVOCATION_VISIBILITY_CONTRACT.md:37-43`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/02_REVOCATION_VISIBILITY_CONTRACT.md#L37-L43):  
  *"Invariant 3: Cache Convergence Is An Operational SLO, Not A Grace Period... Any statement in documentation or architectural commentary implying a 5-second 'revocation grace window' is formally rejected and superseded by this invariant."*
- [`08_SECURITY_BOUNDARIES.md:149`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md#L149):  
  *"zero authorization grace period is permitted."*
- [`16_PHASEWISE_REMEDIATION_PLAN.md:85`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md#L85):  
  *"zero authorization grace period."*

**Verification**: Exactly zero active statements permit an authorization grace period, token-validity extension, or temporary post-revocation acceptance.

---

### 2.4 Cache Uncertainty & Fail-Closed Semantics (Section 7 Compliance)

Inspection of [`02_REVOCATION_VISIBILITY_CONTRACT.md:87-92`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/02_REVOCATION_VISIBILITY_CONTRACT.md#L87-L92) and [`03_REDIS_SECURITY_CACHE_SEMANTICS.md:67-69`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/03_REDIS_SECURITY_CACHE_SEMANTICS.md#L67-L69) confirms the required resolution pathways:
1. When cache freshness is uncertain, the system **bypasses the cache and queries PostgreSQL directly**;
2. If PostgreSQL is unreachable, the system **fails closed (`DENY` / HTTP 401)**;
3. **No Permissive Fallback**: The specification contains exactly **zero** paths where uncertain or partitioned cache state results in an `ALLOW` decision (`uncertain -> fail closed`).

---

### 2.5 Redis Outage & Failure Model (Section 8 Compliance)

The specification explicitly addresses all failure scenarios:
- **Redis Outage / Unreachable**: Pipeline bypasses Redis and queries PostgreSQL directly (`Local Cache -> PostgreSQL Authority`). Core API remains functional in degraded mode;
- **Redis Crash / Restart**: Redis reconnects with exponential backoff and repopulates from PostgreSQL on demand;
- **Redis Data Loss / Flush (`FLUSHALL`)**: PostgreSQL contains all authoritative revocation records (`RevokedTokens` table). No tokens are resurrected or de-revoked;
- **Redis Socket Latency**: Bounded timeout (<2000ms) with circuit-breaking; slow cache never defaults to permissive bypass.

---

### 2.6 Invalidation Delivery Independence (Section 9 Compliance)

In [`02_REVOCATION_VISIBILITY_CONTRACT.md:93-97`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/02_REVOCATION_VISIBILITY_CONTRACT.md#L93-L97):
- Redis Pub/Sub, local memory evictions, and cache key deletions are strictly classified as **operational performance optimizations**;
- Successful invalidation delivery is **NOT the security boundary**;
- Dropped Pub/Sub packets, socket lag, or worker thread delays must never allow a revoked credential to authorize a request post-commit.

---

### 2.7 Race Semantics & Boundary Ordering (Section 10 Compliance)

The boundary ordering is deterministically specified in [`02_REVOCATION_VISIBILITY_CONTRACT.md:101-109`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/02_REVOCATION_VISIBILITY_CONTRACT.md#L101-L109):
- **Decision completed before PostgreSQL commit**: Legitimate evaluation under pre-revocation state (`ALLOW` if otherwise valid);
- **Decision initiated after PostgreSQL commit**: Evaluated under post-revocation state (`DENY` / HTTP 401);
- **Decision crossing commit boundary**: Phase 1 implementation is required to enforce deterministic, fail-safe ordering (e.g. read-after-write verification, serializable isolation, or fail-safe recheck) ensuring no request admitted after commit completes authorized.

---

### 2.8 Gate-A Revocation Test Oracle (Section 11 Compliance)

A deterministic **10-Step Gate-A Acceptance Test Scenario** is formally specified in [`02_REVOCATION_VISIBILITY_CONTRACT.md:127-147`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/02_REVOCATION_VISIBILITY_CONTRACT.md#L127-L147), [`03_REDIS_SECURITY_CACHE_SEMANTICS.md:81`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-codex-correction/03_REDIS_SECURITY_CACHE_SEMANTICS.md#L81), and [`REDIS_ARCHITECTURE_AMENDMENT.md:164`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md#L164):

1. Issue valid JWT for User U;
2. Populate Tier 1 (local) and Tier 2 (Redis) caches with valid status;
3. Commit revocation transaction in PostgreSQL (`Revocation Effective Point established`);
4. Artificially block/delay Redis Pub/Sub invalidation delivery to Worker Node W2;
5. Submit authorization request using User U's token to Worker Node W2;
6. **ASSERT** request is REJECTED with HTTP 401 Unauthorized;
7. **ASSERT** Worker Node W2 did NOT admit the request based on its stale local/Redis cache;
8. Unblock invalidation propagation;
9. **ASSERT** Worker Node W2 converges cache state within operational SLO ($\le 5$s);
10. **ASSERT** security audit log records exactly one post-revocation rejected attempt.

**Acceptance Criterion**:
# Exactly ZERO post-revocation authorizations allowed by stale cache state.

---

## 3. Reviewer Conclusion on CG-C1-01

The Developer's surgical correction completely eliminates the ambiguity identified by Codex in `CG-C1-01`. The Revocation Effective Point, post-revocation request semantics, fail-closed cache uncertainty handling, operational SLO boundaries, and deterministic Gate-A test oracle are fully articulated and consistently reflected across all canonical and remediation documents.

**Verdict: CG-C1-01 RESOLVED (PASS)**
