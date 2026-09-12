# Login & Registration

**What it is:** Flaws in the front door: enumeration, brute force, weak lockout, and registration abuse.

## Username / account enumeration
- [ ] Different error for valid vs invalid user ("no such user" vs "wrong password").
- [ ] Timing difference (valid user hashes password, invalid returns fast).
- [ ] Response length/status/redirect difference.
- [ ] Registration "email already taken", password-reset "email sent" vs "not found".
- [ ] Admin/staff signin API enumeration.

## Brute force / credential stuffing
- [ ] No rate limit / weak lockout on login, OTP, reset.
- [ ] Rate limit bypass: rotate `X-Forwarded-For`, casing, trailing dot/slash, param pollution.
- [ ] Lockout on username but not IP (or vice versa) → still exploitable.

## Registration abuse
- [ ] Register privileged email domains / `admin@target`.
- [ ] Overwrite existing account (same email, different case/unicode, trailing space).
- [ ] Mass-assignment of `role`/`verified`/`plan` at signup (see `07-api/03`).
- [ ] Skip email verification and use the account.
- [ ] `+alias` / dot tricks / unicode homoglyphs to bypass uniqueness or verification.

## Weak credential policy
- [ ] Accepts weak/known-breached passwords, no length check.

## Impact
Account takeover, enumeration feeding targeted attacks, privileged registration.

## Tools
Burp Intruder, `ffuf`, timing scripts.

## 🎯 PoC — Request → Response (user enumeration)

**Valid user:**
```http
POST /api/v1/auth/login HTTP/2
Host: api.target.com
Content-Type: application/json

{"email":"admin@target.com","password":"wrong"}
```
```http
HTTP/2 401 Unauthorized
{"error":"invalid_password"}          ← distinct message + ~180ms (bcrypt ran)
```
**Invalid user:**
```http
POST /api/v1/auth/login HTTP/2
Content-Type: application/json

{"email":"nobody@target.com","password":"wrong"}
```
```http
HTTP/2 401 Unauthorized
{"error":"user_not_found"}            ← different message + ~12ms (no hash)
```
Message + timing oracle = valid-account enumeration.

## Deep cuts — enum sources & anti-bruteforce bypasses
- [ ] **Enumeration beyond login:** signup ("taken"), reset ("sent"/"not found"), SSO-discovery (`/sso?email=` reveals which domains federate), invite, `/api/users/exists`, GraphQL `user(email:)`, and profile-URL 200-vs-404. Timing works even when messages are unified (bcrypt-run vs early-return).
- [ ] **Password spraying (not brute):** one common password across many enumerated users beats per-account lockout; low-and-slow to dodge velocity checks.
- [ ] **Rate-limit bypass matrix:** rotate `X-Forwarded-For`/`X-Real-IP`/`X-Client-IP`/`True-Client-IP`/`CF-Connecting-IP`, casing/whitespace/dot on the username, HTTP/2 or GraphQL batching (`07-api/04`), reset the counter via a parallel endpoint, or hit the **origin** to skip the edge limiter (`10-server-edge/04`).
- [ ] **Lockout asymmetry / DoS:** lockout keyed on username → lock a victim out on purpose (account DoS); keyed on IP only → rotate and keep going.
- [ ] **CAPTCHA bypass:** token reuse across requests, empty/known-answer, solve-once-use-many, missing server-side verify, `g-recaptcha-response` from a sibling site, or CAPTCHA only on the web form not the API.
- [ ] **Registration race:** two parallel signups claim the same unique email/username/slug (`02-business-logic/07`), or one wins a "first admin" bootstrap.
- [ ] **Account pre-hijack / merge:** register the victim's email *before* they sign up via SSO → later OAuth login merges into your pre-created (attacker-owned) account.
- [ ] **Unicode/normalization dedupe bypass:** `ᴀdmin`, `admin`+ZWSP, `Admin `, `admin@x.com` vs `admin@X.COM`, `"admin@x"@evil.com` — uniqueness check and later lookup disagree (`09-advanced/04`).
- [ ] **Breached-password / policy check only client-side** (submit weak via API).

## Report notes
For enumeration show the distinguishable signal (two responses side by side, incl. timing). For brute force show missing/broken rate limit; do not actually crack real accounts. For pre-hijack, show the merge landing in your account.
