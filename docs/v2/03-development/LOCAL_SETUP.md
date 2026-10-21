# Infrastructure Local Development & Shell Testing

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server c458c831711ba2e82a382719f76c98551d7d5a70; infra44a5d6a32bf59f50e7c13b663dbd22bac31eb53d. **Last verified:**2026-10-20. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-DEV-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Audit Date:** 2026-10-20  
> **Related Documents:** [INDEX.md](../INDEX.md), [CLI_AND_ORCHESTRATION.md](../04-modules/CLI_AND_ORCHESTRATION.md)

---

## 1. Local Development Prerequisites

To test and modify `vps-infra` scripts locally:
- **POSIX Shell:** Bash 5.0+ or Zsh.
- **PowerShell:** PowerShell 7+ (`pwsh`) for testing Windows scripts (`infra.ps1`, `setup.ps1`).
- **ShellCheck:** Linter for shell scripts (`shellcheck`).
- **Docker Engine:** Docker Desktop or Docker CE with Compose v2.

---

## 2. Shell Script Linting & Verification

Before committing changes to any shell or PowerShell scripts, run automated static analysis:

```bash
# 1. Lint Linux Shell Scripts
shellcheck setup.sh
shellcheck infra
shellcheck scripts/*.sh

# 2. Test PowerShell Syntax from POSIX / Bash (single-quoted to prevent variable interpolation)
pwsh -Command '$tokens = $null; $errors = $null; [System.Management.Automation.Language.Parser]::ParseFile("infra.ps1", [ref]$tokens, [ref]$errors); if ($errors) { throw ($errors | Out-String) } else { Write-Host "infra.ps1: Valid" }'
pwsh -Command '$tokens = $null; $errors = $null; [System.Management.Automation.Language.Parser]::ParseFile("setup.ps1", [ref]$tokens, [ref]$errors); if ($errors) { throw ($errors | Out-String) } else { Write-Host "setup.ps1: Valid" }'
```

For native PowerShell execution:
```powershell
# In PowerShell:
$tokens = $null; $errors = $null; [System.Management.Automation.Language.Parser]::ParseFile("infra.ps1", [ref]$tokens, [ref]$errors); if ($errors) { throw ($errors | Out-String) } else { Write-Host "infra.ps1: Valid" }
$tokens = $null; $errors = $null; [System.Management.Automation.Language.Parser]::ParseFile("setup.ps1", [ref]$tokens, [ref]$errors); if ($errors) { throw ($errors | Out-String) } else { Write-Host "setup.ps1: Valid" }
```

---

## 3. Testing Docker Compose Locally (Disposable Test Only)

From the infra repository root, use source inspection or a syntax-only Compose check with explicit dummy values. Do not copy over an existing .env or launch the live host stack as a parser test.

```bash
CI_SECRET=example-validation-only JWT_SECRET_KEY=example-validation-only-at-least-32-characters docker compose --profile all config --services
```

This lists configuration services only; it does not establish connectivity, pgvector, valid credentials or disposable mounts. The root does not launch supporting PostgreSQL or runtime.

**GH01 source limitation:** `Database:AutoMigrateOnStartup` gates only Program.cs's migration branch. Program still invokes DataSeeder.SeedData. Seeder independently checks pending migrations and calls MigrateAsync, catches/logs that migration exception, and attempts raw DDL independently. Therefore false does not guarantee zero schema mutation. `Database__SkipAutoMigration` is not consumed. The historical Gate H fresh/upgrade rehearsals failed23502 in the reconciliation chain; that is not proof every arbitrary empty DB always fails at the same statement or that Seeder's caught exception directly escapes. Startup/schema safety remains blocked pending a separately approved repair. No healthy API startup or live migration is required to validate this documentation.
