#!/bin/bash
# ==============================================================================
# 🔗 Automated Broken Link Hijacking (BLH) & Unclaimed Asset Scanner
# Bash port of find_broken_links.ps1 — extracts external links, flags 404/410
# on high-value third-party assets (GitHub, Twitter/X, LinkedIn, S3, Bitly).
# ==============================================================================

TARGET_URL="${1:-}"
OUTPUT_DIR="${2:-recon_output}"
TIMEOUT_SEC="${3:-8}"

if [ -z "$TARGET_URL" ]; then
    echo "Usage: ./scripts/find_broken_links.sh <target_url> [output_dir] [timeout_sec]"
    echo "Example: ./scripts/find_broken_links.sh https://docs.target.com"
    exit 1
fi

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] Broken Link Hijacking (BLH) Prober${NC}"
echo -e "${CYAN}[+] Target URL: $TARGET_URL${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/broken_links_report.jsonl"
CANDIDATES_FILE="$OUTPUT_DIR/hijackable_candidates.txt"
: > "$OUTPUT_FILE"; : > "$CANDIDATES_FILE"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugBountyResearch/1.0"

# 1. Fetch target page
echo -e "${YELLOW}[*] Fetching content from $TARGET_URL...${NC}"
HTML=$(curl -skL --max-time "$TIMEOUT_SEC" -A "$UA" "$TARGET_URL" 2>/dev/null)
if [ -z "$HTML" ]; then
    echo -e "${RED}[-] Failed to fetch target page.${NC}"
    exit 1
fi

# 2. Extract hyperlinks
echo -e "${YELLOW}[*] Extracting hyperlinks...${NC}"
UNIQUE_URLS=$(echo "$HTML" | grep -oP 'href=["'"'"']\Khttps?://[^"'"'"'\s>]+' 2>/dev/null | sort -u)
LINK_COUNT=0; [ -n "$UNIQUE_URLS" ] && LINK_COUNT=$(echo "$UNIQUE_URLS" | wc -l | tr -d ' ')
echo -e "${GREEN}[+] Found $LINK_COUNT unique external/internal links.${NC}"

# 3. Filter for high-value asset targets
CANDIDATES=$(echo "$UNIQUE_URLS" | grep -E \
    'github\.com/|twitter\.com/|x\.com/|linkedin\.com/|s3\.amazonaws\.com|cname\.bitly\.com|bit\.ly/' 2>/dev/null)
CAND_COUNT=0; [ -n "$CANDIDATES" ] && CAND_COUNT=$(echo "$CANDIDATES" | wc -l | tr -d ' ')
echo -e "${CYAN}[*] Analyzing $CAND_COUNT high-value third-party candidate links...${NC}"

# 4. Probe link status (HEAD with GET fallback)
BROKEN_COUNT=0
while IFS= read -r url; do
    [ -z "$url" ] && continue
    printf "  -> Probing: %s" "$url"
    STATUS=$(curl -sk --max-time "$TIMEOUT_SEC" -A "$UA" -o /dev/null -w "%{http_code}" -I "$url" 2>/dev/null)

    # HEAD may be rejected (405/501) — fall back to GET
    if [ "$STATUS" = "405" ] || [ "$STATUS" = "501" ] || [ -z "$STATUS" ]; then
        STATUS=$(curl -sk --max-time "$TIMEOUT_SEC" -A "$UA" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    fi

    if [ -z "$STATUS" ]; then
        echo -e " ${GRAY}[Connection Failed]${NC}"
    elif [ "$STATUS" = "404" ] || [ "$STATUS" = "410" ]; then
        echo -e " ${RED}[POTENTIAL HIJACK: HTTP $STATUS]${NC}"
        BROKEN_COUNT=$((BROKEN_COUNT+1))
        jq -n -c --arg src "$TARGET_URL" --arg url "$url" --arg status "$STATUS" \
           --arg ts "$(date '+%Y-%m-%d %H:%M:%S')" \
           '{SourceUrl:$src, BrokenUrl:$url, StatusCode:($status|tonumber), Timestamp:$ts}' >> "$OUTPUT_FILE"
        echo "$url" >> "$CANDIDATES_FILE"
    else
        echo -e " ${GRAY}[Status: $STATUS]${NC}"
    fi
done <<< "$CANDIDATES"

echo -e "\n${GREEN}[+] Scan Finished!${NC}"
if [ "$BROKEN_COUNT" -gt 0 ]; then
    echo -e "${RED}[+] Total Broken / Potential Hijackable Links: $BROKEN_COUNT${NC}"
    echo -e "${YELLOW}[!] Review report: $OUTPUT_FILE${NC}"
    echo -e "${YELLOW}[!] Candidate list: $CANDIDATES_FILE${NC}"
else
    echo -e "${GREEN}[+] Total Broken / Potential Hijackable Links: 0${NC}"
fi
