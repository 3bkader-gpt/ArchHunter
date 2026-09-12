# OAuth & SSO Implementation Integrity

## Mechanism Overview
OAuth and SSO (Single Sign-On) delegate authentication to third-party Identity Providers (IdP). Vulnerabilities occur in the **Handshake**, **Token Validation**, and **Callback Handling** phases.

## 1. High-Signal Handshake Failures

### Redirect URI Hijacking
*   **Mechanism:** An attacker modifies the `redirect_uri` parameter during the authorization request.
*   **Failure:** The IdP fails to strictly validate the URI against a static allowlist, sending the authorization `code` or `token` to the attacker's server.
*   **Offensive Pivot:** Test `redirect_uri=//attacker.com`, `redirect_uri=https://target.com.attacker.com`, and path traversal `redirect_uri=https://target.com/callback/../../attacker`.

### Missing State (CSRF)
*   **Mechanism:** The `state` parameter is used to link an authorization request with its callback.
*   **Failure:** If `state` is missing or not verified, an attacker can force a victim to "link" the victim's account to the attacker's third-party identity.
*   **Audit Goal:** Attempt the OAuth flow without the `state` parameter or with a static `state` value.

---

## 2. Advanced Validation Gaps & Context Confusion

### Audience Confusion & Cross-Client Replay
*   **Mechanism:** An application accepts a cryptographically valid token that was actually issued for a different client.
*   **Failure:** The server fails to check the `aud` (Audience) claim in the JWT. An attacker obtains a token for a low-privileged public app and replays it against a highly privileged admin API.
*   **Audit Goal:** Swap tokens between different applications or services owned by the same organization.

### Tenant Hopping (Cross-Tenant Replay)
*   **Mechanism:** Multi-tenant SaaS ecosystems where a central IdP issues tokens for all tenants.
*   **Failure:** The resource server validates the signature but fails to validate `tenant_id` claims against the resource being accessed.
*   **Audit Goal:** Change the tenant ID in the URL (`/api/v1/tenant/VICTIM_ID/users`) while providing a token validly issued for your own tenant.

### Contextual Drift & Identity Propagation (The "Trusted Subsystem" Pitfall)
*   **Mechanism:** Identity is translated from an Edge token to a simplified internal header (e.g., `X-User-ID`) or workload identity.
*   **Failure:** Internal services assume the "Edge" has fully validated the user and their context. If an attacker can reach the internal service directly (via SSRF) or reuse a token issued for a different purpose (e.g., "Reset Password" token used for "API Access"), they bypass primary authorization.
*   **Audit Goal:** Identify internal identity-passing headers (test via SSRF). Swap tokens across different functional boundaries.

### OIDC Discovery Manipulation & Blind SSRF
*   **Mechanism:** In enterprise SSO (Okta, Azure AD, custom OIDC), the platform prompts the user for their OIDC Issuer URL:
    `POST /api/sso/configure {"issuer": "https://auth.enterprise.com"}`
*   **Failure:** The backend immediately fetches `/.well-known/openid-configuration` and `jwks_uri` from the user-provided URL without restricting internal IP ranges.
*   **Offensive Pivot:**
    *   Provide `http://169.254.169.254` or `http://127.0.0.1:8080` to trigger direct Blind/Full SSRF.
    *   Host an attacker OIDC server with `jwks_uri` pointing to an internal service, or supply an attacker-controlled public key to forge arbitrary administrative `id_token` claims.

### PKCE Downgrade & Code Challenge Stripping
*   **Mechanism:** Proof Key for Code Exchange (PKCE) protects public/SPA clients by binding an authorization code to a `code_verifier`.
*   **Failure:** The Authorization Server accepts requests where `code_challenge` and `code_challenge_method` are simply omitted.
*   **Exploitation:** If the attacker intercepts an authorization code, but lacks the victim's client secret or code verifier, they strip the PKCE parameters from the initial request, forcing the server to downgrade to legacy Code Flow without verifier validation.

### Unverified Third-Party Email Collision
*   **Mechanism:** Automatic account linking based solely on the `email` claim of the OIDC `id_token`.
*   **Failure:** Some Identity Providers (e.g. self-hosted GitLab, custom OAuth providers) issue tokens without verifying email ownership (`email_verified: false`). If the service provider ignores `email_verified`, an attacker creates an unverified account on the IdP using the victim's email and signs in, automatically seizing control of the victim's existing account.

---

## 3. Escalation Logic
*   **Redirect Hijack** -> **Authorization Code Theft** -> **Account Takeover**.
*   **Missing State** -> **Account Linking Attack** -> **Full ATO**.
*   **Audience/Tenant Confusion** -> **Cross-App/Cross-Tenant Data Access**.
*   **Trusted Subsystem Bypass** -> **Internal API Takeover**.

## 4. Operational Checklist
*   Does the `redirect_uri` support wildcards or open redirects?
*   Is the `state` parameter present and high-entropy?
*   Does the app check the `iss`, `aud`, and `tenant_id` claims in incoming JWTs?
*   Can you reuse a "Password Reset" token as an "Auth" token (Contextual Drift)?
*   Are internal microservices trusting HTTP headers for identity without mutual TLS?
