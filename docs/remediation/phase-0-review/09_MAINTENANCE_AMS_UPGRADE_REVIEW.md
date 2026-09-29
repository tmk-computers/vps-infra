# 09 MAINTENANCE MODE, AMS & UPGRADE FORENSIC INDEPENDENT REVIEW

**Document ID**: `REMED-P0-REV-09`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Maintenance Mode Forensic Audit (MR-34 & MR-35)

### 1.1 MR-34: Schema Migration Gap & Technical Failure Mode (P0)

In commit `4c40800`, Centralized Maintenance Mode introduced 13 new properties across two database entities:
- **`Product.cs:15-22`**: `IsMaintenance`, `MaintenanceMessage`, `MaintenanceVersion`, `MinSupportedVersion`, `ShowMaintenanceForMobile`, `ShowMaintenanceForWeb`, `MaintenanceStartedAt`, `MaintenanceEstimatedEndAt`.
- **`ProjectService.cs:36-40`**: `IsMaintenanceOverride`, `IsMaintenance`, `MaintenanceMessage`, `ShowMaintenanceForMobile`, `ShowMaintenanceForWeb`.

#### Forensic Database Investigation:
1. **Migration Inspection**: The Reviewer listed all files in `devops-manager/api/Migrations/`. The latest migration is `20260831080000_AddDatabaseServerToProjectService.cs` from August 31, 2026. **Zero EF Core migrations were created for the maintenance fields.**
2. **DataSeeder Inspection**: In `DataSeeder.cs:47-167`, the raw SQL execution block contains DDL for `Projects`, `ProjectServices`, and `Ai*` tables, but **omits all 13 maintenance columns**.
3. **Unit Test Masking**: Automated test suites in `DevopsPanel.Tests/` passed exclusively because they configure `.UseInMemoryDatabase()`, which does not enforce relational schema DDL or column presence.

#### Precise Technical Failure Mode (Correction of Developer Claim R1-01):
The Developer's documentation claimed: *"PostgreSQL will crash" / "PostgreSQL instances crash on query."*  
The Reviewer's independent forensic analysis clarifies the exact operational failure path:
- **The PostgreSQL Database Daemon DOES NOT Crash**: The server daemon remains operational and healthy.
- **Application Startup Behavior**: `DataSeeder.cs` runs `clientService.InitializeClient(null)`, which queries `Clients`, not `Products`. Application startup proceeds without an immediate fatal crash.
- **Query & Transaction Failure**: The moment any controller endpoint, deployment check, or UI request queries `Products` or `ProjectServices` via Entity Framework Core (e.g. `_dbContext.Products.ToListAsync()`), EF Core generates a `SELECT` statement requesting the missing columns.
- **Exact PostgreSQL Error**: PostgreSQL returns:  
  `Npgsql.PostgresException (0x80004005): 42703: column p.IsMaintenance does not exist`
- **User Impact**: The ASP.NET Core API throws an unhandled `DbUpdateException` / `PostgresException`, returning **HTTP 500 Internal Server Error** on all product and service management endpoints.

---

### 1.2 MR-35: Docker Compose Regex Contamination Proof (P0)

In [`MaintenanceService.cs:255-295`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MaintenanceService.cs#L255-L295), the Developer implemented `UpdateDockerComposeMaintenanceBlockAsync`:

```csharp
if (content.Contains("SystemStatus__IsMaintenance"))
{
    // Global regex replace replaces EVERY occurrence in the entire file:
    content = Regex.Replace(content, @"(SystemStatus__IsMaintenance\s*=\s*)[^\r\n]*", m => $"{m.Groups[1].Value}{isMaintenanceStr}");
    ...
}
else
{
    // Injects under EVERY 'environment:' section in the file:
    content = Regex.Replace(content, @"^([ \t]*)environment:\s*$", match =>
    {
        var indent = match.Groups[1].Value + "      ";
        var block = $"{match.Value}\n{indent}# --- Maintenance Mode Config ---\n{indent}- SystemStatus__IsMaintenance={isMaintenanceStr}\n...";
        return block;
    }, RegexOptions.Multiline);
}
```

#### Reproducible Failure Demonstration:
Consider a standard multi-service `docker-compose.yml`:
```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
  api:
    image: mycompany/api:1.0
    environment:
      ASPNETCORE_ENVIRONMENT: Production
```

When an operator toggles maintenance mode for a single service (`api`), `SetServiceMaintenanceModeAsync` calls `UpdateDockerComposeMaintenanceBlockAsync`:
1. `Regex.Replace` with multiline `^([ \t]*)environment:\s*$` matches **both** `db` and `api`.
2. It injects `- SystemStatus__IsMaintenance=true` into the `db` (PostgreSQL) container environment as well as the `api` container environment!
3. When `content.Contains("SystemStatus__IsMaintenance")` is later evaluated, `Regex.Replace` without a service boundary mutates every service in the file.
4. **Conclusion**: Service isolation is completely compromised. An AST-aware YAML parser (e.g. `YamlDotNet`) must replace raw string regex manipulation.

---

## 2. Application Modernization Score (AMS) Forensic Audit (MR-36 & MR-37)

### 2.1 MR-36: API Authorization & Proxy Authentication Breakdown (P1)

In commit `fd9bf54` and `f4fec2b`, AMS was introduced across `ci-server` and `devops-manager`:

#### 1. Anonymous Architecture Data Disclosure:
- In `ci-server/api/server.js:623-645`, the endpoints:
  - `GET /api/ci/modernization/summary`
  - `GET /api/ci/modernization/products`
  - `GET /api/ci/modernization/products/:productId`
- Are configured with `optionalAuth` middleware ([`auth.js:104`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/auth.js#L104)).
- If no token is passed, `optionalAuth` calls `next()`.
- **Exposed Data**: Any unauthenticated network caller can dump the complete product directory hierarchy, deployable unit types, detected framework versions, test pattern results, and remediation advice.

#### 2. Internal Recalculation Failure (HTTP 401 Unauthorized):
- In `ci-server/api/server.js:662`, the recalculation endpoint requires strict authentication:  
  `POST /api/ci/modernization/calculate/:productId -> authenticateToken`
- However, in [`ProductController.cs:228-238`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers/ProductController.cs#L228-L238):
  ```csharp
  using var client = _httpClientFactory?.CreateClient() ?? new HttpClient();
  var response = await client.PostAsync($"{ciUrl.TrimEnd('/')}/api/ci/modernization/calculate/{id}", null);
  ```
  The C# backend passes **zero `Authorization` header** or Bearer token!
- `authenticateToken` in `auth.js:46` immediately rejects the call:  
  `HTTP 401 Unauthorized: Authentication required. Please provide a valid Bearer token.`
- Line 238 of `ProductController.cs` returns:  
  `StatusCode(401, new { message = "Failed to recalculate modernization score." })`
- **Result**: The UI button "Recalculate Modernization Score" fails 100% of the time.

---

### 2.2 MR-37: AMS Semantic Scope vs. Commercial Reality (P2 / Gate A Blocker)

The Reviewer audited actual user-visible text in `Product.tsx`, `APPLICATION_MODERNIZATION_SCORE_GUIDE.md`, and `modernization-engine.js`:

1. **What AMS Actually Measures**:
   - `modernization-engine.js` runs shallow string and regex searches (`dirHasPattern`, `.csproj` text checks) for keyword presence (e.g. `UseHealthChecks`, `Serilog`, `Polly`, `AddRateLimiter`, `xunit`).
   - It executes **zero automated test suites**, runs **zero runtime stability benchmarks**, and validates **zero container resource limits**.
2. **Actual User-Visible Text in UI**:
   - `Product.tsx:652`: `🏆 Application Modernization Score (AMS): {selectedAmsProduct?.name}`
   - `Product.tsx:681`: `Enterprise Architectural Modernization Assessment`
   - `Product.tsx:307`: `title="Click to view full architecture & modernization breakdown"`
3. **Truthfulness Evaluation**:
   - While the UI uses the phrase "Architectural Modernization Assessment" rather than explicitly stating "Production Readiness", Dimension 2 is titled *"Test Automation & Quality Gates"* and Dimension 3 is titled *"Cross-Cutting Concerns & Resilience"*.
   - Awarding points for resilience and quality based purely on whether a library name appears in a `.csproj` or `package.json` misleadingly implies operational stability.
   - **Remediation**: Clarify in UI and docs that AMS is a static architectural linting tool, completely independent from runtime production readiness.

---

## 3. Platform Upgrade Subsystem Forensic Audit (MR-19)

The Reviewer audited the platform upgrade flow across `SystemController.cs`, `PlatformUpgradeCard.tsx`, and `scripts/upgrade-client.sh`:

1. **Decoupled Supervisor Container**:
   - In `SystemController.cs:257-268`, when an operator triggers an upgrade from the UI, the API launches a detached container:  
     `docker run -d --name vps-infra-upgrade-runner --rm -v /var/run/docker.sock:/var/run/docker.sock -v /var/www:/var/www ...`
   - This ensures the supervisor process survives when `devops-api-prod` restarts.
2. **Defects in `upgrade-client.sh`**:
   - **Destructive Git Reset**: Line 147 executes `git reset --hard origin/main`. Any local configuration adjustments or untracked operational fixes are silently wiped.
   - **No Pre-Upgrade Database Snapshot**: If the updated application contains new migrations that fail or corrupt the database, there is no pre-upgrade backup to restore from.
   - **Execution of Setup**: Runs `bash setup.sh </dev/null`.
   - **Precise Evaluation of Health Verification (R2-01)**:
     Lines 170-178 state:
     ```bash
     CURRENT_STEP="Verifying service health"
     echo "▶ $CURRENT_STEP..."
     update_status "IN_PROGRESS" "Verifying service health..." "$CURRENT_STEP"
     NEW_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo "latest")"
     echo "✅ Upgrade completed successfully to commit $NEW_COMMIT."
     update_status "SUCCESS" "Platform successfully upgraded to version $NEW_COMMIT." "Completed"
     exit 0
     ```
     - **Nature of Verification**: **Completely absent in execution**. Zero commands (`curl`, `docker ps`, HTTP probes) are executed.
     - **Telemetry Reality**: Status is **falsely reported as successful**.
     - **Rollback Reality**: Zero automated rollback exists. If `setup.sh` breaks the API, the system remains offline and requires manual SSH intervention.
