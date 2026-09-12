# Distributed Consistency Failures

## Mechanism Overview (DDIA Ch 5, 9)
In distributed architectures, multiple nodes (replicas) store the same data. Maintaining a single "Source of Truth" is physically difficult. Vulnerabilities occur when the system makes **Consistency Assumptions** (e.g., "All nodes see the same state") that are violated by replication lag or network partitions.

## 1. Eventual Consistency & Stale Authorization
Weak consistency models (Eventual, Read-your-writes) allow replicas to temporarily diverge.

### **The "Stale Decision" Pattern**
*   **Logic:** A security-critical update (Revoke API Key, Ban User, Change Permissions) is written to a **Leader** node.
*   **Failure:** Replication to **Followers** takes time (seconds or minutes). During this "Inconsistency Window," an attacker directs requests to a Follower node that still sees the old, permissive state.
*   **Offensive Pivot:** Identify global SaaS platforms with multiple regions. Perform a logout/password reset in Region A and immediately attempt an authenticated action in Region B.

### **Rate Limit Multiplication**
*   **Mechanism:** Rate limits are stored in an eventually consistent cache or database.
*   **Failure:** Increments from one node are not instantly visible to others. An attacker distributes a brute-force attack across multiple regions/nodes, effectively multiplying their quota by the number of replicas.
*   **Audit Goal:** Measure if rate limits are global and synchronous. Parallelize requests across different CDN edge locations.

---

## 2. Linearizability & Uniqueness Races
Linearizability (Strong Consistency) ensures that once a value is written, all subsequent reads see that value.

### **The "Phantom Uniqueness" Problem**
*   **Mechanism:** A system checks for uniqueness (e.g., "Is this username taken?") before creating a record.
*   **Failure:** Without a linearizable consensus (e.g., Paxos/Raft), two concurrent requests on different leaders can both pass the "Uniqueness Check" and create duplicate records for a "unique" resource (Vouchers, Usernames, Wallet IDs).
*   **Audit Goal:** Rapidly fire two identical "Create Account" or "Claim Voucher" requests to different endpoints/regions.

---

## 3. Causal Consistency & Sequence Abuse
Causal consistency ensures that events are seen in the order they occurred.

### **Order of Revocation Bypass**
*   **Logic:** A user is "Revoked" and then their "Data is Deleted."
*   **Failure:** A replica receives the "Data Deletion" *before* the "Revocation." If the user hits that replica, they may be able to see or intercept the deletion process while still having active permissions.
*   **Offensive Pivot:** Target systems with complex, multi-step teardown workflows.

---

## 4. Temporal State Drift & Clock Logic (DDIA Ch 8)
Distributed systems cannot rely on a synchronized sense of "Now." Different nodes have different clocks (skew) and receive updates at different times (latency). Vulnerabilities occur when security logic depends on **Time-of-Write** or **Ordering** assumptions that can be manipulated or bypassed.

### **Clock Skew & Last-Write-Wins (LWW)**
*   **Logic:** Two nodes write conflicting data. The database keeps the one with the later timestamp.
*   **Failure:** If the system trusts client-provided timestamps, an attacker can provide a "Future" timestamp. Their write (e.g., "Permissions: ALL") will always win the conflict resolution, even if a legitimate "Revoke" action happens later.
*   **Offensive Pivot:** Identify headers or JSON fields containing timestamps. Inject values years in the future to ensure persistence.

### **Temporal Trust Decoupling (Long-Lived Persistence)**
*   **Mechanism:** A WebSocket or gRPC stream is established after a single JWT check.
*   **Failure:** The server assumes the user remains "Authorized" for the entire life of the connection. If the user's password is changed globally, the stateful connection remains active because the check was a "Point-in-Time" event.
*   **Audit Goal:** Establish a long-lived connection, trigger a global logout in a separate tab, and see if the connection is forcibly terminated.

### **Distributed Replay & Invalidation Gaps**
*   **Mechanism:** A single-use token (Password Reset, 2FA) is used against Node A. Node A invalidates it.
*   **Failure:** Before Node A propagates the invalidation to Node B, the attacker re-uses the *same* token against Node B.
*   **Audit Goal:** Capture a single-use token and fire it simultaneously against multiple regional endpoints (e.g., `us-east-1` and `eu-west-1`).

---

## 5. Consistency & Temporal Audit Checklist
When auditing a distributed data layer or stateful logic, verify these DDIA primitives:

1.  **Source of Truth:** Does the application read security-critical data from a **Leader** or a **Follower**? (Follower reads = Stale Auth risk).
2.  **Inconsistency Window:** How long does it take for a state change to propagate globally?
3.  **Conflict Resolution:** If two nodes disagree on a security state, which one wins? (Does it default to `ALLOW`?).
4.  **Partition Behavior:** If the network splits, does the system "Fail-Open" or "Fail-Closed"?
5.  **Timestamp Origin:** Is the timestamp generated by the **Client** (Untrusted) or the **Server** (Trusted)?

## Recognition Patterns
*   **Multi-Region SaaS:** Target the sync delay between US and EU regions.
*   **Distributed Caches (Redis/Memcached):** Check if cache invalidation is synchronous or async.
*   **Leaderless Datastores (Cassandra/DynamoDB):** Target "Quorum" failures where an attacker can influence `W + R <= N`.
*   **WebSockets/gRPC:** Target the lack of periodic re-authorization on open channels.
