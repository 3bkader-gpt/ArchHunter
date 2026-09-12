# Race Conditions (TOCTOU)

**What it is:** Two requests hit a check-then-act window simultaneously, both pass the check, both act. Breaks "once only" and balance limits.

## High-value targets
- [ ] Coupon/gift-card redeem (use one code N times).
- [ ] Withdrawal/transfer/refund (double-spend, over-withdraw balance).
- [ ] Vote/like/follow limits, one-review-per-user.
- [ ] Invite/referral credit (multiply credits).
- [ ] 2FA/OTP attempt counters (bypass rate limit).
- [ ] Account/username registration (claim same unique resource twice).
- [ ] Stock/inventory (buy more than available).

## Technique
- Burp **Turbo Intruder** or Repeater **"send group in parallel"** (single-packet attack for HTTP/2).
- Fire 20–50 identical requests in one TCP/H2 window (last-byte sync).
- Compare expected count vs actual (e.g. balance -100 five times but only -100 once).

## Single-packet attack
HTTP/2 lets you finish many requests' last frame together → sub-millisecond alignment. Best for tight windows.

## Multi-step / stale-token races (most hunters stop at single-request)
The window isn't always one endpoint — it's between two steps of a flow:
- [ ] **Token used after logout / password reset / MFA enrollment:** fire the action in parallel with (or right after) the revocation → old token still lands (overlaps `09-advanced/10-state-desync.md`).
- [ ] **Two account-change requests at once** (email + password, or two email changes) → inconsistent final state / bypass a "confirm current password" check.
- [ ] **Parallel checkout during stock/limit flow:** N buyers for 1 unit; buy-more-than-stock; apply-then-remove item keeping a discount.
- [ ] **Double-withdraw / double-refund / double-transfer:** race the balance check.
- [ ] **Redeem same coupon/gift/invite twice** across two accounts simultaneously.
- [ ] **Confirm + cancel** (payment, order, subscription) fired together → keep the good state, undo the charge.
- [ ] **Multi-request setup:** step A creates a pending object, step B consumes it — race B before A commits/validates.

## Impact
Financial (double-spend), limit bypass, integrity break.

## Tools
Turbo Intruder, Burp Repeater group (parallel), `race-the-web`.

## 🎯 PoC — Request → Response (single-use gift card redeemed N×)

Fire 20 copies in one HTTP/2 packet (Turbo Intruder / Repeater parallel group):
```http
POST /api/v2/wallet/redeem HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"code":"GIFT-100-USD"}
```
Multiple responses succeed instead of one:
```http
HTTP/2 200 OK      {"credited":100,"balance":100}
HTTP/2 200 OK      {"credited":100,"balance":200}
HTTP/2 200 OK      {"credited":100,"balance":300}
...
HTTP/2 409 Conflict {"error":"code_already_used"}    ← only later requests lose the race
```
Balance ends at `$700` from one `$100` code. Independent `GET /wallet` confirms the impossible balance.

## Deep cuts — winning tighter windows & finding them
- [ ] **Single-packet attack (the reliable one):** HTTP/2, ~20-30 requests, hold every request's last frame and release together (Turbo Intruder `engine=Engine.BURP`/`gate`, or Repeater "send group in parallel"). Removes network jitter → sub-ms alignment even over the internet.
- [ ] **Connection warming + last-byte sync (HTTP/1.1):** pre-send all-but-one byte of each request, then flush the final bytes together on warmed keep-alive connections.
- [ ] **Dependent-request races (Turbo Intruder pipeline):** race step B against step A's commit — e.g. use a token the instant before it's marked consumed; requires ordering, not just parallelism.
- [ ] **Eventual-consistency abuse:** distributed DB / read-replica lag → write once, read-before-replicate lets a check pass on a stale replica (redeem, balance, uniqueness).
- [ ] **Cache-fill / stampede race:** many parallel misses populate an under-derived value (price, entitlement) before the authoritative write lands.
- [ ] **Partial-limit overrun:** if the guard allows *some* concurrency, tune the count — the sweet spot is often 2-5, not 50 (too many can trip a coarse lock).
- [ ] **Detection heuristic:** any "once per {user,order,code}" rule, any balance/quota/counter, any two-step approve/consume, any uniqueness constraint (username/email/slug) is a candidate — try it before assuming it's locked.
- [ ] **Confirm from a second session:** prove the impossible end-state (balance, duplicate rows, two accepted uniques) via an independent read, not just multiple 200s.

## Report notes
Show the counter/balance ending in an impossible state (e.g. one $100 credit redeemed 5×). Include the parallel-request evidence (Turbo Intruder script / Repeater group + the response cluster).
