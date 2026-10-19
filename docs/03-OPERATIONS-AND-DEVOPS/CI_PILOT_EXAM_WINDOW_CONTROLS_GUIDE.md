# 🚦 CI Pilot Exam Operational Window & Resource Controls Guide

This guide documents the architecture, operational runbook, configuration toggles, and REST API controls for the **Pilot Exam CI Suspension Window** in the VPS-Infra platform.

---

## 1. Architecture & Background

### 1.1 Why This Protection Exists
On single-host VPS deployments, concurrent Docker BuildKit compilations (e.g., .NET AOT/SDK builds, Node build trees, Playwright headless browser runners) consume 100% of all host vCPUs and substantial RAM. 

During live exam operational hours, high-priority workloads—including:
* **OMR Ingestion API** (`omr-api`)
* **Background Sheet Grading Workers** (`omr-worker`)
* **RabbitMQ Message Broker** (`omr-batch-queue`, `omr-sheet-queue`)
* **Redis Caching & Result Deduplication** (`omr-ai-redis`)

must execute with sub-second latency and zero CPU starvation. To prevent accidental or automated CI builds from degrading live exam processing, **Gate 7 (Host CPU/RAM Preservation via CI Suspension)** enforces fail-fast rejection of build requests before any build container or process tree is spawned.

```
                              ┌───────────────────────────────────┐
                              │     Build Trigger Request         │
                              │  (Manual UI, Git Webhook, REST)   │
                              └─────────────────┬─────────────────┘
                                                │
                                                ▼
                              ┌───────────────────────────────────┐
                              │    build-runner.js: startBuild()  │
                              └─────────────────┬─────────────────┘
                                                │
                                                ▼
                         ┌─────────────────────────────────────────────┐
                         │      Step 0: getPilotExamWindowStatus()     │
                         └──────────────────────┬──────────────────────┘
                                                │
                    ┌───────────────────────────┴───────────────────────────┐
                    ▼                                                       ▼
        [ Window ACTIVE = true ]                                [ Window ACTIVE = false ]
                    │                                                       │
                    ▼                                                       ▼
  ┌──────────────────────────────────┐                    ┌──────────────────────────────────┐
  │ Throws Error & Rejects Build:    │                    │ Proceed with Pipeline:           │
  │ CI_SUSPENDED_DURING_PILOT_EXAM_  │                    │ 0.1 License Verification         │
  │ WINDOW (HTTP 400 Bad Request)    │                    │ 1. Project Service Discovery     │
  │ Zero DB / BuildKit CPU overhead  │                    │ 2. Build Queue & Docker Spawn    │
  └──────────────────────────────────┘                    └──────────────────────────────────┘
```

---

## 2. Decision Matrix & Evaluation Hierarchy

When `getPilotExamWindowStatus()` evaluates whether builds are permitted, it applies checks in the following strict order of precedence:

| Priority | Check | Condition | Result | Freeze Mode |
| :---: | :--- | :--- | :--- | :--- |
| **1** | Master Bypass Env Var | `PILOT_EXAM_FREEZE="false"` or `"0"` | **Suspension Disabled (Builds Allowed)** | `DISABLED` |
| **2** | Manual Operator Freeze | `manualFreezeState.active === true` (and not expired) | **Suspension Active (Builds Blocked)** | `MANUAL` |
| **3** | Force Enable Env Var | `PILOT_EXAM_FREEZE="true"` or `"1"` | **Suspension Active (Builds Blocked)** | `ENV_OVERRIDE` |
| **4** | Schedule Enabled Toggle | `PILOT_EXAM_SCHEDULE_ENABLED="false"` or `manualFreezeState.scheduleEnabled === false` | **Schedule Bypassed (Builds Allowed)** | `NONE` |
| **5** | Automated Schedule Window | Date: Oct 19–25, 2026 **AND** Time: 08:30–15:30 IST | **Suspension Active (Builds Blocked)** | `SCHEDULE` |
| **6** | Normal Operations | Outside exam dates or hours | **Suspension Inactive (Builds Allowed)** | `NONE` |

---

## 3. Configuration & Toggles

### 3.1 Environment Variables

All variables are defined in `/var/www/vps-infra/.env` and mounted into `ci-api-prod` via `/var/www/vps-infra/docker-compose.yml`:

| Variable | Allowed Values | Default | Purpose |
| :--- | :--- | :--- | :--- |
| `PILOT_EXAM_SCHEDULE_ENABLED` | `false`, `true` | `false` | Controls whether the automated calendar window is enforced. Set to `false` to permit CI builds during exam hours. |
| `PILOT_EXAM_FREEZE` | `false`, `true`, `""` | `""` (empty) | Global override. Set to `false` for emergency master unfreeze (overrides manual & schedule). Set to `true` to lock CI builds immediately. |
| `PILOT_EXAM_START_DATE` | `YYYY-MM-DD` | `2026-10-19` | Operational window start date in IST calendar. |
| `PILOT_EXAM_END_DATE` | `YYYY-MM-DD` | `2026-10-25` | Operational window end date (inclusive) in IST calendar. |
| `PILOT_EXAM_DAILY_START_IST` | `HH:MM` (24h) | `08:30` | Daily operational window start time in IST. |
| `PILOT_EXAM_DAILY_END_IST` | `HH:MM` (24h) | `15:30` | Daily operational window end time in IST. |

---

### 3.2 How to Disable the Schedule Window (Allow Builds)

To disable the automated calendar schedule so that developers and automated pipelines can run builds during pilot dates:

1. Open `/var/www/vps-infra/.env` and ensure:
   ```ini
   PILOT_EXAM_SCHEDULE_ENABLED=false
   PILOT_EXAM_FREEZE=
   ```

2. Recreate or restart the `ci-api-prod` container:
   ```bash
   docker compose -f /var/www/vps-infra/docker-compose.yml --env-file /var/www/vps-infra/.env up -d ci-api-prod
   ```

3. Verify status:
   ```bash
   curl -s http://localhost:5051/api/ci/pilot-window/status
   ```
   **Expected Response:**
   ```json
   {
     "active": false,
     "freezeMode": "NONE",
     "reason": "Automated pilot exam schedule disabled via PILOT_EXAM_SCHEDULE_ENABLED=false; CI builds permitted",
     "window": {
       "startDate": "2026-10-19",
       "endDate": "2026-10-25",
       "dailyStartIst": "08:30",
       "dailyEndIst": "15:30",
       "enabled": false
     }
   }
   ```

---

### 3.3 How to Re-Enable the Schedule Window (Strict Suspension)

To re-enable strict host protection during pilot exams:

1. In `/var/www/vps-infra/.env`, set:
   ```ini
   PILOT_EXAM_SCHEDULE_ENABLED=true
   PILOT_EXAM_FREEZE=
   ```

2. Reload `ci-api-prod`:
   ```bash
   docker compose -f /var/www/vps-infra/docker-compose.yml --env-file /var/www/vps-infra/.env up -d ci-api-prod
   ```

---

### 3.4 How to Configure Custom Exam Dates and Operational Hours

For future pilot batches or semester exams with different dates or operating hours, configure them directly in `/var/www/vps-infra/.env`:

```ini
# /var/www/vps-infra/.env

# Enable calendar schedule enforcement
PILOT_EXAM_SCHEDULE_ENABLED=true
PILOT_EXAM_FREEZE=

# Define custom exam date span
PILOT_EXAM_START_DATE=2026-11-01
PILOT_EXAM_END_DATE=2026-11-15

# Define custom daily operating hours in IST (24h format HH:MM)
PILOT_EXAM_DAILY_START_IST=09:00
PILOT_EXAM_DAILY_END_IST=17:00
```

Apply changes:
```bash
docker compose -f /var/www/vps-infra/docker-compose.yml --env-file /var/www/vps-infra/.env up -d ci-api-prod
```

When queried via `GET /api/ci/pilot-window/status`, the returned `window` object will reflect the active configured dates:
```json
{
  "active": true,
  "freezeMode": "SCHEDULE",
  "reason": "Automated Pilot Exam Window Active (2026-11-01 09:00-17:00 IST)",
  "window": {
    "startDate": "2026-11-01",
    "endDate": "2026-11-15",
    "dailyStartIst": "09:00",
    "dailyEndIst": "17:00",
    "enabled": true
  }
}
```

---

## 4. REST API Endpoints & RBAC

The CI server exposes three dedicated endpoints under `/api/ci/pilot-window`:

### 4.1 `GET /api/ci/pilot-window/status`
* **Access:** Public read-only (unauthenticated).
* **Purpose:** Allows CI frontend UI, health dashboards, and deployment scripts to inspect whether builds are permitted before dispatching a queue request.

#### Example Request:
```bash
curl -s http://localhost:5051/api/ci/pilot-window/status
```

#### Example Response (When Blocked by Schedule):
```json
{
  "active": true,
  "freezeMode": "SCHEDULE",
  "reason": "Automated Pilot Exam Window Active (2026-10-19 08:30-15:30 IST)",
  "currentTimeIst": "2026-10-19T10:37:29.660Z",
  "currentTimeUtc": "2026-10-19T05:07:29.660Z",
  "window": {
    "startDate": "2026-10-19",
    "endDate": "2026-10-25",
    "dailyStartIst": "08:30",
    "dailyEndIst": "15:30",
    "enabled": true
  }
}
```

---

### 4.2 `POST /api/ci/pilot-window/freeze`
* **Access:** Authenticated. Requires `Admin`, `SuperAdmin`, or `DevOps` role token.
  * Unauthenticated callers receive `HTTP 401 Unauthorized`.
  * Unauthorized roles (e.g. `Viewer`, `Developer`) receive `HTTP 403 Forbidden`.
* **State Persistence:** Survives container restarts via `/var/www/vps-infra/volumes/ci-pilot-freeze.json`.

#### Request Payload:
```json
{
  "reason": "Host CPU reserved for State Board Live Exam Ingestion",
  "durationMinutes": 120,
  "scheduleEnabled": true
}
```

#### Example via cURL (with SuperAdmin JWT):
```bash
TOKEN="<SUPERADMIN_OR_DEVOPS_JWT>"

curl -s -X POST http://localhost:5051/api/ci/pilot-window/freeze \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Host CPU reserved for State Board Live Exam Ingestion",
    "durationMinutes": 120
  }'
```

#### Example Response:
```json
{
  "message": "Pilot exam freeze engaged successfully",
  "status": {
    "active": true,
    "freezeMode": "MANUAL",
    "reason": "Host CPU reserved for State Board Live Exam Ingestion",
    "expiresAt": "2026-10-19T07:29:10.619Z",
    "currentTimeUtc": "2026-10-19T05:29:10.619Z"
  },
  "operator": "Super Admin"
}
```

---

### 4.3 `POST /api/ci/pilot-window/unfreeze`
* **Access:** Authenticated (`Admin`, `SuperAdmin`, `DevOps`).
* **Purpose:** Immediately releases a manual freeze and optionally suppresses the automated schedule.

#### Request Payload:
```json
{
  "disableSchedule": true
}
```
*(Setting `"disableSchedule": true` dynamically disables the calendar schedule check without requiring a container restart).*

#### Example via cURL:
```bash
curl -s -X POST http://localhost:5051/api/ci/pilot-window/unfreeze \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"disableSchedule": true}'
```

#### Example Response:
```json
{
  "message": "Pilot exam freeze cleared",
  "status": {
    "active": false,
    "freezeMode": "NONE",
    "reason": "Automated pilot exam schedule disabled via PILOT_EXAM_SCHEDULE_ENABLED=false; CI builds permitted",
    "currentTimeIst": "2026-10-19T10:59:16.612Z",
    "currentTimeUtc": "2026-10-19T05:29:16.612Z",
    "window": {
      "startDate": "2026-10-19",
      "endDate": "2026-10-25",
      "dailyStartIst": "08:30",
      "dailyEndIst": "15:30",
      "enabled": false
    }
  },
  "operator": "Super Admin"
}
```

---

## 5. Troubleshooting & Diagnostics

### 5.1 Symptom: "Build Failed to Queue"
```text
CI_SUSPENDED_DURING_PILOT_EXAM_WINDOW: Builds are strictly suspended during the active pilot exam operational window (Automated Pilot Exam Window Active (2026-10-19 08:30-15:30 IST)). VPS CPU and RAM are reserved exclusively for live OMR ingestion and grading.
```

### 5.2 Resolution Checklist
1. **Check if you are within exam hours:**
   * Window: **08:30 to 15:30 IST** (03:00 to 10:00 UTC) between October 19 and October 25, 2026.
   * If the build is non-urgent, schedule it for **after 15:30 IST**.
2. **If urgent builds are needed right now:**
   * Set `PILOT_EXAM_SCHEDULE_ENABLED=false` in `/var/www/vps-infra/.env`.
   * Restart `ci-api-prod`: `docker compose -f /var/www/vps-infra/docker-compose.yml --env-file /var/www/vps-infra/.env up -d ci-api-prod`.
3. **Run Automated Self-Test & Evidence Generation:**
   ```bash
   bash /var/www/vps-infra/scripts/verify-ci-pilot-window.sh
   ```
   This script verifies:
   * Container code synchronization
   * Unit tests and RBAC enforcement (401 unauthenticated, 403 unauthorized, 200 authorized)
   * Freeze engagement and unfreeze lifecycle
   * Disk persistence across container restart
   * Generates audit evidence at [`/var/www/vps-infra/docs/audits/ci-pilot-window-evidence.json`](file:///var/www/vps-infra/docs/audits/ci-pilot-window-evidence.json)
