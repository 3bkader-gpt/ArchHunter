# 12 — Next-Level Recon (Org → Time → Source → Shadow APIs)

> **Doctrine:** [`Methodology/DEPTH_FIRST_DOCTRINE.md`](../Methodology/DEPTH_FIRST_DOCTRINE.md) · **Rule 0 — Scope is Law:** only test assets explicitly in scope (explicit domain or wildcard `*.target.com` + authorized ASN). Everything below is passive/semi-passive until authorization is confirmed. · **Tooling:** [`scripts/time_travel_recon.sh`](../scripts/time_travel_recon.sh), [`scripts/shadow_api_probe.sh`](../scripts/shadow_api_probe.sh)

## Operational Goal
Top-tier hunters do not start *on* `target.com` — they start *around* it and let forgotten infrastructure hand them RCE / SSO takeover / IDOR before touching the main app's WAF. The average hunter runs `subfinder → httpx → nuclei`; this workflow hunts where the company *forgot* to apply the main app's security.

## Phase 1 — Organization → Infrastructure Map (Not Just Subdomains)

1. **ASN & org expansion:** `amass intel -org "Target Inc"`, `asnmap -org Target`, `shodan org:"Target Inc"`, `bgp.he.net`, `whois -h whois.radb.net -- '-i origin ASXXXXX'`.
2. **Reverse WHOIS:** `viewdns.info/reverseWhois`, SecurityTrails, Whoxy — domains registered with the same org email that the main site never links.
3. **Cloud shadow:** `cloud_enum` / S3Scanner permutations on `target`, `target-corp`, `targetinc` across AWS/GCP/Azure; `site:s3.amazonaws.com "target"`.
4. **Acquisitions:** Crunchbase/LinkedIn/press — acquired infra is almost always less hardened; `target-acquired.com` often leaks `*.target.com` keys in old repos.

## Phase 2 — Time-Travel Recon (Historical DNS, Routing, Wayback)

1. **Historical DNS:** SecurityTrails/ViewDNS history — a subdomain on `NXDOMAIN` today whose old IP `52.x.x.x` still serves the app bypasses Cloudflare/WAF entirely. → [`origin_ip_discovery_waf_bypass`](../skills/infrastructure/origin_ip_discovery_waf_bypass.md)
2. **Wayback diffs, not dumps:** `waymore -i target.com -mode U | unfurl keys | sort -u` — old API versions (`/api/v1_internal/`, `/v2_beta/`, `/admin_legacy/`); `robots.txt` 2018 vs today (disallowed entries = live shadow APIs); old JS → still-active old endpoints.
3. **CT as source of truth:** crt.sh/Censys last-5-years vs current DNS — anything in CT but not resolving = forgotten. → [`subdomain_takeover`](../skills/infrastructure/subdomain_takeover.md)

Automate 1-3 with [`time_travel_recon.sh`](../scripts/time_travel_recon.sh).

## Phase 3 — Source Code & CI/CD Leak Intelligence (Highest ROI)

1. **GitHub org intelligence:** `org:target "api.target.com"`, `org:target filename:.env`, `org:target "aws_access_key"`; employee personal repos via `"target.com" language:javascript pushed:>2023-01-01`.
2. **History, not just HEAD:** deleted secrets live in git history — `trufflehog git https://github.com/target/repo --only-verified`.
3. **CI/CD artifacts:** `Jenkinsfile`, `.github/workflows`, `terraform` leak internal hostnames, S3 buckets, shadow API URLs.
4. **Package registries:** `docker pull target/internal-api` (env vars + source), `npm view @target/api`; Postman public workspaces with live Bearer tokens.
5. **Exposed `.git`:** `httpx -path /.git/HEAD` — full source beats any payload guessing. → [`infrastructure_misconfigurations`](../skills/infrastructure/infrastructure_misconfigurations.md)

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

## Transition
Feed discovered live hosts/APIs back into the Runtime (`signals.jsonl`) for architectural inference, then into **[10 — Depth-First Web & API](10_depth_first_web_api.md)** for the depth pass.
