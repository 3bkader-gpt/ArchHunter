# AUTHZ MATRIX — [TARGET_NAME]

> **Feature:** [e.g. Team Invites] · **Session:** [DATE] · **Workflow:** [`Workflow/10_depth_first_web_api.md`](../Workflow/10_depth_first_web_api.md) Phase 2
> **Method:** for every endpoint × every role × every ID. UI-hiding a button is not access control — replay the raw request.
> **Sessions:** capture one valid request per role first (Victim / Attacker / Admin / Unauthenticated), then swap tokens + IDs mechanically.

## 1. Endpoint × Role Matrix
Mark each cell: the *expected* result, then the *actual* result. Every mismatch is a finding.

| Endpoint | Method | Victim (expected/actual) | Attacker (expected/actual) | Admin (expected/actual) | Unauth (expected/actual) |
|---|---|---|---|---|---|
| `/api/teams/{id}/invites` | POST | 201 / | 403 / | 201 / | 401 / |
| `/api/invites/{id}` | DELETE | 403 / | 403 / | 200 / | 401 / |
| `/api/teams/{id}/members` | GET | 200(own) / | 403 / | 200 / | 401 / |
| | | | | | |

## 2. BOLA/IDOR Sweep (Object-Level)
For each endpoint: replay as Attacker with Victim's object ID. Cover **POST/PUT/PATCH/DELETE**, not just GET.

| Endpoint | ID swapped | Role used | Method | Result | Evidence (req/resp hash) |
|---|---|---|---|---|---|
| `/api/teams/{id}` | VICTIM_TEAM | attacker | GET | | |
| `/api/teams/{id}` | VICTIM_TEAM | attacker | PATCH | | |
| `/api/teams/{id}/members/{mid}` | VICTIM_MEMBER | attacker | DELETE | | |
| | | | | | |

**State-dependent variant:** create the object as Attacker → swap the ID to Victim's *in-flight* → act. Record which IDs are swappable at which state (from the [`STATE_MACHINE_MAP`](STATE_MACHINE_MAP_TEMPLATE.md)).

## 3. BFLA Sweep (Function-Level)
Admin-only actions replayed with lower-privilege tokens:

| Admin endpoint | Replayed as | Expected / Actual |
|---|---|---|
| `/api/admin/export` | viewer | 403 / |
| `/api/admin/users/role` | viewer | 403 / |
| | | |

## 4. Mass Assignment Probes
Add candidate fields to PUT/PATCH/POST bodies (source: JS bundle models, API responses of admins):

| Endpoint | Injected fields | Result | Evidence |
|---|---|---|---|
| `PATCH /api/profile` | `{"role":"admin"}` | | |
| `POST /api/orgs` | `{"isVerified":true,"plan":"enterprise"}` | | |
| | | | |

Wordlists: [`payloads/wordlists/mass_assignment_parameters.txt`](../payloads/wordlists/mass_assignment_parameters.txt)

## 5. Version/Environment Skew (Depth-First Extension)
Replay the failures above against every API version and environment sibling discovered by the Runtime (`env_parity_drift` / `api_version_skew` hypotheses):

| Endpoint (as tested) | Retest on | Result |
|---|---|---|
| `/api/v3/teams/{id}` | `/api/v1/teams/{id}` | |
| `api.target.com` | `staging.target.com` | |
| | | |

---
**Findings:** any (expected ≠ actual) cell → chain it in [`CHAINING_WORKSHEET`](CHAINING_WORKSHEET_TEMPLATE.md) before reporting as-is.
