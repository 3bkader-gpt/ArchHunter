# 08 — Attack Hypothesis Generation

## Goal
Generate a prioritized list of **Attack Hypotheses** by correlating inferred architectural traits with known mechanism failure classes.

## Hypothesis Generation Matrix

| Architectural Trait | Likely Failure Class | Offensive Pivot |
| :--- | :--- | :--- |
| **Multi-region + JWT** | Stale Revocation | [Consistency Failures](../skills/state_management/consistency_failures.md) |
| **H2 Gateway + H1.1 Backend** | Request Smuggling | [Parser Differential Abuse](../skills/infrastructure/parser_differential_abuse.md) |
| **Async Queue + PDF Renderer** | Trust Drift RCE | [Async Workflow Integrity](../skills/state_management/async_workflow_integrity.md) |
| **IMDSv1 + Webhook API** | Cloud Identity Theft | [IAM Trust Boundaries](../skills/auth_logic/iam_trust_boundaries.md) |
| **Zanzibar / ReBAC API** | External Consistency Gap | [Distributed Auth Propagation](../skills/state_management/distributed_auth_propagation.md) |

## Confidence-Tier Scoring
*   **Tier 1 (High Priority):** Correlation of 3+ independent signals (e.g., Regional naming + 202 status + Custom timestamps).
*   **Tier 2 (Medium Priority):** Common architectural anti-pattern (e.g., Proxy with `X-Forwarded-For` and default-deny).
*   **Tier 3 (Low Priority):** Inferred but unverified technology (e.g., generic Port 80 response).

## Automation Output (Reasoning Input)
A prioritized list of attack vectors for the operator to validate manually in **[Workflow Phase 06](../Workflow/06_manual_validation.md)**.

---
[INFERENCE COMPLETE: SYSTEM READY FOR EXECUTION]
