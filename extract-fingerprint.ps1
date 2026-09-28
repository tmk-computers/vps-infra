# ==============================================================================
# 🔒 VPS-INFRA: HARDWARE FINGERPRINT EXTRACTOR (WINDOWS SERVER)
# ==============================================================================
# Compatible with Windows PowerShell 5.1+ and PowerShell Core 7+
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ANSI Color formatting
$ESC = [char]27
$C_GREEN  = "$ESC[0;32m"
$C_CYAN   = "$ESC[0;36m"
$C_YELLOW = "$ESC[1;33m"
$C_RED    = "$ESC[0;31m"
$C_BOLD   = "$ESC[1m"
$C_RESET  = "$ESC[0m"

Write-Host "${C_CYAN}${C_BOLD}"
Write-Host "======================================================================"
Write-Host "   🔒 VPS-INFRA: HARDWARE FINGERPRINT EXTRACTOR (WINDOWS)"
Write-Host "======================================================================"
Write-Host "${C_RESET}"

Write-Host "${C_CYAN}▶ Extracting permanent Windows hardware identifier...${C_RESET}"

$guid = $null
try {
    $cryptoKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -ErrorAction SilentlyContinue
    if ($cryptoKey -and $cryptoKey.MachineGuid) {
        $guid = $cryptoKey.MachineGuid
    }
} catch {
    $guid = $null
}

if (-not $guid) {
    $guid = "$($env:COMPUTERNAME)-$($env:NUMBER_OF_PROCESSORS)-$([Environment]::OSVersion)"
}

$rawBytes = [System.Text.Encoding]::UTF8.GetBytes("TMK-HW-$guid")
$sha = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha.ComputeHash($rawBytes)
$fingerprint = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()

Write-Host ""
Write-Host "${C_BOLD}Server Hardware Fingerprint:${C_RESET} ${C_GREEN}${C_BOLD}$fingerprint${C_RESET}"
Write-Host ""
Write-Host "${C_YELLOW}💡 How to Request an On-Premise License:${C_RESET}"
Write-Host "Send an email to: ${C_CYAN}licensing@tmkcomputers.in${C_RESET}"
Write-Host "Subject: ${C_BOLD}License Request: Hardware-Locked - [Your Company Name]${C_RESET}"
Write-Host ""
Write-Host "Body template:"
Write-Host "  • Company Name:        [Your Company Name]"
Write-Host "  • Operating System:    $([System.Environment]::OSVersion.VersionString)"
Write-Host "  • Hardware Identifier: $fingerprint"
Write-Host "  • Plan Tier:           Enterprise"
Write-Host ""
