# HTTP Request Smuggling

**What it is:** Front-end and back-end disagree on where one request ends → smuggle a partial request that poisons the next user's traffic.

## Variants
- **CL.TE** — front-end uses `Content-Length`, back-end uses `Transfer-Encoding`.
- **TE.CL** — reverse.
- **TE.TE** — both support TE but one is tricked by an obfuscated header.
- **CL.0 / H2.CL / H2.TE** — HTTP/2 downgrade desync.

## Detection (timing-based, safe)
- [ ] Send crafted CL/TE combos, measure delay (a smuggled prefix stalls the socket).
- [ ] TE obfuscation: `Transfer-Encoding: chunked` variants — space, tab, `x`, double header, `\r\nTransfer-Encoding : chunked`.
- [ ] Use `~/scripts` smuggler tool (CL.TE/TE.CL/TE.TE + CRLF, timing-only detection).
- [ ] Burp **HTTP Request Smuggler** extension.

## Escalation (with care)
Cache poisoning, credential/session capture of the next request, bypass front-end auth/WAF, forced redirect. **Do not** capture real users' requests at scale.

## Impact
Mass session hijack, cache poisoning, security-control bypass. High/critical.

## 🎯 PoC — Request → Response (CL.TE timing confirmation)

Front-end reads `Content-Length`, back-end reads `Transfer-Encoding`. The `0\r\n\r\n` ends the request for the back-end, leaving `X` to stall the socket:
```http
POST / HTTP/1.1
Host: target.com
Content-Length: 4
Transfer-Encoding: chunked

1
A
X
```
```http
HTTP/1.1 200 OK
# ...response returns only after ~10s timeout waiting for the dangling "X"
```
Normal request returns instantly; this one hangs → the two servers disagree = CL.TE desync confirmed. Safe, timing-only, no victim traffic touched.

## Report notes
Timing-based confirmation is enough to report; if demonstrating impact, do it against your own second request. Avoid harvesting third-party data.

## Deep cuts — HTTP/2, client-side desync, and modern variants
- [ ] **H2.CL / H2.TE downgrade:** an HTTP/2 front-end that rewrites to HTTP/1.1 to the back-end, honoring an attacker `content-length`/`transfer-encoding` in the h2 request → classic desync after downgrade. Also **h2c smuggling** (`Upgrade: h2c`) to tunnel past the front-end (`h2csmuggler`).
- [ ] **CRLF/newline in h2 header values:** inject `\r\n` (or bare `\n`) into an HTTP/2 header name/value → splits into extra headers/request on downgrade (header/request injection).
- [ ] **CL.0 / 0.CL:** the back-end ignores the body (`Content-Length` treated as 0) on certain endpoints (static, redirects, 301/302) → the body is parsed as the next request. Great where TE is stripped.
- [ ] **Client-side desync (browser-powered):** a desync you can trigger from a victim's browser via `fetch` (no proxy needed) — poisons *their* connection to steal their next request/creds. Higher impact, self-contained PoC.
- [ ] **Response-queue poisoning:** desync so one victim receives *another* user's response (session/data theft) — confirm only against your own paired requests.
- [ ] **Request tunnelling:** smuggle a full second request to a back-end path the front-end would block (auth/WAF bypass, reach internal-only routes).
- [ ] **TE obfuscation zoo:** `Transfer-Encoding:\tchunked`, `Transfer-Encoding : chunked`, `Transfer-Encoding: chunked\r\nTransfer-Encoding: x`, `Transfer-Encoding: chunked` + space/vtab, duplicate/space-prefixed headers, `Content-Length` with leading `+`/whitespace.
- [ ] **Detect with Burp Turbo/HTTP Request Smuggler** (timing + differential), then confirm on your own follow-up request only. Full LB/proxy-desync deep dive: `10-server-edge/02`.

## Tools
`~/scripts` smuggler, Burp HTTP Request Smuggler, `smuggler.py`, `h2csmuggler`, `turbo-intruder`.
