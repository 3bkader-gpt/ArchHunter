#!/bin/bash
# ==============================================================================
# 🪤 Parameter Extraction & Context Reflection Pipeline (Bash port of
# param_reflection_pipeline.ps1). gf -> uro -> qsreplace -> kxss equivalent:
# normalizes URLs, injects canary tokens, probes reflection contexts.
# ==============================================================================

TARGET_DOMAIN=""
URL_FILE=""
OUTPUT_FILE="recon/params/reflected_params.json"
CANARY_PREFIX="bxss"
TIMEOUT_SEC=8
MAX_URLS=500

usage() {
    cat <<EOF
Usage: ./scripts/param_reflection_pipeline.sh -d <target_domain> [-f url_file] [options]

Options:
  -d <domain>   Fetch historical URLs for this domain via OTX & Wayback
  -f <file>     Read candidate URLs from file (one per line)
  -o <file>     Output JSON path (default: recon/params/reflected_params.json)
  -p <prefix>   Canary token prefix (default: bxss)
  -t <seconds>  Timeout per request (default: 8)
  -n <count>    Max URLs from OSINT sources (default: 500)
  -h            Show this help
Example:
  ./scripts/param_reflection_pipeline.sh -d example.com -n 100
EOF
    exit 1
}

while getopts "d:f:o:p:t:n:h" opt; do
    case $opt in
        d) TARGET_DOMAIN="$OPTARG" ;;
        f) URL_FILE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        p) CANARY_PREFIX="$OPTARG" ;;
        t) TIMEOUT_SEC="$OPTARG" ;;
        n) MAX_URLS="$OPTARG" ;;
        h|*) usage ;;
    esac
done

[ -z "$TARGET_DOMAIN" ] && [ -z "$URL_FILE" ] && usage

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; MAGENTA='\033[0;35m'; NC='\033[0m'
RAW_URLS=$(mktemp); FILTERED=$(mktemp)
trap 'rm -f "$RAW_URLS" "$FILTERED"' EXIT

# --- 0. URL collection ---
if [ -n "$URL_FILE" ] && [ -f "$URL_FILE" ]; then
    grep -E "^https?://" < "$URL_FILE" >> "$RAW_URLS" || true
fi

if [ -n "$TARGET_DOMAIN" ]; then
    echo -e "${CYAN}[*] Fetching historical URLs for $TARGET_DOMAIN via AlienVault OTX & Wayback...${NC}"
    curl -sk --max-time 10 "https://otx.alienvault.com/api/v1/indicators/domain/$TARGET_DOMAIN/url_list?limit=100&page=1" \
        | jq -r '.url_list[]?.url // empty' 2>/dev/null >> "$RAW_URLS"
    curl -sk --max-time 10 "https://web.archive.org/cdx/search/cdx?url=*.$TARGET_DOMAIN/*&output=json&collapse=urlkey&limit=$MAX_URLS" \
        | jq -r '.[1:][]?[2] // empty' 2>/dev/null >> "$RAW_URLS"
fi

TOTAL_RAW=$(grep -E "^https?://" < "$RAW_URLS" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOTAL_RAW" -eq 0 ]; then
    echo -e "${RED}[-] No URLs provided or discovered with parameters.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Collected $TOTAL_RAW raw URLs. Normalizing & filtering for query parameters...${NC}"

# --- 1. Normalization (uro equivalent): dedupe on host+path+sorted param names ---
STATIC_EXT='\.(png|jpe?g|gif|css|woff2?|ttf|svg|ico|pdf)$'
while IFS= read -r raw; do
    [ -z "$raw" ] && continue
    host=$(echo "$raw" | sed -E 's#^(https?://)([^/]+).*#\2#')
    path_query=$(echo "$raw" | sed -E 's#^https?://[^/]+##')
    path="${path_query%%\?*}"
    query="${path_query#*\?}"
    [ "$query" = "$path_query" ] && continue          # no query string
    [[ "$path" =~ $STATIC_EXT ]] && continue          # static asset
    params="${query%%#*}"
    keys=$(echo "$params" | tr '&+' '\n\n' | sed -E 's/=.*//' | sort -u | paste -sd'&' -)
    [ -z "$keys" ] && continue
    key="${host}${path}?${keys}"
    if ! grep -qF "$key" < "$FILTERED.dedupe" 2>/dev/null; then
        echo "$key" >> "$FILTERED.dedupe"
        echo "$raw" >> "$FILTERED"
    fi
done < "$RAW_URLS"

TOTAL_FILTERED=$(wc -l < "$FILTERED" | tr -d ' ')
echo -e "${GREEN}[+] Found $TOTAL_FILTERED unique parameterized endpoints.${NC}"
if [ "$TOTAL_FILTERED" -eq 0 ]; then
    echo -e "${YELLOW}[-] No endpoints with query parameters found.${NC}"
    exit 0
fi

# --- 2. Canary seeding & reflection probing ---
CANARY="${CANARY_PREFIX}73<\"'\`>"
RESULTS=$(mktemp)
FOUND=0
counter=0

echo -e "${CYAN}[*] Probing for reflections using canary: $CANARY${NC}"

while IFS= read -r orig_url; do
    counter=$((counter+1))
    # Split off query
    base="${orig_url%%\?*}"
    query="${orig_url#*\?}"

    # Iterate each parameter key
    IFS='&' read -ra PAIRS <<< "$query"
    for pair in "${PAIRS[@]}"; do
        [ -z "$pair" ] && continue
        key="${pair%%=*}"
        [ -z "$key" ] && continue

        # Rebuild query with canary in this param only
        new_query=""
        for p2 in "${PAIRS[@]}"; do
            [ -z "$p2" ] && continue
            k2="${p2%%=*}"
            if [ "$k2" = "$key" ]; then
                new_query="${new_query:+$new_query&}${k2}=${CANARY}"
            else
                new_query="${new_query:+$new_query&}${p2}"
            fi
        done
        test_url="${base}?${new_query}"

        printf "\r[*] [%d/%d] Testing parameter: %s on %s...  " "$counter" "$TOTAL_FILTERED" "$key" "$(echo "$base" | sed -E 's#^https?://([^/]+).*#\1#')" >&2

        body=$(curl -sk --max-time "$TIMEOUT_SEC" \
            -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" \
            -w "\n%{http_code}" "$test_url" 2>/dev/null) || continue
        status="${body##*$'\n'}"
        body="${body%$'\n'*}"
        [ -z "$body" ] && continue
        [[ "$body" != *"$CANARY_PREFIX"* ]] && continue

        # Reflection confirmed — analyze context
        context="BODY_TEXT"
        if echo "$body" | grep -qE "<script[^>]*>[^<]*${CANARY_PREFIX}"; then
            context="INLINE_SCRIPT"
        elif echo "$body" | grep -qE "<[^>]*=[\"'][^\"']*${CANARY_PREFIX}"; then
            context="HTML_ATTRIBUTE"
        elif echo "$body" | grep -qE "<!--[^>]*${CANARY_PREFIX}"; then
            context="HTML_COMMENT"
        fi

        # Unescaped dangerous chars adjacent to the canary prefix
        unfiltered=""
        for c in '<' '>' '"' "'" '`'; do
            case "$c" in
                '<') pat="${CANARY_PREFIX}73[^\"'>]*<" ;;
                '>') pat="${CANARY_PREFIX}73[^\"'>]*>" ;;
                '"') pat="${CANARY_PREFIX}73[^'>]*\"" ;;
                "'") pat="${CANARY_PREFIX}73[^\">]*'" ;;
                '`') pat="${CANARY_PREFIX}73[^\"'>]*\`" ;;
            esac
            if echo "$body" | grep -qP "$pat" 2>/dev/null || echo "$body" | grep -qE "$pat" 2>/dev/null; then
                unfiltered="${unfiltered}${unfiltered:+ }$c"
            fi
        done

        echo -e "\n${YELLOW}[!] REFLECTION CONFIRMED!${NC}"
        echo -e "    ${CYAN}URL:     $test_url${NC}"
        echo -e "    ${MAGENTA}Param:   $key${NC}"
        echo -e "    ${GREEN}Context: $context${NC}"
        echo -e "    ${RED}Unescaped Chars: ${unfiltered:-none}${NC}"

        FOUND=$((FOUND+1))
        jq -n -c --arg param "$key" --arg url "$test_url" --arg orig "$orig_url" \
           --arg ctx "$context" --arg chars "$unfiltered" --arg status "$status" \
           '{Param:$param, Url:$url, OriginalUrl:$orig, Context:$ctx,
             UnfilteredChars:($chars|split(" ")), StatusCode:($status|tonumber)}' >> "$RESULTS"
    done
done < "$FILTERED"

echo -e "\n\n${GREEN}[+] Finished scanning. Reflected parameters found: $FOUND${NC}"

if [ "$FOUND" -gt 0 ]; then
    out_dir=$(dirname "$OUTPUT_FILE")
    mkdir -p "$out_dir"
    cat "$RESULTS" | python3 -c 'import json,sys; print(json.dumps([json.loads(l) for l in sys.stdin if l.strip()], indent=2))' \
        > "$OUTPUT_FILE" 2>/dev/null || cp "$RESULTS" "$OUTPUT_FILE"
    echo -e "${GREEN}[+] Results saved to: $OUTPUT_FILE${NC}"
fi
