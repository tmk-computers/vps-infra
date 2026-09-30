# REDIS ARCHITECTURE AMENDMENT — FIRST-CLASS CACHING & DUAL-STORE GOVERNANCE

**Document ID**: `FINAL-CLOSURE-REDIS-AMENDMENT`  
**Phase**: Phase 0 — Final Closure Amendment  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: FORMALLY ADOPTED & FROZEN  
**Governing Architecture**: Dual-Store Tiered Infrastructure (Durable PostgreSQL 16 Authority + High-Performance Redis 7 Shared Acceleration)

---

## 1. Architectural Decision & Core Invariant

### 1.1 Architectural Designation Replacement
This amendment replaces the previous Phase 0 classification:
> `Redis = Optional / Not Gate-A Certified Dependency`

with the formal production architectural standard:
> **Redis 7 is a first-class component of the standard production architecture.**  
> Redis SHALL be included in the standard production platform deployment across all supported operating systems.

### 1.2 Non-Negotiable Durability Invariant
> **Redis SHALL NOT be the sole authoritative durable store for safety-critical platform state.**  
> PostgreSQL remains the sole durable source of truth for critical control-plane state.

Under no circumstances shall the platform treat data residing solely in Redis memory or Redis persistence as the authoritative, unassailable record for deployment safety, identity, authorization, or recovery governance.

---

## 2. Workload & Responsibility Allocation

### 2.1 Redis Responsibilities (Architectural Capability Allocation)
Redis 7 is allocated for high-throughput, low-latency, and ephemeral workloads. Redis SHOULD be used for:
- **Distributed Caching**: Shared caching of expensive query results, catalog metadata, and system configuration caches.
- **Rate Limiting & Throttling**: Sliding-window and token-bucket counters for API request rate limiting.
- **Short-Lived Coordination State**: Distributed execution leases, heartbeat registries, and process rendezvous.
- **Pub/Sub & Real-Time Event Fan-Out**: Real-time event streaming, status distribution, and WebSocket bridge fan-out.
- **Temporary Counters**: Ephemeral performance metrics, in-flight request counters, and non-financial operational stats.
- **Real-Time Status Distribution**: Low-latency publishing of deployment progress and container state to connected UI sessions.
- **Token & Revocation Caching**: Fast shared read-cache for active token validation and cryptographic revocation lookups (`Local Cache -> Redis -> PostgreSQL`).
- **Short-Lived Session State**: User interactive session state with automatic TTL expiration.
- **LLM Response Caching**: Semantic or hash-based caching of large language model completions.
- **AI Tool-Result Caching**: Deduplication and caching of deterministic tool execution outputs.
- **Future AI Workforce Coordination**: Transient agent state, blackboard messaging, and agent worker presence.

*(Note: This represents an architectural capability allocation across the remediation lifecycle. It does not prematurely mandate that every listed capability be implemented in Gate A).*

### 2.2 PostgreSQL Responsibilities (Durable Source of Truth)
PostgreSQL 16 remains the sole authoritative, durable system of record for all safety-critical and business-critical state, including:
- **Deployment State**: Target state, actual state, step transitions, and execution status records.
- **Release History**: Immutable release manifests, container image digests, semantic tags, and rollback ledgers.
- **Tenant Configuration**: Organization schemas, tenant isolation boundaries, resource quotas, and environment overrides.
- **Users & Authorization State**: User credentials, role assignments, permissions, and tenant memberships.
- **Durable Credential & Token Revocation Truth**: Authoritative revocation ledgers (`RevokedTokens` table with `jti`, subject, expiration, and revocation timestamp).
- **Audit History**: Cryptographically verifiable and append-only audit trail logs.
- **Recovery Metadata**: Backup manifests, snapshot metadata, integrity checksums, and DR verification logs.
- **Licensing & Feature Entitlements**: Commercial license keys, node limits, and feature toggles.
- **Critical Configuration**: Cryptographic secrets, platform host bindings, and database connection profiles.
- **Durable Workflow State**: Long-running workflow steps and state machines where state loss is unacceptable.
- **Financial & Usage Records**: Billing records, metering logs, and financially relevant transaction history.

Redis may cache or accelerate these states but **SHALL NOT** become their only authoritative copy.

---

## 3. Redis Failure & Degraded Operation Model

The platform must maintain fail-safe operational integrity under all Redis degradation or failure modes.

### 3.1 Unavailability Invariant
The complete unavailability or crash of Redis **MUST NOT** by itself cause loss of:
1. Deployment truth;
2. Authorization truth;
3. Credential and token revocation truth;
4. Audit history;
5. Backup and recovery metadata;
6. Release history.

### 3.2 Degraded Fallback Behavior
- **Safe Fallback to Durable Store**: Where safe fallback is possible (e.g., token revocation checks, authorization lookups, deployment state queries), the platform **SHALL fall back immediately to PostgreSQL**. Performance may degrade (higher latency, reduced throughput), but safety and correctness remain uncompromised.
- **Fail-Safe Operation**: Where safe fallback is not possible (e.g., rate-limiting failure where allowing unmetered traffic would risk cascading host failure, or distributed lock acquisition where concurrent modification cannot be prevented), the affected operation **SHALL fail safely (fail-closed)** rather than proceed using stale, unverified, or uncoordinated state.

---

## 4. Multi-Tiered Revocation Architecture

To achieve sub-millisecond authentication verification without sacrificing durable security truth, the platform adopts a canonical three-tier revocation architecture:

```
[ Incoming Request ]
         │
         ▼
┌───────────────────────────────┐
│  Tier 1: Process-Local Cache   │  (Lowest latency; synchronized bounded memory cache)
└───────────────┬───────────────┘
         │ Cache Miss / Expired
         ▼
┌───────────────────────────────┐
│  Tier 2: Redis 7 Shared Cache │  (High throughput; cluster-wide distributed cache)
└───────────────┬───────────────┘
         │ Cache Miss / Redis Outage
         ▼
┌───────────────────────────────┐
│  Tier 3: PostgreSQL 16 Store  │  (DURABLE AUTHORITY: RevokedTokens relational table)
└───────────────────────────────┘
```

### 4.1 Write Path (Revocation Ingress)
1. Revocation requests (e.g., user logout, token revocation, session invalidation) **MUST be written and committed durably to the PostgreSQL `RevokedTokens` table first**.
2. A revocation write is **NOT considered successful** until PostgreSQL acknowledges durable transaction commit.
3. Upon successful PostgreSQL commit, the revocation is published to Redis 7 (via key write and/or Redis Pub/Sub invalidation).
4. Process-local caches invalidate or update their local entries upon receiving Redis notification or polling sync.

### 4.2 Read Path (Token Validation) & Canonical Revocation Effective Point
1. **Revocation Effective Point**: A credential/token revocation becomes security-effective at the exact instant the authoritative PostgreSQL revocation transaction commits.
2. **Post-Revocation Request Semantics**: For any authorization decision initiated after the PostgreSQL revocation commit, **stale cache state MUST NOT authorize the revoked credential**. The request MUST receive an immediate **`DENY` (HTTP 401 Unauthorized)**.
3. **No Authorization Grace Period**: The request MUST NOT succeed merely because:
   - Local process cache is stale;
   - Redis cache is stale;
   - Invalidation Pub/Sub delivery is delayed, lost, or pending;
   - Another process or worker instance has not yet observed the revocation event.
4. **Validation Progression**:
   - Token validation evaluates `jti` (JWT ID) against Tier 1 (local cache) and Tier 2 (Redis 7).
   - If positive cached authorization state is held but its freshness relative to authoritative revocation cannot be guaranteed, or if cache misses occur, the pipeline evaluates Tier 3 (PostgreSQL `RevokedTokens`).
   - **Resilience & Safe Fallback**: If Redis is offline, partitioned, or returns an error, the validation pipeline bypasses Tier 2 and queries Tier 3 directly. If PostgreSQL authoritative validation is required but unreachable, the platform **fails closed (DENY)**. Under no circumstances does an uncertain cache result in permissive authorization (`uncertain cache -> fail closed`).
5. **Race Semantics**:
   - Authorization decisions completed *before* the PostgreSQL revocation transaction commits were evaluated under the pre-revocation state.
   - Authorization decisions initiated *after* the authoritative revocation commit MUST observe revocation semantics and deny the credential.
   - For concurrent evaluations crossing the commit boundary, the implementation must provide a deterministic, fail-safe ordering mechanism consistent with this invariant.

### 4.3 Operational Convergence SLO vs. Authorization Grace Period
In Phase 1 (MR-36 implementation), the team must define:
- Cache entry TTLs bounded by token maximum lifetime (`exp`);
- Invalidation pub/sub channel naming conventions;
- **Operational Convergence SLO ($\le 5$ seconds)**: The operational timeline within which distributed caches must synchronize and evict stale entries across all cluster nodes.
- **Strict Invariant**: **Cache convergence is an operational SLO only, NEVER an authorization grace period.** It does NOT permit revoked tokens to remain valid for up to 5 seconds, and does NOT allow any authorization engine to accept stale cached validity after the durable revocation effective point.

---

## 5. Deployment Truth & Distributed Locking

### 5.1 Deployment State Machine Truth
The state machine governing deployments (Target State, Actual State, Step Transitions, Rollback Triggers) resides exclusively in PostgreSQL. Loss of Redis must not make the platform unable to determine the current deployment state.

### 5.2 Distributed Locks & Fencing
- Redis distributed locks (e.g., via Redlock or single-instance Redis SETNX leases) may be used for **performance pre-filtering and coordination** (e.g., preventing concurrent redundant worker tasks or throttling duplicate webhook dispatches).
- **Prohibition**: A Redis lock alone **SHALL NEVER be treated as sufficient protection** for irreversible deployment or database mutations.
- **Preserved Fencing**: The platform **MUST preserve durable fencing, versioning, and epoch mechanisms** defined by the Release Safety Contract:
  - Single-host deployment mutex via PostgreSQL transaction-level advisory locks (`pg_advisory_xact_lock`);
  - Release execution idempotency keys stored in PostgreSQL;
  - State machine version checks (`WHERE version = @expected_version`) for optimistic concurrency;
  - Physical process supervision and container cgroup fencing.
- Redis coordination complements these mechanisms; it **must not replace them**.

---

## 6. Gate-A Redis Acceptance Testing Scenarios

Because Redis 7 is now a first-class production component, Phase 1 implementation must satisfy six rigorous Gate-A acceptance test scenarios:

| # | Scenario | Injected Condition | Expected Behavior |
|:---:|---|---|---|
| **1** | **Normal Operation** | Redis 7 healthy, authenticated, responsive (warm-cache workload). | All active token validations, rate limits, and coordination states hit Redis cache; sub-millisecond latency; zero fallback pressure on PostgreSQL for cached items. |
| **2** | **Redis Unavailable** | Redis service stopped, network partition, or crashed. | Platform falls back to PostgreSQL for security checks and deployment queries; operations fail safe; zero authorization bypass; platform health monitors signal degraded cache status. If PostgreSQL is also unavailable, security decisions fail closed. |
| **3** | **Redis Restart** | Redis daemon restarted with clean memory or AOF replay. | Platform reconnects automatically with exponential backoff; cache repopulates from PostgreSQL on demand; coordination locks re-synchronize without deadlock. |
| **4** | **Stale Cached Security Data** | Populated local and Redis caches with valid token state, followed by PostgreSQL revocation commit with delayed/blocked invalidation propagation. | **10-Step Deterministic Acceptance Test**:<br>1. Issue valid token.<br>2. Populate local and Redis caches with previously valid state.<br>3. Commit token revocation in PostgreSQL (Revocation Effective Point established).<br>4. Prevent/delay cache invalidation propagation across network/pub-sub.<br>5. Send another request using the revoked token.<br>6. Verify request is rejected (**HTTP 401 DENY**).<br>7. Verify no stale local or Redis entry causes authorization success.<br>8. Restore cache propagation.<br>9. Verify caches converge to revoked state within operational SLO ($\le 5\text{s}$).<br>10. Verify audit/telemetry records the expected security behavior.<br>**Acceptance Criterion: Exactly ZERO successful post-revocation authorizations caused by stale cache state.** |
| **5** | **Redis Data Loss** | Redis cache completely flushed (`FLUSHALL`) or unpersisted restart. | Zero loss of deployment state, user identities, release history, or durable revocation records. Platform reconstructs active cache from PostgreSQL on read. |
| **6** | **Redis Latency / Degradation** | 5000ms latency injected on Redis socket; queue saturation; partition. | Timeouts fire cleanly; circuit breaker opens; requests fall back safely to PostgreSQL or fail closed; slow or partitioned cache NEVER turns safety checks into permissive bypass. |

---

## 7. AI Workforce Forward Compatibility

Redis 7 is explicitly designated as the core operational infrastructure primitive for future **AI Workforce / Autonomous SRE Agent** capabilities planned in Phase 8 and Phase 9:
- **Agent Coordination & Presence**: Distributed agent worker registration, heartbeat leases, and leader election.
- **Transient Agent State & Blackboards**: Short-lived inter-agent context sharing, plan formulation, and scratchpad memory.
- **Event Distribution**: Pub/Sub broadcasting of system anomalies, build events, and telemetry spikes to agent listeners.
- **Tool-Result & LLM Response Caching**: Semantic hashing and caching of LLM inferences and external tool invocations to minimize token consumption and latency.
- **Agent Rate Limiting**: Token-bucket throttling of LLM API calls and execution tool invocations.

### Architectural Boundary
**AI capabilities SHALL NOT be part of the Gate-A critical path.**  
Gate A certifies deterministic, safety-critical deployment and security operations only. AI workforce capabilities remain non-critical extensions implemented in later phases.

---

## 8. Target Production Security & Configuration Requirements

Redis 7 production deployments must satisfy the following target security standards (implemented across Phase 1 and Phase 2):
1. **Mandatory Authentication**: Strong, high-entropy password configured via `requirepass` or Redis 6+ ACLs. Default passwords (e.g., empty or placeholder secrets) are strictly prohibited.
2. **Network Isolation**: Redis ports (6379) bound strictly to `127.0.0.1` or internal Docker overlay bridge (`traefik_net` / `shared_redis`). Redis must never be exposed to public WAN interfaces (MR-06).
3. **Least Privilege**: Restrict dangerous commands (`FLUSHALL`, `FLUSHDB`, `CONFIG`, `KEYS`, `DEBUG`) via Redis ACLs or command renaming.
4. **Transport Encryption**: Encrypted transport (TLS/SSL) required whenever Redis traffic crosses untrusted network boundaries or connects to remote endpoints.
5. **Secret Rotation**: Integration with platform dynamic secret management (MR-02, MR-07) allowing zero-downtime Redis credential rotation.
6. **Resource Limits & Eviction**: Explicit cgroup memory caps and Redis `maxmemory` configuration with appropriate eviction policy (e.g., `volatile-lru` or `allkeys-lru`) to prevent OOM termination of the host.
7. **Monitoring & Health Probes**: Active health monitoring, memory usage tracking, latency profiling, and automated alerts for connection drops (MR-18).
8. **Persistence Configuration**: Persistence (RDB snapshots or AOF) configured strictly for operational convenience and warm restarts, with explicit recognition that persistence is non-authoritative.

---

## 9. Master Remediation (MR) Traceability Mapping

To maintain governance integrity without inflating the remediation scope, Redis architectural requirements are mapped strictly to existing MR items. The total MR count remains **37**:

| MR Item | Remediated Scope | Redis Architectural Role & Responsibility |
|---|---|---|
| **MR-02 / MR-07** | Secret Storage & Dynamic Setup Secrets | Redis authentication credentials managed dynamically with high entropy; zero plaintext or default credentials. |
| **MR-05 / MR-06** | Least Privilege & Network Exposure | Private loopback / overlay network binding; ACL command restrictions; elimination of WAN exposure. |
| **MR-10 / MR-11 / MR-12** | Deployment Engine & Safe Rollback | Redis non-authoritative notification fan-out and status streaming; PostgreSQL retains sole advisory locking and epoch fencing. |
| **MR-16** | System Resource Limits | Cgroup memory limits, CPU quotas, and Redis `maxmemory` eviction policies. |
| **MR-18** | Outbound Alerting & Telemetry | Redis health checks, disconnection alerts, connection pool telemetry, and latency threshold alerts. |
| **MR-20** | Multi-Engine Qualification & Feature Gates | Gate A platform runtime standardizes on PostgreSQL 16 (durable store) + Redis 7 (caching/acceleration). |
| **MR-36** | Token Trust Contract & Inter-Service Auth | Multi-tiered revocation pipeline (`Local Cache -> Redis 7 -> PostgreSQL`) with fail-safe PostgreSQL fallback. |

---

## 10. Compromised Provisioning Credential Disposition

During the Phase 0 final closure audit, an administrative helper script was identified:
- **Path**: `vps-infra/db/postgres/create-readonly-analyst.sh`
- **Defect**: Contained a hardcoded plaintext fallback credential on line 11.

### Policy & Mandate (Section 14 Governance)
1. **Non-Reproduction**: Per security governance standards, the literal credential string is **NOT reproduced** in this or any subsequent remediation documentation.
2. **Compromised Status**: The exposed credential is officially classified as **compromised**.
3. **Mandatory Rotation & Revocation**: The credential MUST be rotated and revoked in any existing environment where the script was executed. This rotation will be evidenced upon actual execution in Phase 1 (not silently assumed in Phase 0).
4. **Elimination of Fallbacks**: Future provisioning MUST strictly require dynamically supplied or generated credentials; no default or fallback production credential is permitted.
5. **Traceability**: Ownership of structural remediation is assigned to **MR-02** and **MR-05** in Phase 1.
