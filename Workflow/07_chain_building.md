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

## Outcome
A mapped sequence of requests that demonstrates a systemic breakdown of the architecture's security model.

## Transition to Impact Modeling
Proceed to **[08 — Impact Modeling](08_impact_modeling.md)** to define the true business risk of the path.