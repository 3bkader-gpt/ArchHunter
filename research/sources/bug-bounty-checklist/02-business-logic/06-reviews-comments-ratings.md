# Reviews, Ratings & Comment Abuse

**What it is:** Logic flaws in user-generated content: fake verified reviews, out-of-range ratings, impersonation, spam, injection.

## Reviews
- [ ] Post a review as a **Verified Reviewer** without purchasing the product (tamper the verified flag).
- [ ] Rating outside the 1–5 scale: `0`, `6`, `-1`, `999`, decimals.
- [ ] Same user posts multiple ratings for one product (also test as a race condition).
- [ ] Review file/photo upload accepts any extension (upload chain → see `06-file-upload/`).
- [ ] Post a review impersonating another user (tamper `author`/`user_id`).
- [ ] CSRF the review submission (often no token).
- [ ] Injection in review body/title: stored XSS, SQLi, SSTI.

## Comments / threads
- [ ] Unlimited comments where a limit should apply.
- [ ] "One comment per user" → race to post many.
- [ ] Post as a verified/privileged user by tampering params.
- [ ] Impersonate other users in comment authorship.
- [ ] Edit/delete another user's comment (IDOR).

## Impact
Reputation manipulation, spam, stored XSS (account takeover), impersonation.

## 🎯 PoC — Request → Response (forge Verified Reviewer + out-of-range rating)

```http
POST /api/v2/products/PRO-PLAN/reviews HTTP/2
Host: api.target.com
Authorization: Bearer <mine, never purchased>
Content-Type: application/json

{"rating":6,"verified_purchase":true,"author_id":"someone-else","body":"great"}
```
```http
HTTP/2 201 Created
Content-Type: application/json

{"id":"rev_9931","rating":6,"verified_purchase":true,"author":"someone-else"}
```
Server accepted `rating:6` (scale 1-5), the `verified_purchase` flag with no purchase, and a spoofed author = impersonation + rating manipulation.

## Deep cuts — UGC integrity + impact chains
- [ ] **Aggregate poisoning:** submit decimal/out-of-range/negative ratings that skew the star average (`rating:6` or `rating:-5` moves a 4.0 to 4.9 or tanks a competitor).
- [ ] **Review-bomb / competitor delete:** post en masse via race/HPP, or delete/flag-down a competitor's reviews through an IDOR on the review id.
- [ ] **Edit-after-verified:** post a benign review to earn the "verified purchase"/badge, then edit the body to spam/XSS/malicious link — badge persists.
- [ ] **Helpful-vote / reaction IDOR + race:** inflate "N found helpful", flip others' votes, or self-vote in a loop (`07-race`).
- [ ] **Reply-as-seller / staff impersonation:** tamper `role`/`author_type` on a reply to appear as official seller/support.
- [ ] **Incentivized-review flag hidden:** remove/flip the `incentivized`/`sponsored` disclosure flag the platform requires.
- [ ] **Stored-XSS pivot:** review body/title/author rendered in the seller dashboard or admin moderation queue → XSS fires in a *privileged* context = ATO (`03-injection/02`, `09-advanced/07`).
- [ ] **Image upload chain:** SVG/EXIF/polyglot in a review photo → stored XSS or SSRF via thumbnailer (`06-file-upload`).
- [ ] **Rating without transaction:** post for a product/order you never touched by forging `order_id`/`verified_purchase` (BOLA on the purchase link).

## Report notes
For stored XSS show it firing in the victim context (bonus: in the seller/admin view). For fake verified review show the "verified" badge on a non-purchase.
