# HTTP Quirks, Methods & Header Abuse

**What it is:** Protocol-level oddities and header handling gaps at the server/proxy layer. Cheap to test, often overlooked.

## Method abuse
- [ ] `TRACE` enabled → Cross-Site Tracing (reflects headers, cookie theft on old stacks).
- [ ] `PUT`/`DELETE` allowed → upload/delete files directly:
```http
PUT /shell.jsp HTTP/1.1
Host: target.com
Content-Length: 20

<% ...jsp... %>
```
- [ ] `OPTIONS` reveals `Allow:` methods.
- [ ] Method override → reach a blocked verb:
```http
POST /admin/users/1 HTTP/1.1
X-HTTP-Method-Override: DELETE
```
Also `X-Method-Override`, `_method=DELETE`.
- [ ] Arbitrary/unknown method sometimes bypasses auth filters bound to `GET`/`POST`:
```http
FOO /admin HTTP/1.1
```

## Range / partial content
- [ ] `Range: bytes=0-0` → `206`; used for cache splitting & WAF body-inspection bypass.
- [ ] Multiple ranges → response-size amplification / DoS.
- [ ] `Range` past EOF → `416`; behavior differentials for cache poisoning.

## Expect / 100-continue & 0.9
- [ ] `Expect: 100-continue` handling differentials between proxy and origin (desync aid).
- [ ] HTTP/0.9 downgrade (`GET /` no version) → some servers respond raw, bypassing headers/WAF.

## Header quirks
- [ ] Duplicate `Host` / `Host` + `:authority` (H2) mismatch → routing confusion.
- [ ] Header injection via CRLF in reflected values (`%0d%0a`) → response splitting, `Set-Cookie` injection.
- [ ] Oversized / many headers → 400 (CPDoS, see `03`).
- [ ] `Transfer-Encoding` obfuscation → smuggling (see `02`).
- [ ] Missing security headers (report as info): `HSTS`, `CSP`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`.
- [ ] `Content-Type` sniffing (no `nosniff`) → uploaded text served as HTML → XSS.

## Response splitting / smuggling via header reflection
```http
GET /set?lang=en%0d%0aSet-Cookie:%20sess=attacker HTTP/1.1
```
If `lang` reflects into a response header from a proxy/app variable → inject headers.

## Verb-based auth bypass
Route protected for `GET` but not `HEAD`/`POST`/custom → data leak via the unguarded verb. `HEAD` may reveal `Content-Length`/headers of a protected page.

## Detection
- [ ] `curl -X OPTIONS -i`, method fuzz with Burp.
- [ ] `nuclei` http misconfig/exposures templates for methods & headers.

## Impact
File write/delete (PUT), method-based auth bypass, response splitting → XSS/cache poison, MIME-sniff XSS, DoS.

## 🎯 PoC — Request → Response (method-override reaches a blocked verb)

`DELETE` is blocked at the edge, but the app honors the override header:
```http
POST /api/v2/users/9c8b7a6d-1e2f-4a3b-8c9d-0e1f2a3b4c5d HTTP/2
Host: api.target.com
Authorization: Bearer <low-priv>
X-HTTP-Method-Override: DELETE
Content-Length: 0
```
```http
HTTP/2 200 OK
{"deleted":"9c8b7a6d-1e2f-4a3b-8c9d-0e1f2a3b4c5d"}    ← DELETE executed via POST
```

**HEAD leaks a protected page's metadata (route guarded only for GET):**
```http
HEAD /admin/export.csv HTTP/2
Host: target.com
Cookie: session=<low-priv>
```
```http
HTTP/2 200 OK
Content-Length: 91234
Content-Disposition: attachment; filename="export.csv"   ← should have been 403
```

## Deep cuts — HTTP/2, HTTP/3, and hop-by-hop tricks
- [ ] **`Connection` hop-by-hop abuse:** `Connection: X-Real-IP` (or any header name) makes a compliant proxy strip that header before the origin → drop a security/auth header the origin relies on; or `Connection: keep-alive, close` state games.
- [ ] **HTTP/2 CONTINUATION flood (CVE-2024-27316-class) & Rapid Reset (CVE-2023-44487):** header-frame / stream-reset floods = DoS — **report-only**, describe the vector, don't run on prod.
- [ ] **h2 pseudo-header injection:** CRLF/newline in `:path`/`:authority`/header values on HTTP/2 → request splitting on downgrade (`08-infra/02`); malformed `:method`/`:scheme`.
- [ ] **HTTP/3 / QUIC parity:** endpoints reachable over h3 may skip an h1/h2-only WAF or apply different limits — test the same payloads over QUIC.
- [ ] **`Expect: 100-continue` desync:** proxy-vs-origin disagreement on the continue handshake aids smuggling; also `Expect: 100-continue` with a large body to probe buffering.
- [ ] **Chunked extensions / trailers:** `Transfer-Encoding: chunked` with chunk-extensions (`1;ext=x\r\n`) and trailing headers after the last chunk — parsers disagree (smuggling + header injection).
- [ ] **`Content-Length` oddities:** negative, leading `+`, multiple CL, CL+TE together, whitespace-padded → desync.
- [ ] **HTTP/0.9 / raw downgrade:** `GET /` with no version → some servers reply header-less, bypassing WAF/security headers.
- [ ] **Verb/override matrix (repeat):** `HEAD`/`OPTIONS`/`TRACE`/arbitrary verb + `X-HTTP-Method-Override`/`_method` to reach guarded actions (`01-access-control/04`).

## Report notes
Show the quirk producing a concrete effect (file written, header injected, protected route reached, header stripped). DoS-class quirks (CONTINUATION/Rapid Reset/range amplification): report the vector, do not execute on prod. Missing-header findings: informational unless you show exploitation.
