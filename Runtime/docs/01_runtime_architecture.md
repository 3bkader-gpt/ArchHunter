# 01 — Runtime Architecture

## System Design
The Runtime Architecture is a pipeline designed to transform flat, unstructured reconnaissance data into a multi-dimensional, semantically aware **Data Flow Graph**.

### Core Components
1.  **Data Intake (The Receiver):** A localized API or file watcher that ingests JSON lines from tools like `httpx`, `katana`, and `arjun`.
2.  **Signal Normalizer:** Flattens disparate tool outputs into a unified `ArchitecturalSignal` schema.
3.  **Graph Synthesizer:** Constructs an in-memory directed graph (Nodes = Endpoints/Services, Edges = Data Flows/Identity Transitions).
4.  **Inference Engine:** Applies rulesets (e.g., "If Node A uses OIDC and routes to Node B, edge is a Federation Boundary") to tag graph edges with trust boundary metadata.
5.  **Correlation Matrix:** Maps tagged boundaries to specific attack primitives in the `skills/` directory.
6.  **Emitter:** Outputs the final `InferredDFD` JSON and a ranked list of `AttackHypotheses`.

## Design Constraints
*   **No Active Scanning:** The runtime is strictly an analysis engine. It does not send HTTP requests or execute payloads.
*   **Stateless Execution:** Each execution run processes a specific point-in-time recon snapshot to ensure reproducible reasoning.
*   **Idempotent Inference:** Feeding the same recon JSON twice must produce the identical DFD and hypotheses.
