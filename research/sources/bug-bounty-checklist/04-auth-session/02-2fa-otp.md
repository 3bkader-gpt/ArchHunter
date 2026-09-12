# 2FA / OTP Bypass

**What it is:** Defeating the second factor via logic flaws, missing rate limits, or response tampering.

## Test steps
- [ ] Brute force OTP: no/weak rate limit on the verify endpoint (4–6 digit space).
- [ ] Rate-limit bypass: rotate IP header, change casing, race (parallel requests).
- [ ] Reuse / no expiry: old OTP still valid; OTP not invalidated after use.
- [ ] Response manipulation: `{"2fa":false}`→`true`, `"status":"fail"`→`"success"`, `200` swap. **Cosmetic unless the session it hands you works on a protected API with no edits — verify per `99-reference/05-response-manipulation-and-verification.md`.**
- [ ] Skip the step: go straight to the post-2FA endpoint / land page after password only.
- [ ] Missing 2FA on some flows: mobile API, "remember device", OAuth login, backup codes.
- [ ] Backup codes: unlimited guesses, predictable, not rate-limited.
- [ ] Change the phone/email in the request so OTP goes to attacker.
- [ ] Code delivered in the response body / accessible via another endpoint.
- [ ] Enable 2FA on victim's account (or disable it) via IDOR/CSRF.
- [ ] Null/empty/`000000`/leading-zero acceptance.

## Race angle
Fire many verify requests in one window to bypass the attempt counter (see race-conditions).

## Impact
Full 2FA bypass → account takeover.

## 🎯 PoC — Request → Response (no rate limit on verify)

```http
POST /api/v1/auth/2fa/verify HTTP/2
Host: api.target.com
Authorization: Bearer <partial-session, password stage done>
Content-Type: application/json

{"code":"000000"}
```
```http
HTTP/2 401 Unauthorized
{"error":"invalid_code"}          ← no 429 after thousands of tries, no lockout
```
Correct code → full session:
```http
HTTP/2 200 OK
Set-Cookie: session=eyJ...; HttpOnly; Secure
{"authenticated":true,"mfa":"complete"}
```
Verify a response-flip is NOT cosmetic: take the session it returns and hit a protected API with **no** edits — `200` = real bypass, `401` = you only fooled the UI (see `99-reference/05`).

## Deep cuts — 2FA bypasses beyond brute + flip
- [ ] **Factor downgrade / fallback abuse:** "use another method", "lost my device", SMS fallback, or email-OTP fallback is weaker or unthrottled → force it. WebAuthn/passkey app that also allows password+OTP = downgrade.
- [ ] **Remember-device cookie forge/reuse:** the `remember_device`/`trusted` cookie/token is static, guessable, not bound to the device, or reusable across accounts → skip MFA forever.
- [ ] **TOTP replay window:** the same code accepted for its whole 30-90s window or across the ±skew; not invalidated after first use → reuse a leaked/observed code.
- [ ] **OTP in response / side channel:** code returned in the JSON, in a header, in a `/status` endpoint, in the SMS-provider webhook, or derivable from a predictable seed/timestamp.
- [ ] **Recovery / backup-code flaws:** codes generated with low entropy, listed via an IDOR, not consumed on use, or the "regenerate codes" endpoint reachable pre-MFA.
- [ ] **Change-the-destination:** the verify request carries `phone`/`email`/`channel` → point the OTP at attacker (also in enrollment).
- [ ] **Enrollment/removal without step-up:** enable MFA on a victim (lock them out) or disable victim's MFA via IDOR/CSRF on the enroll/disable endpoint (`01-access-control/01`, `05-client-side/01`).
- [ ] **Step skipped entirely:** the password-stage session already grants access to protected APIs (MFA is UI-only); or the `/verify` sets a flag the protected route never checks.
- [ ] **Push-fatigue / auto-approve:** spam push prompts, or a `POST /mfa/approve` acceptable without the corresponding challenge.
- [ ] **Null/empty/format tricks:** `""`, `null`, `000000`, `0`, integer vs string `123456` vs `"123456"`, array `["1","2"...]` (bulk-guess in one request), leading-zero coercion.
- [ ] **Race the attempt counter:** parallel verifies land before the counter increments (`02-business-logic/07`).

## Deep cuts — part 2 (logic, enrollment, session, infra)
- [ ] **GraphQL batching / alias multi-guess:** rate limit counts requests not operations → 1000 guesses in one request. `mutation{ a:verifyOtp(code:"000001"){ok} b:verifyOtp(code:"000002"){ok} }` or JSON array `[{"query":"..000001.."},{"query":"..000002.."}]`.
- [ ] **Type-confusion on the OTP param:** loose/NoSQL compare. `{"code":{"$ne":null}}` matches any stored code; `{"code":{"$regex":"^"}}`. (array bulk-guess already above).
- [ ] **Param pollution + normalization:** `code=wrong&code=123456` (backend picks lenient parse); trailing `\n`, ` 123456`, `123456%00`, `+123456`, `123456e0`, string-vs-int coercion.
- [ ] **JWT / client-side MFA flag flip:** session token encodes `{"mfa_passed":false}` client-side. `alg:none` strip signature set `true`; weak HS256 → `hashcat -m 16500` re-sign. Differs from server-side flag (`11-session-puzzling`).
- [ ] **Bind attacker's TOTP secret to victim:** enroll endpoint accepts a supplied secret / lacks step-up → attacker's authenticator generates victim's codes. `POST /2fa/enable {"secret":"ATTACKER_SEED"}` via CSRF/replay. (worse than lockout — persistent).
- [ ] **TOTP seed leaked at enrollment:** setup response returns base32 secret / `otpauth://` QR URI, or seed is static/predictable per-user → generate codes offline forever.
- [ ] **CAPTCHA removal / token reuse enables brute:** rate limit "protected" by CAPTCHA only → drop the captcha field, or reuse one solved token across all guesses.
- [ ] **Enable 2FA without verifying email:** attacker signs up with victim's email (no verify required), enables 2FA → gates the account when victim later claims it (pre-ATO).
- [ ] **Password not checked on disable:** `/2fa/disable` accepts a valid OTP but any/blank password → disable without knowing the password.
- [ ] **Enabling 2FA doesn't kill existing sessions:** attacker's pre-2FA hijacked session stays valid after victim turns on 2FA → 2FA gives no protection (existing-session bypass).
- [ ] **Referer-based gate:** direct-nav to post-2FA page fails, but setting `Referer: https://target/2fa` fools the app into treating 2FA as satisfied.
- [ ] **JS file analysis:** JS referenced on the 2FA request leaks the code, the validation logic, a debug flag, or a hidden bypass param.
- [ ] **Backup codes pulled via CORS/XSS:** backup-code endpoint returns codes on request (static/regenerable); CORS misconfig or XSS "pulls" them from the response → steal + bypass.
- [ ] **Info disclosure on 2FA page:** page reveals data you didn't have (victim phone/email) — report as info disclosure even without full bypass.
- [ ] **Missing code-integrity / shared tokens:** a valid OTP from the attacker's own account accepted on the victim's verify (`{"user":"victim","code":"attacker_valid_code"}`); or an unused token from your account works on another account.
- [ ] **Session-permission boolean (dual-account flow):** in one session run both your and victim's login to the 2FA step; complete 2FA on YOUR account, then continue the victim's flow. If backend only sets a per-session "passed 2FA" boolean → victim bypass.
- [ ] **Infinite OTP regeneration + fixed guess set:** if you can regen OTP unlimited and OTP space is tiny (4 digits) → keep the same 4-5 guesses, regen until one matches.
- [ ] **Resend resets the rate limit:** "resend code" returns the same code AND resets the attempt counter → brute forever by resending. Also test SMS-resend cost abuse (no limit = burn company money).
- [ ] **Flow limit, no absolute limit:** throttled per-request but no hard cap → slow brute (1 thread, sleep) eventually lands the code. Watch for "silent" limits: try several wrong then the real one to confirm.
- [ ] **Old/less-protected surfaces:** testing/staging subdomains or older `/v1/`,`/v3/` API endpoints that skip or use a vulnerable 2FA version (`07-api`).
- [ ] **Clickjacking the disable toggle:** frame the 2FA-disable page + social-engineer the click (`05-client-side/03-clickjacking`).

## Report notes
Show the bypass with two accounts / a controlled victim. Do not brute real users. Response-manipulation bugs: show the toggled field granting a session that works on a protected API. Name the exact bypass (downgrade / remember-device / replay / skip).
