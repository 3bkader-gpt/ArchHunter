# 05 — Temporal Reasoning Stabilization

Tracking architecture over time requires deterministic replay and drift reconciliation to maintain a stable reasoning model.

## 1. Architecture Drift Stabilization
*   **Hysteresis Loops:** Infrastructure often flickers (e.g., dynamic scaling). The engine uses a "Hysteresis" threshold: a node must be absent from signals for multiple recon cycles before it is marked as "Removed."
*   **Consensus Anchors:** Use persistent infrastructure (e.g., DNS, static IPs) as "Anchors" to stabilize the relative positioning of dynamic nodes in the graph.

## 2. Replay Consistency
*   **Deterministic Event Sourcing:** Every `RawSignal` is assigned a monotonically increasing `LogSequenceNumber`.
*   **State Reconstruction:** Replaying the log from sequence $N$ to $N+M$ must produce an identical bit-for-bit graph state across all instances of the engine.

## 3. Temporal Graph Reconciliation
*   **Merge Heuristics:** When merging two temporal timelines (e.g., from two different operators), the system uses `Last-Writer-Wins` for metadata but `Max-Confidence` for architectural facts.
*   **Conflict Markers:** Conflicting timelines that cannot be auto-merged are flagged for manual operator reconciliation.

## 4. Timeline Compression
*   **Snapshot Compaction:** Periodic "Full Architecture Snapshots" are taken to prune old logs.
*   **Pruning Rules:** Ephemeral nodes that only existed for < 1 hour and had 0 hypotheses associated with them are deleted during compaction to save space.

## 5. Inference Persistence Guarantees
*   **Audit-Trail Snapshots:** Every `AttackHypothesis` is saved with a deep-link to the exact graph snapshot that generated it, ensuring that even if the architecture changes, the reasoning remains auditable.
