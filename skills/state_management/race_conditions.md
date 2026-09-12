# Race Conditions & Async Logic

## Mechanism Overview
Race conditions occur when the security of a system depends on the **timing or order** of events. In asynchronous web environments, attackers use concurrent requests to exploit the gap between "Checking" a condition and "Performing" an action (TOCTOU).

## 1. High-Signal Race Patterns

### Limit/Quota Exhaustion (The "Free Lunch" Pattern)
*   **Mechanism:** An application checks a balance or quota, then performs an action.
*   **Failure:** Two requests arrive simultaneously. Both pass the "Check" because the "Action" has not yet updated the database.
*   **Offensive Pivot:** Identify endpoints that decrement a counter (Payments, API Quotas, OTP attempts, Vote counts).
*   **Audit Goal:** Use `Turbo Intruder` or `racepwn` to fire 50+ identical requests in a tight time window.

### Single-Use Token Reuse
*   **Mechanism:** A token is valid until it is used (e.g., Password Reset, Invitation, Voucher).
*   **Failure:** Concurrent requests use the same token before the server marks it as "Used."
*   **Audit Goal:** Trigger a password reset and attempt to use the token multiple times simultaneously.

---

## 2. Advanced Async Logic (AOSSA Logic)

### Partial State Corruption
*   **Mechanism:** A multi-step process updates multiple database tables.
*   **Failure:** If an error occurs midway, or if a second request starts before the first finishes, the tables may fall out of sync (e.g., Balance deducted but order not created).
*   **Audit Goal:** Target the "Tear-down" or "Cleanup" phase of a transaction.

### Handshake vs. Message Desync
*   **Mechanism:** State is initialized during a handshake (WebSocket) but not re-validated on subsequent frames.
*   **Offensive Pivot:** See [Stateful Auth & Protocol Desync](stateful_auth_desync.md).

---

## 3. Escalation Logic
*   **Race Condition** -> **Price Manipulation** -> **Theft of Service**.
*   **Race Condition** -> **2FA Bypass** -> **Account Takeover**.
*   **Race Condition** -> **Voucher/Credit Reuse** -> **Financial Loss**.

## 4. Operational Checklist
*   Does the app involve any "Decrementing" logic (Balances, Stocks)?
*   Are there "One-time" actions (Resets, Invitations)?
*   Does the backend use an asynchronous queue?
*   Can you fire requests fast enough to hit the same millisecond? (Use HTTP/2 for better timing control).
