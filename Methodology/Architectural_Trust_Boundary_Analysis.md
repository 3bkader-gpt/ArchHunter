# Architectural Trust Boundary & DFD Analysis

## Operational Philosophy
The goal of decomposition is not to draw pretty diagrams, but to ruthlessly identify where data changes hands, privileges change, and parsers execute. Trust boundaries cluster threats. Where trust breaks down, exploitation begins.

## DFD Analytical Heuristics (Attacker Perspective)

### 1. "Data Cannot Move Itself"
**Concept:** In system diagrams, you often see an `External Entity` communicating directly with a `Data Store`. This is a physical impossibility.
**Offensive Implication:** There is *always* a hidden `Process` responsible for moving, parsing, or routing that data.
*   **Target the Parser:** The hidden process is where SSRF, Deserialization, or Injection occurs. Map the middleware, the queue workers, the cron jobs.

### 2. "Process Without Input = Miracle"
**Concept:** A process that generates output without visible input is incomplete.
**Offensive Implication:** The process is consuming implicit inputs (environment variables, metadata, timing, uncontrolled external files).
*   **Target the Implicit:** Identify the hidden input vectors. Can you poison environment variables? Is it reading from a predictable, controllable file path?

### 3. "Process Without Output = Black Hole"
**Concept:** A process that takes input but produces no visible output.
**Offensive Implication:** The output is routed somewhere undocumented (logs, secondary systems, third-party analytics) or the process is vulnerable to out-of-band (OOB) techniques.
*   **Target the Out-of-Band:** Use blind payloads (OAST, DNS/HTTP callbacks). If the input is logged, target the log aggregation platform (Log4Shell, XSS in Kibana).

### 4. "Leaky Abstractions" (AOSSA Primitive)
**Concept:** A security assumption made in one module is violated when integrated into a larger system.
**Offensive Implication:** Look for where one component's "security boundary" depends on another's "implementation detail."
*   **Example:** A frontend assumes the backend validates `user_id`, while the backend assumes the frontend only allows authenticated users to see their own `user_id`.

## Trust Boundary Typology

A trust boundary is any surface where an assumption is made about the data. Look for:

1.  **Execution Boundaries:** Crossing from low-privilege container to host kernel.
2.  **Parsing Boundaries:** Crossing from raw bytes/serialized formats to structured objects (The "First Mile" of attack).
3.  **Network Boundaries:** Crossing from public internet to VPC (SSRF).
4.  **Identity Boundaries:** Crossing between Tenant A and Tenant B (IDOR).
5.  **Logic Boundaries (AOSSA Primitive):** Crossing between two business domains. Assumptions about state in Domain A may not hold in Domain B.
6.  **Temporal Trust Boundaries (DDIA Primitive):** Crossing between the "Time of Validation" and "Time of Execution." In distributed systems, trust decays as state drifts over time.
7.  **Identity Delegation Boundaries (Cloud Primitive):** Crossing from one identity context to another via `AssumeRole`, `PassRole`, or Service Account impersonation. Trust is inherited or delegated through explicit policies.

## Advanced Reasoning Primitives (AOSSA & DDIA & Cloud)

### Transitive Trust Analysis
Identify chains of trust. If **Service A** trusts **Service B**, and **Service B** trusts **User C**, then **Service A** implicitly trusts **User C** for whatever data passes through B.
*   **The Chain Link:** Exploitation occurs at the weakest link. Target B to influence A.
*   **Cloud Application:** Role Chaining. If Role A can assume Role B, and Role B can assume Role C, Role A implicitly has the permissions of Role C.

### Identity Context Decay (Cloud Primitive)
As an identity moves through a system (e.g., OIDC Token -> IAM Session -> Database User), the original security context (multi-factor auth, source IP, original request intent) is often stripped or lost.
*   **Failure Mode:** The internal system trusts the "Mapped Identity" without knowing the strength or intent of the original authentication.
*   **Audit Goal:** Find where "Contextual Metadata" is lost. Can we use a "Weak" login (No MFA) to perform a "Strong" action (Admin) because the internal check only sees the resulting IAM Role?

### Async Trust Drift (AOSSA Primitive)
In asynchronous systems (Queues, Background Workers), there is a **temporal gap** between validation and execution.
*   **Failure Mode:** Validation happens in the request-response thread (Main App), but the execution happens minutes later in a background worker (Worker Service). If the system's state changes (e.g., User is banned) during that gap, the worker may still perform the action.
*   **Audit Goal:** Identify "Long-Lived Invariants" that are assumed to be static but are actually dynamic.

### Consistency-Based Race Conditions (DDIA Primitive)
In systems with **Eventual Consistency**, different replicas can hold conflicting data simultaneously.
*   **Failure Mode:** A security update (e.g., "Permissions Revoked") is written to a Leader node but has not yet reached a Follower node. An attacker uses the Follower node to perform actions using the stale, permissive state.
*   **Audit Goal:** Measure the "Inconsistency Window." Rapidly fire requests across different endpoints or regions to catch the state desync.

### Async State Durability (DDIA Primitive)
In distributed workflows, a single logical transaction is often split across multiple services and queues.
*   **Failure Mode:** A process fails midway (e.g., balance deducted but item not shipped). If the system lacks **Atomic Commitment** or robust **Compensating Transactions**, it remains in an inconsistent, exploitable state.
*   **Audit Goal:** Target the "Partial Failure" state. Induce errors (timeouts, malformed data) at specific steps of a workflow.

### Message Ordering Assumptions (DDIA Primitive)
Distributed queues often do not guarantee the exact order of message delivery.
*   **Failure Mode:** An application assumes that "Message A" (Create User) will always be processed before "Message B" (Assign Role). If B arrives first, the handler might crash or default to an insecure state.
*   **Audit Goal:** Inject messages out-of-order. Send "Delete" before "Update" or "Revoke" before "Grant."

### Consensus Trust Assumptions (DDIA Primitive)
Distributed systems often rely on a single "Leader" or "Coordinator" to enforce security invariants (e.g., uniqueness, sequential ID generation).
*   **Failure Mode:** Due to network partitions or process pauses, the system enters a **Split-Brain** state where two nodes believe they are the leader. Both may issue conflicting, unauthorized commands to the data store.
*   **Audit Goal:** Target the "Leader Election" or "Locking" mechanism. Induce network latency to trigger a re-election and see if the old leader's commands are still accepted.

### Coordination Integrity (DDIA Primitive)
Distributed locks are often "Advisory" (ignored by the storage layer) rather than "Mandatory" (enforced by the storage layer).
*   **Failure Mode:** A process acquires a lock, but its execution is delayed (e.g., GC pause). The lock expires and is granted to another process. The first process resumes and performs a write, bypassing the lock.
*   **Audit Goal:** Check if the storage layer uses **Fencing Tokens** (monotonically increasing IDs) to reject writes from stale lock holders. If not, the system is vulnerable to **Zombie Write Injection**.

### Constraint Propagation Failure
A "Constraint" is a rule about data (e.g., "This integer is always < 100").
*   **Failure Mode:** Validation happens at the edge, but the constraint is not *propagated* to the internal process. The internal process assumes the data is safe and uses unsafe functions (e.g., `memcpy`, `system()`).
*   **Audit Goal:** Find where the "Validation state" is lost. Look for data re-serialization or state-machine transitions where constraints are dropped.

## Attack Surface Interpretation
When mapping a target, apply the STRIDE-per-interaction model:

*   **External Entities (Users, APIs):** Vulnerable to *Spoofing* and *Repudiation*.
*   **Processes (Web servers, Workers):** Vulnerable to *All STRIDE*.
*   **Data Flows (Network traffic, IPC):** Vulnerable to *Tampering*, *Info Disclosure*, and *DoS*.
*   **Data Stores (Databases, S3, Caches):** Vulnerable to *Tampering*, *Info Disclosure*, *Repudiation*, and *DoS*.

*Operational Rule:* Do not attack the component; attack the *interaction* across the boundary.
