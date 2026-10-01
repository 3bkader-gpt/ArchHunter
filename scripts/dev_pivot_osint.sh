#!/bin/bash
# ==============================================================================
# 👥 Developer-Pivot OSINT Assistant (Workflow/12 Phase 6)
# Passive human-surface recon: GitHub org commit-email mining (API, needs
# GITHUB_TOKEN), dork-list generation for boards/tfstate/Postman/npm, and
# archived-docs waypoints. Generates leads; human verifies each one.
# ==============================================================================

TARGET_DOMAIN="${1:-}"
ORG_GITHUB="${2:-}"        # GitHub org/login (defaults to domain root label)
OUTPUT_DIR="${3:-recon/osint}"

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/dev_pivot_osint.sh <domain> [github_org] [output_dir]"
    echo "Environment: GITHUB_TOKEN (recommended — unauthenticated API is heavily rate-limited)"
    echo "Example: ./scripts/dev_pivot_osint.sh acme.com acme-corp"
    exit 1
fi

ORG_GITHUB="${ORG_GITHUB:-${TARGET_DOMAIN%%.*}}"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] Developer-Pivot OSINT: $TARGET_DOMAIN (org: $ORG_GITHUB)${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
CORE="${TARGET_DOMAIN%%.*}"

GH_ARGS=()
if [ -n "$GITHUB_TOKEN" ]; then
    GH_ARGS=(-H "Authorization: Bearer $GITHUB_TOKEN")
    echo -e "${GREEN}[+] GITHUB_TOKEN detected — authenticated API mode.${NC}"
else
    echo -e "${YELLOW}[!] No GITHUB_TOKEN — using unauthenticated API (60 req/hour). Export GITHUB_TOKEN for full mining.${NC}"
fi

# --- 1. Commit-email mining from public org repos ---
EMAILS_FILE="$OUTPUT_DIR/commit_emails.txt"
: > "$EMAILS_FILE"
echo -e "${YELLOW}[*] Listing public repos for org '$ORG_GITHUB'...${NC}"
REPOS=$(curl -sk --max-time 20 "${GH_ARGS[@]}" \
    "https://api.github.com/orgs/$ORG_GITHUB/repos?per_page=100" 2>/dev/null \
    | jq -r '.[].full_name' 2>/dev/null)
[ -z "$REPOS" ] && REPOS=$(curl -sk --max-time 20 "${GH_ARGS[@]}" \
    "https://api.github.com/users/$ORG_GITHUB/repos?per_page=100" 2>/dev/null \
    | jq -r '.[].full_name' 2>/dev/null)

REPO_N=$(echo "$REPOS" | wc -l | tr -d ' ')
if [ -n "$REPOS" ] && [ "$REPO_N" -gt 0 ]; then
    echo -e "${GREEN}[+] $REPO_N public repos found. Mining commit author emails...${NC}"
    echo "$REPOS" > "$OUTPUT_DIR/repos.txt"
    while IFS= read -r repo; do
        [ -z "$repo" ] && continue
        curl -sk --max-time 15 "${GH_ARGS[@]}" \
            "https://api.github.com/repos/$repo/commits?per_page=100" 2>/dev/null \
            | jq -r '.[].commit.author.email' 2>/dev/null >> "$EMAILS_FILE"
        sleep 0.2
    done < "$OUTPUT_DIR/repos.txt"
    sort -u "$EMAILS_FILE" -o "$EMAILS_FILE"
    EMAIL_N=$(wc -l < "$EMAILS_FILE" | tr -d ' ')
    echo -e "${GREEN}[+] $EMAIL_N unique committer emails -> $EMAILS_FILE${NC}"
    echo -e "${GRAY}[*] Pivot: feed emails into breach DBs / Hunter.io for pattern discovery; try them as usernames on GitHub/DockerHub/Trello.${NC}"
else
    echo -e "${GRAY}[+] No public repos found for '$ORG_GITHUB'.${NC}"
fi

# --- 2. Dork-list generation (human-in-the-browser leads) ---
DORKS_FILE="$OUTPUT_DIR/dorks.md"
cat > "$DORKS_FILE" << EOF
# OSINT Dork Leads — $TARGET_DOMAIN (generated $(date '+%Y-%m-%d'))

## GitHub (paste into github.com/search)
- org:$ORG_GITHUB filename:.env
- org:$ORG_GITHUB "amazonaws.com"
- org:$ORG_GITHUB "blob.core.windows.net"
- org:$ORG_GITHUB filename:Jenkinsfile
- org:$ORG_GITHUB path:.github/workflows "target-internal"
- "$TARGET_DOMAIN" language:javascript pushed:>2025-01-01
- "$CORE" "API_KEY" OR "SECRET" OR "Authorization"

## Cloud buckets & state files
- site:s3.amazonaws.com "$TARGET_DOMAIN"
- site:storage.googleapis.com "$CORE"
- site:blob.core.windows.net "$CORE"
- inurl:terraform.tfstate "$CORE"

## Public boards & docs
- site:trello.com "$CORE"
- site:atlassian.net "$CORE"
- site:notion.site "$CORE"
- site:postman.com "$CORE"
- site:swagger.io "$CORE"
- site:readme.io "$CORE"

## Wayback waypoints (open in browser)
- https://web.archive.org/web/*/https://$TARGET_DOMAIN/docs/*
- https://web.archive.org/web/*/https://$TARGET_DOMAIN/api/docs/*
- https://web.archive.org/web/*/https://$TARGET_DOMAIN/swagger*
- https://web.archive.org/web/*/https://$TARGET_DOMAIN/developers*

## npm / PyPI internal-name sweep
- https://www.npmjs.com/search?q=%40$CORE
- https://pypi.org/search/?q=$CORE
EOF
echo -e "${GREEN}[+] Dork leads written -> $DORKS_FILE${NC}"

# --- 3. Job-posting keyword reminder ---
echo -e "\n${GRAY}[*] Manual step: scan DevOps/SRE job postings for $TARGET_DOMAIN — named cloud/K8s/CI tools and internal product names${NC}"
echo -e "${GRAY}    feed those into scripts/cloud_asset_hunter.sh seed file (recon/cloud_assets/seed_keywords.txt).${NC}"

echo -e "\n${GREEN}[+] Developer-pivot OSINT complete.${NC}"
echo -e "[!] Everything here is passive lead generation — verify each lead manually before any contact with infrastructure."
