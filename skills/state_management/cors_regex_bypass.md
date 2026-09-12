# CORS Regex Bypass

## Objective & Context
*   **Security Assumption Failure:** The application assumes that its regular expression for validating the `Origin` header securely restricts cross-origin requests to trusted subdomains or partners.
*   **Trust Boundary Violation:** The server reflects the attacker-controlled `Origin` header in the `Access-Control-Allow-Origin` (ACAO) response header because the validation logic (often a regex) is overly permissive or flawed, allowing unauthorized cross-origin requests (often with credentials).

## Recognition Patterns
*   **Mechanism:** Any API endpoint handling cross-origin requests, especially those returning sensitive data or performing state changes.
*   **Headers:** The presence of `Access-Control-Allow-Credentials: true` alongside a dynamically reflected `Access-Control-Allow-Origin`.
*   **Architecture:** Applications utilizing multiple subdomains, third-party integrations, or API gateways.

## Attack Preconditions
*   The target endpoint must rely on CORS for protection (e.g., it uses cookie-based authentication or relies on the browser to send credentials automatically).
*   The CORS implementation must dynamically reflect the `Origin` header based on weak validation.

## Step-by-Step Validation Strategy
1.  **Baseline Testing:** Send a request with `Origin: https://evil.com`. 
    *   If it returns `Access-Control-Allow-Origin: *`, it means CORS is open but typically browsers will reject requests that include credentials (unless specific insecure browser settings are used).
    *   If it does not return the `Access-Control-Allow-Origin` header at all, CORS validation is working correctly (rejecting the bad origin).
    *   If it reflects `Access-Control-Allow-Origin: https://evil.com`, you have found a reflection.
    *   **Crucial Step:** Ensure that `Access-Control-Allow-Credentials: true` is also returned. Without it, the browser won't send cookies, severely limiting impact.
2.  **Unescaped Dot Bypass:** Test if the regex fails to escape dots (`.`). Change the origin to `https://appXtarget.com`. If reflected, register `appXtarget.com` to bypass CORS.
3.  **Prefix/Suffix Bypass:** Test if the regex lacks start/end anchors (`^` and `$`).
    *   **Suffix:** Send `Origin: https://app.target.com.attacker.com`. If reflected, the regex checks if the origin *starts* with `https://app.target.com`.
    *   **Prefix:** Send `Origin: https://attacker.com/app.target.com` (though browsers usually don't send paths in Origin, testing `https://attackerapp.target.com` is more realistic for suffix matching).
4.  **Null Origin:** Send `Origin: null`. Some configurations explicitly allow `null` (often used for local file testing), which an attacker can exploit via a sandboxed iframe (`<iframe sandbox="allow-scripts allow-top-navigation allow-forms" src="data:text/html,...">`).
5.  **Subdomain Takeover Chain:** If the regex correctly restricts to `*.target.com`, look for an abandoned or vulnerable subdomain (e.g., `blog.target.com`) to host the malicious CORS payload.

## Common Weak Implementations
*   Regex missing anchors: `match("https://.*\.target\.com")` allows `https://attacker.com/?.target.com` (if the framework allows unusual Origin parsing) or more commonly `https://attacker-target.com`.
*   Unescaped dots: `match("^https://.*.target.com$")` allows `https://my-target.com`.
*   Trusting any domain containing the target name: `origin.includes("target.com")`.

## Escalation Paths
*   **Data Exfiltration:** Reading sensitive JSON responses containing PII, API keys, or CSRF tokens.
*   **CSRF Bypass:** Using the extracted CSRF token to perform unauthorized state-changing actions.

## Detection Opportunities
*   **Anomalous ACAO Headers:** Monitoring response headers for ACAO values that do not match a strict whitelist of known production domains.
*   **Unexpected Origin Headers:** Logging `Origin` headers that trigger API errors or hit the fallback/default CORS policy.

## Notes
*   **False Positives:** If `Access-Control-Allow-Credentials: true` is missing, the browser will not send cookies, limiting the impact to unauthenticated data exposure.
*   **Constraints:** The attacker must lure the authenticated victim to a malicious site they control (or a compromised allowed subdomain).
