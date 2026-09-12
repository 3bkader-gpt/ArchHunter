param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDomain,

    [Parameter(Mandatory=$false)]
    [string]$CandidateIpsFile = ""
)

Write-Host "[+] Searching Origin IP for: $TargetDomain" -ForegroundColor Green

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "[*] Delegating execution to WSL find_origin_ip.sh..." -ForegroundColor Cyan
    $wslCmd = "bash scripts/find_origin_ip.sh $TargetDomain"
    if ($CandidateIpsFile) { $wslCmd += " '$CandidateIpsFile'" }
    wsl bash -c $wslCmd
    exit $LASTEXITCODE
}

Write-Host "[!] Please install WSL or Python mmh3 to run native hash calculations." -ForegroundColor Yellow
