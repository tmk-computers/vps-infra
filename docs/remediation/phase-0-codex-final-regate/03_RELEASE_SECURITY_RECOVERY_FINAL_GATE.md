# Release, security and recovery final gate

Decisions concern the Phase 0 contract. No deployment, failover, security penetration test or restore drill was executed.

## Release contract — PASS

[07_DEPLOYMENT_SAFETY_CONTRACT.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md) binds durable deployment identity/intent to side effects, idempotency and per-service concurrency. Verification precedes success; staging checks are followed by cutover and affirmative public serving verification. Known-good releases are retained.

Sections 4–6 now require physical termination of a prior worker before recovery mutations, database compare-and-swap and deployment generations. They explicitly route unknown or incompatible schema state to `RECOVERY_REQUIRED`. Merely expiring a heartbeat is not accepted as proof the old worker cannot mutate ingress.

Expand/contract retains elements required by every eligible rollback binary. N expands/dual-writes; N+1 retains the old column; N+2 can drop it only after N is retired. The phase implementation must enforce this invariant; the written generation example is not runtime proof.

The ten documentary failure scenarios in [02_RELEASE_AND_DATABASE_RECOVERY_RECONCILIATION.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/02_RELEASE_AND_DATABASE_RECOVERY_RECONCILIATION.md) were assessed against those canonical invariants:

| Scenario | Contractually safe response |
|---|---|
| Duplicate request | Resolve durable idempotency identity; do not repeat effects |
| Lock-holder death | Fence prior process before takeover and inspect persisted effects |
| Crash before mutation | Confirm no unsafe effects; retain healthy prior release |
| Crash after mutation | Determine schema/effect state; reconcile or require recovery |
| Staging verification failure | Clean failed stage only when prior release remains compatible |
| Cutover failure | Inspect actual ingress, restore compatible prior serving or require recovery |
| Post-cutover failure | Application rollback, then probe prior release |
| Incompatible/irreversible migration | Reject unsafe ordinary rollout; uncertainty/incompatibility cannot take generic rollback path |
| App failure after compatible migration | Revert application while retaining live schema/data |
| Writes after backup | Preserve those writes during app rollback; snapshot restore requires independent authorization |

[12_UPGRADE_CURRENT_STATE.md:125](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md:125) now restores the application image/configuration and verifies health; it explicitly prohibits automatic database restore. The roadmap's transactional application rollback does not reinstate the old destructive instruction. Disaster-recovery-specific restore references are not ordinary release rollback.

**APPLICATION ROLLBACK MUST NOT AUTOMATICALLY RESTORE THE DATABASE.** A separately authorized restore requires the operator's reason/selection, data-loss assessment, quiescing and safety capture. No automatic application-failure path is credited with restoring a database.

## Security and Redis — PASS

[08_SECURITY_BOUNDARIES.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md) distinguishes PlatformSuperAdmin from tenant-scoped TenantAdmin. Its token matrix specifies each service's issuer, audience, subject, tenant, scopes, lifetime and algorithm. Endpoint validation is service-specific; a valid signature alone is insufficient.

The Phase 1 acceptance matrix covers default/retired signing material, wrong issuer/audience, expiry/revocation, tenant mismatch, tenant-to-platform access and valid tokens lacking agent/AMS scopes. AMS, CI and Windows agent trust are distinct. Agent mTLS establishes peer trust; scoped request authorization remains independently required.

Revocation uses certified PostgreSQL durability with synchronized local caching and restart recovery. A cache cannot override durable revocation. Redis is **Optional / Not Gate-A Certified Dependency**. These are requirements for future implementation, not evidence that a RevokedTokens table or middleware already exists.

Break-glass access requires customer consent and ticket/purpose context, bounded elevation (maximum one hour), immutable command audit, expiry and completion revocation. It qualifies normal customer-access restrictions consistently.

## Path containment — PASS

[08_SECURITY_BOUNDARIES.md:86](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:86) binds every deployment write to the server-registered root for the authorized tenant/service/environment. Client-selected arbitrary physical roots are prohibited. Negative cases include sibling prefixes, external absolute paths, traversal, alternate drives, UNC and archive escapes.

Normalized lexical segments do not establish complete filesystem confinement. R4 R2-01's archive-entry validation, symlink/hardlink rejection, reparse checks and OS permissions/DACL verification correctly remain Phase 1/4 implementation acceptance under the invariant. No runtime sandbox certification is inferred.

## Backup/recovery — PASS, with evidence precision corrections

[09_BACKUP_RECOVERY_CONTRACT.md](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md) limits local archive listing to header/TOC evidence and requires real restore drills for recoverability. The wrapper must inspect required object counts; the list command alone does not assert those counts or read all payload blocks. The PostgreSQL manual describes listing archive contents, separately from restoring them: [PostgreSQL 16 pg_restore](https://www.postgresql.org/docs/16/app-pgrestore.html).

The contract provides authenticated envelope encryption, off-host key custody, derivation/wrapping metadata and complete recovery from a clean OS without the original host. Platform configuration, binaries/images, assets and database roles/grants form the recovery set. Supplementary §4 includes protected secrets under the recoverable key; certificate thumbprints alone would not restore private keys.

Phase 5 owns implementation and empirical failure tests: tamper, failed/null upload, key rotation/missing custody, retention floor, full host loss, inconsistent restore and measured RPO/RTO. Both OS recovery profiles must pass. The 24h/1h RPO and 30m RTO remain targets, not measurements.

Retained C2-04 covers remaining dossier overstatements: the reconciliation's truncated-dump row cannot promise that listing will detect a truncation after an intact TOC. Data corruption must be caught by actual restore/integrity checks. This does not reopen C1-02 because the canonical contract explicitly requires those drills and rejects full-data proof from listing.
