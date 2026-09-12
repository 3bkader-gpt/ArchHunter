# 02 — Statistical Confidence Calibration

This document defines the mathematical framework for calibrating the system's "Certainty" in its architectural inferences.

## 1. Bayesian Prior Refinement
The system initializes node properties with "Priors" based on the infrastructure provider.
*   **Infrastructure Priors:**
    *   `AWS_ALB` -> High Prior for `HTTP_2_Support`, Medium Prior for `OIDC_Integration`.
    *   `Unknown_Nginx` -> Neutral Priors.
*   **Dynamic Updating:** As signals arrive, the `ConfidenceScore` is updated using a Bayesian update function: `P(Arch | Signal) = [P(Signal | Arch) * P(Arch)] / P(Signal)`.

## 2. Operator-Feedback Weighting
Operator actions are the "Ground Truth."
*   **Confirmation (+1.0):** If an operator marks a node as "Correct," its confidence is locked to 1.0 and its properties become immutable for the machine.
*   **Rejection (-1.0):** If an operator rejects an inference, the system recalculates the weights of the *Rules* that led to that inference, effectively "tuning" the Multi-Agent Reasoning model.

## 3. Uncertainty Propagation
Confidence scores are not isolated; they propagate through the graph.
*   **Edge Propagation:** If Node A (Proxy) has 0.9 confidence and Node B (Backend) has 0.4, the Edge between them (the flow) cannot have a confidence higher than 0.4.
*   **Chain Degradation:** In long parser chains, the overall confidence of the chain is the product of the confidence of all constituent edges.

## 4. Temporal Decay Tuning
Architectural knowledge has a half-life.
*   **Decay Constants:** Physical nodes (IPs) decay faster (7 days) than Logical nodes (IAM Roles - 30 days).
*   **Re-Verification:** As a node's confidence decays below 0.3, the system automatically tags it for a "Re-recon" task to find fresh signals.
