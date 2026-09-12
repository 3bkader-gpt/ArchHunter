param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDomain,

    [Parameter(Mandatory=$false)]
    [string]$WordlistPath = "",

    [Parameter(Mandatory=$false)]
    [switch]$UseWSL
)

$reconDir = "recon/$TargetDomain"
$subsDir = "$reconDir/subs"
$ipsDir = "$reconDir/ips"
$urlsDir = "$reconDir/urls"
$resultsDir = "$reconDir/results"

New-Item -ItemType Directory -Force -Path $subsDir, $ipsDir, $urlsDir, $resultsDir | Out-Null

Write-Host "[+] Initializing Subdomain Recon for: $TargetDomain" -ForegroundColor Green

# Check if user requested WSL or if native binaries are missing
$wslAvailable = $null -ne (Get-Command wsl -ErrorAction SilentlyContinue)
$hasNativeTools = $null -ne (Get-Command subfinder -ErrorAction SilentlyContinue)

if ($UseWSL -or (-not $hasNativeTools -and $wslAvailable)) {
    Write-Host "[*] Executing full pipeline via WSL..." -ForegroundColor Cyan
    $wslCmd = "bash scripts/full_subdomain_recon.sh $TargetDomain"
    if ($WordlistPath) { $wslCmd += " '$WordlistPath'" }
    wsl bash -c $wslCmd
    exit $LASTEXITCODE
}

# Native Windows Execution
Write-Host "[*] Phase 1: Multi-Engine Passive Aggregation (Native Windows)..." -ForegroundColor Cyan
$rawPassive = "$subsDir/raw_passive.txt"
"" | Set-Content $rawPassive

if (Get-Command subfinder -ErrorAction SilentlyContinue) {
    Write-Host "  -> Running subfinder..."
    subfinder -d $TargetDomain -all -silent | Out-File -Append -Encoding utf8 $rawPassive
}

if (Get-Command assetfinder -ErrorAction SilentlyContinue) {
    Write-Host "  -> Running assetfinder..."
    assetfinder --subs-only $TargetDomain | Out-File -Append -Encoding utf8 $rawPassive
}

if (Get-Command findomain -ErrorAction SilentlyContinue) {
    Write-Host "  -> Running findomain..."
    findomain -t $TargetDomain -q | Out-File -Append -Encoding utf8 $rawPassive
}

# Certificate Transparency Query
Write-Host "  -> Querying crt.sh..."
try {
    $crtUrl = "https://crt.sh/?q=%.$TargetDomain&output=json"
    $response = Invoke-RestMethod -Uri $crtUrl -Method Get -TimeoutSec 10 -ErrorAction SilentlyContinue
    if ($response) {
        $crtSubs = $response | ForEach-Object { $_.name_value -split "`n" } | ForEach-Object { $_.Trim().Replace("*.", "") } | Select-Object -Unique
        $crtSubs | Out-File -Append -Encoding utf8 $rawPassive
    }
} catch {
    Write-Host "  [!] crt.sh query timed out or failed." -ForegroundColor Yellow
}

# Deduplicate passive subdomains
$uniquePassive = Get-Content $rawPassive | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Unique
$uniquePassive | Set-Content $rawPassive
Write-Host "[+] Aggregated $($uniquePassive.Count) unique passive subdomains" -ForegroundColor Green

# Phase 2: DNS Resolution
$resolvedFile = "$subsDir/resolved_subs.txt"
if (Get-Command dnsx -ErrorAction SilentlyContinue) {
    Write-Host "[*] Phase 2: Resolving Subdomains with dnsx..." -ForegroundColor Cyan
    Get-Content $rawPassive | dnsx -silent -a -cname -resp -o "$subsDir/dnsx_resolved.txt"
    if (Test-Path "$subsDir/dnsx_resolved.txt") {
        Get-Content "$subsDir/dnsx_resolved.txt" | ForEach-Object { ($_ -split "\s+")[0] } | Select-Object -Unique | Set-Content $resolvedFile
    }
} else {
    $uniquePassive | Set-Content $resolvedFile
}

# Phase 3: HTTPx Liveness & Signal Extraction
$signalsFile = "$reconDir/signals.jsonl"
$aliveHosts = "$subsDir/alive_hosts.txt"

if (Get-Command httpx -ErrorAction SilentlyContinue) {
    Write-Host "[*] Phase 3: Probing HTTP endpoints and extracting signals..." -ForegroundColor Cyan
    Get-Content $resolvedFile | httpx -ports 80,443,8080,8443,3000,8081,9000,5000,50051 -sc -title -web-server -tech-detect -follow-redirects -json -o $signalsFile -silent
    if (Test-Path $signalsFile) {
        Get-Content $signalsFile | ForEach-Object {
            try {
                $obj = $_ | ConvertFrom-Json
                $obj.url
            } catch {}
        } | Select-Object -Unique | Set-Content $aliveHosts
    }
}

$aliveCount = 0
if (Test-Path $aliveHosts) {
    $aliveCount = (Get-Content $aliveHosts).Count
}

Write-Host "`n[+] Full Subdomain Recon Completed!" -ForegroundColor Green
Write-Host "Results:" -ForegroundColor White
Write-Host "- Total Alive Hosts: $aliveCount"
Write-Host "- Signals file: $signalsFile"
