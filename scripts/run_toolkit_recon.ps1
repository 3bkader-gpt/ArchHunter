<#
.SYNOPSIS
    Bug Bounty Toolkit: Master Unified Recon & Parameter Pipeline (PowerShell Native)
    Chains: Subfinder -> TLSX -> DNSX -> HTTPX -> GAU/Wayback/Katana -> URO -> GF -> QSReplace -> KXSS

.PARAMETER Domain
    The target root domain (e.g. example.com).

.EXAMPLE
    .\scripts\run_toolkit_recon.ps1 -Domain "example.com"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain
)

$ErrorActionPreference = "SilentlyContinue"

$reconDir = "recon/$Domain"
New-Item -ItemType Directory -Path "$reconDir/subs", "$reconDir/urls", "$reconDir/params", "$reconDir/reflections", "$reconDir/loot" -Force | Out-Null

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [*] Launching Master Toolkit Recon Pipeline for: $Domain" -ForegroundColor Yellow
Write-Host " [*] Output Directory: $reconDir" -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Cyan

# Phase 1: Subdomain Discovery
Write-Host "`n[+] [1/5] Running Subdomain Discovery (subfinder / cert transparency)..." -ForegroundColor Green
if (Get-Command subfinder -ErrorAction SilentlyContinue) {
    subfinder -d $Domain -all -silent | Set-Content "$reconDir/subs/raw_subs.txt"
} else {
    Write-Host "[*] Subfinder not in PATH, fetching from crt.sh..." -ForegroundColor DarkGray
    try {
        $crtResp = Invoke-RestMethod -Uri "https://crt.sh/?q=%25.$Domain&output=json" -TimeoutSec 15
        $crtSubs = $crtResp | ForEach-Object { $_.name_value.Split("`n") } | Sort-Object -Unique | Where-Object { $_ -notmatch "^\*" }
        $crtSubs | Set-Content "$reconDir/subs/raw_subs.txt"
    } catch {}
}

# TLSX SAN extraction
if (Get-Command tlsx -ErrorAction SilentlyContinue) {
    Get-Content "$reconDir/subs/raw_subs.txt" | tlsx -san -cn -resp-only -silent | Add-Content "$reconDir/subs/raw_subs.txt"
}

# DNSX resolution
if (Get-Command dnsx -ErrorAction SilentlyContinue) {
    Get-Content "$reconDir/subs/raw_subs.txt" | dnsx -silent -o "$reconDir/subs/resolved_subs.txt"
} else {
    Get-Content "$reconDir/subs/raw_subs.txt" | Sort-Object -Unique | Set-Content "$reconDir/subs/resolved_subs.txt"
}

$subCount = (Get-Content "$reconDir/subs/resolved_subs.txt").Count
Write-Host "[+] Discovered $subCount resolved subdomains." -ForegroundColor Cyan

# Phase 2: HTTP Probing
Write-Host "`n[+] [2/5] Probing Live HTTP Services (httpx)..." -ForegroundColor Green
if (Get-Command httpx -ErrorAction SilentlyContinue) {
    Get-Content "$reconDir/subs/resolved_subs.txt" | httpx -ports 80,443,8080,8443 -sc -title -tech-detect -follow-redirects -silent -o "$reconDir/subs/alive_web.txt"
} else {
    Get-Content "$reconDir/subs/resolved_subs.txt" | ForEach-Object { "https://$_" } | Set-Content "$reconDir/subs/alive_web.txt"
}

# Phase 3: Crawling & Historical URL Archaeology
Write-Host "`n[+] [3/5] Extracting Historical URLs & Crawling..." -ForegroundColor Green
if (Get-Command gau -ErrorAction SilentlyContinue) {
    Get-Content "$reconDir/subs/alive_web.txt" | gau --threads 10 | Add-Content "$reconDir/urls/raw_urls.txt"
}
if (Get-Command waybackurls -ErrorAction SilentlyContinue) {
    Get-Content "$reconDir/subs/alive_web.txt" | waybackurls | Add-Content "$reconDir/urls/raw_urls.txt"
}
if (Get-Command katana -ErrorAction SilentlyContinue) {
    katana -list "$reconDir/subs/alive_web.txt" -depth 2 -silent | Add-Content "$reconDir/urls/raw_urls.txt"
}

# Native PS fallback if tools not found
if (-not (Test-Path "$reconDir/urls/raw_urls.txt") -or (Get-Item "$reconDir/urls/raw_urls.txt").Length -eq 0) {
    Write-Host "[*] Fetching archive URLs via AlienVault & Wayback API..." -ForegroundColor DarkGray
    try {
        $otx = Invoke-RestMethod -Uri "https://otx.alienvault.com/api/v1/indicators/domain/$Domain/url_list?limit=50" -TimeoutSec 10
        if ($otx.url_list) { $otx.url_list | ForEach-Object { $_.url } | Set-Content "$reconDir/urls/raw_urls.txt" }
    } catch {}
}

# Phase 4: Normalization & GF Pattern Slicing
Write-Host "`n[+] [4/5] Normalizing URLs & Slicing Patterns..." -ForegroundColor Green
if (Get-Command uro -ErrorAction SilentlyContinue) {
    Get-Content "$reconDir/urls/raw_urls.txt" | uro | Set-Content "$reconDir/urls/clean_urls.txt"
} else {
    Get-Content "$reconDir/urls/raw_urls.txt" | Where-Object { $_ -match "=" } | Sort-Object -Unique | Set-Content "$reconDir/urls/clean_urls.txt"
}

if (Get-Command gf -ErrorAction SilentlyContinue) {
    Get-Content "$reconDir/urls/clean_urls.txt" | gf xss  | Set-Content "$reconDir/params/xss.txt"
    Get-Content "$reconDir/urls/clean_urls.txt" | gf ssrf | Set-Content "$reconDir/params/ssrf.txt"
    Get-Content "$reconDir/urls/clean_urls.txt" | gf idor | Set-Content "$reconDir/params/idor.txt"
} else {
    Get-Content "$reconDir/urls/clean_urls.txt" | Where-Object { $_ -match "(search|query|q|lang|url|redirect|id)=" } | Set-Content "$reconDir/params/xss.txt"
    Get-Content "$reconDir/urls/clean_urls.txt" | Where-Object { $_ -match "(url|dest|redirect|next|target|uri)=" } | Set-Content "$reconDir/params/ssrf.txt"
    Get-Content "$reconDir/urls/clean_urls.txt" | Where-Object { $_ -match "(user_id|account_id|id|uid|org_id)=" } | Set-Content "$reconDir/params/idor.txt"
}

# Phase 5: Reflection Testing
Write-Host "`n[+] [5/5] Testing Parameter Reflections..." -ForegroundColor Green
if (Test-Path "$reconDir/params/xss.txt") {
    if ((Get-Command qsreplace -ErrorAction SilentlyContinue) -and (Get-Command kxss -ErrorAction SilentlyContinue)) {
        Get-Content "$reconDir/params/xss.txt" | qsreplace 'kXss73<"''`>' | kxss | Set-Content "$reconDir/reflections/kxss_reflections.txt"
    } else {
        .\scripts\param_reflection_pipeline.ps1 -UrlFile "$reconDir/params/xss.txt" -OutputFile "$reconDir/reflections/reflected_params.json"
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [+] Master Pipeline Finished Successfully for: $Domain" -ForegroundColor Green
Write-Host "     Results: $reconDir" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
