#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('Capture','Compare')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [string]$ExpectedVmName,
    [switch]$DisposableVm,
    [string]$ProbeManifest,
    [string]$BaselinePath,
    [string]$CandidatePath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Hash-Text([string]$Value) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Value)))).Replace('-','') }
    finally { $sha.Dispose() }
}
function Write-NewJson($Value) {
    $full = [IO.Path]::GetFullPath($OutputPath)
    # CreateNew deliberately refuses to overwrite evidence.
    $stream = [IO.File]::Open($full, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($Value | ConvertTo-Json -Depth 20))
        $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
}
function Read-Snapshot([string]$Path) {
    $s = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($s.Schema -ne 'w0-preservation/1' -or $s.CaptureStatus -ne 'PASS') { throw 'Incomplete or unsupported snapshot.' }
    foreach ($field in @('Sites','Pools','Services','Probes')) {
        if (@($s.$field).Count -eq 0) { throw "Empty snapshot field: $field" }
        $names = @($s.$field | ForEach-Object { $_.Name })
        if (@($names | Select-Object -Unique).Count -ne $names.Count) { throw "Duplicate snapshot keys: $field" }
    }
    return $s
}

if ($Mode -eq 'Compare') {
    $before = Read-Snapshot $BaselinePath
    $after = Read-Snapshot $CandidatePath
    $findings = New-Object 'System.Collections.Generic.List[object]'
    foreach ($field in @('Machine','OS','ScriptHash','ManifestHash','GlobalConfigHash')) {
        if ($before.$field -cne $after.$field) { $findings.Add([pscustomobject]@{Field=$field; Status='FAIL'}) }
    }
    foreach ($field in @('Sites','Pools','Services','Probes')) {
        foreach ($item in @($before.$field)) {
            $match = @($after.$field | Where-Object { $_.Name -ceq $item.Name })
            if ($match.Count -ne 1 -or ($item | ConvertTo-Json -Depth 15 -Compress) -cne ($match[0] | ConvertTo-Json -Depth 15 -Compress)) {
                $findings.Add([pscustomobject]@{Field=$field; Name=$item.Name; Status='FAIL'})
            }
        }
        # Additional site/pool objects are permitted; services and probes must keep exact scope.
        if ($field -in @('Services','Probes') -and @($before.$field).Count -ne @($after.$field).Count) {
            $findings.Add([pscustomobject]@{Field=$field; Status='FAIL'; Reason='Scope changed'})
        }
    }
    $status = 'PASS'
    if ($findings.Count -gt 0) { $status = 'FAIL' }
    Write-NewJson ([ordered]@{Schema='w0-comparison/1'; Status=$status; Scope='Baseline object preservation only; not W-0 approval'; BaselineHash=(Get-FileHash -LiteralPath $BaselinePath).Hash; CandidateHash=(Get-FileHash -LiteralPath $CandidatePath).Hash; Findings=@($findings.ToArray())})
    if ($status -eq 'FAIL') { throw 'Preservation comparison failed. Review the evidence; this script performs no rollback.' }
    return
}

# The capture path is never executed by offline comparator tests.
if (-not $DisposableVm -or [string]::IsNullOrWhiteSpace($ExpectedVmName) -or $env:COMPUTERNAME -ine $ExpectedVmName) {
    throw 'Capture requires an explicit disposable VM assertion and its exact hostname.'
}
if ($env:COMPUTERNAME -ieq 'WIN-MANOJKARNE') { throw 'The reviewed live host is forbidden.' }
$os = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName
$build = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild
if ($os -notmatch 'Windows Server' -or [int]$build -lt 26100) { throw 'Initial capture requires Windows Server 2025 or later.' }
$manifest = @(Get-Content -LiteralPath $ProbeManifest -Raw | ConvertFrom-Json)
if ($manifest.Count -eq 0) { throw 'Probe manifest cannot be empty.' }
Add-Type -Path (Join-Path $env:windir 'System32\inetsrv\Microsoft.Web.Administration.dll')
$configPath = Join-Path $env:windir 'System32\inetsrv\config\applicationHost.config'
$configBefore = (Get-FileHash -LiteralPath $configPath).Hash
[xml]$xml = Get-Content -LiteralPath $configPath -Raw
$manager = New-Object Microsoft.Web.Administration.ServerManager
try {
    $sites = @($manager.Sites | Sort-Object Name | ForEach-Object {
        $site = $_
        $node = @($xml.configuration.'system.applicationHost'.sites.site | Where-Object { $_.name -ceq $site.Name })
        if ($node.Count -ne 1) { throw 'Site/config inventory mismatch.' }
        [pscustomobject][ordered]@{Name=$site.Name; Id=$site.Id; State=[string]$site.State; ConfigHash=(Hash-Text $node[0].OuterXml); Bindings=@($site.Bindings | Sort-Object Protocol,BindingInformation | ForEach-Object {
            $certHash = ''
            $certStore = ''
            $flags = 0
            if ($_.Protocol -eq 'https') {
                $flags = [int]$_.SslFlags
                if ($_.CertificateHash) { $certHash = [BitConverter]::ToString([byte[]]$_.CertificateHash) }
                $certStore = $_.CertificateStoreName
            }
            [pscustomobject][ordered]@{Protocol=$_.Protocol; Binding=$_.BindingInformation; SslFlags=$flags; CertificateHash=$certHash; CertificateStore=$certStore}
        })}
    })
    $pools = @($manager.ApplicationPools | Sort-Object Name | ForEach-Object {
        $pool = $_
        $node = @($xml.configuration.'system.applicationHost'.applicationPools.add | Where-Object { $_.name -ceq $pool.Name })
        if ($node.Count -ne 1) { throw 'Pool/config inventory mismatch.' }
        [pscustomobject][ordered]@{Name=$pool.Name; State=[string]$pool.State; ConfigHash=(Hash-Text $node[0].OuterXml)}
    })
} finally { $manager.Dispose() }
$services = @(Get-Service -Name W3SVC,WAS | Sort-Object Name | ForEach-Object { [pscustomobject][ordered]@{Name=$_.Name; Status=[string]$_.Status} })
$probes = @()
foreach ($p in $manifest) {
    $uri = [uri]$p.Uri
    if ($uri.Scheme -notin @('http','https') -or $uri.UserInfo -or $uri.Query -or $uri.Fragment) { throw 'Only credential-free HTTP(S) fixture URLs are permitted.' }
    if (@($sites | Where-Object Name -CEQ $p.Site).Count -ne 1) { throw 'Probe must name an inventoried site.' }
    $request = [Net.HttpWebRequest]::Create($uri)
    $request.Proxy = $null
    $request.AllowAutoRedirect = $false
    $request.Timeout = 10000
    $request.ReadWriteTimeout = 10000
    $response = $request.GetResponse()
    try {
        $reader = New-Object IO.StreamReader($response.GetResponseStream())
        try { $bodyHash = Hash-Text $reader.ReadToEnd() } finally { $reader.Dispose() }
        $thumbprint = ''
        if ($uri.Scheme -eq 'https') {
            $certificate = New-Object Security.Cryptography.X509Certificates.X509Certificate2($request.ServicePoint.Certificate)
            try { $thumbprint = $certificate.Thumbprint } finally { $certificate.Dispose() }
            if ($thumbprint -ine $p.ExpectedThumbprint) { throw 'Fixture TLS certificate mismatch.' }
        }
        if ([int]$response.StatusCode -ne [int]$p.ExpectedStatus -or $bodyHash -ine $p.ExpectedBodyHash) { throw 'Fixture response mismatch.' }
        $probes += [pscustomobject][ordered]@{Name=$p.Uri; Site=$p.Site; Status=[int]$response.StatusCode; BodyHash=$bodyHash; Thumbprint=$thumbprint}
    } finally { $response.Dispose() }
}
$protectedSites = $sites
if ($BaselinePath) {
    $reference = Read-Snapshot $BaselinePath
    if ($reference.Machine -ine $env:COMPUTERNAME) { throw 'Baseline belongs to another VM.' }
    $protectedSites = @($sites | Where-Object { $reference.Sites.Name -ccontains $_.Name })
    if ($protectedSites.Count -ne @($reference.Sites).Count) { throw 'A protected baseline site is missing.' }
}
foreach ($site in $protectedSites) {
    foreach ($binding in $site.Bindings) {
        if ($binding.Protocol -in @('http','https') -and @($manifest | Where-Object { $_.Site -ceq $site.Name -and ([uri]$_.Uri).Scheme -eq $binding.Protocol }).Count -eq 0) {
            throw 'Every existing HTTP/HTTPS site protocol requires a baseline probe.'
        }
    }
}
# Hash remaining configuration (including defaults and location overrides), without exporting secrets.
foreach ($node in @($xml.configuration.'system.applicationHost'.sites.site)) { [void]$node.ParentNode.RemoveChild($node) }
foreach ($node in @($xml.configuration.'system.applicationHost'.applicationPools.add)) { [void]$node.ParentNode.RemoveChild($node) }
if ((Get-FileHash -LiteralPath $configPath).Hash -ne $configBefore) { throw 'IIS configuration changed during capture; retry under exclusive fixture change control.' }
Write-NewJson ([ordered]@{Schema='w0-preservation/1'; CaptureStatus='PASS'; CapturedUtc=[DateTime]::UtcNow.ToString('o'); Machine=$env:COMPUTERNAME; OS="$os/$build"; ScriptHash=(Get-FileHash -LiteralPath $PSCommandPath).Hash; ManifestHash=(Get-FileHash -LiteralPath $ProbeManifest).Hash; GlobalConfigHash=(Hash-Text $xml.OuterXml); ApplicationHostHash=$configBefore; Sites=$sites; Pools=$pools; Services=$services; Probes=@($probes | Sort-Object Name)})
