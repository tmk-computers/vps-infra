#requires -Version 5.1
# Synthetic comparator regression tests. Never invokes Capture or accesses IIS.
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'Test-W0IisPreservation.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('w0-fixtures-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($root)
$baseline = [ordered]@{
    Schema='w0-preservation/1'; CaptureStatus='PASS'; Machine='DISPOSABLE-W0'; OS='Windows Server 2025/26100'
    ScriptHash='fixture'; ManifestHash='fixture'; GlobalConfigHash='globals'
    Sites=@([ordered]@{Name='existing'; Id=1; State='Started'; ConfigHash='site'; Bindings=@([ordered]@{Protocol='https'; Binding='*:443:existing.test'; SslFlags=1; CertificateHash='CERT'; CertificateStore='My'})})
    Pools=@([ordered]@{Name='existing-pool'; State='Started'; ConfigHash='pool'})
    Services=@([ordered]@{Name='W3SVC'; Status='Running'})
    Probes=@([ordered]@{Name='https://existing.test/'; Site='existing'; Status=200; BodyHash='fixture-body'; Thumbprint='CERT'})
}
$basePath = Join-Path $root 'baseline.json'
$baseline | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $basePath -Encoding UTF8
$cases = @(
    @{Name='unchanged'; Pass=$true; Change={param($s)}}
    @{Name='new-managed-site'; Pass=$true; Change={param($s) $s.Sites += [pscustomobject]@{Name='new-managed'; Id=2}; $s.Pools += [pscustomobject]@{Name='new-pool'}}}
    @{Name='binding-drift'; Pass=$false; Change={param($s) $s.Sites[0].Bindings[0].Binding='*:443:wrong.test'}}
    @{Name='certificate-drift'; Pass=$false; Change={param($s) $s.Probes[0].Thumbprint='WRONG'}}
    @{Name='site-removed'; Pass=$false; Change={param($s) $s.Sites=@()}}
    @{Name='service-stopped'; Pass=$false; Change={param($s) $s.Services[0].Status='Stopped'}}
    @{Name='pool-drift'; Pass=$false; Change={param($s) $s.Pools[0].ConfigHash='changed'}}
    @{Name='global-drift'; Pass=$false; Change={param($s) $s.GlobalConfigHash='changed'}}
    @{Name='wrong-machine'; Pass=$false; Change={param($s) $s.Machine='OTHER'}}
    @{Name='empty-probes'; Pass=$false; Change={param($s) $s.Probes=@()}}
    @{Name='duplicate-site'; Pass=$false; Change={param($s) $s.Sites += $s.Sites[0]}}
    @{Name='incomplete-capture'; Pass=$false; Change={param($s) $s.CaptureStatus='NOT VERIFIED'}}
)
foreach ($case in $cases) {
    $candidate = Get-Content -LiteralPath $basePath -Raw | ConvertFrom-Json
    & $case.Change $candidate
    $candidatePath = Join-Path $root ($case.Name + '.json')
    $output = Join-Path $root ($case.Name + '-result.json')
    $candidate | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $candidatePath -Encoding UTF8
    $passed = $true
    try { & $scriptPath -Mode Compare -BaselinePath $basePath -CandidatePath $candidatePath -OutputPath $output }
    catch { $passed = $false }
    if ($passed -ne $case.Pass) { throw "Unexpected result: $($case.Name). Evidence: $root" }
    if ($passed -and (Get-Content -LiteralPath $output -Raw | ConvertFrom-Json).Status -ne 'PASS') { throw 'Missing PASS evidence.' }
}
try {
    & $scriptPath -Mode Compare -BaselinePath $basePath -CandidatePath $basePath -OutputPath (Join-Path $root 'unchanged-result.json')
    throw 'OVERWRITE_ACCEPTED'
} catch { if ($_.Exception.Message -eq 'OVERWRITE_ACCEPTED') { throw } }
Write-Output "PASS: $($cases.Count) synthetic comparator cases and evidence overwrite rejection. Evidence retained: $root"
