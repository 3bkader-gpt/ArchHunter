# 04 — Cross-Shard Query Optimization

In a distributed environment where the graph is sharded across multiple machines, query performance must be optimized to ensure real-time reasoning.

## 1. Trust-Boundary Locality Indexing
*   **Locality Strategy:** Attempt to keep all nodes within a single `Trust Zone` (e.g., a specific VPC or Kubernetes namespace) on the same database shard.
*   **Rationale:** Most identity propagation and parser chains happen *within* a trust zone. Minimizing cross-shard hops for these queries is critical.

## 2. Async Shard Traversal
*   **Parallel Execution:** A single architectural query (e.g., `TraceAllPathsToRoot`) is fanned out to all shards simultaneously.
*   **Intermediate Reduction:** Each shard performs local traversal and returns a partial path set, which the Query Coordinator merges into a final result.

## 3. Distributed Traversal Optimization
*   **Boundary Caching:** Cache the results of cross-shard edge lookups (e.g., Gateway in Shard 1 -> Backend in Shard 2).
*   **Edge Indexing:** Maintain a global "Inter-Shard Edge Registry" to quickly identify when a traversal needs to jump to a different physical machine.

## 4. Graph Cache Invalidation
*   **Bloom-Based Invalidation:** Use Bloom Filters to track which sub-graphs have changed, allowing the Query Engine to skip invalidating caches for static architectural segments.
*   **Versioned TTLs:** Caches are tagged with the `GraphVersionID` to prevent returning data from a stale architectural snapshot.

## 5. Fan-out Reduction
*   **Depth-First Pruning:** If a traversal in Shard 1 finds a path that already exceeds the max risk score or depth, it cancels its requests to other shards for that branch of the query.
