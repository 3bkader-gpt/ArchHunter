# 06 — Runtime Performance Guardrails

The Reasoning Engine must protect itself from resource exhaustion and runaway processes during massive ingestion or complex inference tasks.

## 1. Resource Protection
*   **Memory Sandboxing:** Limit the size of each `ReasoningSession` graph to a percentage of total system RAM.
*   **CPU Quotas:** Assign core-specific quotas to the Multi-Agent Reasoning units to prevent an "Identity Loop" from starving the ingestion workers.

## 2. Ingestion Throttling
*   **Elastic Rate Limiting:** Throttles incoming `RawSignals` if the Graph Engine's lock contention or write latency crosses a threshold.
*   **Signal Prioritization:** During heavy load, "Information-Only" signals (e.g., specific HTTP headers) are dropped in favor of "Structural" signals (e.g., new IP or domain discovery).

## 3. Graph Explosion Prevention
*   **Connectivity Limits:** Prevent nodes from having more than a set number of edges (e.g., `max_edges = 5000`) unless explicitly whitelisted (e.g., for a central OAuth server).
*   **Neighbor Culling:** In extremely dense sub-graphs, the engine dynamically collapses low-confidence or redundant nodes to keep traversal speeds manageable.

## 4. Inference Recursion Limits
*   **Hard Depth Caps:** Limit identity propagation and trust boundary walkers to a maximum recursion depth (e.g., `max_depth = 10`).
*   **Cycle Cutoffs:** Detect and halt any walker that re-visits the same node in a single traversal path.

## 5. Adaptive Load Shedding
*   **Graceful Degradation:** If the system is under extreme load, it disables L3 (Mechanism) inference and strictly focuses on maintaining the L1 (Physical) graph.
*   **Worker Ejection:** If an agent consistently exceeds its execution time budget, the Orchestration Core ejects and restarts it.
