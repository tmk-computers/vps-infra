# 02 REVOCATION VISIBILITY CONTRACT & SECURITY INVARIANTS

**Document ID**: `FINAL-CORRECTION-02-REVOCATION-VISIBILITY`  
**Phase**: Phase 0 — Final Codex Closure Surgical Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex CG-C1-01 (`07_FINAL_FINDINGS_REGISTER.md:20-42`)  
**Status**: COMPLETE — AUTHORITATIVE AND FROZEN  

---

## 1. Executive Summary & Problem Statement

During the Codex Final Closure Gate, finding **`CG-C1-01`** identified a critical ambiguity in the Phase 0 token revocation contract:
- The canonical security contract promised immediate token revocation and stated that stale cache entries must not admit revoked credentials.
- The Redis Architecture Amendment introduced multi-tier caching with a stated negative-cache TTL and revocation convergence bound of up to 5 seconds.
- This created a documentary contradiction: if instance A holds a cached entry that a token is valid, PostgreSQL commits its revocation on instance B, and a request arrives at instance A before invalidation Pub/Sub arrives, does instance A accept or deny the request?

This document eliminates that ambiguity. It establishes a single, deterministic, fail-safe security invariant across all platform components: **revocation becomes security-effective at the PostgreSQL commit point; post-commit authorization decisions must DENY the revoked credential; and cache convergence is strictly an operational SLO, NEVER an authorization grace period.**

---

## 2. Canonical Security Invariants

### Invariant 1: The Revocation Effective Point
> **A credential or token revocation becomes security-effective at the exact instant the authoritative PostgreSQL revocation transaction successfully commits.**

- Revocation writes MUST be written and committed durably to the PostgreSQL `RevokedTokens` table before the revocation operation is reported as successful to callers or administrators.
- Invalidation messages dispatched to Redis or process-local memory caches occur immediately *after* durable PostgreSQL commit.

### Invariant 2: Stale Cache State Must Not Authorize Revoked Credentials
> **For any authorization decision initiated after the Revocation Effective Point, stale cache state MUST NOT authorize the revoked credential.**

- Redis distributed cache and process-local memory caches are **acceleration and optimization layers only**.
- They **MUST NOT** extend credential validity beyond the authoritative PostgreSQL revocation point under any circumstances.

### Invariant 3: Cache Convergence Is An Operational SLO, Not A Grace Period
> **Operational cache convergence ($\le 5$ seconds) represents the target timeline for distributed cache synchronization. It is an operational SLO only and NEVER constitutes an authorization grace period.**

- It does **NOT** mean revoked tokens remain valid for up to 5 seconds.
- It does **NOT** permit any authorization engine to accept stale cached validity after the durable revocation effective point.
- Any statement in documentation or architectural commentary implying a 5-second "revocation grace window" is formally rejected and superseded by this invariant.

---

## 3. Post-Revocation Request Semantics

For any request whose authorization decision is evaluated after the authoritative PostgreSQL revocation commit:

### Required Observable Outcome:
# `DENY` (HTTP 401 Unauthorized)

The request **MUST NOT** succeed merely because:
1. Process-local memory cache contains a stale non-revoked entry;
2. Redis distributed cache contains a stale non-revoked entry;
3. Redis Pub/Sub invalidation broadcast is delayed, partitioned, or pending delivery;
4. The executing worker node has not yet processed the invalidation notification;
5. The local cache negative-cache TTL has not yet expired.

```
Timeline:
T0: Token T is valid.
T1: PostgreSQL commits revocation transaction for Token T.  <-- [REVOCATION EFFECTIVE POINT]
T2: Worker 2 holds stale cache entry for Token T.
T3: Request with Token T arrives at Worker 2.
T4: Invalidation message arrives at Worker 2.

At T3 (Evaluated post-T1):
REQUIRED OUTCOME = DENY (HTTP 401 Unauthorized)
Stale cache at T2 MUST NOT authorize Token T.
```

---

## 4. Cache Safety & Eviction Model

The caching protocol must preserve security correctness at all times:

### 4.1 Positive vs. Revocation Cache Information
- **Positive Authorization Cache Information**: Cached entries indicating that a token or credential previously passed validation.
  - Positive cached entries are **derived, disposable hints**.
  - Positive cached entries **MUST NOT** override or bypass authoritative revocation state.
- **Revocation Information**: Durable records in PostgreSQL (`RevokedTokens` table).
  - PostgreSQL is the **sole authoritative source of truth**.
  - Redis and local cache representations of revoked tokens are fast distributed read-caches of PostgreSQL truth.

### 4.2 Handling Uncertain or Stale Cache State
When an authorization decision requires verification of revocation status and the system cannot establish that the cached security state is guaranteed fresh:
1. The platform **SHALL bypass the cache and query PostgreSQL directly**; or
2. If PostgreSQL is unreachable, the platform **SHALL fail closed (`DENY` / HTTP 401)**.
3. **Strict Prohibition**: Under no circumstances shall an uncertain, unverified, or potentially partitioned cache state result in permissive authorization (`uncertain cache -> fail closed`).

### 4.3 Invalidation Failure & Delivery Guarantees
- Redis Pub/Sub, local-cache evictions, and cache key deletions are operational acceleration mechanisms designed to minimize read latency on PostgreSQL.
- **Delivery Independence**: **Successful delivery of an invalidation message MUST NOT be the security boundary.**
- Network lag, socket buffering, Redis restarts, dropped Pub/Sub packets, or worker thread delays must never silently turn a revoked credential into an accepted credential.

---

## 5. Race Semantics & Boundary Ordering

The authorization decision boundary is strictly defined relative to the PostgreSQL transaction commit:

| Decision Timing | State Evaluated Under | Expected Outcome | Rationale |
|---|---|---|---|
| **Completed before T1 commit** | Pre-revocation state | Allowed (if token otherwise valid) | The credential was durably valid when the decision completed. |
| **Initiated after T1 commit** | Post-revocation state | **`DENY` (HTTP 401 Unauthorized)** | The credential was revoked prior to the decision; revocation invariant strictly enforced. |
| **Genuinely concurrent with T1 commit** | Crossing boundary | Deterministic fail-safe ordering | Phase 1 implementation must provide a deterministic ordering mechanism (e.g. read-after-write verification, serializable transaction isolation, or fail-safe recheck) ensuring no request admitted after T1 commit completes authorized. |

---

## 6. Degraded Operation & Redis Outage Behavior

Redis unavailability must never compromise the security boundary:

1. **Redis Offline / Partitioned**:
   - The authorization pipeline bypasses Redis and queries PostgreSQL directly (`Local Cache -> PostgreSQL Authority`).
   - Latency may increase, but zero unauthorized requests are permitted.
2. **PostgreSQL Offline / Unreachable**:
   - If PostgreSQL cannot be queried to verify revocation status for an active credential, the security decision **MUST fail closed (`DENY`)**.
   - The platform never assumes an unverified credential is valid during a database outage.
3. **Redis Restart / Cache Loss**:
   - Following a Redis crash, restart, or `FLUSHALL`, caches are repopulated from PostgreSQL on demand. Authoritative revocation state in PostgreSQL remains completely intact and uncorrupted.

---

## 7. Gate-A Acceptance Test Oracle

To eliminate test ambiguity, Phase 1 Gate-A testing must execute the following **10-Step Deterministic Acceptance Test**:

```text
Step  1: Issue a valid JWT for User U.
Step  2: Execute successful request; populate Tier 1 (local) and Tier 2 (Redis) caches with valid status.
Step  3: Execute revocation for User U; commit revocation transaction in PostgreSQL.
         [REVOCATION EFFECTIVE POINT ESTABLISHED]
Step  4: Artificially block/delay Redis Pub/Sub invalidation delivery to Worker Node W2.
Step  5: Send authorization request using User U's token to Worker Node W2.
Step  6: ASSERT request is REJECTED with HTTP 401 Unauthorized.
Step  7: ASSERT Worker Node W2 did NOT admit the request based on its stale local/Redis cache.
Step  8: Unblock network; allow Redis Pub/Sub invalidation to propagate.
Step  9: ASSERT Worker Node W2 local cache evicts/updates entry within operational SLO (<= 5s).
Step 10: ASSERT security audit log records exactly one post-revocation rejected attempt.
```

### Acceptance Criterion:
# Exactly ZERO post-revocation authorizations allowed by stale cache state.
The operational convergence SLO ($\le 5$s) measures cache synchronization speed; it **MUST NOT** admit any requests after Step 3.
