# Disaster Recovery, Backups & Rollback Runbook

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server d7e8df99cb2b099eb8b6290e524af4d01a6c4a4d; infra b84f9d5de8da991cb603d696b94f829f5361e64a. **Last verified:**2026-10-21. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-OPS-002`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Audit Date:** 2026-10-20  
> **Related Documents:** [OPERATOR_RUNBOOK.md](./OPERATOR_RUNBOOK.md), [PILOT_RELEASE_GATES.md](../08-quality/PILOT_RELEASE_GATES.md)


> **Customer-hosted scope (ARCH-SELFHOST-01):** Operational ownership here is the customer installation: its local API/CI, state, credentials, backups and workloads. TMK separately operates licensing and maintains distribution; no shared central orchestration or implicit support access is established. [Authoritative architecture](../../../../vps-infra-server/docs/v2/02-architecture/SELF_HOSTED_PLATFORM.md).

---

### Recovery operations: proven selection and explicit unknowns

These are constrained documentation templates, not executed recovery proof. Application/production release remains blocked. Source-controlled deployment artifacts cannot identify a qualified live image, database history, external runtime manifest or process-owned workspace; those are UNKNOWN until the operator supplies the evidence below.

**Image rollback:** infra root consumes DEVOPS_API_IMAGE; fallback is ghcr.io/tmk-computers/tmk-devops-api:latest. Set a qualified content-addressed reference; VERSION does not select this image. Read-only syntax check:

```bash
set -eu
: "${QUALIFIED_API_IMAGE:?Supply an independently qualified previous image@sha256 digest}"
if [[ ! "$QUALIFIED_API_IMAGE" =~ ^ghcr\.io/tmk-computers/tmk-devops-api@sha256:[0-9a-fA-F]{64}$ ]]; then
  echo 'Invalid approved API image reference' >&2
  exit 1
fi
printf 'Reviewed candidate image: %s\n' "$QUALIFIED_API_IMAGE"
# Mutating command intentionally not supplied until schema/backout compatibility,
# actual compose profiles, maintenance window and readiness criteria are reviewed.
```

The root compose can consume DEVOPS_API_IMAGE during a separately approved recreate. No fixed2–5second interruption or automatic readiness/rollback is proven. Selecting a syntactically valid digest is not proof the registry artifact exists or matches the DB schema.

**Restore:** infra backup uses pg_dump -U postgres devops_prod and writes plain SQL under /var/www/vps-infra/docker/volumes/db/postgres/backups/devops_prod_TIMESTAMP.sql. It does not create a gzip file or latest.sql pointer. Obtain the verified backup checksum, actual DB credentials, exclusive disposable target and compatibility checks before restore. The required psql invocation must include -v ON_ERROR_STOP=1; if a pipe is introduced it also needs pipefail. Never restore into active devops_prod. A different DB in shared_postgres is a logical target, not a separately disposable server. No rename/switchover is approved without active-connection and consumer analysis. This source-only package supplies no executable live restore command.

**CI stop:** route POST /api/ci/build/stop takes buildId with bearer role Admin/SuperAdmin/Developer/DevOps. Obtain actual reachable CI origin (root compose does not publish5051), authorized token and build ownership. Inspect stop response plus actual process/cancellation completion; HTTP acceptance alone is not proof a workspace is safe to remove.

**Cleanup:** actual build-runner chooses paths based on INFRA_BASE_DIR/VOLUMES_BASE_DIR/CI_CACHE_BASE_DIR and job configuration. There is no universal /var/vps-infra/workspaces root. With separately verified existing root/target, this is inspection only:

```bash
set -eu
: "${VERIFIED_WORKSPACE_ROOT:?Supply actual runner root}"
: "${VERIFIED_BUILD_DIRECTORY:?Supply owned stopped-build directory}"
root=$(realpath -e -- "$VERIFIED_WORKSPACE_ROOT")
target=$(realpath -e -- "$VERIFIED_BUILD_DIRECTORY")
if [[ "$root" == / || "$target" != "$root/"* || ! -d "$target" ]]; then
  echo 'Reject path outside verified root, root itself, or invalid directory' >&2
  exit 1
fi
printf 'Contained directory for separate review: %s\n' "$target"
# No rm command: string containment does not establish job ownership, absence
# of active processes, or immunity to symlink/path replacement races.
```

**Secret rotation:** changing .env does not change an existing container; restart never reinjects its environment. Root API maps JwtSettings__SecretKey from JWT_SECRET_KEY then DEVOPS_JWT_SECRET; CI maps JWT_SECRET from CI_JWT_SECRET then JWT_SECRET_KEY (then a default rejected by auth.js). Inspect overrides and issuer/role expectations before coordinating a JWT change. Editing bare host JWT_SECRET is not equivalent. Updating CI_JWT_SECRET independently can defeat the intended shared value.

Runtime HMAC has separate caller/runtime/callback precedence (see runtime contract). Root compose supplies no runtime service and no direct AgentRuntime shared-secret environment entry. The runtime's deployment project/service/container definition is UNKNOWN; do not invent vps-agent-runtime as a guaranteed live container, issue docker restart as rotation, or substitute API+CI recreation for runtime rotation. Obtain the actual deployment manifest, all consumers and secret source, then author an independently approved recreate/verification procedure. No universal atomic-rotation command is proven by this source. Do not log secret values or replace settings with sed placeholders.

## Historical workload boundary

The recorded OMR worker rollback/backup drills are dated and scoped staging observations. They do not prove general web zero downtime, live archive/runtime readiness, or a safe current database rollback. Preserve original evidence in docs/audits; no destructive drill was executed by this documentation remediation.
