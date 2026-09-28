<#
.SYNOPSIS
    SuperAdmin account validation helper for VPS-Infra (PowerShell 5.1 & 7+).
    Equivalent to scripts/validate-admin.sh.
#>

[CmdletBinding()]
param (
    [string]$AdminEmail = "",
    [string]$DbUser = "postgres",
    [string]$DbName = "devops_prod",
    [switch]$ShowOnly
)

$global:AdminValidationStatus = "error"

function Test-AdminAccount {
    param (
        [string]$AdminEmail = "",
        [string]$DbUser = "postgres",
        [string]$DbName = "devops_prod"
    )

    $global:AdminValidationStatus = "error"

    if ([string]::IsNullOrWhiteSpace($AdminEmail)) {
        $AdminEmail = if ($env:SUPERADMIN_EMAIL) { $env:SUPERADMIN_EMAIL } else { "admin@example.com" }
    }
    if ($env:POSTGRES_USER) { $DbUser = $env:POSTGRES_USER }
    if ($env:POSTGRES_DB) { $DbName = $env:POSTGRES_DB }

    $running = docker ps --format "{{.Names}}" 2>$null
    if ($running -notmatch "shared_postgres") {
        $global:AdminValidationStatus = "skipped"
        return $true
    }

    Write-Host "Checking configured administrator in PostgreSQL (12 attempts, 5s delay)..." -ForegroundColor Cyan

    $sqlQuery = "SELECT EXISTS (SELECT 1 FROM public.`"AspNetUsers`" WHERE lower(`"Email`") = lower('$AdminEmail'));"

    for ($attempt = 1; $attempt -le 12; $attempt++) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "docker"
        $psi.Arguments = "exec -i shared_postgres psql -X -t -A -U $DbUser -d $DbName"
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.StandardInput.WriteLine($sqlQuery)
        $proc.StandardInput.Close()
        $out = $proc.StandardOutput.ReadToEnd().Trim()
        $proc.WaitForExit()

        if ($proc.ExitCode -eq 0) {
            if ($out -eq "t") {
                $global:AdminValidationStatus = "found"
                return $true
            } elseif ($out -eq "f") {
                $global:AdminValidationStatus = "missing"
            }
        }

        if ($attempt -lt 12) {
            Start-Sleep -Seconds 5
        }
    }

    return $false
}

function Show-AdminValidation {
    switch ($global:AdminValidationStatus) {
        "found" {
            Write-Host "  ✅ Account found in the configured database." -ForegroundColor Green
        }
        "skipped" {
            Write-Host "  ℹ️ Local shared_postgres container not running on this host (external database or distributed node)." -ForegroundColor Yellow
        }
        "missing" {
            Write-Host "  ❌ Account NOT FOUND in the configured database after startup retries." -ForegroundColor Red
            Write-Host "     The displayed credentials have no matching account in this database." -ForegroundColor Yellow
            Write-Host "     Check API startup logs for administrator creation failures." -ForegroundColor Yellow
        }
        default {
            Write-Host "  ⚠️ Account check FAILED: could not verify the user table." -ForegroundColor Yellow
            Write-Host "     Check PostgreSQL availability, database settings, and API migrations." -ForegroundColor Yellow
        }
    }
    Write-Host "  Password and administrator role have NOT been validated; these are configuration values." -ForegroundColor Gray
    Write-Host "  Changing .env does not prove an existing account's password was updated." -ForegroundColor Gray
    if ($global:AdminValidationStatus -ne "found" -and $global:AdminValidationStatus -ne "skipped") {
        Write-Host "  Diagnostic command: docker logs --tail 200 devops-api-prod" -ForegroundColor Cyan
    }
}

if ($ShowOnly) {
    Show-AdminValidation
} else {
    Test-AdminAccount -AdminEmail $AdminEmail -DbUser $DbUser -DbName $DbName | Out-Null
    Show-AdminValidation
}
