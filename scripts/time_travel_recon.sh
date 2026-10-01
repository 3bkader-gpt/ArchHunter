#!/bin/bash
# ==============================================================================
# ⏳ Time-Travel Recon — Historical DNS / CT / Wayback Diff (Bash port of
# Workflow/12 Phase 2). Finds forgotten infra: CT certs no longer resolving,
# old API versions from Wayback, and robots.txt drift. Passive only.
# ==============================================================================

TARGET_DOMAIN="${1:-}"
OUTPUT_DIR="${2:-recon/timetravel}"

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/time_travel_recon.sh <target_domain> [output_dir]"
    echo "Example: ./scripts/time_travel_recon.sh target.com"
    echo "Passive/semi-passive only — confirm scope first (Workflow/12 Rule 0)."
    exit 1
fi

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] Time-Travel Recon: $TARGET_DOMAIN${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"

# --- 1. Certificate Transparency history -> forgotten hosts ---
echo -e "${YELLOW}[*] Pulling Certificate Transparency history (crt.sh)...${NC}"
curl -sk --max-time 30 "https://crt.sh/?q=%25.${TARGET_DOMAIN}&output=json" \
    | jq -r '.[].name_value' 2>/dev/null | tr '\n' '\n' | sed 's/^\*\.//' | sort -u \
    > "$OUTPUT_DIR/ct_hosts.txt" || echo "" > "$OUTPUT_DIR/ct_hosts.txt"
CT_COUNT=$(wc -l < "$OUTPUT_DIR/ct_hosts.txt" | tr -d ' ')
echo -e "${GREEN}[+] $CT_COUNT unique hosts in CT history -> $OUTPUT_DIR/ct_hosts.txt${NC}"

echo -e "${YELLOW}[*] Diffing CT hosts against current DNS (forgotten = no resolution)...${NC}"
: > "$OUTPUT_DIR/forgotten_hosts.txt"
while IFS= read -r host; do
    [ -z "$host" ] && continue
    if ! dig +short "$host" A 2>/dev/null | grep -q . ; then
        echo "$host" >> "$OUTPUT_DIR/forgotten_hosts.txt"
    fi
done < "$OUTPUT_DIR/ct_hosts.txt"
FORGOTTEN=$(wc -l < "$OUTPUT_DIR/forgotten_hosts.txt" | tr -d ' ')
if [ "$FORGOTTEN" -gt 0 ]; then
    echo -e "${RED}[!] $FORGOTTEN hosts in CT but NOT resolving today (candidates: dead-subdomain takeover, historical-IP direct hit)${NC}"
    echo -e "    -> $OUTPUT_DIR/forgotten_hosts.txt  (then: historical IP lookup via SecurityTrails/shodan --history)"
else
    echo -e "${GRAY}[+] No forgotten hosts detected via DNS diff.${NC}"
fi

# --- 2. Wayback URL archaeology -> old API versions & sensitive files ---
echo -e "${YELLOW}[*] Pulling Wayback archive URLs...${NC}"
curl -sk --max-time 30 "http://web.archive.org/cdx/search/cdx?url=*.${TARGET_DOMAIN}/*&output=text&collapse=urlkey&limit=5000&fl=original" \
    | sort -u > "$OUTPUT_DIR/wayback_urls.txt" 2>/dev/null
WB_COUNT=$(wc -l < "$OUTPUT_DIR/wayback_urls.txt" | tr -d ' ')
echo -e "${GREEN}[+] $WB_COUNT archived URLs -> $OUTPUT_DIR/wayback_urls.txt${NC}"

echo -e "${YELLOW}[*] Mining old API versions & sensitive artifacts...${NC}"
grep -aiE '/api/v[0-9]+[a-z_-]*/|/api/(internal|legacy|beta|alpha|debug|old)[a-z_-]*/' "$OUTPUT_DIR/wayback_urls.txt" 2>/dev/null \
    | sort -u > "$OUTPUT_DIR/old_api_versions.txt"
grep -aiE '\.(js|json|xml|env|git|zip|sql|bak|config)(\?|$)' "$OUTPUT_DIR/wayback_urls.txt" 2>/dev/null \
    | sort -u > "$OUTPUT_DIR/old_sensitive_files.txt"
OLD_API=$(wc -l < "$OUTPUT_DIR/old_api_versions.txt" | tr -d ' ')
OLD_FILES=$(wc -l < "$OUTPUT_DIR/old_sensitive_files.txt" | tr -d ' ')
[ "$OLD_API" -gt 0 ] && echo -e "${RED}[!] $OLD_API legacy/internal API version paths -> $OUTPUT_DIR/old_api_versions.txt${NC}" \
    || echo -e "${GRAY}[+] No legacy API paths surfaced.${NC}"
[ "$OLD_FILES" -gt 0 ] && echo -e "${YELLOW}[!] $OLD_FILES historically-exposed file artifacts -> $OUTPUT_DIR/old_sensitive_files.txt${NC}"

# --- 3. robots.txt drift ---
echo -e "${YELLOW}[*] Fetching current robots.txt for drift baseline...${NC}"
curl -sk --max-time 10 "https://${TARGET_DOMAIN}/robots.txt" 2>/dev/null > "$OUTPUT_DIR/robots_current.txt"
CURRENT_RULES=$(wc -l < "$OUTPUT_DIR/robots_current.txt" | tr -d ' ')
echo -e "${GRAY}[+] Current robots.txt: $CURRENT_RULES lines ($OUTPUT_DIR/robots_current.txt)${NC}"
echo -e "${GRAY}[*] Compare manually with Wayback captures (e.g. web.archive.org/web/2018/https://${TARGET_DOMAIN}/robots.txt)${NC}"

echo -e "\n${GREEN}[+] Time-travel recon complete.${NC}"
echo -e "[!] Next: feed forgotten/legacy candidates into the Runtime signals, verify live with httpx, then Workflow/12 Phase 5 checklist."
