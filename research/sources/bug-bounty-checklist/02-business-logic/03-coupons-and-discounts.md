# Coupon & Discount Abuse

**What it is:** Flaws in promo-code logic — reuse, stacking, injection, and applying codes where they should not apply.

## Test steps
- [ ] Reuse a single-use coupon multiple times (same account).
- [ ] Race the same one-time code across two accounts in parallel (race condition).
- [ ] Stack multiple codes via HPP / mass assignment when UI allows only one:
      `coupon=A&coupon=B` or `{"coupon":["A","B"]}`.
- [ ] Apply a code to items explicitly excluded from the promo (tamper server-side).
- [ ] Case/whitespace variants of an expired/invalid code to slip validation.
- [ ] Input attacks on the coupon field: XSS, SQLi, template injection (often unsanitized).
- [ ] Generate/guess predictable codes (`SAVE10`, sequential, base64 of amount).
- [ ] Combine percentage + fixed codes to push total negative.
- [ ] Apply a code, remove the item, keep the discount credit.

## Impact
Financial loss, unlimited discounts, occasionally injection RCE/XSS via the field.

## Tools
Burp Intruder (reuse/stack), Turbo Intruder (race).

## 🎯 PoC — Request → Response (stack one-per-order codes via HPP/array)

```http
POST /api/v2/cart/coupons HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"code":["SAVE20","SAVE20","WELCOME15","WELCOME15"]}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"applied":["SAVE20","SAVE20","WELCOME15","WELCOME15"],
 "discount_pct":70,"cart_total":149.70}      ← UI allows one; API stacked four
```

## Deep cuts — promo logic that prints money
- [ ] **Coupon on a gift card:** discount code applies to a stored-value/gift-card purchase → buy $100 card for $70, redeem for $100. Classic uncontested money bug.
- [ ] **Self-referral loop:** refer yourself via `+alias@`/disposable emails, or A refers B refers A, harvesting signup credit each cycle.
- [ ] **First-order-only bypass:** "new customers only" code defeated with a fresh email/device; or apply to a second order by tampering the `is_first_order`/`customer_since` field.
- [ ] **Threshold gaming:** min-spend `$100` for the code → add filler item to cross it, apply code, remove filler, keep discount (also `add-then-remove` credit).
- [ ] **Fixed-amount below subtotal → store credit:** `$50 off` on a `$30` order yields `-$20` banked as credit/refund instead of clamping at 0.
- [ ] **Currency mismatch on fixed code:** `100 OFF` intended as INR applied against a USD total (or vice-versa) via currency swap.
- [ ] **Guessable/leaked codes:** influencer/partner codes follow patterns (`NAME10`, `SUMMER25`), leak on IG/TikTok/retailmenot, or are sequential — enumerate.
- [ ] **Stacking beyond HPP:** apply code, then a second endpoint (`/apply-loyalty`, `/apply-credit`, `/apply-referral`) each independently reduces the *already-discounted* total.
- [ ] **Expired/scheduled code early:** tamper `valid_from`/timezone, or apply a future/expired code the server only checks client-side.
- [ ] **Injection in the field:** SSTI/SQLi/XSS in the coupon input (often an un-sanitized lookup) — `03-injection`.

## Report notes
Show final total with the abused discount and the request proving reuse/stack. For gift-card/credit arbitrage, show the net-positive money flow explicitly.
