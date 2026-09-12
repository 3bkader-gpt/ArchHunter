#!/bin/bash
# ==============================================================================
# 🎯 Target-Tailored Backup & Sensitive File Fuzzer
# Generates contextual backup filenames and validates exposure with httpx
# ==============================================================================

set -e

TARGET_DOMAIN=$1
ALIVE_HOSTS_FILE=${2:-"recon/$TARGET_DOMAIN/subs/alive_hosts.txt"}

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/fuzz_sensitive_backups.sh <target_domain> [alive_hosts_file]"
    echo "Example: ./scripts/fuzz_sensitive_backups.sh target.com"
    exit 1
fi

RECON_DIR="recon/$TARGET_DOMAIN"
LOOT_DIR="$RECON_DIR/loot"
mkdir -p "$LOOT_DIR"

WORDLIST_FILE="$LOOT_DIR/tailored_backup_wordlist.txt"
HITS_FILE="$LOOT_DIR/sensitive_file_hits.txt"

echo -e "\e[1;32m[+] Generating tailored backup dictionary for: $TARGET_DOMAIN\e[0m"

# Extract domain root & name
DOMAIN_NAME=$(echo "$TARGET_DOMAIN" | cut -d'.' -f1)
YEAR=$(date +%Y)
PREV_YEAR=$((YEAR-1))

cat <<EOF > "$WORDLIST_FILE"
.env
.env.local
.env.production
.env.backup
.git/HEAD
.git/config
.gitignore
docker-compose.yml
Dockerfile
server.js.bak
app.py.bak
config.json.bak
web.config
wp-config.php.bak
database.sql
db.sql
dump.sql
backup.sql
${DOMAIN_NAME}.sql
${DOMAIN_NAME}.zip
${DOMAIN_NAME}.tar.gz
${DOMAIN_NAME}.bak
${TARGET_DOMAIN}.zip
${TARGET_DOMAIN}.tar.gz
${TARGET_DOMAIN}.sql
${TARGET_DOMAIN}.bak
backup-${YEAR}.zip
backup-${PREV_YEAR}.zip
${DOMAIN_NAME}-${YEAR}.zip
${DOMAIN_NAME}-${PREV_YEAR}.zip
site-backup.zip
EOF

echo -e "\e[1;34m[*] Generated $(wc -l < "$WORDLIST_FILE") targeted backup patterns\e[0m"

# Determine URLs to test
if [ -f "$ALIVE_HOSTS_FILE" ]; then
    TARGET_URLS="$ALIVE_HOSTS_FILE"
else
    TARGET_URLS="$LOOT_DIR/single_target.txt"
    echo "https://${TARGET_DOMAIN}" > "$TARGET_URLS"
fi

echo -e "\e[1;34m[*] Fuzzing alive endpoints for exposed files...\e[0m"

cat "$TARGET_URLS" | while read -r host; do
    while read -r path; do
        echo "${host%/}/${path#/}"
    done < "$WORDLIST_FILE"
done | httpx -mc 200 -status-code -content-length -content-type -silent -o "$HITS_FILE"

HIT_COUNT=$(wc -l < "$HITS_FILE" || echo 0)
if [ "$HIT_COUNT" -gt 0 ]; then
    echo -e "\e[1;32m[🎯 EXPOSED FILES FOUND! ($HIT_COUNT hits)]\e[0m"
    cat "$HITS_FILE"
else
    echo "[-] No sensitive backup files exposed on examined hosts."
fi

echo -e "\e[1;33m[!] Results saved at: $HITS_FILE\e[0m"
