# 05 — Attack Surface Expansion (Deep Discovery)

## Operational Goal
Extract historical URLs, javascript endpoints, and hidden parameters. Expand the surface beyond top-level directories to find internal logic hubs and resurrect obsolete endpoints.

## Execution Flow

### 1. Historical & Active Crawling
Combine Wayback Machine / CommonCrawl data with headless active crawling.
```bash
# Historical archives aggregation
cat recon/subs/alive_hosts.txt | waybackurls > recon/urls/wayback.txt
cat recon/subs/alive_hosts.txt | gau --threads 10 >> recon/urls/wayback.txt

# Active headless crawling
cat recon/subs/alive_hosts.txt | katana -headless -depth 3 -jc -o recon/urls/katana.txt

# Merge and deduplicate
cat recon/urls/*.txt | sort -u | anew recon/urls/ALL_URLS.txt
```

### 2. 404 Historical Archaeology (Resurrecting Dead Assets)
When `httpx` discovers subdomains or paths returning `404 Not Found`, query archive snapshots (e.g. 2018–2022) to reconstruct defunct APIs, forgotten parameters, or exposed configuration files that were removed from modern navigation but still exist on backend routing.
```bash
# Query CDX Wayback API for specific defunct paths and files
curl -s "http://web.archive.org/cdx/search/cdx?url=*.target.com/*&output=json&collapse=urlkey" \
    | jq -r '.[1:][] | .[2]' \
    | grep -iE '\.(json|xml|yaml|yml|config|bak|sql|env|txt|php|asp|aspx)$' \
    | anew recon/urls/historical_sensitive_files.txt
```

### 3. Parameter Normalization, Pattern Slicing & Contextual Reflection Pipeline
Find hidden parameters feeding into backend query parsers, slice URLs by vulnerability patterns, and evaluate reflection contexts:
```bash
# A. URL Normalization & Parameter Extraction (uro & anew)
cat recon/urls/ALL_URLS.txt | grep '=' | uro | anew recon/params/param_urls.txt

# B. Slice URLs by Vulnerability Signatures (gf patterns)
cat recon/params/param_urls.txt | gf xss   | anew recon/params/xss_candidates.txt
cat recon/params/param_urls.txt | gf ssrf  | anew recon/params/ssrf_candidates.txt
cat recon/params/param_urls.txt | gf idor  | anew recon/params/idor_candidates.txt
cat recon/params/param_urls.txt | gf sqli  | anew recon/params/sqli_candidates.txt
cat recon/params/param_urls.txt | gf lfi   | anew recon/params/lfi_candidates.txt

# C. Bulk Parameter Value Replacement & Reflection Probing (qsreplace + kxss)
# Replace parameter values with canary test payload
cat recon/params/xss_candidates.txt | qsreplace 'kXss73<"'\`' | kxss | anew recon/params/kxss_reflections.txt

# D. Context-Aware Automated XSS Injection (dalfox)
dalfox file recon/params/kxss_reflections.txt --skip-bav --silence --output recon/params/dalfox_findings.txt

# E. Hidden Parameter Discovery (arjun)
arjun -i recon/params/param_urls.txt -m GET,POST -oT recon/params/hidden_params.txt

# F. Pure PowerShell Reflection Pipeline Alternative:
pwsh ./scripts/param_reflection_pipeline.ps1 -UrlFile recon/params/param_urls.txt -OutputFile recon/params/reflected_params.json
```

### 4. JavaScript Deep Mining & Deobfuscation (Front-End Reverse Engineering)
Modern Single Page Applications (React, Angular, Vue, Next.js) embed backend routes, internal parameters, and authorization roles inside compiled Webpack bundle chunks.

```bash
# A. Extract All JavaScript File URLs from Crawl and Historical Archives
cat recon/urls/ALL_URLS.txt | grep -iE '\.js(\?|$)' | anew recon/urls/js_files.txt
katana -list recon/subs/alive_hosts.txt -jc -kf all -silent | grep -iE '\.js(\?|$)' | anew recon/urls/js_files.txt

# B. Download Target JS Bundles to Local Disk for Offline Deep Regexing
mkdir -p recon/js/
cat recon/urls/js_files.txt | head -n 30 | while read url; do
    filename=$(echo "$url" | awk -F/ '{print $NF}' | cut -d? -f1)
    curl -s -L "$url" -o "recon/js/${filename:-bundle.js}"
done
```

#### The 13-Pattern Targeted JavaScript Inspection Playbook:
Run these 13 targeted regex queries against downloaded JS bundles (e.g. `main.js`) or using `./scripts/analyze_js_bundle.ps1`:

| # | Objective | High-Precision Grep Command |
|---|---|---|
| 1 | **API Endpoints** | `grep -Eo '/api/[^"'\'' ]+' recon/js/*.js` |
| 2 | **Full URLs** | `grep -Eo 'https?://[^"'\'' ]+' recon/js/*.js` |
| 3 | **Route Keywords** | `grep -iE 'api\|endpoint\|route' recon/js/*.js` |
| 4 | **Admin Controls** | `grep -iE 'admin\|administrator\|management' recon/js/*.js` |
| 5 | **Auth & Registration** | `grep -iE 'login\|logout\|signin\|signup\|register\|auth' recon/js/*.js` |
| 6 | **User & Identity** | `grep -iE 'user\|account\|profile\|settings' recon/js/*.js` |
| 7 | **Object & ID Parameters** | `grep -iE 'id=\|userId\|user_id\|accountId\|redirect\|returnUrl' recon/js/*.js` |
| 8 | **Legacy & Future API Versions** | `grep -Eo '/api/v[0-9]+[^"'\'' ]*' recon/js/*.js` |
| 9 | **WebSocket Channels** | `grep -Ei 'ws://\|wss://\|websocket' recon/js/*.js` |
| 10 | **Config & Sensitive Files** | `grep -Eoi '[/A-Za-z0-9_.-]+(php\|json\|xml\|config\|graphql)[^"'\'' ]*' recon/js/*.js` |
| 11 | **GraphQL Operations** | `grep -iE 'graphql\|mutation\|query' recon/js/*.js` |
| 12 | **Source Map Pointers** | `grep -Eo '[^"'\'' ]+\.map' recon/js/*.js` |
| 13 | **Client HTTP Clients** | `grep -Ei 'fetch\(|axios|XMLHttpRequest' recon/js/*.js` |

```bash
# C. Secrets, Token & Key Extraction
cat recon/urls/js_files.txt | while read url; do
    curl -s -k "$url" | grep -E -o "AIzaSy[A-Za-z0-9-_]{33}|amzn\.mws\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|AKIA[0-9A-Z]{16}|ey[A-Za-z0-9_-]{10,}\.ey[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}" | anew recon/loot/secrets.txt
done

# D. JavaScript Deobfuscation & Source Map Restoration (.js.map)
cat recon/urls/js_files.txt | sed 's/\.js$/\.js\.map/' | httpx -sc -mc 200 -silent -o recon/urls/live_sourcemaps.txt
# If live source map is found, unpack using sourcemapper:
# sourcemapper -url https://target.com/main.js.map -output recon/loot/source_tree/
```

### 5. API Surface Mapping & Method Multiplexing (`api-list.txt`)

Transition from isolated URL clues to a comprehensive, weaponized API inventory:
```
[Burp Proxy Traffic]  +  [JS 13-Pattern Mining]  +  [Swagger/OpenAPI]  +  [Historical Archives]
                                      │
                                      ▼
                        [recon/api/api-list.txt]
                                      │
                                      ▼
                 [Method Multiplexing: GET, POST, PUT, PATCH, DELETE]
```

#### A. Constructing `api-list.txt`:
Combine all discovered paths into a deduplicated list:
```bash
cat recon/urls/ALL_URLS.txt recon/urls/js_extracted_endpoints.txt | grep -E '^/api/|^https?://' | sort -u > recon/api/api-list.txt
```

#### B. HTTP Method Multiplexing:
Never assume an endpoint only supports `GET`. Often, developers implement authorization middleware solely on `GET` or `POST`, while `PUT`, `PATCH`, or `DELETE` bypass authentication and allow unauthorized object modification:
```bash
# Test all 5 HTTP methods on target API endpoints:
for ep in $(cat recon/api/api-list.txt); do
    for method in GET POST PUT PATCH DELETE; do
        curl -s -o /dev/null -w "%{http_code} $method $ep\n" -X "$method" "$ep" \
             -H "X-HackerOne-Researcher: qalbaz_0x"
    done
done | grep -E '200|201|204|403|405' | tee recon/api/method_matrix.txt
```

#### C. API Priority Ranking:
Prioritize manual audits on endpoints handling high-leverage business operations:
1. `Admin & Permissions:` `/api/admin/users`, `/api/roles`, `/api/permissions`
2. `User & Identity:` `/api/user/settings`, `/api/auth/password-reset`, `/api/tokens`
3. `Financial & Billing:` `/api/billing`, `/api/checkout`, `/api/coupons`, `/api/refunds`
4. `Object Movers:` `/api/export`, `/api/import`, `/api/clone`, `/api/restore`
5. `Multi-Tenant Isolation:` `/api/orgs/{org_id}/members`, `/api/workspaces`


### 6. Origin IP Discovery & WAF Bypass (Direct Host Probing)
Identify backend origin IP addresses behind Cloudflare/Akamai/CloudFront to bypass WAF rules entirely.
```bash
# A. Calculate Favicon MurmurHash3 and search Shodan / Censys
python3 -c "import mmh3, requests, codecs; r=requests.get('https://target.com/favicon.ico', verify=False); print(mmh3.hash(codecs.encode(r.content, 'base64')))"
# Search Shodan: http.favicon.hash:<HASH>

# B. Historical SSL Certificates & DNS Records
# Check Censys / SecurityTrails for direct IPs presenting target's SSL cert

# C. Direct Host Header Verification
curl -s -k -H "Host: target.com" "https://<DISCOVERED_IP>" | grep -i "target.com"
```

### 7. Domain-Tailored Backup & Sensitive Files Fuzzing
Fuzz for developer backups, exposed environment configs, and dangling source repositories generated during deployments.
```bash
# Generate tailored dictionary based on target domain (e.g. target_backup.zip, target.sql, .env)
ffuf -u "https://target.com/FUZZ" \
     -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt \
     -e .bak,.old,.backup,.zip,.tar.gz,.sql,.env,~,.swp,.txt \
     -mc 200,403 -fc 404 -silent -o recon/loot/backup_hits.json

# If .git is exposed:
git-dumper https://target.com/.git/ recon/loot/dumped_git/
```

### 8. OpenAPI, Swagger & GraphQL Schema Harvesting
Locate developer API schemas to discover undocumented internal endpoints and shadow parameters.
```bash
# Fuzz for common API documentation and schema endpoints
cat recon/subs/alive_hosts.txt | while read host; do
    ffuf -u "${host}/FUZZ" \
         -w <(echo -e "swagger.json\nv2/api-docs\nv3/api-docs\nopenapi.json\napi-docs\nswagger-ui.html\nswagger/v1/swagger.json\ngraphql\ngraphiql\naltair\napi/graphql") \
         -mc 200 -silent
done | anew recon/urls/api_schemas.txt
```

## Reasoning Checkpoint
*   **Origin IP Validation:** If origin IP is discovered, re-route all API fuzzing and parameter tests directly to the origin to bypass WAF rate limits.
*   **Async Identification:** Did you find endpoints like `/export`, `/webhook`, or `/process`? These indicate background workers susceptible to [Async Trust Drift](../skills/state_management/async_workflow_integrity.md).
*   **Filter Sorting:** Use `gf` patterns to group parameters by vulnerability class (e.g., `gf ssrf`, `gf idor`) before moving to manual validation.

## Transition to Validation
Proceed to **[06 — Manual Validation](06_manual_validation.md)** to begin hypothesis-driven testing of these mechanisms.
