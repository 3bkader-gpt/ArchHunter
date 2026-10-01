param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TargetName,

    [Parameter(Mandatory=$false)]
    [string]$TargetDomain = "",

    [Parameter(Mandatory=$false)]
    [string]$Platform = "HackerOne",

    [Parameter(Mandatory=$false)]
    [string]$BaseDir = "Z:\bug_bounty",

    [Parameter(Mandatory=$false)]
    [string]$TemplateDir = "Z:\bug_bounty\ArchHunter"
)

$ErrorActionPreference = "Stop"

# 1. Clean Target Name & Domain
$TargetName = $TargetName.Trim().TrimEnd('/').TrimEnd('\')
if ([string]::IsNullOrWhiteSpace($TargetDomain)) {
    if ($TargetName -match "\.") {
        $TargetDomain = $TargetName
    } else {
        $TargetDomain = "$TargetName.com"
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " 🏛️ ArchHunter Target Initialization Engine" -ForegroundColor Yellow
Write-Host " [*] Target Name   : $TargetName" -ForegroundColor White
Write-Host " [*] Target Domain : $TargetDomain" -ForegroundColor White
Write-Host " [*] Platform      : $Platform" -ForegroundColor White
Write-Host " [*] Base Directory: $BaseDir" -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Cyan

# 2. Check Base Directory
if (-not (Test-Path $BaseDir)) {
    Write-Error "Base directory '$BaseDir' does not exist! Please verify that Drive Z is connected and mapped."
    exit 1
}

# 3. Check Template Directory (fallback to Desktop if needed)
if (-not (Test-Path $TemplateDir)) {
    $fallbackTemplate = "c:\Users\medoo\Desktop\ArchHunter"
    if (Test-Path $fallbackTemplate) {
        Write-Host "[!] Template '$TemplateDir' not found, falling back to '$fallbackTemplate'" -ForegroundColor Yellow
        $TemplateDir = $fallbackTemplate
    } else {
        Write-Error "Template ArchHunter directory not found at '$TemplateDir' or '$fallbackTemplate'!"
        exit 1
    }
}

# 4. Create Target Program Directory
$targetProgramDir = Join-Path $BaseDir $TargetName
if (-not (Test-Path $targetProgramDir)) {
    New-Item -ItemType Directory -Path $targetProgramDir -Force | Out-Null
    Write-Host "[+] Created target program directory: $targetProgramDir" -ForegroundColor Green
} else {
    Write-Host "[*] Target program directory already exists: $targetProgramDir" -ForegroundColor Yellow
}

# 5. Copy ArchHunter into Target Program Directory
$targetArchHunter = Join-Path $targetProgramDir "ArchHunter"
if (-not (Test-Path $targetArchHunter)) {
    Write-Host "[*] Copying ArchHunter template to '$targetArchHunter'..." -ForegroundColor Cyan
    
    # Use robocopy for high-speed transfer, excluding .git to keep it clean and fast
    $robocopyArgs = @(
        "`"$TemplateDir`"",
        "`"$targetArchHunter`"",
        "/E",
        "/XD", ".git", "_archive",
        "/NFL", "/NDL", "/NJH", "/NJS", "/nc", "/ns", "/np"
    )
    $cmd = "robocopy $robocopyArgs"
    Invoke-Expression $cmd | Out-Null
    
    if ($LASTEXITCODE -ge 8) {
        Write-Error "Robocopy encountered an error copying ArchHunter (Exit code: $LASTEXITCODE)."
        exit 1
    }
    Write-Host "[+] ArchHunter framework successfully copied!" -ForegroundColor Green
} else {
    Write-Host "[!] ArchHunter already exists in '$targetArchHunter', preserving existing files." -ForegroundColor Yellow
}

# 6. Customize TARGET_SESSION.md
$sessionPath = Join-Path $targetArchHunter "TARGET_SESSION.md"
$sessionTemplatePath = Join-Path $targetArchHunter "templates\TARGET_SESSION_TEMPLATE.md"

if (Test-Path $sessionTemplatePath) {
    $todayDate = (Get-Date).ToString("yyyy-MM-dd")
    $content = Get-Content $sessionTemplatePath -Raw -Encoding UTF8
    
    $content = $content.Replace("[TARGET_NAME]", $TargetName)
    $content = $content.Replace("example.com", $TargetDomain)
    $content = $content.Replace("YYYY-MM-DD", $todayDate)
    $content = $content.Replace("HackerOne / Intigriti / Bugcrowd", $Platform)
    
    Set-Content -Path $sessionPath -Value $content -Encoding UTF8
    Write-Host "[+] Initialized and customized: $sessionPath" -ForegroundColor Green
} else {
    Write-Host "[!] Template '$sessionTemplatePath' not found to create TARGET_SESSION.md" -ForegroundColor Yellow
}

# 7. Create Standard Recon & Engagement Directories
$dirsToCreate = @(
    (Join-Path $targetArchHunter "recon"),
    (Join-Path $targetArchHunter "recon\subs"),
    (Join-Path $targetArchHunter "recon\urls"),
    (Join-Path $targetArchHunter "recon\params"),
    (Join-Path $targetArchHunter "recon\fuzz"),
    (Join-Path $targetArchHunter "recon\results"),
    (Join-Path $targetArchHunter "notes"),
    (Join-Path $targetArchHunter "pocs")
)

foreach ($d in $dirsToCreate) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}
Write-Host "[+] Recon hierarchy created (subs, urls, params, fuzz, results, notes, pocs)" -ForegroundColor Green

# 8. Create Scope Definition Files
$scopeInPath = Join-Path $targetArchHunter "recon\scope_in.txt"
$scopeOutPath = Join-Path $targetArchHunter "recon\scope_out.txt"

if (-not (Test-Path $scopeInPath)) {
    $scopeInContent = @"
$TargetDomain
*.$TargetDomain
"@
    Set-Content -Path $scopeInPath -Value $scopeInContent -Encoding UTF8
    Write-Host "[+] Created: $scopeInPath" -ForegroundColor Green
}

if (-not (Test-Path $scopeOutPath)) {
    $scopeOutContent = @"
# Add out-of-scope assets here (e.g. blog.$TargetDomain, third-party services)
"@
    Set-Content -Path $scopeOutPath -Value $scopeOutContent -Encoding UTF8
    Write-Host "[+] Created: $scopeOutPath" -ForegroundColor Green
}

# 9. Update Runtime Config Session ID
$runtimeConfig = Join-Path $targetArchHunter "Runtime\configs\mvp_config.json"
if (Test-Path $runtimeConfig) {
    try {
        $json = Get-Content $runtimeConfig -Raw | ConvertFrom-Json
        $json.session_id = "session_" + ($TargetName -replace '[^a-zA-Z0-9_]', '_') + "_" + (Get-Date).ToString("yyyyMMdd")
        $json | ConvertTo-Json -Depth 5 | Set-Content $runtimeConfig -Encoding UTF8
        Write-Host "[+] Updated Runtime session_id: $($json.session_id)" -ForegroundColor Green
    } catch {
        Write-Host "[!] Could not update Runtime config JSON: $_" -ForegroundColor DarkGray
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " 🎯 TARGET READY FOR HUNTING!" -ForegroundColor Green
Write-Host " Target Path       : $targetArchHunter" -ForegroundColor White
Write-Host " Active Session    : $sessionPath" -ForegroundColor White
Write-Host " In-Scope Domains  : $scopeInPath" -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Cyan
