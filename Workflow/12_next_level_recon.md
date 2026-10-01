# 12 — Next-Level Recon (Org → Time → Source → Shadow APIs)

> **Doctrine:** [`Methodology/DEPTH_FIRST_DOCTRINE.md`](../Methodology/DEPTH_FIRST_DOCTRINE.md) · **Rule 0 — Scope is Law:** only test assets explicitly in scope (explicit domain or wildcard `*.target.com` + authorized ASN). Everything below is passive/semi-passive until authorization is confirmed. · **Tooling:** [`scripts/time_travel_recon.sh`](../scripts/time_travel_recon.sh), [`scripts/shadow_api_probe.sh`](../scripts/shadow_api_probe.sh)

## Operational Goal
Top-tier hunters do not start *on* `target.com` — they start *around* it and let forgotten infrastructure hand them RCE / SSO takeover / IDOR before touching the main app's WAF. The average hunter runs `subfinder → httpx → nuclei`; this workflow hunts where the company *forgot* to apply the main app's security.

## Phase 1 — Organization → Infrastructure Map (Not Just Subdomains)

1. **ASN & org expansion:** `amass intel -org "Target Inc"`, `asnmap -org Target`, `shodan org:"Target Inc"`, `bgp.he.net`, `whois -h whois.radb.net -- '-i origin ASXXXXX'`. Reverse-enumerate every IP in owned ranges — catches infra with **no DNS record at all**.
2. **Reverse WHOIS:** `viewdns.info/reverseWhois`, SecurityTrails, Whoxy — domains registered with the same org email that the main site never links. Historical (pre-GDPR) WHOIS registrant pivots reveal shadow-IT and acquired-brand domains.
3. **Cloud shadow:** `cloud_enum` / S3Scanner permutations on `target`, `target-corp`, `targetinc` across AWS/GCP/Azure; `site:s3.amazonaws.com "target"`.
4. **Acquisitions:** Crunchbase/LinkedIn/press — acquired infra is almost always less hardened; `target-acquired.com` often leaks `*.target.com` keys in old repos.
5. **Forgotten cloud assets (systematic):** → [`cloud_asset_hunter.sh`](../scripts/cloud_asset_hunter.sh)
   - **Permutation seeding:** don't guess `company-name` — generate `{company}-{env}-{region}`, `{product}-backup`, `{old-brand}-assets`, acquired-company names. Seed keywords from JS bundles and **job postings** (below).
   - **DNS-based discovery:** grep `dnsx`/`subfinder` resolution for CNAMEs to `*.s3.amazonaws.com`, `*.blob.core.windows.net`, `*.storage.googleapis.com`, `*.azurewebsites.net` — often undocumented and forgotten.
   - **CT for cloud-native domains:** grep crt.sh dumps for `*.cloudfront.net`, `*.elb.amazonaws.com`, `*.appspot.com` under the target's SANs.
   - **Favicon hash pivoting:** Shodan/Censys `http.favicon.hash` on the target's favicon → sibling dev/staging infra reusing it. → [`find_origin_ip.sh`](../scripts/find_origin_ip.sh)

## Phase 2 — Time-Travel Recon (Historical DNS, Routing, Wayback)

1. **Historical DNS:** SecurityTrails/ViewDNS history — a subdomain on `NXDOMAIN` today whose old IP `52.x.x.x` still serves the app bypasses Cloudflare/WAF entirely. → [`origin_ip_discovery_waf_bypass`](../skills/infrastructure/origin_ip_discovery_waf_bypass.md)
2. **Wayback diffs, not dumps:** `waymore -i target.com -mode U | unfurl keys | sort -u` — old API versions (`/api/v1_internal/`, `/v2_beta/`, `/admin_legacy/`); `robots.txt` 2018 vs today (disallowed entries = live shadow APIs); old JS → still-active old endpoints.
3. **CT as source of truth:** crt.sh/Censys last-5-years vs current DNS — anything in CT but not resolving = forgotten. → [`subdomain_takeover`](../skills/infrastructure/subdomain_takeover.md)

Automate 1-3 with [`time_travel_recon.sh`](../scripts/time_travel_recon.sh).

## Phase 3 — Source Code & CI/CD Leak Intelligence (Highest ROI)

1. **GitHub org intelligence:** `org:target "api.target.com"`, `org:target filename:.env`, `org:target "aws_access_key"`; employee personal repos via `"target.com" language:javascript pushed:>2023-01-01`. Also search hardcoded bucket/container names: `"amazonaws.com" target`, `"blob.core.windows.net"` in repos and gists — devs leak staging bucket names in commit history constantly.
2. **History, not just HEAD:** deleted secrets live in git history — `trufflehog git https://github.com/target/repo --only-verified`.
3. **CI/CD artifacts:** `Jenkinsfile`, `.github/workflows`, `.gitlab-ci.yml`, `.circleci/config.yml`, `azure-pipelines.yml`, `terraform` leak internal hostnames, S3 buckets, shadow API URLs, deployment endpoints.
4. **Package registries:** `docker pull target/internal-api` (env vars + source), `npm view @target/api`; Postman public workspaces with live Bearer tokens.
5. **Exposed `.git`:** `httpx -path /.git/HEAD` — full source beats any payload guessing. → [`infrastructure_misconfigurations`](../skills/infrastructure/infrastructure_misconfigurations.md)
6. **Build artifacts & registries:**
   - Public Jenkins: `/job/*/lastBuild/api/json` — build logs leak internal hostnames and secrets.
   - Docker registries: `GET /v2/_catalog` on open registries; `docker history` + layer inspection on org-named Hub images reveals secrets baked into layers.
   - npm/PyPI internal-name sweep: `{company}-core`, `{company}-utils` — internal packages accidentally published with secrets or API docs.
   - **Terraform state:** `inurl:terraform.tfstate` / S3 enum — plaintext secrets + full infra topology.
7. **Postman/Swagger public workspaces:** `site:postman.com "target"`, SwaggerHub — collections often contain full API routes with untouched `Authorization: Bearer` headers.

## Phase 4 — Client-Side & Shadow API Mining

1. **JS deep dive:** `katana -jc` → LinkFinder/SecretFinder/`mantra -js`; webpack chunks leak `/internal-api/debug/purge` routes with comments. → [`analyze_js_bundle.sh`](../scripts/analyze_js_bundle.sh)
2. **Mobile beats web:** the APK ships staging/UAT keys and endpoints web never uses (see [Workflow 11](11_depth_first_mobile.md) Phase 1).
3. **Spec brute-force, not directory brute-force:** `/openapi.json`, `/swagger.json`, `/v2/api-docs`, `/.well-known/openid-configuration`, `/schema.graphql` → [`shadow_api_probe.sh`](../scripts/shadow_api_probe.sh). → [`shadow_api_exploitation`](../skills/auth_logic/shadow_api_exploitation.md)
4. **Kiterunner** on JS-derived routes — finds `GET /api/internal/users/export` with no auth.
5. **Gateway routing headers:** `X-Original-URL` / `X-Rewrite-URL` / `X-Forwarded-Host` to reach internal APIs routed by the gateway. → [`forbidden_403_bypass`](../skills/infrastructure/forbidden_403_bypass.md)
6. **Environment parity:** permute `dev-`, `stg-`, `uat-`, `preprod-`, `legacy-`; check `X-Api-Version`/`Accept-Version` — old `v1` often lacks authz fixes shipped in `v3`.

## Phase 5 — Active Validation Without Payloads

```bash
cat historical_ips.txt | httpx -sc -td -title -cdn -probe
nuclei -l live.txt -t exposures/ -t misconfiguration/ -t takeover/ -severity high,critical
ffuf -u https://target.com/FUZZ -w shadow_api_routes.txt -mc 200,401,403 -fs 0
```

**Pre-payload checklist:**
1. Is this API in the main JS bundle? If not — shadow → test authz hardest.
2. Does the response leak `X-Env: development`? → try `../`, `debug=true`.
3. Does `/.git/config` leak? → you have the source; stop guessing payloads.
4. Does the historical IP bypass Cloudflare? → rate-limit/WAF evasion is free.

## Phase 6 — Developer & Organizational OSINT (The Human Attack Surface)

Once technical enumeration is exhausted, the next tier is people: developers leak internal reality through public activity.

1. **Commit-email pivoting:** `git log` every public repo the org owns (forks and archived repos included) → extract all committer emails → feed into breach databases / Hunter.io for address-pattern discovery → check those emails as usernames on GitHub, Docker Hub, Trello, Jira.
2. **Current & former employees:** pivot from commit authors to personal GitHub accounts — personal repos hold old API keys, internal tooling, deployment scripts referencing internal infra. Former-employee repos are the least monitored.
3. **LinkedIn → platform correlation:** identify DevOps/SRE staff, cross-reference their usernames across GitHub / GitLab / Docker Hub / npm — starred and forked repos often contain the internal tooling they use at work.
4. **Public boards:** `site:trello.com "target"`, `site:atlassian.net "target"`, `site:notion.site "target"` — public sprint boards leak internal URLs, hostnames, and occasionally credentials in task descriptions.
5. **Job postings as tech-stack recon:** scrape DevOps/SRE/backend listings — named cloud providers, Kubernetes/CI tooling, internal product names narrow the permutation seeds for Phase 1 cloud hunting intelligently.
6. **Archived API docs:** Wayback on `/docs`, `/api/docs`, `/swagger`, `/developers` — deprecated documentation stays archived while its endpoints often stay live and unmonitored (pair with Phase 2 diffs).

Automate the passive slice with [`dev_pivot_osint.sh`](../scripts/dev_pivot_osint.sh) (dork generation + commit-email mining; requires `GITHUB_TOKEN` for API use).

## Phase 7 — Esoteric Angles

1. **TLS JARM/JA3S sibling hunting:** fingerprint the target's TLS stack (`jarm scan`) and search Censys/Shodan for identical JARM hashes — finds sibling load balancers/origins sharing the same server config, DNS-independent.
2. **Wildcard-cert CT mining:** if the target uses a wildcard certificate, mine crt.sh for *any* SAN ever issued under it — including subdomains never linked anywhere (pair with Phase 2 DNS diff).
3. **CSP mining:** `Content-Security-Policy` headers often whitelist internal subdomains/API hosts discoverable nowhere else — diff the CSP **across every page**, not just the homepage, and feed new hosts back into the Runtime graph.
4. **GraphQL persisted-query replay:** with introspection disabled, batch-query operation names harvested from JS bundles; persisted-query hashes (Apollo APQ) leaked in JS replay against production to reveal schema shape. → [`graphql_attacks`](../skills/infrastructure/graphql_attacks.md)
5. **Second-order SaaS takeover:** beyond classic dangling CNAMEs, check orphaned custom-domain entries on SaaS platforms — Zendesk, Shopify, Statuspage, Help Scout, Fastly allow claiming an unclaimed custom domain even when the DNS record still exists but the tenant is gone. → [`subdomain_takeover`](../skills/infrastructure/subdomain_takeover.md) § Second-Order SaaS
6. **Error-based origin leaks:** malformed `Host` headers and oversized requests on edge-hosted routes — some origins reveal their real IP or internal hostname in error pages/headers.

## Transition
Feed discovered live hosts/APIs back into the Runtime (`signals.jsonl`) for architectural inference, then into **[10 — Depth-First Web & API](10_depth_first_web_api.md)** for the depth pass.
