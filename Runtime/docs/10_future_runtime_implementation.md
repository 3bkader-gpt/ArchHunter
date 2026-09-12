# 10 — Future Runtime Implementation

## Goal
Establish the technical roadmap for actually coding the inference engine into a deployable binary or service.

## Recommended Tech Stack
*   **Language:** Go (Golang) - Preferred for its concurrency model, memory safety, and seamless integration with the existing ProjectDiscovery ecosystem (parsing `httpx` JSON natively).
*   **Graph Engine:** `gonum` (for in-memory DAG modeling) or Neo4j (if persistent querying via Cypher is required for massive datasets).
*   **Data Ingestion:** Standard `stdin` pipelines, allowing the engine to be piped directly from recon tools: `httpx -json | arch-infer -correlate`.

## Development Roadmap
1.  **Phase 1: The Normalizer.** Build Go structs to marshal various recon JSON formats into the `ArchitecturalSignal` format.
2.  **Phase 2: The DAG Builder.** Implement the `gonum` graph and write the clustering heuristics to merge duplicate IPs/Subdomains into logical nodes.
3.  **Phase 3: The Boundary Rules Engine.** Implement a simple rules engine (e.g., using `expr` or custom Go logic) to traverse the graph and tag boundaries.
4.  **Phase 4: Output Emitters.** Write serializers for `MachineReadableDFD.json` and a human-readable Markdown hypothesis report.

## Integration with LLMs
Once implemented, this CLI tool will act as the perfect precursor to an LLM Agent. Instead of feeding the agent 100,000 lines of raw recon JSON, the operator feeds the agent the `MachineReadableDFD.json` and the ranked hypotheses, drastically reducing token usage and hallucination while maximizing architectural context.
