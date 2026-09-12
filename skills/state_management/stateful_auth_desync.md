# Stateful Auth Desynchronization & Multi-Session Inconsistency

## Objective & Context
*   **Security Assumption Failure:** The application assumes that state changes (e.g., password reset, profile updates, privilege changes) applied to a user account instantly propagate across all active sessions and **stateful protocol connections**.
*   **Trust Boundary Violation:** The server maintains isolated state per session or per connection rather than a unified state per user account. When a sensitive action occurs in Session A, Session B or Connection C continues to operate using stale data.

## 1. Handshake vs. Session Desync (AOSSA Ch 14/16)
Many modern architectures use a stateless HTTP handshake to establish a stateful protocol (WebSocket, gRPC Stream).

### **The "Persistence of Privilege" Pattern**
*   **Mechanism:** Authentication happens once during the handshake. The resulting stateful connection is trusted for its entire duration.
*   **Failure:** The user's HTTP session is revoked (e.g., password reset), but the **pre-existing WebSocket** remains authenticated and privileged because the server only checked the token at the handshake.
*   **Audit Goal:** Establish a stateful connection (WS/gRPC), trigger a logout/password reset in a separate HTTP session, and then attempt to send data over the stateful connection.

---

## 2. Protocol State Machine Corruption
AOSSA identifies failures in the sequence of protocol states.

### **State Skipping**
*   **Logic:** A protocol follows a sequence: `INIT -> AUTH -> DATA -> CLOSE`.
*   **Failure:** The server assumes that receiving a `DATA` frame implies the `AUTH` state was successful.
*   **Offensive Pivot:** Send a `DATA` message immediately after `INIT`, skipping the `AUTH` handshake. Test for "Implicit State Assumptions" where the code assumes a previous check passed based on the message type received.

### **Inconsistent State Transitions**
*   **Logic:** Two concurrent requests trigger conflicting state changes (AOSSA Ch 13).
*   **Failure:** Triggering a `LOGOUT` and a `SENSITIVE_ACTION` simultaneously. If the `SENSITIVE_ACTION` starts processing while the `LOGOUT` is in progress, it may succeed using a "zombie" session context.
*   **Audit Goal:** Use race conditions to target the "Tear-down" phase of a session.

---

## 3. Multi-Session Inconsistency Recognition
*   **Architecture:** Complex applications using JWTs, distributed session stores (Redis), or hybrid authentication (Web + Mobile App).
*   **Behaviors:** 
    *   The application allows multiple concurrent logins without invalidating older sessions.
    *   Changing profile details in one session does not reflect in a secondary session or an active WebSocket stream.

## Validation Workflow
1.  **Session Setup:** Log into the same account using two different sessions (Session A and Session B).
2.  **State Mutation (Session A):** Change the password or delete the account.
3.  **Desync Verification (Session B):** Switch to Session B. 
    *   If the password was changed, does Session B remain active?
4.  **Protocol Verification (Connection C):** If a WebSocket is active, does it remain functional after the HTTP session is revoked?
5.  **Race Condition Augmentation:** Trigger a state change and immediately fire authenticated actions from a secondary session.

## Escalation Logic
*   **Account Takeover Persistence:** Attackers maintain access via pre-established stateful connections even after a password reset.
*   **Privilege Escalation Retention:** Retaining admin rights on a long-lived gRPC stream after the user's role was downgraded in the DB.

## Engineering Failure Modes
*   **Stateless JWTs:** Relying entirely on claims without checking a revocation list.
*   **Missing Global Logout:** Failing to broadcast "Session Kill" events to stateful protocol handlers.
*   **Implicit State Assumptions:** Trusting a connection's state without re-validating the user context on every message.
