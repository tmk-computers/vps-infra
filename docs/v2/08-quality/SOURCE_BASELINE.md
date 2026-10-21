# Infrastructure Source Baseline & Verification Record

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server d7e8df99cb2b099eb8b6290e524af4d01a6c4a4d; infra b84f9d5de8da991cb603d696b94f829f5361e64a. **Last verified:**2026-10-21. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-QUAL-001`  
> **Repository:** `vps-infra`  
> **Audit Date:** 2026-10-20  
> **Auditor:** DevOps Architect & Documentation Quality Engineer  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Related Documents:** [PILOT_RELEASE_GATES.md](./PILOT_RELEASE_GATES.md), [KNOWN_ISSUES.md](./KNOWN_ISSUES.md)


---

## Current merged source and documentation baselines

| Repository | Merged main inspected2026-10-21 | Source facts |
|---|---|---|
| vps-infra-server | d7e8df99cb2b099eb8b6290e524af4d01a6c4a4d | R7-reviewed workflow correction; platform application source, not central hosting. |
| vps-infra | b84f9d5de8da991cb603d696b94f829f5361e64a | Merge preserves cfb01ab81001da6fafafa40e29f00a3b57ed6383 upgrade forced-tag fetching plus765c5b71acd111ce85badc3fad5adb1edec5da38 reviewed docs. |

Current correction branch: docs/self-hosted-architecture-correction, documentation only. Final commit SHA is reported from Git after commit; it cannot embed itself. Independent R7 CONDITIONAL HOLD applies to server d7e8df9 / infra765c5b7, not a certification of the later main merge or this architecture correction.

Historical source/document parents c458c831711ba2e82a382719f76c98551d7d5a70 /44a5d6a32bf59f50e7c13b663dbd22bac31eb53d and infra7bac7f75de0f0f666d66fd4475a667957b68e898 remain prior audit inputs. cfb01ab is now included, not remote-main-only pending drift. Its --tags -f and guarded second fetch do not qualify network-failure, ignored-error, reset, image selection, VERSION or rollback consequences. No live upgrade or source change is performed here.

Image references, installed VERSION, source commits, schema history and release approval are separate facts. Root postgres:16-alpine does not prove pgvector; .NET Pgvector package version is not a deployed extension version. Refresh evidence on source/config/schema/image/deployment changes. Preserve original independent R1–R7 audits and external blocker states; no FULL PASS or production approval follows.
