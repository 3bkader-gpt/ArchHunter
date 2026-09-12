<#
.SYNOPSIS
    Automated JavaScript Asset, Secret & API Route Extractor.
.DESCRIPTION
    Scans a target webpage for JavaScript bundles, checks for exposed .js.map source files,
    extracts internal API routes, and detects hardcoded credentials and cloud API keys.
.EXAMPLE
    pwsh scripts/extract_js_secrets.ps1 -TargetUrl "https://target.com"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetUrl,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "recon_output",

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSec = 10
)

$ErrorActionPreference = "Continue"

Write-Host "`n[+] ==================================================" -ForegroundColor Cyan
Write-Host "[+] JavaScript Secret & API Route Extractor" -ForegroundColor Cyan
Write-Host "[+] Target URL: $TargetUrl" -ForegroundColor White
Write-Host "[+] ==================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$reportFile = Join-Path $OutputDir "js_secrets_report.jsonl"
$routesFile = Join-Path $OutputDir "extracted_api_routes.txt"

# 1. Fetch Target Webpage
Write-Host "[*] Fetching page content..." -ForegroundColor Yellow
try {
    $resp = Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing -TimeoutSec $TimeoutSec -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0.0.0"
    $html = $resp.Content
} catch {
    Write-Host "[-] Failed to fetch initial webpage: $_" -ForegroundColor Red
    exit 1
}

# 2. Extract Script Tags
Write-Host "[*] Extracting script references..." -ForegroundColor Yellow
$scriptMatches = [regex]::Matches($html, '<script[^>]+src=["'']([^"'']+)["'']')

$baseUri = [System.Uri]$TargetUrl
$scriptUrls = @()

foreach ($m in $scriptMatches) {
    $src = $m.Groups[1].Value
    try {
        $fullUri = [System.Uri]::new($baseUri, $src).AbsoluteUri
        if ($fullUri -like "*.js*") {
            $scriptUrls += $fullUri
        }
    } catch {}
}

$uniqueScripts = $scriptUrls | Select-Object -Unique
Write-Host "[+] Discovered $($uniqueScripts.Count) JavaScript files." -ForegroundColor Green

# 3. Secret Pattern Signatures
$secretSignatures = @{
    "AWS Access Key"     = '\b(AKIA[0-9A-Z]{16})\b'
    "Google API Key"     = '\b(AIza[0-9A-Za-z\-_]{35})\b'
    "Firebase URL"       = '([a-z0-9.-]+\.firebaseio\.com)'
    "Stripe Publishable" = '\b(pk_live_[0-9a-zA-Z]{24})\b'
    "Slack Token"        = '\b(xox[baprs]-[0-9a-zA-Z]{10,48})\b'
    "Generic Bearer/JWT" = '\b(eyJ[A-Za-z0-9\-_=]{20,}\.[A-Za-z0-9\-_=]{20,}\.[A-Za-z0-9\-_=]+)\b'
}

$apiRoutePattern = '["''`](/(?:api|v[0-9]|graphql|auth|admin|internal)/[a-zA-Z0-9_\-/]+)["''`]'

$allFoundRoutes = @()
$totalSecretsFound = 0

# 4. Probe and Analyze Each Script
foreach ($jsUrl in $uniqueScripts) {
    Write-Host "`n[*] Inspecting: $jsUrl" -ForegroundColor Cyan
    try {
        $jsResp = Invoke-WebRequest -Uri $jsUrl -UseBasicParsing -TimeoutSec $TimeoutSec -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0.0.0"
        $jsContent = $jsResp.Content
    } catch {
        Write-Host "  [-] Failed to download script." -ForegroundColor DarkGray
        continue
    }

    # Check for Source Map (.js.map)
    $mapUrl = "$jsUrl.map"
    try {
        $mapCheck = Invoke-WebRequest -Uri $mapUrl -Method Head -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($mapCheck.StatusCode -eq 200) {
            Write-Host "  [!] EXPOSED SOURCE MAP FOUND: $mapUrl" -ForegroundColor Red
            $entry = [PSCustomObject]@{
                Type      = "Exposed Source Map"
                ScriptUrl = $jsUrl
                MapUrl    = $mapUrl
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $entry | ConvertTo-Json -Compress | Out-File -Append -Encoding utf8 $reportFile
        }
    } catch {}

    # Extract API Routes
    $routeMatches = [regex]::Matches($jsContent, $apiRoutePattern)
    $routesInScript = @()
    foreach ($rm in $routeMatches) {
        $route = $rm.Groups[1].Value
        $routesInScript += $route
        $allFoundRoutes += $route
    }
    $uniqueRoutesInScript = $routesInScript | Select-Object -Unique
    if ($uniqueRoutesInScript.Count -gt 0) {
        Write-Host "  [+] Extracted $($uniqueRoutesInScript.Count) internal API endpoints." -ForegroundColor Yellow
    }

    # Scan for Secrets
    foreach ($name in $secretSignatures.Keys) {
        $pat = $secretSignatures[$name]
        $matches = [regex]::Matches($jsContent, $pat)
        foreach ($match in $matches) {
            $secretVal = $match.Groups[1].Value
            Write-Host "  [CRITICAL LEAK] ${name}: $secretVal" -ForegroundColor Red
            $totalSecretsFound++
            $entry = [PSCustomObject]@{
                Type      = $name
                Secret    = $secretVal
                ScriptUrl = $jsUrl
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $entry | ConvertTo-Json -Compress | Out-File -Append -Encoding utf8 $reportFile
        }
    }
}

# 5. Output Summary
$finalUniqueRoutes = $allFoundRoutes | Select-Object -Unique
if ($finalUniqueRoutes.Count -gt 0) {
    $finalUniqueRoutes | Out-File -Encoding utf8 $routesFile
}

Write-Host "`n[+] JavaScript Scan Completed!" -ForegroundColor Green
Write-Host "[+] Total Unique API Routes Discovered: $($finalUniqueRoutes.Count)" -ForegroundColor Green
Write-Host "[+] Total Hardcoded Secrets Flagged: $totalSecretsFound" -ForegroundColor $(if ($totalSecretsFound -gt 0) { "Red" } else { "Green" })
Write-Host "[!] API Routes list saved to: $routesFile" -ForegroundColor White
Write-Host "[!] Secrets & findings saved to: $reportFile" -ForegroundColor White
