# 04 — Trust Boundary Extraction

## Goal
Traverse the constructed graph to identify "Edges" where trust is delegated, translated, or temporal state diverges.

## Extraction Algorithms

### 1. Identity Translation Boundaries
*   **Pattern Match:** `[GatewayNode: JWT] -ROUTES_TO-> [ComputeNode: X-User-ID]`
*   **Inference:** The gateway validates the cryptographic token and translates it into an implicitly trusted internal header.
*   **Boundary Tag:** `BOUNDARY_IDENTITY_TRANSLATION`

### 2. Parser Differential Boundaries
*   **Pattern Match:** `[GatewayNode: HTTP/2] -ROUTES_TO-> [ComputeNode: HTTP/1.1]`
*   **Inference:** Protocol downgrade occurs across the edge, opening up parsing ambiguity.
*   **Boundary Tag:** `BOUNDARY_PARSER_DESYNC`

### 3. Temporal Trust Boundaries (Async)
*   **Pattern Match:** `[ComputeNode A] -ENQUEUES_TO-> [StateNode: Queue] -PROCESSES_FROM-> [ComputeNode B]`
*   **Inference:** A request is decoupled from its execution. Validation at Node A may decay before Node B acts.
*   **Boundary Tag:** `BOUNDARY_TEMPORAL_DRIFT`

### 4. Workload-to-Cloud Boundaries
*   **Pattern Match:** `[ComputeNode] -ASSUMES_ROLE-> [IdentityNode: Cloud IAM]`
*   **Inference:** A local container or service mesh identity is federated into a global cloud administration role.
*   **Boundary Tag:** `BOUNDARY_WORKLOAD_ESCALATION`
