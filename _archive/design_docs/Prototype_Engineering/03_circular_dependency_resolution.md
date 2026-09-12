# 03 — Circular Dependency Resolution

Modern microservice meshes and complex IAM architectures frequently contain circular references. The Graph Execution Runtime must resolve these without infinite loops or memory exhaustion.

## 1. Recursive Trust-Loop Handling
*   **Cycle Detection:** Implement Tarjan's strongly connected components algorithm or standard Depth-First Search (DFS) back-edge detection during boundary inference.
*   **Edge Pruning (Logical):** When a loop is detected (e.g., Service A calls Service B calls Service A), the Graph Engine maintains the physical edges but collapses the logic into a "Circular Trust Component" node for inference purposes.

## 2. Cyclic Identity Graph Resolution
Identity delegation can form loops (e.g., Role A can assume Role B, which can assume Role A).
*   **Max-Depth Tracing:** Set a hard threshold (e.g., `max_hops = 5`) for identity propagation tracers to prevent runaway inference.
*   **Loop Unrolling:** Represent loops in the UI as self-referential identity nodes rather than rendering infinite paths, halting the Identity Agent's traversal once the cycle is identified.

## 3. Confidence Decay in Recursive Paths
*   **Path Degradation:** As an inference agent traverses deeper into a cyclic path, the `ConfidenceScore` of derived hypotheses decays exponentially.
*   **Rationale:** An attack chain requiring 5 levels of cyclic identity assumption is inherently less reliable (lower confidence) than a direct 1-hop exploitation path.

## 4. Graph Convergence Heuristics
*   **Stable State Identification:** The Orchestration Core monitors inference updates. If the graph weight deltas drop below a defined epsilon (`ε`), the graph is considered "converged" and cyclic inference is forcibly halted to save CPU cycles.
