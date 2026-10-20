# Host Security, Firewall & TLS Architecture

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server c458c831711ba2e82a382719f76c98551d7d5a70; infra44a5d6a32bf59f50e7c13b663dbd22bac31eb53d. **Last verified:**2026-10-20. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-SEC-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md), [OPERATOR_RUNBOOK.md](../06-operations/OPERATOR_RUNBOOK.md)


---

## Source-defined host security boundary

Traefik global entrypoints and external traefik_net are defined in platform/network/traefik/docker-compose.yml. Database/pgAdmin loopback bindings are overridable; review effective configuration. Root app services do not publish8080/5051 directly. Runtime deployment is separate, not a proven private host binding.

Source server ci-server/api/host-firewall-manager.js is the host UFW owner. DNS reachability is not firewall evidence; Docker-published ingress does not equal host INPUT policy. Cosign enforcement is application code in supply-chain.js with audit default and explicit enforce/bypass conditions, not Docker engine admission. See sibling server [CI security](../../../../vps-infra-server/docs/v2/04-modules/CI_SERVER_ENGINE.md).

OMR strict-origin certificate and off-host recovery blockers remain open. No Linux or Windows production qualification is issued. Hardening/least privilege are target policies pending environment-specific evidence, not guarantees established by this document.
