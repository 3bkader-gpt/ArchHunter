#!/bin/bash
# ==============================================================================
# ☁️ Forgotten Cloud Asset Hunter (Workflow/12 Phase 1)
# Generates bucket/container permutations from org+domain seeds, probes S3/GCS/
# Azure for existence, mines existing DNS output for cloud CNAMEs, and greps
# CT history for cloud-native domains. Passive/semi-passive — scope first.
# ==============================================================================

TARGET_DOMAIN="${1:-}"
ORG_NAME="${2:-${TARGET_DOMAIN%%.*}}"
SUBS_FILE="${3:-}"
OUTPUT_DIR="${4:-recon/cloud_assets}"

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/cloud_asset_hunter.sh <domain> [org_name] [subdomains_file] [output_dir]"
    echo "  org_name        seed for permutations (default: domain root label)"
    echo "  subdomains_file resolved-subdomain list (dnsx/subfinder output) for CNAME mining"
    echo "Example:"
    echo "  ./scripts/cloud_asset_hunter.sh acme.com acme recon/timetravel/ct_hosts.txt"
    exit 1
fi

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] Forgotten Cloud Asset Hunter: $TARGET_DOMAIN${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
PERMS_FILE="$OUTPUT_DIR/permutations.txt"
HITS_FILE="$OUTPUT_DIR/existing_assets.txt"
: > "$HITS_FILE"

# --- 1. Permutation generation (domain + org + env + product keywords) ---
CORE="${TARGET_DOMAIN%%.*}"
CORE_NODASH=$(echo "$CORE" | tr -d '-')
ENV_WORDS=("" "dev" "stg" "staging" "uat" "preprod" "test" "qa" "prod" "backup" "old" "legacy" "assets" "static" "media" "uploads" "logs" "archive" "internal" "tmp")
# Optional extra product/brand keywords (one per line) from recon/job postings:
# this file PERSISTS across runs — confirmed bucket names get appended by the
# pattern-feedback loop below, so each re-run seeds smarter.
SEEDS_FILE="$OUTPUT_DIR/seed_keywords.txt"
[ -f "$SEEDS_FILE" ] || : > "$SEEDS_FILE"

SEEDS=("$CORE" "$CORE_NODASH" "$ORG_NAME" "$(echo "$ORG_NAME" | tr -d '-')")
[ -f "$SEEDS_FILE" ] && while IFS= read -r kw; do
    [ -n "$kw" ] && SEEDS+=("$kw")
done < "$SEEDS_FILE"

: > "$PERMS_FILE"
for seed in $(printf '%s\n' "${SEEDS[@]}" | sort -u); do
    for env in "${ENV_WORDS[@]}"; do
        [ -z "$env" ] && echo "$seed" >> "$PERMS_FILE" && continue
        echo "${seed}-${env}"     >> "$PERMS_FILE"
        echo "${env}-${seed}"     >> "$PERMS_FILE"
    done
done
sort -u "$PERMS_FILE" -o "$PERMS_FILE"
PERM_COUNT=$(wc -l < "$PERMS_FILE" | tr -d ' ')
echo -e "${GREEN}[+] Generated $PERM_COUNT permutations -> $PERMS_FILE${NC}"
echo -e "${GRAY}[*] Tip: append product/brand keywords (JS, job postings) to $SEEDS_FILE and re-run for smarter seeds.${NC}"

# --- 2. Bucket existence & response intelligence ---
# S3: 404 NoSuchBucket vs 403 AccessDenied (exists, private) — 403 body/headers
# leak region (x-amz-bucket-region) and policy type (bucket vs object ACL).
# Azure: 404 ContainerNotFound vs 400/409 (exists)   |  GCS: 404 NoSuchBucket vs 403
FOUND_NAMES=""
probe() { # provider url_pattern name
    local provider="$1" pattern="$2" name="$3" url
    url=$(printf "$pattern" "$name")
    local out
    out=$(curl -sk --max-time 8 -D - -o - -w "\n%{http_code}" "$url" 2>/dev/null) || return
    local status="${out##*$'\n'}"
    local meta_body="${out%$'\n'*}"
    local body="${meta_body##*$'\r\n\r\n'}"
    local headers="${meta_body%$'\r\n\r\n'*}"
    case "$provider:$status" in
        s3:200|s3:403)
            local region errtype
            region=$(echo "$headers" | grep -ai "x-amz-bucket-region" | head -1 | sed 's/.*: *//' | tr -d '\r')
            errtype=$(echo "$body" | grep -aoE "<Code>[^<]+</Code>" | head -1 | sed 's/<[^>]*>//g')
            echo -e "${RED}[EXISTS] $url ($status${region:+, region: $region}${errtype:+, $errtype})${NC}"
            echo "$url${region:+	region=$region}${errtype:+	err=$errtype}" >> "$HITS_FILE"
            FOUND_NAMES="$FOUND_NAMES $name"
            # IAM policy differential: AccessDenied = bucket policy blocks listing;
            # other codes may mean object-level ACLs differ from bucket-level (readable objects inside).
            [ "$errtype" = "AccessDenied" ] && echo -e "${GRAY}    -> bucket-policy denial; test object paths directly (objects may be readable even when listing is denied)${NC}" ;;
        azure:200|azure:409|azure:400)
            echo -e "${RED}[EXISTS] $url ($status)${NC}"; echo "$url" >> "$HITS_FILE"; FOUND_NAMES="$FOUND_NAMES $name" ;;
        gcs:200|gcs:403)
            echo -e "${RED}[EXISTS] $url ($status)${NC}"; echo "$url" >> "$HITS_FILE"; FOUND_NAMES="$FOUND_NAMES $name" ;;
        *) : ;;
    esac
}

echo -e "\n${YELLOW}[*] Probing $PERM_COUNT permutations across S3 / Azure / GCS...${NC}"
while IFS= read -r name; do
    probe s3   "https://%s.s3.amazonaws.com/"                    "$name"
    probe azure "https://%s.blob.core.windows.net/assets/"       "$name"
    probe gcs  "https://storage.googleapis.com/%s/"              "$name"
done < "$PERMS_FILE"
HITS=$(wc -l < "$HITS_FILE" | tr -d ' ')
[ "$HITS" = "0" ] && echo -e "${GRAY}[+] No confirmed bucket hits.${NC}"

# --- 2b. Cross-cloud naming correlation + pattern feedback loop ---
# Naming conventions survive migrations: retest every S3 hit's name against
# Azure/GCS, and feed confirmed names back as new permutation seeds.
if [ -n "$(echo "$FOUND_NAMES" | tr -d ' ')" ]; then
    echo -e "\n${YELLOW}[*] Cross-cloud correlation of confirmed names...${NC}"
    for name in $(echo "$FOUND_NAMES" | tr ' ' '\n' | sort -u); do
        [ -z "$name" ] && continue
        probe azure "https://%s.blob.core.windows.net/assets/" "$name"
        probe gcs  "https://storage.googleapis.com/%s/"        "$name"
    done
    echo -e "${GRAY}[*] Seed feedback: confirmed names appended to $SEEDS_FILE (re-run for env/region/function expansion).${NC}"
    echo "$FOUND_NAMES" | tr ' ' '\n' | grep -v '^$' | sort -u >> "$SEEDS_FILE"
fi

# --- 3. DNS-based cloud discovery from existing recon output ---
if [ -n "$SUBS_FILE" ] && [ -f "$SUBS_FILE" ]; then
    echo -e "\n${YELLOW}[*] Mining CNAMEs in $SUBS_FILE for cloud hosting...${NC}"
    CLOUD_RE='(s3\.amazonaws\.com|blob\.core\.windows\.net|storage\.googleapis\.com|azurewebsites\.net|cloudfront\.net|elb\.amazonaws\.com|appspot\.com|herokuapp\.com|azureedge\.net|firebaseio\.com)'
    while IFS= read -r host; do
        [ -z "$host" ] && continue
        cname=$(dig +short CNAME "$host" 2>/dev/null | head -1)
        [ -z "$cname" ] && continue
        if echo "$cname" | grep -aqE "$CLOUD_RE"; then
            echo -e "${RED}[CLOUD CNAME] $host -> $cname${NC}"
            echo "$host -> $cname" >> "$HITS_FILE"
        fi
    done < "$SUBS_FILE"
fi

# --- 4. CT history grep for cloud-native domains ---
echo -e "\n${YELLOW}[*] Grepping crt.sh for cloud-native domains...${NC}"
curl -sk --max-time 30 "https://crt.sh/?q=%25.${TARGET_DOMAIN}&output=json" \
    | jq -r '.[].name_value' 2>/dev/null | tr 'A-Z' 'a-z' | sort -u \
    | grep -E "$CLOUD_RE" > "$OUTPUT_DIR/ct_cloud_domains.txt" 2>/dev/null
CT_CLOUD=$(wc -l < "$OUTPUT_DIR/ct_cloud_domains.txt" | tr -d ' ')
[ "$CT_CLOUD" -gt 0 ] && echo -e "${RED}[!] $CT_CLOUD cloud-native domains in CT history -> $OUTPUT_DIR/ct_cloud_domains.txt${NC}" \
    || echo -e "${GRAY}[+] No cloud-native domains in CT history.${NC}"

echo -e "\n${GREEN}[+] Cloud asset hunt complete. Existing/orphaned assets: $HITS_FILE${NC}"
echo -e "[!] Next: verify ownership & permissions on hits (public listing? write access?) — report only what is demonstrably the target's."
