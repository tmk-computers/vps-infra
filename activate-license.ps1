# ==============================================================================
# 🔑 VPS-INFRA: 1-CLICK AUTOMATED LICENSE ACTIVATOR (WINDOWS POWERSHELL)
# ==============================================================================
# Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$LicenseKey = ""
)

$ErrorActionPreference = 'Stop'

# ANSI Color formatting
$ESC = [char]27
$C_GREEN  = "$ESC[0;32m"
$C_CYAN   = "$ESC[0;36m"
$C_YELLOW = "$ESC[1;33m"
$C_RED    = "$ESC[0;31m"
$C_BOLD   = "$ESC[1m"
$C_RESET  = "$ESC[0m"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

Write-Host "${C_CYAN}${C_BOLD}"
Write-Host "======================================================================"
Write-Host "   🔑 VPS-INFRA: AUTOMATED ENTERPRISE LICENSE ACTIVATOR"
Write-Host "======================================================================"
Write-Host "${C_RESET}"

# 1. Retrieve License Key (from argument or interactive prompt)
if (-not $LicenseKey) {
    Write-Host "${C_YELLOW}👉 Please paste your TMK_LICENSE_KEY token below and press ENTER:${C_RESET}"
    $LicenseKey = Read-Host "Token"
}

$LicenseKey = $LicenseKey.Trim(@(' ', '"', "'"))

if (-not $LicenseKey) {
    Write-Host "${C_RED}❌ Error: No license key provided. Activation aborted.${C_RESET}"
    exit 1
}

# 2. Secure Volumes and License File Storage
Write-Host "`n${C_CYAN}▶ Step 1: Securing volumes and license file storage...${C_RESET}"
$volDir = Join-Path $ScriptDir "volumes"
if (-not (Test-Path -Path $volDir)) {
    New-Item -ItemType Directory -Path $volDir -Force | Out-Null
}

$licFile = Join-Path $volDir "license.key"
if (Test-Path -Path $licFile -PathType Container) {
    Write-Host "${C_YELLOW}⚠️  Detected license.key was created as a directory. Converting to file...${C_RESET}"
    Remove-Item -Path $licFile -Recurse -Force
}

Set-Content -Path $licFile -Value $LicenseKey -Encoding UTF8
Write-Host "${C_GREEN}✅ License key saved to: $licFile${C_RESET}"

# 3. Synchronize Configuration in .env
Write-Host "`n${C_CYAN}▶ Step 2: Synchronizing configuration in .env...${C_RESET}"
$envPath = Join-Path $ScriptDir ".env"
if (Test-Path -Path $envPath) {
    $lines = Get-Content -Path $envPath
    $updated = $false
    $newLines = foreach ($line in $lines) {
        if ($line -match "^\s*TMK_LICENSE_KEY=") {
            "TMK_LICENSE_KEY=`"${LicenseKey}`""
            $updated = $true
        } else {
            $line
        }
    }
    if (-not $updated) {
        $newLines += "TMK_LICENSE_KEY=`"${LicenseKey}`""
    }
    $newLines | Set-Content -Path $envPath -Encoding UTF8
    Write-Host "${C_GREEN}✅ Updated TMK_LICENSE_KEY in .env${C_RESET}"
}

# 4. Refresh Services
Write-Host "`n${C_CYAN}▶ Step 3: Refreshing platform services...${C_RESET}"
$mainCompose = Join-Path $ScriptDir "docker-compose.yml"
$uatCompose  = Join-Path $ScriptDir "docker-compose.uat.yml"
$composeFile = if (Test-Path -Path $mainCompose) { $mainCompose } else { $uatCompose }

if (Test-Path -Path $composeFile) {
    try {
        $dockerCheck = & docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   • Restarting devops-api-prod and ci-api-prod..."
            & docker compose -f $composeFile --env-file $envPath up -d devops-api-prod ci-api-prod 2>$null
            Write-Host "${C_GREEN}✅ Platform services restarted with active license.${C_RESET}"
        } else {
            Write-Host "${C_YELLOW}⚠️ Docker daemon not accessible; updated configuration will take effect on next start.${C_RESET}"
        }
    } catch {
        Write-Host "${C_YELLOW}⚠️ Skipping container reload (Docker daemon offline).${C_RESET}"
    }
}

Write-Host ""
Write-Host "${C_GREEN}${C_BOLD}======================================================================${C_RESET}"
Write-Host "${C_GREEN}${C_BOLD}   🎉 ENTERPRISE LICENSE ACTIVATED SUCCESSFULLY!${C_RESET}"
Write-Host "${C_GREEN}${C_BOLD}======================================================================${C_RESET}"
Write-Host "Visit your DevOps Manager panel to confirm your subscription status."
Write-Host ""
