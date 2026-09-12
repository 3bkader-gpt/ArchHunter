# Registration + Login — One-Path Methodology

The ordered walkthrough for attacking the auth surface end-to-end. Follow top to bottom. Each step links to the deep file for payloads/PoCs. Work with **two accounts** (attacker + victim) and a proxy on from the first request.

```
MAP → REGISTER → VERIFY → LOGIN → MFA → SESSION → RESET/RECOVERY → CROSS-CUTTING
```

---

## 0. Map the auth surface (before touching anything)
- [ ] Enumerate every auth endpoint: `/register /signup /login /auth/token /oauth /sso /verify /forgot /reset /mfa /magic-link /invite`. Include **mobile/API** versions (`/api/v1/auth/*`) — they often skip web checks.
- [ ] Mine JS for hidden auth routes, client-side role checks, keys (`00-recon/05-js-analysis.md`).
- [ ] Note the token type: cookie / JWT / opaque (`04-auth-session/03-jwt.md`).
- [ ] Note the content-type it accepts (JSON/form/XML) — used later for confusion tests.

---

## 1. Registration
Order: create → tamper shape → tamper identity → tamper privilege.

- [ ] **Baseline:** register normally, capture the request. This is your mutation base.
- [ ] **JSON shape fuzzing** — type-confusion / null / arrays / malformed / extra keys → `04-auth-session/08-json-auth-fuzzing.md`.
- [ ] **Privileged self-registration (mass assignment):** add `role/isAdmin/verified/plan/tenant` to the body → `07-api/03-mass-assignment.md`.
- [ ] **Account overwrite / dedupe bypass:** same email with case change, trailing space, unicode homoglyph, `+alias`, dots, `"victim@x"@evil` → `09-advanced/04-parser-differentials.md`, `04-auth-session/01-login-and-registration.md`.
- [ ] **Privileged email/domain:** register `admin@target`, or a corp-domain email to auto-join an org/tenant → `01-access-control/05-cross-tenant-isolation.md`.
- [ ] **Skip/forge verification:** use the account before email verify; set `email_verified:true`.
- [ ] **Enumeration on signup:** "email already taken" reveals valid users → `04-auth-session/01`.
- [ ] **Injection in profile fields** (name/company/bio) — seed second-order tracers now, they fire in admin views later → `09-advanced/01-second-order.md`.
- [ ] **Weak password policy / breached passwords accepted.**
- [ ] **Rate limit / CAPTCHA bypass** on signup (mass account creation) → `07-api/04-rate-limiting.md`.

---

## 2. Verification (email / phone)
- [ ] Verification code brute (no rate limit, short code) → `04-auth-session/02-2fa-otp.md` logic applies.
- [ ] Verify link/token: predictable, reusable, no expiry, not bound to user.
- [ ] Confirmation sent only to the new address, no notice to old → `04-auth-session/09-email-invite-flow-abuse.md`.
- [ ] Response-manipulation "verified:true" — **prove server-side** → `99-reference/05-response-manipulation-and-verification.md`.

---

## 3. Login
- [ ] **Username/account enumeration** — message + timing + status/length diff (valid vs invalid) → `04-auth-session/01`.
- [ ] **Brute / credential stuffing** — missing/weak lockout; bypass rate limit by rotating `X-Forwarded-For`, casing, param pollution, GraphQL/REST batching → `07-api/04`.
- [ ] **JSON shape fuzzing on login** — `{"password":{"$ne":null}}` NoSQLi bypass, arrays, null → `04-auth-session/08` + `03-injection/07-nosql-and-misc.md`.
- [ ] **SQLi in login** (`admin' -- `) → `03-injection/01-sqli.md`.
- [ ] **Login CSRF** (no state/token) → force victim into attacker account → `05-client-side/01-csrf.md`.
- [ ] **OAuth/SSO login** — `redirect_uri` tamper, missing `state`, code theft, account linking, IdP email trust → `04-auth-session/04-oauth-sso.md`.
- [ ] **Magic-link / passwordless** — reuse, no expiry, not device-bound → `04-auth-session/09`.
- [ ] **Response-manipulation** login success flip — verify against a protected API, no edits → `99-reference/05`.
- [ ] **Default / test creds**, debug login endpoints, `?debug=1`.

---

## 4. MFA / 2FA (if present)
- [ ] OTP brute (no rate limit), race the attempt counter → `04-auth-session/02-2fa-otp.md`.
- [ ] Skip the step (go straight to post-MFA endpoint), missing MFA on mobile/OAuth flow.
- [ ] Change phone/email in the verify request so OTP goes to attacker.
- [ ] Backup codes: unlimited/predictable.
- [ ] Response-manipulation MFA bypass — confirm the returned session works on protected APIs.
- [ ] Enable/disable victim's MFA via IDOR/CSRF.

---

## 5. Session (right after you get one)
- [ ] **Session fixation:** compare the session ID before vs after login — not rotated = fixation → `04-auth-session/07-session-hijacking.md`.
- [ ] **JWT attacks:** `alg:none`, RS256→HS256, `sub`/`role` tamper, weak secret, no-expiry → `04-auth-session/03-jwt.md`.
- [ ] **Cookie flags:** `HttpOnly`, `Secure`, `SameSite`, over-broad `Domain`, missing `__Host-` → `05-client-side/06-security-headers-bypass.md`.
- [ ] **Cookie tossing** from a subdomain to override parent session/CSRF → `04-auth-session/07`.
- [ ] **Token in URL / referer leak.**
- [ ] **Logout doesn't invalidate token; concurrent sessions unlimited** → `04-auth-session/06-session-management.md`.

---

## 6. Reset / recovery
- [ ] **Host-header reset poisoning** → link to attacker → `04-auth-session/05-password-reset.md`, `09-advanced/09-host-header-injection.md`.
- [ ] **HPP second recipient** (`email=victim&email=attacker`).
- [ ] **Weak/reusable/no-expiry token; token not bound to user; IDOR on set-password.**
- [ ] **Reset for deactivated accounts; old sessions survive reset (state desync)** → `09-advanced/10-state-desync.md`.
- [ ] **OTP-reset brute / race.**

---

## 7. Cross-cutting (run against every step above)
- [ ] **IDOR/BOLA** on any user id in auth requests (change email/password/MFA for another user) → `01-access-control/01-idor-bola.md`.
- [ ] **Mass assignment** of privilege fields on any create/update.
- [ ] **Race conditions:** double-register same unique resource, MFA attempt-counter race, reset-token race → `02-business-logic/07-race-conditions.md`.
- [ ] **State desync:** disabled/unverified account still hits gated actions; token valid after revoke → `09-advanced/10`.
- [ ] **Parser differentials:** email/host/JSON confusion binding the wrong identity → `09-advanced/04`.
- [ ] **Response vs request tampering discipline** — every "flip" must be confirmed server-side → `99-reference/05`.
- [ ] **Cross-tenant:** does registration/login bind you into another org? → `01-access-control/05`.

---

## Quick decision path
```
See an ID in an auth request?          → IDOR (01/01)
See a JSON body?                        → shape-fuzz it (04/08) + NoSQLi (03/07)
See a token/cookie?                     → JWT (04/03) + session/fixation (04/07)
See OAuth/SSO?                          → redirect/state/linking (04/04)
See email/verify/reset/invite?         → flow-abuse logic (04/09, 04/05)
Any success flag flipped?              → verify server-side (99/05)
Two accounts differ?                   → diff every response
```

## Golden checks
- Two accounts, proxy on, diff everything.
- Request tamper = real; response tamper = prove it server-side.
- Test the API/mobile auth paths, not just the web form.
- One valid proof per bug; never brute real users' accounts.

## Passkeys / WebAuthn / federation (modern front doors)
- [ ] **WebAuthn downgrade:** app offers passkey *and* password/OTP fallback → force the weaker factor (remove the passkey step, hit the password endpoint directly).
- [ ] **Registration ceremony tamper:** swap `user.id`/`rp.id` in the `create()` options, or register your authenticator against a victim's account if the challenge isn't bound.
- [ ] **`rpId` / origin mismatch:** if the server accepts a broad `rpId` (parent domain) a sibling/subdomain can complete the ceremony (pairs with cookie-tossing, `07`).
- [ ] **SCIM / JIT provisioning:** SSO auto-creates accounts from an assertion — email-trust or attribute injection lands you in the wrong org/role (`10-saml`, `04-oauth-sso`, `01-access-control/05`).
- [ ] **Device-code & CIBA flows:** phishable `user_code`, no binding, pollable token endpoint (`04-oauth-sso`).

## Related deep files
`01-login-and-registration` · `02-2fa-otp` · `03-jwt` · `04-oauth-sso` · `05-password-reset` · `06-session-management` · `07-session-hijacking` · `08-json-auth-fuzzing` · `09-email-invite-flow-abuse` · `10-saml`
