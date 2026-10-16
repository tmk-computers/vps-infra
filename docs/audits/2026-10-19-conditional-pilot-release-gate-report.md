# OMR SaaS Conditional Pilot Release Gate Report
**Audit & Evidence Verification Date:** October 16, 2026  
**Evaluation Status:** Technical Remediation Verified on Staging; Production Deployment Strictly Blocked  
**Target Hardware:** Single VPS (8 vCPU, 32 GB RAM, ~387 GB NVMe)  
**Host Environment:** Linux Ubuntu 24.04 LTS (Kernel 6.8.0-45-generic)  
**Proposed Pilot Cohort Boundary:** Proposed 10 partner institutes, max 100 sheets/batch, <=150 active queued sheets/tenant (Subject to Governance Approval)  
**Directive:** **DO NOT DEPLOY PRODUCTION** (Production deployment and migrations blocked pending explicit approval)

---

## 1. Governance Statement & Formal Release Gate Verdict

### Prior Conclusion Rescission
> [!IMPORTANT]
> **Formal Rescission:** Any prior conclusion asserting that the system is "technically qualified and approved for production go-live" is **FORMALLY WITHDRAWN**. The platform has only been qualified against a bounded synthetic and representative staging workload. Certification cannot be claimed beyond the tested envelope.

### Release Gate Verdict: **NO-GO FOR UNCONDITIONAL PRODUCTION GO-LIVE / CONDITIONAL HOLD FOR PILOT**

While backend admission controls, advisory quota locks, front-end summary polling, CI suspension RBAC, and in-flight rollback recovery have been verified on staging, **unconditional production release is rated NO-GO due to two blocking operational prerequisites**:
1. **Off-Host Disaster Replication:** The backup destination resides on the local VPS disk. In the event of a catastrophic VPS host or storage controller failure, data loss is unbounded without an external cloud bucket or remote host replication mount.
2. **Cloudflare Origin CA Certificate:** Traefik serves a default self-signed fallback certificate. While Cloudflare *Full* mode operates, Cloudflare *Full (strict)* cannot pass until an official Cloudflare Origin CA certificate is mounted to Traefik.

> [!CAUTION]
> **Production Mutation Safeguard:** Production database `omr_prod`, production RabbitMQ vhost `/omr-prod`, production volume directories (`volumes/apps/omr-api/prod`), and production secrets remain **100% BLOCKED and UNTOUCHED**. No migrations or release deployments may be scheduled as automatically authorized. Any production mutation strictly requires prior explicit written authorization from system ownership.

---

## 2. Launch Requirements Verification Matrix

| # | Requirement | Status | Verification Summary & Evidence |
|---|-------------|:------:|---------------------------------|
| **1** | **Fail-closed tenant context & authorized tenant switching** | **PASS** | `UserContextService.cs` strictly resolves `ClientId` from validated JWT claims for all non-admin users. Spoofed `X-Client-Id` headers are ignored. `SuperAdmin` role is required for tenant switching. Missing context fails closed to `null`. Tested via unit tests and API integration suite. |
| **2** | **Cross-tenant isolation test suite** | **PASS** | `CrossTenantIsolationTests.cs` (760+ lines) covers cross-tenant reads (404), unauthenticated uploads (401), unauthorized batch cancellations (400), unauthorized retries (403), attachment storage key access controls, and role impersonation defenses. |
| **3** | **Pre-buffering upload admission & bounded memory buffers** | **PASS** | Created `UploadAdmissionFilter.cs` implementing `IAsyncResourceFilter`. Saturated concurrency (>2 slots) rejects with HTTP 429 *before* Kestrel parses or buffers multipart form bytes. `MemoryBufferThreshold` reduced from 100 MB to 2 MB; request body limit lowered to 100 MB. |
| **4** | **Atomic tenant quotas, ZIP validation & failed-upload cleanup** | **PASS** | `UploadAdmissionService.cs` serializes concurrent quota validation across separate DB connections using PostgreSQL transactional advisory locks (`pg_advisory_xact_lock`). Uses `.IgnoreQueryFilters()` to accurately count all tenant sheets across branches. ZIP entry inspection rejects archives >100 entries (`BATCH_SIZE_EXCEEDED`). Failed uploads trigger try/catch cleanup marking `ScanSession.Status = "Failed"` and `IsActive = false`. |
| **5** | **Lightweight progress summaries & paginated sheet details** | **PASS** | Added `GET /api/MobileOmr/scan/{id}/summary` (<1 KB payload) and `GET /api/MobileOmr/scan/{id}/sheets?page=1&pageSize=20`. Frontend (`MobileOmrBulkUploadModal.tsx`, commit `20313aa`) polls lightweight summary every 1–2s and loads sheets only once upon terminal completion. Verified in deployed JS bundle. |
| **6** | **Platform worker build selection & immutable release artifacts** | **PASS** | Built and deployed distinct Docker images with immutable sha256 digests for API (`omr-api:qa`), Worker (`omr-worker:qa`), and Web (`omr-web:qa`). RabbitMQ vhosts `/omr-qa` and `omr-qa` both configured with full permissions to eliminate vhost normalization issues. |
| **7** | **Real API readiness probes** | **PASS** | In `apps/omr-api/docker-compose.yml`, Kestrel listens on port **8080** (not 5000). Active HTTP healthcheck probe (`http://localhost:8080/health`) verified returning `Healthy` and validating DB connectivity and pipeline readiness. |
| **8** | **Production database, vhost, secrets & storage isolation** | **PASS** | Verified full separation: staging uses database `omr_qa` and vhost `omr-qa`; production uses database `omr_prod`, isolated RabbitMQ vhost `/omr-prod` with dedicated credentials (`omr_api_prod_user`), independent secrets (`/etc/vps-infra/secrets/rabbitmq/omr_prod_credentials.env`), and separate NVMe volume directories (`volumes/apps/omr-api/prod/storage`). Production DB remains completely untouched. |
| **9** | **Restricted database & admin access** | **PASS** | In `db/postgres/docker-compose.yml`, PostgreSQL port 5432 and pgAdmin port 5050 are bound strictly to `127.0.0.1`. Public internet access is blocked by firewall and Docker proxy bindings, while local CLI administration and Docker internal overlay networks (`traefik_net`) are preserved. |
| **10** | **Off-host backups with an isolated restore drill** | **NOT VERIFIED** | **BLOCKED:** Destination path `/var/www/vps-infra/volumes/offhost_backup_destination` resides on the same local VPS disk as the primary storage. No remote S3 bucket, Cloudflare R2 bucket, or separate host mount is configured. Parity drill passed locally (10.51s restore), but off-host RPO is unbounded upon host failure. |
| **11** | **Rollback qualification under active in-flight work** | **PASS** | Executed `drill-rollback-inflight.sh` using two **genuinely distinct compatible image digests**: Release A (`sha256:11b8c3c7718d...`) and Release B (`sha256:719a6c0c2eb2...`). Enqueued active 5-sheet batch and rolled back worker container mid-processing. All 5 sheets persisted in DB, **0 lost jobs, 0 duplicate sheets, 0 duplicate results**, valid sheets graded (Marks: 30.00). Recovery duration: **15.5s**. Evidence: `docs/audits/rollback-inflight-evidence.json`. |
| **12** | **CI build resource controls & host protection** | **PASS** | Implemented observable endpoint `GET /api/ci/pilot-window/status`, and RBAC-authenticated endpoints `POST /freeze` and `POST /unfreeze` requiring `Admin`, `SuperAdmin`, or `DevOps` role. Unauthenticated requests return HTTP 401; unauthorized roles return HTTP 403; authorized calls return HTTP 200. Freeze state survives container restarts. Build executor rejects builds with `CI_SUSPENDED_DURING_PILOT_EXAM_WINDOW`. Unit test passed. Evidence: `docs/audits/ci-pilot-window-evidence.json`. |
| **13** | **Trusted production TLS certificates** | **NOT VERIFIED (STRICT)** | Cloudflare edge TLS resolves with trusted Google Trust Services certificates (62d left) across all 4 domains. However, Traefik origin serves a default self-signed cert. Cloudflare operates in *Full* mode, but **Full (strict) cannot pass** until a Cloudflare Origin CA certificate is mounted to Traefik. |

---

## 3. Deep-Dive Gap Remediation & Verification Analyses

### 3.1 Rollback Under In-Flight Work: Genuinely Distinct Digests

During previous evaluation, Release A and Release B were found to share identical sha256 digests due to tagging the same underlying image. To qualify true rollback across distinct release builds:
1. **Revisions Built:**
   * **Release A:** `localhost:5000/omr-worker:qa-release-a`  
     *Digest:* `sha256:11b8c3c7718d3c811baa07542bb00751bd3d96ad241e2a66a200aad8dc37bc81`
   * **Release B:** `localhost:5000/omr-worker:qa-release-b`  
     *Digest:* `sha256:719a6c0c2eb2be762e530a420ab574d56fc7cb8bc0a13ab69e8c07299b3c525e`
   * **Assertion:** `Digest A != Digest B` strictly verified.
2. **Workload & Rollback Execution:**
   * While 5 sheets were in-flight for Tenant Alpha (`ed759a65-28b8-4293-8eb9-9155b54c9909`), the active worker container was stopped, downgraded to Release B, and restarted.
   * Workload Parity: 5/5 sheets persisted in `OmrSheets`.
   * **Lost Jobs:** 0.
   * **Duplicate Sheets:** 0.
   * **Duplicate Results:** 0.
   * **Score Fidelity:** Valid test sheet scored `30.00 / 30.00`.
   * **Recovery Duration:** **15.5 seconds**.
   * Evidence: [rollback-inflight-evidence.json](file:///var/www/vps-infra/docs/audits/rollback-inflight-evidence.json).

---

### 3.2 Backup Failure Domain & Realistic RPO/RTO Analysis

* **Local Drill Results:**
  * Script: `drill-offhost-backup-restore.sh`.
  * Parity: Restored into isolated database `omr_restore_drill` and isolated storage directory `volumes/restore_drill_storage`. 100% record and file parity verified across 3 clients, 88 sessions, 554 sheets, 1 result, 554 storage files (455,016,650 bytes).
  * Restore Time: **10.51 seconds**.
* **Failure Domain Gap:**
  * The destination `/var/www/vps-infra/volumes/offhost_backup_destination` is located on the **same physical NVMe disk** as the source database and storage volumes.
  * No external cloud bucket (AWS S3, Cloudflare R2), remote SFTP server, or separate host mount has been provisioned.
* **Realistic RPO Calculation:**
  * The claim of a "0-second RPO" is valid only for a local software drop drill where the underlying storage survives.
  * If the VPS host suffers a hardware failure, kernel crash, or disk corruption, **all local backups and primary data are lost simultaneously**.
  * Without continuous WAL archiving or remote cloud mirroring, the off-host RPO is **unbounded (loss of all data since last external manual export)**.
  * **Requirement:** Must be marked **NOT VERIFIED** until an off-host cloud destination is provisioned.

---

### 3.3 TLS Validation: Edge vs Origin & Strict Mode

* **Cloudflare Edge Validation:**
  * Domains: `qa-omr-api.kakshaplus.com`, `qa-omr.kakshaplus.com`, `omr-api.kakshaplus.com`, `omr.kakshaplus.com`.
  * Public DNS resolves to Cloudflare edge nodes `172.67.184.230`, `104.21.19.25`.
  * Certificate Authority: Google Trust Services (WE1), valid through Dec 17, 2026 (62 days remaining).
* **Origin TLS Gap & Strict Mode Incompatibility:**
  * Traefik `acme.json` has `"Certificates": null`. Let's Encrypt TLS-ALPN-01 challenges fail because Cloudflare does not proxy ALPN negotiations. Traefik serves a default self-signed fallback certificate.
  * In Cloudflare **Full** mode, Cloudflare accepts this self-signed origin certificate.
  * **Full (strict) Mode WILL FAIL:** If Cloudflare is switched to *Full (strict)*, Cloudflare will reject the origin's self-signed certificate with **HTTP 526 (Invalid SSL Certificate)**.
  * **Requirement:** Retaining Full mode with a default self-signed certificate is not approved for strict compliance. A Cloudflare Origin CA certificate must be generated in the Cloudflare dashboard and mounted to Traefik before Full (strict) can be certified.

---

### 3.4 CI Suspension RBAC & Restart Persistence

To ensure host-taxing BuildKit builds cannot be triggered during pilot exam windows:
1. **Access Control Enforcement:**
   * In `ci-server/api/server.js`, `POST /api/ci/pilot-window/freeze` and `POST /api/ci/pilot-window/unfreeze` are protected by `authenticateToken` and `requireRole(['Admin', 'SuperAdmin', 'DevOps'])`.
   * **Unauthenticated callers:** Rejected with **HTTP 401 Unauthorized**.
   * **Unauthorized roles (e.g. Viewer):** Rejected with **HTTP 403 Forbidden**.
   * **Authorized callers (SuperAdmin):** Accepted with **HTTP 200 OK**.
   * `GET /api/ci/pilot-window/status` remains accessible for unauthenticated read-only observability.
2. **Build Rejection:**
   * In `build-runner.js`, `startBuild()` enforces `getPilotExamWindowStatus()` at Step 0, failing-fast before license or database queries with `CI_SUSPENDED_DURING_PILOT_EXAM_WINDOW`.
   * Automated schedule covers October 19–25, 2026, 08:30–15:30 IST.
3. **Restart Persistence:**
   * State is written to `/var/www/vps-infra/volumes/ci-pilot-freeze.json`.
   * Verified by [verify-ci-pilot-window.sh](file:///var/www/vps-infra/scripts/verify-ci-pilot-window.sh): active freeze mode survives container restart.
   * Evidence: [ci-pilot-window-evidence.json](file:///var/www/vps-infra/docs/audits/ci-pilot-window-evidence.json).

---

### 3.5 Traceability: Message Contracts, Queue Endpoints & Health Check

* **Message Contracts:**
  * Batch Extraction: `OmrPlatform.Core.Storage.Messaging.ProcessBatchCommand`
  * Sheet Grading: `OmrPlatform.Core.Storage.Messaging.ProcessSheetCommand`
* **Queue Endpoints:**
  * Batch Extraction Queue: `omr-batch-queue` (prefetch: 1)
  * Sheet Grading Queue: `omr-sheet-queue` (prefetch: 4, concurrency: 2)
* **Deployed Artifact Digests:**
  * `omr-api:qa`: `localhost:5000/omr-api@sha256:efc6413d192aa37a9a35eb104eeca511ba184f5bc969328cd0c09a87a12d0f71`
  * `omr-worker:qa`: `localhost:5000/omr-worker@sha256:11b8c3c7718d3c811baa07542bb00751bd3d96ad241e2a66a200aad8dc37bc81`
  * `omr-web:qa`: `localhost:5000/omr-web@sha256:574d3945de31ecb5ea85cef4eb964b3597e9610c401cc09302f1668b010d79bc`
* **Health Check Probe Reconciliation:**
  * The API container runs Kestrel on port **8080** (not 5000).
  * **Container Probe:** `docker exec omr-api-qa curl -fsS http://localhost:8080/health` (assert status `Healthy`).
  * **Host Probe (via Traefik):** `curl -k -fsS -H "Host: qa-omr-api.kakshaplus.com" https://127.0.0.1/health`.

---

## 4. Final Sign-Off Recommendation

### Verdict: **NO-GO FOR UNCONDITIONAL PRODUCTION RELEASE / CONDITIONAL HOLD FOR PILOT**

**The system cannot be certified for production go-live until the following two blocking infrastructure gaps are resolved:**
1. **Remote Cloud Storage Target:** Provision an external S3/R2 bucket or remote mount outside this VPS failure domain and verify automated snapshot transfer.
2. **Cloudflare Origin CA Certificate:** Install a Cloudflare Origin CA certificate in Traefik to enable and verify Cloudflare **Full (strict)** mode.

**Production Deployment Directive:** Production database `omr_prod`, migrations, vhosts, and production containers remain **100% BLOCKED**. No production mutations may occur without explicit written authorization from platform governance.
