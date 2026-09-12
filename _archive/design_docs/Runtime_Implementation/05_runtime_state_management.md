# 05 — Runtime State Management

The Runtime State Management (RSM) ensures that the system's reasoning process is persistent, versioned, and replayable.

## 1. Architecture Snapshots
The RSM maintains a versioned history of the entire Data Flow Graph (DFG).

*   **Snapshoting:** Every significant inference event (e.g., trust boundary discovery) triggers a graph snapshot.
*   **Storage:** Snapshots are stored as JSON blobs or in a graph-specific snapshot store.
*   **Rollback:** Operators can "roll back" to a previous architectural state to test alternative hypotheses.

## 2. Recon Delta Tracking
Instead of re-processing entire tool outputs, the RSM tracks the "delta" between recon runs.

*   **Signal Deduplication:** Prevents redundant processing of the same evidence.
*   **Temporal Differencing:** Flags when a node disappears (e.g., an endpoint goes offline) or a new edge appears.

## 3. State Persistence (The Ledger)
The system uses an **Event-Sourced Architecture**.

*   **Reasoning Log:** A sequential record of all signals, inferences, and confidence adjustments.
*   **Recovery:** The current graph state can be reconstructed by replaying the Reasoning Log.
*   **Auditability:** Every Attack Hypothesis can be traced back to its root signals in the log.

## 4. Replayable Inference Sessions
A "Reasoning Session" is a discrete unit of architectural analysis.

*   **Input:** Initial seed URLs/IPs and a configuration profile.
*   **State:** The current graph, active hypotheses, and confidence scores.
*   **Replay:** A session can be exported and reloaded into another instance of the Physical Runtime Engine for collaborative analysis.

## 5. Metadata Registry
*   **Mechanism Lookup:** Stores the library of known architectural patterns and their associated inference rules.
*   **Operator Notes:** Allows human analysts to attach annotations directly to nodes and edges.
