#!/bin/bash
# ==============================================================================
# 🏛️ ArchHunter Target Initialization Engine (Bash port of setup_target.ps1)
# Scaffolds a per-target engagement directory with a clean ArchHunter copy,
# customized TARGET_SESSION.md, recon hierarchy, scope files, and a fresh
# Runtime session_id.
# ==============================================================================

TARGET_NAME="${1:-}"
TARGET_DOMAIN="${2:-}"
PLATFORM="${PLATFORM:-HackerOne}"
BASE_DIR="${BASE_DIR:-/mnt/z/bug_bounty}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${TEMPLATE_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

if [ -z "$TARGET_NAME" ]; then
    cat <<EOF
Usage: ./scripts/setup_target.sh <target_name> [target_domain]

Environment overrides:
  BASE_DIR     Engagement root   (default: /mnt/z/bug_bounty — WSL mapped Z:)
  TEMPLATE_DIR ArchHunter source  (default: the repo containing this script)
  PLATFORM     Program platform   (default: HackerOne)
Example:
  ./scripts/setup_target.sh acme corp
  BASE_DIR=~/bug_bounty ./scripts/setup_target.sh acme acme.com
EOF
    exit 1
fi

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; WHITE='\033[1;37m'; NC='\033[0m'
set -e

# 1. Clean target name & derive domain
TARGET_NAME="${TARGET_NAME%%+([[:space:]])}"
TARGET_NAME="${TARGET_NAME%/}"
TARGET_NAME="${TARGET_NAME%\\}"
if [ -z "$TARGET_DOMAIN" ]; then
    if [[ "$TARGET_NAME" == *.* ]]; then
        TARGET_DOMAIN="$TARGET_NAME"
    else
        TARGET_DOMAIN="${TARGET_NAME}.com"
    fi
fi

echo -e "${CYAN}=================================================================${NC}"
echo -e "${YELLOW} 🏛️ ArchHunter Target Initialization Engine${NC}"
echo -e " ${WHITE}[*] Target Name   : $TARGET_NAME${NC}"
echo -e " ${WHITE}[*] Target Domain : $TARGET_DOMAIN${NC}"
echo -e " ${WHITE}[*] Platform      : $PLATFORM${NC}"
echo -e " ${WHITE}[*] Base Directory: $BASE_DIR${NC}"
echo -e "${CYAN}=================================================================${NC}"

# 2. Check base directory
if [ ! -d "$BASE_DIR" ]; then
    echo -e "${RED}[!] Base directory '$BASE_DIR' does not exist! Verify the drive is mounted (WSL: /mnt/z).${NC}" >&2
    exit 1
fi

# 3. Check template directory
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}[!] Template ArchHunter directory not found at '$TEMPLATE_DIR'.${NC}" >&2
    exit 1
fi

# 4. Create target program directory
TARGET_PROGRAM_DIR="$BASE_DIR/$TARGET_NAME"
if [ ! -d "$TARGET_PROGRAM_DIR" ]; then
    mkdir -p "$TARGET_PROGRAM_DIR"
    echo -e "${GREEN}[+] Created target program directory: $TARGET_PROGRAM_DIR${NC}"
else
    echo -e "${YELLOW}[*] Target program directory already exists: $TARGET_PROGRAM_DIR${NC}"
fi

# 5. Copy ArchHunter into the target program directory (excluding .git, _archive)
TARGET_ARCHHUNTER="$TARGET_PROGRAM_DIR/ArchHunter"
if [ ! -d "$TARGET_ARCHHUNTER" ]; then
    echo -e "${CYAN}[*] Copying ArchHunter template to '$TARGET_ARCHHUNTER'...${NC}"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude '.git' --exclude '_archive' "$TEMPLATE_DIR/" "$TARGET_ARCHHUNTER/"
    else
        # tar-based copy with exclusions (portable, no rsync required)
        mkdir -p "$TARGET_ARCHHUNTER"
        tar -C "$TEMPLATE_DIR" --exclude='./.git' --exclude='./_archive' -cf - . | tar -C "$TARGET_ARCHHUNTER" -xf -
    fi
    echo -e "${GREEN}[+] ArchHunter framework successfully copied!${NC}"
else
    echo -e "${YELLOW}[!] ArchHunter already exists in '$TARGET_ARCHHUNTER', preserving existing files.${NC}"
fi

# 6. Customize TARGET_SESSION.md
SESSION_PATH="$TARGET_ARCHHUNTER/TARGET_SESSION.md"
SESSION_TEMPLATE="$TARGET_ARCHHUNTER/templates/TARGET_SESSION_TEMPLATE.md"
if [ -f "$SESSION_TEMPLATE" ]; then
    TODAY=$(date '+%Y-%m-%d')
    sed -e "s/\[TARGET_NAME\]/$TARGET_NAME/g" \
        -e "s/example\.com/$TARGET_DOMAIN/g" \
        -e "s/YYYY-MM-DD/$TODAY/g" \
        -e "s/HackerOne \/ Intigriti \/ Bugcrowd/$PLATFORM/g" \
        "$SESSION_TEMPLATE" > "$SESSION_PATH"
    echo -e "${GREEN}[+] Initialized and customized: $SESSION_PATH${NC}"
else
    echo -e "${YELLOW}[!] Template '$SESSION_TEMPLATE' not found to create TARGET_SESSION.md${NC}"
fi

# 7. Create standard recon & engagement directories
for d in recon recon/subs recon/urls recon/params recon/fuzz recon/results notes pocs; do
    mkdir -p "$TARGET_ARCHHUNTER/$d"
done
echo -e "${GREEN}[+] Recon hierarchy created (subs, urls, params, fuzz, results, notes, pocs)${NC}"

# 8. Create scope definition files
SCOPE_IN="$TARGET_ARCHHUNTER/recon/scope_in.txt"
SCOPE_OUT="$TARGET_ARCHHUNTER/recon/scope_out.txt"
if [ ! -f "$SCOPE_IN" ]; then
    printf '%s\n*.%s\n' "$TARGET_DOMAIN" "$TARGET_DOMAIN" > "$SCOPE_IN"
    echo -e "${GREEN}[+] Created: $SCOPE_IN${NC}"
fi
if [ ! -f "$SCOPE_OUT" ]; then
    printf '# Add out-of-scope assets here (e.g. blog.%s, third-party services)\n' "$TARGET_DOMAIN" > "$SCOPE_OUT"
    echo -e "${GREEN}[+] Created: $SCOPE_OUT${NC}"
fi

# 9. Seed depth-first hunting artifacts from templates
TPL_DIR="$TARGET_ARCHHUNTER/templates"
declare -A ARTIFACTS=(
    ["STATE_MACHINE_MAP_TEMPLATE.md"]="STATE_MACHINE_MAP.md"
    ["AUTHZ_MATRIX_TEMPLATE.md"]="AUTHZ_MATRIX.md"
    ["CHAINING_WORKSHEET_TEMPLATE.md"]="CHAINING_WORKSHEET.md"
)
for tpl in "${!ARTIFACTS[@]}"; do
    src="$TPL_DIR/$tpl"
    dst="$TARGET_ARCHHUNTER/notes/${ARTIFACTS[$tpl]}"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        sed -e "s/\[TARGET_NAME\]/$TARGET_NAME/g" -e "s/\[DATE\]/$(date '+%Y-%m-%d')/g" "$src" > "$dst"
        echo -e "${GREEN}[+] Seeded: $dst${NC}"
    fi
done

# 10. Update Runtime config session ID
RUNTIME_CONFIG="$TARGET_ARCHHUNTER/Runtime/configs/mvp_config.json"
if [ -f "$RUNTIME_CONFIG" ]; then
    SESSION_ID="session_$(echo "$TARGET_NAME" | tr -c 'a-zA-Z0-9_' '_')_$(date '+%Y%m%d')"
    if command -v jq >/dev/null 2>&1; then
        jq --arg sid "$SESSION_ID" '.session_id = $sid' "$RUNTIME_CONFIG" > "${RUNTIME_CONFIG}.tmp" \
            && mv "${RUNTIME_CONFIG}.tmp" "$RUNTIME_CONFIG" \
            && echo -e "${GREEN}[+] Updated Runtime session_id: $SESSION_ID${NC}"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); d['session_id']=sys.argv[2]; json.dump(d,open(p,'w',encoding='utf-8'),indent=2)" \
            "$RUNTIME_CONFIG" "$SESSION_ID" \
            && echo -e "${GREEN}[+] Updated Runtime session_id: $SESSION_ID${NC}"
    else
        echo -e "${YELLOW}[!] jq/python3 not found — could not update Runtime config session_id${NC}"
    fi
fi

echo -e "\n${CYAN}=================================================================${NC}"
echo -e "${GREEN} 🎯 TARGET READY FOR HUNTING!${NC}"
echo -e " ${WHITE}Target Path       : $TARGET_ARCHHUNTER${NC}"
echo -e " ${WHITE}Active Session    : $SESSION_PATH${NC}"
echo -e " ${WHITE}In-Scope Domains  : $SCOPE_IN${NC}"
echo -e "${CYAN}=================================================================${NC}"
