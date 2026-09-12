# Automated Architecture Inference Runtime

## Goal
The Runtime Implementation Layer serves as the blueprint for converting the static cognitive knowledge base into an **Executable Reasoning Platform**. It defines the data structures, graph schemas, and correlation engines required to automatically ingest recon data and output prioritized architectural attack hypotheses.

## Runtime Pipeline Modules
1.  **[01 — Runtime Architecture](01_runtime_architecture.md)**
2.  **[02 — Signal Ingestion Pipeline](02_signal_ingestion_pipeline.md)**
3.  **[03 — Graph Construction Engine](03_graph_construction_engine.md)**
4.  **[04 — Trust Boundary Extraction](04_trust_boundary_extraction.md)**
5.  **[05 — Mechanism Correlation Engine](05_mechanism_correlation_engine.md)**
6.  **[06 — Attack Hypothesis Ranking](06_attack_hypothesis_ranking.md)**
7.  **[07 — Confidence Scoring Model](07_confidence_scoring_model.md)**
8.  **[08 — Runtime Orchestration](08_runtime_orchestration.md)**
9.  **[09 — Machine-Readable DFD Schema](09_machine_readable_dfd_schema.md)**
10. **[10 — Future Runtime Implementation](10_future_runtime_implementation.md)**

## Operational Integration
This layer bridges `Workflow/04_fingerprint_to_architecture.md` and `Workflow/08_impact_modeling.md`. It consumes tool output (JSON) and generates machine-readable DFDs mapped directly to the `skills/` primitives.
