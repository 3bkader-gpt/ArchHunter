# 03 — Graph Construction Engine

## Goal
Build a Directed Labeled Graph representing the target's architecture.

## Node Types (Entities)
*   `GatewayNode`: Edge proxies, CDNs, WAFs (e.g., Cloudflare, ALB).
*   `ComputeNode`: Execution contexts (e.g., EC2, Lambda, EKS Pod).
*   `IdentityNode`: Issuers and Brokers (e.g., Auth0, Cognito, K8s ServiceAccount).
*   `StateNode`: Databases, Queues, Caches (e.g., Redis, Kafka, Postgres).

## Edge Types (Relationships)
Edges represent the flow of data and propagation of trust.
*   `ROUTES_TO`: Physical or proxy routing (Gateway -> Compute).
*   `AUTHENTICATES_VIA`: Identity dependency (Compute -> IdentityNode).
*   `ASSUMES_ROLE`: Cloud privilege escalation (Compute -> IdentityNode).
*   `ENQUEUES_TO`: Async transition (Compute -> StateNode).
*   `PROCESSES_FROM`: Async consumption (StateNode -> Compute).

## Synthesis Logic
1.  **Node Instantiation:** Create a node for every unique host/IP.
2.  **Attribute Decoration:** Attach normalized signals as properties to nodes (e.g., `has_grpc=true`).
3.  **Edge Inferencing:** 
    *   *If* Node A returns `X-Forwarded-For` and Node B shares the same JARM but an internal IP, *Create Edge* `ROUTES_TO` from A to B.
    *   *If* Node returns `.well-known/openid-configuration`, *Create Node* `IdentityNode` and connect.
