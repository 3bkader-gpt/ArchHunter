# Distributed Authorization Propagation (ReBAC)

## Mechanism Overview (Zanzibar / ReBAC)
Modern global-scale systems use **Relationship-Based Access Control (ReBAC)** to manage permissions across trillions of objects (e.g., Google Drive, Slack). Trust is modeled as a **Graph of Relationships** (User -> Member of Team -> Owner of Doc). Authorization decisions must be consistent across global replicas and handle complex inheritance chains.

## 1. Global Consistency Gaps (The "Zookie" Problem)
Distributed auth systems often trade off absolute consistency for low-latency reads.

### **The "New-Content" Race Window**
*   **Mechanism:** To prevent stale reads, systems use a timestamp or token (e.g., Zanzibar's `Zookie`) to ensure a check is as fresh as the last update.
*   **Failure:** If a system fails to enforce "External Consistency" (reading your own writes), an attacker can perform a write (e.g., "Revoke Access") that is not seen by a subsequent check on a different replica.
*   **Offensive Pivot:** Target "Revocation" actions. Perform a high-privilege action immediately after your access was theoretically removed in a different regional endpoint.

### **Stale ACL Replay**
*   **Mechanism:** Authorization decisions are heavily cached to meet performance requirements.
*   **Failure:** If the "Cache Invalidation" signal is delayed or lost, a user remains authorized for an object they no longer own.
*   **Audit Goal:** Identify "Long-Lived Auth Decisions." Check if removing a user from a group/org instantly terminates their access to resources owned by that group.

---

## 2. Graph-Edge Trust Escalation
In ReBAC, permissions are inherited through nested relationships.

### **Transitive Path Injection**
*   **Logic:** `User A` is `Editor` of `Folder B`. `Folder B` contains `Doc C`. Therefore, `User A` is `Editor` of `Doc C`.
*   **Failure:** The system allows a user to create a "Circular Relationship" or "Indirect Link" that bypasses depth-limits or explicit "Deny" rules.
*   **Offensive Pivot:** Manipulate "Parent-Child" relationships. Can you move a sensitive object into a folder you control? Can you invite a "Service Account" you control into a high-privilege team?

---

## 3. Authorization Context Decay
As an authorization decision moves from the "Auth Service" to the "Data Service."

### **The "Checked-then-Trusted" Gap**
*   **Mechanism:** Service A checks with Zanzibar: "Can User X read Doc Y?". Zanzibar says "Yes." Service A then fetches Doc Y.
*   **Failure:** The "Checked Identity" and the "Fetched Resource" are not atomically bound. An attacker swaps the resource ID *after* the check but *before* the fetch (a distributed TOCTOU).
*   **Audit Goal:** Target multi-step "Check-then-Fetch" workflows. Use race conditions to swap IDs in the request pipeline.

---

## 4. Distributed Auth Audit Checklist
When auditing a global ReBAC or ACL system, verify these primitives:

1.  **Revocation Latency:** How long does it take for a "Remove Member" action to propagate to every global read-replica?
2.  **Inheritance Depth:** Is there a limit to how many levels a permission can traverse? Can you create an infinite loop to cause a DoS?
3.  **Namespace Isolation:** Are "Relationships" scoped to a specific object type? (e.g., Can a "Team Member" relation be used as a "Database Owner" relation?).
4.  **Consistency Token Integrity:** Are tokens like `Zookies` protected against tampering or replay across different users?

## Recognition Patterns
*   **API Calls:** Look for `/check`, `/expand`, or `/read-acl` endpoints.
*   **Headers:** Look for versioned auth tokens or "Consistency Cookies."
*   **Logic:** Systems that use "Teams," "Organizations," or "Workspaces" to aggregate permissions.
