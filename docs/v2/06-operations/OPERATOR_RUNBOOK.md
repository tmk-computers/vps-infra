# Infrastructure Operator Runbook & Maintenance

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server c458c831711ba2e82a382719f76c98551d7d5a70; infra44a5d6a32bf59f50e7c13b663dbd22bac31eb53d. **Last verified:**2026-10-20. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-OPS-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md), [DISASTER_RECOVERY.md](./DISASTER_RECOVERY.md)


---

## Read-only diagnostics and provisioning boundary

Run from /var/www/vps-infra on a separately authorized target. ./infra help/status and docker ps/logs inspect source-defined container names. ./infra up/down/restart/backup and upgrade-client without --check mutate services/state; restart is full-stack and is not a settings-rotation mechanism. Profiles/network/environment/CI_SECRET must be supplied for real Compose invocation. Do not start the production-volume stack as a syntax test.

Root images can be overridden by full qualified digests; VERSION does not select them. Readiness is not proved by process existence. No universal rollback/downgrade safety follows from Compose success. Follow [recovery boundaries](./DISASTER_RECOVERY.md) and [CLI](../10-reference/CLI_REFERENCE.md).

Runtime is independently deployed: obtain actual project/service/host binding and secret sources. Do not invent its container name or execute restart after editing environment. No runtime cancel/abort API is implemented. Windows W0 remains proposed and no production launch is permitted by this guide.
