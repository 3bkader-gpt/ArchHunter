# Content & Endpoint Discovery

**What it is:** Finding hidden paths, params, files, and endpoints the UI never links to. Old admin panels, backups, debug routes, API docs.

## Checklist
- [ ] Crawl: `katana`, `hakrawler`, Burp crawl. Capture in-scope URLs + params.
- [ ] Historical URLs: `gau`, `waybackurls`, `urlfinder`, commoncrawl.
- [ ] Directory/file brute: `feroxbuster` / `ffuf` with `raft`/`seclists` wordlists.
- [ ] Extensions: `.bak .old .zip .tar.gz .sql .env .git .DS_Store .swp .json .config`.
- [ ] `.git/` exposed? → `git-dumper`. `.env`, `.svn`, `.hg` too.
- [ ] Backup of the app: `www.zip`, `site.tar.gz`, `backup.sql`.
- [ ] API docs: `/swagger`, `/api-docs`, `/openapi.json`, `/graphql`, `/redoc`, `/actuator`.
- [ ] Debug/status: `/debug`, `/status`, `/metrics`, `/actuator/*`, `/_profiler`, `/server-status`.
- [ ] Soft-404 aware fuzzing (baseline a random path, diff length/words). Use `~/scripts` pathfinder tool.
- [ ] Param mining: `arjun`, `paramspider`, `x8` on each endpoint.

## Recursion
Feed discovered dirs back into the fuzzer. `feroxbuster` recurses by default; cap depth to avoid loops.

## 2025 crawl → scan pipeline
```bash
# crawl (incl. JS-derived endpoints) → live → nuclei DAST for reflected/injection sinks
katana -u https://target.com -jc -jsl -kf all -d 3 -silent | anew urls.txt
gau --threads 5 target.com | anew urls.txt
httpx -l urls.txt -mc 200,301,302,401,403 -o live_urls.txt
nuclei -l live_urls.txt -dast -tags xss,sqli,ssrf,redirect -silent
```
- [ ] **`katana -jsl`** runs jsluice inline → pulls endpoints/params straight out of JS while crawling.
- [ ] **API route brute:** `kiterunner scan target.com -w routes-large.kite` — finds REST routes wordlists miss (verb-aware).
- [ ] **Auth'd vs unauth'd diff:** crawl once logged in, once out; diff to find forced-browsing / missing authz (`01-access-control/04`).
- [ ] **Recursion + extensions tuned to stack** (from `04-fingerprinting.md`): PHP→`.php .phps .bak`, ASPX→`.asmx .config`.
- [ ] **`robots.txt`, `sitemap.xml`, `security.txt`, `.well-known/`** — free disallowed paths and hidden endpoints.
- [ ] **Param mining at scale:** `arjun -i live_urls.txt` + `x8` per interesting endpoint; feed to nuclei DAST.

## Deep cuts — endpoints the wordlist won't give you
- [ ] **HTTP method enumeration per path:** `OPTIONS` (read `Allow:`), then try `PUT/DELETE/PATCH/PROPFIND/TRACE`. A `PUT` that writes = instant RCE/defacement; hidden `PATCH` often skips authz.
- [ ] **`.well-known/` sweep:** `openid-configuration` (leaks all OAuth/token/JWKS endpoints + supported flows), `security.txt`, `assetlinks.json`, `apple-app-site-association`, `change-password`, `mta-sts.txt`, `oauth-authorization-server`.
- [ ] **GraphQL surface:** probe `/graphql /graphiql /v1/graphql /api/graphql /query`; if up, introspection → full schema (`07-api/02`).
- [ ] **Stack-tuned backup permutations:** for host `app.target.com` generate `app.zip app.tar.gz app.sql app.bak backup-YYYY.zip .env.bak config.php~ web.config.old .git/config .DS_Store` — auto with `bfac`/`fuzz` list; date-stamp the year and last two.
- [ ] **Actuator/framework consoles:** `/actuator/{env,heapdump,mappings,gateway/routes}` (Spring), `/console` (H2/Jolokia), `/_next/` (Next build id → source), `/api/swagger.json`, `/telescope`, `/horizon`, `/_ignition/execute-solution` (Laravel debug RCE).
- [ ] **Parameter-pollution & hidden-verb discovery:** `arjun` with `--headers` and both `GET`+`POST`; mine params that toggle debug/admin (`debug=1`, `admin=true`, `test`, `internal`, `format=`, `callback=`).
- [ ] **Virtual-host-scoped content:** re-run discovery against each `Host:` (some paths only exist on the internal vhost served by the same IP).
- [ ] **Cache-key / cache-buster params:** discover params ignored by cache but reflected (`?cb=`, `?utm_`) → seed for cache poisoning (`08-infra/03`).
- [ ] **Recursive + auth-state diff at scale:** run the pipeline logged-out and logged-in, `anew`-diff the two URL sets → forced-browsing candidates.
- [ ] **403/401 don't stop you:** feed every `40x` path into `/bypass-403` (`10-server-edge/04`) before discarding.

## Tools
`ffuf`, `feroxbuster`, `katana` (`-jsl`), `gau`, `waybackurls`, `kiterunner`, `arjun`, `x8`, `nuclei` (`-dast`), `git-dumper`, `bfac`, byp4xx, pathfinder (`~/scripts`).

## Report notes
For an exposed file, show the sensitive content, not just the 200. `/backup.sql` returning 200 but empty is not a finding.
