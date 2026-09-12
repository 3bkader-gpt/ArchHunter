# 02 — Graph Execution Runtime

The Graph Execution Runtime (GER) is responsible for the algorithmic traversal of the Data Flow Graph (DFG) to extract architectural insights.

## 1. DFG Traversal Logic
The GER implements a set of specialized walkers that navigate the graph to identify vulnerable patterns without exploit execution.

### Trust-Boundary Walking
*   **Objective:** Identify where data crosses from an untrusted zone (e.g., Public Internet) to a trusted zone (e.g., Internal VPC).
*   **Logic:** BFS traversal from root nodes (Entrypoints) until an edge with a `TrustBoundary` property is encountered.
*   **Detection:** Flags missing "Validation Mechanisms" at these boundaries.

### Parser Transition Tracing
*   **Objective:** Map how a single request is re-parsed across multiple services.
*   **Logic:** Tracks the transformation of request objects through the graph.
*   **Signatures:** Flags "Parser Differentials" where Edge A (Proxy) and Edge B (Backend) use different RFC 7230 interpretations.

### Identity Propagation Pathing
*   **Objective:** Trace the flow of identity context (tokens, cookies) through the system.
*   **Logic:** Monitors the `IdentityContext` property on nodes.
*   **Detection:** Flags "Identity Leaks" where context is propagated to a low-trust node without re-validation.

## 2. Distributed-State Traversal
*   **Objective:** Model consistency and state synchronization risks in distributed systems.
*   **Logic:** Identifies nodes that share a `StateBackend` (e.g., Redis) but have different `ConsistencyGuarantees`.
*   **Detection:** Flags potential race conditions and cache poisoning paths.

## 3. Execution Primitives
*   **Concurrent Walkers:** Multi-threaded graph walkers that handle large-scale DFGs.
*   **Incremental Updates:** Only re-runs walkers on sub-graphs affected by new signals.
*   **Cycle Detection:** Prevents infinite loops in complex microservice meshes.

## 4. Output: The Inferred DFD
The result of GER execution is a **Machine-Readable DFD** that includes:
*   Confirmed Nodes (High Confidence).
*   Inferred Nodes (Low Confidence - requiring more recon).
*   Active Trust Boundaries.
*   Parser Chains.
