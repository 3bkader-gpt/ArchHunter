# REST API Testing

**What it is:** APIs concentrate logic and often skip the checks the web UI enforces. The OWASP API Top 10 lives here.

## Checklist
- [ ] **BOLA/IDOR** on every object id (see `01-access-control/`). #1 API bug.
- [ ] **BFLA**: call admin/other-role endpoints directly.
- [ ] **Method tampering**: `GET→POST/PUT/PATCH/DELETE`; `OPTIONS` to reveal allowed methods.
- [ ] **Version pivot**: `/v1/` vs `/v2/` vs `/internal/` — old versions skip auth/checks.
- [ ] **Mass assignment** (see `03-mass-assignment.md`).
- [ ] **Excessive data exposure**: endpoint returns full object (SSN, hashes) though UI shows little.
- [ ] **No/weak rate limiting** on sensitive endpoints (see `04-rate-limiting.md`).
- [ ] **Auth on every route?** Some endpoints skip the middleware. Unauth `/api/...`.
- [ ] **Improper assets mgmt**: `/swagger`, `/openapi.json`, `/api-docs`, staging APIs.
- [ ] **Injection** via JSON values and keys.
- [ ] **Content-type confusion**: JSON↔XML↔form to bypass parsers/filters.
- [ ] **Verb/param pollution**: duplicate params, arrays, extra fields.
- [ ] **Pagination abuse**: `limit=100000`, negative offset, dump everything.
- [ ] **JWT/token issues** (see `04-auth-session/03`).

## Discovery
Import the OpenAPI/Swagger into Burp/Postman. Mine JS for undocumented routes (`00-recon/05`).

## Tools
Burp, Postman, `kiterunner`, `arjun`, `nuclei` API templates.

## 🎯 PoC — Request → Response

**BOLA — attacker token, victim's UUID:**
```http
GET /api/v3/users/9c8b7a6d-1e2f-4a3b-8c9d-0e1f2a3b4c5d/invoices HTTP/2
Host: api.target.com
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.<UserA>.<sig>
Accept: application/json
```
```http
HTTP/2 200 OK
Content-Type: application/json
X-Request-Id: 7f3c1a90-...

{"user_id":"9c8b7a6d-1e2f-4a3b-8c9d-0e1f2a3b4c5d","name":"Bob Victim",
 "email":"bob@corp.com","invoices":[{"id":"inv_88213","total":4821.55}]}
```
`200` + a UUID you don't own = BOLA (OWASP API1). `9c8b...` belongs to UserB.

**Method tampering — GET blocked, PUT slips:**
```http
PUT /api/v3/users/9c8b7a6d-.../role HTTP/2
Host: api.target.com
Authorization: Bearer <UserA-low-priv>
Content-Type: application/json

{"role":"admin"}
```
```http
HTTP/2 200 OK
{"user_id":"9c8b7a6d-...","role":"admin"}      ← BFLA (OWASP API5)
```

## Deep cuts — API-specific tricks that pay
- [ ] **Method-override smuggling:** `X-HTTP-Method-Override`, `X-Method-Override`, `_method=PUT`, or `POST` to a route that also maps `PUT/PATCH` → reach a verb the authz layer forgot to guard.
- [ ] **Excessive-data-exposure levers:** `?fields=*`, `?include=owner,payment`, `?expand=all`, `?embed=`, GraphQL twin, or just read the *full* object the UI truncates — SSN/hash/internal_notes hiding in the JSON.
- [ ] **Filter/sort/pagination injection:** ORM operators in query params (`?filter[role][$ne]=`, `?sort=-password`, `?where=`, `?q[user_id_eq]=`), `limit=-1`/`100000`, negative/huge `offset` → dump or bypass scoping (`03-injection/01`, `07`).
- [ ] **Content-type parser confusion:** `application/json` vs `+json` suffix, `; charset=utf-7/16`, `text/plain`, duplicate/blank `Content-Type`, JSON→XML→form swap → slip the WAF while the app still binds (`09-advanced/04`, `10-server-edge/05`).
- [ ] **Route-normalization authz gaps:** trailing slash, `%2e`, double slash, `.json`/`.xml` suffix, case, matrix params — `/api/admin` guarded, `/api/admin/` or `/api//admin` not (`01-access-control/04`).
- [ ] **404-vs-403 / timing oracle:** distinguish "not found" from "forbidden" to enumerate object existence and valid ids even without read.
- [ ] **Improper inventory (API9):** old `/v1/`,`/internal/`,`/beta/`,`/mobile/` versions, `/actuator`, `/swagger.json` → an unauth or under-checked twin of a guarded route; diff versions for dropped middleware.
- [ ] **Trusted internal headers:** `X-User-Id`, `X-Forwarded-User`, `X-Tenant`, `X-Internal`, `X-Original-URL` accepted from the client when they should be proxy-only (reach via SSRF/origin-bypass, `10-server-edge/04`).
- [ ] **CORS + auth on the API host** (`05-client-side/02`) and **gRPC/gRPC-Web twin** (`07-api/06`).

## Report notes
State the OWASP API category (API1 BOLA / API3 BOPLA / API5 BFLA / API9 inventory ...). Prove object-level bugs with two accounts. Name the exact lever (method-override / version-pivot / filter-injection / trusted-header).
