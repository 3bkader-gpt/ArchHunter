# 05 — Collaborative Reasoning Workflows

Architectural cognition in large-scale engagements requires multiple human operators augmenting the machine. The prototype must support distributed, collaborative modeling.

## 1. Multi-Operator State Sharing
*   **Live Synchronization:** Graph mutations (both machine-inferred and human-overridden) sync in real-time across all connected operator clients via WebSockets.
*   **Conflict-Free Replicated Data Types (CRDTs):** Used to resolve concurrent operator edits to graph metadata without locking the central database.

## 2. Replay Sessions
*   **Handoffs:** An operator finishing a shift can generate a "Reasoning Replay." The next operator watches a high-speed playback of how the graph evolved and which hypotheses were generated during the last 8 hours.

## 3. Reasoning Annotations
*   **Node/Edge Tagging:** Operators can attach rich Markdown notes, screenshots, or raw burp requests to specific components in the DFG.
*   **Hypothesis Pinning:** Operators can "Pin" a low-confidence machine hypothesis, preventing the Adaptive Feedback System from decaying it out of existence.

## 4. Evidence Attribution
*   **Provenance Chains:** Every node, edge, and property maintains an immutable list of `Evidence_IDs` and `Operator_IDs` that contributed to its current state.
*   **Auditability:** "Why does the machine think this is a GraphQL endpoint?" -> The UI traces it back to the exact `httpx` JSON payload or the specific operator who manually flagged it.

## 5. Distributed Cognition Workflows
*   **Swarm Investigation:** Operator A focuses on the `Identity Overlay` while Operator B focuses on the `Parser Overlay`. Their respective feedback is fused instantly by the Orchestration Core to generate new cross-domain attack paths.
