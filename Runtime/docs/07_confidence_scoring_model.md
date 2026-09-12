# 07 — Confidence Scoring Model

## Goal
Quantify the reliability of architectural inferences to prevent the engine from generating hallucinated or low-probability attack paths.

## Bayesian Scoring Logic
The engine uses an additive probability model. A single signal yields low confidence, but multiple intersecting signals drastically increase the confidence of an inference.

### Example: Inferring an "Async Workflow Boundary"
*   **Base Probability:** 0.1
*   **Signal A:** Endpoint returns `202 Accepted` (+0.3)
*   **Signal B:** Endpoint path contains `/job/`, `/queue/`, or `/process/` (+0.2)
*   **Signal C:** Response includes header `X-Task-ID` (+0.3)
*   **Signal D:** Port scanner detects `Kafka` or `RabbitMQ` on a related internal IP (+0.4)

*Result:* If A, B, and C are present, Confidence = 0.9 (High). Hypothesis is generated.

### Confidence Tiers
*   **High (> 0.8):** Confirmed via multiple distinct tool outputs (e.g., `httpx` headers matching endpoint path patterns).
*   **Medium (0.5 - 0.79):** Strongly implied by naming conventions or behavioral status codes.
*   **Low (< 0.5):** Weak inference based on a single generic signal. Requires operator manual validation before pursuing.
