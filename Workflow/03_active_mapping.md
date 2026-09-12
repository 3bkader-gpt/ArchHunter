# 03 — Active Enumeration & Asset Discovery

## Operational Goal
Filter the passive footprint down to alive hosts, discover unindexed internal infrastructure via active DNS brute-forcing, smart permutation fuzzing, and uncover hidden Virtual Hosts (VHosts).

## Execution Flow

### 1. Trusted Resolvers Management
To avoid DNS rate-limiting, poisoned caches, and dropped queries during active brute-forcing, maintain a curated list of reliable public resolvers.
```bash
# Fetch fresh, verified public resolvers
curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -o recon/resolvers.txt
```

### 2. High-Speed DNS Resolution & Wildcard Filtering
Resolve the passive subdomain list while discarding DNS wildcards and dead records.
```bash
# Resolving passive records with dnsx
cat recon/subs/passive_subs.txt | dnsx -r recon/resolvers.txt -silent -a -cname -resp | anew recon/subs/resolved_subs.txt
```

### 3. Active DNS Wordlist Brute-Forcing (The Missing Layer)
Uncover hidden subdomains that never appeared in certificate logs or search engines.
```bash
# High-speed wildcard-aware DNS brute forcing with puredns
puredns bruteforce /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt target.com \
    -r recon/resolvers.txt \
    --write recon/subs/bruteforce_subs.txt

# Merge and deduplicate
cat recon/subs/bruteforce_subs.txt | anew recon/subs/resolved_subs.txt
```

### 4. Smart Permutations & Mutation Fuzzing (Dashes & Numbers)
Attackers find critical staging environments because developers frequently use **dashes (`-`) and numbers** instead of plain dot subdomains (`dev-api`, `app1`, `admin-v2`, `pr-104`).
```bash
# Subdomain Permutation Fuzzing via ffuf:
# A. Prefix / Dash mutations (e.g. dev-FUZZ.target.com or FUZZ-api.target.com)
ffuf -u "https://FUZZ-api.target.com" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -mc 200,301,302,401,403 -silent

# B. Numbered and Environment Sequence Fuzzing (app1, app2, dev01, dev02)
# Fuzzing sequential environments:
ffuf -u "https://appFUZZ.target.com" -w <(seq 1 20) -mc 200,301,302,401,403 -silent
```

### 5. Virtual Host (VHost) Fuzzing & Private Enumeration
Discover internal web applications hosted on the same origin IP but routed solely by the HTTP `Host` header.

```bash
# 1. Baseline the origin IP response size to filter default wildcard vhost responses
curl -s -k -I https://TARGET_IP | grep -i "Content-Length"

# 2. Fuzz Host header with size/word filtering (-fs <default_size> to kill false positives)
ffuf -u 'https://TARGET_IP' \
     -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
     -H 'Host: FUZZ.target.com' \
     -mc 200,301,302,401,403 \
     -fs DEFAULT_RESPONSE_SIZE \
     -o recon/vhosts.json

# 3. Manual verification in /etc/hosts:
# Add: <TARGET_IP> <DISCOVERED_VHOST>.target.com
# Then browse directly in Burp Suite or browser.
```

### 6. TLS Certificate SAN Harvesting & Infrastructure Expansion
Extract Subject Alternative Names (SANs) and organizational metadata from TLS certificates across resolved assets to identify obscure infrastructure:
```bash
# Extract SANs and reverse TLS hostnames
cat recon/subs/resolved_subs.txt | tlsx -san -cn -silent -resp-only | anew recon/subs/resolved_subs.txt
```

### 7. Network-Level CIDR Expansion & Fast Port Discovery (MapCIDR + Naabu)
When assigned broad netblocks or discovering dedicated ASN IP blocks, transform CIDR ranges into distinct host targets and perform ultra-fast port scanning:
```bash
# Expand target CIDR ranges into individual IPs
echo "192.168.1.0/24" | mapcidr -silent | anew recon/ips/target_ips.txt

# Ultra-fast SYN port scanning on exposed hosts/IPs across top 1000 ports
naabu -list recon/ips/target_ips.txt -top-ports 1000 -rate 1500 -silent -o recon/ips/open_ports.txt
```

### 8. Liveness, Port Probing & Status Code Triaging (httpx)
Probe all resolved hosts and discovered ports across standard and non-standard web ports, capturing rich metadata for the reasoning runtime:
```bash
cat recon/subs/resolved_subs.txt recon/ips/open_ports.txt | httpx \
    -ports 80,443,8080,8443,3000,8081,9000,5000,50051 \
    -sc -title -web-server -tech-detect -follow-redirects \
    -json -o recon/signals.jsonl

# Generate clean human-readable alive hosts
cat recon/signals.jsonl | jq -r '.url' | sort -u > recon/subs/alive_hosts.txt
```

### 9. Dangling CNAME & Subdomain Takeover Sweep
Audit all resolved subdomains for unclaimed cloud resources (AWS S3, GitHub Pages, Heroku, Azure, Shopify, Fastly):
```bash
./scripts/check_subdomain_takeover.sh target.com recon/subs/resolved_subs.txt
```
*   *Skill Reference:* **[skills/infrastructure/subdomain_takeover.md](../skills/infrastructure/subdomain_takeover.md)**

## Reasoning Checkpoint
*   **Status Code Strategy:**
    *   `200 OK`: Primary interactive application surface.
    *   `401 / 403`: Access-restricted portals (Candidates for Origin IP Bypass or [Logic & Auth Bypass](../skills/auth_logic/auth_bypass_ato.md)).
    *   `404 Not Found`: Targets for [Wayback Historical Archaeology](../Workflow/05_attack_surface_expansion.md).
    *   `500 Error`: Unhandled backend routing, candidates for [Parser Differential Abuse](../skills/infrastructure/parser_differential_abuse.md).
*   **Takeover Verification:** Did `subzy` or `dnsx` identify dangling CNAMEs? Claim immediately to demonstrate PoC without hosting malicious content.

## Transition to Architecture
Proceed to **[04 — Fingerprint to Architecture](04_fingerprint_to_architecture.md)** to transform these raw endpoints into a logical trust-boundary map.


