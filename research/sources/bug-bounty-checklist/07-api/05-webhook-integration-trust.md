# Webhook & Integration Trust Bugs

**What it is:** Apps trust their integrations (Stripe, GitHub, Slack, Zapier, internal services) far more than end users. Forge, replay, or abuse that trust → auth bypass, data injection, financial fraud, SSRF. Under-tested because it looks like "internal" traffic.

## Inbound webhooks (you → the app's webhook receiver)
- [ ] **Forged events (no/weak signature):** POST a fake provider event directly to the receiver:
```http
POST /webhooks/stripe HTTP/2
Host: target.com
Content-Type: application/json

{"type":"checkout.session.completed","data":{"object":{"customer":"me","amount_total":0,"payment_status":"paid"}}}
```
```http
HTTP/2 200 OK
{"received":true}      ← no signature check → you just "paid" for free = fraud
```
- [ ] **Signature bypass:** missing `Stripe-Signature`/`X-Hub-Signature` still accepted; signature verified but timestamp not (replay); wrong-algorithm accepted; signature over a subset of the body; HMAC secret leaked in JS/repo.
- [ ] **Replay old events:** re-send a real captured event (grant, payment, "subscription active") N times → duplicate credits/entitlements.
- [ ] **Test/staging secrets accepted in prod:** provider "test mode" signing key or a staging secret validates against production.
- [ ] **Type/field confusion:** send an event type the handler trusts (`invoice.paid`, `role.granted`) with tampered amounts/ids.
- [ ] **IDOR in event payload:** set `customer`/`user_id`/`account` to a victim → the handler mutates *their* state.

## Outbound webhooks / integration config (app → your server)
- [ ] **SSRF via webhook URL:** set the destination to `http://169.254.169.254/...` or an internal host; the app's server fetches it (`03-injection/06`).
- [ ] **Blind SSRF / port scan** through the "test webhook" button.
- [ ] **Secret leakage:** the app sends its bearer/signing secret to your webhook URL; capture it.
- [ ] **Data exfil to integration:** configure an integration/logging/notification sink that pulls sensitive data (other users' events) into a channel you control.

## Third-party integration abuse
- [ ] **OAuth app over-scoping:** an integration requests/holds more scopes than needed → pivot.
- [ ] **Shared/guessable integration IDs** → attach your integration to another tenant's events (`01-access-control/05`).
- [ ] **Log injection:** integration writes attacker input into logs/notifications that render unsanitized (stored XSS in an internal tool → second-order, `09-advanced/01`).

## Detection
- [ ] Find webhook receivers: `/webhook(s)`, `/callback`, `/hooks/<provider>`, `/integrations/*`, `/notify`.
- [ ] Grep JS/repo for signing secrets, webhook URLs, provider names.
- [ ] Send an unsigned + a wrong-signed + a replayed event; compare acceptance.

## Impact
Payment/entitlement fraud (forged/replayed events), account state tampering (IDOR events), SSRF→cloud creds, secret theft, stored XSS in internal tooling.

## Report notes
For forged events, show the unsigned/replayed request accepted and the resulting state change (credit granted, "paid"). For SSRF, Collaborator hit from the server IP. Use minimal amounts; don't commit real fraud.

## Deep cuts — signature, replay, and SSRF-filter nuances
- [ ] **Signature comparison flaws:** non-constant-time `==` (timing leak of the HMAC), signature over a subset/normalized body (mutate an unsigned field), wrong-algorithm accepted (GitHub `X-Hub-Signature` sha1 vs `-256` — force the weaker), or the secret is a well-known default/leaked in JS/repo (`08-infra/04`).
- [ ] **Replay & idempotency:** no timestamp/nonce or a wide tolerance window → replay a real "paid"/"granted" event N times; missing idempotency-key check → duplicate entitlements/credits.
- [ ] **Test-vs-prod key crossover:** provider test-mode signing key or a staging secret validates in production.
- [ ] **Forged-event → state-machine advance:** a fake `kyc.approved`/`subscription.active`/`role.granted` flips server state without the real workflow (`02-business-logic/08`).
- [ ] **Outbound webhook SSRF-filter bypass:** the destination-URL validator is defeated by DNS-rebinding, a 302 redirect to internal, `[::1]`/decimal-IP/`@`-userinfo, or a "verified" domain that resolves internal (`03-injection/06`, `09-advanced/06`).
- [ ] **Retry amplification / DoS:** trigger events that make the app hammer your (or a victim's) endpoint; or a webhook loop between two integrations.
- [ ] **Standard-webhooks / Svix / provider libs:** check the exact verify call is present *and* enforced (not logged-and-ignored); many apps parse the event before verifying.
- [ ] **Secret exfil via test button:** the "send test webhook" delivers the app's signing secret/bearer to your URL — capture it, then forge freely.

## Related
`03-injection/06-ssrf.md` · `02-business-logic/07-race-conditions.md` · `02-business-logic/08-workflow-and-result-tampering.md` · `09-advanced/01-second-order.md` · `01-access-control/05-cross-tenant-isolation.md`
