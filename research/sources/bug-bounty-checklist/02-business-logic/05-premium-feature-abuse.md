# Premium / Paywall Feature Abuse

**What it is:** Accessing paid features without paying, by forced browsing or flipping a client-side "entitled" flag.

## Test steps
- [ ] Force-browse premium endpoints/pages as a free user.
- [ ] Pay, cancel subscription — is the premium feature still usable after refund? (monetary impact).
- [ ] Find the true/false entitlement value in request/response and flip it.
- [ ] Burp **Match & Replace** on entitlement responses (`"premium":false`→`true`, `"plan":"free"`→`"pro"`) app-wide. **This is a RESPONSE edit — cosmetic until you prove the server serves the premium resource with interception off. Verify per `99-reference/05-response-manipulation-and-verification.md`. Prefer tampering the REQUEST (mass assignment, `07-api/03`).**
- [ ] Check cookies / localStorage / JWT for the access flag and tamper it.
- [ ] Trial-reset: delete cookie / new device fingerprint / re-register to get endless trials.
- [ ] Downgrade-but-keep: cancel plan, confirm gated features remain enabled.
- [ ] Feature-flag endpoint returns the full flag list → enable paid flags client-side.

## Impact
Revenue loss, unauthorized feature access.

## 🎯 PoC — Request → Response (server-side, the real way)

Do not just flip the response — tamper the **request** and confirm the server persisted it:
```http
POST /api/v2/subscription HTTP/2
Host: api.target.com
Authorization: Bearer <free-user>
Content-Type: application/json

{"plan":"enterprise","trial":false,"seats":50}
```
```http
HTTP/2 200 OK
{"plan":"enterprise","status":"active","seats":50}
```
Independent confirm (interception off):
```http
GET /api/v2/features/export HTTP/2
Host: api.target.com
Authorization: Bearer <free-user>
```
```http
HTTP/2 200 OK
Content-Disposition: attachment; filename="full-export.csv"   ← paid feature served to free acct
```
If instead it returns `402 Payment Required` with interception off, your earlier response-flip was cosmetic (see `99-reference/05`).

## Deep cuts — paywall bypasses that persist server-side
- [ ] **Seat / license over-provisioning:** buy 1 seat, add N members via a membership endpoint that doesn't re-check seat count; each gets full paid access.
- [ ] **Org-invite trial farming:** get invited into a paid org as guest → inherit premium features; or self-invite across throwaway orgs for perpetual trials.
- [ ] **Entitlement cache TTL:** cancel/downgrade, then use the feature within the cache window; or force the cached `plan:pro` to persist by never triggering the refresh event.
- [ ] **API tier ungated:** the web UI enforces the plan, the API/mobile/GraphQL twin of the same action doesn't (`07-api/01`, `07-api/02`).
- [ ] **Grandfathered / internal plan values:** set `plan` to a legacy or internal tier (`beta`, `internal`, `founder`, `unlimited`) the validator still honors.
- [ ] **Feature-flag endpoint write:** the `/flags` endpoint that returns your flags also *accepts* them, or a `?ff_export=1` override toggles server behavior.
- [ ] **Downgrade-keeps-export / data-retention:** cancel, but the export/backup/API-key feature stays live long enough to exfil everything you paid to lock in.
- [ ] **Referral/credit → premium:** convert farmed referral credit into a paid plan for free (chains with `03-coupons` self-referral).
- [ ] **Metering bypass:** usage-based feature counts client-side, or the counter endpoint is writable/resettable → unlimited "metered" usage.

## Report notes
Show the flag/response you changed and the premium feature functioning on a free account. Server-side confirmation (feature actually performs paid work) beats a UI-only unlock.
