# ==============================================================================
# 🚀 VPS-INFRA: ZERO-TOUCH ENTERPRISE RUNTIME DEPLOYMENT SCRIPT (POWERSHELL)
# ==============================================================================
# Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+
[CmdletBinding()]
param(
    [string]$Mode = "",
    [string]$DeploymentMode = "",
    [string]$License = "",
    [string]$Tag = "",
    [string]$Domain = "",
    [switch]$Yes,
    [switch]$Force,
    [string]$RegistryType = "",
    [string]$RegistryHost = "",
    [string]$RegistryUser = "",
    [string]$RegistryPass = "",
    [string]$SyncMode = "",
    [string]$CiSecret = "",
    [int]$HttpPort = 0,
    [int]$HttpsPort = 0
)

$ErrorActionPreference = 'Stop'

# ANSI Color helpers (compatible with Win10/Server 2019+ and PS 5.1)
$ESC = [char]27
$C_GREEN  = "$ESC[0;32m"
$C_CYAN   = "$ESC[0;36m"
$C_YELLOW = "$ESC[1;33m"
$C_RED    = "$ESC[0;31m"
$C_BOLD   = "$ESC[1m"
$C_RESET  = "$ESC[0m"

function Write-Info([string]$msg)    { Write-Host "${C_CYAN}${msg}${C_RESET}" }
function Write-Success([string]$msg) { Write-Host "${C_GREEN}${msg}${C_RESET}" }
function Write-Warn([string]$msg)    { Write-Host "${C_YELLOW}${msg}${C_RESET}" }
function Write-Err([string]$msg)     { Write-Host "${C_RED}${msg}${C_RESET}" }

Write-Host "${C_CYAN}${C_BOLD}"
Write-Host "======================================================================"
Write-Host "   🚀 VPS-INFRA: MANAGED DEVOPS & CI/CD RUNTIME SETUP (WINDOWS)"
Write-Host "======================================================================"
Write-Host "${C_RESET}"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

# ------------------------------------------------------------------------------
# 1. Check Docker & Docker Compose
# ------------------------------------------------------------------------------
Write-Info "▶ Checking Docker prerequisites..."

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Err "❌ Docker CLI is not installed or not found in system PATH."
    Write-Host ""
    Write-Host "${C_YELLOW}💡 Windows Server Docker Requirements:${C_RESET}"
    Write-Host "   The VPS-Infra platform runs Linux containers (PostgreSQL, Traefik, DevOps/CI APIs)."
    Write-Host "   To run Linux containers on Windows Server:"
    Write-Host "   1. Enable WSL2 and Virtual Machine Platform:"
    Write-Host "      dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
    Write-Host "      wsl --install --no-distribution"
    Write-Host "   2. Install Docker Desktop for Windows (configured with WSL2 backend in 'Linux Containers' mode):"
    Write-Host "      winget install Docker.DockerDesktop"
    Write-Host "   3. Or on Windows Server 2022/2025, install Mirantis Container Runtime with Linux container support."
    Write-Host "   4. Note: If you ONLY want to host .NET/IIS applications natively on this Windows Server,"
    Write-Host "      you can point this node to an external Linux DevOps Manager host via TMK IIS Agent (scripts\tmk-iis-agent.ps1)."
    Write-Host ""
    exit 1
}

$composeWorking = $false
try {
    $composeVer = & docker compose version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $composeWorking = $true
    }
} catch {
    $composeWorking = $false
}

if (-not $composeWorking) {
    $composeStandAlone = Get-Command docker-compose -ErrorAction SilentlyContinue
    if ($composeStandAlone) {
        $composeWorking = $true
    }
}

if (-not $composeWorking) {
    Write-Err "❌ Docker Compose (v2) is not installed."
    Write-Err "   Please install the Docker Compose CLI plugin."
    exit 1
}
Write-Success "✅ Docker & Docker Compose detected."

# Verify Docker daemon is running
try {
    $dockerInfo = & docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "❌ Cannot connect to Docker daemon: $dockerInfo"
        Write-Err "   Ensure Docker Desktop or the Docker Windows Service is running."
        exit 1
    }
} catch {
    Write-Err "❌ Failed to query Docker daemon."
    exit 1
}

# Inspect Docker OSType
$dockerOs = ""
foreach ($line in ($dockerInfo -split "`n")) {
    if ($line -match "^\s*OSType:\s*(.+)$") {
        $dockerOs = $matches[1].Trim()
        break
    }
}

if ($dockerOs -match "windows") {
    Write-Warn "⚠️  Notice: Docker daemon is currently running in Windows Containers mode ('$dockerOs')."
    Write-Warn "   The VPS-Infra platform services and 20+ app stacks use Linux containers."
    Write-Warn "   If using Docker Desktop, please switch to 'Linux Containers' via system tray:"
    Write-Warn "     • Right-click Docker Desktop in the system tray -> Switch to Linux containers..."
    if (-not $Force) {
        Write-Err "❌ Cannot deploy Linux containers on a Windows-mode Docker daemon. Switch to Linux containers and rerun setup.ps1."
        Write-Err "   (Use -Force to bypass this check if you are running an experimental setup)."
        exit 1
    }
} else {
    Write-Success "✅ Docker Engine is running Linux containers mode ('$dockerOs')."
}

# ------------------------------------------------------------------------------
# 2. Check or Create .env configuration
# ------------------------------------------------------------------------------
$EnvPath = Join-Path $ScriptDir ".env"
$EnvExamplePath = Join-Path $ScriptDir ".env.example"

if (-not (Test-Path -Path $EnvPath)) {
    Write-Warn "⚠️  No .env file found. Creating one from .env.example..."
    Copy-Item -Path $EnvExamplePath -Destination $EnvPath
    Write-Warn "👉 Setup will configure routing domains; review credentials and TMK_LICENSE_KEY in '.env'."
}

function Set-EnvVal([string]$key, [string]$val) {
    $content = @()
    if (Test-Path -Path $EnvPath) {
        $content = Get-Content -Path $EnvPath
    }
    $found = $false
    $newContent = foreach ($line in $content) {
        if ($line -match "^\s*${key}=") {
            $found = $true
            "${key}=`"${val}`""
        } else {
            $line
        }
    }
    if (-not $found) {
        $newContent += "${key}=`"${val}`""
    }
    $newContent | Set-Content -Path $EnvPath -Encoding UTF8
    [System.Environment]::SetEnvironmentVariable($key, $val, [System.EnvironmentVariableTarget]::Process)
}

function Get-EnvVal([string]$key, [string]$defaultVal = "") {
    if (Test-Path -Path $EnvPath) {
        $lines = Get-Content -Path $EnvPath
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed.StartsWith("#")) { continue }
            if ($trimmed -match "^\s*${key}=(.*)$") {
                $v = $matches[1].Trim()
                if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
                    $v = $v.Substring(1, $v.Length - 2)
                }
                return $v
            }
        }
    }
    $envVar = [System.Environment]::GetEnvironmentVariable($key)
    if ($envVar) { return $envVar }
    return $defaultVal
}

function New-CryptoHex([int]$bytes = 32) {
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buf = New-Object byte[] $bytes
    $rng.GetBytes($buf)
    return [System.BitConverter]::ToString($buf).Replace("-", "").ToLower()
}

# Normalize INFRA_BASE_DIR for Windows (use forward slashes for Docker Compose path compatibility)
$normalizedScriptDir = $ScriptDir.Replace("\", "/")
$normalizedWwwRoot = (Split-Path -Parent $ScriptDir).Replace("\", "/")
Set-EnvVal "INFRA_BASE_DIR" $normalizedScriptDir
Set-EnvVal "WWW_ROOT" $normalizedWwwRoot

# Windows Docker socket fallback
$existingSock = Get-EnvVal "DOCKER_SOCK_PATH" ""
if (-not $existingSock) {
    if ($dockerOs -match "windows") {
        Set-EnvVal "DOCKER_SOCK_PATH" "//./pipe/docker_engine"
    } else {
        Set-EnvVal "DOCKER_SOCK_PATH" "/var/run/docker.sock"
    }
}

# PostgreSQL persistence default to named volume
$existingPgStorage = Get-EnvVal "POSTGRES_DATA_STORAGE" ""
if (-not $existingPgStorage) {
    Set-EnvVal "POSTGRES_DATA_STORAGE" "postgres_data"
}

# CLI Argument Resolution
$selectedMode = ""
if ($Mode) { $selectedMode = $Mode }
elseif ($DeploymentMode) { $selectedMode = $DeploymentMode }

if (-not $selectedMode) {
    $existingMode = Get-EnvVal "DEPLOYMENT_MODE" ""
    if (-not $existingMode) {
        Write-Host ""
        Write-Host "${C_CYAN}======================================================================${C_RESET}"
        Write-Host "${C_CYAN}${C_BOLD}   🌐 SELECT DEPLOYMENT TOPOLOGY${C_RESET}"
        Write-Host "${C_CYAN}======================================================================${C_RESET}"
        Write-Host "1) All-in-One          : DevOps Manager + CI Server + Registry + PostgreSQL on ONE VPS (Default)"
        Write-Host "2) DevOps Manager Only : Production / App Host (DevOps Panel, DB, Apps, Traefik)"
        Write-Host "3) CI Server Only      : Dedicated Build Machine (Build Runner, Artifacts, Docker Engine)"
        $choice = Read-Host "Enter choice [1-3, default: 1]"
        switch ($choice) {
            "2" { $selectedMode = "devops-only" }
            "3" { $selectedMode = "ci-only" }
            default { $selectedMode = "all-in-one" }
        }
    } else {
        $selectedMode = $existingMode
    }
}

switch ($selectedMode) {
    "devops-only" {
        $composeProfiles = "devops"
    }
    "ci-only" {
        $composeProfiles = "ci"
    }
    default {
        $selectedMode = "all-in-one"
        $composeProfiles = "all"
    }
}
Set-EnvVal "DEPLOYMENT_MODE" $selectedMode
Set-EnvVal "COMPOSE_PROFILES" $composeProfiles
Write-Success "✅ Active Deployment Topology: ${C_BOLD}${selectedMode}${C_RESET} (Profiles: ${composeProfiles})"

# Apply Registry overrides
if ($RegistryType) { Set-EnvVal "DOCKER_REGISTRY_TYPE" $RegistryType }
if ($RegistryHost) { Set-EnvVal "DOCKER_REGISTRY_HOST" $RegistryHost }
if ($RegistryUser) { Set-EnvVal "DOCKER_REGISTRY_USER" $RegistryUser }
if ($RegistryPass) { Set-EnvVal "DOCKER_REGISTRY_PASSWORD" $RegistryPass }

# Apply CI Sync overrides
if ($SyncMode) {
    Set-EnvVal "SYNC_MODE" $SyncMode
} else {
    $curSync = Get-EnvVal "SYNC_MODE" ""
    if (-not $curSync) { Set-EnvVal "SYNC_MODE" "api" }
}

if ($CiSecret) { Set-EnvVal "CI_SECRET" $CiSecret }

# Apply Tag overrides
if ($Tag) {
    Write-Info "▶ Applying container image tag override: ${Tag}..."
    Set-EnvVal "DEVOPS_API_IMAGE" "ghcr.io/tmk-computers/tmk-devops-api:${Tag}"
    Set-EnvVal "DEVOPS_WEB_IMAGE" "ghcr.io/tmk-computers/tmk-devops-web:${Tag}"
    Set-EnvVal "CI_API_IMAGE" "ghcr.io/tmk-computers/tmk-ci-api:${Tag}"
    Set-EnvVal "CI_WEB_IMAGE" "ghcr.io/tmk-computers/tmk-ci-web:${Tag}"
    Write-Success "✅ Configured container images to use tag '${Tag}'."
}

# Apply License override
if ($License) {
    $cleanLicense = $License.Trim(@(' ', '"', "'"))
    Set-EnvVal "TMK_LICENSE_KEY" $cleanLicense
    Write-Success "✅ Configured TMK_LICENSE_KEY from argument."
}

# Generate secure random secrets if default placeholders exist
$jwtSecret = Get-EnvVal "JWT_SECRET_KEY" ""
if ($jwtSecret -match "generate_a_64_character_hex_string_here") {
    $newJwt = New-CryptoHex 32
    Set-EnvVal "JWT_SECRET_KEY" $newJwt
}

$ciJwtSecret = Get-EnvVal "CI_JWT_SECRET" ""
if ($ciJwtSecret -match "generate_a_64_character_hex_string_here") {
    $newCiJwt = New-CryptoHex 32
    Set-EnvVal "CI_JWT_SECRET" $newCiJwt
}

# ------------------------------------------------------------------------------
# 3. Configure Domains & Routing
# ------------------------------------------------------------------------------
$configDomainsScript = Join-Path $ScriptDir "scripts\configure-domains.ps1"
if (Test-Path -Path $configDomainsScript) {
    if ($Domain) {
        & $configDomainsScript -Domain $Domain
    } else {
        & $configDomainsScript
    }
}

# ------------------------------------------------------------------------------
# 4. Create External Docker Network
# ------------------------------------------------------------------------------
Write-Info "▶ Ensuring 'traefik_net' Docker network exists..."
$netExists = $false
try {
    $netInspect = & docker network inspect traefik_net 2>&1
    if ($LASTEXITCODE -eq 0) { $netExists = $true }
} catch {
    $netExists = $false
}

if (-not $netExists) {
    & docker network create traefik_net | Out-Null
    Write-Success "✅ Created external network 'traefik_net'."
} else {
    Write-Success "✅ Network 'traefik_net' is already present."
}

# ------------------------------------------------------------------------------
# 5. Scaffold Persistent Volume Directories
# ------------------------------------------------------------------------------
Write-Info "▶ Scaffolding persistent volume directories for [${selectedMode}]..."
$dirsToCreate = @(
    (Join-Path $ScriptDir "volumes\apps"),
    (Join-Path $ScriptDir "volumes\artifacts\builds"),
    (Join-Path $ScriptDir "volumes\apk"),
    (Join-Path $ScriptDir "volumes\env-backups"),
    (Join-Path $ScriptDir "network\traefik"),
    (Join-Path $ScriptDir "network\traefik\dynamic")
)

if ($selectedMode -ne "ci-only") {
    $dirsToCreate += @(
        (Join-Path $ScriptDir "volumes\db\postgres\data"),
        (Join-Path $ScriptDir "volumes\db\postgres\backups"),
        (Join-Path $ScriptDir "volumes\db\pgadmin"),
        (Join-Path $ScriptDir "volumes\db\pgadmin-config"),
        (Join-Path $ScriptDir "volumes\infra\backups")
    )
}

if ($regType -eq "private" -and $selectedMode -ne "devops-only") {
    $dirsToCreate += (Join-Path $ScriptDir "volumes\infra\registry")
}

$setupDirsScript = Join-Path $ScriptDir "scripts\setup-directories.ps1"
if (Test-Path -Path $setupDirsScript) {
    & $setupDirsScript -Paths $dirsToCreate
} else {
    foreach ($d in $dirsToCreate) {
        if (-not (Test-Path -Path $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
    }
}
Write-Success "✅ Persistent volume directories scaffolded."

# Crucial Docker Safeguard: Pre-create license.key as a regular file before Docker bind-mounts it
$licenseFilePath = Join-Path $ScriptDir "volumes\license.key"
if (Test-Path -Path $licenseFilePath -PathType Container) {
    Remove-Item -Path $licenseFilePath -Recurse -Force
}
if (-not (Test-Path -Path $licenseFilePath)) {
    $licKey = Get-EnvVal "TMK_LICENSE_KEY" ""
    if ($licKey) {
        Set-Content -Path $licenseFilePath -Value $licKey -Encoding UTF8
    } else {
        New-Item -ItemType File -Path $licenseFilePath -Force | Out-Null
    }
}
Write-Success "✅ Volume license.key secured as regular file mount."

# Crucial Docker Safeguard: Pre-create pgadmin config_local.py if missing
if ($selectedMode -ne "ci-only") {
    $pgAdminConfigFile = Join-Path $ScriptDir "volumes\db\pgadmin-config\config_local.py"
    if (Test-Path -Path $pgAdminConfigFile -PathType Container) {
        Remove-Item -Path $pgAdminConfigFile -Recurse -Force
    }
    if (-not (Test-Path -Path $pgAdminConfigFile)) {
        Set-Content -Path $pgAdminConfigFile -Value 'SESSION_DB_PATH = "/var/lib/pgadmin/pgadmin_sessions"' -Encoding UTF8
    }
    Write-Success "✅ Volume pgAdmin config_local.py secured as regular file mount."
}

# ------------------------------------------------------------------------------
# 6. Prepare Traefik SSL Certificate Storage & Dashboard Auth
# ------------------------------------------------------------------------------
$acmePath = Join-Path $ScriptDir "network\traefik\acme.json"
if (-not (Test-Path -Path $acmePath)) {
    New-Item -ItemType File -Path $acmePath -Force | Out-Null
}

$htpasswdPath = Join-Path $ScriptDir "network\traefik\users.htpasswd"
if (-not (Test-Path -Path $htpasswdPath)) {
    Set-Content -Path $htpasswdPath -Value 'admin:$2y$05$LcKxE/OkQYg7D2UPBkedkOO./SILLHS6GW04OS3B/.urSdR7bmPnW' -Encoding UTF8
}
Write-Success "✅ Traefik acme.json & users.htpasswd prepared."

# ------------------------------------------------------------------------------
# 7. Check Port Conflicts (IIS / W3SVC / Other Listeners)
# ------------------------------------------------------------------------------
$traefikHttp = if ($HttpPort -gt 0) { $HttpPort } else { [int](Get-EnvVal "TRAEFIK_HTTP_PORT" "80") }
$traefikHttps = if ($HttpsPort -gt 0) { $HttpsPort } else { [int](Get-EnvVal "TRAEFIK_HTTPS_PORT" "443") }
Set-EnvVal "TRAEFIK_HTTP_PORT" "$traefikHttp"
Set-EnvVal "TRAEFIK_HTTPS_PORT" "$traefikHttps"

function Test-PortInUse([int]$port) {
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        return ($null -ne $conns -and $conns.Count -gt 0)
    } catch {
        return $false
    }
}

Write-Info "▶ Checking Traefik ports ($traefikHttp, $traefikHttps)..."
$httpConflict = Test-PortInUse $traefikHttp
$httpsConflict = Test-PortInUse $traefikHttps

if ($httpConflict -or $httpsConflict) {
    Write-Warn "⚠️  One or more Traefik ports are already bound ($traefikHttp / $traefikHttps)."
    
    # Check if W3SVC (IIS) is running
    $w3svc = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
    if ($w3svc -and $w3svc.Status -eq 'Running') {
        Write-Warn "   • IIS Web Server (W3SVC) is actively running on this host."
        Write-Warn "   • Stopping W3SVC will assign ports 80/443 to Traefik, but will stop existing IIS sites."
        
        $shouldStop = $false
        if ($Yes -or $Force) {
            $shouldStop = $true
        } else {
            Write-Host ""
            $ans = Read-Host "Would you like to stop W3SVC (IIS) to free ports 80/443 for Traefik? [y/N]"
            if ($ans -match "^(y|yes)$") {
                $shouldStop = $true
            }
        }
        
        if ($shouldStop) {
            Write-Info "▶ Stopping IIS (W3SVC)..."
            Stop-Service W3SVC -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Write-Success "✅ IIS (W3SVC) stopped."
        } else {
            Write-Warn "ℹ️ Keeping IIS running. You can change TRAEFIK_HTTP_PORT and TRAEFIK_HTTPS_PORT in .env (e.g. 8080 and 8443)."
        }
    }
} else {
    Write-Success "✅ Ports $traefikHttp and $traefikHttps are available."
}

# ------------------------------------------------------------------------------
# 8. Start Core Infrastructure Services
# ------------------------------------------------------------------------------
$networkMode = Get-EnvVal "NETWORK_MODE" "public"
$enableHttpsRedirect = Get-EnvVal "ENABLE_HTTPS_REDIRECT" "true"

if ($networkMode -eq "private" -or $enableHttpsRedirect -eq "false") {
    Write-Warn "▶ Private Network Mode Active: Disabling mandatory HTTPS redirect..."
    [System.Environment]::SetEnvironmentVariable("TRAEFIK_HTTP_REDIRECT_TO", "--api.debug=false", [System.EnvironmentVariableTarget]::Process)
    [System.Environment]::SetEnvironmentVariable("TRAEFIK_HTTP_REDIRECT_SCHEME", "--api.insecure=false", [System.EnvironmentVariableTarget]::Process)
}

Write-Info "`n▶ Starting Reverse Proxy (Traefik)..."
$traefikCompose = Join-Path $ScriptDir "network\traefik\docker-compose.yml"
& docker compose -f $traefikCompose --env-file $EnvPath up -d

if ($selectedMode -ne "ci-only") {
    Write-Info "`n▶ Starting Shared PostgreSQL & pgAdmin..."
    $postgresCompose = Join-Path $ScriptDir "db\postgres\docker-compose.yml"
    & docker compose -f $postgresCompose --env-file $EnvPath up -d
} else {
    Write-Warn "`n▶ Skipping local PostgreSQL (Topology: ci-only; using REST API sync to DevOps Manager)."
}

# Registry Auth & Startup
$regType = Get-EnvVal "DOCKER_REGISTRY_TYPE" "private"
if ($regType -eq "private" -and $selectedMode -ne "devops-only") {
    $regAuthScript = Join-Path $ScriptDir "scripts\authenticate-registry.ps1"
    Write-Info "`n▶ Starting Private Docker Registry..."
    $registryCompose = Join-Path $ScriptDir "docker-registry\docker-compose.yml"
    & docker compose -f $registryCompose --env-file $EnvPath up -d
    
    Start-Sleep -Seconds 3
    if (Test-Path -Path $regAuthScript) {
        & $regAuthScript
    }
}

# Compose File Detection
$mainCompose = Join-Path $ScriptDir "docker-compose.yml"
$uatCompose = Join-Path $ScriptDir "docker-compose.uat.yml"
$activeComposeFile = if (Test-Path -Path $mainCompose) { $mainCompose } else { $uatCompose }

# Wait for PostgreSQL
if ($selectedMode -ne "ci-only") {
    Write-Info "`n▶ Waiting for PostgreSQL to be ready before starting platform services..."
    $pgUser = Get-EnvVal "POSTGRES_USER" "postgres"
    $pgDb   = Get-EnvVal "POSTGRES_DB" "devops_prod"
    $ready  = $false
    for ($i = 1; $i -le 30; $i++) {
        $res = & docker exec shared_postgres pg_isready -U $pgUser -d $pgDb 2>&1
        if ($LASTEXITCODE -eq 0) {
            $ready = $true
            Write-Success "✅ PostgreSQL is ready and accepting connections."
            break
        }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) {
        Write-Warn "⚠️  PostgreSQL is still initializing. Continuing startup..."
    }
}

Write-Info "`n▶ Pulling and Starting Platform Services (Profile: ${composeProfiles})..."
& docker compose -f $activeComposeFile --profile $composeProfiles --env-file $EnvPath up -d

# Account Validation
$validateAdminScript = Join-Path $ScriptDir "scripts\validate-admin.ps1"
if (Test-Path -Path $validateAdminScript -and $selectedMode -ne "ci-only") {
    $pgUser = Get-EnvVal "POSTGRES_USER" "postgres"
    $pgDb   = Get-EnvVal "POSTGRES_DB" "devops_prod"
    & $validateAdminScript -AdminEmail $adminEmail -DbUser $pgUser -DbName $pgDb
}

# ------------------------------------------------------------------------------
# 9. Print Completion Summary
# ------------------------------------------------------------------------------
$companyName = Get-EnvVal "COMPANY_NAME" "Custom Organization"
$primaryDomain = Get-EnvVal "PRIMARY_DOMAIN" "example.com"
$devopsWeb = Get-EnvVal "DEVOPS_WEB_HOST" "devops.example.com"
$devopsApi = Get-EnvVal "DEVOPS_API_HOST" "devops-api.example.com"
$ciWeb = Get-EnvVal "CI_WEB_HOST" "ci.example.com"
$ciApi = Get-EnvVal "CI_API_HOST" "ci-api.example.com"
$regHost = Get-EnvVal "REGISTRY_HOST" "registry.example.com"
$pgAdminHost = Get-EnvVal "PGADMIN_HOST" "pgadmin.example.com"
$traefikHost = Get-EnvVal "TRAEFIK_DASHBOARD_HOST" "traefik.example.com"
$adminEmail = Get-EnvVal "SUPERADMIN_EMAIL" "admin@example.com"
$adminPass = Get-EnvVal "SUPERADMIN_PASSWORD" "[Configured in .env]"

Write-Host ""
Write-Host "${C_GREEN}${C_BOLD}======================================================================${C_RESET}"
Write-Host "${C_GREEN}${C_BOLD}   🎉 VPS-INFRA [$($selectedMode.ToUpper())] DEPLOYED SUCCESSFULLY!${C_RESET}"
Write-Host "${C_GREEN}${C_BOLD}======================================================================${C_RESET}"
Write-Host "${C_BOLD}Topology Mode:${C_RESET}           ${C_CYAN}${selectedMode}${C_RESET} (Profiles: ${composeProfiles})"
Write-Host "${C_BOLD}Registry Mode:${C_RESET}           ${C_CYAN}${regType}${C_RESET} ($regHost)"
Write-Host "${C_BOLD}Sync Mode:${C_RESET}               ${C_CYAN}$(Get-EnvVal 'SYNC_MODE' 'api')${C_RESET}"
Write-Host "${C_BOLD}Company / Organization:${C_RESET}  ${companyName}"
Write-Host "${C_BOLD}Primary Domain:${C_RESET}          ${primaryDomain}"
Write-Host ""
Write-Host "${C_BOLD}🌐 Active Endpoints for this Node:${C_RESET}"

if ($selectedMode -ne "ci-only") {
    Write-Host "  • DevOps Manager Panel:  ${C_CYAN}https://${devopsWeb}${C_RESET}"
    Write-Host "  • DevOps REST API:       ${C_CYAN}https://${devopsApi}${C_RESET}"
    Write-Host "  • pgAdmin Web:           ${C_CYAN}https://${pgAdminHost}${C_RESET}"
}

if ($selectedMode -ne "devops-only") {
    Write-Host "  • CI/CD Dashboard:       ${C_CYAN}https://${ciWeb}${C_RESET}"
    Write-Host "  • CI/CD API & Artifacts: ${C_CYAN}https://${ciApi}${C_RESET}"
    if ($regType -eq "private") {
        Write-Host "  • Private Registry:      ${C_CYAN}https://${regHost}${C_RESET}"
    }
}

Write-Host "  • Traefik Dashboard:     ${C_CYAN}https://${traefikHost}${C_RESET}"
Write-Host ""

if ($selectedMode -ne "ci-only") {
    Write-Host "${C_BOLD}🔑 Configured Administrator Credentials:${C_RESET}"
    Write-Host "  • SuperAdmin Email:      $adminEmail"
    Write-Host "  • SuperAdmin Password:   $adminPass"
    if (Test-Path -Path $validateAdminScript) {
        & $validateAdminScript -ShowOnly
    }
    Write-Host ""
}

Write-Host "${C_BOLD}💡 Next Steps:${C_RESET}"
if ($selectedMode -eq "ci-only") {
    Write-Host "  1. Verify connection to DevOps Manager via DEVOPS_API_URL and CI_SECRET."
    Write-Host "  2. Run builds from the CI Dashboard or trigger via DevOps Webhook."
} elseif ($selectedMode -eq "devops-only") {
    Write-Host "  1. Configure CI_SECRET in .env to match the remote CI Server."
    Write-Host "  2. Point application domain DNS A-records to this host."
    Write-Host "  3. Log in to DevOps Manager to deploy application microservices."
} else {
    Write-Host "  1. Verify DNS points to this VPS and HTTPS certificates are issued before logging in."
    Write-Host "  2. Log in to the DevOps Manager to register your Products & microservices."
    Write-Host "  3. Use templates in 'templates' for new service deployments."
}
Write-Host "${C_GREEN}======================================================================${C_RESET}`n"
