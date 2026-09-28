<#
.SYNOPSIS
    Docker registry authentication helper for VPS-Infra (PowerShell 5.1 & 7+).
    Equivalent to scripts/authenticate-registry.sh.
#>

[CmdletBinding()]
param (
    [string]$User = "",
    [string]$Password = "",
    [string]$HostTarget = "",
    [string]$RegistryType = "",
    [string]$DeploymentMode = ""
)

function Authenticate-Registry {
    param (
        [string]$User = "",
        [string]$Password = "",
        [string]$HostTarget = "",
        [string]$RegistryType = "",
        [string]$DeploymentMode = ""
    )

    if ([string]::IsNullOrWhiteSpace($User)) {
        $User = if ($env:DOCKER_REGISTRY_USER) { $env:DOCKER_REGISTRY_USER } else { $env:REGISTRY_USER }
    }
    if ([string]::IsNullOrWhiteSpace($Password)) {
        $Password = if ($env:DOCKER_REGISTRY_PASSWORD) { $env:DOCKER_REGISTRY_PASSWORD } else { $env:REGISTRY_PASSWORD }
    }
    if ([string]::IsNullOrWhiteSpace($HostTarget)) {
        $HostTarget = if ($env:DOCKER_REGISTRY_HOST) { $env:DOCKER_REGISTRY_HOST } else { if ($env:REGISTRY_HOST) { $env:REGISTRY_HOST } else { "localhost:5000" } }
    }
    if ([string]::IsNullOrWhiteSpace($RegistryType)) {
        $RegistryType = if ($env:DOCKER_REGISTRY_TYPE) { $env:DOCKER_REGISTRY_TYPE } else { "private" }
    }
    if ([string]::IsNullOrWhiteSpace($DeploymentMode)) {
        $DeploymentMode = if ($env:DEPLOYMENT_MODE) { $env:DEPLOYMENT_MODE } else { "all-in-one" }
    }

    $attempts = 1
    if ($RegistryType -eq "private") {
        if ([string]::IsNullOrWhiteSpace($User)) { $User = "admin" }
        if ([string]::IsNullOrWhiteSpace($Password)) { $Password = "tmkregistry2026" }
        if ($DeploymentMode -ne "devops-only") {
            $attempts = 30
        }
    }

    if ([string]::IsNullOrWhiteSpace($User) -or [string]::IsNullOrWhiteSpace($Password)) {
        return $true
    }

    Write-Host "▶ Authenticating Docker with registry ${HostTarget}..." -ForegroundColor Cyan

    for ($attempt = 1; $attempt -le $attempts; $attempt++) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "docker"
        $psi.Arguments = "login `"$HostTarget`" -u `"$User`" --password-stdin"
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.StandardInput.WriteLine($Password)
        $proc.StandardInput.Close()
        $out = $proc.StandardOutput.ReadToEnd()
        $err = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if ($proc.ExitCode -eq 0) {
            Write-Host "✅ Docker registry authentication succeeded." -ForegroundColor Green
            if ($HostTarget -ne "localhost:5000" -and $RegistryType -eq "private") {
                foreach ($alias in @("localhost:5000", "127.0.0.1:5000")) {
                    try {
                        $p = [System.Diagnostics.Process]::Start($psi)
                        $p.StandardInput.WriteLine($Password)
                        $p.StandardInput.Close()
                        $p.WaitForExit()
                    } catch { }
                }
            }
            return $true
        }

        if ($attempt -lt $attempts) {
            if ($attempt -eq 1) {
                Write-Host "Waiting for the private registry to accept login..." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 2
        }
    }

    Write-Host "Registry authentication failed for ${HostTarget}. Check registry availability and credentials in .env." -ForegroundColor Yellow
    if ($attempts -gt 1) {
        Write-Host "Inspect startup errors with: docker logs --tail 100 docker-registry-backend" -ForegroundColor Yellow
    }
    return $false
}

Authenticate-Registry -User $User -Password $Password -HostTarget $HostTarget -RegistryType $RegistryType -DeploymentMode $DeploymentMode
