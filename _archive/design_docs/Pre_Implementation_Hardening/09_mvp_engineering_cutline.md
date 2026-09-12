# 09 — MVP Engineering Cutline

This document defines the strict Minimum Viable Product (MVP) boundary to ensure project completion and avoid feature-creep during the initial build.

## 1. Core Core (Must Have)
1.  **Fast In-Memory Graph (Go):** Thread-safe nodes/edges with basic property support.
2.  **Basic Ingestion (Go):** JSONL log tailer for `httpx` and `katana`.
3.  **One Specialized Agent (Python/gRPC):** The "Trust Boundary Agent."
4.  **Static UI (React):** Read-only graph rendering using a basic D3.js force-directed layout (no WebGL yet).
5.  **Event Ledger (BadgerDB):** Local persistence of signals and graph snapshots.

## 2. Distributed Scaling (Phase 2)
1.  **Graph Sharding:** Shard nodes across multiple machines.
2.  **NATS JetStream:** Move from local Go channels to a real message broker.
3.  **WebGL Rendering:** High-performance GPU rendering for massive graphs.
4.  **Temporal Timelines:** Scrubbing through historical architecture states.

## 3. Advanced Cognition (Phase 3)
1.  **Distributed-State Agent:** Modeling race conditions and consistency.
2.  **Bayesian Prior Tuning:** Sophisticated provider-specific priors.
3.  **CRDT Collaborative UI:** Real-time multi-operator synchronization.
4.  **Inference Tracing (Jaeger):** Full distributed tracing for reasoning.

## 4. Implementation Priority Order
1.  **L1 Graph Engine:** The foundation of all reasoning.
2.  **Ingestion Mesh:** Getting data into the graph.
3.  **Trust Boundary Agent:** The primary value-add of architectural reasoning.
4.  **Basic Dashboard:** Visualizing the inferences.
5.  **Local Snapshotting:** Ensuring work is not lost.

## 5. Non-Core (Deferred)
*   Autonomous payload generation.
*   Exploit execution or validation.
*   SIEM/Log Management features.
*   Mobile UI support.
