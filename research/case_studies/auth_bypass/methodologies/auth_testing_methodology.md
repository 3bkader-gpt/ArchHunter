# Authentication & Authorization Bypass Pentesting Methodology

A battle-tested, structured methodology for identifying, exploiting, and reporting authentication bypasses, broken access control (BAC), and account takeover (ATO) vulnerabilities in modern web and mobile applications.

---

## Phase 1: Authentication Architecture Reconnaissance

1. **Mapping Authentication Entry Points:**
   - Standard username/password login endpoints (`/api/v1/auth/login`, `/users/sign_in`).
   - Social & Single Sign-On (SSO) login (`/oauth/authorize`, `/auth/google`, `/saml/login`).
   - Password reset and magic link mechanisms (`/auth/forgot-password`, `/auth/magic-link`).
   - Registration and user invitation flows (`/api/register`, `/team/invite/accept`).

2. **Session Identification & Token Analysis:**
   - Determine session type: Cookie-based (session cookies, HttpOnly, SameSite), Bearer Token (JWT, opaque tokens), or API keys.
   - Inspect token contents (Header, Payload, Signature in JWT).
   - Check entropy, predictability, and expiration enforcement.

---

## Phase 2: Core Authentication Bypass Techniques

### 1. Direct Response / Status Manipulation
- Intercept the failed login or 2FA verification response in Burp Suite / Caido.
- Alter response status and body:
  - Change `HTTP/1.1 401 Unauthorized` or `403 Forbidden` to `HTTP/1.1 200 OK`.
  - Modify JSON payload from `{"success": false, "error": "Invalid code"}` to `{"success": true, "token": "..."}` or `{"authenticated": true}`.
  - Check if client-side redirection grants access to protected views or initializes a valid session.

### 2. Parameter Manipulation & Type Juggling
- **Parameter Pollution:** Submit duplicate parameters (e.g., `user=victim&user=attacker`).
- **JSON Data Type Mutation:**
  - Submit `{"password": true}` or `{"password": {"$ne": ""}}` (NoSQL injection).
  - Submit array instead of string: `{"code": [123456]}` or `{"code": 0}`.
  - Float vs. Integer vs. String type juggling.

### 3. Password Reset & Account Takeover (ATO) Vectors
- **Host Header Injection:** Manipulate the `Host` or `X-Forwarded-Host` header during password reset requests to leak the reset token to an attacker-controlled server.
- **Token Leaks via Referer:** Trigger a password reset, click the link, and observe whether the token leaks in `Referer` headers when external assets (fonts, analytics, CDN) are loaded.
- **Weak Token Generation:** Check if reset tokens are based on timestamps (`time()`), user IDs, or predictable MD5/SHA hashes.
- **Lack of Token Invalidation:** Verify if reset tokens remain valid after use, or if changing the password terminates existing active sessions across other devices.

---

## Phase 3: Two-Factor Authentication (2FA / MFA) Bypass

1. **Direct Endpoint Re-navigation (Forced Browsing):**
   - After entering valid credentials (Step 1), directly navigate to `/dashboard`, `/account/settings`, or `/api/user/profile` without entering the 2FA code.
2. **2FA Code Brute-Force & Rate-Limit Evasion:**
   - Check if 4-digit or 6-digit codes lack rate limiting.
   - Test IP-header rotation: `X-Forwarded-For`, `X-Real-IP`, `Client-IP`.
   - Test race conditions: Send concurrent verification requests using Turbo Intruder or Burp Repeater groups.
3. **2FA Disablement via Parameter Tampering:**
   - Submit 2FA deactivation requests without providing the current 2FA code or password.
   - Test IDOR on 2FA disable endpoints: `POST /api/user/1337/2fa/disable`.
4. **OAuth / SSO Overrides:**
   - If an account has 2FA enabled, log in using "Sign in with Google" or "Sign in with GitHub" linked to the same email; check if 2FA prompt is bypassed.

---

## Phase 4: Broken Access Control & IDOR (Authorization Testing)

1. **Horizontal Privilege Escalation (User A to User B):**
   - Identify all endpoints containing user-specific identifiers: `/api/users/{id}/profile`, `/invoices?customer_id=105`, `/orders/export?uuid=...`.
   - Swap identifiers between two accounts of the same privilege level.
   - Test numeric incrementing, UUID substitution, and GUID discovery via public profiles or search APIs.

2. **Vertical Privilege Escalation (Standard User to Admin):**
   - Access administrative routes: `/admin/users`, `/api/v1/management/export`, `/internal/metrics`.
   - Inspect client-side JavaScript bundles (`app.js`, `main.chunk.js`) for hidden admin endpoints, feature flags, or role parameters.
   - Header manipulation: Inject `X-Original-URL`, `X-Rewrite-URL`, `X-Custom-IP-Authorization`, `X-Forwarded-For: 127.0.0.1`.

3. **HTTP Method & Content-Type Tampering:**
   - If `GET /api/documents/10` is forbidden, try `POST`, `PUT`, `DELETE`, `PATCH`, or `HEAD`.
   - If `application/json` triggers access control filters, switch to `application/x-www-form-urlencoded` or `multipart/form-data`.

---

## Phase 5: OAuth 2.0 & SSO Implementation Flaws

1. **`redirect_uri` Validation Bypass:**
   - Parameter poisoning: `redirect_uri=https://legitimate.com.attacker.com`
   - Path traversal: `redirect_uri=https://legitimate.com/oauth/callback/../../attacker`
   - Open redirect chaining: Chain an open redirect on `legitimate.com` to steal authorization codes.
2. **Missing `state` Parameter (OAuth CSRF):**
   - If `state` is missing or static, an attacker can complete the authorization flow and bind their identity to the victim's session.
3. **Pre-Account Takeover via Account Linking:**
   - Register an account with `victim@example.com` using password.
   - Log in with Google using `victim@example.com` without requiring password confirmation.
