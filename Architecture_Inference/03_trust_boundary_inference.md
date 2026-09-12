# 03 — Trust Boundary Inference

## Goal
Identify the "Edges" in the architecture where data changes hands, privileges change, or parsers execute.

## Boundary Inference Heuristics

### 1. The Gateway Edge (External-to-Internal)
*   **Signal:** High-performance proxy headers (e.g., `X-Cloud-Trace-Context`, `Via`).
*   **Inference:** A **Protocol Boundary** exists between the public internet and the internal VPC.
*   **Offensive Focus:** [Parser Differential Abuse](../skills/infrastructure/parser_differential_abuse.md).

### 2. The Identity Edge (Unauth-to-Auth)
*   **Signal:** Redirection to `/login` or 401/403 responses on sensitive paths.
*   **Inference:** A **Cryptographic Boundary** managed by an IdP.
*   **Offensive Focus:** [OAuth SSO Integrity](../skills/auth_logic/oauth_sso_integrity.md).

### 3. The Workload Edge (Container-to-Cloud)
*   **Signal:** Discovery of IMDS endpoints (`169.254.169.254`) or Kubernetes API server (`kubernetes.default`).
*   **Inference:** A **Workload Identity Bridge** exists between the application runtime and the cloud control plane.
*   **Offensive Focus:** [Workload Identity & Federated Trust](../skills/infrastructure/workload_identity_federation.md).

### 4. The Async Edge (Temporal Boundary)
*   **Signal:** Endpoints that return `202 Accepted` or presence of webhook callback parameters.
*   **Inference:** An **Async Workflow Boundary**. Data is moved to a background worker.
*   **Offensive Focus:** [Async Workflow Integrity](../skills/state_management/async_workflow_integrity.md).

## Trust Inference Matrix

| Boundary Type | Signal to Look For | Likely Mechanism Failure |
| :--- | :--- | :--- |
| **Logic Boundary** | Cross-subdomain CSRF or CORS. | [Context Confusion](../skills/auth_logic/oauth_sso_integrity.md) |
| **Parser Boundary** | Multipart/form-data or JSON with mixed types. | [Implementation Integrity](../skills/infrastructure/parser_implementation_integrity.md) |
| **State Boundary** | Websocket upgrade or gRPC streams. | [State Machine Integrity](../skills/state_management/state_machine_integrity.md) |

## Operational Output
A map of boundaries for each logical cluster. This feeds **Identity Propagation Mapping**.
