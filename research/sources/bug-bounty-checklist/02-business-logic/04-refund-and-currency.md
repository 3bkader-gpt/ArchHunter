# Refund Abuse & Currency Arbitrage

**What it is:** Exploiting refund logic and multi-currency conversion to extract money or keep paid features.

## Refund abuse
- [ ] Buy a subscription/product, request refund, check the feature is still usable (monetary impact).
- [ ] Race multiple cancellation/refund requests → multiple refunds for one purchase.
- [ ] Refund an already-consumed digital good / used credit.
- [ ] Refund to a different payment method/account than the one charged.
- [ ] Partial-refund rounding: many small partials that sum to more than paid.

## Currency arbitrage
- [ ] Pay in currency A (e.g. USD), request refund in currency B (e.g. EUR). Conversion-rate gap = net gain.
- [ ] Switch account currency between purchase and refund.
- [ ] Price a product in a weak currency, pay, then value it in a strong one.
- [ ] Exploit stale/cached exchange rates during a volatile window.

## Impact
Direct financial gain, service theft.

## 🎯 PoC — Request → Response (currency arbitrage)

Charged in a weak currency, refund requested in a strong one:
```http
POST /api/v2/orders/ord_44812/refund HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"amount":1000,"currency":"USD"}          # original charge was 1000 INR
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"refund_id":"rf_7781","amount":1000,"currency":"USD","status":"processed"}
```
Paid ~$12 (1000 INR), refunded $1000. Server never re-checked the original currency.

## Deep cuts — refund logic edges
- [ ] **Refund to store credit + chargeback:** take the refund as instant store credit, then dispute the original charge with the bank → paid twice.
- [ ] **Tax-only / fee-only refund keeping goods:** refund the tax or shipping component while the order stays fulfilled.
- [ ] **Partial-refund round-up:** split one refund into many small partials that each round in your favor and sum to > paid.
- [ ] **Refund after consuming referral/promo credit:** buy with credit, refund to *cash/original method*, net-extract the promo value.
- [ ] **Return-to-stock resale of digital goods:** refund a license/key that stays active, or that gets re-sold while you keep using it.
- [ ] **Refund a $0 / fully-discounted order:** refund path issues credit for an order that cost nothing.
- [ ] **Cross-method refund:** charged card A, refund to wallet/PayPal/card B you control — reconciliation gap.
- [ ] **Refund-then-cancel race:** parallel refund + cancel (or two refunds) for one order (`07-race`).
- [ ] **Subscription proration extraction:** upgrade→refund→downgrade cycles that each mint prorated credit.
- [ ] **Exchange-rate timing:** refund during a rate window using a stale/cached FX rate the server doesn't re-fetch.

## Report notes
Show the money flow: charged amount + refunded amount + the delta. Keep test amounts minimal; do not defraud real funds beyond proof.
