# Multi-Factor Authentication (MFA / 2FA) Logic Bypass Manual

This mechanism manual documents tactical and architectural flaws in Multi-Factor Authentication (MFA/2FA) implementations, covering client-side response manipulation, race conditions, legacy protocol parity, and token lifecycle vulnerabilities.

---

## 1. The Multi-Step Authentication State Machine

MFA is fundamentally a state machine:
```
[State 0: Unauth] ──► Submit User/Pass ──► [State 1: Partially Auth (MFA Required)] ──► Submit OTP ──► [State 2: Fully Auth]
```
Vulnerabilities occur when transitions between State 1 and State 2 can be forged, skipped, or decoupled from the active session.

---

## 2. Core Exploitation Vectors

### Vector A: Direct Navigation & Forced Browsing
* Many applications set the complete session cookie upon password verification (State 1) and merely display an overlay or client-side route guard (`/auth/mfa`).
* **Test:**
  1. Authenticate with username and password.
  2. When prompted for 2FA, do NOT submit the code.
  3. Manually browse directly to `/dashboard`, `/settings`, or request an authenticated API endpoint: `GET /api/v1/user/profile`.
  4. If the server evaluates the session cookie as valid without checking the `mfa_completed` flag, MFA is bypassed.

### Vector B: Response Status & Body Manipulation
* Single Page Applications (React, Vue, Angular) often rely on boolean flags in API responses to trigger UI transitions.
* **Test (via Burp Suite Match & Replace / Intercept):**
  1. Submit an invalid OTP code (`000000`).
  2. Intercept the HTTP response:
     ```http
     HTTP/1.1 401 Unauthorized
     Content-Type: application/json

     {"success": false, "message": "Invalid 2FA code"}
     ```
  3. Modify response headers and payload:
     ```http
     HTTP/1.1 200 OK
     Content-Type: application/json

     {"success": true, "token": "<INTERMEDIATE_TOKEN>", "mfa_verified": true}
     ```
  4. Observe if the client application stores the token and grants access.

### Vector C: Legacy & Mobile API Parity
* Modern Web frontends require 2FA, but legacy REST endpoints or mobile gateways still authenticate with username and password alone.
* **Test:**
  - Query legacy endpoints extracted from JavaScript or mobile APKs:
    * `POST /api/v1/mobile/login`
    * `POST /api/v1/auth/token`
    * `POST /oauth/token` with `grant_type=password`
  - Verify if these endpoints issue full access tokens without triggering an MFA challenge.

### Vector D: OTP Concurrency & Limit Overrun (Race Conditions)
* When an application restricts OTP attempts (e.g. lockout after 5 incorrect guesses), lack of atomic database locks allows brute-forcing via Turbo Intruder:
* **Test:**
  - Send 100 concurrent requests containing 6-digit OTP candidates in a single TCP connection (Single-Packet Attack) before the failure counter is incremented in Redis/DB.

### Vector E: Pre-Authentication Token Leakage / Predictive OTP
* Inspect response headers and cookies returned during password submission for leaked OTP values or predictable cryptographic nonces.

---

## 3. 10-Point Validation Gate for MFA Findings
1. Did the bypass yield a **fully authenticated, persistent session** capable of performing state-changing actions?
2. Did you verify that the victim account actually had 2FA enforced and active?
3. Can the attack be reproduced consistently from an incognito window?
