<#
.SYNOPSIS
    Automated GraphQL Endpoint Discovery and Security Auditor.
.DESCRIPTION
    Scans a target host for common GraphQL paths, probes Introspection query status,
    tests array-based query batching, and detects field-suggestion information leaks.
.EXAMPLE
    pwsh scripts/audit_graphql_endpoints.ps1 -TargetHost "https://target.com"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetHost,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "recon_output",

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSec = 8
)

$ErrorActionPreference = "Continue"

$TargetHost = $TargetHost.TrimEnd("/")
Write-Host "`n[+] ==========================================" -ForegroundColor Cyan
Write-Host "[+] GraphQL Security Prober & Endpoint Auditor" -ForegroundColor Cyan
Write-Host "[+] Target Host: $TargetHost" -ForegroundColor White
Write-Host "[+] ==========================================`n" -ForegroundColor Cyan

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$reportFile = Join-Path $OutputDir "graphql_audit_report.jsonl"

$commonPaths = @(
    "/graphql",
    "/api/graphql",
    "/v1/graphql",
    "/v2/graphql",
    "/gql",
    "/query",
    "/api/query",
    "/graphql/console",
    "/api/v1/graphql"
)

$headers = @{
    "Content-Type" = "application/json"
    "User-Agent"   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugBountyResearch/1.0"
}

$foundEndpoints = @()

foreach ($path in $commonPaths) {
    $fullUrl = "$TargetHost$path"
    Write-Host "[*] Testing: $fullUrl" -NoNewline

    $testBody = '{"query": "{ __typename }"}'
    try {
        $resp = Invoke-RestMethod -Uri $fullUrl -Method Post -Body $testBody -Headers $headers -TimeoutSec $TimeoutSec -ErrorAction Stop
        
        $isGraphQL = $false
        if ($resp -and ($resp.data -or $resp.errors)) {
            $isGraphQL = $true
        }

        if ($isGraphQL) {
            Write-Host " [DETECTED GRAPHQL]" -ForegroundColor Green
            $foundEndpoints += $fullUrl

            # --- Test 1: Introspection Query ---
            Write-Host "    -> Testing Introspection... " -NoNewline
            $introBody = '{"query": "{ __schema { types { name } } }"}'
            try {
                $introResp = Invoke-RestMethod -Uri $fullUrl -Method Post -Body $introBody -Headers $headers -TimeoutSec $TimeoutSec -ErrorAction Stop
                if ($introResp.data -and $introResp.data.__schema) {
                    $typeCount = $introResp.data.__schema.types.Count
                    Write-Host "[VULNERABLE: Introspection Enabled ($typeCount types)]" -ForegroundColor Red
                    $introStatus = "ENABLED"
                } else {
                    Write-Host "[Disabled/Blocked]" -ForegroundColor DarkGray
                    $introStatus = "DISABLED"
                }
            } catch {
                Write-Host "[Disabled/Error]" -ForegroundColor DarkGray
                $introStatus = "DISABLED"
            }

            # --- Test 2: Array-Based Query Batching ---
            Write-Host "    -> Testing Query Batching... " -NoNewline
            $batchBody = '[{"query": "{ __typename }"}, {"query": "{ __typename }"}]'
            try {
                $batchResp = Invoke-RestMethod -Uri $fullUrl -Method Post -Body $batchBody -Headers $headers -TimeoutSec $TimeoutSec -ErrorAction Stop
                if ($batchResp -is [System.Array] -and $batchResp.Count -eq 2) {
                    Write-Host "[VULNERABLE: Batching Enabled (Rate-limit bypass potential)]" -ForegroundColor Yellow
                    $batchStatus = "ENABLED"
                } else {
                    Write-Host "[Disabled]" -ForegroundColor DarkGray
                    $batchStatus = "DISABLED"
                }
            } catch {
                Write-Host "[Disabled/Blocked]" -ForegroundColor DarkGray
                $batchStatus = "DISABLED"
            }

            # --- Test 3: Field Suggestions Leak ---
            Write-Host "    -> Testing Field Suggestions... " -NoNewline
            $fuzzBody = '{"query": "{ nonExistentFieldXYZ }"}'
            try {
                $fuzzResp = Invoke-RestMethod -Uri $fullUrl -Method Post -Body $fuzzBody -Headers $headers -TimeoutSec $TimeoutSec -ErrorAction Stop
                $rawErrors = $fuzzResp.errors | ConvertTo-Json -Compress
                if ($rawErrors -like "*Did you mean*") {
                    Write-Host "[LEAK: Suggestions Enabled]" -ForegroundColor Yellow
                    $suggestionStatus = "ENABLED"
                } else {
                    Write-Host "[Safe]" -ForegroundColor DarkGray
                    $suggestionStatus = "SAFE"
                }
            } catch {
                Write-Host "[Safe/Error]" -ForegroundColor DarkGray
                $suggestionStatus = "SAFE"
            }

            # Save finding
            $auditResult = [PSCustomObject]@{
                Endpoint         = $fullUrl
                Introspection    = $introStatus
                Batching         = $batchStatus
                FieldSuggestions = $suggestionStatus
                Timestamp        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $auditResult | ConvertTo-Json -Compress | Out-File -Append -Encoding utf8 $reportFile
        } else {
            Write-Host " [Not GraphQL]" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host " [Unreachable/Closed]" -ForegroundColor DarkGray
    }
}

Write-Host "`n[+] GraphQL Audit Completed!" -ForegroundColor Green
Write-Host "[+] Total Detected GraphQL Endpoints: $($foundEndpoints.Count)" -ForegroundColor $(if ($foundEndpoints.Count -gt 0) { "Green" } else { "DarkGray" })
if ($foundEndpoints.Count -gt 0) {
    Write-Host "[!] Detailed audit results stored in: $reportFile" -ForegroundColor Yellow
}
