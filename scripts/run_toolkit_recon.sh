#!/usr/bin/env bash
# ==============================================================================
# Bug Bounty Toolkit: Master Unified Recon & Parameter Pipeline
# Chains: subfinder -> tlsx -> dnsx -> httpx -> gau/katana -> uro -> gf -> qsreplace -> kxss/dalfox
# ==============================================================================

set -e

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
    echo "Usage: ./scripts/run_toolkit_recon.sh <target.com>"
    exit 1
fi

RECON_DIR="recon/${DOMAIN}"
mkdir -p "${RECON_DIR}/subs" "${RECON_DIR}/urls" "${RECON_DIR}/params" "${RECON_DIR}/reflections" "${RECON_DIR}/loot"

echo "================================================================="
echo "[*] Launching Master Toolkit Recon Pipeline for: ${DOMAIN}"
echo "[*] Output Directory: ${RECON_DIR}"
echo "================================================================="

# --- Phase 1: Subdomain Discovery & TLS SAN Harvesting ---
echo "[+] [1/5] Running Subdomain Discovery (subfinder + tlsx + dnsx)..."
subfinder -d "${DOMAIN}" -all -silent | anew "${RECON_DIR}/subs/raw_subs.txt"

# Extract TLS SANs from discovered subdomains
if command -v tlsx &> /dev/null; then
    cat "${RECON_DIR}/subs/raw_subs.txt" | tlsx -san -cn -resp-only -silent | anew "${RECON_DIR}/subs/raw_subs.txt"
fi

# Resolve subdomains
if command -v dnsx &> /dev/null; then
    cat "${RECON_DIR}/subs/raw_subs.txt" | dnsx -silent -o "${RECON_DIR}/subs/resolved_subs.txt"
else
    cat "${RECON_DIR}/subs/raw_subs.txt" | sort -u > "${RECON_DIR}/subs/resolved_subs.txt"
fi

echo "[+] Discovered $(wc -l < "${RECON_DIR}/subs/resolved_subs.txt") resolved subdomains."

# --- Phase 2: HTTP Probing & Fingerprinting ---
echo "[+] [2/5] Probing Live HTTP Services (httpx)..."
if command -v httpx &> /dev/null; then
    cat "${RECON_DIR}/subs/resolved_subs.txt" | httpx \
        -ports 80,443,8080,8443,3000 \
        -sc -title -tech-detect -follow-redirects -silent \
        -json -o "${RECON_DIR}/subs/signals.jsonl"
    
    cat "${RECON_DIR}/subs/signals.jsonl" | jq -r '.url' | sort -u > "${RECON_DIR}/subs/alive_web.txt"
else
    cat "${RECON_DIR}/subs/resolved_subs.txt" | sed 's|^|https://|' > "${RECON_DIR}/subs/alive_web.txt"
fi

echo "[+] Found $(wc -l < "${RECON_DIR}/subs/alive_web.txt") live web applications."

# --- Phase 3: Crawling & Historical URL Archaeology ---
echo "[+] [3/5] Extracting Historical URLs & Crawling (gau + waybackurls + katana)..."
if command -v gau &> /dev/null; then
    cat "${RECON_DIR}/subs/alive_web.txt" | gau --threads 10 --subs | anew "${RECON_DIR}/urls/raw_urls.txt"
fi
if command -v waybackurls &> /dev/null; then
    cat "${RECON_DIR}/subs/alive_web.txt" | waybackurls | anew "${RECON_DIR}/urls/raw_urls.txt"
fi
if command -v katana &> /dev/null; then
    katana -list "${RECON_DIR}/subs/alive_web.txt" -headless -depth 2 -jc -silent | anew "${RECON_DIR}/urls/raw_urls.txt"
fi

# --- Phase 4: URL Normalization & Pattern Slicing ---
echo "[+] [4/5] Normalizing URLs & Slicing Patterns (uro + gf)..."
if command -v uro &> /dev/null; then
    cat "${RECON_DIR}/urls/raw_urls.txt" | uro | anew "${RECON_DIR}/urls/clean_urls.txt"
else
    cat "${RECON_DIR}/urls/raw_urls.txt" | grep '=' | sort -u > "${RECON_DIR}/urls/clean_urls.txt"
fi

# Apply GF Patterns
if command -v gf &> /dev/null; then
    cat "${RECON_DIR}/urls/clean_urls.txt" | gf xss   | anew "${RECON_DIR}/params/xss.txt"
    cat "${RECON_DIR}/urls/clean_urls.txt" | gf ssrf  | anew "${RECON_DIR}/params/ssrf.txt"
    cat "${RECON_DIR}/urls/clean_urls.txt" | gf idor  | anew "${RECON_DIR}/params/idor.txt"
    cat "${RECON_DIR}/urls/clean_urls.txt" | gf sqli  | anew "${RECON_DIR}/params/sqli.txt"
    cat "${RECON_DIR}/urls/clean_urls.txt" | gf lfi   | anew "${RECON_DIR}/params/lfi.txt"
else
    grep -iE '(search|query|q|lang|url|redirect|id)=' "${RECON_DIR}/urls/clean_urls.txt" > "${RECON_DIR}/params/xss.txt" || true
fi

# --- Phase 5: Reflection Analysis & Vulnerability Probing ---
echo "[+] [5/5] Checking Parameter Reflections (qsreplace + kxss)..."
if [ -s "${RECON_DIR}/params/xss.txt" ]; then
    if command -v qsreplace &> /dev/null && command -v kxss &> /dev/null; then
        cat "${RECON_DIR}/params/xss.txt" | qsreplace 'kXss73<"'\`>' | kxss | anew "${RECON_DIR}/reflections/kxss_findings.txt"
    else
        echo "[!] Running PowerShell fallback reflection pipeline..."
        pwsh ./scripts/param_reflection_pipeline.ps1 -UrlFile "${RECON_DIR}/params/xss.txt" -OutputFile "${RECON_DIR}/reflections/reflected_params.json"
    fi
fi

echo "================================================================="
echo "[+] Toolkit Recon Pipeline Complete for: ${DOMAIN}"
echo "    • Alive Hosts:      ${RECON_DIR}/subs/alive_web.txt"
echo "    • Normalized URLs:  ${RECON_DIR}/urls/clean_urls.txt"
echo "    • Sliced Targets:   ${RECON_DIR}/params/"
echo "    • Reflected Params: ${RECON_DIR}/reflections/"
echo "================================================================="
