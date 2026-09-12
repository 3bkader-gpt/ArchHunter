# 06 — Runtime Pipeline Orchestration

The Runtime Pipeline Orchestration (RPO) defines the sequential and parallel stages that transform tool output into architectural models.

## 1. Pipeline Stages

### Stage 1: Ingestion & Normalization
*   **Trigger:** New data arriving from tools (`katana`, `httpx`, `cloudsploit`).
*   **Activity:** Raw logs are normalized into `ArchitecturalEvidence` objects.
*   **Constraint:** Must be purely stateless and idempotent.

### Stage 2: Evidence Fusion
*   **Trigger:** `EvidenceCreated` event.
*   **Activity:** The Evidence Correlation Engine (ECE) merges signals into existing graph nodes and edges.
*   **Output:** An updated Topological Map with initial weights.

### Stage 3: Inference & Extraction
*   **Trigger:** `TopologyChanged` or crossing a "Data Density" threshold.
*   **Activity:** Specialized inference agents (Identity, Parser, Distributed-State) traverse the graph.
*   **Output:** New Mechanisms, Trust Boundaries, and Parser Chains.

### Stage 4: Scoring & Prioritization
*   **Trigger:** Inference completion.
*   **Activity:** Attack hypotheses are generated and ranked using the Bayesian scoring model.
*   **Output:** A prioritized list of `AttackHypotheses`.

### Stage 5: Feedback & Validation
*   **Trigger:** Operator override or automated empirical validation.
*   **Activity:** Confidence scores are updated, and the graph is re-weighted.
*   **Loop:** Returns to Stage 3 if significant confidence deltas occur.

## 2. Orchestration Strategy
*   **Parallel Ingestion:** Multiple workers process tool outputs concurrently.
*   **Async Inference:** Inference agents run in background tasks to avoid blocking the ingestion stream.
*   **Saga Pattern:** Complex, multi-stage inferences use the Saga pattern to handle partial failures and rollbacks (e.g., if a provider identification is found to be false).

## 3. Monitoring & Observability
*   **Pipeline Health:** Tracks throughput of ingestion and inference.
*   **Confidence Drift:** Monitors how quickly the system's "Understanding" of the target improves.
*   **Agent Performance:** Metrics for each specialized inference agent.
