# Cross-Site Request Forgery (CSRF)

**What it is:** Victim's browser is tricked into sending an authenticated state-changing request they did not intend.

## Where to look
State-changing actions: change email/password, add address, transfer, post content, change settings, link accounts, delete.

## Test steps
- [ ] Remove the CSRF token → request still succeeds?
- [ ] Use another user's / a blank / a malformed token → accepted?
- [ ] Token not tied to session (any valid token works).
- [ ] Change method `POST→GET` and drop the token.
- [ ] `SameSite` cookie missing/`None` → cross-site cookie sent.
- [ ] JSON endpoint: switch `Content-Type` to `text/plain`/form, does it still parse? (enables HTML-form CSRF).
- [ ] Token only checked when present (omit the header entirely).
- [ ] Referer/Origin check bypass: omit Referer, or match via `evil.com?target.com`.
- [ ] CSRF on login (login CSRF) / logout / OAuth (see oauth file).

## PoC
```html
<form action="https://target/account/email" method="POST">
  <input name="email" value="attacker@evil.com">
</form>
<script>document.forms[0].submit()</script>
```
JSON via fetch (if CORS/simple-request allows) or `text/plain` trick.

## Impact
Account takeover (email/password change), unwanted actions, fund transfer.

## 🎯 PoC — Request → Response (token not tied to session)

Cross-site form submits the victim's browser cookie; server accepts a missing/foreign token:
```http
POST /api/v1/account/email HTTP/1.1
Host: target.com
Origin: https://evil.com
Cookie: session=<victim, sent because SameSite=None>
Content-Type: application/x-www-form-urlencoded

email=attacker@evil.com
```
```http
HTTP/1.1 200 OK
Content-Type: application/json

{"email":"attacker@evil.com","status":"updated"}    ← no CSRF token required = ATO
```
Victim's account email now points to attacker → password reset → takeover.

## Deep cuts — SameSite-era CSRF that still works
- [ ] **`SameSite=Lax` is not immunity:** it still sends on **top-level GET navigations** → any state-changing GET (or a `POST` the app also accepts as GET, or `?_method=PUT` override) is CSRF-able via `window.location`/a link. Chrome's "Lax+POST" 2-minute grace window on freshly-set cookies also allows cross-site POST right after login.
- [ ] **Method-override smuggling:** send `POST` with `_method=DELETE`/`X-HTTP-Method-Override: PUT` so a simple form reaches a non-simple verb.
- [ ] **JSON endpoint via `text/plain`:** `<form enctype="text/plain">` with a single field named `{"email":"a@evil.com","x":"` value `"}` reconstructs valid JSON server-side if it doesn't enforce `Content-Type` — no preflight, no token.
- [ ] **Token defeat, not token presence:** extract the CSRF token via reflected/`GET`-leak/CORS read, or overwrite the double-submit cookie via **cookie tossing** from a subdomain (`04-auth-session/07`) so your forged value matches.
- [ ] **Token reuse / not-per-session:** one static token, a token from a fresh anon session, or a blank token accepted when the param is present-but-empty.
- [ ] **Referer/Origin check bypasses:** omit `Referer` (`<meta name=referrer content=no-referrer>` or `rel=noreferrer`), `https://evil.com/target.com`, `https://target.com.evil.com`, `Origin: null` (sandboxed iframe/data-URI), or the check only runs when the header is present.
- [ ] **307/308 redirect preserves method+body:** bounce a cross-site POST through a redirect that keeps the body → lands the forged JSON/form.
- [ ] **CSWSH is CSRF for WebSockets:** the handshake sends cookies with no token (`05-client-side/07`).
- [ ] **GET-based sensitive actions / login-logout CSRF / OAuth-link CSRF** — enumerate every state change reachable by navigation.

## Report notes
Provide a working HTML PoC that fires the action for a logged-in victim. Show `SameSite`/token weakness that allows it. Modern browsers default `SameSite=Lax` — confirm the bug is real (top-level GET, method-override, Lax+POST window, or token defeat) and name which one.
