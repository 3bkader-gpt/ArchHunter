# Privilege Escalation & Function-Level AuthZ (BFLA)

**What it is:** Low-priv user reaches high-priv function (admin action, another role's endpoint). Vertical = user→admin. Horizontal = user→user (see IDOR).

## Where to look
- Admin routes referenced in JS but hidden in UI (`/admin`, `/api/admin/*`).
- Role/permission flags in requests, cookies, JWT claims, localStorage.
- Multi-step flows where step N does not re-check the role set at step 1.
- Mass-assignment of role fields (see `07-api/03-mass-assignment.md`).

## Test steps
- [ ] As low-priv user, call admin endpoints directly (skip the UI gate).
- [ ] Flip permission flags: `role=user`→`admin`, `isAdmin:false`→`true`, `1→0`, `Y→N`.
- [ ] Fuzz permission bits: observe the value encoding (hex/binary/string) and toggle.
- [ ] Forge/alter JWT claims (`role`, `scope`, `groups`) — see `04-auth-session/03-jwt.md`.
- [ ] Add yourself to a privileged group via a group-membership endpoint.
- [ ] Replay an admin's captured request with your token (does it 403 or execute?).
- [ ] Register at a normally-gated signup (`/admin/register`) directly.

## Business-logic flavor (from field notes)
Watch HTTP request+response for ACL/permission parameters. Once a suspicious param is found, decode its value and tamper logically: `1↔0`, `Y↔N`, add/remove a flag. Mix brute force + logical deduction + tampering to decode the scheme, then escalate.

## Impact
Full admin takeover, tenant compromise, config change, other-user data access.

## Tools
Burp **AuthMatrix**/**Autorize**, `jwt_tool`, manual diffing.

## 🎯 PoC — Request → Response (BFLA)

**Low-priv user calls an admin-only endpoint directly (URL found in JS):**
```http
POST /api/v1/admin/users/9c8b7a6d-1e2f-4a3b-8c9d-0e1f2a3b4c5d/impersonate HTTP/2
Host: api.target.com
Authorization: Bearer eyJ...<role=member>...
Content-Type: application/json

{}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"impersonation_token":"eyJ...<role=admin, sub=9c8b7a6d>...","expires_in":900}
```
Member token → admin impersonation token. No function-level check = vertical privilege escalation.

## Deep cuts — escalation paths beyond flipping isAdmin
- [ ] **Registration-time role injection:** add `role`/`is_staff`/`account_type`/`plan` to the signup body (mass assignment, `07-api/03`) — the field the UI never sends is often bound blindly.
- [ ] **Invitation/role-assignment tamper:** invite endpoint takes `role=member` → change to `admin`/`owner`; or accept an invite while altering the embedded role token.
- [ ] **Ownership transfer abuse:** "transfer workspace/repo ownership" or "make owner" flows that check the *target* exists but not that *you* may grant it.
- [ ] **GraphQL mutation for role:** `updateUser(role: ADMIN)` / `setMembership(role: OWNER)` reachable directly even when the UI hides it (`07-api/02`).
- [ ] **Step-up / re-auth skip:** a sensitive action requires password/2FA re-entry — replay the final request without the step-up token, or reuse a stale one.
- [ ] **API-key / token scope escalation:** mint a personal token, then use it on org endpoints; request broader `scope` at creation than the UI offers; downgrade a scope check by omitting the scope param.
- [ ] **Horizontal→vertical pivot:** IDOR into an admin's object (`03` impersonate) yields an admin token/session → vertical escalation (`09-advanced/07` ATO chains).
- [ ] **Permission-bit / bitmask fuzz:** role encoded as bitmask/CSV (`perms=1,2,4`) → add `8`/`admin`/`*`; observe the encoding then set the superset.
- [ ] **Feature-flag / impersonation endpoints:** `/support/impersonate`, `debug=1`, `?as_user=`, `X-Act-As` — support tooling exposed to normal users.
- [ ] **Default-deny gaps on new endpoints:** freshly shipped routes (from JS/`_buildManifest`) predate the authz middleware — call them before the team wires the guard.
- [ ] **Group-membership self-add:** `POST /groups/admins/members {user_id: me}` checking only the target id, not the caller's right to modify that group.

## Report notes
Show the exact param/claim you changed and the privileged action that succeeded (screenshot admin-only response with your low-priv token). If chained (IDOR→token→admin), diagram each hop.
