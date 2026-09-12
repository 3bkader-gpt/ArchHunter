# 🛠️ Practical Burp Suite Hunting Guide (The Real-World Bounty Blueprint)

> **Core Law:** 80% of real-world Bug Bounties are found by testing **Business Logic, Broken Access Control (BOLA/IDOR), and Race Conditions** using two accounts in Burp Suite. This guide provides the exact hands-on steps to find them.

---

## 1. The Two-Account Setup (The #1 Money-Making Technique)

### Step 1: Create Your Identity Matrix
Open two distinct browser sessions (e.g. Chrome Profile 1 + Firefox / Incognito):
- **User A (Attacker):** `attacker@wearehackerone.com` (Org A / Role: Member)
- **User B (Victim):** `victim@wearehackerone.com` (Org B / Role: Member)
- **Admin (Optional):** `admin@wearehackerone.com` (Org A / Role: Admin)

### Step 2: Configure Burp Suite
Choose one of these methods:
1. **Burp Extension (Autorize / AutoRepeater):**
   - Install `Autorize` from BApp Store.
   - Paste `User B`'s authorization header (`Cookie` or `Bearer <Token>`) into Autorize.
   - Browse the application as `User A`.
   - Autorize automatically replays every request with User B's token and highlights `Bypassed!` in red.
2. **Burp Match and Replace:**
   - Go to `Proxy -> Options -> Match and Replace`.
   - Add rule: Replace `Authorization: Bearer <User_A_Token>` with `Authorization: Bearer <User_B_Token>`.
3. **Manual Multi-Tab Repeater:**
   - Send interesting requests to Repeater.
   - Group tabs: `User A (Source)` and `User B (Target)`.

### Step 3: Enable Passive Intelligence Extensions (JS Miner)
- Install **`JS Miner`** from the BApp Store.
- During navigation, `JS Miner` runs in the background analyzing all loaded `.js` files to automatically extract:
  - Hidden Subdomains and Cloud Buckets (AWS S3, GCP, Azure).
  - API Endpoints, GraphQL queries, and routing paths.
  - Hardcoded API Keys, JWT tokens, and OAuth Client IDs.
- Access extracted subdomains via `Target -> Site Map -> Right Click -> JS Miner -> Run/View Results`.

---

## 2. The CRUD Access Control Checklist (Test Every Feature)

When auditing any feature (e.g. Invoices, Projects, Comments, API Keys, Team Members), test all 4 operations:

| Operation | Action | What to Test in Burp | Vulnerability |
|---|---|---|---|
| **CREATE** | User A creates object | Can User A specify `org_id: <Org_B>` in POST body? | Cross-Tenant Object Creation |
| **READ** | User A fetches object | Replace `/api/v1/projects/<ID_A>` with `<ID_B>` | Horizontal IDOR (BOLA) |
| **UPDATE** | User A edits object | Send `PUT/PATCH` with User A's token to `<ID_B>` | Unauthorized Mutation |
| **DELETE** | User A deletes object | Send `DELETE` with User A's token to `<ID_B>` | Unauthorized Deletion |

---

## 3. High-Signal Parameter & Type Tampering

When examining JSON request bodies or query parameters, try these high-yield mutations:

### A. Role & Privilege Injection (Mass Assignment)
Inject hidden fields into profile/account updates (`PUT /api/v1/users/me`):
```json
{
  "name": "Hacker",
  "role": "admin",
  "is_admin": true,
  "role_id": 1,
  "plan": "enterprise",
  "verified": true,
  "account_type": "superuser"
}
```

### B. Type Juggling & Array Poisoning
Convert single values to arrays or alternative types to bypass backend filters:
```json
// Original:
{"user_id": 1052}

// Bypass attempts:
{"user_id": [1052, 1053]}
{"user_id": "1052"}
{"user_id": {"$gt": ""}}
{"user_id": true}
```

### C. Numeric Edge Cases (Negative Numbers & Decimals)
On financial, cart, or quota endpoints:
```json
{"quantity": -1}
{"quantity": 0.00001}
{"amount": -50}
{"discount_percentage": 150}
```

---

## 4. Race Conditions & Concurrency (Turbo Intruder Scripts)

When an action involves:
- Redeeming a coupon / gift card / promo code
- Transferring balance / credits
- Accepting a single-use invitation link
- Upvoting / liking / rating once per user

### Single-Packet Attack (Turbo Intruder Python Script)
Install **Turbo Intruder** from BApp Store, send the target request to Turbo Intruder, and use this script:

```python
def queueRequests(target, wordlists):
    engine = RequestEngine(endpoint=target.endpoint,
                           concurrentConnections=30,
                           requestsPerConnection=100,
                           pipeline=False)

    # 1. Warm up the connection
    for i in range(5):
        engine.queue(target.req, target.baseInput, learn=1)

    # 2. Prepare 30 identical requests in a single TCP packet
    for i in range(30):
        engine.queue(target.req, target.baseInput, gate='race1')

    # 3. Release all requests simultaneously
    engine.openGate('race1')

def handleResponse(req, interesting):
    # Log all successful responses
    if req.status == 200 or req.status == 201:
        table.add(req)
```

---

## 5. Password Reset & Account Takeover (ATO) Checklist

1. **Pre-Account Takeover (Pre-ATO) Test:**
   - Register victim's email (`target_user@company.com`) with a custom password.
   - Without clicking verification email, attempt "Sign in with Google/OAuth" for the same email.
   - Verify if OAuth automatically links to the existing password account without demanding current password confirmation.
2. **Email Verification Bypass:**
   - Intercept the post-registration response (`POST /api/register` or `GET /api/user/status`).
   - Change `{"is_verified": false}` $\rightarrow$ `{"is_verified": true}`.
   - Directly navigate to `/dashboard` or trigger authenticated actions (`POST /api/v1/orders`) to test if backend enforces verification.
3. **Host Header Poisoning in Reset Email:**
   - In `POST /api/forgot-password`, change `Host: target.com` to `Host: attacker-controlled.com` or `Host: target.com.attacker.com`.
   - Check if the password reset link in the email uses the poisoned host.
4. **Token Leakage in Referer:**
   - Click the reset link in your email. Inspect if any 3rd party assets (Google Analytics, Sentry, CDNs) receive the token in the `Referer` header.
5. **Response Manipulation on OTP:**
   - Intercept the OTP validation response (`POST /api/verify-otp`).
   - Change response from `{"status": "error", "valid": false}` to `{"status": "success", "valid": true}` or HTTP status from `400` to `200`.
6. **Rate Limit Evasion on OTP:**
   - Rotate headers: `X-Forwarded-For: 127.0.0.1`, `X-Real-IP: 10.0.0.1`, `CF-Connecting-IP: 1.1.1.1`.
   - Add null bytes or path variations: `POST /api/verify-otp/` or `POST /api/v1/../verify-otp`.

---

## 6. Financial & E-Commerce Business Logic Checklist

When testing billing, cart, and payment flows:
1. **Currency Swapping without FX Conversion:**
   - Create checkout session in USD ($100).
   - In Burp Repeater, modify payload to `"currency": "INR"` or `"currency": "EGP"`.
   - Check if Stripe/Gateway bills ₹100 or 100 EGP (~$2 USD) instead of $100.
2. **Negative Quantity & Offsetting Items:**
   - Add Item A ($100, qty: 1) and Item B ($10, qty: -9).
   - Verify if total calculates to $10.00 ($100 - $90).
3. **Cart Holding / Inventory Lock (Business DoS):**
   - Reserve maximum available stock in cart via automated script.
   - Check if product goes out of stock for other users without paying, and if hold persists without expiration TTL.
4. **Multi-Step State Desync:**
   - Complete payment authorization step for a $1.00 item $\rightarrow$ Capture authorization token.
   - Replay final fulfillment request (`POST /api/order/complete`) substituting `item_id` for high-value $500 product.

---

## 7. Advanced File Upload & Web Shell Checklist

When testing image, avatar, or document upload endpoints:
1. **MIME-Type Manipulation:**
   - Intercept upload request, upload `shell.php`, but change header to `Content-Type: image/jpeg` or `image/png`.
2. **Double & Special Extensions:**
   - Fuzz extensions: `.php.jpg`, `.jpg.php`, `.phtml`, `.php5`, `.phar`, `.inc`, `.php%00.jpg`, `shell.php.`.
3. **Server Configuration Overwrite:**
   - Upload `.htaccess` with content: `AddType application/x-httpd-php .jpg`. Then upload `payload.jpg` containing PHP code.
4. **Path Traversal in Upload Directory:**
   - Change `filename="avatar.png"` $\rightarrow$ `filename="../../../../var/www/html/shell.php"`.
5. **Polyglot Magic Bytes:**
   - Prepend `GIF89a;` to the start of the payload body.

---

## 8. Rate Limiting & Brute-Force Bypass Checklist

1. **Client IP Header Rotation in Intruder (Pitchfork):**
   - Inject header: `X-Forwarded-For: 192.168.1.§payload§`, `X-Real-IP: 10.0.0.§payload§`.
2. **URI Path Normalization Bypass:**
   - Append `/`, `.json`, `?param=1`, or `/./` to the login/OTP path (`/api/v1/login/`).
3. **Method & Header Overrides:**
   - Change `POST` to `GET` or add `X-HTTP-Method-Override: POST`.
4. **Single-Packet Parallel Burst (Turbo Intruder):**
   - Burst 30 requests concurrently to race the Redis rate-limiter counter.

---

## 9. The Response Manipulation & Verification Discipline (Anti-Self-Deception)

> [!CAUTION]
> **Golden Rule of Triage:**
> *Response edits are cosmetic; request edits are real.*
> Modifying a response from `{"is_admin": false}` to `true` or HTTP `403` to `200` only fools your local browser DOM. Triagers will instantly reject your report as **Not Applicable (NA)** unless the state change persists on the backend!

### How to Prove a Real Logic Bypass (3-Step Verification Protocol):
1. **Never Report Purely from Intercepted Responses:**
   - Intercepting and flipping a response is only a diagnostic tool to see what UI components unlock.
2. **Execute Server-Side Action with Interception OFF:**
   - Click the unlocked administrative action (e.g. `POST /api/v1/admin/users/delete`).
   - If the backend returns `403 Forbidden` $\rightarrow$ The vulnerability does **NOT** exist (Client-only gate).
   - If the backend executes the deletion (`200 OK` / `204 No Content`) $\rightarrow$ Valid Critical Logic Flaw!
3. **Verify from an Independent Clean Session:**
   - Open a separate private incognito window or query the database/API with User B to assert that the state change persisted server-side.

---

## 10. Webhooks & NGINX Server-Edge Misconfigs Checklist

1. **Unverified Inbound Webhooks:**
   - Find endpoints like `/api/webhooks/stripe`, `/api/webhooks/github`.
   - Send raw JSON without `Stripe-Signature` or `X-Hub-Signature-256`. Check if status updates trigger automatically.
2. **Outbound Webhook SSRF:**
   - Configure webhook URL in tenant settings pointing to `http://169.254.169.254/latest/meta-data/` or `http://127.0.0.1:8080`.
   - Click "Test Webhook" and monitor response time and error messages.
3. **NGINX Off-By-Slash Alias Traversal:**
   - Test static asset paths: `GET /static../config/database.yml`, `GET /images../.env`.
4. **CRLF on NGINX Redirects:**
   - Test `GET /%0d%0aSet-Cookie:%20pwned=1` on non-canonical paths to trigger HTTP Response Splitting.

---

## 11. Daily Hunting Workflow (2-Hour Focused Session)

1. **Min 0 - 15:** Pick 1 target feature (e.g. Team Invitations, Checkout, or OAuth Login).
2. **Min 15 - 30:** Map all HTTP requests generated by this feature in Burp.
3. **Min 30 - 60:** Run the 2-account CRUD Access Control Checklist (User A vs User B) + Pre-ATO test + 40 ID-Tamper Mutations.
4. **Min 60 - 90:** Test parameter tampering (Mass assignment, negative values, currency swap, array poisoning, file upload bypasses).
5. **Min 90 - 120:** Test race condition with Turbo Intruder if the action is state-changing, coupon-based, or single-use.



