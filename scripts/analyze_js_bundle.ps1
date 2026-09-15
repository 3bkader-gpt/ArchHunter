<#
.SYNOPSIS
    13-Pattern Targeted JavaScript Bundle Analyzer for Offensive Recon.
.DESCRIPTION
    Analyzes local or remote JavaScript bundles using the 13 high-precision offensive regex
    patterns to extract API endpoints, admin functions, auth flows, object parameters,
    GraphQL queries, WebSockets, and source maps.
.EXAMPLE
    pwsh scripts/analyze_js_bundle.ps1 -JsFile "recon/js/main.js"
.EXAMPLE
    pwsh scripts/analyze_js_bundle.ps1 -JsDirectory "recon/js" -OutputDir "recon/api"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$JsFile,

    [Parameter(Mandatory = $false)]
    [string]$JsDirectory,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "recon/api"
)

$ErrorActionPreference = "Continue"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " 🏛️ ArchHunter: 13-Pattern JS Bundle Deep Inspector" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$targetFiles = @()

if ($JsFile -and (Test-Path $JsFile)) {
    $targetFiles += (Get-Item $JsFile)
}
elseif ($JsDirectory -and (Test-Path $JsDirectory)) {
    $targetFiles += Get-ChildItem -Path $JsDirectory -Filter "*.js" -Recurse
}
else {
    Write-Host "[-] Please provide a valid -JsFile or -JsDirectory." -ForegroundColor Red
    exit 1
}

Write-Host "[*] Analyzing $($targetFiles.Count) JavaScript file(s)..." -ForegroundColor Yellow

$Patterns = [ordered]@{
    "1. API Endpoints"           = '(?i)["''](/api/[a-zA-Z0-9_\-\./]+)["'']'
    "2. Full External URLs"      = 'https?://[a-zA-Z0-9_\-\.:]+(?:/[a-zA-Z0-9_\-\./\?&=%#]*)?'
    "3. Route Keywords"          = '(?i)["''](/[a-zA-Z0-9_\-/]*(?:api|endpoint|route|gateway)[a-zA-Z0-9_\-/]*)["'']'
    "4. Admin Controls"          = '(?i)["''](/[a-zA-Z0-9_\-/]*(?:admin|administrator|management|superadmin)[a-zA-Z0-9_\-/]*)["'']'
    "5. Auth & Registration"     = '(?i)["''](/[a-zA-Z0-9_\-/]*(?:login|logout|signin|signup|register|auth|oauth|token|sso)[a-zA-Z0-9_\-/]*)["'']'
    "6. User & Account Surfaces" = '(?i)["''](/[a-zA-Z0-9_\-/]*(?:user|account|profile|settings|tenant|org)[a-zA-Z0-9_\-/]*)["'']'
    "7. Sensitive ID Parameters" = '(?i)(?:id=|userId|user_id|accountId|account_id|orgId|org_id|tenantId|redirect|returnUrl)[=:]["''a-zA-Z0-9_\-]*'
    "8. API Versions (Legacy)"   = '(?i)["''](/api/v\d+/[a-zA-Z0-9_\-\./]+)["'']'
    "9. WebSocket Channels"      = '(?i)wss?://[a-zA-Z0-9_\-\.:]+[a-zA-Z0-9_\-\./]*'
    "10. Config & Data Files"    = '(?i)["'']([/a-zA-Z0-9_\-\.]+\.(?:php|json|xml|config|graphql|env|yaml|yml))["'']'
    "11. GraphQL Operations"     = '(?i)(?:mutation|query|subscription)\s+[a-zA-Z0-9_]+'
    "12. Source Map Pointers"    = '(?i)["'']([^"'']+\.map)["'']|//#\s*sourceMappingURL=([^\s]+)'
    "13. HTTP Client Invocations"= '(?i)(?:fetch\(|axios\.(?:get|post|put|delete|patch)\(|XMLHttpRequest)'
}

$Results = @{}
foreach ($category in $Patterns.Keys) {
    $Results[$category] = [System.Collections.Generic.HashSet[string]]::new()
}

foreach ($file in $targetFiles) {
    Write-Host "[*] Processing: $($file.Name)" -ForegroundColor Cyan
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
    } catch {
        Write-Host "[-] Could not read $($file.FullName): $_" -ForegroundColor Red
        continue
    }

    foreach ($category in $Patterns.Keys) {
        $regex = [regex]$Patterns[$category]
        $matches = $regex.Matches($content)
        foreach ($match in $matches) {
            # Capture inner group if exists, else full match
            $val = if ($match.Groups.Count -gt 1 -and $match.Groups[1].Value) { $match.Groups[1].Value } else { $match.Value }
            $val = $val.Trim("`"' ")
            if ($val.Length -gt 1 -and $val.Length -lt 250) {
                [void]$Results[$category].Add($val)
            }
        }
    }
}

Write-Host "`n[+] ================= 13-PATTERN SUMMARY ==================" -ForegroundColor Green
foreach ($category in $Patterns.Keys) {
    $count = $Results[$category].Count
    $color = if ($count -gt 0) { "White" } else { "DarkGray" }
    Write-Host "  [$category]: $count unique hits" -ForegroundColor $color
}
Write-Host "========================================================`n" -ForegroundColor Green

# Save Results to Output Files
$apiListFile = Join-Path $OutputDir "api-list.txt"
$reportJsonFile = Join-Path $OutputDir "js_analysis_report.json"

$allApis = [System.Collections.Generic.HashSet[string]]::new()
foreach ($item in $Results["1. API Endpoints"]) { [void]$allApis.Add($item) }
foreach ($item in $Results["8. API Versions (Legacy)"]) { [void]$allApis.Add($item) }
foreach ($item in $Results["4. Admin Controls"]) { [void]$allApis.Add($item) }

$allApis | Sort-Object | Out-File -FilePath $apiListFile -Encoding utf8
Write-Host "[+] Extracted $(@($allApis).Count) unique API endpoints to: $apiListFile" -ForegroundColor Green

$jsonReport = [ordered]@{}
foreach ($category in $Patterns.Keys) {
    $jsonReport[$category] = @($Results[$category] | Sort-Object)
}
$jsonReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportJsonFile -Encoding utf8
Write-Host "[+] Full 13-Pattern JSON report saved to: $reportJsonFile" -ForegroundColor Green
