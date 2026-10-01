#!/bin/bash
# ==============================================================================
# 🕵️ Origin IP Uncloaker (Workflow/12 Phase 7 + origin_ip_discovery skill)
# SPF/DMARC infrastructure mining, non-proxied subdomain classes, CT SAN dump,
# and error-based origin leaks. Complements find_origin_ip.sh (favicon hash).
# ==============================================================================

TARGET_DOMAIN="${1:-}"
OUTPUT_DIR="${2:-recon/origin_uncloak}"

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/origin_ip_uncloak.sh <domain> [output_dir]"
    echo "Example: ./scripts/origin_ip_uncloak.sh target.com"
    exit 1
fi

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; NC='\033[0m'
echo -e "\n${CYAN}[+] ==========================================${NC}"
echo -e "${CYAN}[+] Origin IP Uncloaker: $TARGET_DOMAIN${NC}"
echo -e "${CYAN}[+] ==========================================${NC}\n"

mkdir -p "$OUTPUT_DIR"
CANDIDATES="$OUTPUT_DIR/origin_candidates.txt"
: > "$CANDIDATES"

dns_txt() { dig +short TXT "$1" 2>/dev/null || nslookup -type=TXT "$1" 2>/dev/null | grep -i "text\|spf"; }

# --- 1. SPF / DMARC / MX infrastructure mining ---
echo -e "${YELLOW}[*] Mining SPF/DMARC/MX for outbound infrastructure...${NC}"
SPF_RECORDS=$(dns_txt "$TARGET_DOMAIN" | grep -ai "v=spf1")
echo "$SPF_RECORDS" > "$OUTPUT_DIR/spf_records.txt"
echo "$SPF_RECORDS" | grep -aoE "include:[a-z0-9._-]+|ip4:[0-9a-fA-F.:/]+|ip6:[0-9a-fA-F:/:]+" \
    | sort -u > "$OUTPUT_DIR/spf_mechanisms.txt"
SPF_N=$(wc -l < "$OUTPUT_DIR/spf_mechanisms.txt" | tr -d ' ')
if [ "$SPF_N" -gt 0 ]; then
    echo -e "${GREEN}[+] $SPF_N SPF mechanisms (include:/ip4:/ip6:) -> $OUTPUT_DIR/spf_mechanisms.txt${NC}"
    while IFS= read -r mech; do
        case "$mech" in
            include:*)
                inc_domain="${mech#include:}"
                echo -e "${GRAY}[*] Resolving include: $inc_domain${NC}"
                dig +short A "$inc_domain" 2>/dev/null | grep -E '^[0-9]+\.' >> "$CANDIDATES" ;;
            ip4:*|ip6:*)
                echo "${mech#*:}" >> "$CANDIDATES" ;;
        esac
    done < "$OUTPUT_DIR/spf_mechanisms.txt"
else
    echo -e "${GRAY}[+] No SPF record surfaced.${NC}"
fi
dig +short MX "$TARGET_DOMAIN" 2>/dev/null > "$OUTPUT_DIR/mx_records.txt"
MX_N=$(wc -l < "$OUTPUT_DIR/mx_records.txt" | tr -d ' ')
[ "$MX_N" -gt 0 ] && echo -e "${GREEN}[+] $MX_N MX records -> $OUTPUT_DIR/mx_records.txt (resolve the mail hosts for non-proxied IPs)${NC}"

# --- 2. Non-proxied subdomain classes ---
echo -e "\n${YELLOW}[*] Sweeping non-proxied subdomain classes...${NC}"
EXCLUDE_CLASSES=(mail smtp mx direct origin backend api-internal webmail ftp cpanel vpn)
for cls in "${EXCLUDE_CLASSES[@]}"; do
    host="${cls}.${TARGET_DOMAIN}"
    ip=$(dig +short A "$host" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
    [ -z "$ip" ] && continue
    echo -e "${GREEN}[RESOLVES] $host -> $ip (class: $cls — often not behind CDN)${NC}"
    echo "$host $ip" >> "$CANDIDATES"
done

# --- 3. CT SAN dump (cert pivoting source list) ---
echo -e "\n${YELLOW}[*] Pulling crt.sh SAN history for cert pivoting...${NC}"
curl -sk --max-time 30 "https://crt.sh/?q=%25.${TARGET_DOMAIN}&output=json" \
    | jq -r '.[] | [.common_name, .issuer_name, .not_before] | @tsv' 2>/dev/null | sort -u \
    > "$OUTPUT_DIR/ct_cert_history.tsv"
CT_N=$(wc -l < "$OUTPUT_DIR/ct_cert_history.tsv" | tr -d ' ')
echo -e "${GREEN}[+] $CT_N cert records -> $OUTPUT_DIR/ct_cert_history.tsv${NC}"
echo -e "${GRAY}[*] Next: search Censys/Shodan for hosts still serving certs with the target's exact CN/SAN on :443.${NC}"

# --- 4. Error-based origin leaks ---
echo -e "\n${YELLOW}[*] Probing for error-based origin leaks...${NC}"
LEAK_OUT="$OUTPUT_DIR/error_leaks.txt"
: > "$LEAK_OUT"
for host in "$TARGET_DOMAIN" "www.$TARGET_DOMAIN"; do
    # Malformed Host header — some origins echo internal host/IP in error pages
    resp=$(curl -sk --max-time 8 -H "Host: $(printf 'x%.0s' {1..60}).invalid" \
        -o - -D - "https://$host/" 2>/dev/null) || continue
    echo "$resp" | grep -aoiE "([a-z0-9-]+\.(internal|local|corp|target\.com))|([0-9]{1,3}\.){3}[0-9]{1,3}" \
        | sort -u | while IFS= read -r leak; do
            echo -e "${RED}[LEAK] $host: $leak${NC}"
            echo "$host: $leak" >> "$LEAK_OUT"
        done
done
LEAKS=$(wc -l < "$LEAK_OUT" | tr -d ' ')
[ "$LEAKS" = "0" ] && echo -e "${GRAY}[+] No error-based leaks observed.${NC}"

TOTAL=$(wc -l < "$CANDIDATES" | tr -d ' ')
echo -e "\n${GREEN}[+] Origin uncloaking pass complete. Candidate IPs/hosts: $TOTAL -> $CANDIDATES${NC}"
echo -e "[!] Next: for each candidate, curl -k -H 'Host: $TARGET_DOMAIN' https://<IP>/ and diff content vs the CDN response (Workflow/12 Phase 5)."
