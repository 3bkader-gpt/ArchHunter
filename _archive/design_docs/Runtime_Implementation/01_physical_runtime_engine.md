# 01 — Physical Runtime Engine (PRE) Architecture

The Physical Runtime Engine (PRE) is the high-performance execution core of the architectural reasoning system. It transforms passive mechanism models into an active, event-driven inference machine.

## 1. System Architecture
The PRE follows a Hexagonal Architecture, decoupling the core reasoning logic from ingestion and persistence adapters.

### Ingestion Mesh (Ports/Adapters)
*   **Log Tailing Workers:** Async workers that monitor file streams (e.g., `httpx.jsonl`, `katana.jsonl`).
*   **Queue Listeners:** Subscribers to message brokers (NATS/RabbitMQ) for real-time tool signal ingestion.
*   **Normalization Layer:** Transforms raw JSON into the `ArchitecturalEvidence` schema (defined in `07_machine_reasoning_api.md`).

### Graph Execution Engine (The Hexagon Core)
*   **Graph Model:** Multi-layered Directed Property Graph (DPG).
*   **Implementation:** In-memory graph processing using concurrent data structures (e.g., Go's `map` with mutexes or a specialized graph library like `Cayley`).
*   **Layering:**
    *   **L1 (Physical):** Hostnames, IPs, Ports, Protocols.
    *   **L2 (Identity):** IAM Roles, JWT Claims, Session Identifiers.
    *   **L3 (Mechanism):** Parsers, Trust Boundaries, Distributed Transactions.

### Orchestration Core (The Control Plane)
*   **PubSub Hub:** Internal event bus managing the flow between ingestion, inference, and scoring.
*   **State Machine:** Tracks the lifecycle of `ReasoningSessions`.
*   **Scheduler:** Prioritizes graph traversal tasks based on confidence deltas.

## 2. Memory & State Management
*   **Working Memory:** Ephemeral session-scoped graphs used for hypothesis testing.
*   **Persistence Layer:** Backed by an Event Store (storing all `RawSignal` events) and a Snapshot Store (storing versioned graph states).
*   **Concurrency:** Shared-nothing actor model for specialized inference agents.

## 3. Async Processing Model
1.  **Ingestion:** Tool signal -> Normalizer -> `SignalAdded` Event.
2.  **Fusion:** Graph Engine consumes `SignalAdded` -> Updates Nodes/Edges -> Emits `TopologyChanged`.
3.  **Inference:** Orchestration Hub detects `TopologyChanged` -> Tasks specialized agents (e.g., Identity Agent).
4.  **Feedback:** Agents return `ConfidenceAdjustment` -> Graph Engine updates weights.
