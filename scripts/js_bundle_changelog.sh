#!/bin/bash
# ==============================================================================
# 📜 JS Bundle Changelog — Historical Diff of the Internal API Surface
# (Workflow/12 Phase 4). Queries Wayback for snapshots of the target's JS
# bundles, extracts endpoint-ish strings from old vs current builds, and diffs
# them: endpoints added/removed between releases = a changelog of internal API
# surface that current scanners only see a snapshot of.
# ==============================================================================

TARGET_DOMAIN="${1:-}"
OUTPUT_DIR="${2:-recon/js_changelog}"

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/js_bundle_changelog.sh <domain> [output_dir]"
    echo "Example: ./scripts/js_bundle_changelog.sh target.com"
    echo "Passive only — reads Wayback Machine snapshots."
    exit 1
fi

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] JS Bundle Changelog: $TARGET_DOMAIN${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"

ENDPOINT_RE='(/api/[a-zA-Z0-9_./-]*|/internal[a-zA-Z0-9_./-]*|/admin[a-zA-Z0-9_./-]*|/v[0-9]+/[a-zA-Z0-9_./-]*)'

extract_endpoints() { # stdin: JS content -> stdout: sorted unique endpoint strings
    grep -aoE "$ENDPOINT_RE" 2>/dev/null | sort -u
}

# --- 1. Discover JS bundle paths from Wayback CDX (with retry — CDX rate-limits aggressively) ---
echo -e "${YELLOW}[*] Listing archived JS bundles in Wayback CDX...${NC}"
fetch_cdx() {
    curl -sk --max-time 30 \
        "http://web.archive.org/cdx/search/cdx?url=*.${TARGET_DOMAIN}/*&output=text&collapse=urlkey&limit=5000&fl=original,timestamp&filter=original:.*\.js" \
        2>/dev/null | sort -u > "$OUTPUT_DIR/cdx_js_snapshots.raw.txt"
    grep -aE '\.js(\?|$)' "$OUTPUT_DIR/cdx_js_snapshots.raw.txt" 2>/dev/null \
        | grep -avE '\.jsp|\.json|\.js\.map' > "$OUTPUT_DIR/cdx_js_snapshots.txt" || true
}
fetch_cdx
if [ ! -s "$OUTPUT_DIR/cdx_js_snapshots.txt" ]; then
    echo -e "${YELLOW}[*] Empty CDX response — Wayback rate-limits aggressively; retrying once after 15s...${NC}"
    sleep 15
    fetch_cdx
fi

SNAP_N=$(wc -l < "$OUTPUT_DIR/cdx_js_snapshots.txt" | tr -d ' ')
if [ "$SNAP_N" = "0" ]; then
    echo -e "${RED}[-] No JS snapshots returned for $TARGET_DOMAIN (CDX may be rate-limiting or the domain has no archived JS).${NC}"
    echo -e "${GRAY}    Retry later, or seed bundles manually into $OUTPUT_DIR/bundles.txt (one URL per line) and re-run.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] $SNAP_N JS snapshot records -> $OUTPUT_DIR/cdx_js_snapshots.txt${NC}"

# --- 2. Pick the most-snapshotted bundle paths (highest intelligence density) ---
# Keep original URL only (drop timestamp column), dedupe, take top N by repetition
echo -e "${YELLOW}[*] Selecting top bundles by snapshot count...${NC}"
cut -d' ' -f1 "$OUTPUT_DIR/cdx_js_snapshots.txt" | sort | uniq -c | sort -rn \
    | awk '$1 >= 2 {print $2}' | head -10 > "$OUTPUT_DIR/bundles.txt"
BUNDLE_N=$(wc -l < "$OUTPUT_DIR/bundles.txt" | tr -d ' ')
[ "$BUNDLE_N" = "0" ] && cut -d' ' -f1 "$OUTPUT_DIR/cdx_js_snapshots.txt" | sort -u | head -5 > "$OUTPUT_DIR/bundles.txt"
BUNDLE_N=$(wc -l < "$OUTPUT_DIR/bundles.txt" | tr -d ' ')
echo -e "${GREEN}[+] $BUNDLE_N bundle path(s) selected -> $OUTPUT_DIR/bundles.txt${NC}"

# --- 3. Fetch earliest + latest snapshot per bundle and diff endpoints ---
FINAL_REPORT="$OUTPUT_DIR/changelog_report.txt"
: > "$FINAL_REPORT"

while IFS= read -r bundle_url; do
    [ -z "$bundle_url" ] && continue
    echo -e "\n${CYAN}[*] Bundle: $bundle_url${NC}"

    TS_LIST=$(curl -sk --max-time 15 "http://archive.org/wayback/available?url=$(echo "$bundle_url" | sed 's|https*://||')&timestamp=1999" 2>/dev/null \
        | jq -r '.archived_snapshots.closest.url // empty' 2>/dev/null)
    [ -z "$TS_LIST" ] && { echo -e "${GRAY}  [-] No snapshots resolvable, skipping.${NC}"; continue; }

    # Earliest and latest via CDX timestamps for this exact URL
    OLD_TS=$(grep -F "$bundle_url" "$OUTPUT_DIR/cdx_js_snapshots.txt" | awk '{print $2}' | sort | head -1)
    NEW_TS=$(grep -F "$bundle_url" "$OUTPUT_DIR/cdx_js_snapshots.txt" | awk '{print $2}' | sort | tail -1)
    [ -z "$OLD_TS" ] || [ "$OLD_TS" = "$NEW_TS" ] && { echo -e "${GRAY}  [-] Only one era snapshot — no diff possible.${NC}"; continue; }

    OLD_URL="http://web.archive.org/web/${OLD_TS}id_/${bundle_url}"
    NEW_URL="http://web.archive.org/web/${NEW_TS}id_/${bundle_url}"
    echo -e "${GRAY}  [*] old: $OLD_TS  new: $NEW_TS${NC}"

    curl -skL --max-time 30 "$OLD_URL" 2>/dev/null | extract_endpoints > "$OUTPUT_DIR/bundle_old.txt"
    curl -skL --max-time 30 "$NEW_URL" 2>/dev/null | extract_endpoints > "$OUTPUT_DIR/bundle_new.txt"

    ADDED=$(comm -13 "$OUTPUT_DIR/bundle_old.txt" "$OUTPUT_DIR/bundle_new.txt" | grep -v '^$' | wc -l | tr -d ' ')
    REMOVED=$(comm -23 "$OUTPUT_DIR/bundle_old.txt" "$OUTPUT_DIR/bundle_new.txt" | grep -v '^$' | wc -l | tr -d ' ')
    echo -e "  ${YELLOW}[+] Endpoints added in newer build: $ADDED | removed: $REMOVED${NC}"

    {
        echo "### $bundle_url"
        echo "# old snapshot: $OLD_TS | new snapshot: $NEW_TS"
        echo "# --- REMOVED in newer build (retired endpoints — often still routed): ---"
        comm -23 "$OUTPUT_DIR/bundle_old.txt" "$OUTPUT_DIR/bundle_new.txt" | grep -v '^$' || true
        echo "# --- ADDED in newer build (new surface since the old era): ---"
        comm -13 "$OUTPUT_DIR/bundle_old.txt" "$OUTPUT_DIR/bundle_new.txt" | grep -v '^$' || true
        echo ""
    } >> "$FINAL_REPORT"
done < "$OUTPUT_DIR/bundles.txt"

echo -e "\n${GREEN}[+] JS changelog complete -> $FINAL_REPORT${NC}"
echo -e "[!] Next: probe RETIRED endpoints live (they are frequently still routed but unmonitored) — pair with shadow_api_probe.sh."
