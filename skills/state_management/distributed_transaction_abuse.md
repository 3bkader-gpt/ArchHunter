# Distributed Transaction & Coordination Abuse

## Mechanism Overview (DDIA Ch 9)
In distributed systems, a single operation (e.g., "Purchase Item") often requires coordinated changes across multiple services. To ensure integrity, systems use **Distributed Transactions** (2PC) or **Asynchronous Workflows** (Sagas, TCC). Vulnerabilities occur when the coordination logic fails, allowing for partial commits, reservation exhaustion, or unauthorized state transitions.

## 1. Two-Phase Commit (2PC) Failures
2PC is a blocking protocol used to achieve atomicity across multiple nodes.

### **The "Uncertainty" Lockup (DoS)**
*   **Mechanism:** A coordinator asks participants to "Prepare." If the coordinator crashes before sending the "Commit" or "Abort" signal, all participants remain in an "Uncertain" state, holding locks indefinitely.
*   **Failure:** An attacker induces a coordinator failure (e.g., via DoS or specialized payloads) during the critical window to paralyze the entire database or service pool.
*   **Audit Goal:** Identify services that use 2PC (common in older enterprise Java/Oracle stacks). Target the coordinator's availability.

---

## 2. Saga & TCC (Try-Confirm-Cancel) Abuse
Sagas are sequences of local transactions connected by messages. TCC is an application-layer pattern for reservations.

### **Reservation Exhaustion**
*   **Logic:** `Step 1: Try` (Reserve resource) -> `Step 2: Confirm` (Execute) or `Step 3: Cancel` (Release).
*   **Failure:** An attacker initiates thousands of "Try" operations (e.g., "Add to Cart", "Hold Seat") but never calls "Confirm" or "Cancel."
*   **Offensive Pivot:** Target limited resources (Inventory, Booking, Promo codes). If the system lacks a short **Reservation TTL**, the attacker can cause a business-level DoS by "holding" all available stock.

### **Unauthorized Confirm/Cancel**
*   **Mechanism:** Confirms and Cancels are often simple API calls to internal or external endpoints.
*   **Failure:** The server fails to verify that the `Confirm` request originated from the legitimate transaction coordinator.
*   **Audit Goal:** Identify the transaction ID format. Attempt to call `/api/v1/transaction/{ID}/confirm` directly without completing the "Try" phase.

---

## 3. Coordination & Consensus Failures
Systems use distributed locks (ZooKeeper, etcd, Redis) to ensure only one node performs a sensitive action.

### **Zombie Write Injection (Fencing Bypass)**
*   **Mechanism:** A process acquires a lock and receives a **Fencing Token** (monotonic ID). The storage layer *should* reject any write with an older token.
*   **Failure:** The storage layer (S3, Database, File System) does not enforce the fencing token. A "stale" leader (recovering from a GC pause) overwrites new data.
*   **Audit Goal:** Measure if the application-layer locking is actually enforced at the data-layer. Target "Leader-only" actions like log rotation or periodic cleanup.

### **Split-Brain Authorization**
*   **Mechanism:** A network partition causes two nodes to both believe they are the "Leader" (Split-Brain).
*   **Offensive Pivot:** If the nodes are in different regions, use them to perform conflicting actions (e.g., "Delete User" on Node A and "Transfer Funds" on Node B) during the partition window.

---

## 4. Transaction Audit Checklist
When mapping a cross-service workflow, verify these DDIA primitives:

1.  **Atomicity Guarantee:** If a sub-step fails, does the *entire* workflow roll back, or does it leave "Zombie Records" in downstream services?
2.  **Compensation Logic:** Is the "Cancel" action idempotent? If the "Cancel" message is lost, does the resource remain locked forever?
3.  **Visibility:** Is the "Pending" state visible to other users? (e.g., Can User B see User A's unconfirmed data?).
4.  **Token Monotonicity:** Does the system use fencing tokens to prevent stale leaders from corrupting state?

## Recognition Patterns
*   **Payment Gateways:** Target the Try/Confirm split.
*   **Microservice Orchestrators:** Temporal, Camunda, or custom Step Functions.
*   **Distributed Locks:** Applications using Redis `SETNX`, ZooKeeper, or etcd for concurrency control.
