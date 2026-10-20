# Infrastructure Local Development & Shell Testing

> **Document ID:** `V2-INFRA-DEV-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Setup Guide  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [INDEX.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/INDEX.md), [CLI_AND_ORCHESTRATION.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/04-modules/CLI_AND_ORCHESTRATION.md)

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

# 2. Test PowerShell Syntax (on Windows or via pwsh)
pwsh -Command "Test-ScriptFileInfo setup.ps1; Test-ScriptFileInfo infra.ps1"
```

---

## 3. Testing Docker Compose Locally

You can test the entire platform compose stack locally using Docker Desktop:

```bash
# 1. Create a local test .env file
cp .env.example .env

# 2. Validate docker-compose.yml syntax
docker compose config

# 3. Launch the platform in detached mode
docker compose up -d

# 4. Check service status using the infra CLI
./infra status
```
