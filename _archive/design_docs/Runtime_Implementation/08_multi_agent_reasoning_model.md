# 08 — Multi-Agent Reasoning Model

The Multi-Agent Reasoning Model (MARM) distributes architectural inference across specialized cognitive units.

## 1. Inference Agents

### Identity Agent
*   **Specialization:** Auth flows (OAuth, SAML, JWT), Identity Propagation, IAM trust relationships.
*   **Reasoning:** Detects when an identity context is insufficiently validated across a boundary.

### Parser Agent
*   **Specialization:** HTTP parsing, serialization formats (JSON, Protobuf), GraphQL schema analysis.
*   **Reasoning:** Identifies "Parser Differentials" by comparing the known behaviors of upstream proxies and downstream backends.

### Distributed-State Agent
*   **Specialization:** Cache consistency, database replication lags, async job queues, race conditions.
*   **Reasoning:** Models how state changes propagate and identifies windows of inconsistency.

### Infrastructure Agent
*   **Specialization:** Cloud providers (AWS, Azure, GCP), Kubernetes, Service Meshes, Serverless environments.
*   **Reasoning:** Infers hidden infrastructure based on network metadata and provider-specific behavior.

## 2. Agent Orchestration

### Coordination Strategy
*   **Hierarchical:** The Orchestration Core acts as the "Brain," tasking specialized agents and fusing their outputs.
*   **Blackboard Pattern:** Agents write their partial inferences to a shared blackboard (the Graph), which other agents can then use to further their reasoning.

### Conflict Resolution
*   **Weighting:** If the Identity Agent and the Infrastructure Agent disagree on a node's property, the system uses the higher-confidence signal.
*   **Mediation:** The Orchestration Core can trigger "Verification Tasks" to resolve conflicts (e.g., requesting more targeted recon).

## 3. Reasoning Lifecycle
1.  **Observation:** Ingestion of signals into the blackboard.
2.  **Specialization:** Relevant agents "wake up" based on signal types.
3.  **Inference:** Agents update graph properties and confidence scores.
4.  **Synthesis:** Orchestration Core builds the multi-layer DFD and attack hypotheses.
5.  **Refinement:** Feedback loops improve future agent accuracy.
