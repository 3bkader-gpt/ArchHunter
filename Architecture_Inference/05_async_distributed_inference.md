# 05 — Async & Distributed Inference

## Goal
Identify the presence of message queues, distributed caches, and multi-region replicas to infer distributed consistency risks.

## Distributed Inference Heuristics

### 1. The "Replication Window" Detection
*   **Signal:** Latency differences between regional subdomains (e.g., `us-east` vs `eu-west`).
*   **Inference:** Indicates **Multi-region Replicas**.
*   **Risk:** [Stale Authorization Windows](../skills/state_management/consistency_failures.md).

### 2. Async Job Pipeline Identification
*   **Signal:** Endpoints that return `202 Accepted` or parameters like `job_id`, `task_uuid`.
*   **Inference:** Data is being processed by a **Background Worker pool**.
*   **Risk:** [Async Trust Drift](../skills/state_management/async_workflow_integrity.md).

### 3. Distributed Lock/Concurrency Clues
*   **Signal:** Repeated 429 (Rate Limit) responses across multiple subdomains.
*   **Inference:** Global shared state or distributed rate-limiting logic.
*   **Risk:** [Uniqueness Race Conditions](../skills/state_management/consistency_failures.md).

## Distributed State Indicators

| Signal | Inferred Infrastructure | Offensive Pivot |
| :--- | :--- | :--- |
| `Set-Cookie` with `Domain=.target.com` | Shared Session Store | [Cross-Subdomain CSRF](../skills/state_management/cross_subdomain_csrf.md) |
| `/callback` from unknown IPs | Webhook Worker pool | [Backend SSRF](../skills/infrastructure/backend_ssrf_rce.md) |
| JSON containing `timestamp_ns` | Logical/Vector clocks | [LWW State Poisoning](../skills/state_management/consistency_failures.md) |

## Operational Output
A list of **Distributed Interaction Points**. This feeds the **Parser Pipeline Mapping**.
