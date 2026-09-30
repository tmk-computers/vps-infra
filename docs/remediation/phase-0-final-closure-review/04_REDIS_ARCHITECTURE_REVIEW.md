# 04 REDIS 7 PRODUCTION ARCHITECTURE & DUAL-STORE GOVERNANCE REVIEW

**Document ID**: `FINAL-REVIEW-04-REDIS`  
**Phase**: Phase 0 — Final Independent Closure Review  
**Review Cycle**: Final Independent Closure Review  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Status**: Authoritative Architectural Audit Complete  
**Date**: 2026-09-30  

---

## 1. Intentional Architectural Shift: First-Class Production Redis 7

### 1.1 Policy Mandate & Scope
Prior to final candidate freeze, an intentional product architecture decision was made:
> **Redis 7 is now a first-class component of the standard production architecture.**  
> It replaces the previous classification: `Redis = Optional / Not Gate-A Certified Dependency`.

The Reviewer evaluated the new Redis architecture for coherence, safety, traceability, non-authoritative durability boundaries, and compatibility with previously frozen Phase 0 safety contracts.

### 1.2 Verification of Active Authoritative Baseline
The Reviewer searched all authoritative baseline documents under `docs/remediation/phase-0/` for stale exclusion statements:
- `Optional / Not Gate-A Certified Dependency`: **0 occurrences**.
- `without Redis`: **0 occurrences**.
- `Redis excluded`: **0 occurrences**.

All active authoritative documents ([`04_TARGET_ARCHITECTURE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md), [`06_DATABASE_SUPPORT_MATRIX.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md), [`08_SECURITY_BOUNDARIES.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md), [`16_PHASEWISE_REMEDIATION_PLAN.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md), [`17_PHASE_1_ENTRY_CRITERIA.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/17_PHASE_1_ENTRY_CRITERIA.md), [`PHASE_0_FINAL_REPORT.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md)) consistently define Redis 7 as standard production caching and acceleration infrastructure. Historical audit reports retain earlier historical text as immutable evidence.

**Reviewer Assessment**: **PASS**.

---

## 2. Non-Negotiable Durability Invariant: PostgreSQL as Sole Durable Truth

### 2.1 The Dual-Store Boundary
[`REDIS_ARCHITECTURE_AMENDMENT.md:22-26`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md#L22-L26) and [`06_DATABASE_SUPPORT_MATRIX.md:54`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md#L54) establish the fundamental safety invariant:
> **Redis SHALL NOT be the sole authoritative durable store for safety-critical platform state.**  
> **PostgreSQL remains the sole durable source of truth for critical control-plane state.**

### 2.2 Strictly Partitioned Responsibilities

| Subsystem State | Durable Authority (PostgreSQL 16) | High-Performance Acceleration (Redis 7) |
|---|---|---|
| **Deployment State** | Sole authoritative state machine transitions, target/actual state, rollback triggers. | Ephemeral step progress publishing and WebSocket status distribution. |
| **Release History** | Immutable release manifests, image digests, SemVer tags. | None (query PostgreSQL directly). |
| **User & Tenant Config** | Organizations, users, roles, permissions, tenant boundaries. | Bounded TTL read-through caching. |
| **Token Revocation** | Authoritative `RevokedTokens` table (`jti`, subject, expiration). | Distributed revocation cache (`Local Cache -> Redis 7 -> PostgreSQL`). |
| **Audit Trails** | Cryptographically verifiable append-only audit ledgers. | None (all audit events commit to PostgreSQL). |
| **Backup / DR Metadata** | Signed recovery point catalogs, checksums, encryption manifests. | None (cataloged in PostgreSQL and cloud metadata). |
| **Rate Limiting & Counters** | Historical usage and financial billing records. | Sliding-window request counters, API throttling, token buckets. |
| **Distributed Coordination** | Transaction-level advisory locks (`pg_advisory_xact_lock`), idempotency keys, epoch tokens. | Ephemeral worker lease pre-filtering and heartbeat rendezvous. |
| **Real-Time Pub/Sub** | None (PostgreSQL NOT used for high-frequency pub/sub). | High-throughput Pub/Sub message broker and event fan-out. |

**Reviewer Assessment**: **PASS**. The boundary is clean, unambiguous, and guarantees zero data loss of critical state upon Redis restart or wipe.

---

## 3. Redis Failure & Degraded Operation Model

[`REDIS_ARCHITECTURE_AMENDMENT.md:66-83`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md#L66-L83) defines explicit behavior across all failure modes:

1. **Unavailability Invariant**: The complete crash, partition, or stoppage of Redis **MUST NOT** by itself cause loss of deployment truth, authorization truth, token revocation truth, audit history, or release history.
2. **Safe Fallback to PostgreSQL**: Where safe fallback is possible (e.g. token validation, permission checks, deployment status queries), the platform falls back immediately to PostgreSQL. Latency increases, but security truth is preserved.
3. **Fail-Closed on Unsafe Coordination**: Where safe fallback is impossible (e.g. distributed lock acquisition where concurrent modification cannot be prevented, or rate-limiting failure that would risk cascading host exhaustion), operations **fail closed** (HTTP 429/503) rather than proceed on unverified state.
4. **Slow Cache Protection**: Timeouts and circuit breakers guarantee that a degraded/high-latency Redis instance does not silently turn security checks into permissive bypasses.

---

## 4. Multi-Tiered Token Revocation Architecture

The canonical token revocation pipeline is structured across three tiers:
```
[ Client Request ] ──> Tier 1: Process Memory Cache (Sub-millisecond)
                             │ Cache Miss / Expired
                             ▼
                       Tier 2: Redis 7 Shared Cache (Cluster-wide fast check)
                             │ Cache Miss / Redis Outage
                             ▼
                       Tier 3: PostgreSQL 16 Store (DURABLE TRUTH: RevokedTokens)
```

1. **Write Path**: Revocation writes **MUST durably commit to PostgreSQL first** before returning HTTP 200. Upon commit, invalidation is published to Redis 7 and process caches.
2. **Read Path**: Reads check Tier 1, then Tier 2, then Tier 3.
3. **Outage Behavior**: If Redis is offline, the pipeline queries PostgreSQL directly. Redis failure never assumes a token is valid without verifying PostgreSQL truth.

---

## 5. Deployment Safety & Distributed Locking Invariant

The Reviewer specifically verified that Redis does **NOT** displace existing Phase 0 release safety mechanisms:
- Redis distributed locks (Redlock or SETNX) are permitted **only for performance pre-filtering and worker coordination**.
- Redis locks **must never replace** PostgreSQL transaction advisory locks (`pg_advisory_xact_lock`), idempotency keys, optimistic concurrency CAS (`WHERE version = @expected_version`), and process/cgroup supervision for irreversible deployment or database actions.
- Determining current deployment state must remain fully functional if Redis is down.

---

## 6. Target Production Security & Configuration Requirements

[`REDIS_ARCHITECTURE_AMENDMENT.md:175-186`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md#L175-L186) codifies 8 target security standards for Phase 1 / Phase 2:
1. **Mandatory Authentication**: High-entropy password via `requirepass` or Redis ACLs; default credentials strictly prohibited.
2. **Network Isolation**: Port 6379 bound strictly to `127.0.0.1` or internal Docker overlay bridge; WAN exposure prohibited (MR-06).
3. **Least Privilege**: Dangerous commands (`FLUSHALL`, `FLUSHDB`, `CONFIG`, `KEYS`, `DEBUG`) disabled or restricted.
4. **Transport Encryption**: TLS required when crossing untrusted boundaries.
5. **Secret Rotation**: Integration with dynamic secret management (MR-02, MR-07).
6. **Resource Limits**: Explicit cgroup memory caps and Redis `maxmemory` eviction policies (`volatile-lru` / `allkeys-lru`) to prevent host OOM.
7. **Health Monitoring**: Connection drop alerts and latency profiling (MR-18).
8. **Warm-Restart Persistence**: RDB/AOF configured purely for operational restart convenience, recognized as non-authoritative.

---

## 7. Objective Gate-A Acceptance Test Scenarios

Phase 1 implementation must satisfy six objective, testable acceptance scenarios:
1. **Normal Operation**: Sub-millisecond latency on Redis cache hits; zero fallback pressure on PostgreSQL.
2. **Redis Unavailable**: Seamless fallback to PostgreSQL; zero authorization bypass; health monitor alerts.
3. **Redis Restart**: Automatic reconnection with exponential backoff; cache repopulates from PostgreSQL on demand.
4. **Stale Cached Security Data**: Multi-tier invalidation pipeline evicts stale entries within $\le 5$ seconds of PostgreSQL revocation commit.
5. **Redis Data Loss**: Cache flush (`FLUSHALL`) causes zero loss of deployment state, user identities, or revocation records.
6. **Redis Latency / Degradation**: Injected 5000ms socket latency trips circuit breaker; requests fall back safely or fail closed.

---

## 8. AI Workforce Forward Compatibility Boundary

The architecture allocates Redis as the operational primitive for future AI Workforce capabilities (Phase 8 / Phase 9):
- Agent coordination, leader election, and worker presence.
- Transient agent state, blackboard messaging, and scratchpad memory.
- Pub/Sub broadcasting of system anomalies and build events.
- Tool-result and LLM response caching to reduce token spend.
- Agent token-bucket rate limiting.

### Mandatory Invariant
> **AI Workforce capabilities SHALL NOT be part of the Gate-A deterministic safety-critical path.**  
> Gate A certifies deterministic infrastructure deployment and security operations only. AI workforce capabilities remain non-critical extensions implemented in later phases.

---

## 9. Reviewer Domain Verdict

- **Redis Architectural Coherence**: **PASS** (First-class production component).
- **Durable Safety State Boundary**: **PASS** (PostgreSQL sole durable authority; Redis non-authoritative).
- **Failure Model & Degraded Fallback**: **PASS** (Safe fallback to PostgreSQL; fail-closed on unsafe coordination).
- **Deployment Safety Invariant**: **PASS** (PostgreSQL advisory locks, CAS, and epoch fencing preserved).
- **Target Security Requirements**: **PASS** (Authentication, network isolation, ACLs, resource caps).
- **Gate-A Testability**: **PASS** (6 objective test scenarios codified).
- **AI Workforce Boundary**: **PASS** (Explicitly excluded from Gate-A critical path).
