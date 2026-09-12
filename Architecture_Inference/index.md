# Automated Architecture Inference Layer

## Goal
The Inference Layer automates the translation of raw reconnaissance data into structured architectural hypotheses. It bridges the gap between physical discovery and logical reasoning.

## Orchestration Flow

1.  **[Signal Classification](01_recon_signal_classification.md):** Classify headers, ports, and TLS metadata into architectural indicators.
2.  **[Service Clustering](02_service_clustering.md):** Group disparate endpoints into logical clusters (Tier 1/2/3).
3.  **[Trust Boundary Inference](03_trust_boundary_inference.md):** Locate edges where data changes hands or parsers execute.
4.  **[Identity Propagation Mapping](04_identity_propagation_mapping.md):** Map the lifecycle of user and workload identities.
5.  **[Async & Distributed Inference](05_async_distributed_inference.md):** Detect queues, replicas, and consistency risks.
6.  **[Parser Pipeline Mapping](06_parser_pipeline_mapping.md):** Infer sequences of proxies, WAFs, and backends.
7.  **[DFD Generation](07_dfd_generation.md):** Synthesize findings into a DFD for STRIDE analysis.
8.  **[Attack Hypothesis Generation](08_attack_hypothesis_generation.md):** Prioritize mechanism failures for manual validation.

---
*Operational Rule: Do not trust a single signal; correlate across clusters to infer the hidden logic.*
