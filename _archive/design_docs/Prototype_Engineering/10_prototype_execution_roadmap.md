# 10 — Prototype Execution Roadmap

This outlines the phased delivery of the final executable prototype, moving from theoretical architecture to a running system.

## 1. Phased Implementation Plan
*   **Phase 1 (Ingestion & L1 Graph):** Build the Go-based NATS consumer, normalization logic, and the basic in-memory node/edge mapping.
*   **Phase 2 (Inference & Scoring):** Introduce the Python gRPC agents. Implement the Bayesian scoring model and the first basic "Trust Boundary" walker.
*   **Phase 3 (State & Observability):** Implement event-sourcing persistence, snapshotting, and the Inference Traceability logs.
*   **Phase 4 (UI & Operator Interface):** Build the collaborative web UI (React/D3.js or similar) with WebSocket synchronization.

## 2. MVP Runtime Path
The Minimum Viable Product (MVP) will focus exclusively on:
1.  Ingesting `httpx` and basic `katana` endpoint tags.
2.  Building a 2-layer graph (Physical + Basic Identity/Headers).
3.  Generating a single type of hypothesis (e.g., "Missing Auth at Trust Boundary").
4.  Supporting operator overrides via a simple CLI or basic API.

## 3. Graph Engine Priorities
*   **Priority 1:** Thread-safe concurrent map access in Go.
*   **Priority 2:** Tarjan's algorithm for circular dependency detection.
*   **Priority 3:** Persistent snapshotting to BadgerDB.

## 4. Go/Python Integration Roadmap
*   **Core (Go):** Heavy lifting, ingestion, state management, routing, and fast graph traversal.
*   **Cognition (Python):** The multi-agent models (Parser Agent, Identity Agent) subscribe to NATS topics, query the Go core via gRPC, run heuristic models, and issue graph mutation commands back to Go.

## 5. Observability-First Rollout Strategy
Before complex inference is trusted, the observability pipelines must be rock solid.
*   Every node addition must have an associated provenance trace.
*   The system will run in "Shadow Mode" initially, visualizing its inferences for operators without actively guiding them, to tune the False-Positive suppression loops.
