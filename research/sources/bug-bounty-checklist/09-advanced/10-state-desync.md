# State Desync Bugs (frontend says X, backend accepts Y)

**What it is:** The UI reflects one state (disabled, deleted, expired, unverified, logged-out) but a backend path still honors the old state. The "revoked" thing still works. Scanners never find these — you must test the *stale* path directly after a state change.

## Method
1. Perform the state change (disable, delete, revoke, reset, upgrade→downgrade).
2. Immediately replay a **previously-captured** request for the old state — token, resource URL, endpoint.
3. If it still succeeds, the state is cosmetic on the frontend only.

## High-value cases
- [ ] **Disabled/suspended account still has a live API token** → acts via API after "disable".
```http
GET /api/v2/account/me HTTP/2
Authorization: Bearer <token issued before account was disabled>
```
```http
HTTP/2 200 OK
{"id":"...","status":"active"}      ← server never revoked the token = desync
```
- [ ] **Deleted resource still downloadable/readable** via a direct/old endpoint (soft-delete not enforced on read).
- [ ] **Expired invite still valid** through an older endpoint/version.
- [ ] **Unverified user hits verified-only actions** (verification gated only in UI).
- [ ] **Old sessions survive password reset / MFA enrollment** — pre-reset session/JWT still authenticates (should be killed).
- [ ] **Downgraded plan keeps premium** — entitlement cached; paid endpoint still serves (`02-business-logic/05`).
- [ ] **Revoked OAuth grant / rotated key still accepted** for a window.
- [ ] **Removed team member** keeps access to shared resources / webhooks / API keys they created.
- [ ] **Deactivated 2FA device / old backup codes** still valid.
- [ ] **Email changed but old email still receives sensitive mail / can still reset.**
- [ ] **Logout doesn't invalidate server token** (`04-auth-session/06`).

## Timing / TOCTOU flavor
- [ ] Race the state change vs the action: use a resource in the window between "delete requested" and "delete committed" (overlaps with `02-business-logic/07-race-conditions.md`).
- [ ] Parallel: one request downgrades, another consumes the premium feature simultaneously.

## 🎯 PoC — Request → Response (session survives password reset)
Capture a session, reset the password from another session, replay the old one:
```http
GET /api/v2/account/settings HTTP/2
Host: api.target.com
Authorization: Bearer <session from BEFORE the password reset>
```
```http
HTTP/2 200 OK
{"email":"victim@corp.com","2fa":true}      ← old session still valid after reset = desync
```

## Impact
Persistent access after revocation, data access after deletion, auth bypass, entitlement theft. Often high (defeats the "we revoked it" control).

## Report notes
Show the state change succeeded (screenshot the "disabled/deleted/reset" confirmation) **and** the stale request still working afterward with no re-auth. Use your own accounts/resources.

## Deep cuts — distributed & token-lifecycle desync
- [ ] **Refresh-token reuse-detection gap:** after rotation, the old refresh token still mints access tokens (no reuse-detection revoke) → steal-once, persist forever (`04-auth-session/06`).
- [ ] **Stateless-JWT no-revocation:** logout/ban/role-change can't kill a signed JWT before `exp`; no denylist = the control is cosmetic until expiry.
- [ ] **CDN/edge-cached authed page after logout:** the victim's authenticated page sits in a shared/edge cache and is served post-logout or to another client (`08-infra/03`, `10-server-edge/03`).
- [ ] **Multi-region / read-replica lag:** revoke on the primary, but a replica/region still serves the old state for the replication window (eventual consistency).
- [ ] **Cache/feature-flag propagation delay:** entitlement, ban, or permission change cached in-app/CDN/config service → old behavior persists for the TTL (`02-business-logic/05`).
- [ ] **Integration/OAuth after removal:** an installed app/webhook/API key keeps receiving events or acting after the integration is "removed" (`07-api/05`).
- [ ] **Grace-period abuse:** "you can still access until end of billing period" / "30-day deletion grace" honored by *all* endpoints, including ones that shouldn't grant it.
- [ ] **Device/session-list desync:** "sign out everywhere" or device removal doesn't actually invalidate the listed session; the removed device's token still works.
- [ ] **Password-reset/MFA-change session survival (repeat, high):** pre-change sessions/JWTs must die — capture-before, replay-after.

## Related
`04-auth-session/06-session-management.md` · `04-auth-session/09-email-invite-flow-abuse.md` · `02-business-logic/07-race-conditions.md` · `07-api/05-webhook-integration-trust.md` · `99-reference/05-response-manipulation-and-verification.md`
