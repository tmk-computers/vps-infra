# Infrastructure Implementation Roadmap

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server d7e8df99cb2b099eb8b6290e524af4d01a6c4a4d; infra b84f9d5de8da991cb603d696b94f829f5361e64a. **Last verified:**2026-10-21. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-ROAD-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Audit Date:** 2026-10-20  
> **Related Documents:** [INDEX.md](../INDEX.md), [PILOT_RELEASE_GATES.md](../08-quality/PILOT_RELEASE_GATES.md)


> **Customer-hosted scope (ARCH-SELFHOST-01):** Roadmap/ADR scope is the customer-hosted platform. The product owner has directed local operational Control Plane per installation and separate central licensing; runtime packaging, distributed deployment, Windows and release safety still require implementation/qualification decisions. [Authoritative architecture](../../../../vps-infra-server/docs/v2/02-architecture/SELF_HOSTED_PLATFORM.md).

---

## Independent release tracks

```mermaid
flowchart TD
    Safety["Required safety and owner decisions"] --> Linux["Linux: bounded CI/host release gate"]
    Safety --> Windows["Windows: proposed W0 to W15 qualification"]
    Safety --> AI["AI: independent Gate H repair and re-gate"]
    Future["Distributed clustering/swarm: proposed research"]
```

Historical phases are not renumbered. An AI swarm is not a prerequisite for separately scoped Linux or Windows work; each release still depends on the safety checks relevant to its actual stack. Current Linux OMR workload is HOLD, Windows W0 is proposed/re-gated2026-10-06 and the named Server2025 harness only preserves baseline. It provisions no VM or installer/rollback qualification. Source application GH01 is not made safe by an env switch.

Future clustering and autonomous swarms need separate owner ADR, networking/trust/recovery/capacity evidence, failure-injection and operational qualification. No phase is complete merely because a plan or preservation script exists.
