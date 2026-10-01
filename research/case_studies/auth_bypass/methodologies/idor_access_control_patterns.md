# IDOR & Broken Access Control: Practical Exploitation Patterns

A comprehensive guide to uncovering Insecure Direct Object References (IDOR), Horizontal & Vertical Privilege Escalation, and Access Control bypasses.

---

## 1. Anatomy of an IDOR Vulnerability

An IDOR occurs when an application exposes a reference to an internal implementation object (such as a database key, file path, or tenant ID) in an endpoint or parameter without performing server-side authorization checks against the currently authenticated session.

### Core Attack Surfaces:
- URL parameters: `/api/v1/users/1337/invoices`
- Query parameters: `/api/documents?doc_id=9872`
- Request body (JSON / Form Data): `{"account_id": 5421, "action": "export"}`
- HTTP Headers: `X-User-Id: 104`, `Tenant-ID: 88`
- File download/view paths: `/download?file=statement_2026_09_user_44.pdf`

---

## 2. Parameter Variation & Identifier Bypasses

Developers often attempt ad-hoc fixes that can be bypassed using parser variations:

### A. Numeric ID Variations:
- **Array Parameter Wrap:**
  - Original: `{"user_id": 1337}`
  - Bypass: `{"user_id": [1337, 1338]}` or `{"user_id": {"id": 1338}}`
- **String Conversion:**
  - Original: `GET /api/contract/105`
  - Bypass: `GET /api/contract/105.json` or `GET /api/contract/105/` or `GET /api/contract/105.xml`

### B. UUID / GUID Obfuscation Bypasses:
When targets use UUIDs (e.g., `4f9b2d3e-8c7a-4a5e-9f1d-2b3c4d5e6f7a`), don't assume authorization is enforced:
1. **Discovering Victim UUIDs:**
   - Public user profile pages, forum threads, or comments.
   - Autocomplete / Search endpoints (`/api/users/search?q=victim`).
   - Billing history, invoice headers, or shared collaboration boards.
2. **Replacing UUID with Numeric Equivalents:**
   - Some legacy backends support both UUID and internal integer IDs:
     `GET /api/orders/1234` instead of `GET /api/orders/{uuid}`.
3. **Wildcard & Regex Substitution:**
   - `GET /api/users/*` or `GET /api/users/%25` or `GET /api/users/null`.

---

## 3. HTTP Method Tampering for Access Control Bypass

Web application firewalls (WAFs) and routing frameworks often enforce access rules based strictly on specific HTTP methods:

| Blocked Request | Bypass Attempt | Rationale |
| :--- | :--- | :--- |
| `DELETE /api/users/12` (403 Forbidden) | `POST /api/users/12` with `_method=DELETE` | Framework method override (`_method`, `X-HTTP-Method-Override`) |
| `GET /api/admin/orders` (401 Unauthorized) | `HEAD /api/admin/orders` or `OPTIONS` | Inspecting headers/metadata |
| `PUT /api/profile` (403 Forbidden) | `PATCH /api/profile` or `POST /api/profile` | Inconsistent controller route handling |

---

## 4. Mass Assignment & Privilege Escalation

When updating user profiles or entity states, backend ORMs (e.g., Rails, Django, Hibernate, Spring) may map all incoming JSON keys directly to database columns:

### Attack Pattern:
Normal update request:
```http
PUT /api/user/settings HTTP/1.1
Content-Type: application/json

{
  "name": "Jane Doe",
  "phone": "+1234567890"
}
```

Injected administrative/privilege attributes:
```http
PUT /api/user/settings HTTP/1.1
Content-Type: application/json

{
  "name": "Jane Doe",
  "phone": "+1234567890",
  "role": "admin",
  "is_admin": true,
  "account_tier": "enterprise",
  "email_verified": true,
  "credits": 999999
}
```

---

## 5. Multi-Tenant & Session Misbinding (Second-Order IDOR)

1. **Session Misbinding in Registration / Onboarding:**
   - User initiates an account deletion or organization migration.
   - The confirmation token is generated, but the server validates the confirmation token without checking if the operating session matches the organization owner (Reference: HackerOne Report #3154983).
2. **Cross-Tenant IDOR in API Gateways:**
   - Specifying Organization A's auth token while querying Organization B's project ID:
     `GET /v1/organizations/{org_B}/projects/{project_id}`
   - The gateway validates that the token is *valid*, but fails to verify that the token *belongs to* `org_B`.
