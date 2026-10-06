#requires -Version 5.1
# Read-only VM qualification orchestration. Does not provision or mutate IIS.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ExpectedVmName,
    [Parameter(Mandatory=$true)][string]$ProbeManifest,
    [Parameter(Mandatory=$true)][string]$EvidenceDirectory,
    [Parameter(Mandatory=$true)][switch]$DisposableVm
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $DisposableVm -or $env:COMPUTERNAME -ine $ExpectedVmName -or $env:COMPUTERNAME -ieq 'WIN-MANOJKARNE') {
    throw 'Run only on the explicitly named disposable VM; the reviewed live server is forbidden.'
}
$os = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName
$build = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild
if ($os -notmatch 'Windows Server' -or [int]$build -lt 26100) { throw 'A disposable Windows Server 2025 VM is required.' }
$root = Get-Item -LiteralPath $EvidenceDirectory
if (-not $root.PSIsContainer -or ($root.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'EvidenceDirectory must be an existing ordinary directory with operator-restricted access.'
}
$run = Join-Path $root.FullName ('w0-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($run)
$harness = Join-Path $PSScriptRoot 'Test-W0IisPreservation.ps1'
$before = Join-Path $run 'before.json'
$after = Join-Path $run 'after.json'
$comparison = Join-Path $run 'comparison.json'
$checks = @(
    [ordered]@{Criterion='No-operation preservation'; Status='NOT VERIFIED'}
    [ordered]@{Criterion='Additive managed-site preservation'; Status='NOT VERIFIED'}
    [ordered]@{Criterion='Collision rejection'; Status='NOT VERIFIED'}
    [ordered]@{Criterion='Health-failure scoped rollback'; Status='NOT VERIFIED'}
    [ordered]@{Criterion='Concurrent drift and rollback failure'; Status='NOT VERIFIED'}
    [ordered]@{Criterion='ADR approval'; Status='NOT VERIFIED'}
)
try {
    & $harness -Mode Capture -DisposableVm -ExpectedVmName $ExpectedVmName -ProbeManifest $ProbeManifest -OutputPath $before
    & $harness -Mode Capture -DisposableVm -ExpectedVmName $ExpectedVmName -ProbeManifest $ProbeManifest -BaselinePath $before -OutputPath $after
    & $harness -Mode Compare -BaselinePath $before -CandidatePath $after -OutputPath $comparison
    $checks[0].Status = 'PASS'
} catch {
    $checks[0].Status = 'FAIL'
    throw
} finally {
    $summary = [ordered]@{
        Schema='w0-vm-run/1'; TimestampUtc=[DateTime]::UtcNow.ToString('o')
        Machine=$env:COMPUTERNAME; OS="$os/$build"; OverallW0='NOT VERIFIED'
        Scope='No-operation baseline only; no installer, worker, or rollback implementation exercised'
        RunnerHash=(Get-FileHash -LiteralPath $PSCommandPath).Hash
        HarnessHash=(Get-FileHash -LiteralPath $harness).Hash
        Checks=$checks
    }
    [IO.File]::WriteAllText((Join-Path $run 'summary.json'), ($summary | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
}
Write-Output "Baseline check PASS; W-0 remains NOT VERIFIED. Evidence: $run"
