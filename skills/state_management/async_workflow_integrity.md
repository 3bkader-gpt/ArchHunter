# Async Workflow Integrity

## Mechanism Overview
Asynchronous systems (Job Queues, Message Brokers, Background Workers) introduce a **temporal and structural gap** between the point of data entry (Request) and the point of data execution (Sink). Vulnerabilities occur when security assumptions made during the request do not persist in the background.

## 1. Async Trust Drift (AOSSA Primitive)
The gap between "Validation Time" and "Execution Time."

### **The "Stale Context" Pattern**
*   **Logic:** A request is validated (e.g., "User is not banned"), and a job is added to a queue.
*   **Failure:** During the queue delay, the user's status changes (e.g., Account Suspended). The background worker, however, only trusts the "Validated" flag attached to the job and performs the sensitive action anyway.
*   **Audit Goal:** Identify sensitive actions triggered via queues (Email, Payments, Data Export). Trigger the action, immediately change your account state, and see if the action completes.

---

## 2. Validation Latency & Partial State
Asynchronous workflows often process data in stages.

### **In-Queue Transformation Abuse**
*   **Mechanism:** Data is stored in a queue in a "Raw" or "Partially Decoded" state.
*   **Failure:** An upstream service performs basic filtering (e.g., "No `<script>` tags"). The background worker later performs a complex transformation (e.g., Markdown to PDF) that reveals hidden payloads (e.g., CSS injection leading to SSRF) that were not checked at the edge.
*   **Audit Goal:** Target the "Deep Parser" (the background worker). Use payloads that only become dangerous after the worker's specific transformation logic.

---

## 3. Background Worker Trust Disconnect
Workers often operate in a "Trusted Zone" with high privileges.

### **Implicit Authorization Assumption**
*   **Mechanism:** A worker processes a job and assumes the "User Context" has been pre-verified.
*   **Failure:** The worker lacks a local authorization check. If an attacker can inject a job directly into the queue (via SSRF or Queue Poisoning), they can execute any action with the worker's high-privilege credentials.
*   **Audit Goal:** Identify the internal communication channel to the worker. Can you influence the "Job Parameters" to target other users' data?

---

## 4. Idempotency Integrity & Replay Prevention
Idempotency ensures that performing the same operation multiple times has the same result as a single execution. In distributed queues, where "At-Least-Once" delivery is the norm, applications use **Idempotency Keys** (e.g., UUIDs) to safely retry requests. 

### **The "TTL Replay" Pattern (Key Erosion)**
*   **Mechanism:** Idempotency keys are stored in a cache (e.g., Redis) with a Time-to-Live (TTL) of 24 hours.
*   **Failure:** After 24 hours, the key is purged. An attacker intercepts a valid request from a year ago and "replays" it. The server treats it as a brand-new request.
*   **Offensive Pivot:** Target "One-time" actions with financial or security impact (Withdrawals, Account Creation, Invites). Test if old requests can be re-submitted.

### **The "Key Shadowing" Race (Check-then-Act)**
*   **Logic:** `if (!exists(key)) { process(); save(key); }`
*   **Failure:** Two identical requests arrive simultaneously. Both pass the `exists()` check because neither has reached the `save()` step yet.
*   **Audit Goal:** Use HTTP/2 or parallelization tools to hit the endpoint with the same idempotency key at the same millisecond.

### **Payload Mismatch (Key Collision)**
*   **Mechanism:** A system trusts the `idempotency_key` but ignores the request body.
*   **Failure:** An attacker re-uses a legitimate key but changes the payload (e.g., same key, different recipient). The server returns the "Success" response from the *first* recipient but might perform the action for the *second*.

---

## 5. Distributed Logic Failures (DDIA Primitive)

### **At-Least-Once Processing Failures**
*   **Mechanism:** Most queues guarantee "At-Least-Once" delivery. If a worker crashes *after* processing but *before* acknowledging, the message is re-delivered.
*   **Failure:** If the operation is not **Idempotent**, it executes twice. 
*   **Audit Goal:** Identify non-idempotent actions (Increment balance, Deduct stock, Send SMS). Simulate worker failures (timeouts) to trigger retries.

### **Poison Message "Death Spirals"**
*   **Mechanism:** A malformed message causes a worker to crash.
*   **Failure:** The queue sees the crash, assumes a transient error, and re-queues the message. This triggers an **Infinite Retry Loop**, causing a permanent Denial of Service (DoS) of the worker pool.
*   **Offensive Pivot:** Inject malformed data that triggers edge-case exceptions (e.g., division by zero, invalid type casting) in the background worker.

### **Trust Context Divergence**
*   **Mechanism:** Identity is "frozen" into the job payload during the request.
*   **Failure:** As the message moves through multiple queues and intermediate workers, original security claims (JWT scopes, User-Role) are stripped or simplified. The final worker trusts the "Job Metadata" rather than the current system state.
*   **Audit Goal:** Find where "Identity Propagation" breaks. Can we modify job metadata to assume the identity of a different user?

---

## 6. Async Audit Checklist
When mapping an asynchronous workflow, verify these AOSSA & DDIA primitives:

1.  **Idempotency Enforcement:** Does every job have a unique `request_id` or `idempotency_key` that is checked atomically against a persistent store?
2.  **Temporal Validation:** Does the background worker re-verify account status (Banned, Deleted, Suspended) before execution?
3.  **Order Sensitivity:** Does the system fail if "Action B" is processed before "Action A"?
4.  **Error Handling:** Are "Poison Messages" moved to a Dead Letter Queue (DLQ) after X retries, or do they block the entire pipeline?
5.  **Job Parameter Integrity:** Is the job payload signed? Can an attacker modify the `amount`, `recipient`, or `file_path` while the job is in transit?

## Recognition Patterns
*   **Email Systems:** Delayed processing of templates.
*   **Media Converters:** Video/Image transcoding workers.
*   **Webhooks:** Outbound requests triggered by background events.
*   **Data Exports:** CSV/PDF generation from large datasets.
