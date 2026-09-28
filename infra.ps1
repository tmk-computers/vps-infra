# ==============================================================================
# 🚀 VPS-INFRA UNIFIED CLI TOOL ('infra.ps1')
# ==============================================================================
# Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Command = "help",

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

$EnvPath = Join-Path $ScriptDir ".env"

# ANSI Color helpers
$ESC = [char]27
$C_GREEN  = "$ESC[0;32m"
$C_CYAN   = "$ESC[0;36m"
$C_YELLOW = "$ESC[1;33m"
$C_RED    = "$ESC[0;31m"
$C_BOLD   = "$ESC[1m"
$C_RESET  = "$ESC[0m"

function Show-Help() {
    Write-Host "${C_CYAN}${C_BOLD}🚀 VPS-Infra Unified CLI Tool (Windows)${C_RESET}"
    Write-Host "Usage: ${C_BOLD}infra <command> [options]${C_RESET}`n"
    Write-Host "Commands:"
    Write-Host "  ${C_GREEN}up, up --vps${C_RESET}       Deploy and start all core platform services (Traefik, DB, DevOps, CI)"
    Write-Host "  ${C_GREEN}down${C_RESET}               Stop all platform infrastructure services"
    Write-Host "  ${C_GREEN}restart${C_RESET}            Restart all platform infrastructure services"
    Write-Host "  ${C_GREEN}status, ps${C_RESET}         Show live health and container status"
    Write-Host "  ${C_GREEN}logs <service>${C_RESET}     Tail live logs (e.g. 'infra logs devops-api-prod', 'infra logs ci-api-prod')"
    Write-Host "  ${C_GREEN}backup${C_RESET}             Trigger immediate PostgreSQL database backup"
    Write-Host "  ${C_GREEN}help, -h, --help${C_RESET}   Show this help menu"
    Write-Host ""
}

switch ($Command.ToLower()) {
    "up" {
        Write-Host "${C_CYAN}▶ Starting VPS-Infra platform...${C_RESET}"
        $setupPs1 = Join-Path $ScriptDir "setup.ps1"
        if ($Arguments) {
            & $setupPs1 @Arguments
        } else {
            & $setupPs1
        }
    }

    "down" {
        Write-Host "${C_YELLOW}▶ Stopping VPS-Infra platform containers...${C_RESET}"
        $composeFiles = @(
            (Join-Path $ScriptDir "docker-compose.yml"),
            (Join-Path $ScriptDir "docker-registry\docker-compose.yml"),
            (Join-Path $ScriptDir "db\postgres\docker-compose.yml"),
            (Join-Path $ScriptDir "network\traefik\docker-compose.yml")
        )
        foreach ($cf in $composeFiles) {
            if (Test-Path -Path $cf) {
                if (Test-Path -Path $EnvPath) {
                    & docker compose -f $cf --env-file $EnvPath down 2>$null
                } else {
                    & docker compose -f $cf down 2>$null
                }
            }
        }
        Write-Host "${C_GREEN}✅ All platform services stopped.${C_RESET}"
    }

    "restart" {
        Write-Host "${C_CYAN}▶ Restarting VPS-Infra platform...${C_RESET}"
        & $PSCommandPath down
        & $PSCommandPath up
    }

    "status" {
        Write-Host ""
        Write-Host "${C_CYAN}${C_BOLD}📊 VPS-INFRA CONTAINER STATUS:${C_RESET}"
        $psOut = & docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>&1
        $filtered = $psOut | Where-Object { $_ -match "NAMES|devops|ci-|shared_|registry|traefik" }
        if ($filtered) {
            $filtered | ForEach-Object { Write-Host $_ }
        } else {
            $psOut | ForEach-Object { Write-Host $_ }
        }
        Write-Host ""
    }

    "ps" {
        Write-Host ""
        Write-Host "${C_CYAN}${C_BOLD}📊 VPS-INFRA CONTAINER STATUS:${C_RESET}"
        $psOut = & docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>&1
        $filtered = $psOut | Where-Object { $_ -match "NAMES|devops|ci-|shared_|registry|traefik" }
        if ($filtered) {
            $filtered | ForEach-Object { Write-Host $_ }
        } else {
            $psOut | ForEach-Object { Write-Host $_ }
        }
        Write-Host ""
    }

    "logs" {
        $svc = if ($Arguments -and $Arguments.Count -gt 0) { $Arguments[0] } else { "" }
        if (-not $svc) {
            Write-Host "${C_YELLOW}Please specify a container name (e.g. devops-api-prod, ci-api-prod, traefik, shared_postgres)${C_RESET}"
            exit 1
        }
        & docker logs -f --tail=100 $svc
    }

    "backup" {
        Write-Host "${C_CYAN}▶ Triggering automated backup for devops_prod...${C_RESET}"
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $backupDir = Join-Path $ScriptDir "volumes\db\postgres\backups"
        if (-not (Test-Path -Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        $backupFile = Join-Path $backupDir "devops_prod_${timestamp}.sql"
        & docker exec shared_postgres pg_dump -U postgres devops_prod > $backupFile
        Write-Host "${C_GREEN}✅ Backup saved to: $backupFile${C_RESET}"
    }

    "help" { Show-Help }
    "-h" { Show-Help }
    "--help" { Show-Help }
    "" { Show-Help }

    default {
        Write-Host "${C_RED}Unknown command: $Command${C_RESET}"
        Show-Help
        exit 1
    }
}
