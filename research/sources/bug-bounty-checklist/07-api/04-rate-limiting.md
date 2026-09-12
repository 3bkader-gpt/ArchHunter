# Rate Limiting & Anti-Automation

**What it is:** Missing/weak limits enable brute force, enumeration, OTP cracking, resource abuse, and cost/DoS.

## High-value targets
Login, OTP/2FA verify, password reset, coupon redeem, invite/referral, search, expensive report/export, email/SMS trigger (bill the target).

## Bypass a present limit
- [ ] IP spoof headers: `X-Forwarded-For`, `X-Real-IP`, `X-Client-IP`, `True-Client-IP`, `X-Originating-IP` (rotate values).
- [ ] Case/format of path: `/Login`, `/login/`, `/login%00`, add query `?x=1`.
- [ ] Null byte / unicode in username to look like a new key.
- [ ] Race/parallel (single-packet) to fit many under one window.
- [ ] Rotate session/token; limit keyed per-token not per-account.
- [ ] Different endpoint, same action (web vs mobile API vs GraphQL batch).
- [ ] GraphQL aliasing/batching (see graphql file).

## Impact
Brute force → ATO, enumeration, OTP bypass, email/SMS bombing (financial), DoS.

## 🎯 PoC — Request → Response

**No limit on OTP verify — same request, 6-digit space, no `429`:**
```http
POST /api/v2/auth/otp/verify HTTP/2
Host: api.target.com
Content-Type: application/json
X-Forwarded-For: 10.0.0.7          # rotate per request to defeat IP limits

{"session":"otp_5f2a...","code":"000123"}
```
```http
HTTP/2 401 Unauthorized
{"error":"invalid_code","attempts_remaining":null}   ← no lockout, no 429 after 5k tries
```
Correct code eventually:
```http
HTTP/2 200 OK
{"token":"eyJ...","expires_in":3600}                 ← brute succeeded
```
Reference `X-RateLimit-Remaining` header if present — if it never decrements or resets per-token, the limit is bypassable.

## Deep cuts — identify the key, then break it
- [ ] **First, find the limit key:** per-IP, per-account, per-token/session, per-endpoint, or global? The bypass follows the key — rotate whatever it keys on. `X-RateLimit-*` headers, `Retry-After`, and the `429` trigger point reveal it.
- [ ] **IP-spoof header matrix (rotate values):** `X-Forwarded-For` (also multi-IP `a, b, c` — some read first, some last), `X-Real-IP`, `X-Client-IP`, `CF-Connecting-IP`, `True-Client-IP`, `X-Forwarded`, `Forwarded: for=`, `X-Originating-IP`, `X-Cluster-Client-IP`, `Fastly-Client-IP`. Add IPv6 ranges (huge space).
- [ ] **Key-value permutations:** username case/`+alias`/dot/trailing-space/unicode look "new" to a per-account limiter; path case/`%00`/`;`/`?x=` and trailing slash look "new" to a per-path limiter; a fresh session/anon token resets a per-token limiter.
- [ ] **Different door, same action:** web form vs mobile API vs GraphQL alias/batch vs JSON-array batch vs legacy `/v1` — one is unmetered (`02-graphql`, `07-api/01`).
- [ ] **Single-packet / parallel window:** fit N attempts inside one limiter tick (`02-business-logic/07`).
- [ ] **Hit the origin:** the limiter lives at the CDN/WAF edge → reach the origin IP directly and it's gone (`10-server-edge/04`).
- [ ] **CAPTCHA/anti-bot bypass:** reuse one solved token, empty/known answer, missing server-side verify, or CAPTCHA only on web not API.
- [ ] **Business vs security limit:** even when brute is throttled, look for unlimited **email/SMS/push triggers** (cost + bombing a victim), unlimited expensive exports/reports (wallet-drain DoS), and invite/referral farming.

## Report notes
Show the endpoint accepting far more requests than the stated/expected limit, and the abuse it enables (e.g. 10k OTP guesses, SMS bombing). Name the limit key and the bypass. Do not actually take services down or spam real users; prove with a controlled burst.
