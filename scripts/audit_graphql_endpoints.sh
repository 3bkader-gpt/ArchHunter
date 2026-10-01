#!/bin/bash
# ==============================================================================
# 🕸️ Automated GraphQL Endpoint Discovery & Security Auditor
# Bash port of audit_graphql_endpoints.ps1 — path discovery, introspection,
# array-based query batching, and field-suggestion leak detection.
# ==============================================================================

TARGET_HOST="${1:-}"
OUTPUT_DIR="${2:-recon_output}"
TIMEOUT_SEC="${3:-8}"

if [ -z "$TARGET_HOST" ]; then
    echo "Usage: ./scripts/audit_graphql_endpoints.sh <target_host> [output_dir] [timeout_sec]"
    echo "Example: ./scripts/audit_graphql_endpoints.sh https://target.com"
    exit 1
fi

TARGET_HOST="${TARGET_HOST%/}"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] GraphQL Security Prober & Endpoint Auditor${NC}"
echo -e "${CYAN}[+] Target Host: $TARGET_HOST${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/graphql_audit_report.jsonl"
: > "$REPORT_FILE"

COMMON_PATHS=(
    "/graphql" "/api/graphql" "/v1/graphql" "/v2/graphql" "/gql"
    "/query" "/api/query" "/graphql/console" "/api/v1/graphql"
)

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugBountyResearch/1.0"
FOUND_COUNT=0

gql_post() { # url body -> prints body
    curl -sk --max-time "$TIMEOUT_SEC" -X POST -H "Content-Type: application/json" -A "$UA" -d "$2" "$1" 2>/dev/null
}

for path in "${COMMON_PATHS[@]}"; do
    FULL_URL="$TARGET_HOST$path"
    printf "${CYAN}[*] Testing: %s${NC}" "$FULL_URL"

    RESP=$(gql_post "$FULL_URL" '{"query": "{ __typename }"}')

    if [ -n "$RESP" ] && [[ "$RESP" == *'"data"'* || "$RESP" == *'"errors"'* ]]; then
        echo -e " ${GREEN}[DETECTED GRAPHQL]${NC}"
        FOUND_COUNT=$((FOUND_COUNT+1))

        # --- Test 1: Introspection ---
        printf "    -> Testing Introspection... "
        INTRO_STATUS="DISABLED"
        INTRO_RESP=$(gql_post "$FULL_URL" '{"query": "{ __schema { types { name } } }"}')
        if [ -n "$INTRO_RESP" ] && [[ "$INTRO_RESP" == *'"__schema"'* ]]; then
            TYPE_COUNT=$(echo "$INTRO_RESP" | jq '[.data.__schema.types[]] | length' 2>/dev/null || echo "unknown")
            echo -e "${RED}[VULNERABLE: Introspection Enabled ($TYPE_COUNT types)]${NC}"
            INTRO_STATUS="ENABLED"
        else
            echo -e "${GRAY}[Disabled/Blocked]${NC}"
        fi

        # --- Test 2: Array-Based Query Batching ---
        printf "    -> Testing Query Batching... "
        BATCH_STATUS="DISABLED"
        BATCH_RESP=$(gql_post "$FULL_URL" '[{"query": "{ __typename }"}, {"query": "{ __typename }"}]')
        if [ -n "$BATCH_RESP" ]; then
            BATCH_LEN=$(echo "$BATCH_RESP" | jq 'if type == "array" then length else 0 end' 2>/dev/null || echo 0)
            if [ "$BATCH_LEN" = "2" ]; then
                echo -e "${YELLOW}[VULNERABLE: Batching Enabled (Rate-limit bypass potential)]${NC}"
                BATCH_STATUS="ENABLED"
            else
                echo -e "${GRAY}[Disabled]${NC}"
            fi
        else
            echo -e "${GRAY}[Disabled/Blocked]${NC}"
        fi

        # --- Test 3: Field Suggestions Leak ---
        printf "    -> Testing Field Suggestions... "
        SUGG_STATUS="SAFE"
        FUZZ_RESP=$(gql_post "$FULL_URL" '{"query": "{ nonExistentFieldXYZ }"}')
        if [ -n "$FUZZ_RESP" ] && [[ "$FUZZ_RESP" == *"Did you mean"* ]]; then
            echo -e "${YELLOW}[LEAK: Suggestions Enabled]${NC}"
            SUGG_STATUS="ENABLED"
        else
            echo -e "${GRAY}[Safe]${NC}"
        fi

        TS=$(date '+%Y-%m-%d %H:%M:%S')
        jq -n -c --arg ep "$FULL_URL" --arg intro "$INTRO_STATUS" --arg batch "$BATCH_STATUS" \
           --arg sugg "$SUGG_STATUS" --arg ts "$TS" \
           '{Endpoint:$ep, Introspection:$intro, Batching:$batch, FieldSuggestions:$sugg, Timestamp:$ts}' >> "$REPORT_FILE"
    else
        echo -e " ${GRAY}[Not GraphQL / Unreachable]${NC}"
    fi
done

echo -e "\n${GREEN}[+] GraphQL Audit Completed!${NC}"
if [ "$FOUND_COUNT" -gt 0 ]; then
    echo -e "${GREEN}[+] Total Detected GraphQL Endpoints: $FOUND_COUNT${NC}"
    echo -e "${YELLOW}[!] Detailed audit results stored in: $REPORT_FILE${NC}"
else
    echo -e "${GRAY}[+] Total Detected GraphQL Endpoints: 0${NC}"
fi
