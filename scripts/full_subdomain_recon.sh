#!/bin/bash
# ==============================================================================
# 🎯 Elite Subdomain Reconnaissance & Surface Expansion Pipeline
# Integrates: Passive Multi-Source -> ASN PTR -> PureDNS Brute -> Permutations -> VHost Fuzz -> HTTPx Signals
# ==============================================================================

set -e

TARGET_DOMAIN=$1
WORDLIST_PATH=${2:-"/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt"}

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/full_subdomain_recon.sh <target_domain> [wordlist_path]"
    echo "Example: ./scripts/full_subdomain_recon.sh target.com"
    exit 1
fi

RECON_DIR="recon/$TARGET_DOMAIN"
SUBS_DIR="$RECON_DIR/subs"
IPS_DIR="$RECON_DIR/ips"
URLS_DIR="$RECON_DIR/urls"
RESULTS_DIR="$RECON_DIR/results"

mkdir -p "$SUBS_DIR" "$IPS_DIR" "$URLS_DIR" "$RESULTS_DIR"

echo -e "\e[1;32m[+] Starting Full Subdomain Recon for: $TARGET_DOMAIN\e[0m"

# ------------------------------------------------------------------------------
# 1. Update Trusted DNS Resolvers
# ------------------------------------------------------------------------------
RESOLVERS_FILE="$RECON_DIR/resolvers.txt"
if [ ! -f "$RESOLVERS_FILE" ] || [ $(find "$RESOLVERS_FILE" -mtime +1 2>/dev/null) ]; then
    echo -e "\e[1;34m[*] Updating trusted public DNS resolvers...\e[0m"
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -o "$RESOLVERS_FILE"
fi

# ------------------------------------------------------------------------------
# 2. Passive Subdomain Aggregation
# ------------------------------------------------------------------------------
echo -e "\e[1;34m[*] Phase 1: Multi-Engine Passive Aggregation...\e[0m"
RAW_PASSIVE="$SUBS_DIR/raw_passive.txt"
touch "$RAW_PASSIVE"

# Subfinder
if command -v subfinder &>/dev/null; then
    echo "  -> Running subfinder..."
    subfinder -d "$TARGET_DOMAIN" -all -silent | anew "$RAW_PASSIVE" >/dev/null
fi

# Assetfinder
if command -v assetfinder &>/dev/null; then
    echo "  -> Running assetfinder..."
    assetfinder --subs-only "$TARGET_DOMAIN" | anew "$RAW_PASSIVE" >/dev/null
fi

# Findomain
if command -v findomain &>/dev/null; then
    echo "  -> Running findomain..."
    findomain -t "$TARGET_DOMAIN" -q | anew "$RAW_PASSIVE" >/dev/null
fi

# Chaos (ProjectDiscovery)
if command -v chaos &>/dev/null; then
    echo "  -> Running chaos dataset query..."
    chaos -d "$TARGET_DOMAIN" -silent | anew "$RAW_PASSIVE" >/dev/null || true
fi

# Certificate Transparency Logs (crt.sh)
echo "  -> Querying crt.sh..."
curl -s "https://crt.sh/?q=%.${TARGET_DOMAIN}&output=json" 2>/dev/null \
    | jq -r '.[].name_value 2>/dev/null' 2>/dev/null \
    | sed 's/\*\.//g' | sort -u | anew "$RAW_PASSIVE" >/dev/null || true

# GitHub Subdomains (if GITHUB_TOKEN exists)
if [ -n "$GITHUB_TOKEN" ] && command -v github-subdomains &>/dev/null; then
    echo "  -> Running github-subdomains..."
    github-subdomains -d "$TARGET_DOMAIN" -t "$GITHUB_TOKEN" | anew "$RAW_PASSIVE" >/dev/null || true
fi

# ------------------------------------------------------------------------------
# 3. ASN Mapping & Reverse DNS (PTR)
# ------------------------------------------------------------------------------
echo -e "\e[1;34m[*] Phase 2: ASN Mapping & Reverse DNS Lookup...\e[0m"
if command -v asnmap &>/dev/null; then
    asnmap -d "$TARGET_DOMAIN" -silent > "$IPS_DIR/asn_cidrs.txt" 2>/dev/null || true
    if [ -s "$IPS_DIR/asn_cidrs.txt" ]; then
        if command -v hakrevdns &>/dev/null; then
            cat "$IPS_DIR/asn_cidrs.txt" | hakrevdns -d | grep -i "$TARGET_DOMAIN" | awk '{print $2}' | anew "$RAW_PASSIVE" >/dev/null || true
        elif command -v dnsx &>/dev/null; then
            dnsx -ptr -resp-only -l "$IPS_DIR/asn_cidrs.txt" -r "$RESOLVERS_FILE" | grep -i "$TARGET_DOMAIN" | anew "$RAW_PASSIVE" >/dev/null || true
        fi
    fi
fi

PASSIVE_COUNT=$(wc -l < "$RAW_PASSIVE" || echo 0)
echo -e "\e[1;32m[+] Aggregated $PASSIVE_COUNT unique passive subdomains\e[0m"

# ------------------------------------------------------------------------------
# 4. Active DNS Resolution & Wildcard Filtering
# ------------------------------------------------------------------------------
echo -e "\e[1;34m[*] Phase 3: Resolving Subdomains with dnsx...\e[0m"
RESOLVED_FILE="$SUBS_DIR/resolved_subs.txt"
if command -v dnsx &>/dev/null; then
    cat "$RAW_PASSIVE" | dnsx -r "$RESOLVERS_FILE" -silent -a -cname -resp -o "$SUBS_DIR/dnsx_resolved.txt" 2>/dev/null || true
    cat "$SUBS_DIR/dnsx_resolved.txt" | awk '{print $1}' | sort -u > "$RESOLVED_FILE"
else
    sort -u "$RAW_PASSIVE" > "$RESOLVED_FILE"
fi

# ------------------------------------------------------------------------------
# 5. Active DNS Brute-Forcing
# ------------------------------------------------------------------------------
if [ -f "$WORDLIST_PATH" ] && command -v puredns &>/dev/null; then
    echo -e "\e[1;34m[*] Phase 4: PureDNS Active Brute-forcing ($WORDLIST_PATH)...\e[0m"
    BRUTE_OUT="$SUBS_DIR/bruteforce_subs.txt"
    puredns bruteforce "$WORDLIST_PATH" "$TARGET_DOMAIN" -r "$RESOLVERS_FILE" --write "$BRUTE_OUT" -q || true
    if [ -f "$BRUTE_OUT" ]; then
        cat "$BRUTE_OUT" | anew "$RESOLVED_FILE" >/dev/null
    fi
elif [ -f "$WORDLIST_PATH" ] && command -v dnsx &>/dev/null; then
    echo -e "\e[1;34m[*] Phase 4: dnsx Wordlist Brute-forcing...\e[0m"
    dnsx -d "$TARGET_DOMAIN" -w "$WORDLIST_PATH" -r "$RESOLVERS_FILE" -silent | anew "$RESOLVED_FILE" >/dev/null || true
fi

FINAL_SUB_COUNT=$(wc -l < "$RESOLVED_FILE" || echo 0)
echo -e "\e[1;32m[+] Total Resolved Subdomains: $FINAL_SUB_COUNT\e[0m"

# ------------------------------------------------------------------------------
# 6. HTTP Probing, Tech Detection & Signal Emission (httpx)
# ------------------------------------------------------------------------------
echo -e "\e[1;34m[*] Phase 5: Live HTTP Probing and Signals Ingestion...\e[0m"
SIGNALS_FILE="$RECON_DIR/signals.jsonl"
ALIVE_HOSTS="$SUBS_DIR/alive_hosts.txt"

if command -v httpx &>/dev/null; then
    cat "$RESOLVED_FILE" | httpx \
        -ports 80,443,8080,8443,3000,8081,9000,5000,50051 \
        -sc -title -web-server -tech-detect -follow-redirects \
        -json -o "$SIGNALS_FILE" -silent

    # Generate categorized target lists by status code
    cat "$SIGNALS_FILE" | jq -r 'select(.status_code == 200) | .url' | sort -u > "$SUBS_DIR/alive_200.txt" || true
    cat "$SIGNALS_FILE" | jq -r 'select(.status_code == 401 or .status_code == 403) | "\(.status_code) \(.url)"' | sort -u > "$SUBS_DIR/auth_restricted_401_403.txt" || true
    cat "$SIGNALS_FILE" | jq -r 'select(.status_code == 404) | .url' | sort -u > "$SUBS_DIR/dead_404_archaeology.txt" || true
    cat "$SIGNALS_FILE" | jq -r '.url' | sort -u > "$ALIVE_HOSTS"
fi

ALIVE_COUNT=$(wc -l < "$ALIVE_HOSTS" 2>/dev/null || echo 0)
echo -e "\e[1;32m[+] Finished! Found $ALIVE_COUNT Live Web Endpoints.\e[0m"
echo -e "\e[1;33m[!] Signals stored at: $SIGNALS_FILE (Ready for Runtime Engine)\e[0m"
