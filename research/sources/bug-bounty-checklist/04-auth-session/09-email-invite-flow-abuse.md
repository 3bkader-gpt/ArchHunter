# Email / Invite / Reset Flow Abuse (logic bugs)

**What it is:** Subtle logic flaws in email-change, invite, magic-link, and reset flows — beyond straight token theft (`05-password-reset.md`). These bind the wrong account, reuse tokens, or leak verification. Often account takeover or unauthorized access.

## Invite tokens
- [ ] **Usable by unintended users:** an invite for `victim@corp.com` accepted while logged in as attacker → attacker joins with victim's intended role.
- [ ] **Reusable / not single-use:** one invite consumed by many accounts.
- [ ] **No expiry / stale onboarding token** binds to the wrong account when clicked later.
- [ ] **Role/tenant baked in the token but tamperable** → escalate role or land in another tenant (`01-access-control/05`).
- [ ] **Invite enumeration:** guessable invite ids → join orgs you were never invited to.
- [ ] **Email mismatch:** accept an invite with a different email than addressed (bypasses domain allowlist for a corp workspace).

## Magic links / passwordless
- [ ] **Reusable magic link:** works more than once / after login / not invalidated on use.
- [ ] **No expiry**, or long window.
- [ ] **Link not bound to the requesting device/session** → attacker who obtains it (referer/log leak) logs in.
- [ ] **Login CSRF:** force a victim to consume the attacker's magic link → victim now in attacker's account (data capture), or attacker's link logs victim's browser into attacker account.
- [ ] **Token in URL leaks** via `Referer` to third-party resources on the landing page.

## Email-change flow
- [ ] **Confirmation sent to the wrong address:** change to `attacker@evil.com`, confirmation goes to the *new* address only (no notice/confirm to the old) → silent takeover of the contact channel.
- [ ] **No re-auth / no password prompt** to change email → chain with CSRF/IDOR = ATO.
- [ ] **Old email retains reset/verification power** after change (state desync, `09-advanced/10`).
- [ ] **Partial-verification bypass (timing):** change email + a session/verification race leaves the account verified against the *new* attacker email:
```
1. Request email change to attacker@evil.com  (pending confirm)
2. Trigger a verified-only action in the window before/around confirmation
3. Session still "verified" but now tied to attacker-controlled email
```
- [ ] **HPP / second recipient:** `email=victim&email=attacker` routes confirmation to attacker (`05-password-reset.md`).

## Reset flow logic (beyond token theft)
- [ ] **Reset for deactivated/suspended accounts** succeeds → reactivate + take over.
- [ ] **Reset doesn't invalidate old sessions / other reset tokens.**
- [ ] **Reset token reusable** or valid after use.
- [ ] **Unverified account reset** creates a usable password on an account you don't own.

## 🎯 PoC — Request → Response (email change, confirmation to attacker only)
```http
POST /api/v2/account/email HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"new_email":"attacker@evil.com"}
```
```http
HTTP/2 200 OK
{"status":"confirmation_sent","to":"attacker@evil.com"}
```
No password re-prompt, no alert to the old address. Chain with CSRF/IDOR on this endpoint (supply victim id) → silent ATO. Confirm the old inbox got no warning.

## Impact
Account takeover, unauthorized org access, silent contact-channel hijack, verification bypass.

## Report notes
Demonstrate end-to-end on accounts/orgs you control. Show which address received the confirmation and that no re-auth/notice protected the change. For invites, show the token binding to the wrong identity.

## Deep cuts — provisioning, guest, and share-link abuse
- [ ] **SSO JIT / SCIM provisioning trust:** a first-time SSO login auto-creates the account from IdP attributes → attribute injection sets `role`/`groups`/`department`, or email-domain trust auto-joins the victim org (`10-saml`, `01-access-control/05`).
- [ ] **Guest → member/admin drift:** accept an invite as guest, then a role/membership endpoint that checks only the target id lets you self-promote (`01-access-control/03`).
- [ ] **Invite-role tamper at accept-time:** the accept request carries `role`/`seat`/`team` from the (unsigned) invite payload → escalate on acceptance.
- [ ] **Share-link permission escalation:** a "view" share link accepts a tampered `?perm=edit`/`role=owner`, or the link's object-id is swappable to a higher-value object (IDOR, `01-access-control/01`).
- [ ] **Expired/revoked invite still works:** removed member's old invite/deep-link re-grants access (state desync, `09-advanced/10`).
- [ ] **Invite/verification token reuse across accounts:** one token verifies/joins multiple accounts, or an email-verify token from account A verifies attacker-chosen account B.
- [ ] **Auto-join by email domain:** signing up (or changing email) to `@victim-corp.com` auto-enrolls into their workspace with default (sometimes non-trivial) permissions — test catch-all + `+alias` + unverified.
- [ ] **Notification-channel takeover:** change email/phone with confirmation only to the new address (no old-address notice) → silently own the recovery channel, then reset (`05-password-reset`).
- [ ] **Bulk-invite / referral abuse:** invite endpoint unthrottled → spam/enumerate, or referral credit farmed via self-invites (`02-business-logic/03`).

## Related
`04-auth-session/05-password-reset.md` · `04-auth-session/04-oauth-sso.md` · `04-auth-session/10-saml.md` · `09-advanced/10-state-desync.md` · `01-access-control/05-cross-tenant-isolation.md`
