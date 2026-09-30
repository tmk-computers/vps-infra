# verify-baseline-integrity.ps1
# Mechanical baseline integrity and mirror verification script (C3-01)

$ErrorActionPreference = "Stop"

$serverRoot = "d:\company\products\vps-infra\vps-infra-server"
$infraRoot  = "d:\company\products\vps-infra\vps-infra"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   VPS-INFRA BASELINE INTEGRITY VERIFICATION (C3-01)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Parse 02_MASTER_REMEDIATION_REGISTER.md and verify exact MR ID set
$registerFile = Join-Path $serverRoot "docs\remediation\phase-0\02_MASTER_REMEDIATION_REGISTER.md"
if (-not (Test-Path $registerFile)) {
    Write-Error "Register file not found: $registerFile"
}

$lines = Get-Content $registerFile
$mrEntries = $lines | Where-Object { $_ -match '^\|\s*\*\*MR-\d+\*\*' }
$totalMRCount = $mrEntries.Count

Write-Host "`n[Check 1] Master Remediation (MR) Item Count & Exact Set..." -ForegroundColor Yellow
Write-Host "  Found MR entries in table: $totalMRCount"
if ($totalMRCount -ne 37) {
    Write-Error "Assertion Failed: Expected exactly 37 MR entries, found $totalMRCount"
}

# Verify exact ID set MR-01 through MR-37
$foundMrIds = @()
foreach ($entry in $mrEntries) {
    if ($entry -match '\*\*(MR-\d+)\*\*') {
        $foundMrIds += $matches[1]
    }
}
$expectedMrIds = 1..37 | ForEach-Object { "MR-$('{0:D2}' -f $_)" }
$missingMr = $expectedMrIds | Where-Object { $foundMrIds -notcontains $_ }
$extraMr   = $foundMrIds   | Where-Object { $expectedMrIds -notcontains $_ }

if ($missingMr.Count -gt 0 -or $extraMr.Count -gt 0) {
    Write-Error "Assertion Failed: MR ID set mismatch. Missing: $($missingMr -join ', ') Extra: $($extraMr -join ', ')"
} else {
    Write-Host "  PASS: Exact set {MR-01..MR-37} verified with zero duplicates and zero missing." -ForegroundColor Green
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

# 3. Check Traceability Completeness & Target References
$traceFile = Join-Path $serverRoot "docs\remediation\phase-0\03_HISTORICAL_FINDING_TRACEABILITY.md"
$traceLines = Get-Content $traceFile
$fEntries = $traceLines | Where-Object { $_ -match '^\|\s*\*\*F\d+\*\*' }
$defEntries = $traceLines | Where-Object { $_ -match '^\|\s*\*\*DEF-\d+\*\*' }

Write-Host "`n[Check 3] Historical Finding Traceability Exact Sets & Target Validity..." -ForegroundColor Yellow
Write-Host "  Historical Codex F-findings: $($fEntries.Count) (Expected: 22)"
Write-Host "  Historical Antigravity DEF-defects: $($defEntries.Count) (Expected: 37)"

if ($fEntries.Count -ne 22 -or $defEntries.Count -ne 37) {
    Write-Error "Assertion Failed: Historical finding count mismatch (Expected: 22 F, 37 DEF)."
}

# Check exact sets
$foundFIds = @()
foreach ($entry in $fEntries) {
    if ($entry -match '\*\*(F\d+)\*\*') { $foundFIds += $matches[1] }
}
$expectedFIds = 1..22 | ForEach-Object { "F$('{0:D2}' -f $_)" }
$missingF = $expectedFIds | Where-Object { $foundFIds -notcontains $_ }

$foundDefIds = @()
foreach ($entry in $defEntries) {
    if ($entry -match '\*\*(DEF-\d+)\*\*') { $foundDefIds += $matches[1] }
}
$expectedDefIds = 1..37 | ForEach-Object { "DEF-$('{0:D2}' -f $_)" }
$missingDef = $expectedDefIds | Where-Object { $foundDefIds -notcontains $_ }

if ($missingF.Count -gt 0 -or $missingDef.Count -gt 0) {
    Write-Error "Assertion Failed: Finding ID set mismatch. Missing F: $($missingF -join ', ') Missing DEF: $($missingDef -join ', ')"
} else {
    Write-Host "  PASS: Exact sets {F01..F22} and {DEF-01..DEF-37} verified." -ForegroundColor Green
}

# Validate all mapped target MR references exist in the 37 MR set across ALL table rows
$allTableRows = $traceLines | Where-Object { $_ -match '^\|\s*\*\*' }
$invalidTargetRefs = @()
foreach ($row in $allTableRows) {
    $matchedMRs = [regex]::Matches($row, 'MR-\d+')
    foreach ($m in $matchedMRs) {
        if ($expectedMrIds -notcontains $m.Value) {
            $invalidTargetRefs += $m.Value
        }
    }
}
if ($invalidTargetRefs.Count -gt 0) {
    Write-Error "Assertion Failed: Invalid MR targets found in traceability table rows: $($invalidTargetRefs -join ', ')"
} else {
    Write-Host "  PASS: All referenced MR targets across all table rows in traceability are valid members of {MR-01..MR-37}." -ForegroundColor Green
}

# 4. Forward and Reverse Mirror Verification Check
Write-Host "`n[Check 4] Cross-Repository Forward & Reverse Mirror Equality..." -ForegroundColor Yellow

$dirsToVerify = @(
    "docs\remediation\phase-0",
    "docs\remediation\phase-0-codex-remediation",
    "docs\remediation\phase-0-codex-regate-remediation",
    "docs\remediation\phase-0-final-closure",
    "docs\remediation\phase-0-final-codex-correction",
    "docs\remediation\phase-0-final-c2-04-correction",
    "docs\remediation\phase-0-review"
)

$allMatched = $true
$fileCount = 0

foreach ($relDir in $dirsToVerify) {
    $srcDir = Join-Path $serverRoot $relDir
    $dstDir = Join-Path $infraRoot $relDir

    if (-not (Test-Path $srcDir)) {
        Write-Error "Assertion Failed: Required source dossier directory missing: $srcDir"
    }
    if (-not (Test-Path $dstDir)) {
        Write-Error "Assertion Failed: Required mirror destination directory missing: $dstDir"
    }

    # Forward check: server -> infra
    $srcFiles = Get-ChildItem -Path $srcDir -Filter "*.md" -Recurse
    foreach ($file in $srcFiles) {
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

    # Reverse check: infra -> server (asserting no rogue/orphaned files)
    if (Test-Path $dstDir) {
        $dstFiles = Get-ChildItem -Path $dstDir -Filter "*.md" -Recurse
        foreach ($file in $dstFiles) {
            $relPath = $file.FullName.Substring($infraRoot.Length + 1)
            $srcCounterpart = Join-Path $serverRoot $relPath
            if (-not (Test-Path $srcCounterpart)) {
                Write-Host "  ROGUE FILE IN MIRROR: $relPath" -ForegroundColor Red
                $allMatched = $false
            }
        }
    }
}

if (-not $allMatched) {
    Write-Error "Assertion Failed: Mirror files do not match bit-for-bit."
} else {
    Write-Host "  PASS: $fileCount documentation artifacts verified with 100% bit-for-bit SHA-256 equality across all $($dirsToVerify.Count) active directories." -ForegroundColor Green
}

# 5. Stale Forbidden Phrases Scan in Authoritative Phase 0 Baseline
Write-Host "`n[Check 5] Stale Forbidden Phrases Scan in docs/remediation/phase-0..." -ForegroundColor Yellow
$authDir = Join-Path $serverRoot "docs\remediation\phase-0"
$authFiles = Get-ChildItem -Path $authDir -Filter "*.md"

$forbiddenPatterns = @(
    @{ Pattern = 'restore pre-upgrade database'; Description = 'Automatic pre-upgrade database restore' },
    @{ Pattern = 'StartsWith\(tenantSandboxRoot'; Description = 'Naive StartsWith path traversal check' },
    @{ Pattern = 'Trust Server Certificate\s*=\s*true'; Description = 'Insecure TLS certificate trust' },
    @{ Pattern = 'Redis denylist'; Description = 'Mandatory Redis denylist requirement' },
    @{ Pattern = '\bLocalService\b'; Description = 'Unqualified LocalService agent identity' },
    @{ Pattern = 'Optional / Not Gate-A Certified Dependency'; Description = 'Stale Redis exclusion classification' },
    @{ Pattern = 'revocation grace (period|window)'; Description = 'Stale revocation grace period semantics' },
    @{ Pattern = 'SSL Mode\s*=\s*Require\s*;\s*Trust Server Certificate\s*=\s*false'; Description = 'Stale Npgsql Require TLS alternative' },
    @{ Pattern = 'MonitoringService\.cs:213'; Description = 'False pruning attribution to MonitoringService.cs:213' },
    @{ Pattern = 'active pruning.*MonitoringService'; Description = 'False claim that active pruning resides in MonitoringService' }
)

$forbiddenFound = 0
foreach ($file in $authFiles) {
    $content = Get-Content $file.FullName -Raw
    foreach ($fp in $forbiddenPatterns) {
        if ($content -match $fp.Pattern) {
            Write-Host "  FORBIDDEN TEXT FOUND in $($file.Name): $($fp.Description)" -ForegroundColor Red
            $forbiddenFound++
        }
    }
}

if ($forbiddenFound -gt 0) {
    Write-Error "Assertion Failed: Found $forbiddenFound forbidden stale phrases in authoritative Phase 0 baseline."
} else {
    Write-Host "  PASS: Zero forbidden stale phrases found in authoritative Phase 0 baseline." -ForegroundColor Green
}

# 6. Authoritative Security Invariants & Correction Dossier Existence
Write-Host "`n[Check 6] Authoritative Invariant Language & Dossier Existence..." -ForegroundColor Yellow
$correctionDir = Join-Path $serverRoot "docs\remediation\phase-0-final-codex-correction"
if (-not (Test-Path $correctionDir)) {
    Write-Error "Assertion Failed: Required correction dossier missing: $correctionDir"
}

$secDoc = Join-Path $authDir "08_SECURITY_BOUNDARIES.md"
$revocationEffectiveFound = $false
if (Test-Path $secDoc) {
    $secContent = Get-Content $secDoc -Raw
    if ($secContent -match 'Revocation Effective Point') {
        $revocationEffectiveFound = $true
    }
}

if (-not $revocationEffectiveFound) {
    Write-Error "Assertion Failed: Canonical 'Revocation Effective Point' invariant missing from 08_SECURITY_BOUNDARIES.md."
} else {
    Write-Host "  PASS: Canonical 'Revocation Effective Point' invariant verified in authoritative security baseline." -ForegroundColor Green
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "   ALL MECHANICAL INTEGRITY CHECKS PASSED (EXIT 0)  " -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan
exit 0
