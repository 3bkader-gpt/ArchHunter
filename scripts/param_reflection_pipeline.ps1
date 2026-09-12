<#
.SYNOPSIS
    Automated Parameter Extraction & Context Reflection Pipeline (qsreplace + kxss equivalent in pure PowerShell).
    Extracts URLs, normalizes parameters, injects canary tokens, and analyzes reflection context (HTML tag, attribute, JS script).

.DESCRIPTION
    Replicates the core functionality of gf -> uro -> qsreplace -> kxss/dalfox pipeline:
    1. Normalizes and deduplicates URLs with query parameters.
    2. Injects canary tokens containing test characters: " ' < > ` { } ;
    3. Performs concurrent HTTP requests.
    4. Evaluates reflection:
       - Exact match of canary
       - Unfiltered reflection of dangerous chars: < > " ' `
       - Reflection Context: Tag content, HTML attribute, inline <script>, or comment.

.EXAMPLE
    .\scripts\param_reflection_pipeline.ps1 -TargetDomain "example.com" -MaxUrls 50
    Get-Content urls.txt | .\scripts\param_reflection_pipeline.ps1 -Concurrency 10
#>

param(
    [string]$TargetDomain,
    [string]$UrlFile,
    [string[]]$Urls,
    [int]$Concurrency = 5,
    [int]$TimeoutSec = 8,
    [string]$OutputFile = "recon/params/reflected_params.json",
    [string]$CanaryPrefix = "bxss"
)

$ErrorActionPreference = "SilentlyContinue"

# Collect URLs
$rawUrls = [System.Collections.Generic.List[string]]::new()

if ($Urls) {
    $rawUrls.AddRange($Urls)
}
if ($UrlFile -and (Test-Path $UrlFile)) {
    Get-Content $UrlFile | Where-Object { $_ -match "^https?://" } | ForEach-Object { $rawUrls.Add($_.Trim()) }
}
if ($TargetDomain) {
    Write-Host "[*] Fetching historical URLs for $TargetDomain via AlienVault OTX & Wayback..." -ForegroundColor Cyan
    try {
        # Alienvault OTX
        $otxUrl = "https://otx.alienvault.com/api/v1/indicators/domain/$TargetDomain/url_list?limit=100&page=1"
        $otxResp = Invoke-RestMethod -Uri $otxUrl -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($otxResp.url_list) {
            foreach ($item in $otxResp.url_list) {
                if ($item.url -match "^https?://") { $rawUrls.Add($item.url) }
            }
        }
    } catch {}

    try {
        # Wayback CDX
        $wbUrl = "https://web.archive.org/cdx/search/cdx?url=*.$TargetDomain/*&output=json&collapse=urlkey&limit=200"
        $wbResp = Invoke-RestMethod -Uri $wbUrl -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($wbResp -and $wbResp.Count -gt 1) {
            for ($i = 1; $i -lt [Math]::Min($wbResp.Count, 200); $i++) {
                $rawUrls.Add($wbResp[$i][2])
            }
        }
    } catch {}
}

if ($rawUrls.Count -eq 0) {
    Write-Host "[-] No URLs provided or discovered with parameters." -ForegroundColor Red
    return
}

Write-Host "[+] Collected $($rawUrls.Count) raw URLs. Normalizing & filtering for query parameters..." -ForegroundColor Green

# 1. Parameter Normalization (uro & qsreplace equivalent)
$paramMap = @{} # Key: base_path + param_names -> Value: Uri
$filteredUrls = [System.Collections.Generic.List[string]]::new()

foreach ($raw in $rawUrls) {
    try {
        $uri = [System.Uri]$raw
        if (-not $uri.Query -or $uri.Query.Length -le 1) { continue }

        # Filter out static extensions
        $ext = [System.IO.Path]::GetExtension($uri.AbsolutePath).ToLower()
        if ($ext -in @('.png','.jpg','.jpeg','.gif','.css','.woff','.woff2','.ttf','.svg','.ico','.pdf')) { continue }

        # Parse query params
        $queryParams = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
        if ($queryParams.Count -eq 0) { continue }

        $paramKeys = ($queryParams.AllKeys | Sort-Object) -join "&"
        $normKey = "$($uri.Host)$($uri.AbsolutePath)?$paramKeys"

        if (-not $paramMap.ContainsKey($normKey)) {
            $paramMap[$normKey] = $uri
            $filteredUrls.Add($uri.AbsoluteUri)
        }
    } catch {}
}

Write-Host "[+] Found $($filteredUrls.Count) unique parameterized endpoints." -ForegroundColor Green
if ($filteredUrls.Count -eq 0) {
    Write-Host "[-] No endpoints with query parameters found." -ForegroundColor Yellow
    return
}

# 2. Canary Seeding & Reflection Probing
$canary = "${CanaryPrefix}73<\"'>``"
$probeResults = [System.Collections.Generic.List[PSCustomObject]]::new()

Write-Host "[*] Probing for reflections using canary: $canary" -ForegroundColor Cyan

$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.ServerCertificateCustomValidationCallback = { $true }
$httpClient = [System.Net.Http.HttpClient]::new($handler)
$httpClient.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
$httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36")

$counter = 0
$total = $filteredUrls.Count

foreach ($origUrl in $filteredUrls) {
    $counter++
    try {
        $uri = [System.Uri]$origUrl
        $queryDict = [System.Web.HttpUtility]::ParseQueryString($uri.Query)

        # Test each parameter individually
        foreach ($key in $queryDict.AllKeys) {
            if ([string]::IsNullOrWhiteSpace($key)) { continue }

            $testDict = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
            $testDict[$key] = $canary

            $builder = [System.UriBuilder]$uri
            $builder.Query = $testDict.ToString()
            $testUrl = $builder.Uri.AbsoluteUri

            Write-Host -NoNewline "`r[*] [$counter/$total] Testing parameter: $key on $($uri.Host)..."

            $response = $httpClient.GetAsync($testUrl).GetAwaiter().GetResult()
            if ($response.IsSuccessStatusCode -or [int]$response.StatusCode -lt 500) {
                $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

                if ($body -and $body.Contains($CanaryPrefix)) {
                    # Check reflection context
                    $unfilteredChars = @()
                    foreach ($c in @('<', '>', '"', "'", '`')) {
                        if ($body.Contains("${CanaryPrefix}73") -and $body -match [regex]::Escape("${CanaryPrefix}73") + "[^`"'>]*" + [regex]::Escape("$c")) {
                            $unfilteredChars += $c
                        }
                    }

                    # Determine Context
                    $context = "BODY_TEXT"
                    if ($body -match "<script[^>]*>[^<]*" + [regex]::Escape($CanaryPrefix)) {
                        $context = "INLINE_SCRIPT"
                    } elseif ($body -match "<[^>]*=[`"'][^`"']*" + [regex]::Escape($CanaryPrefix)) {
                        $context = "HTML_ATTRIBUTE"
                    } elseif ($body -match "<!--[^>]*" + [regex]::Escape($CanaryPrefix)) {
                        $context = "HTML_COMMENT"
                    }

                    Write-Host "`n[!] REFLECTION CONFIRMED!" -ForegroundColor Yellow
                    Write-Host "    URL:     $testUrl" -ForegroundColor Cyan
                    Write-Host "    Param:   $key" -ForegroundColor Magenta
                    Write-Host "    Context: $context" -ForegroundColor Green
                    Write-Host "    Unescaped Chars: $($unfilteredChars -join ' ')" -ForegroundColor Red

                    $probeResults.Add([PSCustomObject]@{
                        Param = $key
                        Url = $testUrl
                        OriginalUrl = $origUrl
                        Context = $context
                        UnfilteredChars = $unfilteredChars
                        StatusCode = [int]$response.StatusCode
                    })
                }
            }
        }
    } catch {}
}

$httpClient.Dispose()
$handler.Dispose()

Write-Host "`n`n[+] Finished scanning. Reflected parameters found: $($probeResults.Count)" -ForegroundColor Green

if ($probeResults.Count -gt 0) {
    $outDir = [System.IO.Path]::GetDirectoryName($OutputFile)
    if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $probeResults | ConvertTo-Json -Depth 4 | Set-Content -Path $OutputFile -Encoding UTF8
    Write-Host "[+] Results saved to: $OutputFile" -ForegroundColor Green
}
