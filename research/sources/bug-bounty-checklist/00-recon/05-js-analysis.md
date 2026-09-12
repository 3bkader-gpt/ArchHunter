# JavaScript Analysis — The App Blueprint

JS runs client-side and leaks what the app *actually does*, not what it shows. Without JS you test the UI; with JS you test the server's real expectations. Highest ROI recon step for modern SPAs.

## What lives in the JS
- **Undocumented API endpoints** — `fetch('/api/internal/admin/delete-user?id=123')`, `/v2/private/export-all-data`. Not in HTML, robots.txt, or the Burp sitemap.
- **Hidden params** the backend forgot to validate.
- **Admin/unlinked routes** gated only by a UI `if (role==='admin')`.
- **Hardcoded secrets** — API keys, tokens, bucket names committed then minified+deployed.
- **Client-side logic** — role checks, feature flags, price math done in the browser (backend may not re-check → BOLA/IDOR/privesc).
- **Source maps** (`.js.map`) — rebuild original source with names, comments, dev-only routes.

## Fast workflow (don't read 5MB)
1. Collect every JS: crawl + `gau | grep '\.js'` + DevTools → Sources. Include `.js.map`.
2. Pretty-print (`{}` in DevTools, or `js-beautify`).
3. Auto-extract endpoints (`linkfinder`, `xnLinkFinder`, `jsluice`) and secrets (`trufflehog`, `secretfinder`).
4. `Ctrl+F` the bundle for: `api admin internal key token secret graphql endpoint upload debug staging password bearer`.
5. Rebuild from source maps: `sourcemapper -url https://t/static/js/main.js.map -output src/`.
6. Feed extracted paths/params back into fuzzers + BOLA tests.

## Secret regexes
```
(api[_-]?key|secret|token|passwd|password|bearer|authorization)\s*[:=]
AIza[0-9A-Za-z\-_]{35}          # Google API key
AKIA[0-9A-Z]{16}                # AWS access key
sk_live_[0-9a-zA-Z]{24}         # Stripe secret
ghp_[0-9A-Za-z]{36}             # GitHub PAT
xox[baprs]-[0-9A-Za-z-]+        # Slack token
eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+   # JWT
firebaseio\.com | s3\.amazonaws\.com
```

## Turn a JS find into a real request
Found in bundle:
```javascript
fetch(`/api/internal/admin/users/${id}/export`, {headers:{Authorization:`Bearer ${t}`}})
```
Replay raw against the server as a low-priv user:
```http
GET /api/internal/admin/users/1089/export HTTP/1.1
Host: api.target.com
Authorization: Bearer <your-low-priv-token>
Accept: application/json
```
`200` with data = missing function-level authz (BFLA). `1089` = a victim id you set up.

## Client-side logic flaw pattern
```javascript
if (user.role !== "admin") { showError("Not authorized"); }
else { sendRequest("/admin/delete-all"); }
```
The gate is in the browser. Call the endpoint directly:
```http
POST /admin/delete-all HTTP/1.1
Host: target.com
Cookie: session=<low-priv>
Content-Length: 0
```
Executes → privilege escalation.

## Real-world payouts from JS
- OAuth token in a public JS file → $15k (GitHub-class).
- Internal admin endpoint only in JS → SSRF → $10k (Facebook-class).
- Hardcoded API key in bundled JS → $5k (Uber-class).

## Why jsluice beats regex tools
`jsluice` parses JS with a real **AST**, not regex — so it catches **dynamically constructed** URLs/routes (`base + "/api/" + version + path`) that LinkFinder/regex miss. Four modes: `urls`, `secrets`, `tree`, `query`.
```bash
cat app.js | jsluice urls              # endpoints incl. dynamically built
cat app.js | jsluice secrets           # keys/tokens with context
katana -u https://target.com -jsl -silent | anew endpoints.txt   # jsluice inline while crawling
```

## 2025 JS-recon pipeline
```bash
# collect → beautify → mine urls+secrets → scan JS with nuclei DAST
subjs -i live.txt | anew jsfiles.txt
gau target.com | grep -Ei '\.js(\?|$)' | anew jsfiles.txt
cat jsfiles.txt | jsluice urls | anew endpoints.txt
cat jsfiles.txt | while read u; do curl -s "$u" | jsluice secrets; done | anew secrets.txt
nuclei -l jsfiles.txt -tags exposure,token -silent          # secret/exposure templates
mantra -f jsfiles.txt                                        # fast secret scanner
```
- [ ] **Source-map exposure** = jackpot: `.js.map` → `sourcemapper -url .../main.js.map -output src/` rebuilds original TS/JSX with names + comments + dev routes.
- [ ] **Dependency-confusion recon**: pull internal `@scope/pkg` names from bundles → check if unclaimed (`09-advanced/03`).
- [ ] **DOM XSS sinks**: grep AST/source for `innerHTML`, `eval`, `document.write`, `location`, `postMessage` (`05-client-side/04`).
- [ ] **Framework/build fingerprint** from chunk names + webpack runtime → tailors payloads.

## Tools
`jsluice`, `katana -jsl`, `subjs`, `linkfinder`, `xnLinkFinder`, `mantra`, `getjs`, `sourcemapper`, `trufflehog`, `secretfinder`, `nuclei`, `js-beautify`, DevTools, pathfinder (`~/scripts`).

## Deep cuts — squeeze the bundle dry
- [ ] **Webpack chunk enumeration:** the runtime holds a chunk-id → filename map (`{0:"main",42:"admin.chunk"}`). Extract it, then fetch every lazy chunk directly — admin/settings/billing routes are code-split and never loaded for a normal user, but the JS is public. Regex the runtime for `\.push\(\[\[` and the chunk map object.
- [ ] **Source-map brute even when not referenced:** try `<bundle>.map`, and for Next.js pull `/_next/static/<buildId>/_buildManifest.js` → lists every page/route + their chunks. `<script src>` minus `//# sourceMappingURL` sometimes still has the `.map` deployed.
- [ ] **Service worker** (`/sw.js`, `/service-worker.js`): precache manifest lists every asset/route the app knows; also a postMessage + fetch-intercept attack surface (`05-client-side/04`).
- [ ] **WASM modules** (`.wasm`): `wasm2wat` / `wasm-decompile` → business logic, embedded secrets, license checks moved client-side.
- [ ] **Env/config JSON:** `/config.json`, `/env.js`, `window.__ENV`, `__NEXT_DATA__`, `__NUXT__`, `runtime-config` — front-end config often ships API base URLs, feature flags, tenant IDs, publishable keys, and sometimes a secret that shouldn't be there.
- [ ] **GraphQL from JS:** grep for `gql`\`, `query `, `mutation `, and persisted-query hashes → recover the full operation set without introspection (`07-api/02`).
- [ ] **SRI + integrity hints:** `integrity=` attrs and importmaps reveal exact dependency versions → `retire.js` CVE match.
- [ ] **Comments & TODOs in source maps:** rebuilt source often contains dev credentials, staging URLs, `// FIXME auth disabled`, and internal ticket refs.
- [ ] **`postMessage`/`addEventListener('message'` handlers:** list every origin check (or lack of) for `04-postmessage-dom`.

## Sources
Bishop Fox — jsluice deep-dive; ReconFTW JS module; "Hunting Sensitive Data Leaks in JavaScript" (samael0x4); PortSwigger — web-message + DOM sink research.

## Report notes
A key is a finding only if it grants access or costs money. Prove impact minimally (identity call, one bucket list), never dump/pivot.
