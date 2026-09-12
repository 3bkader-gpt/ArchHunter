# Account Takeover Chains (0-click & 1-click)

**What it is:** Combine small bugs into full ATO. Individually low; chained = critical. The most valuable reports are chains.

## Common 0-click / 1-click patterns

### Pre-account-takeover
Attacker registers victim's email (unverified allowed), victim later signs up via SSO → accounts merge → attacker retains access.
```http
POST /register HTTP/1.1
Host: target.com
Content-Type: application/json

{"email":"victim@corp.com","password":"attacker123"}
```
Then victim "Sign in with Google" → same email → merged. Attacker's password still works.

### Reset-token leak via Host header
```http
POST /forgot-password HTTP/1.1
Host: evil.com
Content-Type: application/x-www-form-urlencoded

email=victim@corp.com
```
If reset email builds link from `Host` → victim clicks `https://evil.com/reset?token=...` → token to attacker → ATO. (see `04-auth-session/05`).

### Reset-token leak via Referer + open redirect
Reset page loads a third-party script or has an open redirect → `Referer` carries `?token=` to attacker.

### Response-manipulation OTP/2FA bypass
```http
HTTP/1.1 200 OK
{"verified":false,"next":"/otp"}
```
Flip to `{"verified":true}` in the proxy → skip step (only works if backend trusts client). Confirm server-side.

### IDOR on "change email/password"
```http
POST /api/user/update HTTP/1.1
Host: target.com
Cookie: session=<attacker>
Content-Type: application/json

{"user_id":1089,"email":"attacker@evil.com"}
```
Sets victim's email to yours → reset → ATO.

### JWT sub-swap
Change `sub`/`user_id` claim when signature isn't verified (see `04-auth-session/03`).

### OAuth `redirect_uri` code theft
Steal `code` to attacker-controlled URL, replay at callback (see `04-auth-session/04`).

### CORS + credentialed read → token theft
Reflected `Origin` + `Allow-Credentials:true` → read victim's `/me` (with CSRF token/session) cross-origin → act as them (see `05-client-side/02`).

## Method
- [ ] Map every auth transition (register, verify, login, reset, 2FA, SSO, email change).
- [ ] For each, find one weak link (host trust, missing state, IDOR, response trust, token leak).
- [ ] Chain the weakest links into a repeatable takeover of a victim you control.

## Impact
Full account takeover. Chains = highest bounties.

## Chain recipe table (A → B → … → ATO)
```
open-redirect  → OAuth code lands on attacker host → replay at callback → session          (05/05 → 04/04)
subdomain TO   → Set-Cookie domain=.target.com → session fixation / CSRF-token override      (08/01 → 04/07)
S3/bucket read → sourcemap/.env → API key/OAuth secret → forge tokens                        (08/04 → 00/05 → 04/03)
CORS creds read→ steal /me CSRF token+email → CSRF email-change → reset → ATO                 (05/02 → 05/01 → 04/05)
stored XSS     → exfil session/CSRF → silent email/password change → ATO                      (03/02 → 04/09)
IDOR export    → victim PII/session id → impersonate / support-tool takeover                  (01/01 → 01/03)
proto-pollution→ DOM XSS gadget under CSP → token theft → ATO                                 (09/02 → 03/02)
host-header    → poisoned reset link → token to attacker → ATO                                (09/09 → 04/05)
JWT secret leak→ forge admin token → impersonate any user                                     (08/04 → 04/03)
cache deception→ victim's authed page cached → attacker reads session/data                    (08/03 → 04/07)
reset race     → email-change + verified-action race → account bound to attacker email        (02/07 → 04/09)
```

## Deep cuts — chain enablers to always test
- [ ] **Unverified-email trust:** register/link where the IdP or app trusts an unverified address → pre-ATO or SSO merge.
- [ ] **Response-flip discipline:** any "verified/success" flip must be proven server-side before you call it a chain link (`99-reference/05`).
- [ ] **Weakest-link mapping:** for every auth transition list the one cheap bug (host trust / missing state / IDOR / token leak / response trust) — the report is the shortest path through them.
- [ ] **Cross-file chains:** the best payouts cross categories (recon→secret→auth, client→auth, logic→auth). Read the `Related` links in each file as edges of a graph.

## Report notes
Write the chain as an ordered attacker narrative, each step with its request. Demonstrate end-to-end on a victim account you own. Lead with the final impact (full ATO), then the steps.
