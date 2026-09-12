# Cache Attacks (Poisoning & Deception)

## Objective & Context
Cache attacks exploit the discrepancy between how a Content Delivery Network (CDN) or caching proxy processes a request and how the backend application processes it. This can lead to serving malicious content to legitimate users or leaking sensitive data.

## Recognition Patterns
*   **Headers:** `X-Cache: HIT`, `CF-Cache-Status: HIT`, `Age`.
*   **Architecture:** Applications using Cloudflare, Fastly, Akamai, or Varnish.
*   **Behaviors:** Static file extensions (`.js`, `.css`) appended to dynamic routes.

## Attack Mechanisms & Heuristics

### 1. Web Cache Poisoning
*   **Concept:** An attacker tricks the cache into saving a malicious response, which is then served to other users.
*   **Unkeyed Inputs:** Identify headers (e.g., `X-Forwarded-Host`, `X-Original-URL`) or cookies that alter the backend response but are *not* included in the cache key.
*   **Execution:** Send a request with a malicious unkeyed header that reflects an XSS payload. The CDN caches the response based on the URL (the cache key). Subsequent visitors to the URL receive the XSS payload.
*   **WAF Bypass:** Cache poisoning can sometimes bypass Web Application Firewalls. If a WAF blocks `<script>`, an attacker might use an unkeyed cookie like `hav="><img src=x onerror=alert(1)>`. The WAF might miss it, the backend reflects it, and the CDN caches it for everyone.

### 2. Web Cache Deception (WCD)
*   **Concept:** An attacker tricks the cache into saving a victim's sensitive, authenticated response.
*   **Static Extension Confusion (e.g. `.svg`, `.css`, `.ico`):**
    1.  Target endpoint: Authenticated JSON API `https://target.com/api/v2/account/profile`.
    2.  Appended static extension: `https://target.com/api/v2/account/profile.svg`.
    3.  Backend logic treats the path as `/profile` and returns the user's private JSON, but the edge web server or CDN assigns caching rules matching `*.svg` (e.g., `Cache-Control: public, max-age=31536000`).
    4.  Victim clicks the `.svg` link while logged in. The edge CDN caches their PII, credit cards, or bearer tokens globally.
    5.  Attacker fetches the same URL without credentials and dumps the victim's data.
*   **Path Delimiter Confusion Variations:**
    *   Semicolon matrix: `https://target.com/account/settings;test.css`
    *   Encoded hash/query: `https://target.com/account/settings%23test.jpg`
    *   Dot-segment normalization desync: `https://target.com/static/..%2faccount%2fsettings`

## Chaining Logic
*   `Cache Deception` -> `Session Token Extraction` -> `Account Takeover`
*   `Cache Poisoning` -> `Stored XSS on High-Traffic Page` -> `Mass Session Hijacking`

## Remediation & Validation
*   Ensure that any input (header, cookie, parameter) that alters the response is included in the cache key.
*   Configure the CDN to cache strictly based on `Content-Type` headers, not just URL extensions.
*   Never cache responses containing sensitive user data or session identifiers. Use `Cache-Control: private, no-store`.
