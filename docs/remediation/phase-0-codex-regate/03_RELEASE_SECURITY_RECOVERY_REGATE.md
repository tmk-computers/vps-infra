# Release, security and recovery re-gate

Audit date: 2026-09-30. **Release FAIL; Security FAIL; Backup/Recovery FAIL.** Static contract review only.

## Release safety: credited corrections

The authoritative lifecycle is now PENDING → PRECHECK → PREPARED → APPLYING → VERIFYING → CUTOVER → POST_CUTOVER_VERIFY → SUCCEEDED. Intent persistence, request idempotency, per-service ownership, immutable artifact/config identity, standby retention, public serving verification and explicit RECOVERY_REQUIRED are specified. Both adapters share this lifecycle.

Atomic or logically indivisible target switching is an adequate architecture invariant. Linux and Windows may implement it differently. Affirmative evidence that the intended release satisfies its declared health/readiness contract is the success invariant; HTTP 200, 30 seconds and 5xx <1% may be defaults implemented/configured in Phase 2. Their exact values do not cause this FAIL.

## C0-01: remaining contradictions and walkthrough

| Scenario | Current contract result | Re-gate |
|---|---|---|
| Duplicate active/terminal request | Unique tenant/service/idempotency tuple; conflict/status or cached terminal result | Core deduplication intent passes. |
| Ordinary compatible deployment | Stage, verify, switch, verify public serving, then succeed | Correct ordering passes. |
| Cutover failure | Restore prior routing; verify preceding release; use recovery state if impossible | Core compensation intent passes. |
| Paused worker loses ownership after recording intent but before ingress mutation | Database updates check Version; no rule makes the already-authorized physical mutation impossible after takeover | Incomplete: DB CAS is not itself ingress/IIS/process fencing. |
| Crash after authorized incompatible migration, before cutover | Authoritative §4 says prune staging and mark FAILED; supplement §6.3 requires RECOVERY_REQUIRED if post-migration deployment fails | Contradictory unless durable schema compatibility/effect reconciliation controls the branch. |
| Release N dual-writes old/new columns; N+1 drops old column; N+1 app fails | Authoritative §5.2 permits dropping the column still used by rollback binary N | Unsafe rollback compatibility promise. |
| Platform upgrade fails after writes since snapshot | Upgrade specification §4 automatically restores pre-upgrade DB | Direct violation of explicit data-loss authorization rule. |
| Destructive migration fails partway | Supplement assumes transaction rollback and no loss for every destructive migration | Must require proven transactional outcome or recovery-required branch, rather than blanket safe outcome. |

The direct evidence is [12_UPGRADE_CURRENT_STATE.md:125](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md:125), [07_DEPLOYMENT_SAFETY_CONTRACT.md:162](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md:162), and [02_RELEASE_CONTRACT_CORRECTION.md:174](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/02_RELEASE_CONTRACT_CORRECTION.md:174). The last specifies optimistic concurrency on database writes; the scenario above is a documentary counterexample, not a reproduced deployment race.

Required correction: make the no-automatic-destructive-restore rule apply to platform upgrades too; specify effect ownership and state-specific reconciliation; allow rollback only to binaries compatible with the actual schema. If old-worker exclusion or schema outcome is unproven, fence/halt and require recovery. This does not mandate distributed infrastructure or a particular lock implementation.

## Security: credited corrections and remaining C1-01

Distinct PlatformSuperAdmin and TenantAdmin roles, tenant binding, algorithm allowlisting, issuer/audience fields, expiry, revocation, service identities and default-key failure are now specified. A signed JWT alone is explicitly insufficient. Negative tenant A/B and tenant-admin/platform-operation cases are present.

However, the supplementary security matrix has auth, CI and manager issuers while its §3.2 requires every API to accept only the auth issuer. The baseline must define accepted issuers per credential/service, not reject its own service tokens. The negative suites do not preserve every original case: wrong issuer, historical/default signing material after rotation, and valid-but-wrongly-scoped AMS/agent credentials need explicit ownership and outcomes. Unauthenticated or missing-token rejection does not test these authorization paths.

The supplementary MR table also misassigns public network isolation to MR-03, rate limiting to MR-05, CORS to MR-06 and DB exposure to MR-28. Authoritative Phase 1 scope largely retains the real MR owners; reconcile rather than redesign the register.

### RG-C1-01: Redis

[08_SECURITY_BOUNDARIES.md:110](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:110) explicitly requires a Redis denylist, while database matrix §2–3 excludes Redis and R3 security §3.2 says not to introduce it.

R3 identifies this conflict but its recommendation is not incorporated. Define revocation independently of Redis and qualify behavior under the Gate-A profile.

### Privileged exceptional access and agent authentication

Break-glass governance remains a C2 precision correction (RG-C2-02). The ordinary zero-data-access statement and customer-consented execution exception need one governed policy; this audit does not claim a new implemented tenant bypass.

mTLS provides transport/peer identity; a scoped token authorizes the request. R3 states this distinction correctly. Phase 1 should establish the reusable trust contract and minimal legacy containment; the compiled TMK.Agent.Windows and full transport/token integration remain Phase 4. No substantial legacy daemon productionization is required.

## Backup/recovery: credited corrections

The seven stages now include capture, format check, client-side encryption, transfer, remote integrity, authenticated recovery-point catalog and retention. The contract includes off-host recovery custody, protects last-known-good points and separates destructive restore from application rollback. Google Drive/provider-neutral storage remains valid; S3 is not a condition.

RPO 24h scheduled / 1h pre-deploy and RTO 30 minutes for the stated restore profile are **targets for later measurement**, not certified guarantees.

## C1-02: verification and complete host-loss recovery

The corrected command is appropriate for listing a custom archive, but the text still attributes payload/compression validation to it. PostgreSQL documents --list as a TOC listing operation; it is not a successful database restore or proof every data block is usable. Correct the Stage 2 claim and require real later restore drills with exit status and data/integrity checks. [PostgreSQL 16 pg_restore documentation](https://www.postgresql.org/docs/16/app-pgrestore.html).

The BIP-39 choice itself is not a blocker or original requirement. Off-host recoverable key custody is the invariant. The proposed Argon2id derivation includes Salt, while the documented clean-host inputs are storage credentials and the phrase; the contract must say where the recoverable derivation/wrapping metadata lives and how recovery starts without the destroyed host. Do not claim cryptographic impossibility or demand a particular KDF: establish a complete, tested procedure.

The recovery-set inventory also needs usable protected secrets, roles/grants and immutable artifact dependencies. Hashes of secret envelopes and Docker tags are identifiers, not by themselves a complete restoration dependency set. Define the Windows artifact/config/identity counterpart as well as the Linux set.

### Required Phase 5 acceptance matrix (specification to add, not tests run here)

| Case | Required observable outcome |
|---|---|
| Archive/ciphertext/manifest tamper | Detect corruption/authentication failure; do not select as a usable recovery point. |
| Null/failed upload and remote digest mismatch | Fail backup result, alert, retain previous usable points. |
| Key rotation and unavailable old key | Recover retained points using documented custody/version metadata; clearly fail when authorization/material is absent. |
| Source host destroyed | Recover on clean Linux and Windows-profile infrastructure using only the documented off-host kit and dependencies. |
| Retention pressure/partial backup | Never delete the protected last usable complete recovery set. |
| Restore failure or inconsistent data | Fail drill; preserve evidence; do not count a listed TOC/table count alone as success. |
| RPO/RTO targets | Measure backup age and the defined recovery interval for the stated data/hardware profile; record pass/fail against targets. |

These are the original C1-02 acceptance categories. Later Phase 11 failure injection remains mandatory. No runtime drill was executed during this re-gate.
