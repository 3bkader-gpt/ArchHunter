param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDomain,

    [Parameter(Mandatory=$false)]
    [string]$ProgramName = "HackerOne"
)

Write-Host "[+] Initializing Bug Bounty Target: $TargetDomain ($ProgramName)" -ForegroundColor Green

# 1. Create target recon directories
$dirs = @(
    "recon/$TargetDomain/subs",
    "recon/$TargetDomain/urls",
    "recon/$TargetDomain/fuzz",
    "recon/$TargetDomain/results"
)

foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# 2. Copy and customize TARGET_SESSION.md
if (-not (Test-Path "TARGET_SESSION.md")) {
    $template = Get-Content "templates/TARGET_SESSION_TEMPLATE.md" -Raw
    $customized = $template.Replace("example.com", $TargetDomain).Replace("[TARGET_NAME]", $TargetDomain)
    Set-Content -Path "TARGET_SESSION.md" -Value $customized
    Write-Host "[+] Created TARGET_SESSION.md customized for $TargetDomain" -ForegroundColor Cyan
} else {
    Write-Host "[!] TARGET_SESSION.md already exists, skipping overwrite." -ForegroundColor Yellow
}

Write-Host "`n[+] Setup Complete!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. Fill in account credentials in TARGET_SESSION.md"
Write-Host "2. Run passive & active recon:"
Write-Host "   subfinder -d $TargetDomain -silent | dnsx -silent | httpx -sc -title -tech-detect -json -o recon/$TargetDomain/signals.jsonl"
Write-Host "3. Run Reasoning Engine:"
Write-Host "   cd Runtime; go run cmd/runtime/main.go -input ../recon/$TargetDomain/signals.jsonl -output ../recon/$TargetDomain/results/"
