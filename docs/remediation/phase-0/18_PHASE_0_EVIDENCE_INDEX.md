# 18 PHASE 0 FORENSIC EVIDENCE INDEX

**Document ID**: `REMED-P0-18`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Baseline Date**: 2026-09-29  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Executive Summary

This document indexes all executable commands, code anchors, AST parser outputs, and file references established as verifiable evidence during Phase 0 reconciliation.

---

## 2. Repository Git Baseline Evidence

| Repository | Command Line Executed | Captured Output / SHA | Evidence Significance |
| :--- | :--- | :--- | :--- |
| `vps-infra` | `git status; git rev-parse HEAD; git remote -v` | Branch: `main`, Clean tree, SHA: `780e8b4f152e039e9ee31ed46c71811e04947f7b` | Freezes current local and remote HEAD. |
| `vps-infra-server` | `git status; git rev-parse HEAD; git remote -v` | Branch: `main`, Clean tree, SHA: `36354a32884fd0c03470d2b3f5333776f7aed6c9` | Freezes current local and remote HEAD. |
| `vps-infra` | `git log --oneline eab8df6..780e8b4` | 6 commits ahead of historical audit baseline | Proves post-audit maintenance and AMS doc changes. |
| `vps-infra-server` | `git log --oneline a1f4a51..36354a3` | 10 commits ahead of historical audit baseline | Proves maintenance mode, AMS engine, upgrade runner additions. |

---

## 3. Forensic Code Anchors by Key Discovery

### 3.1 Maintenance Mode Schema Migration Gap (MR-34)
- **Entities**:
  - [`Product.cs:15-23`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/Product.cs#L15-L23): 8 persistent maintenance fields.
  - [`ProjectService.cs:36-40`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/Entities/ProjectService.cs#L36-L40): 5 persistent maintenance fields.
- **Missing Migrations**:
  - [`devops-manager/api/Migrations/`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Migrations/): Directory inspection confirms latest migration is `20260831080000_AddDatabaseServerToProjectService.cs`. Zero maintenance migrations exist.
- **Seeder DDL Check**:
  - [`DataSeeder.cs:48-56`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Data/DataSeeder.cs#L48-L56): Raw `ALTER TABLE` statements check legacy fields; maintenance fields completely absent.
- **Test In-Memory Bypass**:
  - [`MaintenanceServiceTests.cs:32`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/DevopsPanel.Tests/MaintenanceServiceTests.cs#L32): `.UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())`.
  - [`MaintenanceControllerIntegrationTests.cs:39`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/DevopsPanel.Tests/MaintenanceControllerIntegrationTests.cs#L39): `.UseInMemoryDatabase(...)`. Proves real Postgres DDL was never tested.

### 3.2 Maintenance Mode Service Isolation Defect (MR-35)
- **Global Regex Replacement**:
  - [`MaintenanceService.cs:268`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MaintenanceService.cs#L268): `Regex.Replace(content, @"(SystemStatus__IsMaintenance\s*=\s*)[^\r\n]*", ...)` replaces across entire compose file without service scoping.
- **Compose Block Injection**:
  - [`MaintenanceService.cs:278`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MaintenanceService.cs#L278): `Regex.Replace(content, @"^([ \t]*)environment:\s*$", ...)` matches every service environment key.
- **Swallowed Error in Docker Execution**:
  - [`MaintenanceService.cs:326`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MaintenanceService.cs#L326): `catch (Exception ex) { _logger.LogWarning(...); }` logs warning but returns success to caller.

### 3.3 AMS Authentication Breakdown (MR-36)
- **Anonymous Exposure**:
  - [`ci-server/api/server.js:623,634,645`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/server.js#L623): `app.get([...], optionalAuth, ...)` allows unauthenticated callers to read full architectural breakdown.
- **Unauthenticated C# Proxy Request**:
  - [`ProductController.cs:231`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers/ProductController.cs#L231): `client.PostAsync($"{ciUrl.TrimEnd('/')}/api/ci/modernization/calculate/{id}", null)` passes no Bearer token.
  - [`ci-server/api/server.js:662`](file:///d:/company/products/vps-infra/vps-infra-server/ci-server/api/server.js#L662): `app.post([...], authenticateToken, ...)` rejects with HTTP 401 Unauthorized.

### 3.4 Upgrade Health Check Absent in Execution Path (MR-19)
- **Runner Invocation**:
  - [`SystemController.cs:260-268`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Controllers/SystemController.cs#L260-L268): `docker run -d --name vps-infra-upgrade-runner ... ghcr.io/tmk-computers/tmk-devops-api:latest`.
- **Absent Health Verification Section in Script**:
  - [`vps-infra/scripts/upgrade-client.sh:170-178`](file:///d:/company/products/vps-infra/vps-infra/scripts/upgrade-client.sh#L170-L178):
    ```bash
    CURRENT_STEP="Verifying service health"
    echo "▶ $CURRENT_STEP..."
    update_status "IN_PROGRESS" "Verifying service health..." "$CURRENT_STEP"
    NEW_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo "latest")"
    update_status "SUCCESS" "Platform successfully upgraded to version $NEW_COMMIT." "Completed"
    ```
    Proves zero health verification commands exist.

### 3.5 Windows IIS Agent Fatal AST Error (MR-22, F09, DEF-28)
- **PowerShell AST Parse Output**:
  - Execution: `[System.Management.Automation.Language.Parser]::ParseFile(".../vps-infra/scripts/tmk-iis-agent.ps1", [ref]$tokens, [ref]$errors)`
  - Output:
    - `Message: The Try statement is missing its Catch or Finally block.`
    - `Message: Unexpected token '}' in expression or statement.`
  - Contrasting Server Copy: `vps-infra-server/scripts/tmk-iis-agent.ps1` parses with 0 errors.

### 3.6 Unverified IIS Deployment Success (MR-22, F10, DEF-31)
- **Health Probe Swallowed**:
  - [`vps-infra-server/scripts/tmk-iis-agent.ps1:290-301`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1#L290-L301):
    Probe error caught in catch block at lines 293–295, logged as `"Notice: Health probe returned: $_ (site may still be warming up)"`, then immediately executes at lines 298–301:
    `Send-JsonResponse $response 200 @{ Success = $true }`.

### 3.7 Database Ports Exposed to WAN (MR-06, F07, DEF-03)
- **Compose Port Mappings**:
  - [`db/postgres/docker-compose.yml:19,50`](file:///d:/company/products/vps-infra/vps-infra/db/postgres/docker-compose.yml#L19): `"5432:5432"` and `"5050:80"` bind to all interfaces (`0.0.0.0`).
  - [`db/mariadb/docker-compose.yml:16,38`](file:///d:/company/products/vps-infra/vps-infra/db/mariadb/docker-compose.yml#L16): `"3306:3306"` and `"8082:80"` bind to all interfaces (`0.0.0.0`).

### 3.8 Ghost Redis Manifest (Audit Reconciled)
- **Search Execution**: `Get-ChildItem -Path "vps-infra" -Filter "*redis*" -Recurse`
- **Output**: 0 files returned. Proves Antigravity audit assertion of implemented `db/redis/docker-compose.yml` was incorrect.
