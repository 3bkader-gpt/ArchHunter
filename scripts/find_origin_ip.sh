#!/bin/bash
# ==============================================================================
# 🎯 Origin IP & WAF/CDN Bypass Hunter
# Automates: Favicon MurmurHash3 + Direct Host Header Verification
# ==============================================================================

set -e

TARGET_DOMAIN=$1
IP_CANDIDATES_FILE=$2

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/find_origin_ip.sh <target_domain> [candidate_ips_file]"
    echo "Example: ./scripts/find_origin_ip.sh target.com recon/target.com/ips/asn_cidrs.txt"
    exit 1
fi

echo -e "\e[1;32m[+] Searching Origin IP for: $TARGET_DOMAIN\e[0m"

# 1. Fetch Favicon and Compute MurmurHash3
FAVICON_URL="https://${TARGET_DOMAIN}/favicon.ico"
echo -e "\e[1;34m[*] Step 1: Checking Favicon hash at $FAVICON_URL...\e[0m"

python3 - <<EOF
import requests, mmh3, codecs, sys
try:
    r = requests.get("$FAVICON_URL", timeout=10, verify=False)
    if r.status_code == 200 and len(r.content) > 0:
        b64 = codecs.encode(r.content, "base64")
        h = mmh3.hash(b64)
        print(f"\e[1;32m[+] Favicon MurmurHash3: {h}\e[0m")
        print(f"    -> Shodan Dork: https://www.shodan.io/search?query=http.favicon.hash:{h}")
        print(f"    -> Censys Dork: https://search.censys.io/search?q=services.http.response.favicons.md5_hash%3A{h}")
    else:
        print("[-] Favicon not reachable or empty.")
except Exception as e:
    print(f"[-] Could not fetch favicon: {e}")
EOF

# 2. Get baseline response from live CDN
echo -e "\e[1;34m[*] Step 2: Baselining live CDN response...\e[0m"
LIVE_TITLE=$(curl -s -k "https://${TARGET_DOMAIN}" -L | grep -iPo '(?<=<title>)(.*?)(?=</title>)' || echo "N/A")
echo "    -> Live CDN Page Title: '$LIVE_TITLE'"

# 3. If Candidate IPs supplied, verify them
if [ -n "$IP_CANDIDATES_FILE" ] && [ -f "$IP_CANDIDATES_FILE" ]; then
    echo -e "\e[1;34m[*] Step 3: Verifying candidate IPs against target Host header...\e[0m"
    while read -r ip; do
        # Skip empty lines or CIDR notation for direct curl
        if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            RESP=$(curl -s -k --max-time 5 -H "Host: ${TARGET_DOMAIN}" "https://${ip}/" 2>/dev/null || true)
            if [ -n "$RESP" ]; then
                CANDIDATE_TITLE=$(echo "$RESP" | grep -iPo '(?<=<title>)(.*?)(?=</title>)' || echo "")
                if [ -n "$CANDIDATE_TITLE" ] && [[ "$CANDIDATE_TITLE" == *"$LIVE_TITLE"* || "$RESP" == *"$TARGET_DOMAIN"* ]]; then
                    echo -e "\e[1;32m[🎯 ORIGIN HIT!] IP: $ip matches domain '$TARGET_DOMAIN' (Title: '$CANDIDATE_TITLE')\e[0m"
                fi
            fi
        fi
    done < "$IP_CANDIDATES_FILE"
fi

echo -e "\e[1;33m[!] Search complete. Validate any hits by navigating directly to https://<IP> with Host: $TARGET_DOMAIN\e[0m"
