# Host Security, Firewall & TLS Architecture

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server d7e8df99cb2b099eb8b6290e524af4d01a6c4a4d; infra b84f9d5de8da991cb603d696b94f829f5361e64a. **Last verified:**2026-10-21. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-SEC-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md), [OPERATOR_RUNBOOK.md](../06-operations/OPERATOR_RUNBOOK.md)


> **Customer-hosted scope (ARCH-SELFHOST-01):** Trust boundaries are vendor distribution/central licensing versus each customer-local operational installation. Separate local state does not repair intra-installation tenancy/authentication flaws or prove air-gapped operation. [Authoritative architecture](../../../../vps-infra-server/docs/v2/02-architecture/SELF_HOSTED_PLATFORM.md).

---

## Source-defined host security boundary

Traefik global entrypoints and external traefik_net are defined in platform/network/traefik/docker-compose.yml. Database/pgAdmin loopback bindings are overridable; review effective configuration. Root app services do not publish8080/5051 directly. Runtime deployment is separate, not a proven private host binding.

Source server ci-server/api/host-firewall-manager.js is the host UFW owner. DNS reachability is not firewall evidence; Docker-published ingress does not equal host INPUT policy. Cosign enforcement is application code in supply-chain.js with audit default and explicit enforce/bypass conditions, not Docker engine admission. See sibling server [CI security](../../../../vps-infra-server/docs/v2/04-modules/CI_SERVER_ENGINE.md).

OMR strict-origin certificate and off-host recovery blockers remain open. No Linux or Windows production qualification is issued. Hardening/least privilege are target policies pending environment-specific evidence, not guarantees established by this document.
