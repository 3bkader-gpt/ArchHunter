# 06 — Streaming Inference Refinement

Inference is not a batch process; it is a continuous stream of hypothesis generation, empirical testing, and model correction.

## 1. Live Signal Refinement
*   **Continuous Feedback:** As new data streams in, the Bayesian model instantly recalculates the `ConfidenceScore` for affected nodes.
*   **Threshold Triggers:** If a score crosses a threshold (e.g., > 0.8), it triggers the generation of new downstream hypotheses immediately.

## 2. Adaptive Confidence Evolution
*   **Decay and Reinforcement:** The system automatically decays the confidence of inferences based on ephemeral data (e.g., dynamic IPs) while solidifying long-standing structural inferences (e.g., IAM roles).
*   **Source Weighting:** Over time, the runtime dynamically adjusts the reliability weights of different ingestion tools based on historical accuracy.

## 3. Inference Correction Pipelines
*   **Automated Retraction:** If a high-confidence signal contradicts a previous assumption (e.g., a 404 indicates a previously "Discovered" API no longer exists), the system retracts the node and instantly cascades "Invalidation" events down to all dependent attack hypotheses.
*   **Saga Compensating Transactions:** The Orchestration Core issues compensating actions to remove derived edges when foundational evidence is invalidated.

## 4. Architecture Hypothesis Mutation
*   **Dynamic Reprioritization:** As the graph evolves, the ranking of `AttackHypotheses` shifts in real-time. A low-priority issue might jump to #1 if a new recon signal links it directly to a sensitive internal trust boundary.
