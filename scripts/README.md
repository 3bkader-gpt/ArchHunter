# 🛠️ Tactical Scripts & Automation Hub

This directory contains the production-ready tactical automation scripts for the Bug Bounty Architectural Reasoning Engine. Every script is mapped directly to our 4-Phase Operational Methodology and specific atomic mechanism skills.

---

## 📋 Script Inventory & Matrix

| Script | Platform | Operational Phase | Target Mechanism / Skill | Required Tools |
|---|---|---|---|---|
| [`full_subdomain_recon.sh`](full_subdomain_recon.sh) / [`.ps1`](full_subdomain_recon.ps1) | Bash / PWSH | Phase 1 (Recon) | External Attack Surface Mapping | `subfinder`, `assetfinder`, `puredns`, `httpx` |
| [`run_toolkit_recon.sh`](run_toolkit_recon.sh) / [`.ps1`](run_toolkit_recon.ps1) | Bash / PWSH | Phase 1 (Recon) | Passive + Active Chained Pipeline | `subfinder`, `tlsx`, `katana`, `uro`, `httpx` |
| [`check_subdomain_takeover.sh`](check_subdomain_takeover.sh) / [`.ps1`](check_subdomain_takeover.ps1) | Bash / PWSH | Phase 1 & 3 | [`subdomain_takeover.md`](../skills/infrastructure/subdomain_takeover.md) | `subzy`, `nuclei`, `dig` |
| [`find_origin_ip.sh`](find_origin_ip.sh) / [`.ps1`](find_origin_ip.ps1) | Bash / PWSH | Phase 1 (Perimeter) | [`origin_ip_discovery_waf_bypass.md`](../skills/infrastructure/origin_ip_discovery_waf_bypass.md) | `shodan`, `censys`, `curl`, `openssl` |
| [`discover_api_endpoints.sh`](discover_api_endpoints.sh) / [`.ps1`](discover_api_endpoints.ps1) | Bash / PWSH | Phase 2 (Architecture) | API Attack Surface & DFD Mapping | `katana`, `ffuf`, `httpx` |
| [`fuzz_sensitive_backups.sh`](fuzz_sensitive_backups.sh) / [`.ps1`](fuzz_sensitive_backups.ps1) | Bash / PWSH | Phase 2 & 3 | [`infrastructure_misconfigurations.md`](../skills/infrastructure/infrastructure_misconfigurations.md) | `ffuf` / `curl` |
| [`test_403_bypasses.ps1`](test_403_bypasses.ps1) | PWSH | Phase 3 (Auditing) | [`forbidden_403_bypass.md`](../skills/infrastructure/forbidden_403_bypass.md) | PowerShell 7+, [`payloads/headers/`](../payloads/headers/) |
| [`test_ssrf_bypasses.ps1`](test_ssrf_bypasses.ps1) | PWSH | Phase 3 (Auditing) | [`backend_ssrf_rce.md`](../skills/infrastructure/backend_ssrf_rce.md) | PowerShell 7+, Burp Collaborator / Interactsh |
| [`audit_graphql_endpoints.ps1`](audit_graphql_endpoints.ps1) | PWSH | Phase 3 (Auditing) | [`graphql_attacks.md`](../skills/infrastructure/graphql_attacks.md) | PowerShell 7+ |
| [`extract_js_secrets.ps1`](extract_js_secrets.ps1) | PWSH | Phase 2 & 3 | Hardcoded Credentials & Hidden API Discovery | PowerShell 7+, `curl` |
| [`analyze_js_bundle.ps1`](analyze_js_bundle.ps1) | PWSH | Phase 1 & 2 (Recon & Mapping) | 13-Pattern JS Bundle Deep Regex Inspection | PowerShell 7+ |
| [`find_broken_links.ps1`](find_broken_links.ps1) | PWSH | Phase 3 (Auditing) | [`broken_link_hijacking.md`](../skills/infrastructure/broken_link_hijacking.md) | PowerShell 7+ |
| [`param_reflection_pipeline.ps1`](param_reflection_pipeline.ps1) | PWSH | Phase 3 (Auditing) | [`xss_variations.md`](../skills/infrastructure/xss_variations.md) | `katana`, `uro`, `kxss`, `dalfox` |
| [`quick_hunt_setup.sh`](quick_hunt_setup.sh) / [`.ps1`](quick_hunt_setup.ps1) | Bash / PWSH | Setup | Session Initialization & Scaffolding | Standard shell utilities |
| [`download_medium_writeup.py`](download_medium_writeup.py) | Python 3 | Intelligence | Real-World Research Ingestion | Python 3, `beautifulsoup4`, `requests` |

---

## 🚀 Detailed Tool Usage & Examples

### 1. `full_subdomain_recon.sh` / `.ps1`
*   **Purpose:** Comprehensive multi-stage subdomain enumeration combining passive sources, DNS resolution, and active permutation discovery.
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/full_subdomain_recon.sh example.com
    ```
*   **Usage (PowerShell):**
    ```powershell
    .\scripts\full_subdomain_recon.ps1 -Domain "example.com"
    ```
*   **Outputs:** `targets/example.com/subdomains/all_alive_subdomains.txt`

### 2. `run_toolkit_recon.sh` / `.ps1`
*   **Purpose:** Chained pipeline leveraging `subfinder` $\rightarrow$ `tlsx` $\rightarrow$ `katana` $\rightarrow$ `uro` $\rightarrow$ `gf patterns` for rapid parameter and endpoint classification.
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/run_toolkit_recon.sh target.com
    ```
*   **Usage (PowerShell):**
    ```powershell
    .\scripts\run_toolkit_recon.ps1 -Domain "target.com"
    ```
*   **Outputs:** Discovered live hosts, crawled endpoints, normalized URLs (`urls_clean.txt`), and filtered pattern buckets (`gf_xss.txt`, `gf_ssrf.txt`, `gf_idor.txt`).

### 3. `check_subdomain_takeover.sh` / `.ps1`
*   **Purpose:** Checks discovered subdomains against dangling cloud CNAME fingerprints (AWS S3, GitHub Pages, Heroku, Azure, Bitly, Shopify).
*   **Usage:**
    ```bash
    ./scripts/check_subdomain_takeover.sh -l targets/example.com/subdomains/all.txt
    ```

### 4. `find_origin_ip.sh` / `.ps1`
*   **Purpose:** Circumvents Cloudflare/Akamai/Fastly reverse proxies by computing favicon MurmurHash3 and cross-referencing Shodan, Censys, and historical TLS certificates.
*   **Usage:**
    ```bash
    ./scripts/find_origin_ip.sh https://target.com
    ```

### 5. `discover_api_endpoints.sh` / `.ps1`
*   **Purpose:** Aggressively hunts for hidden Swagger/OpenAPI documentation, GraphQL schemas, Postman collections, and internal REST routes.
*   **Usage:**
    ```bash
    ./scripts/discover_api_endpoints.sh https://api.target.com
    ```

### 6. `fuzz_sensitive_backups.sh` / `.ps1`
*   **Purpose:** Fuzzes target-specific backup files (`.bak`, `.old`, `.zip`, `.tar.gz`, `.env`, `.git/config`, `docker-compose.yml`) using dynamic mutations of the target's domain and host name.
*   **Usage:**
    ```bash
    ./scripts/fuzz_sensitive_backups.sh target.com
    ```

### 7. `test_403_bypasses.ps1`
*   **Purpose:** Automated testing of 5,865 reverse proxy bypass headers from [`payloads/headers/403_bypass_headers.txt`](../payloads/headers/403_bypass_headers.txt), matrix path mutations, and HTTP verb overrides against restricted 403/401 endpoints.
*   **Usage:**
    ```powershell
    .\scripts\test_403_bypasses.ps1 -Url "https://target.com/admin" -HeadersFile "payloads\headers\403_bypass_headers.txt"
    ```

### 8. `audit_graphql_endpoints.ps1`
*   **Purpose:** Probes identified GraphQL endpoints for enabled introspection, field suggestion leakage, array-based query batching (brute-force amplification), and circular recursion DoS vulnerabilities.
*   **Usage:**
    ```powershell
    .\scripts\audit_graphql_endpoints.ps1 -Endpoint "https://target.com/graphql"
    ```

### 9. `extract_js_secrets.ps1`
*   **Purpose:** Downloads loaded JavaScript bundles from target URLs and runs high-precision regex extraction for AWS Access Keys, Google API keys, JWT tokens, Stripe secrets, and internal staging endpoints.
*   **Usage:**
    ```powershell
    .\scripts\extract_js_secrets.ps1 -UrlList "targets\target.com\js_files.txt"
    ```

### 10. `find_broken_links.ps1`
*   **Purpose:** Crawls target domains and documentation to detect expired/unclaimed social handles (Twitter/X, LinkedIn, Telegram), dead GitHub user repos, and dangling external CDNs.
*   **Usage:**
    ```powershell
    .\scripts\find_broken_links.ps1 -TargetUrl "https://target.com"
    ```

### 11. `param_reflection_pipeline.ps1`
*   **Purpose:** Mines parameterized URLs, extracts high-risk reflection sinks, and passes them to `kxss` and `dalfox` for non-destructive XSS confirmation.
*   **Usage:**
    ```powershell
    .\scripts\param_reflection_pipeline.ps1 -UrlList "targets\target.com\urls_clean.txt"
    ```

### 12. `quick_hunt_setup.sh` / `.ps1`
*   **Purpose:** Initializes standardized engagement directory scaffolding (`targets/<domain>/recon`, `notes`, `pocs`) and generates a populated `TARGET_SESSION.md`.
*   **Usage:**
    ```bash
    ./scripts/quick_hunt_setup.sh target.com
    ```

### 13. `download_medium_writeup.py`
*   **Purpose:** Downloads real-world bug bounty writeups from Medium/blogs, removes ads, extracts actionable methodology patterns, and converts them to structured markdown for the knowledge base.
*   **Usage:**
    ```bash
    python scripts/download_medium_writeup.py "https://medium.com/@author/writeup-title" -o research/writeups/
    ```

---

## 🔗 Architectural Integration
All scripts feed data directly into the **Runtime Reasoning Engine** (`Runtime/cmd/runtime/main.go`) and map to our core skills. For workflow guidelines, refer to **[`Methodology/OPERATIONAL_PLAYBOOK.md`](../Methodology/OPERATIONAL_PLAYBOOK.md)** and **[`OPERATIONAL_MAP.md`](../OPERATIONAL_MAP.md)**.
