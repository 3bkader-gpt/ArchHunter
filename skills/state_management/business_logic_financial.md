# Mechanism: Financial Business Logic, Currency & Inventory Integrity

## 1. Architectural Vulnerability Profile
*   **Vulnerability Class:** Business Logic Error / Financial Flaw / State Machine Inversion
*   **STRIDE Category:** Tampering, Denial of Service, Elevation of Privilege
*   **Trust Boundary Crossed:** Frontend Client / Mobile App $\rightarrow$ API Gateway $\rightarrow$ Payment Processor (Stripe/PayPal) $\rightarrow$ Order Management System
*   **Target Architectures:** E-commerce stores, SaaS billing platforms, crypto exchanges, subscription engines, credit/wallet transfer portals.

---

## 2. Core Failure Modes

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                      أنماط ثغرات منطق الأعمال المالي والكميات                     │
├─────────────────────────┬─────────────────────────────────────────────────────────┤
│ A. Price & Currency     │ • إرسال كميات سالبة (quantity: -1) لخصم الإجمالي         │
│    Tampering            │ • التلاعب برمز العملة (currency: EGP بدلاً من USD)      │
│                         │ • كسور الأسعار المجهرية (amount: 0.0001)                │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ B. Inventory Locking    │ • حجز كميات المخزون في السلة دون دفع (Cart Holding DoS) │
│    (Business DoS)       │ • غياب عداد زمني لتحرير المخزون (Missing Expiry TTL)    │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ C. Multi-Step Desync    │ • دفع $1 لمنتج رخيص ثم استبدال كود المنتج في الخطوة 2   │
│                         │ • تخطي خطوة التحقق من الدفع (Forced Browsing to /success│
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ D. Coupon & Promo Loop  │ • تكرار تطبيق الكوبون في طلبات متزامنة (Race Condition) │
│                         │ • الجمع بين خصومات متضاربة (Discount Stacking)          │
│                         │ • حلقات الإحالة الذاتية (Self-Referral Bonus Cycling)   │
└─────────────────────────┴─────────────────────────────────────────────────────────┘
```

### 1. Price & Currency Parameter Manipulation
*   **Mechanism:** The server calculates the final amount based on client-supplied price or currency fields instead of reading strictly from the authoritative product database.
*   **High-Yield Payloads:**
    ```json
    // Original:
    {"item_id": 401, "price": 999.00, "quantity": 1, "currency": "USD"}

    // Attacks:
    {"item_id": 401, "price": 0.01, "quantity": 1, "currency": "USD"}
    {"item_id": 401, "price": 999.00, "quantity": -1}              // Negative price offset
    {"item_id": 401, "price": 999.00, "quantity": 1, "currency": "EGP"} // Currency mismatch without FX conversion
    {"item_id": 401, "price": 999.00, "quantity": 0.00001}        // Decimal truncation to 0
    ```

### 2. Inventory Lock via Cart Reservation (Business DoS)
*   **Mechanism:** Adding an item to the shopping cart or initiating checkout decrements the available stock counter in Redis/Database immediately *before* payment capture.
*   **Flaw:** If the application lacks an automatic Cart Expiration Time-to-Live (TTL) or lock release mechanism on abandoned sessions:
    *   Attacker writes a script to add 10,000 units of a limited item to cart using multiple fake accounts.
    *   Stock drops to `0` for all legitimate customers globally.
    *   No financial transaction is executed, causing direct operational and revenue Denial of Service.

### 3. Multi-Step Checkout Workflow Desync
*   **Mechanism:** Modern checkout flows involve distinct states:
    1. `POST /api/order/create` $\rightarrow$ returns `order_id: 101` (Amount: $1.00).
    2. `POST /api/payment/authorize` $\rightarrow$ verifies $1.00 authorization on Stripe.
    3. `POST /api/order/complete` $\rightarrow$ attacker modifies body to `order_id: 505` ($5,000 enterprise plan).
*   **Flaw:** The final completion endpoint relies solely on the presence of a valid transaction token without re-validating that `Transaction.Amount == Order.Total`.

### 4. Rounding Errors & Micro-Transaction Leaks
*   **Mechanism:** High-frequency balance splits, crypto exchanges, or multi-currency conversions using integer truncation instead of banker's rounding (`round-half-to-even`).
*   **Attack:** Transferring $0.0049 multiple times in a loop where sender is debited $0.00 while recipient receives $0.01.

### 5. Coupon Stacking & Single-Packet Race Conditions
*   **Mechanism:** Redeem single-use promo code with 20 parallel threads using **Turbo Intruder** (`gate='race1'`).
*   **Result:** Coupon discount applies 5x or 10x consecutively, resulting in a negative or zero-balance cart.

---

## 3. Practical Burp Suite Testing Playbook

### Step 1: Intercept Checkout Flow in Burp Repeater
1. Trace `Cart -> Shipping -> Payment -> Order Success`.
2. Inspect every JSON body for `price`, `amount`, `unit_price`, `currency`, `discount_code`.
3. Test negative values and extreme decimals.

### Step 2: Test Multi-Currency Tampering
1. Select USD item ($100).
2. Change `"currency": "USD"` $\rightarrow$ `"currency": "INR"` or `"currency": "EGP"` during checkout payload transmission.
3. Check if credit card gets billed 100 EGP (~$2 USD) instead of $100 USD.

### Step 3: Test Turbo Intruder Coupon Race
*   Send coupon application request to Turbo Intruder:
    ```python
    def queueRequests(target, wordlists):
        engine = RequestEngine(endpoint=target.endpoint, concurrentConnections=30, requestsPerConnection=100)
        for i in range(30):
            engine.queue(target.req, target.baseInput, gate='race1')
        engine.openGate('race1')

    def handleResponse(req, interesting):
        if req.status == 200:
            table.add(req)
    ```

---

## 4. Remediation & Defense
1. **Server-Side Authoritative Pricing:** Never trust price, currency, or discounts sent from the client. Compute totals strictly on the backend from the product catalog database.
2. **Atomic Payment Validation:** Ensure `PaymentGateway.AmountCaptured == Database.OrderTotal` immediately prior to state transition to `FULFILLED`.
3. **Cart Lock TTL:** Never hold physical inventory without a hard expiration timer (e.g. 15 minutes) enforced by Redis expiration keys.
