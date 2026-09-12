# 02 — Passive Reconnaissance

## Operational Goal
Map the organization's technological footprint without touching their infrastructure. Establish the outer boundary of the attack surface, learning the organization's **Identity, ASN, and IP habits**.

## Execution Flow

### 1. Multi-Engine Subdomain Aggregation
Run multiple complementary passive sources to cast the widest possible net and eliminate single-tool blind spots.
```bash
# Core Passive Aggregation Engines
subfinder -d target.com -all -silent | anew recon/subs/passive_subs.txt
assetfinder --subs-only target.com | anew recon/subs/passive_subs.txt
findomain -t target.com -q | anew recon/subs/passive_subs.txt
amass enum -passive -d target.com -silent | anew recon/subs/passive_subs.txt
chaos -d target.com -silent | anew recon/subs/passive_subs.txt
```

### 2. Certificate Transparency Logs
Extract subdomains from historical TLS/SSL certificate logs (SANs) to uncover legacy or forgotten infrastructure.
```bash
# Query crt.sh JSON API and clean wildcard records
curl -s "https://crt.sh/?q=%.target.com&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | anew recon/subs/passive_subs.txt
```

### 3. Developer Repositories & Source Leaks
Scrape version control commits, pull requests, and public repositories for internal staging and development subdomains.
```bash
# GitHub Subdomain Enumeration with API Token
github-subdomains -d target.com -t $GITHUB_TOKEN | anew recon/subs/passive_subs.txt
```

### 4. ASN & IP Range to Subdomain Discovery (Reverse DNS)
Identify network boundaries and perform reverse DNS lookups on the target's Autonomous System (ASN) and CIDRs.
```bash
# 1. Discover target ASNs and CIDRs
asnmap -d target.com -silent | tee recon/ips/asn_cidrs.txt

# 2. Reverse DNS lookup across identified IP ranges
cat recon/ips/asn_cidrs.txt | hakrevdns -d | grep -i "target.com" | awk '{print $2}' | anew recon/subs/passive_subs.txt
# Alternatively using dnsx PTR mode
dnsx -ptr -resp-only -l recon/ips/asn_cidrs.txt | grep -i "target.com" | anew recon/subs/passive_subs.txt
```

### 5. Client-Side Passive Mining (Burp JS Miner)
While proxying traffic through Burp Suite during normal application exploration:
- Use **JS Miner** (Burp BApp) to automatically parse `.js` scripts, inline scripts, and source maps for hardcoded subdomains, hidden cloud buckets, and API endpoints.

## Reasoning Checkpoint
*   **Infrastructure Posture:** Are they using cloud-native hosting (AWS/GCP/Cloudflare) or private datacenters/ASNs?
*   **Trust Boundaries:** Have you identified external SaaS integrations or SSO portals (Okta/Ping) that hint at Identity Delegation frameworks?
*   **Naming Conventions:** What patterns emerge? (`*-dev`, `*-stage`, `*-internal`, `app[0-9]`)

## Transition to Mapping
Move to **[03 — Active Mapping](03_active_mapping.md)** to run active DNS brute-forcing, permutation fuzzing, and live service fingerprinting.

