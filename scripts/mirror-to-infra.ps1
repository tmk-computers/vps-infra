# mirror-to-infra.ps1
$ErrorActionPreference = "Stop"

$srcBase = "d:\company\products\vps-infra\vps-infra-server"
$dstBase = "d:\company\products\vps-infra\vps-infra"

$dirs = @(
    "docs\remediation\phase-0",
    "docs\remediation\phase-0-codex-remediation",
    "docs\remediation\phase-0-review"
)

foreach ($dir in $dirs) {
    $srcDir = Join-Path $srcBase $dir
    $dstDir = Join-Path $dstBase $dir
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    $files = Get-ChildItem -Path $srcDir -Filter "*.md" -Recurse
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($srcDir.Length).TrimStart('\')
        $target = Join-Path $dstDir $rel
        $targetParent = Split-Path $target -Parent
        if (-not (Test-Path $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        Copy-Item -Path $file.FullName -Destination $target -Force
    }
}

Copy-Item -Path (Join-Path $srcBase "scripts\verify-baseline-integrity.ps1") -Destination (Join-Path $dstBase "scripts\verify-baseline-integrity.ps1") -Force
Write-Host "Mirror synchronization completed successfully." -ForegroundColor Green
