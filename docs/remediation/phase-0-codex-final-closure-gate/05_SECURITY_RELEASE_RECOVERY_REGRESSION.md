# Accepted-contract regression check

This is a targeted comparison with the previous accepted contracts, not a renewed product implementation audit.

## Release — PASS

Git comparison against the previous audited server HEAD `76b4bcb` shows no changes to canonical deployment safety document 07, backup document 09 or upgrade document 12. The architecture amendment adds an explicit prohibition on substituting Redis locks for durable PostgreSQL safety mechanisms.

Durable intent/idempotency, crash reconciliation, prior-worker termination, generation/version fencing, pre/post-cutover verification, eligible known-good releases and schema compatibility remain required. Application rollback must not automatically restore the database. Destructive data recovery still requires independent authorization, quiescing and safety capture. Documentary walkthroughs remain specifications, not executed failure tests.

## Security — FAIL only for amended revocation semantics

PlatformSuperAdmin/TenantAdmin separation, service-specific issuer/audience/subject/tenant/scope/key checks, fifteen negative security tests, CI/AMS/agent trust separation and consent/ticket-bound break-glass remain intact.

The new cache consistency ambiguity is recorded as CG-C1-01 in report 04. It affects the original immediate revocation requirement and is the only material regression found. Existing source fallback credentials remain future Phase 1 remediation; their presence is not a new implementation-phase blocker.

## Path containment — PASS

[08_SECURITY_BOUNDARIES.md:86](D:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md:86) continues to require the server-registered root for the authorized tenant/service/environment. Segment boundaries, sibling-prefix/UNC/cross-drive/traversal negatives and archive/link/reparse/DACL acceptance remain assigned to Phase 1/4. Lexical normalization is not credited as complete filesystem isolation.

## Backup/recovery — PASS

Canonical 09 remains unchanged: listing establishes limited header/TOC evidence, real restore drills prove recoverability, authenticated encryption and off-host derivation/key metadata support clean-host recovery, and retention protects usable points. Database restore remains separate from application rollback.

The targets remain 24h scheduled/1h pre-deploy RPO and 30-minute RTO for the defined profile; no timing has been measured by this gate. Reviewer master-report references to a four-hour RTO or a mandatory WAL-archive design do not replace the canonical contract.

R3-01 periodic synthetic drills are appropriate Phase 5 advice. Correct ownership is backup/recovery MR-14/MR-15, not the Windows MR-24/MR-25 labels in the review register. No particular weekly cadence is necessary to close Phase 0.

## Windows — PASS

Windows Server 2022, IIS 10/HTTP.sys on 80/443, ANCM, compiled agent, explicitly delegated service identity, mTLS plus scoped requests, remote PostgreSQL VerifyFull and health/reboot-aware agent update acceptance remain. No Windows-host Traefik, Docker Desktop or WSL2 database dependency is introduced. Redis can be centralized/private.

## Traceability — PASS

Canonical F01/F02/F15/F16/F22/DEF-08/DEF-15 rows preserve the previously accepted substantive obligations. F02 concerns published signing defaults under MR-02/MR-36; F15 concerns approval drift/replay, reauthorization, crash reconciliation and clock-hour stability under MR-08. F16.5 stays MR-16; all five F16 criteria remain necessary before AI re-enable. False supplementary F02/F15 descriptions remain C2-04 rather than silently changing canonical ownership.

## Dual-OS — PASS

Phase 12A independently certifies Linux; 12B independently certifies Windows. Neither certifies the other. A Linux pilot can begin after Linux qualification while Windows remediation continues actively. Phase 15 remains unified Dual-OS Commercial Gate B.

## Overall regression decision

**FAIL**, solely because the Redis amendment leaves the revocation visibility acceptance rule ambiguous. All other reviewed domains retain the previously accepted contract. No runtime readiness or completion of OPEN MR items is inferred.
