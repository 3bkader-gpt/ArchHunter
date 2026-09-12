# Mechanism: Webhook & Third-Party Integration Trust Flaws

## 1. Architectural Vulnerability Profile
*   **Vulnerability Class:** Unverified Event Ingestion / Outbound SSRF / Signature Replay
*   **STRIDE Category:** Elevation of Privilege, Tampering, Spoofing, Information Disclosure
*   **Trust Boundary Crossed:** External Webhook Emitter (e.g. Stripe, Shopify, GitHub, Attacker) $\rightarrow$ Ingestion Webhook Controller $\rightarrow$ Internal Business Queue
*   **Target Architectures:** Payment gateways, CI/CD integrations, CRM syncing, Slack/Discord bots, custom webhook handlers (`/api/webhooks/*`).

---

## 2. Core Failure Modes

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                     أنماط ثغرات معالجة الـ Webhooks والربط الخارجي                 │
├─────────────────────────┬─────────────────────────────────────────────────────────┤
│ 1. Missing HMAC Sig     │ • غياب التحقق من التوقيع (Stripe-Signature / X-Hub-Sig)  │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 2. Blind Outbound SSRF  │ • تسجيل رابط Webhook يشير لـ Cloud Metadata أو شبكة داخلية│
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 3. Signature Replay     │ • إعادة إرسال أحداث سابقة معتمدة دون فحص الطابع الزمني   │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 4. Cross-Tenant Event   │ • تزوير أحداث (Event Injection) للتلاعب بحسابات مستأجر آخر│
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 5. Redirect Following   │ • تتبع خادم الـ Webhook لإعادة التوجيه (302) نحو IP داخلي │
└─────────────────────────┴─────────────────────────────────────────────────────────┘
```

### 1. Ingestion: Missing HMAC Signature Verification
When the backend processes inbound webhooks (`POST /api/webhooks/stripe`) without validating the cryptographic signature:
```http
POST /api/webhooks/stripe HTTP/2
Host: api.target.com
Content-Type: application/json

{
  "type": "checkout.session.completed",
  "data": {
    "object": {
      "customer_email": "attacker@evil.com",
      "amount_total": 500000,
      "payment_status": "paid",
      "metadata": {
        "user_id": "attacker-uuid",
        "plan": "enterprise"
      }
    }
  }
}
```
*   **Impact:** Attacker directly forges "payment successful" events without spending any money, triggering full subscription upgrades or wallet credit issuance!

### 2. Registration: Blind Outbound SSRF
When an application allows users to configure a custom Webhook URL (`POST /api/settings/webhooks` with `"url": "http://..."`):
*   **SSRF Injection Payloads:**
    ```text
    http://169.254.169.254/latest/meta-data/iam/security-credentials/
    http://metadata.google.internal/computeMetadata/v1/
    http://127.0.0.1:8080/actuator/env
    http://kubernetes.default.svc.cluster.local
    ```
*   **302 Redirect Bypass:** If the server validates that the registered URL is a public domain (`http://attacker.com/webhook`), the attacker's server responds with `HTTP 302 Found` $\rightarrow$ `Location: http://169.254.169.254/`. If the HTTP client follows redirects without re-checking the destination IP, SSRF succeeds.

### 3. Replay Attacks & Timestamp Drift
*   If signature verification only validates `HMAC(secret, body)` but ignores the timestamp `t=...`:
    *   Attacker captures a valid refund or credit event from last year and replays it 1,000 times to repeatedly inflate wallet balances.

---

## 3. Offensive Testing Checklist

- [ ] Can you call `/api/webhooks/*` without `X-Signature` or with a randomized signature header?
- [ ] Does the application accept `POST /webhooks/github` without checking `X-Hub-Signature-256`?
- [ ] Can you register `http://169.254.169.254` or `http://127.0.0.1:port` as your team webhook endpoint?
- [ ] Does the test webhook trigger an Outbound HTTP request immediately ("Send Test Webhook" button)?
- [ ] Does the webhook handler follow 302 redirects to internal IP ranges?
- [ ] Can you modify `"customer_id"` or `"tenant_id"` inside an unverified webhook payload to mutate another customer's state?

---

## 4. Remediation & Defense
1. **Enforce Raw Body HMAC Verification:** Always verify signatures against the exact raw byte stream *before* parsing JSON.
2. **Timestamp Verification:** Reject any webhook where `|CurrentTime - EventTimestamp| > 300 seconds`.
3. **Hardened SSRF Safe HTTP Client:** Disable redirect following and validate resolved IP against RFC1918 / Cloud Metadata CIDRs at the socket connection level.
