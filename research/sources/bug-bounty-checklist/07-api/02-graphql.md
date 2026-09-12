# GraphQL

**What it is:** Single-endpoint query language. Common flaws: introspection exposure, missing object/field authz, batching abuse, injection.

## Recon
- [ ] Find endpoint: `/graphql`, `/graphiql`, `/api/graphql`, `/v1/graphql`, `/query`.
- [ ] Introspection enabled? Dump the schema:
```
{__schema{types{name fields{name args{name}}}}}
```
- [ ] Introspection disabled → field-stomping / `clairvoyance` to infer schema; suggestions leak names.

## Test steps
- [ ] **Authz per field/object**: query sensitive fields/objects other users own (BOLA at field level).
- [ ] **Hidden mutations**: `deleteUser`, `updateRole`, admin ops exposed in schema.
- [ ] **Batching/aliasing** to bypass rate limits & brute (OTP/login):
```
{ a:login(pw:"0000"){t} b:login(pw:"0001"){t} ... }
```
- [ ] **Query depth/complexity DoS** (nested recursion) — confirm carefully, don't take it down.
- [ ] **Injection** via arguments (SQLi/NoSQLi/SSRF in resolvers).
- [ ] **IDOR** via node/global IDs (decode base64 `Type:id`).
- [ ] **Mutation mass-assignment**: set `role`/`isAdmin` in an update mutation.
- [ ] **Info leak** in errors (stack traces, backend paths).
- [ ] CSRF if it accepts `GET` or form-encoded queries.

## Advanced attacks (2025)

### Introspection disabled? Recover the schema anyway
- [ ] **Field suggestions**: send a typo, the error leaks the real field — `"Cannot query field 'usr' ... Did you mean 'user'?"`. Automate with **clairvoyance** to rebuild the schema blind.
- [ ] Try introspection over `GET`, with `Content-Type` swaps, or an alternate endpoint (`/graphql/v2`, `/api`); prod-only disable is common.
- [ ] `__typename` and partial introspection often still allowed.

### Alias overloading → DoS / cost amplification
Aliases run the same resolver N times in **one** operation → multiply cost, dodge per-request rate limits:
```graphql
query { a1:expensiveReport{id} a2:expensiveReport{id} ... a200:expensiveReport{id} }
```
200 aliases = 200× the work, one HTTP request. (Confirm carefully — do not actually take it down.)

### Batching brute-force (bypasses external rate monitoring)
Many `login`/`otp` attempts per HTTP request → the WAF/rate-limiter sees "one request":
```graphql
mutation { a:login(u:"admin",p:"1"){t} b:login(u:"admin",p:"2"){t} ... }
```
Also array-batching: `[{"query":"..."},{"query":"..."}, ...]` if the server accepts a JSON array.

### Directive overloading (DoS + engine fingerprint)
Repeat directives to exhaust the parser, or use invalid directives to fingerprint the engine:
```graphql
query { user @a @a @a @a ...(x1000) { id } }
```
InQL/graphw00f use crafted directives to ID Apollo/Hasura/graphene/etc.

### Deep-recursion query DoS
Cyclic types (`user{posts{author{posts{author{...}}}}}`) explode cost — test depth, don't sustain.

### CSRF on GraphQL
Still viable when the server accepts **GET** or non-JSON (`application/x-www-form-urlencoded`, `text/plain`):
```
GET /graphql?query=mutation{deleteAccount}          ← state-changing over GET = CSRF
POST /graphql  Content-Type: text/plain             ← simple request, no preflight
```

### Injection in resolvers
Arguments flow into backends → **SQLi/NoSQLi/SSRF/command injection** inside resolvers. Fuzz every arg (`filter`, `id`, `url`, `orderBy`).

### AuthZ gaps
- [ ] **BFLA**: hidden mutations (`updateRole`, `deleteUser`, admin ops) callable directly.
- [ ] **BOLA** on node/global IDs — decode→increment→re-encode (see `01-access-control/01`).
- [ ] **Mutation mass-assignment**: set `role`/`isAdmin` in an update mutation.
- [ ] Field-level authz: sensitive fields returned to unauthorized users.

## Tools
`graphw00f` (fingerprint engine), `clairvoyance` (schema recovery), `InQL` (Burp), `graphql-cop`, `graphql-voyager`, `batchql`, `nuclei` graphql templates.

## 🎯 PoC — Request → Response

**Field-level BOLA via node ID:**
```http
POST /graphql HTTP/2
Host: api.target.com
Authorization: Bearer <UserA>
Content-Type: application/json

{"query":"query{ user(id:\"dXNlcjo5YzhiN2E2ZA==\"){ id email phone ssn } }"}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"data":{"user":{"id":"dXNlcjo5YzhiN2E2ZA==","email":"bob@corp.com",
 "phone":"+1...","ssn":"***-**-1234"}}}      ← victim object, no authz on field
```
(`dXNlcjo5YzhiN2E2ZA==` = base64 `user:9c8b7a6d`.)

**Batching to brute an OTP under one request (bypasses per-request rate limit):**
```http
POST /graphql HTTP/2
Host: api.target.com
Content-Type: application/json

{"query":"mutation{ a:verifyOtp(code:\"0000\"){token} b:verifyOtp(code:\"0001\"){token} c:verifyOtp(code:\"0002\"){token} }"}
```
```http
HTTP/2 200 OK
{"data":{"a":{"token":null},"b":{"token":"eyJ..."},"c":{"token":null}}}   ← "0001" hit
```

## Deep cuts — engine-specific & auth-directive bypasses
- [ ] **Persisted-query (APQ) bypass:** Apollo Automatic Persisted Queries — send the `sha256Hash` with no query to probe, or register your own operation; some gateways enforce an allowlist by hash that you can desync (`PersistedQueryNotFound` → send full query anyway).
- [ ] **`@skip`/`@include` auth bypass:** wrap an authz-gated field with `@skip(if:false)`/`@include(if:true)` or alias it so a field-level guard keyed on the query shape misfires.
- [ ] **Hasura specifics:** `X-Hasura-Role`/`X-Hasura-User-Id` header trust (set a higher role), exposed `x-hasura-admin-secret`, `_by_pk`/`*_aggregate` reachable, `/v1/graphql` vs `/v1alpha1` diff, insert/update/delete mutations auto-generated per table (BOLA/mass-assignment on `_set`).
- [ ] **Apollo/graphene/others fingerprint** (`graphw00f`) → pick the matching DoS (alias/directive/field-dup) and known CVEs.
- [ ] **Introspection when "disabled":** over `GET`, with `__type(name:"User")` targeted queries, via field-suggestion (`clairvoyance`), or on an alternate path (`/graphql/console`, `/v1alpha1/graphql`).
- [ ] **File upload via GraphQL multipart** (`graphql-multipart-request`): the `map`/`operations` fields are an upload surface → path/type bypass (`06-file-upload`).
- [ ] **SSRF/resolver injection in args:** `url`/`webhook`/`redirect`/`filter`/`orderBy` args flow to backends (SSRF `03-injection/06`, SQLi/NoSQLi `03-injection/01/07`).
- [ ] **`@defer`/`@stream`** to smuggle expensive/side-effecting work or desync responses.
- [ ] **GET-based query cached** → cache poisoning of a mutation-ish query, or CSRF on state-changing GET (`08-infra/03`, `05-client-side/01`).
- [ ] **Batching = rate-limit + WAF bypass (repeat, critical):** alias fan-out *and* JSON-array batching for OTP/login/IDOR brute in one HTTP request.

## Report notes
Show the query returning unauthorized data or the batching brute working. Include the schema evidence and the engine (graphw00f). Name the bypass (persisted-query / directive / Hasura-role / introspection-recovery).
