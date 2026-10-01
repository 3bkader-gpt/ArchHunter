#!/bin/bash
# ==============================================================================
# 🔑 Automated JavaScript Asset, Secret & API Route Extractor
# Bash port of extract_js_secrets.ps1 — discovers JS bundles from a page,
# checks exposed .js.map source files, extracts API routes, flags secrets.
# ==============================================================================

TARGET_URL="${1:-}"
OUTPUT_DIR="${2:-recon_output}"
TIMEOUT_SEC="${3:-10}"

if [ -z "$TARGET_URL" ]; then
    echo "Usage: ./scripts/extract_js_secrets.sh <target_url> [output_dir] [timeout_sec]"
    echo "Example: ./scripts/extract_js_secrets.sh https://target.com"
    exit 1
fi

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; CRITICAL='\033[1;31m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==================================================${NC}"
echo -e "${CYAN}[+] JavaScript Secret & API Route Extractor${NC}"
echo -e "${CYAN}[+] Target URL: $TARGET_URL${NC}"
echo -e "${CYAN}[+] ==================================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/js_secrets_report.jsonl"
ROUTES_FILE="$OUTPUT_DIR/extracted_api_routes.txt"
: > "$REPORT_FILE"; : > "$ROUTES_FILE"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0.0.0"

# 1. Fetch target page
echo -e "${YELLOW}[*] Fetching page content...${NC}"
HTML=$(curl -skL --max-time "$TIMEOUT_SEC" -A "$UA" "$TARGET_URL" 2>/dev/null)
if [ -z "$HTML" ]; then
    echo -e "${RED}[-] Failed to fetch initial webpage.${NC}"
    exit 1
fi

# 2. Extract script tags and resolve relative URLs (pure bash resolver)
echo -e "${YELLOW}[*] Extracting script references...${NC}"
BASE_URL="${TARGET_URL%%\?*}"
BASE_SCHEME="${BASE_URL%%://*}"
BASE_REST="${BASE_URL#*://}"
BASE_AUTHORITY="${BASE_REST%%/*}"
BASE_PATH_DIR="${BASE_REST#"$BASE_AUTHORITY"}"
BASE_PATH_DIR="${BASE_PATH_DIR%/*}"
[ "$BASE_PATH_DIR" = "$BASE_REST" ] && BASE_PATH_DIR=""

resolve_url() { # Resolve candidate src against the page URL
    local src="$1"
    case "$src" in
        http://*|https://*) echo "$src" ;;
        //*) echo "$BASE_SCHEME:$src" ;;
        /*)  echo "$BASE_SCHEME://$BASE_AUTHORITY$src" ;;
        *)   echo "$BASE_SCHEME://$BASE_AUTHORITY$BASE_PATH_DIR/$src" ;;
    esac
}

SCRIPT_URLS=$(echo "$HTML" | grep -oP '<script[^>]+src=["'"'"']\K[^"'"'"']+' 2>/dev/null \
    | while IFS= read -r src; do
        [ -z "$src" ] && continue
        full=$(resolve_url "$src")
        case "$full" in
            *.js|*.js\?*|*.js*) echo "$full" ;;
        esac
    done | sort -u)

SCRIPT_COUNT=0; [ -n "$SCRIPT_URLS" ] && SCRIPT_COUNT=$(echo "$SCRIPT_URLS" | wc -l | tr -d ' ')
echo -e "${GREEN}[+] Discovered $SCRIPT_COUNT JavaScript files.${NC}"

# 3. Secret signatures: Name|PCRE pattern (group 1 via \K)
SECRET_SIGNATURES=(
    "AWS Access Key|\b\KAKIA[0-9A-Z]{16}"
    "Google API Key|\b\KAIza[0-9A-Za-z\-_]{35}"
    "Firebase URL|\b\K[a-z0-9.-]+\.firebaseio\.com"
    "Stripe Publishable|\b\Kpk_live_[0-9a-zA-Z]{24}"
    "Slack Token|\b\Kxox[baprs]-[0-9a-zA-Z]{10,48}"
    "Generic Bearer/JWT|\b\KeyJ[A-Za-z0-9\-_=]{20,}\.[A-Za-z0-9\-_=]{20,}\.[A-Za-z0-9\-_=]+"
)
API_ROUTE_PATTERN='["'"'"'\`]\K(/(?:api|v[0-9]|graphql|auth|admin|internal)/[a-zA-Z0-9_\-/]+)(?=["'"'"'\`])'

TOTAL_ROUTES=0
TOTAL_SECRETS=0

# 4. Probe and analyze each script
while IFS= read -r js_url; do
    [ -z "$js_url" ] && continue
    echo -e "\n${CYAN}[*] Inspecting: $js_url${NC}"

    JS_CONTENT=$(curl -skL --max-time "$TIMEOUT_SEC" -A "$UA" "$js_url" 2>/dev/null)
    if [ -z "$JS_CONTENT" ]; then
        echo -e "  ${GRAY}[-] Failed to download script.${NC}"
        continue
    fi

    # Check for exposed source map
    MAP_STATUS=$(curl -sk --max-time 5 -A "$UA" -o /dev/null -w "%{http_code}" -I "${js_url}.map" 2>/dev/null)
    if [ "$MAP_STATUS" = "200" ]; then
        echo -e "  ${RED}[!] EXPOSED SOURCE MAP FOUND: ${js_url}.map${NC}"
        jq -n -c --arg url "$js_url" --arg map "${js_url}.map" --arg ts "$(date '+%Y-%m-%d %H:%M:%S')" \
           '{Type:"Exposed Source Map", ScriptUrl:$url, MapUrl:$map, Timestamp:$ts}' >> "$REPORT_FILE"
    fi

    # Extract API routes
    ROUTES_IN_SCRIPT=$(echo "$JS_CONTENT" | grep -aoP "$API_ROUTE_PATTERN" 2>/dev/null | sort -u)
    if [ -n "$ROUTES_IN_SCRIPT" ]; then
        N=$(echo "$ROUTES_IN_SCRIPT" | wc -l | tr -d ' ')
        echo -e "  ${YELLOW}[+] Extracted $N internal API endpoints.${NC}"
        echo "$ROUTES_IN_SCRIPT" >> "$ROUTES_FILE"
    fi

    # Scan for secrets
    for sig in "${SECRET_SIGNATURES[@]}"; do
        name="${sig%%|*}"
        pat="${sig#*|}"
        MATCHES=$(echo "$JS_CONTENT" | grep -aoP "$pat" 2>/dev/null | sort -u)
        if [ -n "$MATCHES" ]; then
            while IFS= read -r secret; do
                echo -e "  ${CRITICAL}[CRITICAL LEAK] $name: $secret${NC}"
                TOTAL_SECRETS=$((TOTAL_SECRETS+1))
                jq -n -c --arg type "$name" --arg secret "$secret" --arg url "$js_url" \
                   --arg ts "$(date '+%Y-%m-%d %H:%M:%S')" \
                   '{Type:$type, Secret:$secret, ScriptUrl:$url, Timestamp:$ts}' >> "$REPORT_FILE"
            done <<< "$MATCHES"
        fi
    done
done <<< "$SCRIPT_URLS"

# 5. Summary
sort -u "$ROUTES_FILE" -o "$ROUTES_FILE"
TOTAL_ROUTES=$(wc -l < "$ROUTES_FILE" | tr -d ' ')

echo -e "\n${GREEN}[+] JavaScript Scan Completed!${NC}"
echo -e "${GREEN}[+] Total Unique API Routes Discovered: $TOTAL_ROUTES${NC}"
if [ "$TOTAL_SECRETS" -gt 0 ]; then
    echo -e "${RED}[+] Total Hardcoded Secrets Flagged: $TOTAL_SECRETS${NC}"
else
    echo -e "${GREEN}[+] Total Hardcoded Secrets Flagged: 0${NC}"
fi
echo -e "[!] API Routes list saved to: $ROUTES_FILE"
echo -e "[!] Secrets & findings saved to: $REPORT_FILE"
