<#
.SYNOPSIS
    TMK DevOps Platform - Windows IIS Native Host Agent
    Listens on http://127.0.0.1:5055 to provide native IIS management & zero-lock deployments.

.DESCRIPTION
    Exposes a secure REST interface for DevOps Manager to:
    - Start, stop, and recycle IIS Application Pools
    - Harvest w3wp.exe CPU% and Memory telemetry
    - Execute zero-downtime, zero-lock artifact deployments with app_offline.htm and auto-rollback
    - Stream recent ASP.NET Core stdout and W3C access logs
#>

[CmdletBinding()]
param(
    [int]$Port = 5055,
    [string]$Secret = $env:CI_SECRET
)

if ([string]::IsNullOrWhiteSpace($Secret)) {
    throw "CI_SECRET must be configured before starting the IIS agent."
}

# Ensure IIS WebAdministration module is available
try {
    Import-Module WebAdministration -ErrorAction Stop
} catch {
    Write-Warning "WebAdministration module could not be imported. Some IIS features may be limited."
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host " 🚀 TMK IIS Host Agent listening on $prefix" -ForegroundColor Green
    Write-Host " Security: Bearer Token Auth enabled" -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to start HttpListener on $prefix : $_"
    exit 1
}

function Send-JsonResponse($response, $statusCode, $object) {
    $json = $object | ConvertTo-Json -Depth 5 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $response.StatusCode = $statusCode
    $response.ContentType = "application/json"
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.OutputStream.Close()
}

function Send-TextResponse($response, $statusCode, [string]$text) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $response.StatusCode = $statusCode
    $response.ContentType = "text/plain"
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.OutputStream.Close()
}

function Get-AppPoolMetrics([string]$appPoolName) {
    $result = @{
        Status = "Stopped"
        Uptime = "Stopped"
        CpuUsage = "0%"
        MemoryUsage = "0 MB"
        ProcessId = $null
    }

    try {
        $state = (Get-WebAppPoolState -Name $appPoolName -ErrorAction SilentlyContinue).Value
        if ($state) {
            $result.Status = if ($state -eq "Started") { "Running" } else { $state }
        }

        if ($result.Status -eq "Running") {
            # Find matching w3wp worker process
            $procs = Get-CimInstance Win32_Process -Filter "Name = 'w3wp.exe'" -ErrorAction SilentlyContinue |
                     Where-Object { $_.CommandLine -like "*-ap `"$appPoolName`"*" -or $_.CommandLine -like "* $appPoolName *" }

            if ($procs) {
                $targetProc = $procs[0]
                $result.ProcessId = $targetProc.ProcessId
                
                $sysProc = [System.Diagnostics.Process]::GetProcessById($targetProc.ProcessId)
                if ($sysProc) {
                    $memMb = [math]::Round($sysProc.WorkingSet64 / 1MB, 1)
                    $result.MemoryUsage = "$memMb MB"
                    $result.CpuUsage = "Active"
                    
                    $startTime = $sysProc.StartTime
                    $uptimeSpan = (Get-Date) - $startTime
                    if ($uptimeSpan.TotalHours -ge 1) {
                        $result.Uptime = "Up $([int]$uptimeSpan.TotalHours)h $($uptimeSpan.Minutes)m"
                    } else {
                        $result.Uptime = "Up $($uptimeSpan.Minutes)m $($uptimeSpan.Seconds)s"
                    }
                }
            }
        }
    } catch {
        $result.Status = "Error: $_"
    }

    return $result
}

# Main request processing loop
try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # CORS Headers
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.OutputStream.Close()
            continue
        }

        # Authentication check
        $authHeader = $request.Headers["Authorization"]
        $expectedBearer = "Bearer $Secret"
        if ($request.Url.AbsolutePath -ne "/api/iis/health" -and $authHeader -ne $expectedBearer) {
            Send-JsonResponse $response 401 @{ message = "Unauthorized: Invalid or missing Bearer token." }
            continue
        }

        $path = $request.Url.AbsolutePath.TrimEnd('/')

        # 1. Health Probe
        if ($path -eq "/api/iis/health" -and $request.HttpMethod -eq "GET") {
            Send-JsonResponse $response 200 @{
                status = "Healthy"
                platform = "Windows Server"
                timestamp = (Get-Date).ToString("o")
            }
            continue
        }

        # 2. Get Single AppPool Status: /api/iis/apppools/{name}/status
        if ($path -match "^/api/iis/apppools/([^/]+)/status$" -and $request.HttpMethod -eq "GET") {
            $poolName = [System.Uri]::UnescapeDataString($Matches[1])
            $metrics = Get-AppPoolMetrics $poolName
            Send-JsonResponse $response 200 $metrics
            continue
        }

        # 3. Start AppPool: /api/iis/apppools/{name}/start
        if ($path -match "^/api/iis/apppools/([^/]+)/start$" -and $request.HttpMethod -eq "POST") {
            $poolName = [System.Uri]::UnescapeDataString($Matches[1])
            try {
                Start-WebAppPool -Name $poolName -ErrorAction Stop
                Send-TextResponse $response 200 "AppPool '$poolName' started successfully."
            } catch {
                Send-TextResponse $response 500 "Failed to start AppPool '$poolName': $_"
            }
            continue
        }

        # 4. Stop AppPool: /api/iis/apppools/{name}/stop
        if ($path -match "^/api/iis/apppools/([^/]+)/stop$" -and $request.HttpMethod -eq "POST") {
            $poolName = [System.Uri]::UnescapeDataString($Matches[1])
            try {
                Stop-WebAppPool -Name $poolName -ErrorAction Stop
                Send-TextResponse $response 200 "AppPool '$poolName' stopped successfully."
            } catch {
                Send-TextResponse $response 500 "Failed to stop AppPool '$poolName': $_"
            }
            continue
        }

        # 5. Recycle AppPool: /api/iis/apppools/{name}/recycle
        if ($path -match "^/api/iis/apppools/([^/]+)/recycle$" -and $request.HttpMethod -eq "POST") {
            $poolName = [System.Uri]::UnescapeDataString($Matches[1])
            try {
                Restart-WebAppPool -Name $poolName -ErrorAction Stop
                Send-TextResponse $response 200 "AppPool '$poolName' recycled successfully."
            } catch {
                Send-TextResponse $response 500 "Failed to recycle AppPool '$poolName': $_"
            }
            continue
        }

        # 6. Stream Recent Logs: /api/iis/logs/{name}
        if ($path -match "^/api/iis/logs/([^/]+)$" -and $request.HttpMethod -eq "GET") {
            $poolName = [System.Uri]::UnescapeDataString($Matches[1])
            $tail = 100
            if ($request.QueryString["tail"]) {
                [int]::TryParse($request.QueryString["tail"], [ref]$tail) | Out-Null
            }
            $targetPath = $request.QueryString["path"]

            $logContent = "No log files found for AppPool '$poolName'."
            if (![string]::IsNullOrWhiteSpace($targetPath) -and (Test-Path $targetPath)) {
                $candidates = @((Join-Path $targetPath "logs"), $targetPath)
                foreach ($dir in $candidates) {
                    if (Test-Path $dir) {
                        $logFiles = Get-ChildItem -Path $dir -Filter "*.log" -File | Sort-Object LastWriteTime -Descending
                        if ($logFiles.Count -gt 0) {
                            $latest = $logFiles[0]
                            $lines = Get-Content -Path $latest.FullName -Tail $tail -ErrorAction SilentlyContinue
                            $logContent = "=== Latest Log: $($latest.Name) ($($latest.LastWriteTime)) ===`n" + ($lines -join "`n")
                            break
                        }
                    }
                }
            }
            Send-TextResponse $response 200 $logContent
            continue
        }

        # 7. Zero-Lock Atomic Deployment: /api/iis/deploy
        if ($path -eq "/api/iis/deploy" -and $request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $deployReq = $body | ConvertFrom-Json

            $log = New-Object System.Text.StringBuilder
            $log.AppendLine("=== IIS Native Deployment Initiated by Agent ===") | Out-Null
            $log.AppendLine("Service: $($deployReq.ServiceName) | AppPool: $($deployReq.AppPoolName)") | Out-Null

            $targetDir = $deployReq.PhysicalPath
            if ([string]::IsNullOrWhiteSpace($targetDir)) {
                $targetDir = "C:\inetpub\wwwroot\$($deployReq.ServiceName)"
            }

            if (!(Test-Path $deployReq.ArtifactZipPath)) {
                Send-JsonResponse $response 400 @{
                    Success = $false
                    Output = $log.ToString()
                    ErrorMessage = "Artifact zip file '$($deployReq.ArtifactZipPath)' does not exist."
                }
                continue
            }

            if (!(Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            $backupDir = Join-Path $targetDir "_backups"
            if (!(Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            $backupZip = Join-Path $backupDir "pre_deploy_$((Get-Date).ToString('yyyyMMdd_HHmmss')).zip"
            $offlineHtm = Join-Path $targetDir "app_offline.htm"

                # 1. Backup snapshot & prune old pre-deployment backups
                $log.AppendLine("[1/5] Creating pre-deployment directory backup at $(Split-Path $backupZip -Leaf)...") | Out-Null
                try {
                    Compress-Archive -Path "$targetDir\*" -DestinationPath $backupZip -Force -ErrorAction SilentlyContinue
                    # Keep only the last 3 pre-deployment backups to prevent disk bloat
                    $excessBackups = Get-ChildItem -Path $backupDir -Filter "pre_deploy_*.zip" -File -ErrorAction SilentlyContinue |
                                     Sort-Object LastWriteTime -Descending |
                                     Select-Object -Skip 3
                    foreach ($oldBkp in $excessBackups) {
                        Remove-Item -Path $oldBkp.FullName -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    $log.AppendLine("Notice: Initial backup skipped or partial: $_") | Out-Null
                }

                # Prune old application stdout/stderr logs (>7 days)
                $appLogsDir = Join-Path $targetDir "logs"
                if (Test-Path $appLogsDir) {
                    $logCutoff = (Get-Date).AddDays(-7)
                    Get-ChildItem -Path $appLogsDir -Filter "*.log" -File -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.LastWriteTime -lt $logCutoff } |
                        Remove-Item -Force -ErrorAction SilentlyContinue
                }

                # 2. Place app_offline.htm
                $log.AppendLine("[2/5] Placing app_offline.htm to drain active requests...") | Out-Null
                "<html><body><h2>Application update in progress. Please refresh in a moment...</h2></body></html>" | Set-Content -Path $offlineHtm -Force
                Start-Sleep -Seconds 2

                # 3. Extract new artifact
                $log.AppendLine("[3/5] Extracting artifact package $(Split-Path $deployReq.ArtifactZipPath -Leaf)...") | Out-Null
                Expand-Archive -Path $deployReq.ArtifactZipPath -DestinationPath $targetDir -Force

                # 4. Remove app_offline.htm & Recycle
                $log.AppendLine("[4/5] Removing app_offline.htm and recycling AppPool '$($deployReq.AppPoolName)'...") | Out-Null
                if (Test-Path $offlineHtm) {
                    Remove-Item -Path $offlineHtm -Force -ErrorAction SilentlyContinue
                }
                if (![string]::IsNullOrWhiteSpace($deployReq.AppPoolName)) {
                    Restart-WebAppPool -Name $deployReq.AppPoolName -ErrorAction SilentlyContinue
                }

                # 5. Warm-up health probe
                $port = if ($deployReq.InternalPort) { $deployReq.InternalPort } else { 8081 }
                $probePath = if ($deployReq.HealthCheckPath) { $deployReq.HealthCheckPath } else { "/" }
                $probeUrl = "http://127.0.0.1:$port$probePath"
                $log.AppendLine("[5/5] Performing warm-up probe to $probeUrl...") | Out-Null
                
                try {
                    $probe = Invoke-WebRequest -Uri $probeUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction SilentlyContinue
                    $log.AppendLine("Health probe returned HTTP $($probe.StatusCode) ($($probe.StatusDescription))") | Out-Null
                } catch {
                    $log.AppendLine("Notice: Health probe returned: $_ (site may still be warming up)") | Out-Null
                }

                $log.AppendLine("=== IIS Deployment Completed Successfully ===") | Out-Null
                Send-JsonResponse $response 200 @{
                    Success = $true
                    Output = $log.ToString()
                }
            } catch {
                $log.AppendLine("❌ Deployment failed: $_. Restoring previous backup...") | Out-Null
                if (Test-Path $backupZip) {
                    try {
                        Expand-Archive -Path $backupZip -DestinationPath $targetDir -Force
                        $log.AppendLine("Rollback completed successfully.") | Out-Null
                    } catch {
                        $log.AppendLine("Rollback failed: $_") | Out-Null
                    }
                }
                if (Test-Path $offlineHtm) {
                    Remove-Item -Path $offlineHtm -Force -ErrorAction SilentlyContinue
                }
                if (![string]::IsNullOrWhiteSpace($deployReq.AppPoolName)) {
                    Restart-WebAppPool -Name $deployReq.AppPoolName -ErrorAction SilentlyContinue
                }

                Send-JsonResponse $response 500 @{
                    Success = $false
                    Output = $log.ToString()
                    ErrorMessage = "$_"
                }
            }
            continue
        }

        # 404 for unknown endpoints
        Send-JsonResponse $response 404 @{ message = "Endpoint not found: $path" }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
