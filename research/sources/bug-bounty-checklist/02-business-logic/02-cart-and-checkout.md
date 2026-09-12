# Cart, Checkout & Delivery Abuse

**What it is:** Flaws in the multi-step purchase flow — quantities, delivery fees, step-skipping, and payment-gate bypass.

## Cart / wishlist
- [ ] Negative quantity to offset a positive item and balance the total to ~0.
- [ ] Quantity beyond available stock (oversell, or price/stock logic break).
- [ ] Quantity `0`, decimals, or huge values (overflow).
- [ ] Move an item from your wishlist into **another user's** cart, or delete from theirs (IDOR in cart ops).
- [ ] Add an out-of-stock / unreleased / hidden product by ID.

## Delivery / shipping charges
- [ ] Set delivery charge to negative to reduce final total.
- [ ] Force free delivery by tampering the shipping param/flag.
- [ ] Change shipping tier price to a cheaper one server-side.

## Checkout flow / payment gate
- [ ] Skip the payment step: complete order via the post-payment "success" endpoint directly.
- [ ] Reuse an old successful-payment token/reference for a new order.
- [ ] Change order status to `paid`/`shipped` via an exposed status endpoint.
- [ ] Apply discount after total is locked, or edit the order between "review" and "pay".
- [ ] Race the "confirm" and "cancel payment" endpoints (see `07-race-conditions.md`).
- [ ] Login directly into the cart app bypassing the payment gateway auth (broken flow).

## Impact
Free/discounted goods, financial loss.

## 🎯 PoC — Request → Response (negative quantity offsets total)

```http
POST /api/v2/cart/items HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"items":[{"sku":"LAPTOP","qty":1,"unit_price":1200},
          {"sku":"USB-CABLE","qty":-4,"unit_price":300}]}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"cart_total":0.00,"lines":[{"sku":"LAPTOP","subtotal":1200},
 {"sku":"USB-CABLE","subtotal":-1200}]}      ← negative line zeroes the bill
```
Checkout ships the laptop for free.

## Deep cuts — checkout-flow logic most miss
- [ ] **Add another user's saved item / cart:** cart/wishlist ops keyed by item id, not owner (IDOR) → move theirs into yours or drop theirs.
- [ ] **Reserved-stock / hold abuse:** add-to-cart reserves inventory; loop it to deny stock to everyone (DoS) or hold a limited-drop item indefinitely.
- [ ] **Address swap after charge:** ship to a cheap-shipping zone at checkout, change the address post-authorization to the real (expensive/international) destination.
- [ ] **Mixed digital+physical:** free-ship on digital extends to a physical line; or a digital line auto-fulfills before payment settles.
- [ ] **Currency/store swap mid-flow:** start cart in one store/currency, pay in a cheaper one (`01-price` locale trick).
- [ ] **Idempotency-key replay:** reuse the key from a completed cheap order on a new order → gateway short-circuits to the old success without charging the new total.
- [ ] **Post-payment success forgery:** call the `/order/confirm` or thank-you/callback endpoint directly with a crafted `order_id`+`status=paid`, skipping the gateway (also webhook forgery, `07-api/05`).
- [ ] **Partial-capture / auth-only:** exploit auth-vs-capture gap — get goods on an authorization that's never captured, or is captured at a lower amount.
- [ ] **Quantity in a shadow field:** UI qty validated, but a second field (`line_qty`, `bundle_count`, `seats`) isn't.
- [ ] **Free-trial → paid item smuggle:** attach a paid SKU to a $0 trial checkout that skips the payment gate.

## Report notes
Show the exact tampered field + the completed order at the abused price/quantity/shipping. For flow bugs, capture each step so triage sees the skipped gate.
