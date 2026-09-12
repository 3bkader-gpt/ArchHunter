<#
.SYNOPSIS
    Automated Broken Link Hijacking (BLH) & Unclaimed Asset Scanner.
.DESCRIPTION
    Extracts all external links from target URLs/documentation, probes their HTTP status,
    and flags 404/unclaimed handles across GitHub, Twitter/X, LinkedIn, S3, and Bitly.
.EXAMPLE
    pwsh scripts/find_broken_links.ps1 -TargetUrl "https://docs.target.com"
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

Write-Host "`n[+] ==========================================" -ForegroundColor Cyan
Write-Host "[+] Broken Link Hijacking (BLH) Prober" -ForegroundColor Cyan
Write-Host "[+] Target URL: $TargetUrl" -ForegroundColor White
Write-Host "[+] ==========================================`n" -ForegroundColor Cyan

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$outputFile = Join-Path $OutputDir "broken_links_report.jsonl"
$highSignalCandidates = Join-Path $OutputDir "hijackable_candidates.txt"

# 1. Fetch Target Page Content
Write-Host "[*] Fetching content from $TargetUrl..." -ForegroundColor Yellow
try {
    $resp = Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing -TimeoutSec $TimeoutSec -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugBountyResearch/1.0"
    $html = $resp.Content
} catch {
    Write-Host "[-] Failed to fetch target page: $_" -ForegroundColor Red
    exit 1
}

# 2. Extract Hyperlinks
Write-Host "[*] Extracting hyperlinks..." -ForegroundColor Yellow
$linkPattern = 'href=["''](https?://[^"''\s>]+)["'']'
$matches = [regex]::Matches($html, $linkPattern)

$extractedUrls = @()
foreach ($m in $matches) {
    $extractedUrls += $m.Groups[1].Value
}
$uniqueUrls = $extractedUrls | Select-Object -Unique

Write-Host "[+] Found $($uniqueUrls.Count) unique external/internal links." -ForegroundColor Green

# 3. Filter for High-Value Asset Targets
$targetPatterns = @(
    "github.com/",
    "twitter.com/",
    "x.com/",
    "linkedin.com/",
    "s3.amazonaws.com",
    "cname.bitly.com",
    "bit.ly/"
)

$candidateLinks = $uniqueUrls | Where-Object {
    $u = $_
    $matched = $false
    foreach ($pat in $targetPatterns) {
        if ($u -like "*$pat*") { $matched = $true; break }
    }
    $matched
}

Write-Host "[*] Analyzing $($candidateLinks.Count) high-value third-party candidate links..." -ForegroundColor Cyan

# 4. Probe Link Status
$brokenAssets = @()

foreach ($url in $candidateLinks) {
    Write-Host "  -> Probing: $url" -NoNewline
    try {
        $check = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        Write-Host " [OK: $($check.StatusCode)]" -ForegroundColor DarkGray
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($null -eq $status) {
            # Try GET fallback
            try {
                $checkGet = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
                Write-Host " [OK: $($checkGet.StatusCode)]" -ForegroundColor DarkGray
                continue
            } catch {
                $status = $_.Exception.Response.StatusCode.value__
            }
        }

        if ($status -eq 404 -or $status -eq 410) {
            Write-Host " [POTENTIAL HIJACK: HTTP $status]" -ForegroundColor Red
            $entry = [PSCustomObject]@{
                SourceUrl  = $TargetUrl
                BrokenUrl  = $url
                StatusCode = $status
                Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $brokenAssets += $entry
            $entry | ConvertTo-Json -Compress | Out-File -Append -Encoding utf8 $outputFile
            $url | Out-File -Append -Encoding utf8 $highSignalCandidates
        } else {
            Write-Host " [Status: $status]" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n[+] Scan Finished!" -ForegroundColor Green
Write-Host "[+] Total Broken / Potential Hijackable Links: $($brokenAssets.Count)" -ForegroundColor $(if ($brokenAssets.Count -gt 0) { "Red" } else { "Green" })
if ($brokenAssets.Count -gt 0) {
    Write-Host "[!] Review report: $outputFile" -ForegroundColor Yellow
    Write-Host "[!] Candidate list: $highSignalCandidates" -ForegroundColor Yellow
}
