# 08 — Graph Storage and Querying

The prototype requires a storage layer capable of handling rapid structural mutations while supporting complex, temporal architectural queries.

## 1. Graph Persistence Models
*   **In-Memory Primary:** The hot graph lives in RAM (Go structs or specialized memory engine) for microsecond traversal speeds during live inference.
*   **Persistent Backing Store:** An underlying multi-model or native graph database (e.g., ArangoDB, Neo4j, or Cayley with BadgerDB) ensures durability and handles complex aggregations that exceed L1 memory.

## 2. Query Engines
*   **Gremlin / Cypher / AQL:** Support for standard graph query languages to allow operators to run bespoke architectural queries.
*   **Domain-Specific API:** A wrapped GraphQL or REST API specifically tuned for security architecture (e.g., `GetParserChain(entrypoint: "A", destination: "B")`).

## 3. Trust-Boundary Indexing
*   **Edge Indexing:** Special indexing strategies applied to edges marked as `TrustBoundary=true` or `CrossesNetwork=true`.
*   **Path Acceleration:** Pre-computing and caching the shortest paths between untrusted public entrypoints and high-value data nodes.

## 4. Temporal Graph Querying
*   **Time-Travel Queries:** The database model must support queries like, "Match nodes where `type=API_Gateway` AS OF `timestamp=X`."
*   **Snapshot Differencing Query:** Finding exactly which attack surface expanded between Monday and Wednesday.

## 5. Identity-Chain Search Optimization
*   **Recursive Queries:** Deep traversal of IAM assume-role chains or token exchange flows.
*   **Graph Reduction:** For search purposes, deeply nested microservice calls within the same trust zone are dynamically collapsed to speed up cross-boundary identity queries.
