# 02 — Graph Visualization System

A machine-readable Data Flow Graph (DFG) is useless to an operator without an interface designed for human cognitive processing. This document defines the Human-Centric Graph Visualization layer.

## 1. Multi-Dimensional Rendering
Standard node-link diagrams become "hairballs" at scale. The UI must support layered architectural overlays.

*   **Trust-Boundary Visualization:** Emphasize boundaries using distinct colors/strokes (e.g., Red Dashed Line = Unvalidated Public Boundary, Green Solid = mTLS Internal).
*   **Parser-Chain Rendering:** Visual isolation of request transformation paths. Node shapes change based on parser types (e.g., Circle = Proxy, Hexagon = Backend API).
*   **Identity Propagation Maps:** A specific view mode that highlights only identity context nodes (JWTs, Session Cookies) and the edges where they transit or mutate.
*   **Distributed-State Overlays:** Highlights shared state backends (Redis, Kafka) and visualizes consistency models (e.g., pulsing edges for async eventual consistency).

## 2. Temporal Graph Diffing
Operators need to see what changed between recon runs.
*   **Visual Deltas:** Added nodes glow green, removed nodes fade to grey/red, and mutated edges show side-by-side property diffs.
*   **Timeline Slider:** A scrubbable timeline at the bottom of the UI allowing the operator to rewind the architectural state to a specific snapshot.

## 3. Operator-Centric Interaction
*   **Semantic Zooming:** Zooming out collapses microservices into aggregate `Trust Zones` or `VPCs`. Zooming in reveals specific parser configurations and headers.
*   **Hypothesis Focus Mode:** Clicking an `AttackHypothesis` dims all irrelevant nodes and strictly highlights the critical path required for the attack chain.
