param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDomain,

    [Parameter(Mandatory=$false)]
    [string]$AliveHostsFile = ""
)

Write-Host "[+] Initializing Backup Fuzzing for: $TargetDomain" -ForegroundColor Green

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "[*] Delegating execution to WSL fuzz_sensitive_backups.sh..." -ForegroundColor Cyan
    $wslCmd = "bash scripts/fuzz_sensitive_backups.sh $TargetDomain"
    if ($AliveHostsFile) { $wslCmd += " '$AliveHostsFile'" }
    wsl bash -c $wslCmd
    exit $LASTEXITCODE
}

Write-Host "[!] WSL is recommended for high-speed fuzzing." -ForegroundColor Yellow
