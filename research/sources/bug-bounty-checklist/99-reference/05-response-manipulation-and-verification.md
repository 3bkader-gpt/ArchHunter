# Response Manipulation & How to Know a Bug Is REAL

The #1 beginner trap: you intercept a response, change `"isPremium":false` → `true`, forward it, the UI unlocks the feature, you scream "bug!". Usually it is **not** a bug. You only edited what *your own browser* received. The server changed nothing. This file teaches how to tell a **cosmetic client-only flip** from a **real server-side vulnerability**.

## Two completely different things

### A) Editing the RESPONSE (Burp: intercept server→client)
```
Server sends:  {"isPremium":false}
You edit to:   {"isPremium":true}   → Forward
```
This byte-swap happens **inside your machine, after the server already decided**. The server's database, session, and next response are untouched. The UI may render premium buttons because the frontend trusted the JSON. That is a **client-side trust** situation — only a real bug if the *actual protected resource* is served without a server-side check.

### B) Editing the REQUEST (Burp: intercept client→server)
```
You send:  {"verified":false}
You edit:  {"verified":true}   → Forward
```
Now the **server** processes your tampered value. If it accepts it and grants access → **real server-side bug** (mass assignment / broken validation). This is the one that pays.

Rule of thumb: **Request tampering that the server honors = real. Response tampering = usually cosmetic — you must prove the server also honors the resulting state.**

## The verification test (does the flip survive without you?)

After any `false→true` response edit that "unlocks" something, run this. If the unlock survives **without** your proxy editing, it is real.

1. **Turn interception OFF.** Stop editing responses entirely.
2. **Re-request the protected resource fresh** (reload the premium data endpoint, or replay the request in Repeater with no edits).
3. Read the untouched server response:

**Cosmetic (NOT a bug):**
```http
GET /api/reports/export HTTP/1.1
Host: target.com
Cookie: session=<free-user>

HTTP/1.1 403 Forbidden
{"error":"upgrade_required"}
```
Server still refuses. Your earlier flip only fooled the UI. No finding (or informational at best).

**Real (server-side bug):**
```http
GET /api/reports/export HTTP/1.1
Host: target.com
Cookie: session=<free-user>

HTTP/1.1 200 OK
Content-Disposition: attachment; filename=report.csv
<full premium data>
```
Server actually serves premium data to a free account → real, report it.

## Confirm from an independent channel
The strongest proof: leave your session out of it.
- Repeat the "successful" action, then verify the effect with **curl** or a **second browser/account**.
- For a state change (order, balance, role), do an independent `GET` as a **different** identity and confirm the change persisted server-side.
```bash
curl -s https://target.com/api/me -H "Cookie: session=<free-user>" | jq .plan
# real bug => "pro"   |   cosmetic => "free"
```

## Worked example — 2FA "verified:false → true"

You intercept the verify **response** and flip it:
```http
HTTP/1.1 200 OK
{"verified":false,"next":"/otp"}      →  edit to  {"verified":true,"next":"/dashboard"}
```
UI navigates to the dashboard. **Is 2FA actually bypassed?** Test the session it gave you against a *protected API*, no edits:
```http
GET /api/account/sensitive HTTP/1.1
Host: target.com
Cookie: session=<the cookie you hold now>

# REAL bypass:
HTTP/1.1 200 OK
{"ssn":"...","balance":...}

# COSMETIC (still gated):
HTTP/1.1 401 Unauthorized
{"error":"2fa_required"}
```
Only the `200` = real 2FA bypass. If the API still says `401`, your flip just moved the frontend; the server never issued a 2FA-complete session.

## Worked example — premium flag (request side, the good kind)
Tamper the **request** you send when saving settings:
```http
PATCH /api/account HTTP/1.1
Host: target.com
Cookie: session=<free-user>
Content-Type: application/json

{"displayName":"x","plan":"pro"}
```
```http
HTTP/1.1 200 OK
{"displayName":"x","plan":"pro"}
```
Then independently confirm it stuck:
```http
GET /api/me HTTP/1.1
Cookie: session=<free-user>

HTTP/1.1 200 OK
{"plan":"pro"}          ← server persisted your value = real privilege/plan escalation
```

## Decision checklist
- [ ] Did I edit a **request** (server processes it) or a **response** (only my UI)?
- [ ] With interception **off**, does the protected resource still come back?
- [ ] Does an **independent** session/curl/account see the changed state?
- [ ] Is there a **persistent server side-effect** (DB/role/balance/order)?
- [ ] Could I reproduce it in **Repeater with zero edits** using only what the server gave me?

If yes → real, report with both the tamper request and the clean confirmation response.
If the effect vanishes the moment you stop editing → cosmetic; not a valid submission on its own.

## Where response-manipulation *is* legitimately a bug
- The client makes a **security decision** the server never re-checks, and the client then hands you data/token it already holds (e.g. the full premium dataset was in the same response, just hidden by a flag).
- The flipped value is **echoed back into a later request** the server trusts (client→server round trip).
- Price/total computed client-side and **sent back** to the server on checkout (that is request tampering — real; see `02-business-logic/01`).

## Same verification discipline across channels
- **WebSocket / GraphQL:** a flipped WS frame or GraphQL response is cosmetic too — prove the *server* state changed with an independent read (`05-client-side/07`, `07-api/02`).
- **Signed client values are still client values:** a signed `priceToken`/entitlement blob only matters if the server re-validates *and binds* it; test swapping/replaying it (`02-business-logic/01`, `05`).
- **Mobile/API vs web:** the web UI may gate client-side while the API returns the real resource with no check — hit the API directly, no proxy edits.
- **The one-line gate:** if the effect vanishes the moment you stop editing, it's not submittable. If a fresh, independent request (curl / second account / interception off) still shows it → real. Put *that* clean request/response in the report, not the edited one.
