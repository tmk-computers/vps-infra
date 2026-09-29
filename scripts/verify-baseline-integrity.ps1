# verify-baseline-integrity.ps1
# Mechanical baseline integrity and mirror verification script (C3-01)

$ErrorActionPreference = "Stop"

$serverRoot = "d:\company\products\vps-infra\vps-infra-server"
$infraRoot  = "d:\company\products\vps-infra\vps-infra"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   VPS-INFRA BASELINE INTEGRITY VERIFICATION (C3-01)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Parse 02_MASTER_REMEDIATION_REGISTER.md
$registerFile = Join-Path $serverRoot "docs\remediation\phase-0\02_MASTER_REMEDIATION_REGISTER.md"
if (-not (Test-Path $registerFile)) {
    Write-Error "Register file not found: $registerFile"
}

$lines = Get-Content $registerFile
$mrEntries = $lines | Where-Object { $_ -match '^\|\s*\*\*MR-\d+\*\*' }
$totalMRCount = $mrEntries.Count

Write-Host "`n[Check 1] Master Remediation (MR) Item Count..." -ForegroundColor Yellow
Write-Host "  Found MR entries in table: $totalMRCount"
if ($totalMRCount -ne 37) {
    Write-Error "Assertion Failed: Expected exactly 37 MR entries, found $totalMRCount"
} else {
    Write-Host "  PASS: Exactly 37 MR entries verified." -ForegroundColor Green
}

# 2. Check Status Distribution Arithmetic
$openCount = ($mrEntries | Where-Object { $_ -match '`OPEN`' }).Count
$partialCount = ($mrEntries | Where-Object { $_ -match '`PARTIALLY_IMPLEMENTED`' }).Count
$implNotVerCount = ($mrEntries | Where-Object { $_ -match '`IMPLEMENTED_NOT_VERIFIED`' }).Count
$sumStatuses = $openCount + $partialCount + $implNotVerCount

Write-Host "`n[Check 2] Status Arithmetic Validation..." -ForegroundColor Yellow
Write-Host "  OPEN: $openCount"
Write-Host "  PARTIALLY_IMPLEMENTED: $partialCount"
Write-Host "  IMPLEMENTED_NOT_VERIFIED: $implNotVerCount"
Write-Host "  Total Status Sum: $sumStatuses"

if ($sumStatuses -ne 37 -or $openCount -ne 33 -or $partialCount -ne 3 -or $implNotVerCount -ne 1) {
    Write-Error "Assertion Failed: Status sum does not match expected (33 OPEN, 3 PARTIAL, 1 IMPL_NOT_VERIFIED = 37)"
} else {
    Write-Host "  PASS: Exact status distribution verified (33 + 3 + 1 = 37)." -ForegroundColor Green
}

# 3. Check Traceability Completeness
$traceFile = Join-Path $serverRoot "docs\remediation\phase-0\03_HISTORICAL_FINDING_TRACEABILITY.md"
$traceLines = Get-Content $traceFile
$fEntries = $traceLines | Where-Object { $_ -match '^\|\s*\*\*F\d+\*\*' }
$defEntries = $traceLines | Where-Object { $_ -match '^\|\s*\*\*DEF-\d+\*\*' }

Write-Host "`n[Check 3] Historical Finding Traceability Completeness..." -ForegroundColor Yellow
Write-Host "  Historical Codex F-findings traced: $($fEntries.Count) (Expected: 22)"
Write-Host "  Historical Antigravity DEF-defects traced: $($defEntries.Count) (Expected: 37)"

if ($fEntries.Count -ne 22 -or $defEntries.Count -ne 37) {
    Write-Error "Assertion Failed: Historical findings incomplete in traceability matrix."
} else {
    Write-Host "  PASS: 100% of historical findings (22 F-findings + 37 DEF-defects) traced." -ForegroundColor Green
}

# 4. Bit-for-Bit Mirror Equality Check
Write-Host "`n[Check 4] Cross-Repository Mirror SHA-256 Equality..." -ForegroundColor Yellow

$dirsToVerify = @(
    "docs\remediation\phase-0",
    "docs\remediation\phase-0-codex-remediation",
    "docs\remediation\phase-0-review"
)

$allMatched = $true
$fileCount = 0

foreach ($relDir in $dirsToVerify) {
    $srcDir = Join-Path $serverRoot $relDir
    $dstDir = Join-Path $infraRoot $relDir

    if (-not (Test-Path $srcDir)) { continue }

    $files = Get-ChildItem -Path $srcDir -Filter "*.md" -Recurse
    foreach ($file in $files) {
        $fileCount++
        $relPath = $file.FullName.Substring($serverRoot.Length + 1)
        $targetFile = Join-Path $infraRoot $relPath

        if (-not (Test-Path $targetFile)) {
            Write-Host "  MISSING IN MIRROR: $relPath" -ForegroundColor Red
            $allMatched = $false
            continue
        }

        $srcHash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $targetFile -Algorithm SHA256).Hash

        if ($srcHash -ne $dstHash) {
            Write-Host "  HASH MISMATCH: $relPath" -ForegroundColor Red
            $allMatched = $false
        }
    }
}

if (-not $allMatched) {
    Write-Error "Assertion Failed: Mirror files do not match bit-for-bit."
} else {
    Write-Host "  PASS: $fileCount documentation artifacts verified with 100% bit-for-bit SHA-256 equality." -ForegroundColor Green
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "   ALL MECHANICAL INTEGRITY CHECKS PASSED (EXIT 0)  " -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan
exit 0
