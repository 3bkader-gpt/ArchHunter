# Session Puzzling (Session Variable Overloading)

**What it is:** The app reuses **one session variable** across unrelated flows. A public/pre-auth flow (password recovery, registration, guest checkout) sets `session['user']`, and a *different* endpoint later trusts the mere presence of that variable as proof of authentication or ownership. Fill the variable via the innocent flow, then walk into the protected one. Pure logic bug — scanners never find it.

## Where to look
- Multi-step flows that write to the session before auth completes: password reset (sets username to send the email), registration (sets user before verification), "continue as guest", email/2FA verification, impersonation/support.
- Endpoints that check `if (session['username'])` / `if (session['userId'])` without re-verifying identity.

## Test steps
- [ ] Enumerate every session variable set during pre-auth flows (diff the session cookie/state before and after each step).
- [ ] For each, find another endpoint that reads the **same** variable.
- [ ] Trigger the pre-auth flow (e.g. start password reset for the victim), do **not** complete it, then request the protected endpoint on the same session.
- [ ] Verify: does presence of the variable alone grant access / act on the victim's account?

## What it becomes
- [ ] **Auth bypass / ATO:** reset-flow sets `session['user']=victim` → `/myAccount` renders victim's data without login.
- [ ] **2FA bypass:** a variable meant to be set only post-2FA is also set by an earlier step → skip the second factor (Invicti-documented).
- [ ] **Privilege confusion:** admin-impersonation flow leaves an elevated id in the session for later requests.

## 🎯 PoC pattern
```
1. POST /forgot-password    email=victim@target.com     # server: session['username']=victim
2. GET  /account            (same session cookie, never logged in)
   → 200, shows victim's profile / lets you change victim's email
```
Access granted purely because `session['username']` was populated by the reset flow.

## Impact
Authentication bypass, account takeover, 2FA bypass, acting on another user's account. Severity high (often critical) when it reaches account data or state change.

## Report notes
Show the exact two-request sequence on one session: the pre-auth flow that seeds the variable, then the protected action succeeding without authentication. Prove on your own victim account. Name the shared variable if you can infer it. Logic bug → explain *why* the variable is trusted out of context.

## Related
`04-auth-session/05-password-reset.md` · `04-auth-session/02-2fa-otp.md` · `04-auth-session/06-session-management.md` · `01-access-control/03-privilege-escalation.md`
