# Authentication Bypass & Account Takeover (ATO)

## Objective & Context
Authentication mechanisms verify a user's identity. Bypassing these mechanisms or hijacking the flow allows attackers to assume the identity of other users. This skill focuses on logic flaws in password resets, OTP validation, SSO integrations, and callback handling.

## Recognition Patterns
*   **Endpoints:** `/password/reset`, `/forgot-password`, `/verify-otp`, `/login/sso`, `/auth/callback`.
*   **Parameters:** `email`, `user_id`, `otp`, `code`, `callbackUrl`, `redirect_uri`.
*   **Architecture:** Systems relying on email/SMS for out-of-band verification, or delegating trust to third-party Identity Providers (IdP).

## Attack Mechanisms & Heuristics

### 1. Password Reset Manipulation
*   **Multi-Email Array Injection:** Application expects a single email but accepts a JSON array. 
    *   *Payload:* `{"email": ["victim@target.com", "attacker@evil.com"]}`
    *   *Impact:* The backend iterates over the array, generating a valid reset token and sending it to *both* emails.
*   **Host Header Injection:** The backend constructs the password reset link using the `Host` header.
    *   *Payload:* `Host: evil.com`
    *   *Impact:* Victim receives an email with `https://evil.com/reset?token=123`.

### 2. OTP Validation Bypass
*   **Response Manipulation:** The client-side application trusts the server's HTTP response to proceed to the next step.
    *   *Execution:* Enter any OTP. Intercept the `400 Bad Request` or `{"success": false}` response. Modify it to `200 OK` or `{"success": true}`. If the client logs you in, the server lacks stateful enforcement.
*   **Information Disclosure in Response:** The server includes the generated OTP in the API response (e.g., in debug fields or hidden JSON properties).
*   **Rate Limit Missing:** Brute-force the 4- or 6-digit PIN if rate limiting is absent or bypassable (e.g., via IP rotation or `X-Forwarded-For` spoofing).

### 3. SSO and SCIM Provisioning Abuse
*   **SAML Signature Bypass:** Removing the signature, stripping elements, or using control characters (`%0d%0a`) in domain parameters to bypass validation.
*   **SCIM Import Hijacking:** When syncing users from a corporate directory, altering the email or username in the SCIM payload to match an existing high-privilege account.

### 4. Callback and Deeplink Hijacking
*   **Open Redirect to Token Theft:** If the authentication flow uses a `callbackUrl` parameter that is not strictly validated, an attacker can point it to their server.
    *   *Execution:* Victim clicks link, authenticates, and is redirected to `https://evil.com/?token=abc`.
*   **Mobile Deeplink Hijacking:** Deep links (e.g., `myapp://auth?token=...`) that are improperly validated by the mobile app can leak tokens to malicious apps or servers.

### 5. Email Verification Bypass Patterns
*   **Response Modification:** Client-side SPA routing blocks access to `/dashboard` based on JSON flag `{"is_email_verified": false}`. Intercept and change response body to `{"is_email_verified": true}` or HTTP status `403` to `200`.
*   **Forced Browsing / Direct API Access:** While web UI displays "Please verify your email", backend API endpoints (`/api/v1/projects`, `/api/v1/billing`) fail to assert email verification middleware, allowing full platform interaction.
*   **Token Expiration & Replay:** Reusing old verification links or tokens across different accounts or expired sessions.
*   **HTTP Parameter Pollution (HPP):** Sending `POST /api/verify?email=victim@target.com&email=attacker@evil.com` to manipulate backend verification status.

### 6. Unauthorized Email Modification & Account Lockout
*   **Missing Current Password Requirement:** Updating the account email via `PUT /api/v1/user/email` without verifying the user's current password.
*   **No Confirmation to Old Address:** Changes take effect immediately without sending an "Undo/Revert" link to the original email address, allowing an attacker with temporary session access to lock the true owner out permanently.

### 7. JWT Architectural & Design Flaws
*   **Minimalist Payload Anti-Pattern:** JWT only contains `{"sub": "<id>", "iat": ..., "exp": ...}` with no `iss`, `aud`, or `jti` (JWT ID).
*   **Missing Tenant / Context Binding:** Numerical or predictable `sub` with no organization or tenant identifier. When decoded by different internal microservices, an attacker-supplied token from tenant A is accepted in tenant B.
*   **Refresh Token Overloading:** Backend uses the *Refresh Token* interchangeably for both API authentication and session refresh, completely negating token revocation and short-lived access lifecycles.

### 8. Authentication Gateway Re-hashing DoS
*   **Algorithmic Complexity Abuse:** Submitting an oversized password (~1.3k - 5k characters) during login or registration.
*   **Impact:** Expensive key-derivation functions (bcrypt, PBKDF2, Argon2) or unbuffered string copying trigger CPU exhaustion and Gateway Timeouts (`504 Gateway Timeout`) with a **single HTTP request**, causing application-level denial of service.

### 9. JWT Algorithm Confusion (RS256 to HS256)
*   **Failure:** The verification library uses `jwt.verify(token, key)` where `key` is the server's public RSA key (often reachable via `/.well-known/jwks.json` or extracted from public certificates). If the library accepts the algorithm from the token header without restriction:
*   **Exploitation:**
    1. Obtain the server's public key (e.g. PEM format).
    2. Change the token header from `{"alg": "RS256"}` to `{"alg": "HS256"}`.
    3. Modify the payload (e.g. `{"user_id": "admin", "role": "superuser"}`).
    4. Sign the token with HMAC-SHA256 using the **literal text of the public key** as the HMAC secret key.
    5. The backend verifies the signature with its configured key using HMAC, and verification succeeds.
    *   **Impact:** Unrestricted arbitrary JWT forgery and instant Account Takeover.

### 10. Client-Side Authentication Bypass & Frontend Guard Tampering
Many Single Page Applications (React, Vue, Angular, Next.js) implement route guards that check authentication exclusively in JavaScript:
*   **Mechanism:** Client code checks variables or objects stored in `localStorage` or `sessionStorage` to decide whether to render protected views (e.g. `/admin`, `/dashboard`, `/settings`).
*   **Indicators in JS Bundles:**
    ```javascript
    authRequired, isLoggedIn, isAuthenticated, userInfo, tokenExpiry, is_active, userRole
    ```
*   **Exploitation:**
    1. **Storage State Injection:** Inject mock user session objects into the browser console:
       ```javascript
       sessionStorage.setItem("userInfo", JSON.stringify({ "id": 1, "role": "admin", "permissions": ["*"] }));
       localStorage.setItem("isLoggedIn", "true");
       localStorage.setItem("tokenExpiry", "9999999999");
       ```
    2. **Dummy JWT Injection:** When the UI decodes client tokens via `jwt_decode()` without immediate backend validation, injecting a self-signed or forged JWT unblocks full administrative UI views.
    3. **Forced Browsing / Unprotected API Endpoints:** Once the frontend UI is unlocked, observe which backend API endpoints are queried. Developers who made the frontend-only auth mistake often forget authentication middleware on corresponding backend endpoints (e.g. `GET /api/v1/admin/users`), allowing full unauthenticated data extraction!

## Chaining Logic
*   `Pre-ATO (OAuth Auto-Link)` -> `Persistent Backdoor` -> `Account Takeover`
*   `Email Verification Bypass` -> `Unverified Account Feature Execution` -> `Phishing & Spamming`
*   `Open Redirect` -> `Token Exfiltration` -> `Account Takeover`
*   `Information Disclosure (/reports/:id.json)` -> `OTP Backup Codes Leaked` -> `2FA Bypass` -> `Account Takeover`

## Remediation & Validation
*   Never trust client-side validation for authentication steps.
*   Require current password verification for any sensitive profile change (email, phone, 2FA).
*   Enforce `email_verified == true` strictly at the API gateway layer for all authenticated routes.
*   Validate `callbackUrl` and `redirect_uri` against a strict, static allowlist.

