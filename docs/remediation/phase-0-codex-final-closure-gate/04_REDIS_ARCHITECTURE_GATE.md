# Redis architecture gate

Redis 7 is an intentional first-class standard production component. The earlier optional/excluded classification is not an acceptance requirement in this gate.

## Durable-state boundary — PASS

[06_DATABASE_SUPPORT_MATRIX.md:54](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md:54) and the amendment §2.2 preserve PostgreSQL as sole durable authority for deployment state, releases, users/authorization, credential revocation, audit history, recovery metadata, critical configuration, durable workflows and financial records. Redis persistence remains warm-restart convenience, not an authoritative recovery source.

Redis allocations include caches, throttling, ephemeral coordination, Pub/Sub, temporary non-financial counters, real-time status, revocation caching and short-lived session state. Future LLM/tool-result caching and AI Workforce coordination are capability allocations, not mandatory Gate-A implementations.

## Deployment safety — PASS

Canonical architecture §2 and amendment §5 preserve PostgreSQL deployment truth, durable intent/idempotency, optimistic versions, advisory locking and physical/generation fencing. Redis leases can pre-filter or coordinate; they cannot authorize an irreversible mutation alone. Redis loss must not obscure deployment truth.

## Failure model and testability — FAIL for one security contract ambiguity

Five classes have objective, coherent requirements; the stale-security case lacks one consistent acceptance rule.

| Scenario | Assessment |
|---|---|
| Healthy Redis | Cache acceleration is specified. The “all hits / zero PostgreSQL fallback” performance row needs a warm-cache workload qualification; healthy cold/missing entries still require the documented read-through path. |
| Unavailable | Fall back to PostgreSQL where safe; otherwise fail closed. Preserve durable state and expose degraded health. |
| Restart | Reconnect/backoff, repopulate from PostgreSQL and reconcile coordination. |
| Stale security cache | **CG-C1-01:** immediate rejection and bounded delayed propagation are not reconciled into one externally testable rule. |
| Cache/data loss | Rebuild caches; no loss of durable deployment/auth/recovery truth. |
| Latency/degradation | Injected 5000ms latency must trigger bounded timeout/circuit breaking, then safe fallback or rejection. |

### CG-C1-01: revocation effective point versus negative-cache visibility

The active texts prescribe:

- [08_SECURITY_BOUNDARIES.md:118](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:118): immediate revocation on user suspension/security-stamp change.
- [08_SECURITY_BOUNDARIES.md:147](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:147): revoked credentials return HTTP 401.
- [06_DATABASE_SUPPORT_MATRIX.md:81](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md:81): stale cache entries must not permit revoked credentials.
- [REDIS_ARCHITECTURE_AMENDMENT.md:110](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md:110): PostgreSQL commit is required before successful revocation; Redis publication/invalidation follows.
- [REDIS_ARCHITECTURE_AMENDMENT.md:114](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md:114): tiered reads descend on cache miss, with PostgreSQL bypass of Redis on outage.
- [REDIS_ARCHITECTURE_AMENDMENT.md:124](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md:124): negative “not revoked” caching with revocation propagation bounded at five seconds.
- [REDIS_ARCHITECTURE_AMENDMENT.md:154](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md:154): stale cached approval after PostgreSQL revocation is rejected within a window of up to five seconds, while also saying invalidation is immediate.

**Documentary counterexample, not a live exploit test:**

1. Instance A holds a cache entry saying token T is not revoked.
2. Another instance commits T's revocation in PostgreSQL.
3. A's invalidation is delayed/lost; its negative entry remains within the amendment's permitted short TTL.
4. T is presented before the five-second bound. A cache-hit implementation can admit it under the described bounded-convergence model, while the canonical immediate/stale-cache requirements require denial.

Both PostgreSQL durability and eventual invalidation can succeed while authorization visibility is still stale. Persisting revocation first therefore does not by itself settle the acceptance outcome in step 4. Redis outage fallback on a miss/error also does not specify handling of an already-held local negative hit.

**Required specification correction:** Define the effective point for revocation and the relationship between PostgreSQL commit, API success, cached-negative freshness and enforcement on every instance. State expected responses during the interval, on missed Pub/Sub delivery, Redis partition/restart and unavailable authoritative validation. Cache synchronization latency must not silently be treated as a permission to bypass the intended revocation rule.

Either an explicit immediate-enforcement contract or an explicitly authorized bounded contract can be evaluated; this audit imposes no universal TTL. The two standards must not coexist as competing acceptance criteria. If immediate rejection remains canonical, stale negative cache hits must not satisfy authorization after the defined effective point. Phase 1 owns the implementation.

**Severity:** C1, because this is ambiguity in safety-critical authorization and its pass/fail oracle. It is not a complaint about Redis adoption or a request to implement caching now.

## Redis security specification — PASS

Amendment §8 specifies authenticated access, generated high-entropy credentials, private exposure, least-privilege ACL/dangerous-command restrictions, TLS across untrusted/remote boundaries, rotation, memory/cgroup/maxmemory limits, monitoring and non-authoritative RDB/AOF warm persistence. Existing MR-02/05/06/07/16/18/20/36 ownership assigns implementation and certification.

A controlled FLUSHALL failure test is a test-harness operation, not permission for production service identities to run dangerous commands. Runtime configuration was not certified here.

## AI Workforce and Windows boundaries — PASS

AI coordination, presence, transient state, event fan-out, LLM/tool caches and agent throttling remain outside the deterministic Gate-A critical path. Redis availability cannot bring AI into deployment authority.

Canonical database matrix allows an internal shared service or remote endpoint. Windows workloads can consume centralized/private Redis; neither native IIS topology nor the amendment requires a Redis daemon on every Windows IIS host. Independent Windows certification remains mandatory.

## Overall decision

**Redis architecture: FAIL**, limited to CG-C1-01. **Durable-state boundary, security specification and AI boundary: PASS.** Six test categories are present, but stale-revocation behavior must have one consistent acceptance outcome before the full failure/testability gate can pass.
