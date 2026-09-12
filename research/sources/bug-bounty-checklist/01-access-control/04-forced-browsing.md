# Forced Browsing & Missing Function-Level Access Control

**What it is:** Restricted pages/endpoints are protected only by "not being linked" or by a client-side redirect, not by a server-side check.

## Test steps
- [ ] Access authenticated pages while logged out (does content render before the JS redirect?).
- [ ] Intercept and drop the redirect response — is the body already the protected content?
- [ ] Hit API endpoints directly without the referring UI page.
- [ ] Access another tenant's/org's resource by guessing predictable slugs.
- [ ] Try `/print`, `/export`, `/pdf`, `/download` variants that skip auth.
- [ ] Access step 3 of a wizard without completing steps 1–2.
- [ ] Old/deprecated routes still live (`/old/`, `/v1/`, `/beta/`).

## Classic tell
Response is `302 → /login` but the `302` body **already contains** the sensitive data. The redirect is cosmetic; data leaked.

## Impact
Info disclosure, unauthorized actions, auth bypass.

## Multi-tenant / cross-org isolation
- [ ] Resource keyed by tenant slug/org id in the path (`/org/acme/reports`) → swap to another org you don't belong to.
- [ ] Shared/invited resource stays accessible after your access is revoked (stale grant).
- [ ] Object created in tenant A visible via tenant B's listing (missing tenant scoping on the query).

## Tools
`ffuf`/`feroxbuster` with authenticated + unauthenticated sessions, diff the two. Burp **Autorize** for automatic unauth/low-priv replay.

## 🎯 PoC — Request → Response

**Redirect is cosmetic — body already leaks the data:**
```http
GET /admin/dashboard HTTP/2
Host: target.com
Cookie: session=<logged-out / low-priv>
```
```http
HTTP/2 302 Found
Location: /login
Content-Type: text/html
Content-Length: 8421

<!doctype html><h1>Admin Dashboard</h1>
<table><tr><td>Total revenue</td><td>$1,204,551</td></tr>
<tr><td>Users</td><td>48,201</td></tr>...     ← full page in the 302 body
```
The `302` never stops rendering; the sensitive data ships anyway. Confirm in Burp (raw response), not the browser.

## Deep cuts — reach the gated route another way
- [ ] **Method swap to dodge the guard:** `GET /admin/x` 403s but `POST`/`HEAD`/`OPTIONS`/`PATCH` isn't guarded; or the router maps an unlisted verb to the same handler.
- [ ] **403/401 path-trick bypass:** `/admin` → `/admin/`, `/admin/.`, `/admin%2f`, `/./admin`, `/Admin`, `/admin..;/`, `/admin?`, `/%2e/admin`, add `X-Original-URL: /admin` / `X-Rewrite-URL` — run the full matrix via `/bypass-403` (`10-server-edge/04`).
- [ ] **Header-based gate bypass:** guard keys on `Referer`, `Origin`, `X-Requested-With: XMLHttpRequest`, or `X-Forwarded-For: 127.0.0.1` → supply/spoof it.
- [ ] **Version/host skew:** `/v1/admin` unguarded while `/v2/admin` is; internal vhost (`admin.internal`) serves the same app without the edge auth.
- [ ] **Wizard/step state in the client:** step gating stored in a cookie/hidden field/JWT (`step=3`) — set it and jump straight to the privileged final step.
- [ ] **Pre-auth data in redirects/errors:** `302→/login`, `401`, and `500` bodies leaking the protected payload, `Location` echoing a signed URL, or a stack trace with data.
- [ ] **Static/rendered artifacts:** the gated report also exists at a cacheable/static path (`/exports/2024/report.pdf`, `/_next/data/.../page.json`, SSR JSON) with no auth.
- [ ] **`returnUrl`/`next` open handling:** the post-login redirect target reflects a signed or unsigned path that itself renders sensitive content.
- [ ] **GraphQL/REST twins:** the REST route is guarded but the GraphQL field returning the same data isn't (and vice-versa).

## Report notes
Show the protected data reachable without proper session/role. If you used a bypass trick, name it and show the guarded-vs-bypassed pair side by side.
