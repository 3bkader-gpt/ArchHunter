#!/bin/bash
# ==============================================================================
# 🕳️ Shadow API Probe — Spec-File Discovery & Undocumented Surface Fingerprint
# (Workflow/12 Phase 4). Brute-forces API spec artifacts (openapi.json,
# swagger, api-docs, schema.graphql) and fingerprints shadow-API indicators.
# ==============================================================================

TARGET_HOST="${1:-}"
OUTPUT_DIR="${2:-recon/shadow_api}"

if [ -z "$TARGET_HOST" ]; then
    echo "Usage: ./scripts/shadow_api_probe.sh <target_host> [output_dir]"
    echo "Example: ./scripts/shadow_api_probe.sh https://target.com"
    exit 1
fi

TARGET_HOST="${TARGET_HOST%/}"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] Shadow API Probe: $TARGET_HOST${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
SPEC_FILE="$OUTPUT_DIR/exposed_specs.txt"
ROUTES_FILE="$OUTPUT_DIR/shadow_routes.txt"
: > "$SPEC_FILE"; : > "$ROUTES_FILE"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugBountyResearch/1.0"

# --- 1. Spec artifact brute-force (spec paths, not directory fuzz) ---
SPEC_PATHS=(
    "/openapi.json" "/openapi.yaml" "/swagger.json" "/swagger.yaml"
    "/v1/swagger.json" "/v2/swagger.json" "/v3/swagger.json"
    "/api/openapi.json" "/api/swagger.json" "/api-docs" "/v2/api-docs" "/v3/api-docs"
    "/api/__docs" "/api/docs" "/docs" "/swagger" "/swagger/ui"
    "/schema.graphql" "/graphql/schema.json"
    "/.well-known/openid-configuration" "/.well-known/ai-plugin.json"
)

echo -e "${YELLOW}[*] Probing ${#SPEC_PATHS[@]} API spec artifact paths...${NC}"
for path in "${SPEC_PATHS[@]}"; do
    STATUS=$(curl -sk --max-time 8 -A "$UA" -o /dev/null -w "%{http_code}" "${TARGET_HOST}${path}" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo -e "  ${RED}[EXPOSED SPEC] ${TARGET_HOST}${path}${NC}"
        echo "${TARGET_HOST}${path}" >> "$SPEC_FILE"
    elif [ "$STATUS" != "000" ] && [ "$STATUS" != "404" ]; then
        echo -e "  ${GRAY}[$STATUS] ${path}${NC}"
    fi
done

# --- 2. GraphQL introspection quick-check (schema = spec equivalent) ---
echo -e "\n${YELLOW}[*] Checking GraphQL schema exposure...${NC}"
GQL_STATUS=$(curl -sk --max-time 8 -X POST -H "Content-Type: application/json" -A "$UA" \
    -d '{"query":"{ __schema { types { name } } }"}' \
    -o /dev/null -w "%{http_code}" "${TARGET_HOST}/graphql" 2>/dev/null)
if [ "$GQL_STATUS" = "200" ]; then
    echo -e "  ${RED}[EXPOSED SCHEMA] ${TARGET_HOST}/graphql answers introspection${NC}"
    echo "${TARGET_HOST}/graphql (introspection)" >> "$SPEC_FILE"
fi

# --- 3. Shadow-route fingerprinting (JS-derived keywords + version skew) ---
echo -e "\n${YELLOW}[*] Fingerprinting undocumented route families (401/403 = exists+authz gap)${NC}"
ROUTE_PROBES=(
    "/api/internal/users/export" "/internal-api/status" "/api/v1_internal/health"
    "/api/admin/debug" "/api/debug/vars" "/actuator" "/actuator/env" "/console"
    "/api/v1/users" "/api/v2/users" "/api/v1_internal/users"
)
for path in "${ROUTE_PROBES[@]}"; do
    STATUS=$(curl -sk --max-time 8 -A "$UA" -o /dev/null -w "%{http_code}" "${TARGET_HOST}${path}" 2>/dev/null)
    case "$STATUS" in
        200|301|302)
            echo -e "  ${RED}[OPEN $STATUS] ${path}${NC}"
            echo "$path" >> "$ROUTES_FILE" ;;
        401|403)
            echo -e "  ${YELLOW}[AUTHZ $STATUS] ${path} — exists, test header spoof / version skew${NC}"
            echo "$path" >> "$ROUTES_FILE" ;;
        *) : ;;
    esac
done

SPECS=$(wc -l < "$SPEC_FILE" | tr -d ' ')
ROUTES=$(wc -l < "$ROUTES_FILE" | tr -d ' ')

echo -e "\n${GREEN}[+] Shadow API probe complete.${NC}"
echo -e "${GREEN}[+] Exposed spec artifacts: $SPECS -> $SPEC_FILE${NC}"
echo -e "${YELLOW}[+] Shadow route candidates: $ROUTES -> $ROUTES_FILE${NC}"
echo -e "[!] Next: replay 401/403 routes with header spoofing (payloads/headers/) and across API versions (Workflow/12 Phase 5)."
