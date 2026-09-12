# 08 — Runtime Orchestration

## Goal
Manage the state machine of the automated inference process.

## Execution States

1.  `INIT`: Load correlation rules and skill mappings from the Knowledge Base.
2.  `INGEST_WAIT`: Poll for or receive `httpx.json`, `katana.json`, and `arjun.json`.
3.  `NORMALIZE`: Parse raw JSON into `ArchitecturalSignal` objects.
4.  `BUILD_GRAPH`: Instantiate nodes and evaluate `ROUTES_TO` and `TRUSTS` edges.
5.  `INFER_BOUNDARIES`: Run traversal algorithms to detect trust, parser, and temporal gaps.
6.  `CORRELATE`: Match boundaries to `skills/*.md` primitives.
7.  `RANK`: Apply Confidence and Impact math.
8.  `EMIT_DFD`: Generate `MachineReadableDFD.json`.
9.  `EMIT_HYPOTHESES`: Generate human-readable Markdown report of ranked hypotheses for the operator.

## Handling Partial Data
The orchestrator must support **Progressive Enhancement**. If only `httpx` data is available, it generates a low-resolution graph. If `katana` data is added later, the orchestrator re-runs `BUILD_GRAPH` to inject new nodes and re-evaluates hypotheses.
