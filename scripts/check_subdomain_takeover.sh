#!/bin/bash
# ==============================================================================
# 🎯 Subdomain Takeover & Dangling DNS Auditor
# Checks CNAME chains against 15+ cloud provider takeover fingerprints
# ==============================================================================

set -e

TARGET_DOMAIN=$1
RESOLVED_SUBS_FILE=${2:-"recon/$TARGET_DOMAIN/subs/resolved_subs.txt"}

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/check_subdomain_takeover.sh <target_domain> [resolved_subs_file]"
    echo "Example: ./scripts/check_subdomain_takeover.sh target.com"
    exit 1
fi

RECON_DIR="recon/$TARGET_DOMAIN"
SUBS_DIR="$RECON_DIR/subs"
TAKEOVER_REPORT="$SUBS_DIR/subdomain_takeovers.txt"
CNAMES_FILE="$SUBS_DIR/cname_records.txt"

mkdir -p "$SUBS_DIR"

if [ ! -f "$RESOLVED_SUBS_FILE" ]; then
    echo "[-] Resolved subdomains file not found at: $RESOLVED_SUBS_FILE"
    echo "    Falling back to querying single domain: $TARGET_DOMAIN"
    echo "$TARGET_DOMAIN" > "$SUBS_DIR/single_target.txt"
    RESOLVED_SUBS_FILE="$SUBS_DIR/single_target.txt"
fi

echo -e "\e[1;32m[+] Starting Subdomain Takeover Audit for: $TARGET_DOMAIN\e[0m"

# Step 1: Extract CNAME records
echo -e "\e[1;34m[*] Step 1: Extracting DNS CNAME chains using dnsx...\e[0m"
cat "$RESOLVED_SUBS_FILE" | dnsx -cname -resp -silent -o "$CNAMES_FILE" || true

# Step 2: Use subzy if installed, or fallback to fingerprint matcher
echo -e "\e[1;34m[*] Step 2: Checking dangling CNAME fingerprints...\e[0m"

if command -v subzy &> /dev/null; then
    echo "[*] Running subzy engine..."
    subzy run --targets "$RESOLVED_SUBS_FILE" --hide_fails --verify_ssl | tee "$TAKEOVER_REPORT"
else
    echo "[*] Subzy not found. Running built-in fingerprint regex probe via httpx..."
    cat "$RESOLVED_SUBS_FILE" | httpx -silent -title -status-code -body -match-regex "(There isn't a GitHub Pages site here|The specified bucket does not exist|NoSuchBucket|No such app|herokucdn.com/error-pages/no-such-app.html|404 Web Site not found|Sorry, this shop is currently unavailable|Fastly error: unknown domain|The thing you were looking for is no longer here|Help Center Closed|project not found|Repository not found)" -o "$TAKEOVER_REPORT" || true
fi

COUNT=$(wc -l < "$TAKEOVER_REPORT" 2>/dev/null || echo 0)
if [ "$COUNT" -gt 0 ]; then
    echo -e "\e[1;31m[🚨 POTENTIAL SUBDOMAIN TAKEOVERS FOUND! ($COUNT hits)]\e[0m"
    cat "$TAKEOVER_REPORT"
else
    echo -e "\e[1;32m[+] No dangling CNAMEs or takeover fingerprints detected.\e[0m"
fi

echo -e "\e[1;33m[!] Report saved at: $TAKEOVER_REPORT\e[0m"
