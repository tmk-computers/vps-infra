# Infrastructure Source Baseline & Verification Record

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server c458c831711ba2e82a382719f76c98551d7d5a70; infra44a5d6a32bf59f50e7c13b663dbd22bac31eb53d. **Last verified:**2026-10-20. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-QUAL-001`  
> **Repository:** `vps-infra`  
> **Audit Date:** 2026-10-20  
> **Auditor:** DevOps Architect & Documentation Quality Engineer  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Related Documents:** [PILOT_RELEASE_GATES.md](./PILOT_RELEASE_GATES.md), [KNOWN_ISSUES.md](./KNOWN_ISSUES.md)


---

## Reviewed source and ancestry

| Repository | Documentation implementation parent | Source ancestor | Remote main observed2026-10-20 |
|---|---|---|---|
| vps-infra-server | c458c831711ba2e82a382719f76c98551d7d5a70 | bdfb1223e274e4c39f5eed3573e46ebed819a930 | 339945429d2e1a348569c1d4400e0d7bfa2c51d3 |
| vps-infra | 44a5d6a32bf59f50e7c13b663dbd22bac31eb53d | 7bac7f75de0f0f666d66fd4475a667957b68e898 | cfb01ab81001da6fafafa40e29f00a3b57ed6383 |

Current local implementation branch is docs/v2-codex-complete-remediation. The final documentation commit SHA is obtained from git rev-parse HEAD after commit; it cannot truthfully appear in its own committed content. Parent above is not the application source ancestor. Earlier docs/R2/R3/R4 are historical inputs. This mission changes docs only; use git diff <parent> HEAD -- . :!docs to prove no implementation drift.

Infra7bac untracks VERSION, writes installed version through setup/successful upgrade and derives release tags. It is newer than original41fcb993e58d36df5951ee009a48609deb748e88; neither version file nor Git tag automatically pins images. Main-only cfb01ab changes upgrade tag fetch to --tags -f and adds another guarded fetch; existing reset --hard origin/main remains. Do not merge/rebase it here. A future integration candidate must requalify forced-tag/network-failure/ignored-error/reset consequences, tag fallback, image selection and VERSION writes on failed setup/upgrade.

Pgvector.EntityFrameworkCore0.3.0 is a NuGet integration package version, not a server extension version. Root postgres:16-alpine does not prove pgvector installation. Release metadata, documentation parent, installed VERSION and image digest are different facts. Refresh this record whenever source, DTO/routes/config, package graph, deploy manifests or remote main changes; old observed remote tips are not a permanent freshness guarantee.
