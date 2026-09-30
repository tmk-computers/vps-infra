# CG-C1-01 closure

**Result: RESOLVED.**

The previous Codex closure condition required one coherent revocation-effective point, explicit outcomes for post-commit requests, stale local/Redis entries, Pub/Sub loss/delay, uncertain cache freshness and authoritative-store outage, race semantics, and a single objectively testable Gate-A oracle.

The active canonical security text (`docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md`, lines 129–131) places effectiveness at successful PostgreSQL revocation commit. Any authorization decision initiated after commit must return DENY/401; stale local and Redis state and delayed Pub/Sub cannot authorize. If freshness is uncertain, the flow validates against PostgreSQL or fails closed if PostgreSQL is unavailable. The Redis amendment (`docs/remediation/phase-0-final-closure/REDIS_ARCHITECTURE_AMENDMENT.md`, §4.2–4.3) gives matching race semantics and states the <=5-second convergence value is operational only, with zero authorization grace.

Gate-A stale-cache acceptance is explicit: delayed invalidation may leave caches stale, but there must be zero successful post-revocation authorization. This is a specification/test oracle; it does not claim Phase 1 implementation or runtime execution.

Redis remains a first-class production cache/coordination component, while PostgreSQL remains the durable revocation authority. No direct architectural regression found.
