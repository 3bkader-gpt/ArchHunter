#!/bin/bash
# ==============================================================================
# 🎯 API Schema & Documentation Harvester
# Probes alive hosts for Swagger, OpenAPI, GraphQL, and Postman specs
# ==============================================================================

set -e

TARGET_DOMAIN=$1
ALIVE_HOSTS_FILE=${2:-"recon/$TARGET_DOMAIN/subs/alive_hosts.txt"}

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/discover_api_endpoints.sh <target_domain> [alive_hosts_file]"
    echo "Example: ./scripts/discover_api_endpoints.sh target.com"
    exit 1
fi

RECON_DIR="recon/$TARGET_DOMAIN"
URLS_DIR="$RECON_DIR/urls"
mkdir -p "$URLS_DIR"

API_PATHS_FILE="$URLS_DIR/api_probe_paths.txt"
FOUND_SCHEMAS="$URLS_DIR/discovered_api_schemas.txt"

echo -e "\e[1;32m[+] Starting API Documentation Discovery for: $TARGET_DOMAIN\e[0m"

cat <<EOF > "$API_PATHS_FILE"
swagger.json
swagger/v1/swagger.json
api/swagger.json
v2/api-docs
v3/api-docs
api-docs
openapi.json
api/openapi.json
swagger-ui.html
swagger-ui/
api/swagger-ui.html
docs
api/docs
graphql
api/graphql
v1/graphql
graphiql
altair
playground
api/playground
postman.json
EOF

if [ -f "$ALIVE_HOSTS_FILE" ]; then
    TARGET_URLS="$ALIVE_HOSTS_FILE"
else
    TARGET_URLS="$URLS_DIR/single_target.txt"
    echo "https://${TARGET_DOMAIN}" > "$TARGET_URLS"
fi

echo -e "\e[1;34m[*] Probing endpoints across $(wc -l < "$TARGET_URLS") hosts...\e[0m"

cat "$TARGET_URLS" | while read -r host; do
    while read -r path; do
        echo "${host%/}/${path#/}"
    done < "$API_PATHS_FILE"
done | httpx -mc 200 -title -status-code -content-type -silent -o "$FOUND_SCHEMAS"

COUNT=$(wc -l < "$FOUND_SCHEMAS" || echo 0)
if [ "$COUNT" -gt 0 ]; then
    echo -e "\e[1;32m[🎯 DISCOVERED API SCHEMAS & DOCS! ($COUNT found)]\e[0m"
    cat "$FOUND_SCHEMAS"
else
    echo "[-] No exposed API schemas or GraphQL playgrounds discovered on tested hosts."
fi

echo -e "\e[1;33m[!] Results saved at: $FOUND_SCHEMAS\e[0m"
