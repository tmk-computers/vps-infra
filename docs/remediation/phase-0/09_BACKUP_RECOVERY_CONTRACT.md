# 09 BACKUP, DISASTER RECOVERY & RESTORATION CONTRACT

**Document ID**: `REMED-P0-09`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Status**: Authoritative Disaster Recovery Contract Frozen (Codex C1-02 Remediation Applied)  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C1-02`)  

---

## 1. Disaster Recovery Engineering Axiom

A backup does not exist simply because a dump utility was invoked. A backup exists ONLY when:
1. It is generated consistently without transaction corruption.
2. It is verified using format-aware engine validation (`pg_restore --list`).
3. It is encrypted client-side with AES-256-GCM using an escrowed key kit before leaving the host.
4. It is dispatched offsite beyond the failure domain of the source host.
5. Its remote integrity is proven via authenticated digest verification.
6. It is cataloged in an authenticated `RecoveryPoint` manifest.
7. It has been proven restorable to a clean, isolated host under total-source-host-loss simulation.

> [!CAUTION]
> **Prohibited Equivalence**:
> Backup Creation $\neq$ Client-Side Encryption $\neq$ Offsite Dispatch $\neq$ Remote Digest Verification $\neq$ Source-Host-Loss Restoration.
> These stages must be tracked, logged, and reported as distinct states.

---

## 2. Seven-Stage Backup Lifecycle Pipeline

```mermaid
graph TD
    S1["Stage 1: CAPTURE (pg_dump -Fc)"]
    S2["Stage 2: LOCAL VERIFY (pg_restore --list)"]
    S3["Stage 3: ENCRYPT (AES-256-GCM + DEK/KEK)"]
    S4["Stage 4: DISPATCH (TLS 1.3 Transfer)"]
    S5["Stage 5: REMOTE VERIFY (SHA-256 Digest Match)"]
    S6["Stage 6: CATALOG (RecoveryPoint Manifest)"]
    S7["Stage 7: RETAIN & EXPIRE (Pruning Safeguards)"]

    S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7
```

### Stage 1: Backup Creation (Local Dump)
- **Engine**: PostgreSQL 16 native utility: `pg_dump -Fc` (custom format).
- **Execution**: Consistent snapshot mode; non-blocking to active read/write transactions.
- **Status**: `LOCAL_CREATED`.

### Stage 2: Format-Aware Local Verification
- **Verification Engine**: `pg_restore --list "$LOCAL_BACKUP_PATH"`.
- **Integrity Scope & Limits**: `pg_restore --list` verifies the custom archive header and Table of Contents (TOC) parseability. It asserts that the archive structure can be read and listed, and validates non-zero table and schema counts. **Crucial Precision**: It does **NOT** decompress data blocks or prove full table data integrity. Full data and relational integrity is proven exclusively via real automated restore drills. Prohibits invalid `gzip -t` on custom `-Fc` archives.
- **Status**: `FORMAT_VERIFIED`.

### Stage 3: Client-Side Envelope Encryption
- **Encryption Algorithm**: AES-256-GCM with a single-use 256-bit Data Encryption Key (DEK).
- **Key Wrap**: DEK is encrypted using the Key Encryption Key (KEK) derived from the off-host recovery key/passphrase (via Argon2id or enterprise key vault).
- **Derivation & Wrapping Metadata**: Generates IV, Auth Tag, KEK version, and Argon2id salt. All nonsecret derivation metadata is bundled into the recovery point manifest so that decryption is fully deterministic on a clean host without local state. Plaintext data never leaves the host.
- **Status**: `ENCRYPTED`.

### Stage 4: Offsite Dispatch (Transfer)
- **Transport**: Encrypted TLS 1.3 streaming transfer to provider-neutral storage (S3-compatible, Azure Blob, SFTP, Google Drive).
- **Failure Handling**: Network timeouts or provider errors are not swallowed. Retries use exponential backoff (up to 3 attempts).
- **Status**: `DISPATCHED_PENDING_VERIFICATION`.

### Stage 5: Remote Verification (Digest Match)
- **Integrity Check**: Control plane queries remote storage API to list the uploaded object, verify reported byte length, and compare remote SHA-256 digest against local pre-transfer digest.
- **Status**:
  - Remote digest matches local digest → Mark `VERIFIED_OFFSITE`.
  - Remote file missing or size mismatch → Mark `OFFSITE_FAILED` and trigger high-priority alert (MR-18).

### Stage 6: Catalog Recovery Point
- **Manifest**: Creates signed `RecoveryPoint` manifest containing tenant ID, environment, database version, plain/encrypted SHA-256, encryption metadata, salt, IV, and retention class.
- **Status**: `CATALOGED`.

### Stage 7: Retention Policy & Pruning Safeguards
- **Retention Classes**: `PRE_DEPLOY` (7 days, min 2 points), `DAILY` (30 days, min 7 points), `WEEKLY` (90 days, min 4 points).
- **Safety Invariant**: Cleanup MUST NEVER silently delete the only restorable recovery point. Under storage pressure, oldest `PRE_DEPLOY` points are pruned first, while the minimum verified recovery floor is strictly maintained.

---

## 3. Total Host Loss & Offsite Key Escrow Contract

If the source VPS host is completely destroyed:
1. **Zero Host Dependency**: Recovery does NOT depend on files, local container registries, local secret stores, or configuration caches existing on the destroyed host.
2. **Self-Sufficient Offsite Recovery Kit**: Recovery on a clean machine requires only:
   - Offsite storage endpoint URL and access credentials;
   - The off-host recovery key/passphrase;
   - The offsite manifest catalog containing Argon2id salt, KEK version, and envelope IVs;
   - Clean base operating system (Ubuntu 24.04 LTS or Windows Server 2022).
3. **Complete Platform Recovery Set**:
   - **Data Plane**: Application and tenant database dump (`.dump.enc`), decrypted via recovery kit;
   - **Linux Platform Set**: Docker Compose specifications, pinned image tags, Traefik dynamic TLS/routing configurations, and customer uploaded assets;
   - **Windows Platform Set**: IIS site/AppPool definitions, compiled agent packages (`TMK.Agent.Windows`), Windows service configurations, certificate store thumbprints, and customer asset storage;
   - **Identity & Roles**: Core database role definitions and least-privilege application database grants.

---

## 4. Realistic RPO and RTO Operational Targets

Unrealistic claims of "instantaneous snapshot rollback" or certified guarantees are eliminated. Defined operational targets for Phase 5 Gate A testing:

| Metric | Target | Verification Method |
|---|---|---|
| **Recovery Point Objective (RPO)** | **24 hours** (Scheduled daily)<br>**1 hour** (Pre-deploy) | Measured backup execution frequency and data-loss window; validated in Phase 5 drills. |
| **Recovery Time Objective (RTO)** | **30 minutes** | Disaster drill restores 10 GB database onto freshly provisioned VM and starts services within 30 minutes. |

---

## 5. Pre-Restore Safety Contract (MR-15)

Database restoration is a destructive disaster recovery operation, NOT an automated release rollback.
1. **Mandatory Confirmation**: Requires operator confirmation flag `--confirm-destructive-data-loss`.
2. **Quiescing**: Active connections are terminated; application placed in Maintenance Mode.
3. **Pre-Restore Safety Dump**: An ad-hoc physical dump of the live database is taken immediately before restoration to preserve any post-snapshot writes for forensic recovery.

---

## 6. Phase 5 Failure & Resilience Acceptance Matrix

Phase 5 implementation must execute and pass the complete failure scenario acceptance matrix:

| Failure Scenario | Test Condition | Expected Observable Outcome | Pass/Fail Gate |
|---|---|---|---|
| **Archive Tampering** | Bit-flip injected into encrypted archive or plaintext manifest. | Verification fails with authentication/integrity error; corrupted backup rejected from catalog; alert dispatched. | Corrupted backup never promoted to usable recovery point. |
| **Upload / Null Failure** | Simulated network drop or zero-byte response during transfer. | Transfer marked `OFFSITE_FAILED`; prior recovery points preserved; retry dispatched. | Failed transfer alerted; zero data loss of prior points. |
| **Key Rotation & Custody** | Backups created under KEK Version 1 restored after rotation to KEK Version 2. | Engine resolves historical KEK Version 1 via recovery kit metadata and successfully decrypts. Missing key fails gracefully. | Versioned key custody operational. |
| **Source Host Destruction** | Source VM completely wiped. Recovery executed on bare-metal / clean VM. | Full restoration of database and services using only offsite recovery kit and clean base OS. | Complete recovery under total host loss. |
| **Storage Retention Pressure** | Backup storage quota exceeded. | Retention engine purges oldest non-critical backups while strictly protecting the last verified known-good point. | Last verified recovery point NEVER deleted. |
| **Inconsistent Data / Drill Failure** | Restore drill detects missing tables or schema constraint failures. | Drill marked FAILED; error log captured; live production unaffected; incident logged. | Flawed backup detected without impacting production. |
| **Measured RPO / RTO** | Timed disaster recovery simulation on clean target host. | RPO verified $\le 24\text{h}$ (or $\le 1\text{h}$ pre-deploy); RTO measured against 30-minute target profile. | Pass/fail logged with concrete run timing records. |

