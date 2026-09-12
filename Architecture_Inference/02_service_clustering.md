# 02 — Service Clustering

## Goal
Group disparate subdomains and IP addresses into **Logical Architectural Clusters** (e.g., "The API Cluster", "The Admin Tier", "The Microservice Mesh").

## Clustering Heuristics

### 1. Header Correlation
*   **Indicator:** Multiple subdomains returning identical `X-Backend-Version` or `Server` headers.
*   **Inference:** These subdomains share a deployment pipeline or a common container image. They likely share the same **Parser Logic**.

### 2. TLS/Certificate Overlap
*   **Indicator:** Subdomains sharing a single wildcard certificate or possessing identical SAN (Subject Alternative Name) lists.
*   **Inference:** These assets belong to the same organizational unit and likely share an **Identity Domain**.

### 3. JARM / Fingerprint Similarity
*   **Indicator:** Identical JARM fingerprints across different ports or IPs.
*   **Inference:** These services use the same underlying TLS stack and likely the same infrastructure provider (e.g., same AWS ALB configuration).

### 4. Naming Convention Consistency
*   **Indicator:** `api-us-east.target.com`, `api-eu-west.target.com`.
*   **Inference:** Indicates **Multi-region Replicas**. This is a high-confidence signal for [Distributed Consistency Failures](../skills/state_management/consistency_failures.md).

## Cluster Classification

| Cluster Type | Operational Significance |
| :--- | :--- |
| **Monolith Tier** | Consistent headers/responses across many sub-paths. Single point of failure for logic. |
| **Aggregation Gateway** | Routing many sub-paths to different backends (e.g., GraphQL). High risk of **Context Loss**. |
| **Internal Utility Hub** | Low-traffic, non-standard ports (9200, 5000). Likely a **Trusted Subsystem** for the main app. |

## Operational Output
A list of clusters, each mapped to a set of subdomains. This feeds the next phase: **Trust Boundary Inference**.
