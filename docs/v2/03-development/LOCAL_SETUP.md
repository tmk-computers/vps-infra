# Infrastructure Local Development & Shell Testing

> **Document ID:** `V2-INFRA-DEV-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Setup Guide  
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

# 2. Test PowerShell Syntax (via PowerShell Language Parser)
pwsh -Command "$null = [System.Management.Automation.Language.Parser]::ParseFile('setup.ps1', [ref]$null, [ref]$e); if ($e) { throw $e }; $null = [System.Management.Automation.Language.Parser]::ParseFile('infra.ps1', [ref]$null, [ref]$e); if ($e) { throw $e }"
```

---

## 3. Testing Docker Compose Locally (Disposable Test Only)

You can validate the compose stack locally using Docker Desktop or Docker CE:

```bash
# 1. Create a local test .env file
cp .env.example .env

# 2. Validate docker-compose.yml syntax
docker compose config

# 3. Launch disposable test containers
docker compose up -d

# 4. Check service status using the infra CLI
./infra status
```

> [!WARNING]
> **Startup Limitation (GH01):** On a fresh, un-migrated database, the `devops-api-prod` container will encounter an uncaught exception during startup (`SQLSTATE 23502: not-null constraint violation on AiAgents.Slug`). Production deployments remain on conditional hold until Phase GH-1 schema remediation is merged.
