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
| [`test_403_bypasses.sh`](test_403_bypasses.sh) / [`.ps1`](test_403_bypasses.ps1) | Bash / PWSH | Phase 3 (Auditing) | [`forbidden_403_bypass.md`](../skills/infrastructure/forbidden_403_bypass.md) | PowerShell 7+, [`payloads/headers/`](../payloads/headers/) |
| [`test_ssrf_bypasses.sh`](test_ssrf_bypasses.sh) / [`.ps1`](test_ssrf_bypasses.ps1) | Bash / PWSH | Phase 3 (Auditing) | [`backend_ssrf_rce.md`](../skills/infrastructure/backend_ssrf_rce.md) | PowerShell 7+, Burp Collaborator / Interactsh |
| [`audit_graphql_endpoints.sh`](audit_graphql_endpoints.sh) / [`.ps1`](audit_graphql_endpoints.ps1) | Bash / PWSH | Phase 3 (Auditing) | [`graphql_attacks.md`](../skills/infrastructure/graphql_attacks.md) | PowerShell 7+ |
| [`extract_js_secrets.sh`](extract_js_secrets.sh) / [`.ps1`](extract_js_secrets.ps1) | Bash / PWSH | Phase 2 & 3 | Hardcoded Credentials & Hidden API Discovery | PowerShell 7+, `curl` |
| [`analyze_js_bundle.sh`](analyze_js_bundle.sh) / [`.ps1`](analyze_js_bundle.ps1) | Bash / PWSH | Phase 1 & 2 (Recon & Mapping) | 13-Pattern JS Bundle Deep Regex Inspection | PowerShell 7+ |
| [`find_broken_links.sh`](find_broken_links.sh) / [`.ps1`](find_broken_links.ps1) | Bash / PWSH | Phase 3 (Auditing) | [`broken_link_hijacking.md`](../skills/infrastructure/broken_link_hijacking.md) | PowerShell 7+ |
| [`param_reflection_pipeline.sh`](param_reflection_pipeline.sh) / [`.ps1`](param_reflection_pipeline.ps1) | Bash / PWSH | Phase 3 (Auditing) | [`xss_variations.md`](../skills/infrastructure/xss_variations.md) | `katana`, `uro`, `kxss`, `dalfox` |
| [`quick_hunt_setup.sh`](quick_hunt_setup.sh) / [`.ps1`](quick_hunt_setup.ps1) | Bash / PWSH | Setup | Session Initialization & Scaffolding | Standard shell utilities |
| [`setup_target.sh`](setup_target.sh) / [`.ps1`](setup_target.ps1) | Bash / PWSH | Setup / Onboarding | Automated Target Scaffolding & ArchHunter Deployment | PowerShell 5.1+ / 7+ |
| [`download_medium_writeup.py`](download_medium_writeup.py) | Python 3 | Intelligence | Real-World Research Ingestion | Python 3, `beautifulsoup4`, `requests` |
| [`time_travel_recon.sh`](time_travel_recon.sh) | Bash | Phase 1 (Recon — passive) | [`Workflow/12`](../Workflow/12_next_level_recon.md) Time-Travel: CT/DNS/Wayback diff | `curl`, `jq`, `dig` |
| [`shadow_api_probe.sh`](shadow_api_probe.sh) | Bash | Phase 2 & 3 (Surface) | [`shadow_api_exploitation.md`](../skills/auth_logic/shadow_api_exploitation.md) | `curl`, `jq` |
| [`cloud_asset_hunter.sh`](cloud_asset_hunter.sh) | Bash | Phase 1 (Recon — passive) | [`Workflow/12`](../Workflow/12_next_level_recon.md) Forgotten cloud assets + orphaned-asset rule | `curl`, `jq`, `dig` |
| [`origin_ip_uncloak.sh`](origin_ip_uncloak.sh) | Bash | Phase 1 (Perimeter) | [`origin_ip_discovery_waf_bypass.md`](../skills/infrastructure/origin_ip_discovery_waf_bypass.md) SPF/DMARC + exclusion classes | `dig`, `curl`, `jq` |
| [`dev_pivot_osint.sh`](dev_pivot_osint.sh) | Bash | Phase 1 (OSINT) | [`Workflow/12`](../Workflow/12_next_level_recon.md) Developer-pivot phase | `curl`, `jq` (+ `GITHUB_TOKEN`) |
| [`js_bundle_changelog.sh`](js_bundle_changelog.sh) | Bash | Phase 2 (Mapping — passive) | [`Workflow/12`](../Workflow/12_next_level_recon.md) JS→infra graph: Wayback bundle diffing = internal API changelog | `curl`, `jq` |
| [`intel/fetch_h1_reports.py`](intel/fetch_h1_reports.py) | Python 3 | Intelligence | Disclosed H1 Report Ingestion (auth / ai / state presets) | Python 3, `requests` |
| [`intel/fetch_telegram_intel.py`](intel/fetch_telegram_intel.py) | Python 3 | Intelligence | Telegram Channel Writeup Crawler → `research/case_studies/` | Python 3, `telethon`, `beautifulsoup4`, `requests` |
| [`intel/tg_login.py`](intel/tg_login.py) | Python 3 | Intelligence | One-time Telegram Session Provisioning (interactive) | Python 3, `telethon` |

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

### 7. `test_403_bypasses.sh` / `.ps1`
*   **Purpose:** Path normalizations, rewrite headers, IP spoofing, verb overrides, and optional extended header wordlist against restricted 403/401 endpoints.
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/test_403_bypasses.sh -u "https://target.com/admin" -x
    ```

### 7b. `test_403_bypasses.ps1`
*   **Purpose:** Automated testing of 5,865 reverse proxy bypass headers from [`payloads/headers/403_bypass_headers.txt`](../payloads/headers/403_bypass_headers.txt), matrix path mutations, and HTTP verb overrides against restricted 403/401 endpoints.
*   **Usage:**
    ```powershell
    .\scripts\test_403_bypasses.ps1 -Url "https://target.com/admin" -HeadersFile "payloads\headers\403_bypass_headers.txt"
    ```

### 8. `audit_graphql_endpoints.sh` / `.ps1`
*   **Purpose:** Probes common GraphQL paths for discovery, introspection status, array-based batching, and field-suggestion leaks.
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/audit_graphql_endpoints.sh https://target.com
    ```

### 8b. `audit_graphql_endpoints.ps1`
*   **Purpose:** Probes identified GraphQL endpoints for enabled introspection, field suggestion leakage, array-based query batching (brute-force amplification), and circular recursion DoS vulnerabilities.
*   **Usage:**
    ```powershell
    .\scripts\audit_graphql_endpoints.ps1 -Endpoint "https://target.com/graphql"
    ```

### 9. `extract_js_secrets.sh` / `.ps1`
*   **Purpose:** Discovers JS bundles from a page, checks exposed `.js.map` source files, extracts API routes, and flags hardcoded cloud/API secrets.
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/extract_js_secrets.sh https://target.com
    ```

### 9b. `extract_js_secrets.ps1`
*   **Purpose:** Downloads loaded JavaScript bundles from target URLs and runs high-precision regex extraction for AWS Access Keys, Google API keys, JWT tokens, Stripe secrets, and internal staging endpoints.
*   **Usage:**
    ```powershell
    .\scripts\extract_js_secrets.ps1 -UrlList "targets\target.com\js_files.txt"
    ```

### 10. `find_broken_links.sh` / `.ps1`
*   **Purpose:** Extracts external links, probes HTTP status (HEAD with GET fallback), and flags 404/410 on high-value third-party assets (GitHub, Twitter/X, LinkedIn, S3, Bitly).
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/find_broken_links.sh https://docs.target.com
    ```

### 10b. `find_broken_links.ps1`
*   **Purpose:** Crawls target domains and documentation to detect expired/unclaimed social handles (Twitter/X, LinkedIn, Telegram), dead GitHub user repos, and dangling external CDNs.
*   **Usage:**
    ```powershell
    .\scripts\find_broken_links.ps1 -TargetUrl "https://target.com"
    ```

### 11. `param_reflection_pipeline.sh` / `.ps1`
*   **Purpose:** Collects URLs (OTX/Wayback/file), dedupes parameterized endpoints, injects canary tokens, and classifies reflection contexts (tag/attribute/script/comment) with unescaped-char analysis.
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/param_reflection_pipeline.sh -d example.com -n 100
    ```

### 11b. `param_reflection_pipeline.ps1`
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

### 12b. `analyze_js_bundle.sh` / `.ps1`
*   **Purpose:** 13-pattern deep inspection of local JS bundles (API endpoints, admin routes, auth flows, GraphQL ops, WebSockets, source maps) producing `api-list.txt` + JSON report.
*   **Usage (Bash/WSL):**
    ```bash
    ./scripts/analyze_js_bundle.sh -d recon/js -o recon/api
    ```

### 12c. `setup_target.sh` / `.ps1`
*   **Purpose:** Per-target engagement scaffolding: clean ArchHunter copy (no `.git`/`_archive`), customized `TARGET_SESSION.md`, recon hierarchy, scope files, and fresh Runtime `session_id`.
*   **Usage (Bash/WSL):**
    ```bash
    BASE_DIR=/mnt/z/bug_bounty ./scripts/setup_target.sh acme acme.com
    ```

### 12c-bis. `cloud_asset_hunter.sh`
*   **Purpose:** Forgotten-cloud-asset hunting per [`Workflow/12`](../Workflow/12_next_level_recon.md) Phase 1: permutation generation (org/env/product seeds), S3/Azure/GCS existence probing, CNAME cloud mining from recon output, CT cloud-domain grep.
*   **Usage:**
    ```bash
    ./scripts/cloud_asset_hunter.sh acme.com acme recon/timetravel/ct_hosts.txt
    ```

### 12c-quater. `origin_ip_uncloak.sh`
*   **Purpose:** Origin uncloaking per [`origin_ip_discovery_waf_bypass`](../skills/infrastructure/origin_ip_discovery_waf_bypass.md): SPF/DMARC infrastructure mining, non-proxied subdomain classes (mail./direct./origin.), CT cert-history dump, error-based Host-header leak probes. Complements `find_origin_ip.sh` (favicon hash).
*   **Usage:**
    ```bash
    ./scripts/origin_ip_uncloak.sh target.com
    ```

### 12c-quin. `dev_pivot_osint.sh`
*   **Purpose:** Developer/organizational OSINT per [`Workflow/12`](../Workflow/12_next_level_recon.md) Phase 6: commit-email mining via GitHub API (`GITHUB_TOKEN` recommended), dork-list generation (boards/tfstate/Postman/npm), Wayback doc waypoints. Passive lead generation only.
*   **Usage:**
    ```bash
    GITHUB_TOKEN=ghp_xxx ./scripts/dev_pivot_osint.sh acme.com acme-corp
    ```

### 12d. `js_bundle_changelog.sh`
*   **Purpose:** Historical JS bundle diffing per [`Workflow/12`](../Workflow/12_next_level_recon.md) Phase 4: Wayback snapshots of the same bundle paths, endpoint-string extraction, old-vs-new diff = changelog of added/retired internal endpoints.
*   **Usage:**
    ```bash
    ./scripts/js_bundle_changelog.sh target.com
    ```

### 12d-bis. `time_travel_recon.sh`
*   **Purpose:** Passive time-travel recon per [`Workflow/12`](../Workflow/12_next_level_recon.md) Phase 2: CT history vs current DNS (forgotten hosts), Wayback legacy-API-version mining, and robots.txt drift baseline.
*   **Usage:**
    ```bash
    ./scripts/time_travel_recon.sh target.com recon/timetravel
    ```

### 12e. `shadow_api_probe.sh`
*   **Purpose:** Spec-artifact brute-force (openapi.json / swagger / api-docs / schema.graphql), GraphQL introspection check, and shadow-route fingerprinting (401/403 = exists + authz gap) per [`Workflow/12`](../Workflow/12_next_level_recon.md) Phase 4.
*   **Usage:**
    ```bash
    ./scripts/shadow_api_probe.sh https://target.com
    ```

### 13. `download_medium_writeup.py`
*   **Purpose:** Downloads real-world bug bounty writeups from Medium/blogs, removes ads, extracts actionable methodology patterns, and converts them to structured markdown for the knowledge base.
*   **Usage:**
    ```bash
    python scripts/download_medium_writeup.py "https://medium.com/@author/writeup-title" -o research/writeups/
    ```

### 14. `intel/fetch_h1_reports.py`
*   **Purpose:** Pulls disclosed HackerOne reports matching a mechanism preset (`auth` / `ai` / `state`) or custom hacktivity queries, converts each full disclosure to Markdown, and writes an `INDEX.md`. Output lands in `research/case_studies/_fresh/` by default.
*   **Usage:**
    ```bash
    python scripts/intel/fetch_h1_reports.py --preset ai --limit 20
    python scripts/intel/fetch_h1_reports.py --query 'title:"Race Condition" AND disclosed:true' --limit 10
    ```

### 15. `intel/fetch_telegram_intel.py`
*   **Purpose:** Crawls the channels inside a Telegram dialog filter, keyword-filters messages, fetches linked full articles, and archives them under categorized subfolders in `research/case_studies/_fresh_tg/`. Credentials are read from `TELEGRAM_API_ID` / `TELEGRAM_API_HASH` / `TELEGRAM_SESSION` env vars (never hardcode them).
*   **Usage:**
    ```bash
    python scripts/intel/tg_login.py                      # one-time session provisioning
    python scripts/intel/fetch_telegram_intel.py --keywords "ssrf,mcp,llm" --folder-filter bug_bounty
    ```

---

## 🔗 Architectural Integration
All scripts feed data directly into the **Runtime Reasoning Engine** (`Runtime/cmd/runtime/main.go`) and map to our core skills. For workflow guidelines, refer to **[`Methodology/OPERATIONAL_PLAYBOOK.md`](../Methodology/OPERATIONAL_PLAYBOOK.md)** and **[`OPERATIONAL_MAP.md`](../OPERATIONAL_MAP.md)**.
