# Load Balancer / Reverse Proxy Desync & Routing Abuse

**What it is:** Multi-tier setups (LB → proxy → app) disagree on parsing/routing → smuggling, header trust, host routing, connection reuse leaks.

## HTTP request smuggling (full variants)
Front and back disagree on where a request ends. Confirm timing-based first (safe).

### CL.TE
Front uses `Content-Length`, back uses `Transfer-Encoding`:
```http
POST / HTTP/1.1
Host: target.com
Content-Length: 6
Transfer-Encoding: chunked

0

G
```
Back sees `0\r\n\r\n` (end), leaves `G` prefixing the next request.

### TE.CL
```http
POST / HTTP/1.1
Host: target.com
Content-Length: 4
Transfer-Encoding: chunked

5c
GPOST / HTTP/1.1
Host: target.com

0

```

### TE obfuscation (TE.TE — one side ignores it)
```
Transfer-Encoding: chunked
Transfer-Encoding : chunked        (space before colon)
Transfer-Encoding:\tchunked        (tab)
Transfer-Encoding: xchunked
X: x\nTransfer-Encoding: chunked
Transfer-Encoding
 : chunked                         (folded)
```

### CL.0 / H2 desync
HTTP/2 → HTTP/1.1 downgrade where back-end ignores CL, or front-end forwards a body the back-end treats as a new request. Test `h2c` smuggling, `h2.tE`, header-name/value injection via HTTP/2 pseudo-headers.

### Escalation
Poison the next visitor's request → capture their session/credentials, force redirect, cache-poison, bypass front-end auth/WAF. **Demo only against your own second request.**

## Header trust (LB → app)
App trusts LB-injected headers; attacker sets them directly if the LB doesn't strip:
```http
GET /admin HTTP/1.1
Host: target.com
X-Forwarded-For: 127.0.0.1
X-Forwarded-Host: internal-admin
X-Forwarded-Proto: https
X-Real-IP: 127.0.0.1
X-Original-URL: /admin
X-Rewrite-URL: /admin
True-Client-IP: 127.0.0.1
```
- IP allowlist bypass (`X-Forwarded-For: 127.0.0.1` → "internal" access).
- Auth-header trust (`X-Forwarded-User`, `X-Auth-Request-User` from a mis-scoped SSO proxy).
- Path override (`X-Original-URL`/`X-Rewrite-URL`) → reach blocked routes.

## Host header routing abuse
```http
GET / HTTP/1.1
Host: internal-app.local
```
- Reach internal vhosts routed by Host.
- Password-reset poisoning (see auth/05), cache poisoning (see 03), SSRF via routing.
- Absolute-URI + Host mismatch: `GET https://evil.com/ HTTP/1.1` with `Host: target.com`.

## Connection reuse / cross-request leakage
Back-end keep-alive pools shared across users + a desync → response of user A served to user B. Detect via odd `Set-Cookie`/`Content-Length` mismatches after a crafted request.

## Detection
- [ ] Burp **HTTP Request Smuggler** (timing + differential probes).
- [ ] `~/scripts` smuggler (CL.TE/TE.CL/TE.TE + CRLF, timing-only).
- [ ] `h2csmuggler`, `smuggler.py`.
- [ ] Header-trust: fuzz the `X-Forwarded-*`/`X-Original-URL` set on protected routes.

## Impact
Mass session hijack, WAF/auth bypass, cache poisoning, internal access. Critical.

## Deep cuts — 2024–2025 desync classes & header smuggling
- [ ] **Client-side desync (browser-triggered):** a `Content-Length`-honoring back-end on a POST endpoint that ignores the body lets a victim's own browser (`fetch`, `credentials:include`) poison its connection → self-contained ATO PoC, no proxy. High impact, easy to demo safely on yourself.
- [ ] **CL.0 / 0.CL:** back-end treats `Content-Length` as 0 on some routes (redirects, static, OPTIONS) → the body becomes the next request. Hunt endpoints that reply without reading the body.
- [ ] **Response-queue poisoning:** desync so responses shift by one → the next client gets *your* response or you get *theirs* (session/data theft). Confirm only against your paired requests.
- [ ] **Request tunnelling:** smuggle a complete second request past the front-end to a blocked path (WAF/auth bypass, internal-only routes) even when full desync isn't possible.
- [ ] **Connection-state / first-request routing:** some proxies route the whole keep-alive connection based on the *first* request's Host/auth → send a benign first request, then smuggle to a different vhost/backend on the same connection.
- [ ] **`Connection`-header hop-by-hop stripping:** `Connection: X-Auth-User` (or `close`) makes an intermediary drop the named header before the origin → strip a security header, or smuggle by removing `Content-Length`/`Transfer-Encoding` on one hop.
- [ ] **HTTP/2 downgrade specifics:** H2.CL/H2.TE, CRLF/newline in h2 header values (request injection), `:path`/`:authority` splitting, and h2c upgrade smuggling (`h2csmuggler`).
- [ ] **Trusted proxy headers (repeat, high-yield):** `X-Forwarded-For: 127.0.0.1` (IP allowlist), `X-Forwarded-User`/`X-Auth-Request-User` from a mis-scoped oauth2-proxy, `X-Original-URL`/`X-Rewrite-URL` path override — test the full set on every guarded route (`01-access-control/04`).

## Report notes
Timing confirmation is reportable. For impact, target only your own follow-up request (or your own browser for client-side desync). Never harvest third-party traffic. Name the exact variant.
