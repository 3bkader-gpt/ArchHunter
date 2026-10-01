#!/bin/bash
# ==============================================================================
# 🔍 13-Pattern Targeted JavaScript Bundle Analyzer (Bash port of
# analyze_js_bundle.ps1). Extracts API endpoints, admin routes, auth flows,
# GraphQL ops, WebSockets, and source maps from local JS bundles.
# ==============================================================================

JS_FILE=""
JS_DIR=""
OUTPUT_DIR="recon/api"

usage() {
    cat <<EOF
Usage: ./scripts/analyze_js_bundle.sh [-f <js_file>] [-d <js_directory>] [-o <output_dir>]

Options:
  -f <file>    Single JS file to analyze
  -d <dir>     Directory to scan recursively for *.js
  -o <dir>     Output directory (default: recon/api)
  -h           Show this help
Examples:
  ./scripts/analyze_js_bundle.sh -f recon/js/main.js
  ./scripts/analyze_js_bundle.sh -d recon/js -o recon/api
EOF
    exit 1
}

while getopts "f:d:o:h" opt; do
    case $opt in
        f) JS_FILE="$OPTARG" ;;
        d) JS_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        h|*) usage ;;
    esac
done

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}========================================================${NC}"
echo -e "${CYAN} 🏛️ ArchHunter: 13-Pattern JS Bundle Deep Inspector${NC}"
echo -e "${CYAN}========================================================${NC}\n"

mkdir -p "$OUTPUT_DIR"

# Build target file list
FILELIST=$(mktemp)
trap 'rm -f "$FILELIST"' EXIT
if [ -n "$JS_FILE" ] && [ -f "$JS_FILE" ]; then
    echo "$JS_FILE" >> "$FILELIST"
elif [ -n "$JS_DIR" ] && [ -d "$JS_DIR" ]; then
    find "$JS_DIR" -type f -name "*.js" >> "$FILELIST"
else
    echo -e "${RED}[-] Please provide a valid -f <js_file> or -d <js_directory>.${NC}"
    exit 1
fi

FILE_COUNT=$(wc -l < "$FILELIST" | tr -d ' ')
echo -e "${YELLOW}[*] Analyzing $FILE_COUNT JavaScript file(s)...${NC}"

RESULTS_DIR=$(mktemp -d)
mkdir -p "$RESULTS_DIR"/{01..13}

# 13 offensive patterns: "id|name|grep -oP pattern"
# \K marks the capture-group equivalent (inner quoted value) where the ps1 used group 1.
PATTERNS=(
    "01|API Endpoints|(?i)[\"']\K(/api/[a-zA-Z0-9_\-\./]+)(?=[\"'])"
    "02|Full External URLs|https?://[a-zA-Z0-9_\-\.:]+(?:/[a-zA-Z0-9_\-\./\?&=%#]*)?"
    "03|Route Keywords|(?i)[\"']\K(/[a-zA-Z0-9_\-/]*(?:api|endpoint|route|gateway)[a-zA-Z0-9_\-/]*)(?=[\"'])"
    "04|Admin Controls|(?i)[\"']\K(/[a-zA-Z0-9_\-/]*(?:admin|administrator|management|superadmin)[a-zA-Z0-9_\-/]*)(?=[\"'])"
    "05|Auth & Registration|(?i)[\"']\K(/[a-zA-Z0-9_\-/]*(?:login|logout|signin|signup|register|auth|oauth|token|sso)[a-zA-Z0-9_\-/]*)(?=[\"'])"
    "06|User & Account Surfaces|(?i)[\"']\K(/[a-zA-Z0-9_\-/]*(?:user|account|profile|settings|tenant|org)[a-zA-Z0-9_\-/]*)(?=[\"'])"
    "07|Sensitive ID Parameters|(?i)(?:id=|userId|user_id|accountId|account_id|orgId|org_id|tenantId|redirect|returnUrl)[=:][\"'a-zA-Z0-9_\-]*"
    "08|API Versions (Legacy)|(?i)[\"']\K(/api/v\d+/[a-zA-Z0-9_\-\./]+)(?=[\"'])"
    "09|WebSocket Channels|(?i)wss?://[a-zA-Z0-9_\-\.:]+[a-zA-Z0-9_\-\./]*"
    "10|Config & Data Files|(?i)[\"']\K([/a-zA-Z0-9_\-\.]+\.(?:php|json|xml|config|graphql|env|yaml|yml))(?=[\"'])"
    "11|GraphQL Operations|(?i)(?:mutation|query|subscription)\s+[a-zA-Z0-9_]+"
    "12|Source Map Pointers|(?i)(?:[\"']\K[^\"']+\.map(?=[\"'])|//#\s*sourceMappingURL=\K[^\s]+)"
    "13|HTTP Client Invocations|(?i)(?:fetch\(|axios\.(?:get|post|put|delete|patch)\(|XMLHttpRequest)"
)

declare -A COUNTS

while IFS='|' read -r id name pat; do
    while IFS= read -r file; do
        grep -aoP "$pat" "$file" 2>/dev/null \
            | sed "s/^[\"'\` ]*//; s/[\"'\` ]*$//" \
            | awk 'length($0) > 1 && length($0) < 250' \
            >> "$RESULTS_DIR/$id/hits.txt" || true
    done < "$FILELIST"
    if [ -f "$RESULTS_DIR/$id/hits.txt" ]; then
        sort -u "$RESULTS_DIR/$id/hits.txt" -o "$RESULTS_DIR/$id/hits.txt"
        COUNTS[$id]=$(wc -l < "$RESULTS_DIR/$id/hits.txt" | tr -d ' ')
    else
        COUNTS[$id]=0
    fi
done < <(printf '%s\n' "${PATTERNS[@]}")

echo -e "\n${GREEN}[+] ================= 13-PATTERN SUMMARY ==================${NC}"
while IFS='|' read -r id name _; do
    c="${COUNTS[$id]}"
    color=$GRAY; [ "$c" -gt 0 ] && color=$NC
    echo -e "  ${color}[$id. $name]: $c unique hits${NC}"
done < <(printf '%s\n' "${PATTERNS[@]}")
echo -e "${GREEN}========================================================${NC}\n"

# API list = union of categories 01, 08, 04
cat "$RESULTS_DIR"/01/hits.txt "$RESULTS_DIR"/08/hits.txt "$RESULTS_DIR"/04/hits.txt 2>/dev/null \
    | sort -u > "$OUTPUT_DIR/api-list.txt"
API_COUNT=$(wc -l < "$OUTPUT_DIR/api-list.txt" | tr -d ' ')
echo -e "${GREEN}[+] Extracted $API_COUNT unique API endpoints to: $OUTPUT_DIR/api-list.txt${NC}"

# Full JSON report
if command -v python3 >/dev/null 2>&1; then
    python3 - "$RESULTS_DIR" "$OUTPUT_DIR/js_analysis_report.json" <<'PYEOF'
import json, os, sys
results_dir, out = sys.argv[1], sys.argv[2]
names = {
    "01": "1. API Endpoints", "02": "2. Full External URLs", "03": "3. Route Keywords",
    "04": "4. Admin Controls", "05": "5. Auth & Registration", "06": "6. User & Account Surfaces",
    "07": "7. Sensitive ID Parameters", "08": "8. API Versions (Legacy)", "09": "9. WebSocket Channels",
    "10": "10. Config & Data Files", "11": "11. GraphQL Operations", "12": "12. Source Map Pointers",
    "13": "13. HTTP Client Invocations",
}
report = {}
for i in range(1, 14):
    key = f"{i:02d}"
    path = os.path.join(results_dir, key, "hits.txt")
    vals = []
    if os.path.exists(path):
        with open(path, encoding="utf-8", errors="replace") as fh:
            vals = [l.rstrip("\n") for l in fh if l.strip()]
    report[names[key]] = vals
with open(out, "w", encoding="utf-8") as fh:
    json.dump(report, fh, indent=2)
PYEOF
    echo -e "${GREEN}[+] Full 13-Pattern JSON report saved to: $OUTPUT_DIR/js_analysis_report.json${NC}"
else
    echo -e "${YELLOW}[!] python3 not found — JSON report skipped (txt outputs written).${NC}"
fi
