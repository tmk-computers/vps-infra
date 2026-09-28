<#
.SYNOPSIS
    Persistent directory scaffolding helper for VPS-Infra (PowerShell 5.1 & 7+).
    Equivalent to scripts/setup-directories.sh.
#>

[CmdletBinding()]
param (
    [string[]]$Paths = @(),
    [switch]$DebugMode
)

function New-SetupDirectories {
    param (
        [string[]]$Paths,
        [switch]$DebugMode
    )

    $hasError = $false

    foreach ($p in $Paths) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        try {
            if (-not (Test-Path $p)) {
                New-Item -ItemType Directory -Path $p -Force | Out-Null
            }
            if ($DebugMode -or $env:SETUP_DEBUG -eq "1") {
                Write-Host "  OK: $p" -ForegroundColor Green
            }
        } catch {
            $hasError = $true
            Write-Host "`n✗ Cannot create: $p" -ForegroundColor Red
            Write-Host "Reason: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "Action: Check folder permissions, disk space, and security policies on Windows host." -ForegroundColor Cyan
        }
    }

    return (-not $hasError)
}

if ($Paths -and $Paths.Count -gt 0) {
    New-SetupDirectories -Paths $Paths -DebugMode:$DebugMode
}
