# 10 — Final Pre-Coding Architecture

This document presents the unified system architecture and subsystem dependency map, serving as the master blueprint for the implementation phase.

## 1. Unified Subsystem Dependency Map
The system is built from the bottom up:
1.  **Level 0 (Storage):** Event Ledger (BadgerDB) + Graph Store.
2.  **Level 1 (Ingestion):** Tailers -> Normalizers -> Event Bus (NATS).
3.  **Level 2 (Topology):** Graph Engine (Go) consumes from NATS -> Maintains multi-layer DFG.
4.  **Level 3 (Reasoning):** Multi-Agent Cluster (Python) queries Level 2 via gRPC -> Issues Confidence Updates.
5.  **Level 4 (Presentation):** Collaborative UI (React/WebGL) -> Syncs via WebSockets.

## 2. Event Flow Topology
1.  **Signal Arrival:** `ToolSignal` -> `Normalizer` -> `RawEvidence` (Published to Bus).
2.  **Fusion:** `GraphEngine` (Subscribed) -> `UpdateTopology` -> `TopologyChanged` (Published to Bus).
3.  **Inference:** `InferenceAgents` (Subscribed) -> `RunHeuristics` -> `ConfidenceUpdate` (Sent to Core).
4.  **Scoring:** `Orchestrator` -> `RankHypotheses` -> `HypothesisList` (Pushed to UI).
5.  **Feedback:** `OperatorUI` -> `ManualOverride` -> `ConfidenceUpdate` (High Weight).

## 3. Runtime Lifecycle Model
*   **Initialization:** Load existing snapshots from Level 0.
*   **Streaming:** Continuous processing of new tool output.
*   **Convergence:** Agents reach a stable confidence state for the current signal density.
*   **Hibernation:** Periodic snapshotting and resource scale-down if no new signals arrive.

## 4. Implementation Sequencing
1.  **Internal (Go):** Subsystem L0 and L1.
2.  **Logic (Go/Python):** L2 Core and the gRPC bridge.
3.  **Cognition (Python):** L3 Agent framework and the Trust Boundary Agent.
4.  **External (React):** L4 Basic Dashboard.
5.  **Hardening:** L2/L3 Confidence Calibration and Suppression loops.
