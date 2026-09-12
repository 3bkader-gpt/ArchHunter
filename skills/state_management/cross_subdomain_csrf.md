# Cross-Subdomain Trust Exploitation

## Objective & Context
*   **Security Assumption Failure:** The application assumes that setting cookies with `SameSite=None` or scoping them broadly across subdomains (e.g., `Domain=.example.com`) is safe as long as the core application (e.g., `account.example.com`) is secure.
*   **Trust Boundary Violation:** The core application trusts requests originating from sibling subdomains (e.g., `marketing.example.com` or `dev-api.example.com`) because of permissive cookie scoping and weak CORS configurations, allowing vulnerabilities in lower-security subdomains to compromise the core.

## Recognition Patterns
*   **Mechanism:** Authentication cookies and state-changing APIs.
*   **Architecture:** Complex applications spread across multiple subdomains.
*   **Headers:** 
    *   Cookies set with `SameSite=None`.
    *   Cookies explicitly scoped to the root domain (`Domain=.example.com`).
*   **CORS:** `Access-Control-Allow-Origin` allowing subdomains (e.g., via flawed regex like `.*\.example\.com`).

## Attack Preconditions
*   Authentication cookies must be sent cross-site (`SameSite=None`) or broadly scoped.
*   The attacker needs to find an injection vulnerability (like XSS or HTML injection) on *any* associated subdomain, or potentially achieve a Subdomain Takeover.

## Step-by-Step Validation Strategy
1.  **Cookie Profiling:** Log in to the main application and inspect the authentication cookies. Check for `Domain` scoping and `SameSite` attributes.
2.  **CORS Mapping:** Use an intercepting proxy to test CORS configurations on sensitive API endpoints. Check if they allow `Origin` headers from arbitrary subdomains (e.g., `https://anything.example.com`).
3.  **Vulnerability Hunting on the Periphery:** Instead of focusing on the highly secure core application, broaden your recon to find XSS, open redirects, or subdomain takeovers on forgotten or lower-security subdomains (e.g., `help.example.com`, `blog.example.com`).
4.  **Exploit Chaining:**
    *   If you find XSS on `help.example.com`, write a payload that sends an `XMLHttpRequest` or `fetch` to `account.example.com/api/change-password`.
    *   Because the cookies are scoped to `.example.com` or `SameSite=None`, the browser will attach the victim's session cookies to the request.
    *   Because the API's CORS policy trusts `*.example.com`, the request is permitted and the response can be read.

## Common Weak Implementations
*   Using `SameSite=None` to fix integration issues without implementing robust anti-CSRF tokens.
*   **CSRF Token Context Confusion (Cross-Form Replay):** The backend validates that a submitted CSRF token belongs to the session, but fails to tie it to the specific action/form. A token issued for a low-risk or public form (e.g. Password Reset Request or Contact Us) is accepted on a critical state-changing endpoint (e.g. Profile Update or Email Change). Chaining this with a low-impact CORS leak on the public form yields full Account Takeover.
*   Regex mistakes in CORS validation (e.g., matching `attacker-example.com` when aiming for `*.example.com`).
*   Assuming that static or marketing subdomains don't need strict security because "they don't handle sensitive data."

## Escalation Paths
*   **Full Account Takeover:** Forcing password resets, email changes, or token generation via the core API.
*   **Mass Data Theft:** Reading sensitive user data by exploiting XSS on a completely unrelated subdomain.

## Detection Opportunities
*   **CORS Anomaly Detection:** Monitoring for `Origin` headers that match the allowed pattern but originate from forgotten or unused subdomains.
*   **Cross-Subdomain API Calls:** Telemetry detecting sudden spikes in API requests originating from marketing or support subdomains.

## Notes
*   **False Positives:** Sometimes broadly scoped cookies are just tracking/analytics cookies, not actual session tokens.
*   **Constraints:** Requires finding a vulnerability on a valid subdomain or bypassing CORS regex checks.
