# 11 APPLICATION MODERNIZATION SCORE (AMS) FORENSIC REVIEW & CURRENT-STATE REPORT

**Document ID**: `REMED-P0-11`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Baseline Date**: 2026-09-29  
**Target Master IDs**: **MR-36**, **MR-37**  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Executive Summary

In commit `fd9bf54` ("feat(ci): implement Application Modernization Score (AMS) engine, REST APIs, and dashboard") and commit `f4fec2b`, the Application Modernization Score (AMS) subsystem was introduced into `ci-server` and `devops-manager`.

This forensic review determines:
1. **MR-36 (Authentication Breakdown & Anonymous Exposure — Pilot Blocker)**:
   - In `ci-server/api/server.js`, AMS read endpoints use `optionalAuth`, allowing unauthenticated external callers to access complete architectural maps and compliance data.
   - In `ProductController.cs`, `RecalculateProductModernization()` calls CI server without a Bearer token, causing the calculation to fail with HTTP 401 Unauthorized because CI's `/calculate/:productId` requires `authenticateToken`.
2. **MR-37 (Semantics & Commercial Truthfulness — Pilot Blocker)**:
   - AMS is calculated entirely via static directory checks and shallow regex matching on source files (`dirHasPattern`, `.csproj`, `tests/`).
   - It performs ZERO dynamic test execution, ZERO build verification, and ZERO runtime health checks.
   - It must be formally labeled and governed as **static architectural pattern analysis**, NEVER as proof of production readiness or release qualification.

---

## 2. Technical Investigation by Architectural Dimension

### 2.1 How AMS is Calculated & Source Data Used
- **Engine Source**: [`ci-server/api/modernization-engine.js`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/modernization-engine.js)
- **Source Data**:
  - Scans directories under `/var/www/vps-infra/code/` or projects defined in database.
  - Inspects file existence (e.g. `pubspec.yaml`, `build.gradle.kts`, `Dockerfile`, `package.json`).
  - Executes regex pattern matches via `dirHasPattern(dirPath, regex, extensions, maxDepth = 6)`.
- **The 5 Evaluation Dimensions (100 Points Total)**:
  1. *Framework Currency (20 pts)*: Looks for strings like `net10` (20 pts), `net9` (18 pts), `net8` (15 pts), `Flutter 3.24+` in `.csproj` or `pubspec.yaml`.
  2. *Test Automation & Quality Gates (25 pts)*: Checks if a folder exists matching `tests/` or files containing `xunit` or `jest` (+10 pts). Reads `coverage_percentage` column from DB (+9 pts).
  3. *Cross-Cutting Concerns (25 pts)*: Checks regex for `MaintenanceModeMiddleware` (+5), `/health` (+5), `ILogger` (+5), `ClaimsPrincipal` (+5), `ProblemDetails` (+5).
  4. *Containerization & 12-Factor Hygiene (15 pts)*: Checks for `Dockerfile` and `mem_limit` in compose.
  5. *Modern Tooling & Code Quality (15 pts)*: Checks for `.editorconfig`, `eslint`, `prettier`.
- **Forensic Truth**: No tests are executed during AMS calculation. A project with broken, non-compiling C# code and crashing containers can receive a score of **95/100 (Grade A+)** simply by having modern `.csproj` tags, a dummy test folder, and a Dockerfile.

### 2.2 API Authorization & Authentication Vulnerabilities (MR-36)
- **In `ci-server/api/server.js`**:
  ```javascript
  // Lines 623, 634, 645:
  app.get(['/api/ci/modernization/summary', ...], optionalAuth, async (req, res) => { ... });
  app.get(['/api/ci/modernization/products', ...], optionalAuth, async (req, res) => { ... });
  app.get(['/api/ci/modernization/products/:productId', ...], optionalAuth, async (req, res) => { ... });
  ```
  `optionalAuth` allows callers with no Authorization header to retrieve full product lists, internal microservice names, and architectural summaries.
- **In `devops-manager/api/Controllers/ProductController.cs`**:
  ```csharp
  // Line 231 in ProductController.cs:
  var response = await client.PostAsync($"{ciUrl.TrimEnd('/')}/api/ci/modernization/calculate/{id}", null);
  ```
  `ProductController` creates an unauthenticated `HttpClient` and invokes `/api/ci/modernization/calculate/{id}`.
  However, `ci-server/api/server.js` line 662 specifies:
  ```javascript
  app.post(['/api/ci/modernization/calculate/:productId', ...], authenticateToken, async (req, res) => { ... });
  ```
  `authenticateToken` requires a valid Bearer token. Because `ProductController` sends no token, `ci-server` returns **HTTP 401 Unauthorized (`Missing token`)**. The C# controller logs an error and returns HTTP 401/500 to the UI. The recalculation flow is completely broken in production.

### 2.3 Persistence & Recalculation Flow
- **Persistence**: Table `ci_modernization_scores` in PostgreSQL, initialized by `ci-server/api/db.js:74`.
- **Recalculation**: Supposed to be triggered on new CI build completions or manually via UI modal in `Product.tsx`. Broken by the authentication mismatch noted above.

### 2.4 Documentation & Marketing Claims vs. Engineering Truth (MR-37)
- **Documentation**: [`vps-infra/docs/03-OPERATIONS-AND-DEVOPS/APPLICATION_MODERNIZATION_SCORE_GUIDE.md`](file:///d:/company/products/vps-infra/vps-infra/docs/03-OPERATIONS-AND-DEVOPS/APPLICATION_MODERNIZATION_SCORE_GUIDE.md) and UI cards describe AMS as:
  `"Automated, quantitative architectural governance across all enterprise products... Verified Code Coverage Gate... 100-point rubric"`.
- **Required Commercial Position**:
  - AMS is a **developer productivity and architecture guidance metric**.
  - It is **NOT production readiness proof**.
  - It does NOT replace Gate A functional, security, or DR qualification.

---

## 3. Required Remediation Specifications (Phase 1 & Phase 2)

1. **For MR-36 (Phase 1)**:
   - Change `optionalAuth` to `authenticateToken` on all AMS routes in `ci-server/api/server.js`.
   - In `ProductController.cs`, inject service-to-service JWT token generator or forward caller's Bearer token in `HttpClient` requests to `ci-server`.
   - Add integration tests verifying that anonymous calls are rejected (401) and authenticated recalculation succeeds (200).
2. **For MR-37 (Phase 1)**:
   - Update documentation and UI headers in `Product.tsx` and `ModernizationDashboard.tsx`:
     Change label from `"Production Readiness"` / `"Health Score"` to **`"Static Architectural Modernization"`**.
   - Explicitly document that AMS evaluates static heuristics, while deployment safety is governed independently by the Deployment State Machine (MR-10).
