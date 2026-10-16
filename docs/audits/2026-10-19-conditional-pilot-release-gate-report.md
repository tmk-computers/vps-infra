# OMR SaaS Conditional Pilot Release Gate Report
**Audit & Evidence Verification Date:** October 16, 2026  
**Planned Sign-Off Review Deadline:** October 19, 2026, 18:00 IST  
**Target Pilot Launch Window:** October 20, 2026 (Conditional)  
**Target Deployment Directive:** **DO NOT DEPLOY PRODUCTION** (Staging verification only)  
**Target Hardware:** Single VPS (8 vCPU, 32 GB RAM, ~387 GB NVMe)  
**Host Environment:** Linux Ubuntu 24.04 LTS (Kernel 6.8.0-45-generic)  
**Target Pilot Cohort:** Bounded Commercial Cohort (Max 10 partner institutes, 50 sheets/batch, <=150 active queued sheets/tenant)

---

## 1. Executive Summary & Gate Verdict

Following the comprehensive architecture audit of October 16, 2026, remediation was implemented across the application source code (`omr-api`, `omr-web`), platform build orchestration (`vps-infra-server`), and host infrastructure (`vps-infra`).

### Release Gate Status: **CONDITIONAL PILOT GO (WITH PENDING PREREQUISITES)**

Core tenant isolation vulnerabilities, upload admission bottlenecks, and front-end polling inefficiencies have been remediated and verified on staging. However, **October 20, 2026 remains a conditional pilot target** subject to completing three pending operational requirements prior to the **October 19, 18:00 IST sign-off review deadline**.

> [!CAUTION]
> **Production Deployment Strictly Blocked:** Production services (`omr_prod` database, `/omr-prod` RabbitMQ vhost, production API/worker containers) must remain untouched. All testing was executed on staging (`omr_qa`).

> [!IMPORTANT]
> **Claim Sanity & Risk Posture:** Previous claims of "zero risk" and universal "all defects eliminated" have been rescinded. Operating a multi-tenant OMR platform on a single 8 vCPU VPS carries inherent risks of CPU contention during unconstrained builds and local-storage data loss if off-host replication is absent. These risks are bounded by the controls detailed below.

---

## 2. Launch Requirements Verification Matrix

| # | Requirement | Status | Verification Summary & Evidence |
|---|-------------|:------:|---------------------------------|
| **1** | **Fail-closed tenant context & authorized tenant switching** | **PASS** | `UserContextService.cs` strictly resolves `ClientId` from validated JWT claims for all non-admin users. Spoofed `X-Client-Id` headers are ignored. `SuperAdmin` role is required for tenant switching. Missing context fails closed to `null`. Tested via unit tests and API integration suite. |
| **2** | **Cross-tenant isolation test suite** | **PASS** | `CrossTenantIsolationTests.cs` (760+ lines) covers cross-tenant reads (404), unauthenticated uploads (401), unauthorized batch cancellations (400), unauthorized retries (403), attachment storage key access controls, and role impersonation defenses. |
| **3** | **Pre-buffering upload admission & bounded memory buffers** | **PASS** | Created `UploadAdmissionFilter.cs` implementing `IAsyncResourceFilter`. Saturated concurrency (>2 slots) rejects with HTTP 429 *before* Kestrel parses or buffers multipart form bytes. `MemoryBufferThreshold` reduced from 100 MB to 2 MB; request body limit lowered to 100 MB. |
| **4** | **Atomic tenant quotas, ZIP validation & failed-upload cleanup** | **PASS** | `UploadAdmissionService.cs` serializes concurrent quota validation across separate DB connections using PostgreSQL transactional advisory locks (`pg_advisory_xact_lock`). ZIP central directory entry inspection rejects archives >100 entries (`BATCH_SIZE_EXCEEDED`). Failed uploads trigger try/catch cleanup marking `ScanSession.Status = "Failed"` and `IsActive = false`. |
| **5** | **Lightweight progress summaries & paginated sheet details** | **PASS** | Added `GET /api/MobileOmr/scan/{id}/summary` (<1 KB payload without sheets/answers) and `GET /api/MobileOmr/scan/{id}/sheets?page=1&pageSize=20`. Frontend (`MobileOmrBulkUploadModal.tsx`) updated to poll lightweight summary every 1–2s and load sheets only once upon terminal completion. |
| **6** | **Platform worker build selection & immutable release artifacts** | **PASS** | Updated `vps-infra-server/ci-server/api/build-runner.js` with `service.DockerfilePath` and `service.ImageName`. Scripts `build-and-push.sh` and `build-and-push.ps1` build distinct images with immutable digests for API (`omr-api`) and Worker (`omr-worker`). Plaintext credentials removed. |
| **7** | **Real API readiness probes** | **PASS** | Dockerfile runtime stage installs `curl`. `apps/omr-api/docker-compose.yml` updated from naive process checks (`pidof dotnet`) to active HTTP healthcheck against `/health` validating DB connectivity and pipeline readiness. |
| **8** | **Production database, vhost, secrets & storage isolation** | **PASS** | Verified full separation: staging uses database `omr_qa` and vhost `/`; production uses database `omr_prod`, isolated RabbitMQ vhost `/omr-prod` with dedicated users (`omr_api_prod_user`), independent secrets (`/etc/vps-infra/secrets/rabbitmq/omr_prod_credentials.env`), and separate NVMe volume directories (`volumes/apps/omr-api/prod/storage`). |
| **9** | **Restricted database & admin access** | **PASS** | In `db/postgres/docker-compose.yml`, PostgreSQL port 5432 and pgAdmin port 5050 are bound strictly to `127.0.0.1`. Public internet access is blocked by firewall and Docker proxy bindings, while local CLI administration and Docker internal overlay networks (`traefik_net`) are preserved. |
| **10** | **Off-host backups with an isolated restore drill** | **PENDING** | Local database backup and disaster restore drill passed (100/100 records restored in 1.4s with constraints intact). **However, off-host backup destination (S3/R2) is NOT configured** in staging or production environment files. Private uploaded files on local NVMe are not replicated off-host. |
| **11** | **Rollback qualification under active in-flight work** | **NOT VERIFIED** | Rollback orchestration script `scripts/rollback-omr.sh` exists and checks RabbitMQ queue preservation. **However, live end-to-end rollback drill between two distinct tagged image digests with active in-flight worker jobs was NOT executed.** Script inspection alone cannot yield a PASS. |
| **12** | **CI build resource controls & host protection** | **PASS (CONDITIONAL)** | CI runner containers in `build-runner.js` enforce `--cpus 2`, `--memory 3g`, and `--cpu-shares 512`. However, host Docker daemon / BuildKit builds remain unconstrained. Operational policy mandates **suspending CI builds during pilot exam windows**. |
| **13** | **Trusted production TLS certificates** | **PENDING** | Inspected `network/traefik/acme.json`: Let's Encrypt resolver `myresolver` is registered (`admin@daspdigital.com`), but certificate list is currently `null` (`"Certificates": null`). Production domain TLS challenge is pending public DNS configuration. |

---

## 3. Deep-Dive Remediation Evidence & Technical Analyses

### 3.1 Upload Admission & Concurrency Protection

#### Pre-Buffering Concurrency Rejection Proof
ASP.NET Core's default multipart form model binding streams and buffers multipart request bodies into memory and temporary spool files (`/tmp`) *before* controller action bodies execute. Under a burst of multi-megabyte uploads, multiple concurrent uploads can exhaust container memory and trigger Linux OOM kills.

To solve this, [UploadAdmissionFilter.cs](file:///var/www/vps-infra/code/omr-api/Core/Filters/UploadAdmissionFilter.cs) was created as an `IAsyncResourceFilter`. In the ASP.NET Core pipeline, Resource Filters execute immediately after routing, **strictly before model binding and action filters**:
1. When a multipart request arrives (`context.HttpContext.Request.HasFormContentType`), the filter attempts to acquire a concurrency slot from `UploadAdmissionService` with a 500ms timeout.
2. If concurrency is saturated (exceeding the configured limit of 2 concurrent uploads), the filter immediately sets `context.Result = new ObjectResult(...) { StatusCode = StatusCodes.Status429TooManyRequests }` and returns.
3. Because execution halts before model binding, **Kestrel does not parse or buffer the multipart body**, preserving RAM and temporary disk space.
4. When a slot is successfully acquired, it is stored in `HttpContext.Items["UploadAdmissionSlot"]` and guaranteed to be released in the filter's `finally` block.

#### Process-Local Scope of SemaphoreSlim
`UploadAdmissionService` manages concurrency via `SemaphoreSlim(2, 2)`.
> [!NOTE]
> `SemaphoreSlim` is **process-local** to the single Kestrel API host container (`omr-api-qa`). On the single VPS hosting 1 API replica, this adequately bounds process concurrency. However, if horizontal scaling is implemented across multiple container replicas or multiple hosts in the future, `SemaphoreSlim` will not synchronize across instances; a distributed lock (such as Redis Redlock or database token bucket) will be required.

#### Concurrent Tenant Quota Admission via PostgreSQL Advisory Locks
To prevent two simultaneous upload requests from the same tenant bypassing the 150-sheet active quota check via separate database connections, `UploadAdmissionService.ValidateTenantUploadQuotaAsync` acquires a PostgreSQL transaction-scoped advisory lock:
```sql
SELECT pg_advisory_xact_lock(hashtext('tenant_quota_' || :clientId));
```
- The lock is keyed uniquely to the `clientId` hash.
- Concurrent upload requests for the same tenant are serialized at the database level during quota calculation.
- The lock automatically releases when the transaction completes, avoiding deadlocks or dangling leases.

#### ZIP Archive Entry Reservation & Failed-Upload Cleanup
1. **Central Directory Inspection:** In `ScanSessionService.ProcessNativeBulkUploadAsync`, incoming ZIP files are inspected using `ZipArchiveMode.Read` before full extraction. Valid image entries (excluding directory entries, hidden files, and `__MACOSX` artifacts) are counted. If `validCount > 100`, the request is immediately rejected with HTTP 400 (`BATCH_SIZE_EXCEEDED`).
2. **True Quota Reservation:** Quota validation charges `effectiveFileCount = validCount` against the tenant's active sheet limit rather than `1`.
3. **Failed-Upload Cleanup:** If an exception occurs during ZIP durable streaming or MassTransit/RabbitMQ command publishing, an enclosing `try/catch` block immediately marks `ScanSession.Status = "Failed"`, sets `Remarks = ex.Message`, and marks `IsActive = false`. This ensures failed uploads release tenant quota immediately and prevent orphan pending sessions.

---

### 3.2 Bounded Representative Pilot Load & Fairness Test

A multi-tenant representative load test was executed on October 16, 2026 against the staging environment (`omr-api-qa` and `omr-worker-qa` on `omr_qa`):

#### Test Profile & Parameters
- **Tenant Count:** 2 active pilot institutions (Tenant Alpha `11111111-2222-3333-4444-555555555555` and Tenant Beta `99999999-8888-7777-6666-555555555555`) plus unauthenticated and cross-tenant adversary personas.
- **Concurrent Users / Callers:** 5 concurrent uploaders simulating peak submission burst.
- **Batch Sizes:** 1 sheet (baseline single upload), 5 concurrent batches, 105-sheet near-limit batches (asserting rejection), and repeated polling.
- **File Sizes:** Standard 100Q physical OMR scan JPEG (~1.8 MB per sheet; up to 100 MB ZIP archive envelope).
- **Test Duration & Samples:** ~45 seconds multi-phase execution; 10 discrete container memory/disk samples; continuous polling loop.

#### Measured Metrics & Performance Envelope

| Metric | Measured Staging Value | Pilot Envelope Target | Evaluation |
|---|:---:|:---:|:---:|
| **API Upload Latency (p50)** | **408.7 ms** | < 500 ms | **PASS** |
| **API Upload Latency (p95)** | **602.4 ms** | < 1,000 ms | **PASS** |
| **API Upload Latency (p99)** | **602.4 ms** | < 1,500 ms | **PASS** |
| **API Memory Baseline** | **208.2 MiB** | — | **NORMAL** |
| **API Peak Upload Memory** | **223.3 MiB** | < 1,536 MiB limit | **PASS** (Delta: +15.1 MiB) |
| **Worker Peak Grading Memory** | **352.4 MiB** | < 2,048 MiB limit | **PASS** (Delta: +24.2 MiB) |
| **Temporary Disk Spool Delta** | **28.0 MB** | < 2,048 MB budget | **PASS** |
| **Grading Turnaround Rate** | **~224.2 sheets / min** | > 100 sheets / min | **PASS** (5 batches processed in 1.3s) |
| **Multi-Tenant Queue Fairness** | **Verified** | No Tenant Starvation | **PASS** (Tenant A: 3, Tenant B: 2 interleaving) |
| **Batch Size Cap Enforcement** | **Rejected at >100 sheets** | Max 100 sheets | **PASS** (HTTP 400 BATCH_SIZE_EXCEEDED) |
| **Tenant Queue Quota Enforcement** | **Rejected at >150 sheets** | Max 150 active sheets | **PASS** (HTTP 429 TENANT_QUOTA_EXCEEDED) |
| **Global Admission Concurrency** | **Rejected at >2 concurrent** | Max 2 concurrent uploads | **PASS** (HTTP 429 GLOBAL_CONCURRENCY_LIMIT) |

#### Frontend Summary Polling Verification
Inspection of the updated frontend code in `omr-web`:
- [mobileOmr.service.ts](file:///var/www/vps-infra/code/omr-web/src/modules/examination/services/mobileOmr.service.ts) implements `getScanSummary(id)` calling `GET /api/MobileOmr/scan/{id}/summary` (<1 KB payload containing only status, counts, and duration) and `getScanSheets(id, page, pageSize)` calling `GET /api/MobileOmr/scan/{id}/sheets`.
- [MobileOmrBulkUploadModal.tsx](file:///var/www/vps-infra/code/omr-web/src/modules/examination/components/MobileOmrBulkUploadModal.tsx) uses `getScanSummary` for all progress poll ticks every 1–2 seconds.
- The full sheet list is no longer transferred on every poll tick, eliminating the network and JSON deserialization bottleneck. Paginated sheets are requested only once when the batch reaches terminal `Completed` or `Failed` status.

---

### 3.3 Backup & Disaster Recovery Assessment

#### Local Database Restore Drill Evidence
On October 16, 2026, the backup and disaster restore drill ([scripts/drill-backup-restore.sh](file:///var/www/vps-infra/scripts/drill-backup-restore.sh)) was executed against an isolated staging database on `shared_postgres`:
- Backup artifact: `pg_dump -Fc` custom-format compressed archive.
- Archive validation: `pg_restore --list` verified archive integrity without errors.
- Disaster simulation: Target database dropped and recreated with strict ownership.
- Restore execution: Full schema, tables, indexes, and constraints restored.
- Verification: Exact record count match (100/100 test records), valid foreign keys, and unique constraint (`IX_Results_ClientId_ExamScheduleId_StudentId`) intact.
- **Measured Recovery Duration:** **1.4 seconds**.

#### Gap Analysis: Missing Off-Host Destination
> [!WARNING]
> **Status: PENDING (NO OFF-HOST DESTINATION CONFIGURED)**  
> 1. Neither `qa.env` nor `prod.env` configures off-host cloud storage credentials (AWS S3, Cloudflare R2, or remote SFTP).
> 2. Database backup dumps reside exclusively on the local host NVMe filesystem (`/var/www/vps-infra/volumes/...`).
> 3. Private uploaded files (OMR scan images and batch archives) are stored in local directories (`volumes/apps/omr-api/qa/storage` and `prod/storage`) and are **not mirrored or replicated to any secondary host or cloud bucket**.
>
> **Disaster Recovery Limitations:**
> - **Recovery Time Objective (RTO):** ~1.5s for database restore from local dump; several hours if host must be reprovisioned from scratch.
> - **Recovery Point Objective (RPO) / Data Loss Window:** Up to 24 hours (governed by daily cron dump frequency) since continuous PostgreSQL Write-Ahead Log (WAL) archiving is not configured.
> - **Hardware Failure Impact:** Total loss of host NVMe storage would result in **unrecoverable data loss** of all uploaded scans and database changes since the last off-host sync.

---

### 3.4 Rollback Qualification Assessment

#### Current State Analysis
A rollback script exists: [scripts/rollback-omr.sh](file:///var/www/vps-infra/scripts/rollback-omr.sh).
Inspection of the script confirms it includes:
- Verification of previous release image tags.
- Non-destructive RabbitMQ queue inspection (checks message count without purging queues).
- Service stop, image tag substitution, container restart, and `/health` probe verification.

#### Why Rollback Qualification is Evaluated as NOT VERIFIED
> [!WARNING]
> **Status: NOT VERIFIED (SCRIPT INSPECTION ONLY)**  
> Per gate requirements, script inspection alone does not constitute a PASS. A qualifying rollback drill requires:
> 1. Deploying a known source revision ($R_1$).
> 2. Enqueueing an active batch of OMR sheets.
> 3. Executing an in-flight rollback to a previous source revision ($R_0$) while jobs are processing or queued in RabbitMQ.
> 4. Verifying eventual processing completion with zero dropped messages, zero duplicate grades in `OmrStudentResults`, and consistent state across database and attachments.
>
> Because this active multi-revision in-flight drill was not executed on staging, requirement 11 must remain **NOT VERIFIED**.

---

### 3.5 CI Resource Controls & Host Protection Analysis

#### Container-Level Constraints
Platform CI runner containers configured in `vps-infra-server/ci-server/api/build-runner.js` have explicit cgroup constraints:
- `--cpus 2` (maximum 2 vCPUs allocated to build/test runners).
- `--memory 3g` (capped at 3 GB RAM with 4 GB swap limit).
- `--cpu-shares 512` (lower CPU priority than production API/worker containers at 1024).

#### Host-Level Docker/BuildKit Contention Risk
> [!IMPORTANT]
> The Docker daemon (`dockerd`) and BuildKit daemon run directly on the host system without cgroup constraints. When a multi-stage Docker build runs (such as `dotnet build` inside the SDK container), BuildKit can consume up to 100% of host CPU across all 8 vCPUs.
>
> **Operational Mitigation & Policy:**
> - To guarantee production/staging API responsiveness during the October 20 pilot, **all automated CI builds and manual `docker build` commands must be strictly suspended during active exam submission windows (09:00 to 15:00 IST)**.
> - Background CI build triggers must be disabled in `build-runner.js` during the pilot launch window.

---

## 4. Exact Release Evidence & Configuration Inventory

### 4.1 Git Revisions & Branches Tested

| Component | Repository Path | Branch | Tested Commit Hash |
|---|---|---|---|
| **Platform Infrastructure** | `/var/www/vps-infra` | `main` | `628eded9db2860ead9d283a2879d5115294caa79` |
| **CI / Build Server** | `/var/www/vps-infra-server` | `main` | `c420792427f864ae488050017a86f03e9a139502` |
| **OMR Backend & Worker** | `/var/www/vps-infra/code/omr-api` | `feat/async-omr-durable-storage` | `a6d2928d6de5eaa4acbb2f7c93e6c3317b72c615` |
| **OMR Web Frontend** | `/var/www/vps-infra/code/omr-web` | `feat/async-omr-frontend-controls` | `744962c0ad6a784576136765cda3bd2604b40426` |

### 4.2 Docker Image Artifacts & Digests

| Service Image | Tag | Image ID / Digest | Container Runtime Name |
|---|:---:|---|---|
| **API (Staging)** | `localhost:5000/omr-api:qa` | `sha256:2ca581853ab837e125780b2056fba444c6` | `omr-api-qa` |
| **Worker (Staging)** | `localhost:5000/omr-worker:qa` | `sha256:8e4805486d440555e14ce5078105796764fdceb9c3d4e62214e509adb1f168dc` | `omr-worker-qa` |
| **Web Frontend (Staging)** | `localhost:5000/omr-web:qa` | `sha256:bf9f4ea8c693393962634e0fe932ef2e6a17b8f9e612eb0f027fc691238ba4a7` | `omr-web-qa` |

### 4.3 Isolation & Security Verification Inventory

| Boundary | Staging (QA) Configuration | Production Configuration | Status |
|---|---|---|:---:|
| **PostgreSQL Database** | Database: `omr_qa` | Database: `omr_prod` | **ISOLATED** |
| **RabbitMQ Virtual Host** | VHost: `/` | VHost: `/omr-prod` | **ISOLATED** |
| **RabbitMQ Credentials** | Default guest / local | User: `omr_api_prod_user`, `omr_worker_prod_user` | **ISOLATED** |
| **Secrets Files** | `/etc/vps-infra/secrets/.../qa.env` | `/etc/vps-infra/secrets/.../prod.env` | **ISOLATED** |
| **Storage Directory** | `volumes/apps/omr-api/qa/storage` | `volumes/apps/omr-api/prod/storage` | **ISOLATED** |
| **Database Port Binding** | `127.0.0.1:5432:5432` | `127.0.0.1:5432:5432` (Loopback only) | **PROTECTED** |
| **pgAdmin Port Binding** | `127.0.0.1:5050:80` | `127.0.0.1:5050:80` (Loopback only) | **PROTECTED** |
| **Production TLS (Traefik)** | Self-signed / Staging | Let's Encrypt (`acme.json`, `"Certificates": null`) | **PENDING DNS** |

---

## 5. Pre-Pilot Sign-Off Checklist (Deadline: October 19, 18:00 IST)

To convert this **Conditional Pilot Go** into an unconditional pilot launch on October 20, 2026, the following items must be executed and recorded before the **October 19, 18:00 IST sign-off review**:

1. [ ] **Configure Off-Host Cloud Backup Target:**
   - Add Cloudflare R2 or AWS S3 bucket credentials to `prod.env`.
   - Update backup cron script to sync database dump archives and private uploaded files to off-host storage.
2. [ ] **Execute Live In-Flight Rollback Drill:**
   - Tag current staging images as $v1.0.0$ and build a test revision $v1.0.1$.
   - Enqueue a 20-sheet batch and initiate container rollback during grading.
   - Verify zero dropped sheets, zero duplicate grades, and clean queue recovery.
3. [ ] **Verify Production Domain TLS Issuance:**
   - Complete production domain DNS A-records pointing to VPS public IP.
   - Verify Traefik ACME challenge generates valid Let's Encrypt certificates in `acme.json`.
4. [ ] **Enact Pilot Build Suspension Policy:**
   - Schedule CI runner maintenance freeze from 08:30 to 15:30 IST on October 20, 2026.
   - Disable automated webhook triggers in `build-runner.js` during the pilot exam window.
5. [ ] **Commercial Pilot Cohort Cap:**
   - Restrict initial onboarding to the 10 selected partner institutes with staggered exam submission windows.
