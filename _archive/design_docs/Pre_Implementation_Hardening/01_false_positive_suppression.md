# 01 — False Positive Suppression & Hallucination Prevention

The integrity of the Reasoning Engine depends on its ability to filter noise and prevent LLM-based agents from "hallucinating" architectural components that do not exist.

## 1. Probabilistic Suppression Loops
*   **Hypothesis Gating:** No `AttackHypothesis` is promoted to the UI unless it crosses a dynamic `SuppressionThreshold` (initially 0.6).
*   **Conflict Resolution:** If Agent A (Parser) predicts a mechanism and Agent B (Identity) finds evidence that contradicts it (e.g., an auth bypass that shouldn't work on that parser), the system triggers an automatic `ConflictSuppression` event, dropping the confidence of both until further recon arrives.

## 2. Hallucination Prevention (Agent Guardrails)
*   **Evidence Pinning:** Agents are prohibited from proposing a node property unless it is linked to a `SourceSignalID`.
*   **Negative Signals:** The system explicitly tracks "Negative Evidence" (e.g., "Tried Path X, got 404"). Negative signals provide a heavy negative weight to related inferences, "pruning" hallucinated paths.

## 3. Evidence Quorum Thresholds
*   **Multi-Source Verification:** Critical architectural features (like a Trust Boundary) require a quorum of signals from at least two different tool categories (e.g., Header Analysis + Timing Delta).
*   **Confidence Hardening:** Inferences based on a single signal are marked as `Speculative` and suppressed from high-priority dashboards.

## 4. Adaptive Trust Scoring (Signal Reliability)
*   **Source Calibration:** Not all tools are equally reliable. The system maintains a `ToolTrustScore`. If a scanner frequently produces findings that are later invalidated by an operator, its influence on the overall `ConfidenceScore` is automatically dampened.
