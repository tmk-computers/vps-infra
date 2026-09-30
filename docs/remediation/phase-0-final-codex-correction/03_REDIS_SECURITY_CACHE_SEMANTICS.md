# 03 REDIS SECURITY CACHE SEMANTICS & FAILURE CONTRACT

**Document ID**: `FINAL-CORRECTION-03-REDIS-CACHE-SEMANTICS`  
**Phase**: Phase 0 — Final Codex Closure Surgical Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex 04_REDIS_ARCHITECTURE_GATE.md, CG-C1-01  
**Status**: COMPLETE — AUTHORITATIVE AND FROZEN  

---

## 1. Executive Summary

This specification establishes the detailed operational and failure semantics for **Redis 7** as a first-class component of the standard production architecture, specifically detailing its role within the multi-tiered authentication and token revocation pipeline.

It formally aligns Redis acceleration capabilities with the core durability invariant:
> **PostgreSQL 16 remains the sole authoritative, durable store for safety-critical state. Redis 7 provides high-throughput shared caching and ephemeral event distribution. Caching layers MUST NOT extend credential lifetime beyond the authoritative PostgreSQL revocation point.**

---

## 2. Multi-Tiered Read & Write Pathways

### 2.1 Write Pathway (Revocation Ingress)
1. **Durable Ingress**: A revocation event (e.g., user logout, account suspension, security stamp rotation, admin credential revocation) arrives at the API layer.
2. **PostgreSQL Commit (Effective Point)**: The API executes `INSERT INTO "RevokedTokens" ("Jti", "Subject", "RevokedAt", "ExpiresAt")` inside a PostgreSQL transaction.
   - The revocation is **NOT successful** until PostgreSQL acknowledges durable transaction commit.
   - The instant this commit completes is the **Revocation Effective Point**.
3. **Redis Synchronization**: Immediately following PostgreSQL commit, the API writes the revoked `jti` to Redis 7 (with a TTL matching the token's remaining lifetime) and publishes an invalidation event to the Redis Pub/Sub channel `auth:revocation:broadcast`.
4. **Local Cache Invalidation**: Worker nodes listening to `auth:revocation:broadcast` evict or update local process memory cache entries.
5. **API Response**: HTTP 200 OK or 204 No Content returned to caller confirming durable revocation.

### 2.2 Read Pathway (Token Authorization)
```
[ Incoming API Request with Bearer JWT ]
                 │
                 ▼
┌─────────────────────────────────┐
│ Tier 1: Process-Local Memory    │  Fast in-memory hash set.
│         Cache Look-up           │  Checks if jti is marked revoked.
└────────────────┬────────────────┘
                 │
        ┌────────┴────────┐
   Marked Revoked     Not Marked Revoked
        │                 │
        ▼                 ▼
   [ DENY 401 ]   ┌─────────────────────────────────┐
                  │ Tier 2: Redis 7 Distributed     │  Shared cluster-wide lookup.
                  │         Revocation Cache        │  Checks if jti is marked revoked.
                  └───────────────┬─────────────────┘
                                  │
                         ┌────────┴────────┐
                    Marked Revoked     Not Marked Revoked / Cache Miss / Redis Error
                         │                 │
                         ▼                 ▼
                    [ DENY 401 ]   ┌─────────────────────────────────┐
                                   │ Tier 3: PostgreSQL 16 Authority │  Evaluates "RevokedTokens"
                                   │         Validation Query        │  table directly.
                                   └───────────────┬─────────────────┘
                                                   │
                                          ┌────────┴────────┐
                                     Record Found       No Record Found
                                          │                 │
                                          ▼                 ▼
                                     [ DENY 401 ]     [ ALLOW 200 ]
```

- **Safety Rule on Cache Freshness**: If a worker node relies on a cached positive authorization entry, but cannot verify that its cache is fresh relative to authoritative PostgreSQL state, the worker node **must verify against PostgreSQL** or **fail closed**.
- **No Stale Pass**: Stale negative cache entries ("not revoked") held in local memory or Redis **shall never authorize a request evaluated after PostgreSQL commit**.

---

## 3. Comprehensive Gate-A Testing Scenarios (Deterministic Oracles)

All six Gate-A Redis testing scenarios are defined below with explicit, unambiguous pass/fail criteria:

| Scenario # | Condition | Injected Fault / State | Expected Behavioral Oracle | Acceptance Criteria |
|:---:|---|---|---|---|
| **1** | **Healthy Redis (Warm Cache)** | Redis 7 available, authenticated, responsive. Standard production workload. | Active token validations and rate-limit checks hit Redis; sub-millisecond response latency. Cold entries or cache misses follow the documented read-through path to PostgreSQL without crashing. | Zero dropped requests; sub-millisecond cache latency on warm entries; 100% authorization correctness. |
| **2** | **Redis Unavailable (Outage)** | Redis service stopped, network partition injected, or daemon crashed. | Platform falls back to PostgreSQL 16 for security checks and deployment queries; system health probes signal `DEGRADED (Redis unavailable)`. If PostgreSQL is also unavailable, security operations **fail closed (`DENY`)**. | Zero authorization bypass; zero loss of durable data; health probes report degraded cache; fail-closed behavior verified. |
| **3** | **Redis Restart & Recovery** | Redis daemon restarted with clean memory or AOF replay. | Platform reconnects automatically using exponential backoff; cache repopulates from PostgreSQL on read; temporary coordination leases re-synchronize without deadlock. | Automatic reconnection within 15 seconds; zero orphan locks; authoritative state intact. |
| **4** | **Stale Cached Security Data (CG-C1-01)** | Worker holds valid token status in local/Redis cache; revocation committed in PostgreSQL; invalidation message delayed or dropped. | **10-Step Test**: Token revocation committed at T1. At T2, request using revoked token arrives at worker with stale cache. Request is **DENIED (HTTP 401)**. Invalidation propagation restores cache sync within operational SLO ($\le 5$s). | **Exactly ZERO post-revocation requests authorized by stale cache state.** Zero authorization grace period. |
| **5** | **Redis Data Loss (Flush/Wipe)** | `FLUSHALL` executed on Redis cluster or unpersisted crash. | Zero loss of deployment state, user identities, release history, or durable revocation records. Platform reconstructs active cache from PostgreSQL on read. | Authoritative database state 100% intact; system continues operating safely via read-through. |
| **6** | **Redis Latency / Partition** | 5000ms socket latency injected; queue saturation; network partition. | Timeout circuit-breaker opens; requests fall back safely to PostgreSQL or fail closed. Slow cache **NEVER** turns safety checks into permissive bypass. | Timeouts enforced within 2000ms; requests fall back or fail closed; zero permissive timeouts. |

---

## 4. Master Remediation (MR) Ownership & Lifecycle Traceability

Redis security and failure contract responsibilities are strictly allocated to existing MR items, maintaining the exact 37 Master Remediation count:

- **MR-02 / MR-07**: Redis authentication secrets dynamically generated during install; zero default passwords.
- **MR-05 / MR-06**: Redis network binding restricted to internal loopback (`127.0.0.1`) or private container overlay bridge (`traefik_net`); ACL command restrictions for dangerous operations.
- **MR-10 / MR-11 / MR-12**: Non-authoritative deployment notification fan-out; deployment mutexes and state machine remain durably grounded in PostgreSQL.
- **MR-16**: Cgroup memory caps and Redis `maxmemory` eviction policies to safeguard host resources.
- **MR-18**: Redis health checks, disconnection alerts, and latency threshold monitoring.
- **MR-20**: Standard platform runtime engine standardization on PostgreSQL 16 (durable store) + Redis 7 (caching/acceleration).
- **MR-36**: Multi-tiered token revocation pipeline (`Local Cache -> Redis 7 -> PostgreSQL`) with fail-safe PostgreSQL fallback and zero authorization grace period.
