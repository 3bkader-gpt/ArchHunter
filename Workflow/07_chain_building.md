# 07 — Chain Building (Escalation)

## Operational Goal
Combine low-impact mechanism failures into critical compromises by crossing major Trust Boundaries. This is where "Critical" bugs are manufactured.

## Escalation Primitives

### 1. The Cloud Metadata Pivot (Workload to Control Plane)
*   **Trigger:** SSRF in a PDF generator or webhook.
*   **Chain:** Extract IMDSv1/v2 credentials -> Authenticate via AWS CLI -> `AssumeRole` -> Access S3/RDS data.
*   **Reasoning:** Exploits the transition from [Workload Identity](../skills/infrastructure/workload_identity_federation.md) to [Cloud-Native Role Delegation](../skills/auth_logic/iam_trust_boundaries.md).

### 2. The Async State Desync (Edge to Background Worker)
*   **Trigger:** Parameter injection leading to a delayed payload execution.
*   **Chain:** Inject Blind XSS or Command Injection payload -> Trigger background export/email job -> Gain execution in the high-privilege worker pool.
*   **Reasoning:** Exploits [Async Trust Drift](../skills/state_management/async_workflow_integrity.md) where background workers assume data is pre-validated by the edge.

### 3. The Protocol Desync (Proxy to Backend)
*   **Trigger:** HTTP Request Smuggling.
*   **Chain:** Desync the load balancer -> Smuggle administrative requests -> Bypass frontend WAF/Auth -> Access internal APIs.
*   **Reasoning:** Exploits [Parser Differential Abuse](../skills/infrastructure/parser_differential_abuse.md).

## Business-Logic Chains (Depth-First)

Agents report these individually as Info/Low and move on. The chain is the finding — each primitive alone is "non-issue", together it is Account Takeover or Stored XSS.

### 1. Host Header Poisoning → Pre-Auth ATO
*   **Primitives:** Arbitrary `Host` header accepted (Low) + password-reset link renders `Host` into the emailed URL (Low) + rate-limit evasion on the reset endpoint (Info).
*   **Chain:** Spoof `Host: evil.com` on the reset request → victim's reset token is delivered to the attacker's domain → token used before victim notices.
*   **Reasoning:** [cache_attacks](../skills/state_management/cache_attacks.md) + [rate_limiting_evasion](../skills/state_management/rate_limiting_evasion.md) + [pre_account_takeover](../skills/auth_logic/pre_account_takeover.md).

### 2. Upload + Error-Page CSP Gap → Stored XSS
*   **Primitives:** SVG upload permitted (Info) + error/referrer page rendered without CSP framing/script restrictions (Info).
*   **Chain:** Host the payload SVG as a "profile image" → force the privileged victim through the CSP-less error page referencing it → script executes in-app.
*   **Reasoning:** [file_upload_rce](../skills/infrastructure/file_upload_rce.md) + [xss_variations](../skills/infrastructure/xss_variations.md).

### 3. State-Dependent IDOR (Two-Role Workflow)
*   **Primitives:** Create-resource endpoint as User A (normal) + resource ID accepted cross-team (Low IDOR on GET).
*   **Chain:** `POST /api/teams/ATTACKER_TEAM/invite` → swap path ID to `VICTIM_TEAM` while acting as attacker → invite accepted because the token is never bound to the team object it was issued for.
*   **Reasoning:** [logic_idor_auth](../skills/auth_logic/logic_idor_auth.md) + [state_machine_integrity](../skills/state_management/state_machine_integrity.md) — the state map ([Workflow 10](10_depth_first_web_api.md) Phase 1) is what reveals which IDs are swappable in-flight.

### 4. Coupon Persistence Race (Financial State Tampering)
*   **Primitives:** Coupon removal does not invalidate the discount binding (Low) + no DB lock on checkout totals (Low).
*   **Chain:** Apply 100% coupon → remove item → race checkout against coupon expiry/invalidation → discount persists on the final charge.
*   **Reasoning:** [race_conditions](../skills/state_management/race_conditions.md) + [business_logic_financial](../skills/state_management/business_logic_financial.md).

**Worksheet:** log every Info/Low in [`templates/CHAINING_WORKSHEET_TEMPLATE.md`](../templates/CHAINING_WORKSHEET_TEMPLATE.md) and review it every Friday before closing the week.

## Outcome
A mapped sequence of requests that demonstrates a systemic breakdown of the architecture's security model.

## Transition to Impact Modeling
Proceed to **[08 — Impact Modeling](08_impact_modeling.md)** to define the true business risk of the path.