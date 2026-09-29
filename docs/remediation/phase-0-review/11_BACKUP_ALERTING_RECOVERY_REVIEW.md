# 11 BACKUP, ALERTING & DISASTER RECOVERY INDEPENDENT REVIEW

**Document ID**: `REMED-P0-REV-11`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Backup & Disaster Recovery Forensic Audit (MR-14 & MR-15)

The Reviewer audited [`DatabaseBackupBackgroundService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DatabaseBackupBackgroundService.cs), [`GoogleDriveService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/GoogleDriveService.cs), and [`DisasterRecoveryService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/DisasterRecoveryService.cs).

### 1.1 Complete Lifecycle Audit of Backup Subsystem

| Lifecycle Dimension | Current Code Implementation Reality | Status | Assessment |
| :--- | :--- | :---: | :--- |
| **Backup Creation** | Executes `pg_dump` via `ProcessStartInfo` into local `.sql` or `.sql.gz` dump files. | **PRESENT** | Functional for local PostgreSQL instances. |
| **Local Storage Location**| `/var/www/vps-infra/volumes/db/postgres/backups` | **PRESENT** | Stored on local host disk. |
| **Local Encryption** | Plaintext gzip; zero encryption-at-rest implemented for local backup files. | **ABSENT** | Gaps in credential and PII protection on disk. |
| **Google Drive Upload** | `GoogleDriveService.UploadFileAsync` handles OAuth2 and Service Account uploads. | **PRESENT** | Code exists and communicates with Google Drive API v3. |
| **Return Code Checking** | In `DatabaseBackupBackgroundService.cs:472`, `await googleDriveService.UploadFileAsync(...)` return string is **ignored**. Success is logged to DB **prior** to the upload call! | **DEFECTIVE** | F11 / MR-14: Upload failures are not detected by caller. |
| **Retry & Error Alerting**| If upload fails, error is logged; zero retry queue or operator alerts dispatched. | **ABSENT** | Silent offsite backup drop. |
| **Remote Checksum Match** | Zero remote MD5/SHA-256 verification against the Google Drive file object. | **ABSENT** | Corrupted uploads remain undetected. |
| **Remote Retention Policy**| Zero scheduled pruning on Google Drive; remote files accumulate indefinitely. | **ABSENT** | Storage bloat. |
| **Restore from Offsite** | `DatabaseController.cs` restores only from local files on the VM disk. Zero mechanism to download and restore from Google Drive. | **ABSENT** | Host loss renders offsite backups inaccessible via UI. |
| **Clean-Server Recovery** | Zero bootstrap scripts to restore a blank server from offsite cloud dumps. | **ABSENT** | Total host failure requires manual human reconstruction. |

### 1.2 Vendor Diversity (S3/R2) vs. Verified Recovery Outcome
The Reviewer explicitly evaluated whether the absence of AWS S3 or Cloudflare R2 is an independent Gate-A blocker:
- **Mandatory Gate-A Outcome**: Verified, dependable offsite recovery. If a disaster wipes the local VM, the platform must be restorable from cloud storage with confirmed data integrity.
- **Vendor Specificity**: The Gate-A blocker is **NOT the lack of S3 or R2 specifically**. Google Drive is technically capable of serving as a valid offsite object target for single-VM pilot deployments **IF AND ONLY IF**:
  1. The return value is checked and errors bubble up.
  2. The remote digest/checksum is validated.
  3. A bare-metal restoration procedure from Google Drive onto a clean host is documented and verified.
- Multi-cloud vendor diversity (S3 / R2 / MinIO) is an enterprise resilience enhancement appropriately scheduled for post-pilot phases.

---

## 2. Monitoring & Outbound Alerting Forensic Audit (MR-18)

The Reviewer audited [`DockerEventsBackgroundService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerEventsBackgroundService.cs) to resolve historical audit discrepancy **DEF-09**:

### 2.1 Code Reality vs. Historical Audit Statements
- **Historical Claim (Antigravity DEF-09)**: *"Alerts logged only to DB table; zero outbound email/Slack/webhook dispatch. Cites MonitoringBackgroundService.cs:40."*
- **Current Code Reality**:
  - The historical audit cited the wrong file.
  - In `DockerEventsBackgroundService.cs:208-260`, the service **DOES implement outbound email alerting** via `SendEmailAlertAsync` using `IEmailSender`.
  - When critical Docker events occur, it generates an HTML alert email and calls `emailSender.SendEmailAsync(adminEmail, subject, htmlBody)`.

### 2.2 Alerting Trigger Events & Throttling
1. **Trigger Conditions** (lines 150-165):
   - `oom` (Out of memory termination of any container).
   - `die` with non-zero exit code (`exitCode != "0"` abnormal crash).
2. **Deduplication & Rate Limiting** (lines 217-225):
   - In-memory cache `_lastEmailSent` keyed by `${containerName}:${action}`.
   - Throttles duplicate alerts to once every 15 minutes (`_emailRateLimit = TimeSpan.FromMinutes(15)`).

### 2.3 Operational Gaps Preventing Closed Status
While the email dispatch code exists, it remains classified as `IMPLEMENTED_NOT_VERIFIED` under **MR-18** because:
1. **Zero Runtime Verification**: No automated or lab test proves that SMTP credentials connect, authenticate, and deliver emails to an external mailbox.
2. **Zero Retry on Transport Failure**: If the SMTP server is down or unreachable, the exception is caught, logged, and permanently dropped without a retry spool.
3. **Host-Loss Vulnerability**: Because `DockerEventsBackgroundService` runs *inside* the local DevOps API container, a total host crash, kernel panic, or power outage kills the alerting engine before any message can be dispatched.
4. **Gate-A Requirement**: For Pilot Gate A, dependable external notification (verified SMTP delivery and external heartbeat) is required. Additional channels like Slack, Discord, or SMS are valuable enhancements, but are not mandatory pilot blockers unless required by specific customer contracts.
