# 07 REGRESSION CHECK OF PREVIOUSLY ACCEPTED CONTRACTS & DUAL-OS REVIEW

**Document ID**: `FINAL-REVIEW-07-REGRESSION`  
**Phase**: Phase 0 — Final Independent Closure Review  
**Review Cycle**: Final Independent Closure Review  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Status**: Authoritative Regression Audit Complete  
**Date**: 2026-09-30  

---

## 1. Audit Mandate

The Reviewer performed a targeted regression audit to confirm that the Phase 0 final closure corrections and the Redis Architecture Amendment did **NOT regress** any previously accepted Phase 0 contracts:
1. Release Contract & Deployment State Machine
2. Security Boundaries & Token Trust Contract
3. Path Containment & Filesystem Sandboxing
4. Backup, Encryption & Disaster Recovery
5. Windows Server 2022 Native Hosting Architecture
6. Historical Traceability & Substantive Obligations
7. Dual-OS Non-Negotiable Mandate

---

## 2. Regression Spot-Check Across Accepted Contracts

### 2.1 Release Contract & Deployment Safety (C0-01) — REGRESSION CHECK: PASS
- **Database Restore Invariant Preserved**: The universal invariant:
  > **`APPLICATION ROLLBACK MUST NOT AUTOMATICALLY RESTORE THE DATABASE`**
  remains strictly enforced in [`07_DEPLOYMENT_SAFETY_CONTRACT.md:177`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/07_DEPLOYMENT_SAFETY_CONTRACT.md#L177) and [`12_UPGRADE_CURRENT_STATE.md:127`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/12_UPGRADE_CURRENT_STATE.md#L127).
- **10 Failure Walkthroughs Intact**: Scenarios 1–10 (duplicate request, lock-holder death, crash before mutation, crash after mutation, staging verification failure, cutover failure, post-cutover failure, incompatible migration, app failure after compatible migration, post-backup writes) remain completely verified, terminating in deterministic safe states (`FAILED`, `ROLLED_BACK`, or `RECOVERY_REQUIRED`).
- **Fencing & Epoch Tokens Preserved**: Redis distributed locks complement, but **do not replace**, PostgreSQL transaction-level advisory locks (`pg_advisory_xact_lock`), idempotency keys, and optimistic concurrency version CAS.

### 2.2 Security Boundaries & Token Trust Contract (C1-01) — REGRESSION CHECK: PASS
- **Token Trust Matrix**: Explicit parameters for all 5 token types (`Platform User`, `Tenant User`, `CI Runner`, `Windows Agent`, `AMS Inter-Service`) remain intact in [`08_SECURITY_BOUNDARIES.md:115-121`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md#L115-L121).
- **15 Negative Security Tests**: The complete negative test suite (SEC-NEG-01 to SEC-NEG-15) remains mandatory for Phase 1.
- **Break-Glass Access Protocol (RG-C2-02)**: The 4-point emergency governance protocol (ticket context, 1-hour time-bound, immutable cryptographic audit logging, immediate invalidation) remains active in [`08_SECURITY_BOUNDARIES.md:95-99`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md#L95-L99).

### 2.3 Path Containment & Filesystem Sandboxing (RG-C1-03) — REGRESSION CHECK: PASS
- **Normalized Segment-Boundary Containment**: Enforces trailing directory separator on normalized root, rejecting sibling-prefix attacks (`tenant-a` vs `tenant-ab`), cross-drive escapes, UNC paths, and null bytes ([`08_SECURITY_BOUNDARIES.md:86-88`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md#L86-L88)).
- **Defense-in-Depth Specification**: Reviewer finding R2-01 (combining lexical checks with archive Zip Slip sanitization and directory reparse point inspection) remains incorporated into downstream guidance.

### 2.4 Backup Verification, Cryptography & Disaster Recovery (C1-02) — REGRESSION CHECK: PASS
- **Verification Scope Limits**: `pg_restore --list` remains properly limited to header and TOC parseability; full data integrity remains reserved for automated DR restore drills ([`09_BACKUP_RECOVERY_CONTRACT.md:51`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md#L51)).
- **Envelope Encryption**: AES-256-GCM envelope encryption (DEK/KEK), Argon2id salt, KEK version, and IV bundled into self-sufficient offsite manifests remain active.
- **RPO / RTO Targets**: 24h/1h RPO and 30m RTO remain correctly classified as operational targets subject to Phase 5 validation.

### 2.5 Windows Server 2022 Architecture & Identity (C1-03, RG-C2-01) — REGRESSION CHECK: PASS
- **Native Hosting Topology**: Native IIS 10 + HTTP.sys (ports 80/443) + ASP.NET Core Module + compiled `TMK.Agent.Windows` remains frozen. Traefik on Windows, Docker Desktop, and WSL2 PostgreSQL remain completely excluded.
- **Dedicated Service Identity**: Bare `LocalService` remains replaced with dedicated least-privilege Windows service account (`NT SERVICE\TMKAgent`) with explicitly enumerated rights.
- **Peer-Authenticated TLS**: Strengthened from misleading `Require + Trust Server Certificate=false` to canonical `SSL Mode=VerifyFull` with validated CA and hostname verification.
- **Agent Authentication**: Mutual TLS on port 5055 paired with scoped bearer authorization.

### 2.6 Historical Traceability & Substantive Obligations (C1-04) — REGRESSION CHECK: PASS
- **MR-16 Mapping**: `F16.5` cleanly mapped to `MR-16` (Resource Admission & Limits); zero stale references to MR-17.
- **Substantive Obligations**: F01, F02, F15, F16, F22, DEF-08, and DEF-15 obligations remain preserved.
- **Master Register Integrity**: Exactly 37 MR items with exact status distribution (`33 OPEN` + `3 PARTIAL` + `1 IMPL_NOT_VERIFIED` = `37`).

---

## 3. Dual-OS Architecture & Roadmap Gates Audit

The Reviewer specifically audited the Dual-OS Non-Negotiable Mandate following the Redis Architecture Amendment:

1. **Equal First-Class Tracks**: Linux (Ubuntu 24.04 LTS) and Windows Server (Windows Server 2022) remain parallel, equal first-class target operating systems. Windows remediation is actively scheduled across Phase 4, Phase 10, Phase 11, and Phase 12B.
2. **Redis Non-Authoritative for OS-Specific State**: The Redis amendment does not alter or weaken OS-specific deployment state machines. Windows IIS AppPool configurations, virtual directories, and Windows Agent state machines continue to reside durably in PostgreSQL and local host SCM. Redis is used solely for caching and transient event fan-out across both operating systems.
3. **Independent Gate A Certifications**:
   - **Phase 12A**: Independent Linux Gate A Certification.
   - **Phase 12B**: Independent Windows Gate A Certification.
4. **Staggered Pilot Guardrails**:
   - If Linux Gate A passes first, an operational pilot for Linux may commence under Phase 13A.
   - **Mandatory Guardrail**: Commencing a Linux pilot under Phase 13A **does not pause, cancel, or defer** Windows remediation. Windows tracks proceed actively within the same program.
5. **Unified Commercial Gate**:
   - **Phase 15**: Dual-OS Commercial Enterprise Gate B. Commercial release requires full dual-OS certification across both Ubuntu 24.04 LTS and Windows Server 2022.

---

## 4. Reviewer Domain Verdict

- **Release Contract**: **PASS** (Zero regression; no-auto-DB-restore invariant preserved).
- **Security Boundaries**: **PASS** (Token Trust Matrix and 15 negative tests preserved).
- **Path Containment**: **PASS** (Normalized segment-boundary checks preserved).
- **Backup & Recovery**: **PASS** (TOC limits, envelope encryption, and targets preserved).
- **Windows Architecture**: **PASS** (Native IIS 10, dedicated identity, VerifyFull TLS preserved).
- **Traceability**: **PASS** (37 MR set, F16.5 to MR-16, substantive obligations preserved).
- **Dual-OS Mandate**: **PASS** (Equal tracks, independent Gate A, unified Phase 15 Gate B preserved).
