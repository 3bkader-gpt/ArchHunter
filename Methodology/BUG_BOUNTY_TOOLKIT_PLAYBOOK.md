# Bug Bounty Toolkit: The Unified Offensive Tooling Playbook

> **Authoritative reference for CLI automation, pipe chaining, parameter archaeology, and high-yield reconnaissance.**  
> Derived directly from the curated methodologies of **Bug Bounty Toolkit**, tailored for modern enterprise and SaaS bug bounty targets.

---

## 1. Operational Philosophy: The Chained Unix Pipe Model

Running scanners in isolation yields high noise, duplicate findings, and wasted bandwidth. The elite bug hunter's edge lies in **streaming data pipes** where each specialized tool performs a single mathematical or network operation at wire speed:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  subfinder   │ ──> │     tlsx     │ ──> │     dnsx     │ ──> │    httpx     │
│ (Passive DNS)│     │(SAN Discovery│     │(Resolver/Wild│     │(Fingerprint) │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                                                                      │
┌──────────────┐     ┌──────────────┐     ┌──────────────┐            ▼
│    dalfox    │ <── │     kxss     │ <── │  qsreplace   │ <── ┌──────────────┐
│  (Injection) │     │ (Reflection) │     │ (Seed Tokens)│     │ gau / katana │
└──────────────┘     └──────────────┘     └──────────────┘     │(Crawling/Arc)│
                                                               └──────────────┘
```

---

## 2. Core Tooling Encyclopedia & Flag Matrix

### 1. `anew` (Streaming Deduplication)
*   **Purpose:** Appends only unique lines from standard input to a target file. Essential for continuous background recon pipelines without re-parsing old data.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat fresh_subdomains.txt | anew recon/subs/all_subs.txt
    ```

### 2. `uro` (URL Normalization & Decluttering)
*   **Purpose:** Strips static media files (`.png`, `.jpg`, `.woff`, `.css`), deduplicates identical path structures with varying query parameters, and reduces 100,000 messy archive URLs to a lean, testable surface of ~2,000 endpoints.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat recon/urls/raw_archive.txt | uro -o recon/urls/clean_urls.txt
    ```

### 3. `gf` (Vulnerability Pattern Slicing)
*   **Purpose:** Applies regex patterns against normalized URLs to categorize endpoints into attack surfaces: XSS, SSRF, IDOR, SQLi, LFI, Open Redirect.
*   **Integrated Patterns (`payloads/gf_patterns/`):**
    ```bash
    cat clean_urls.txt | gf xss   | anew recon/params/xss_candidates.txt
    cat clean_urls.txt | gf ssrf  | anew recon/params/ssrf_candidates.txt
    cat clean_urls.txt | gf idor  | anew recon/params/idor_candidates.txt
    cat clean_urls.txt | gf sqli  | anew recon/params/sqli_candidates.txt
    cat clean_urls.txt | gf lfi   | anew recon/params/lfi_candidates.txt
    ```

### 4. `qsreplace` (Wire-Speed Parameter Replacement)
*   **Purpose:** Replaces all query parameter values across thousands of URLs simultaneously with a single canary or test token.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    # Seeding Canary for XSS
    cat recon/params/xss_candidates.txt | qsreplace 'kXss73<"'\`>' | anew recon/params/seeded_xss.txt

    # Seeding Canary for SSRF
    cat recon/params/ssrf_candidates.txt | qsreplace 'http://169.254.169.254/latest/meta-data/' | anew recon/params/seeded_ssrf.txt
    ```

### 5. `kxss` (Contextual Reflection Analyzer)
*   **Purpose:** Takes URLs with seeded characters (`<`, `>`, `"`, `'`, `` ` ``) and probes the target, reporting not just whether the string reflected, but *which dangerous characters remained unescaped* and in what context.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat recon/params/seeded_xss.txt | kxss | anew recon/reflections/reflected_params.txt
    ```

### 6. `dalfox` (Context-Aware XSS Prober)
*   **Purpose:** Analyzes reflection contexts (HTML body, attribute, inline JS, DOM) and fires targeted verification payloads with headless browser confirmation.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    dalfox file recon/reflections/reflected_params.txt --skip-bav --silence --output recon/loot/xss_confirmed.txt
    ```

### 7. `arjun` (Hidden Parameter Discovery)
*   **Purpose:** Discovers undocumented GET, POST, JSON, and XML parameters on API endpoints that never appeared in the UI or web archives.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    # Passive archive parameter mining
    arjun -u "https://target.com/api/v1/user/profile" -m GET,POST --passive -oJ recon/params/arjun_params.json
    ```

### 8. `gau` & `waybackurls` (Historical Endpoint Extraction)
*   **Purpose:** Extracts years of archived URLs from Wayback Machine, AlienVault OTX, CommonCrawl, and URLScan to uncover defunct endpoints and unlinked functionality.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat recon/subs/alive_hosts.txt | gau --threads 10 --subs | anew recon/urls/historical_urls.txt
    cat recon/subs/alive_hosts.txt | waybackurls | anew recon/urls/historical_urls.txt
    ```

### 9. `katana` (Next-Gen Web Crawler)
*   **Purpose:** Fast, headless JavaScript-aware crawler capable of parsing React/Vue bundles, extracting form endpoints, and discovering dynamically loaded API routes.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    katana -list recon/subs/alive_hosts.txt -headless -depth 3 -jc -kf all -silent -o recon/urls/crawled_urls.txt
    ```

### 10. `subfinder` (Passive Subdomain Aggregator)
*   **Purpose:** Passive DNS aggregation across dozens of free and API-keyed sources without touching the target network directly.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    subfinder -d target.com -all -recursive -silent -o recon/subs/passive_subs.txt
    ```

### 11. `tlsx` (TLS SAN Certificate Harvesting)
*   **Purpose:** Connects to resolved IP addresses and hosts, extracting Subject Alternative Names (SANs) and reverse hostnames from SSL/TLS certificates.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat recon/subs/passive_subs.txt | tlsx -san -cn -resp-only -silent | anew recon/subs/passive_subs.txt
    ```

### 12. `dnsx` (Multi-Resolver DNS Engine)
*   **Purpose:** Rapidly resolves massive subdomain lists, filters out DNS wildcards, and extracts A, CNAME, PTR, and TXT records.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat recon/subs/passive_subs.txt | dnsx -r recon/resolvers.txt -silent -a -cname -resp -o recon/subs/resolved_subs.txt
    ```

### 13. `mapcidr` & `naabu` (Network-Level CIDR & Port Scanning)
*   **Purpose:** Expands target CIDR blocks into discrete IP ranges, followed by wire-speed SYN port scanning across non-standard web ports.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    echo "192.168.1.0/24" | mapcidr -silent | anew recon/ips/target_ips.txt
    naabu -list recon/ips/target_ips.txt -top-ports 1000 -rate 1500 -silent -o recon/ips/open_ports.txt
    ```

### 14. `httpx` (HTTP Probing & Fingerprinting)
*   **Purpose:** Probes web services, extracts HTTP status codes, titles, technology stacks, CDN indicators, and Content-Lengths.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat recon/subs/resolved_subs.txt recon/ips/open_ports.txt | httpx \
        -ports 80,443,8080,8443,3000,8081,9000,5000,50051 \
        -sc -title -tech-detect -follow-redirects \
        -json -o recon/signals.jsonl
    ```

### 15. `ffuf` (High-Speed Web Fuzzer)
*   **Purpose:** Blazing fast fuzzing for directories, virtual hosts (VHosts), backup files, and hidden HTTP headers.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    ffuf -u "https://target.com/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -mc 200,301,302,401,403 -fc 404 -silent
    ```

### 16. `nuclei` (Template-Based Vulnerability Engine)
*   **Purpose:** Executes community and custom YAML templates for zero-day CVEs, exposed panels, misconfigurations, and tokens.
*   **Optimal Bug Bounty Syntax:**
    ```bash
    cat recon/subs/alive_hosts.txt | nuclei -t cves/ -t misconfiguration/ -t exposures/ -severity medium,high,critical -silent -o recon/loot/nuclei_findings.txt
    ```

---

## 3. The 5 Canonical Chained Pipelines (Battle-Tested One-Liners)

### Pipeline 1: Complete Subdomain & TLS Asset Discovery
Takes a root domain, aggregates passive records, extracts TLS certificate SANs, resolves with wildcard filtering, and identifies alive web applications:
```bash
subfinder -d target.com -all -silent \
    | tlsx -san -cn -resp-only -silent \
    | anew recon/subs/raw_subs.txt \
    | dnsx -r recon/resolvers.txt -silent \
    | httpx -sc -title -tech-detect -follow-redirects -silent \
    | anew recon/subs/alive_web.txt
```

### Pipeline 2: The High-Yield Parameter Archaeology & XSS Pipeline
Aggregates historical snapshots from multiple providers, crawls headless SPA bundles, normalizes queries, slices by XSS patterns, injects canary probes, and analyzes reflection contexts:
```bash
cat recon/subs/alive_web.txt | gau --subs --threads 10 \
    | anew recon/urls/raw_archive.txt
cat recon/subs/alive_web.txt | katana -headless -depth 3 -jc -silent \
    | anew recon/urls/raw_archive.txt

cat recon/urls/raw_archive.txt \
    | uro \
    | gf xss \
    | qsreplace 'kXss73<"'\`>' \
    | kxss \
    | anew recon/reflections/xss_reflections.txt
```

### Pipeline 3: Blind SSRF & Cloud Metadata Hunting Pipeline
Extracts URL parameters that accept URLs/paths (`redirect`, `url`, `dest`, `feed`), seeds cloud metadata probes, and monitors for response size anomalies:
```bash
cat recon/urls/raw_archive.txt \
    | uro \
    | gf ssrf \
    | qsreplace 'http://169.254.169.254/latest/meta-data/' \
    | httpx -sc -cl -title -silent \
    | anew recon/loot/ssrf_probe_results.txt
```

### Pipeline 4: Network-Level Expansion to Service Fingerprinting
Takes target netblocks or CIDRs, expands them to individual host IPs, performs high-speed port scanning, and extracts running web technologies:
```bash
cat recon/ips/target_cidrs.txt \
    | mapcidr -silent \
    | naabu -top-ports 1000 -rate 1500 -silent \
    | httpx -sc -title -web-server -tech-detect -silent \
    | anew recon/ips/alive_services.txt
```

### Pipeline 5: Hidden API Parameter Discovery
Identifies static or undocumented API endpoints from JavaScript bundles and performs deep parameter fuzzing:
```bash
cat recon/urls/crawled_urls.txt | grep -iE '/api/' | uro \
    | while read api_endpoint; do
        echo "[*] Fuzzing parameters on: $api_endpoint"
        arjun -u "$api_endpoint" -m GET,POST --passive -q | anew recon/params/discovered_params.txt
    done
```

---

## 4. Bridging CLI Pipelines to Manual Burp Suite Hunting

Once the CLI pipeline identifies high-value anomalies:
1. **Reflected Parameters:** Feed `recon/reflections/xss_reflections.txt` into Burp Repeater to analyze the exact HTML escaping and CSP policy.
2. **Access Control (403/401):** Run the automated prober:
   ```powershell
   pwsh ./scripts/test_403_bypasses.ps1 -TargetUrl "https://target.com/admin" -Extended
   ```
3. **Privilege Boundaries:** Import discovered internal endpoints (`/api/internal/*`) into **Burp Autorize** to test for vertical and horizontal IDOR.
