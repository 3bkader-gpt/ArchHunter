# Price & Amount Manipulation

**What it is:** The client sends the price/amount/total and the server trusts it. Tamper the value → pay less, pay nothing, or get paid.

## Test steps (tamper the price field in cart/checkout/payment request)
- [ ] Lower it: `100 → 50`.
- [ ] Negative: `100 → -100` (may credit your account / reduce order total).
- [ ] Negative to offset: add item at `-120` to cancel a `+120` item → free.
- [ ] Fractional multiplier: `100 → 0.5` or send `0.5*100` style if the field is evaluated.
- [ ] Zero: `100 → 0`.
- [ ] Change currency to a weaker one while keeping the number (`100 USD → 100 XYZ`).
- [ ] Decimal/precision: `100.00 → 100.001` rounding, or `0.001` micro-charges.
- [ ] Overflow: very large value → integer wrap to negative.
- [ ] String vs int: `"100"` → `100` → `[100]` → `{"amount":100}` (type confusion).
- [ ] Extra field via HPP/mass-assignment: `amount=100&amount=1`.

## Where the real price should live
Server-side, keyed by product ID from the DB. If changing the client value changes the charge, it is broken.

## Impact
Direct financial loss. Buy premium/products for free or negative cost. High severity.

## Report notes
Show the tampered request and the confirmed order/charge at the manipulated price. Do **not** complete real fraudulent purchases with real money beyond proving the server accepted the value — stop at order confirmation / use test cards where allowed.

## 🎯 PoC — Request → Response

**Client sends the price; server trusts it:**
```http
POST /api/v2/checkout HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"cart_id":"c_9f21","items":[{"sku":"PRO-PLAN","qty":1,"unit_price":0.01}]}
```
```http
HTTP/2 201 Created
Content-Type: application/json

{"order_id":"ord_44812","status":"paid","total":0.01,"plan":"PRO-PLAN"}
```
Server charged `$0.01` for a plan priced `$499`. Independent confirm:
```http
GET /api/v2/orders/ord_44812 HTTP/2
Authorization: Bearer <mine>
```
```http
HTTP/2 200 OK
{"order_id":"ord_44812","total":0.01,"status":"paid","entitlements":["PRO-PLAN"]}
```

## Deep cuts — money bugs past the obvious lower-the-price
- [ ] **Signed-price token swap:** server sends a signed/opaque price blob (`priceToken`, `lineItemHash`) to stop tampering — but it isn't bound to the SKU/qty. Grab the token from a *cheaper* product and submit it for an expensive one.
- [ ] **Tax/VAT/fees as the lever:** set `tax:-50`, `shipping:-x`, `fees:0`, or a tax-exempt flag; totals often sum blindly `subtotal+tax+ship`.
- [ ] **Loyalty points / store credit as currency:** redeem more points than held (race or negative), or value points at a tampered conversion rate.
- [ ] **Region / A-B / locale price:** switch `country`, `locale`, `store`, or `currency` header to a cheaper regional catalog, then ship anywhere. `1,000` vs `1.000` decimal-locale confusion changes the parsed amount 1000×.
- [ ] **Proration / upgrade-downgrade credit:** upgrade then immediately downgrade to bank a prorated credit larger than paid; or set `proration_date` in the past.
- [ ] **Gift-card arbitrage:** buy a gift card *with* a discount code, redeem for full face value = net money printer (pairs with `03-coupons`).
- [ ] **Rounding across many lines:** many `0.004` lines each round down to `0`, or partials each round *up* on refund (`04-refund`).
- [ ] **Quantity/price desync:** `qty` and `unit_price` validated separately; send high qty at a unit price captured from a bulk-discount tier.
- [ ] **Post-authorization edit:** modify the order/cart between "authorize" and "capture" so the captured amount ≠ the shown total.
- [ ] **Idempotency-key reuse:** reuse a prior successful charge's idempotency key on a new higher-value order → gateway returns the old cheap success (`08-workflow`).

## Report notes
Show the tampered request and the confirmed order/charge at the manipulated price. Do **not** complete real fraudulent purchases with real money beyond proving the server accepted the value — stop at order confirmation / use test cards where allowed.

## Reference
Parameter-tampering price manipulation demo: youtube `3VMlV7j_yzg`.
