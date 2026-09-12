# Session Management

**What it is:** Flaws in how sessions are issued, stored, and destroyed.

## Test steps
- [ ] Session fixation: session ID not rotated after login → set victim's ID pre-auth.
- [ ] Logout does not invalidate the token server-side (still works after logout).
- [ ] Password change / reset does not kill other sessions.
- [ ] Predictable/weak session IDs (short, sequential, low entropy).
- [ ] Token in URL (logged, referer-leaked, browser history).
- [ ] Cookie flags missing: `HttpOnly`, `Secure`, `SameSite`.
- [ ] Overly long / non-expiring sessions; "remember me" token weak or permanent.
- [ ] Concurrent sessions unlimited / no device management.
- [ ] Session not bound to IP/UA when it claims to be.
- [ ] JWT/opaque token still valid after account deletion/deactivation.
- [ ] Cross-site cookie scope too broad (`domain=.target.com` shared with untrusted subdomain).

## Impact
Session hijacking, persistence after logout/reset, fixation → takeover.

## Tools
Burp Sequencer (entropy), manual cookie inspection.

## 🎯 PoC — Request → Response (token survives logout)

Capture the session, log out, then replay the same token:
```http
POST /api/v1/auth/logout HTTP/2
Host: api.target.com
Authorization: Bearer eyJ...<captured>...
```
```http
HTTP/2 204 No Content
```
```http
GET /api/v1/account/me HTTP/2
Host: api.target.com
Authorization: Bearer eyJ...<same token, after logout>...
```
```http
HTTP/2 200 OK
{"id":"3a1f...","email":"me@corp.com"}      ← still valid = server never invalidated it
```
Same test after password change / reset (should kill all sessions).

## Deep cuts — tokens, refresh, and binding
- [ ] **Refresh-token rotation gaps:** reuse a refresh token after it should have rotated; if reuse still mints access tokens, rotation is broken (and there's no reuse-detection revoke). Steal-once = permanent access.
- [ ] **Access vs refresh lifetime:** short access token but a long/immortal refresh; revoked session leaves the refresh token live.
- [ ] **Stateless-JWT logout illusion:** "logout" only drops the client cookie; the signed JWT stays valid until `exp`. No server-side denylist = no real logout/revoke (chains with `03-jwt`).
- [ ] **"Remember me" token:** static, guessable, derived from user id/email, not rotated, or valid forever — forge or replay it.
- [ ] **Device/session binding bypass:** session claims IP/UA/device binding but doesn't enforce it (change UA/IP, token still works); or the binding value is attacker-settable.
- [ ] **Concurrent-session & "sign out everywhere":** the global-logout button doesn't kill other devices; new login doesn't cap sessions; ended session still listed as active.
- [ ] **Privilege-change doesn't re-issue:** role downgrade / removal from org / plan cancel leaves the *old* session with old privileges (state desync, `09-advanced/10`).
- [ ] **Session-upgrade / step-up not scoped:** a step-up (re-auth/MFA) elevates the whole session indefinitely instead of one action.
- [ ] **Cross-subdomain scope:** `Domain=.target.com` shares the cookie with an untrusted/user-content subdomain → theft/tossing (`07`); missing `__Host-` prefix.
- [ ] **Deletion/deactivation:** token/JWT still valid after the account is deleted or suspended.

## Report notes
Show the reused/uninvalidated token performing an authenticated action after the event that should have killed it (logout / password change / role change / deletion / rotation). Name which invalidation failed.
