# Cross-Tenant / Organization Boundary Bugs

**What it is:** In SaaS/multi-tenant apps, one workspace/org/company affecting or reading another. Breaks customer isolation → almost always high/critical. Needs **two tenants you control** (Org A = attacker, Org B = victim).

## Setup
- Create two orgs/workspaces with separate accounts.
- As Org A, try to reach Org B's objects, invites, files, settings, billing, members.
- Diff every request: does the server scope by tenant, or only by object id?

## Where to hunt
- [ ] **Object refs cross tenant:** `GET /api/v2/orgs/<orgB>/documents/<id>` with Org A's token → leaked? Also try omitting the org (`/documents/<id>`) so the server picks the "current" tenant incorrectly.
- [ ] **File references A→B:** an attachment/report URL from Org A works when authenticated as Org B (or vice versa) — download endpoint checks the file id, not the tenant.
- [ ] **Invite links usable across tenants:** an invite generated for Org B accepted while logged into Org A, or an Org A member joins Org B via a guessable/again-usable invite.
- [ ] **Shared object-ID space:** sequential/global IDs leak counts and let you walk another tenant's records (see `01-idor-bola.md`).
- [ ] **Shared cache leaking across tenants:** CDN/edge caches a tenant-specific page under a key missing the tenant → served to another (`10-server-edge/03`).
- [ ] **SSO misbinding:** SAML/OIDC assertion for Org B accepted in Org A's context; `RelayState`/`tenant` param tamper binds your login to the wrong org.
- [ ] **Role confusion (personal ↔ org account):** actions allowed on your personal account leak into an org where you're low-priv; a personal API token acting on org resources.
- [ ] **Billing/plan bleed:** change another tenant's subscription/seats; read their invoices.
- [ ] **Member management:** add yourself to Org B, or elevate role via a membership endpoint that only checks the target user id.
- [ ] **Webhook/integration scope:** Org A configures a webhook that receives Org B's events.

## 🎯 PoC — Request → Response (cross-tenant object read)
```http
GET /api/v2/workspaces/ws_victimB/documents HTTP/2
Host: api.target.com
Authorization: Bearer <Org-A member token>
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"workspace":"ws_victimB","documents":[
  {"id":"doc_991","title":"Board deck Q3","url":"/files/doc_991"}]}   ← Org B data via Org A token
```
Also test the "no tenant in path" variant:
```http
GET /api/v2/documents/doc_991 HTTP/2
Authorization: Bearer <Org-A member token>
```
`200` = server resolved a foreign object with no tenant scoping.

## Detection tips
- Burp **Autorize** with an Org-B "victim" identity set; auto-flags cross-tenant `200`s.
- Test both directions (A→B and B→A) — one may be scoped, the other not.
- Try `null`/empty/other-tenant slug where a tenant id is expected.

## Impact
Customer-data breach, cross-tenant takeover, data tampering, billing fraud. Isolation break = top severity.

## Report notes
Prove with two tenants you own. Show Org A's credential returning Org B's data/action. One object is enough — do not sweep real customers.

## Deep cuts — isolation breaks that hide in the plumbing
- [ ] **Tenant id mismatch: JWT vs path vs body.** Token says `tenant:A`, path says `orgB` — which wins? Set them to disagree; if the body/path overrides the token claim, you're in B.
- [ ] **Email-domain auto-join:** signup with `you@victim-corp.com` (catch-all or a real employee address you control via `+`/subdomain) auto-joins the victim's SSO-provisioned org. Also test unverified-email auto-provisioning.
- [ ] **Default/fallback tenant:** omit the tenant param entirely → server resolves to the "first" or a global tenant and leaks/writes there; `tenant=0`, `tenant=null`, `tenant=default`, `tenant=*`.
- [ ] **Shared object-storage prefix:** files stored at `s3://bucket/<tenant>/<id>` but served by id only, or a predictable/guessable key across tenants (`08-infra/04`).
- [ ] **Integration/OAuth token cross-tenant:** a connected Slack/GitHub/Stripe token installed in Org A queried through Org B's context; webhook secrets reused across tenants.
- [ ] **Audit-log / activity-feed bleed:** admin audit log, usage analytics, or "recent activity" surfaces other tenants' user emails/actions/object names.
- [ ] **Search / autocomplete leak:** global search or `@mention`/typeahead resolves users, files, or orgs outside your tenant (great source of victim ids for the IDOR above).
- [ ] **Sub-resource inherits wrong scope:** parent (project) is tenant-scoped, but a child (comment, attachment, export job, share link) is looked up globally.
- [ ] **Async/job worker no-context:** background export/report/email jobs run without the requester's tenant context and can be pointed at another tenant's data.
- [ ] **Tenant enumeration oracle:** signup/invite/SSO-metadata endpoints reveal which orgs/domains exist (name squatting, subdomain `orgB.app.com` behavior) — recon for the attacks above.
- [ ] **Custom-domain / vanity-URL confusion:** tenant-B's custom domain routed to tenant-A context, or host-header override picking the wrong tenant (`09-advanced/09`).

## Related
`01-access-control/01-idor-bola.md` · `01-access-control/04-forced-browsing.md` · `07-api/03-mass-assignment.md` · `10-server-edge/03-cdn-cache-poisoning-deep.md` · `04-auth-session/04-oauth-sso.md` · `04-auth-session/10-saml.md`
