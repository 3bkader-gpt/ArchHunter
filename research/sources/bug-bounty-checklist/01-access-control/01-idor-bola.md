# IDOR / BOLA (Broken Object Level Authorization)

**What it is:** The server exposes a reference to an object (id, uuid, filename, email) and does not verify the caller owns it. Change the reference → read/modify someone else's data. #1 highest-hit-rate bug class.

## Setup
- Two accounts: **UserA** (attacker, your token) and **UserB** (victim).
- Capture UserB's object IDs while logged in as UserB, then replay the request with UserA's token.
- Automate the diff with Burp (Match&Replace token, or Autorize/AuthMatrix extension).

## Where to look
- Numeric IDs in path/query/body: `/account/1001`, `?order=55`, `{"user_id":42}`.
- UUIDs/GUIDs (still test — sometimes guessable/leaked elsewhere).
- Filenames: `/download?file=invoice_1001.pdf`.
- Email/username as identifier.
- Base64/hashed IDs — decode, tamper, re-encode.
- Nested/related objects (order → address → payment method).

## Core test
```
GET /api/v1/account/2222        Token: UserA   → your data (200)
GET /api/v1/account/3333        Token: UserA   → UserB data? (200 = IDOR)
```

## Bypass tricks when the simple swap 403s
- HTTP method swap: `GET` blocked → try `POST`/`PUT`/`PATCH`/`DELETE`.
- Wrap the ID (see `02-id-tamper-methods.md` — 20 encodings/wrappers).
- Add the ID twice / array / HPP: `id=A&id=B`, `{"id":["A","B"]}`.
- Path vs body: move the ID between URL and JSON body.
- Content-type swap: JSON ↔ form ↔ XML.
- Add missing parent object you own but child you don't.
- Wildcard/`*`/`0`/`null`/`me`/`current` as the ID.
- Old API version: `/v2/` enforces, `/v1/` does not.
- Case/encoding of UUID, trailing `/`, `.json` suffix.

## UUIDs are not protection
A UUID only means "not sequential" — it does **not** mean authorized. Test it anyway:
- [ ] **Leaked elsewhere:** the victim's UUID often appears in another response — search/list endpoints, `?ref=`, shared-link URLs, emails, `Location` headers, error messages, other users' public profiles. Harvest it there, replay it here.
- [ ] **Predictable UUIDs:** UUIDv1 encodes MAC + timestamp (guessable); some apps use sequential ULIDs/snowflakes/`ObjectId` (Mongo `ObjectId` = timestamp+counter → adjacent objects guessable).
- [ ] **Old-format leftover:** a v3 API uses UUIDs but a legacy `/v1/` path still takes the integer id.

## GraphQL / encoded global IDs (decode → increment → re-encode)
Node IDs are usually base64 of `Type:integer`. Systematically exploited across HackerOne/GitLab/Shopify.
```
Z2lkOi8vc2hvcC9PcmRlci8xMDAx   →  base64 decode →  gid://shop/Order/1001
                                   increment      →  gid://shop/Order/1002
                                   re-encode      →  Z2lkOi8vc2hvcC9PcmRlci8xMDAy
```
- [ ] Decode every opaque ID (base64, hex, JWT-ish). If it wraps an integer/known field → tamper and re-encode.
- [ ] Encoded ID / username / email / UUID formats = ~39% of disclosed BOLA reports — always decode first.

## BOPLA — Broken Object *Property* Level Auth (OWASP API3:2023)
Object-level check passes, but you read/write **fields** you shouldn't:
- [ ] **Excessive read:** the object returns extra properties (`ssn`, `password_hash`, `internal_notes`, other users' data) the UI hides.
- [ ] **Excessive write:** you set properties you shouldn't (`role`, `verified`, `owner_id`) — this is mass assignment (`07-api/03`).

## Automation
- [ ] Burp **Autorize** / **AuthMatrix**: replay every request with UserB's token/no-token, auto-flag `200`s that should be `403`.
- [ ] Two-session diff: record as UserA, replay-as UserB, compare.

## Impact ladder
Read PII → modify data → account takeover → cross-tenant access → mass extraction (increment across all IDs = data breach).

## 🎯 PoC — Request → Response

**Your token, victim's account UUID → their statement:**
```http
GET /api/v3/accounts/a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d/statements HTTP/2
Host: api.target.com
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.<UserA>.<sig>
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"account_id":"a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
 "holder":"Bob Victim","iban":"GB29 NWBK ...","balance":48213.55,
 "transactions":[{"id":"txn_9931","amount":-1200.00,"to":"..."}]}
```
`200` + Bob's data under UserA's token = BOLA. (UUID captured while logged in as UserB.)

**Filename IDOR — sequential invoice:**
```http
GET /download?file=invoice_1089.pdf HTTP/2
Host: target.com
Cookie: session=<UserA>
```
```http
HTTP/2 200 OK
Content-Type: application/pdf
Content-Disposition: inline; filename="invoice_1089.pdf"      ← not yours = IDOR
```

## Deep cuts — the IDOR variants scanners never find
- [ ] **Blind IDOR (write, no reflection):** the response says `200 OK` with no victim data, but the *state changed* — victim's email/password/2FA/shipping got overwritten. Confirm from the victim session, not the attacker response. Highest-impact, easiest to miss.
- [ ] **Second-order IDOR:** you can't set `owner_id` directly, but a *later* endpoint trusts an id you planted earlier (invite → accept, draft → publish, cart → order). See `09-advanced/01-second-order.md`.
- [ ] **Batch/bulk amplification:** an endpoint takes an array — `{"ids":[victim1,victim2,...]}` or CSV export `?ids=1,2,3` — one request pulls many victims, often skipping the per-object check the single-GET enforces.
- [ ] **GraphQL alias fan-out:** batch hundreds of object reads in one query via aliases (`a:node(id:X){...} b:node(id:Y){...}`) → bypasses per-request rate limits *and* sometimes per-object authz (`07-api/02`).
- [ ] **Export / render side channel:** `/invoice/<id>/pdf`, `/report/<id>/csv`, image thumbnailer, "share to PDF" — the render worker fetches the object server-side with no user context (IDOR **and** SSRF, `03-injection/06`).
- [ ] **WebSocket / SSE IDOR:** after upgrade, the per-message `{"subscribe":"account:3333"}` frame is rarely authz-checked like the REST route (`05-client-side/07`).
- [ ] **Referer/Origin-gated check:** endpoint "protected" only when `Referer` is the app — drop or spoof the header and the check vanishes.
- [ ] **Notification/webhook/callback config IDOR:** set another tenant's object as your webhook source, or read delivery logs containing their payloads.
- [ ] **Timing/oracle confirmation:** no data returned, but `404` (not exists) vs `403` (exists, not yours) vs response-time delta lets you enumerate valid IDs even without read.
- [ ] **Read-your-own then replay:** capture the id from a *shared* surface (activity feed, mentions, search autocomplete, `@user`), where the app leaks other tenants' ids, then use it here.

## Report notes
Prove with two distinct accounts you control. Show UserA's token returning UserB's data. For blind/write IDOR, show the state change from the *victim's* session. Never enumerate real users' data at scale — one or two IDs to prove, then stop.

## Tools
Burp + **Autorize**/**AuthMatrix**, `ffuf` for ID sweeps, `arjun` for hidden id params.
