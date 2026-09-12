# 03 — Adaptive Feedback & Confidence Refinement

The Adaptive Feedback System (AFS) is the learning layer of the runtime. it ensures that the system's architectural model evolves based on empirical evidence and operator feedback.

## 1. Confidence Scoring Model
Every Node, Edge, and Mechanism in the graph has an associated `ConfidenceScore` (0.0 to 1.0).

*   **Inferred (0.0 - 0.4):** Based on weak signals (e.g., common naming conventions).
*   **Predicted (0.4 - 0.7):** Based on structural patterns and mechanism correlation.
*   **Verified (0.7 - 1.0):** Based on direct empirical evidence (e.g., tool-specific findings, error messages).

## 2. Feedback Loops

### Empirical Signal Refinement
*   **Mechanism:** Ingestion of new tool outputs that confirm or contradict previous inferences.
*   **Example:** A prediction of an AWS Lambda backend is upgraded to "Verified" if a specific `x-amzn-RequestId` header is detected.

### Mechanism Confidence Decay
*   **Mechanism:** Confidence scores for inferred components naturally decrease over time if no supporting signals are received.
*   **Purpose:** Ensures the graph remains relevant and prioritizes active entrypoints.

### False-Positive Suppression
*   **Mechanism:** If an Attack Hypothesis is marked as "Invalid" by an operator or a validation step, the associated mechanism's weight is reduced across the entire graph.
*   **Learning:** The system "learns" that certain signal combinations are noise for this specific target.

## 3. Operator-Confirmed Signal Boosting
The runtime supports manual overrides where an operator can confirm an architectural fact (e.g., "This endpoint uses Istio Sidecar").
*   **Impact:** Boosting a node's confidence propagates through the graph, increasing the confidence of connected edges and dependent mechanisms.

## 4. Automatic Re-Weighting
1.  **Event:** `SignalAdded` or `OperatorOverride`.
2.  **Impact Analysis:** Determine which sub-graphs are affected.
3.  **Recalculation:** Update Confidence Scores using a Bayesian inference model.
4.  **Prioritization:** Re-rank Attack Hypotheses based on the updated scores.
