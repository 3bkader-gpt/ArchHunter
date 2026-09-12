# 10 — Future Physical Implementation Strategy

This document outlines the technical implementation roadmap for transitioning from design to a functional code prototype.

## 1. Primary Tech Stack

| Layer | Technology | Rationale |
| :--- | :--- | :--- |
| **Execution Core** | **Go (Golang)** | High concurrency (goroutines) for ingestion and graph walkers. |
| **Graph Library** | **Cayley or Gonum** | Native Go graph processing; Cayley supports multiple backends. |
| **Orchestration** | **NATS JetStream** | Lightweight, high-performance messaging and persistence. |
| **Persistence** | **BadgerDB or ArangoDB** | Fast key-value store or native multi-model graph DB. |
| **Inference Logic** | **Python (via gRPC)** | Leverage Python's rich data science and AI libraries for agents. |

## 2. Implementation Roadmap

### Phase 1: Ingestion MVP
*   Implement `ArchitecturalSignal` parser in Go.
*   Basic NATS-based ingestion pipeline.
*   Log tailers for `httpx` and `katana`.

### Phase 2: In-Memory Graph
*   Build the concurrent DPG (Directed Property Graph).
*   Implement L1 (Physical) and L2 (Identity) node structures.
*   Basic BFS/DFS walkers for reachability.

### Phase 3: Mechanism Inference
*   Port key `skills/` logic into Python inference agents.
*   Implement gRPC bridge between Go core and Python agents.
*   Initial "Trust Boundary" extraction logic.

### Phase 4: Adaptive Feedback
*   Implement the Bayesian Confidence Scoring model.
*   Build the "Operator Override" API.
*   Temporal signal decay implementation.

## 3. Library & Framework Recommendations
*   **Graph:** `github.com/cayleygraph/cayley` (Querying), `github.com/gonum/graph` (Topology analysis).
*   **Event Sourcing:** `github.com/looplab/eventhorison` (CQRS/ES for Go).
*   **API:** `google.golang.org/grpc` (High-speed agent communication).

## 4. Execution Targets
*   **Local Prototype:** Single-binary Go application with embedded BadgerDB.
*   **Cloud Runtime:** Kubernetes-based deployment with NATS and ArangoDB for scaling.
