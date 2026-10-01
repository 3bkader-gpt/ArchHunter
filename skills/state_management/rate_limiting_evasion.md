# Rate Limiting Evasion

## Objective & Context
*   **Security Assumption Failure:** The system assumes the rate-limit key (client IP, session token, or device fingerprint) is an attacker-controlled value it can trust, and that quota counters cannot be reset or parallelized.
*   **Trust Boundary Violation:** The gateway/edge layer computes the rate-limit key from spoofable inputs (`X-Forwarded-For`, `X-Real-IP`, `Client-IP`) instead of the TCP peer or an authenticated server-side identity, and the backend never re-checks.

## Recognition Patterns
*   **Mechanism:** Any endpoint enforcing a quota: login, OTP/2FA verification, password reset, registration, coupon redemption, search/export, AI/LLM chat endpoints.
*   **Behaviors:**
    *   `429 Too Many Requests`, `Retry-After`, `X-RateLimit-Limit/Remaining/Reset` headers.
    *   Blocking is immediate after N identical requests and clears after a time window or a client change.
    *   Blocks disappear when switching IP, browser profile, or deleting cookies — indicating a weak key.

## Attack Preconditions
*   The limiter keys on a header or client-supplied value rather than an authenticated principal.
*   Response differentiates "limit reached" from "invalid input" (allows an oracle for brute-force).
*   No server-side per-account lockout independent of the per-client quota.

## Step-by-Step Validation Strategy
1.  **Baseline Discovery:** Send 50–100 requests to the target endpoint; record the exact request count and response at which the limit triggers, and capture the limiter headers.
2.  **IP Header Rotation:** Replay the request rotating `X-Forwarded-For`, `X-Real-IP`, `CF-Connecting-IP`, `True-Client-IP`, `Client-IP`, `Forwarded`, `X-Client-IP`, `X-Originating-IP` with fresh values each attempt (`X-Forwarded-For: 1.2.3.<N>`). A success past the baseline proves header-keyed limiting.
3.  **IPv6 / Subnet Rotation:** If IPv6 is supported, iterate the /64 (`2001:db8::1` → `2001:db8::ffff`) — many limiters key the full address instead of the prefix.
4.  **Path & Method Mutation:** Vary the path so the limiter normalizes differently from the router: `/api/v1/login` vs `/api/v1//login` vs `/api/v1/./login` vs `/API/V1/login` vs `/api/v1/login;foo=bar`, and `POST` vs `PATCH`/`PUT` on handlers that ignore the verb.
5.  **Parameter Pollution:** Duplicate the identity parameter (`?email=a@b.c&email=a@b.c`) or change casing/encoding (`a@b.c` vs `a%40b.c` vs `A@B.C`) so each attempt hashes to a different limiter bucket while the backend resolves the same account.
6.  **Session/Token Cycling:** For guest- or token-keyed quotas, clear/reissue the session or guest cookie per request; for Bearer tokens, register throwaway identities and pool their tokens.
7.  **Concurrency Burst (Last-Byte Sync):** If the limiter increments asynchronously, fire 20–50 requests where all but the final byte of each body are pre-sent, then release simultaneously (single-packet race) to slip through before the counter updates.
8.  **Time-Window Probing:** Send requests straddling the reset boundary (`X-RateLimit-Reset`) and test whether failed/aborted requests still consume quota (some counters only charge on 2xx).

## Common Weak Implementations
*   Nginx `limit_req_zone key=$http_x_forwarded_for` — full spoof control from the client.
*   Gateway limits by IP while the backend limits by account (or not at all) — whichever is weaker wins for the attacker.
*   Client-side counters or "disabled" buttons with a server accepting unlimited requests.
*   Limiter skipping internal/maintenance paths (`/api/internal/*` exempt) reachable via path normalization.
*   Per-endpoint limits without a global per-principal budget — attacker fans out across equivalent endpoints.

## Escalation Paths
*   **Account Takeover:** Rotate headers/IPs to brute-force 4–6 digit OTPs or password-reset tokens before the quota or token expiry is exhausted.
*   **Financial State Tampering:** Unlimited coupon/benefit redemption, gift-card balance probing, refund request spamming.
*   **Mass Data Extraction:** Scraping or paginating PII/search results beyond the intended quota.
*   **Resource Exhaustion:** Driving paid AI/model inference or SMS/email sending (cost attacks) on the provider's bill.

## Detection Opportunities
*   Alert on request bursts where `X-Forwarded-For` never repeats but other fingerprints (TLS JA3, user-agent, session behavior) stay constant.
*   Correlate 429 responses with high-frequency header-key changes on a single TCP session.
*   Maintain per-principal (account) counters independently of IP so edge-limiter evasion still trips the account-level alarm.

## Notes
*   **False Positives:** Corporate egress proxies and CGNAT legitimately concentrate many users behind one IP — a header-only bypass demo without a brute-forceable or quota-gated impact is usually N/A.
*   **Constraints:** CDN-level limiters (e.g., Cloudflare) often ignore client-supplied IP headers; determine whether the app origin or the edge is enforcing.
*   **Cross-reference:** `payloads/headers/403_bypass_headers.txt` and `payloads/wordlists/auth_bypass_headers.txt` for rotation header sets; `skills/state_management/race_conditions.md` for the concurrency-burst sync primitive.
