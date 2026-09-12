param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDomain,

    [Parameter(Mandatory=$false)]
    [string]$AliveHostsFile = ""
)

Write-Host "[+] Initializing API Discovery for: $TargetDomain" -ForegroundColor Green

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "[*] Delegating execution to WSL discover_api_endpoints.sh..." -ForegroundColor Cyan
    $wslCmd = "bash scripts/discover_api_endpoints.sh $TargetDomain"
    if ($AliveHostsFile) { $wslCmd += " '$AliveHostsFile'" }
    wsl bash -c $wslCmd
    exit $LASTEXITCODE
}

Write-Host "[!] WSL is recommended for API probing." -ForegroundColor Yellow
