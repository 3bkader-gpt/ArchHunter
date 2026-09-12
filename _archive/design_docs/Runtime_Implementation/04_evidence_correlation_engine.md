# 04 — Evidence Correlation Engine

The Evidence Correlation Engine (ECE) is the data-fusion layer. It takes unstructured tool signals and stitches them into a cohesive architectural story.

## 1. Multi-Signal Fusion
Disparate tools often see different facets of the same architecture. The ECE fuses these into a single `Node` or `Edge`.

*   **Host-to-Service Correlation:** Merging `httpx` (URL) with `nmap` (Port) and `katana` (Path) to define a `PhysicalNode`.
*   **Provider Correlation:** Linking AWS S3 bucket names (found in JS files) to a specific AWS account ID (found in headers).
*   **Infrastructure Stitching:** Correlating CloudFront headers with a hidden backend S3 origin based on response latency patterns.

## 2. Weighted Architectural Indicators
Not all signals are equal. The ECE uses a weighted system to prioritize evidence.

| Signal Type | Weight | Description |
| :--- | :--- | :--- |
| **Explicit Header** | 0.9 | `X-Served-By: Kubernetes` |
| **Error Fingerprint** | 0.8 | `Expected format: JSON` (Gives clue to parser) |
| **Timing Delta** | 0.6 | 100ms vs 10ms latency (Suggests proxy/WAF) |
| **URL Path Pattern** | 0.5 | `/api/v1/auth` (Suggests Auth Mechanism) |

## 3. Temporal Correlation
The ECE tracks how signals change over time.

*   **Drift Detection:** Flags when an architectural component changes (e.g., a proxy is added or a WAF is removed).
*   **Stateful Tracking:** Correlates a `Set-Cookie` header seen at T1 with an identity propagation event seen at T2.

## 4. Cross-Layer Evidence Stitching
The ECE bridges the gap between layers of the graph.

*   **Physical to Identity:** Linking an IP address to a specific JWT `sub` claim.
*   **Mechanism to Boundary:** Stitching a "GraphQL Parser" mechanism to an "Internal Service Boundary" edge.

## 5. Output: The Unified Evidence Object
The ECE emits a `FusedEvidence` JSON that serves as the input for the Graph Engine. This object includes the source signals, the correlation logic used, and the initial confidence weight.
