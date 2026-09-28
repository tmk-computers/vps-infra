<#
.SYNOPSIS
    Domain configuration and validation helper for VPS-Infra (PowerShell 5.1 & 7+).
    Equivalent to scripts/configure-domains.sh.
#>

[CmdletBinding()]
param (
    [string]$ScriptDir = "",
    [string]$Domain = ""
)

function Test-ValidDomain {
    param (
        [string]$Domain
    )

    if ([string]::IsNullOrWhiteSpace($Domain)) { return $false }
    $trimmed = $Domain.Trim()

    if ($trimmed.Length -gt 253) { return $false }
    if (-not $trimmed.Contains('.')) { return $false }
    if ($trimmed.EndsWith('.')) { return $false }
    if ($trimmed -match 'yourdomain\.com') { return $false }
    if ($trimmed -eq 'example.com' -or $trimmed.EndsWith('.example.com')) { return $false }
    if ($trimmed -match '[^a-zA-Z0-9.-]') { return $false }

    $labels = $trimmed.Split('.')
    foreach ($label in $labels) {
        if ($label.Length -lt 1 -or $label.Length -gt 63) { return $false }
        if ($label.StartsWith('-') -or $label.EndsWith('-')) { return $false }
    }

    return $true
}

function Set-EnvDomainValue {
    param (
        [string]$EnvFilePath,
        [string]$Key,
        [string]$Value
    )

    if (-not (Test-Path $EnvFilePath)) {
        Set-Content -Path $EnvFilePath -Value "$Key=$Value" -Encoding utf8
        [System.Environment]::SetEnvironmentVariable($Key, $Value, "Process")
        return
    }

    $lines = [System.IO.File]::ReadAllLines($EnvFilePath, [System.Text.Encoding]::UTF8)
    $found = $false
    $newLines = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $lines) {
        if ($line -match "^\s*${Key}\s*=") {
            $newLines.Add("${Key}=${Value}")
            $found = $true
        } else {
            $newLines.Add($line)
        }
    }

    if (-not $found) {
        $newLines.Add("${Key}=${Value}")
    }

    [System.IO.File]::WriteAllLines($EnvFilePath, $newLines, [System.Text.Encoding]::UTF8)
    [System.Environment]::SetEnvironmentVariable($Key, $Value, "Process")
}

function Configure-Domains {
    param (
        [string]$ScriptDir,
        [string]$DomainOverride = ""
    )

    $envPath = Join-Path $ScriptDir ".env"
    if (-not (Test-Path $envPath)) {
        throw "Missing .env file at $envPath. Run setup first."
    }

    $primaryDomain = if (-not [string]::IsNullOrWhiteSpace($DomainOverride)) {
        $DomainOverride.Trim()
    } else {
        $env:PRIMARY_DOMAIN
    }

    if (-not (Test-ValidDomain -Domain $primaryDomain)) {
        if ([Environment]::UserInteractive -and [System.Console]::IsInputRedirected -eq $false) {
            Write-Host -NoNewline "Primary domain (for example, company.com): " -ForegroundColor Cyan
            $inputDomain = Read-Host
            if (Test-ValidDomain -Domain $inputDomain) {
                $primaryDomain = $inputDomain.Trim()
            } else {
                Write-Error "Invalid primary domain: '$inputDomain'"
                return $false
            }
        } else {
            Write-Error "A real primary domain is required. Run ./setup.ps1 --domain company.com (use your own domain)."
            return $false
        }
    }

    $explicitKeys = @(
        "DEVOPS_WEB_HOST", "DEVOPS_API_HOST", "CI_WEB_HOST", "CI_API_HOST",
        "REGISTRY_HOST", "PGADMIN_HOST", "PHPMYADMIN_HOST", "TRAEFIK_DASHBOARD_HOST", "MONGO_EXPRESS_HOST"
    )

    foreach ($key in $explicitKeys) {
        $val = [System.Environment]::GetEnvironmentVariable($key)
        if (-not [string]::IsNullOrWhiteSpace($val)) {
            if ($val -match '^(yourdomain\.com|\*\.yourdomain\.com|example\.com|\*\.example\.com)$') {
                continue
            }
            if (-not (Test-ValidDomain -Domain $val)) {
                Write-Error "Invalid hostname configured in ${key}: $val"
                return $false
            }
        }
    }

    $backupDir = Join-Path $ScriptDir "volumes\env-backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
    $backupFile = Join-Path $backupDir ".env.backup.${timestamp}.$PID"
    Copy-Item -Path $envPath -Destination $backupFile -Force

    Set-EnvDomainValue -EnvFilePath $envPath -Key "PRIMARY_DOMAIN" -Value $primaryDomain

    $hostPrefixes = @{
        "DEVOPS_WEB_HOST"        = "devops"
        "DEVOPS_API_HOST"        = "devops-api"
        "CI_WEB_HOST"            = "ci"
        "CI_API_HOST"            = "ci-api"
        "REGISTRY_HOST"          = "registry"
        "PGADMIN_HOST"           = "pgadmin"
        "PHPMYADMIN_HOST"        = "phpmyadmin"
        "TRAEFIK_DASHBOARD_HOST" = "traefik"
        "MONGO_EXPRESS_HOST"     = "mongo"
    }

    foreach ($k in $hostPrefixes.Keys) {
        $val = [System.Environment]::GetEnvironmentVariable($k)
        if ([string]::IsNullOrWhiteSpace($val) -or $val -match '^(yourdomain\.com|\*\.yourdomain\.com|example\.com|\*\.example\.com)$') {
            $computed = "$($hostPrefixes[$k]).$primaryDomain"
            Set-EnvDomainValue -EnvFilePath $envPath -Key $k -Value $computed
        }
    }

    $acmeEmail = $env:ACME_SSL_EMAIL
    if ([string]::IsNullOrWhiteSpace($acmeEmail) -or $acmeEmail -match '(@yourdomain\.com|@example\.com)$') {
        Set-EnvDomainValue -EnvFilePath $envPath -Key "ACME_SSL_EMAIL" -Value "admin@$primaryDomain"
    }

    $adminEmail = $env:SUPERADMIN_EMAIL
    if ([string]::IsNullOrWhiteSpace($adminEmail) -or $adminEmail -match '(@yourdomain\.com|@example\.com)$') {
        Set-EnvDomainValue -EnvFilePath $envPath -Key "SUPERADMIN_EMAIL" -Value "admin@$primaryDomain"
    }

    Write-Host "Domain configuration saved. Ensure these hostnames resolve to this server before certificate issuance:" -ForegroundColor Green
    foreach ($k in @("DEVOPS_WEB_HOST", "DEVOPS_API_HOST", "CI_WEB_HOST", "CI_API_HOST", "REGISTRY_HOST", "PGADMIN_HOST", "TRAEFIK_DASHBOARD_HOST")) {
        $resolved = [System.Environment]::GetEnvironmentVariable($k)
        Write-Host "  $k=$resolved" -ForegroundColor Cyan
    }

    return $true
}

# Resolve ScriptDir if not explicitly supplied
if (-not $ScriptDir) {
    if ($PSScriptRoot) {
        $ScriptDir = Split-Path -Parent $PSScriptRoot
    } else {
        $ScriptDir = (Get-Location).Path
    }
}

Configure-Domains -ScriptDir $ScriptDir -DomainOverride $Domain
