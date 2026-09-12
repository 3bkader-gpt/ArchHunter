# Protocol State Machine Integrity

## Mechanism Overview (AOSSA Ch 13/14)
A state machine manages the lifecycle of a connection or process. Security depends on ensuring the system is always in a **known-good state** and that all transitions are **validated and authorized**.

## 1. Unexpected Transitions (State Confusion)
Attackers attempt to force the system into a state for which it is not prepared.

### **Linear Assumption Bypass**
*   **Logic:** Code assumes a strict sequence (e.g., `Step 1 (INIT) -> Step 2 (AUTH) -> Step 3 (DATA)`).
*   **Failure:** The handler for `Step 3` does not explicitly check if `Step 2` completed. An attacker sends a `DATA` message immediately after `INIT`.
*   **Offensive Pivot:** Identify every message type in a protocol and send them "Out of Order". Target messages that perform sensitive actions.

### **Error-State Short-Circuiting**
*   **Mechanism:** An error occurs, and the system transitions to a "Recovery" state.
*   **Failure:** The Recovery state returns the user to an "Authenticated" context without re-verifying credentials.
*   **Audit Goal:** Intentionally trigger errors (timeouts, malformed packets) during sensitive transitions to see where the system lands.

---

## 2. Implicit vs. Explicit State Inconsistency
The gap between the "Formal State" (a variable) and the "Actual State" (pointers, buffers, session data).

### **Zombie Session Residue**
*   **Mechanism:** A connection is closed or an error occurs, resetting the state variable to `IDLE`.
*   **Failure:** The internal session structure or data buffer is **not cleared**. A new connection on the same thread/process "inherits" the previous session's context.
*   **Audit Goal:** Perform a sensitive action, crash the connection, and immediately start a new connection to see if any data persists.

---

## 3. Protocol Desynchronization (Interpretation Gaps)
Occurs when two systems (e.g., Load Balancer and App Server) have different views of the protocol state.

### **In-Band Signal Smuggling**
*   **Mechanism:** Smuggling a "State Change" signal (like `Connection: Close` or `End-of-Message`) inside a data field.
*   **Failure:** The proxy treats it as data, but the backend treats it as a signal to terminate the current request and start a new one (HTTP Request Smuggling).
*   **Audit Goal:** Test how delimiters and control characters are handled when they appear inside values vs. as headers.

---

## 4. State Machine Audit Checklist
When mapping a protocol stack, verify these AOSSA primitives:

1.  **Completeness:** Is there a defined behavior for *every* message type in *every* state? (Unexpected inputs often trigger default "safe" paths that are actually insecure).
2.  **Invariants:** What must be true for State X to be active? (e.g., "Encryption must be enabled"). Is that invariant checked on *every* entry to State X?
3.  **Atomicity of Transition:** Does the state change happen *before* or *after* the sensitive action? (If after, a crash during the action leaves the system in the previous state).
4.  **Resource Cleanup:** Does every transition to an "End" or "Error" state explicitly free all allocated buffers and nullify pointers?

## Recognition Patterns
*   **TLS/SSL:** Target handshakes (ServerHello before ClientHello).
*   **SMTP/FTP:** Target command sequences (DATA before RCPT).
*   **Custom Binary Protocols:** Target "Session Resumption" logic where state is re-loaded from a cache.
