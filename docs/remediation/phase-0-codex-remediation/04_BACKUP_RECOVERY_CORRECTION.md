# BACKUP AND DISASTER RECOVERY CONTRACT CORRECTION (C1-02 RESOLUTION)

**Document ID**: `REMED-P0-CDX-04`  
**Phase**: Phase 0 — Codex Gate Remediation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-29  
**Audit Reference**: `docs/remediation/phase-0-codex-gate/06_CODEX_FINDINGS_REGISTER.md` (Finding `C1-02`)  
**Status**: COMPLETE ARCHITECTURAL SPECIFICATION  

---

## 1. Context & Problem Statement

The Codex Phase 0 Audit Gate flagged finding `C1-02` as a **Significant Defect (C1)**. The audited baseline suffered from critical gaps in its disaster recovery architecture:
1. **Incomplete Pipeline**: The contract lacked client-side encryption before offsite transfer, off-host key recovery, a durable `RecoveryPoint` manifest, and retention safety controls.
2. **Fatal Key Custody Flaw**: Decryption keys were stored only inside local vaults on the source VPS. If the source VPS were destroyed, all offsite backups would become permanently undecryptable.
3. **Incompatible Verification Commands**: The baseline specified `pg_dump -Fc` (PostgreSQL custom archive format) followed by `gzip -t`. In PostgreSQL, custom-format dumps (`-Fc`) contain an internal binary header and table of contents with internal per-block zlib compression; they are NOT wrapped in an outer gzip stream. Running `gzip -t` on an unwrapped `-Fc` archive fails immediately.
4. **Provider Assumptions**: Assumed S3 ETags were standard MD5 hashes (which is false for multi-part uploads) and hardcoded S3-specific behaviors.
5. **Overstated RTO Claims**: Promised "instantaneous snapshot rollback" without technical grounding.

This document establishes the corrected, provider-neutral Backup & Disaster Recovery Architecture for Gate A.

---

## 2. Complete Backup Lifecycle Pipeline

The backup lifecycle follows a strictly ordered, seven-stage pipeline:

```
[ Stage 1: CAPTURE ]
   |  PostgreSQL 16 custom format dump (pg_dump -Fc) to local scratch volume.
   v
[ Stage 2: LOCAL VERIFY ]
   |  Format-aware validation: pg_restore --list <archive> verifies TOC & header.
   v
[ Stage 3: CLIENT-SIDE ENCRYPT ]
   |  Payload encrypted with AES-256-GCM using rotating Data Encryption Key (DEK).
   |  DEK encrypted with Recovery Master Key (KEK) and appended to EncryptionMetadata.
   v
[ Stage 4: AUTHENTICATED TRANSFER ]
   |  Encrypted payload + detached signature streamed to offsite StorageProvider over TLS 1.3.
   v
[ Stage 5: REMOTE AUDIT & INTEGRITY CHECK ]
   |  Verify remote size and cryptographic SHA-256 digest against local pre-transfer digest.
   v
[ Stage 6: CATALOG RECOVERY POINT ]
   |  Commit authenticated RecoveryPoint manifest to local database and offsite catalog.
   v
[ Stage 7: RETENTION & PRUNING ]
   |  Evaluate retention rules. Protect minimum verified recovery points. Prune expired points.
```

---

## 3. Core Conceptual Entities

The recovery engine models backup and restore operations using the following formal concepts:

### 3.1 Conceptual Entity Definitions

```csharp
// Conceptual data structures for Phase 5 implementation
public record RecoveryPoint(
    Guid RecoveryPointId,
    string TenantId,
    string Environment,
    DateTime CreatedAtUtc,
    string DatabaseVersion,       // e.g. "PostgreSQL 16.2"
    string DumpFormat,           // "custom_fc"
    long PlaintextSizeBytes,
    long EncryptedSizeBytes,
    string PlaintextSha256,
    string EncryptedSha256,
    EncryptionMetadata Encryption,
    StorageMetadata Storage,
    VerificationResult Verification,
    string RetentionClass,       // "DAILY", "WEEKLY", "PRE_DEPLOY"
    DateTime? ExpiresAtUtc,
    bool IsProtectedFromDeletion
);

public record EncryptionMetadata(
    string Algorithm,            // "AES-256-GCM"
    string KeyId,                // Identifier of Key Encryption Key (KEK)
    string EncryptedDEK,         // DEK encrypted by KEK (Base64)
    string InitializationVector, // 96-bit IV (Base64)
    string AuthenticationTag     // 128-bit Auth Tag (Base64)
);

public record StorageMetadata(
    string ProviderType,         // "S3_COMPATIBLE", "AZURE_BLOB", "SFTP", "LOCAL_MIRROR"
    string StorageEndpoint,
    string BucketOrContainer,
    string ObjectKey,
    string RemoteDigest          // Computed SHA-256 digest from provider API
);

public record VerificationResult(
    bool IsFormatValid,
    string VerificationEngine,   // "pg_restore 16.2 --list"
    int TableCount,
    int SchemaCount,
    DateTime VerifiedAtUtc,
    string VerificationLogSnippet
);
```

---

## 4. Backup Payload Encryption & Key Custody Architecture

A disaster recovery system must guarantee recoverability even in the event of **TOTAL HOST DESTRUCTION**. Storing encryption keys exclusively on the source host violates the fundamental disaster recovery boundary.

### 4.1 Envelope Encryption Model
1. **Data Encryption Key (DEK)**: A single-use 256-bit symmetric key generated via cryptographically secure RNG (`RandomNumberGenerator.GetBytes(32)`) for each backup archive.
2. **Payload Encryption**: The raw dump stream is encrypted in streaming chunks using **AES-256-GCM**, producing an encrypted payload and a 128-bit authentication tag.
3. **Key Encryption Key (KEK)**: The DEK is encrypted using the customer's / system's Master Key Encryption Key (KEK).

### 4.2 Surviving Total Host Loss: Offsite Key Custody & Escrow
To ensure that backups remain recoverable if the source VPS is destroyed:
1. **Independent Recovery Passphrase / Key Kit**: During initial platform installation, a 24-word BIP-39 mnemonic recovery phrase is generated.
2. **Air-Gapped Customer Recovery Sheet**: The operator is required to record the recovery phrase off-host (e.g. in secure password vault or physical safe).
3. **Key Derivation (PBKDF2 / Argon2id)**: The KEK is deterministically derived from this recovery passphrase:
   $$\text{KEK} = \text{Argon2id}(\text{Passphrase}, \text{Salt}, \text{Iterations}=3, \text{Memory}=64\text{MB})$$
   **Self-Sufficient Recovery Manifest**: Nonsecret derivation metadata (Argon2id salt, KEK version identifier, initialization vector) is stored in plaintext within the recovery manifest accompanying the backup archive, enabling clean-slate reconstruction.
4. **Disaster Recovery Execution**: On a completely blank replacement VPS, the operator provides:
   - The offsite storage credentials (endpoint, bucket, access keys);
   - The 24-word recovery passphrase.
   The replacement host retrieves the recovery manifest, extracts the salt, derives the KEK, downloads the encrypted backup, unwraps the DEK, and decrypts the archive. **Zero dependency on the destroyed host filesystem, local registry, or licensing server.**

---

## 5. Format-Aware Backup Verification

Checksum verification (MD5 or SHA-256) proves that a file was not corrupted during transit, but it does NOT prove that the file is a syntactically valid, restorable PostgreSQL database archive.

### 5.1 Elimination of Invalid `gzip -t`
PostgreSQL custom dumps (`pg_dump -Fc`) use an internal, proprietary format designed specifically for `pg_restore`. Custom dumps are NOT raw gzip streams; running `gzip -t` on them will report decompression errors on valid archives.

### 5.2 Gate A Authoritative Verification Command
For Gate A (PostgreSQL 16), backup validity is verified non-destructively using `pg_restore`:

```bash
# Non-destructive format-aware verification:
# Reads the archive header and Table of Contents (TOC).
# Crucial Precision: It does NOT decompress data blocks or verify full table data integrity.
# Full data and relational integrity is proven exclusively via real automated restore drills.
# Returns exit code 0 if valid; non-zero if truncated, corrupted, or unreadable.
pg_restore --list "$LOCAL_BACKUP_PATH" > /tmp/backup_toc.txt

if [ $? -ne 0 ]; then
    echo "ERROR: Backup archive failed PostgreSQL format verification!"
    exit 1
fi

# Verify TOC contains required schema and table definitions
SCHEMA_COUNT=$(grep -c "SCHEMA" /tmp/backup_toc.txt)
TABLE_COUNT=$(grep -c "TABLE DATA" /tmp/backup_toc.txt)

if [ "$TABLE_COUNT" -eq 0 ]; then
    echo "ERROR: Backup TOC contains zero tables. Rejecting recovery point."
    exit 1
fi
```

This verification occurs immediately after dump generation (on the unencrypted local dump) and is logged into `VerificationResult`.

---

## 6. Complete Platform Recovery Set

A database dump alone is insufficient to reconstruct a functional platform. A complete recovery set consists of three components:

1. **Database Archive (`.dump.enc`)**: PostgreSQL custom-format database archive containing all application schemas, tenant records, users, and audit logs.
2. **Platform Manifest (`manifest.json.enc`)**: Machine-readable configuration snapshot recording:
   - Platform software version;
   - Docker image tags and digest hashes;
   - Ingress routing rules and domain names;
   - Tenant-to-host mappings and environment variables;
   - Protected secrets (database credentials, JWT signing keys, TLS private keys) encrypted under the KEK, enabling complete restoration on a bare-metal host.
3. **Asset & Storage Bundle**: Customer file uploads, project templates, and persistent object files stored in the persistent volume root.

All three components are packaged under a common `RecoveryPointId` and uploaded together.

---

## 7. Retention Policy & Storage Pressure Safeguards

Backup cleanup must never jeopardize disaster recovery.

### 7.1 Retention Classes

| Retention Class | Generation Trigger | Default Retention Window | Minimum Retained Points |
|---|---|---|---|
| **`PRE_DEPLOY`** | Triggered automatically prior to applying migrations. | 7 days | At least 2 |
| **`DAILY`** | Scheduled daily cron job (02:00 UTC). | 30 days | At least 7 |
| **`WEEKLY`** | Scheduled weekly (Sunday 03:00 UTC). | 90 days | At least 4 |
| **`MANUAL_HOLD`** | Created by administrator before major maintenance. | Indefinite (until manual release) | N/A |

### 7.2 Safety Invariants During Pruning
1. **Never Prune the Last Known Good**: The pruning engine evaluates candidate deletions. If a deletion would leave fewer than 2 verified recovery points for a tenant/service, the deletion is aborted, and an alert is logged (`WARN_RETENTION_FLOOR_REACHED`).
2. **Protection of Unverified Points**: Unverified or failed recovery points are quarantined for 72 hours for debugging, then purged. They never count toward the minimum retained quota.
3. **Storage Pressure Handling**: If offsite storage capacity threshold is exceeded (> 90%), the pruning engine prunes oldest `PRE_DEPLOY` points first, but strictly preserves the minimum daily and weekly retention baselines.

---

## 8. Master Phase 5 Failure Acceptance Matrix

To ensure full coverage of disaster recovery failure modes, Phase 5 testing mandates verification against the following scenarios:

| Failure Mode | Injected Fault | Expected Behavior | Acceptance Standard |
|---|---|---|---|
| **Corrupted Payload (Tamper)** | Random byte flipped in encrypted `.dump.enc`. | AES-256-GCM authentication tag verification fails during decryption. | Decryption aborts with `CryptographicException`; corrupted file quarantined. |
| **Truncated Dump** | `pg_dump` interrupted before completion. | `pg_restore --list` returns non-zero exit code or zero `TABLE DATA` entries in TOC. | Local verification fails; recovery point marked `INVALID`; offsite upload aborted. |
| **Null / Upload Failure** | Network disconnected during S3 upload. | Upload task fails; remote digest verification detects missing object. | State set to `FAILED_OFFSITE_UPLOAD`; notification dispatched; local dump retained. |
| **Key Rotation & Custody** | Backup created under KEK v1; system rotated to KEK v2. | Manifest specifies `KekVersion = 1`; engine resolves historical KEK from kit. | Successful decryption and restore using historical key. |
| **Storage Pressure / Floor** | Disk at 95% capacity; automated prune triggered. | Pruning purges expired pre-deploy dumps; aborts if verified count would drop below floor. | Minimum retention floor (2 verified points) strictly preserved. |
| **Total Source Host Loss (Linux)** | Linux host destroyed; blank VM provisioned. | Operator provides S3 credentials and 24-word recovery passphrase. | System derives KEK, downloads manifest, restores DB, and restarts services. |
| **Total Source Host Loss (Windows)** | Windows Server destroyed; fresh Windows Server provisioned. | Operator provides S3 credentials and 24-word recovery passphrase. | System derives KEK, restores remote DB schema, provisions IIS sites/apppools, binds TLS. |

---

## 9. Realistic RPO and RTO Targets (Gate A Profile)

Unrealistic promises of "instantaneous recovery" are eliminated. The Gate A recovery contract defines operational targets for subsequent measurement:

| Metric | Target | Measurement Method | Gate-A Acceptance Criterion |
|---|---|---|---|
| **Recovery Point Objective (RPO)** | **24 hours** (Scheduled)<br>**1 hour** (Pre-deploy) | Maximum elapsed time between the most recent restorable backup and the point of failure. | Operational target: Daily backups run successfully every 24h; pre-deploy backups run immediately before deployment. |
| **Recovery Time Objective (RTO)** | **30 minutes** | Total time required to download, decrypt, format-verify, and restore a 10 GB database onto a provisioned replacement VPS. | Operational target: Restore drill on test VM restores 10 GB database and starts services in $\le 30$ minutes. |

---

## 10. Conclusion

This contract resolves all defects identified in finding `C1-02`. It establishes end-to-end client-side encryption with disaster-proof key custody, format-aware PostgreSQL verification, a complete platform recovery set, full Phase 5 failure test coverage, and realistic RPO/RTO operational targets.
