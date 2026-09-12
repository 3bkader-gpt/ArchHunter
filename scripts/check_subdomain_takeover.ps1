param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDomain,

    [Parameter(Mandatory=$false)]
    [string]$ResolvedSubsFile = ""
)

Write-Host "[+] Initializing Subdomain Takeover Check for: $TargetDomain" -ForegroundColor Green

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "[*] Delegating execution to WSL check_subdomain_takeover.sh..." -ForegroundColor Cyan
    $wslCmd = "bash scripts/check_subdomain_takeover.sh $TargetDomain"
    if ($ResolvedSubsFile) { $wslCmd += " '$ResolvedSubsFile'" }
    wsl bash -c $wslCmd
    exit $LASTEXITCODE
}

Write-Host "[!] WSL is recommended for DNS and takeover auditing." -ForegroundColor Yellow
