# 06 — Attack Hypothesis Ranking

## Goal
Prioritize the generated attack hypotheses based on operational impact and execution feasibility. Ensure the operator addresses high-risk systemic failures first.

## Ranking Algorithm
`Score = (Impact_Weight * 0.6) + (Confidence_Score * 0.4)`

### Impact Weighting (0 - 10)
Defines the business risk of the mechanism failure.
*   **10.0:** Cloud Control Plane Compromise (e.g., Workload Identity Escalation).
*   **9.0:** Global Authorization Bypass (e.g., ReBAC Consistency Gaps, OIDC Claim Spoofing).
*   **8.0:** Remote Code Execution / Async Trust Drift (e.g., Poisoning background workers).
*   **7.0:** Parser Smuggling & Data Exfiltration (e.g., Parser Differential Abuse).
*   **6.0:** State Machine Corruption / Idempotency Failures.
*   **5.0:** Standard Web Flaws (DOM XSS, Basic IDOR).

### Hypothesis Output Schema
```json
{
  "hypothesis_id": "HYP_001",
  "rank_score": 8.8,
  "title": "Workload Identity Escapement via OIDC Spoofing",
  "skill_reference": "infrastructure/workload_identity_federation.md",
  "target_nodes": ["api.target.com", "sts.amazonaws.com"],
  "rationale": "Inferred K8s OIDC federation boundary coupled with high-confidence AssumeRole indicators."
}
```
