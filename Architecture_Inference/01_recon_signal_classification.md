# 01 — Recon Signal Classification

## Goal
Classify raw reconnaissance artifacts (headers, ports, TLS metadata, etc.) into high-level **Architectural Indicators**.

## Signal Classification Heuristics

| Raw Signal | Architectural Indicator | Reasoning |
| :--- | :--- | :--- |
| `Server: Cloudflare`, `X-Amz-Cf-Id` | **Edge Gateway (CDN)** | Indicates a multi-layer architecture with a caching and filtering edge. |
| `Content-Type: application/grpc` | **Binary RPC Interface** | Indicates a length-prefixed, highly structured parser boundary. |
| `Sec-WebSocket-Key` header | **Stateful Connection Hub** | Indicates long-lived TCP state and per-message authorization needs. |
| `X-Forwarded-For` header presence | **Proxy Layer** | Confirms an interpretation boundary between the public IP and internal backend. |
| `.well-known/openid-configuration` | **Identity Provider (IdP)** | Indicates a federation boundary and OIDC trust bridge. |
| `access-control-allow-origin: *` | **Permissive Cross-Domain Hub** | Indicates a weak browser-to-backend trust boundary. |
| Port `50051`, `9090` | **Internal Service Port** | Likely gRPC or Prometheus; indicates internal telemetry or service mesh edges. |
| `Retry-After` header | **Async Workflow Hint** | Suggests back-pressure and potential background job processing. |

## Confidence Scoring Model
*   **High Confidence (Level 3):** Explicit technology headers or unique protocol handshakes (e.g., gRPC, OIDC).
*   **Medium Confidence (Level 2):** Common port/header combinations (e.g., Port 8080 + `Server: Jetty`).
*   **Low Confidence (Level 1):** Generic status codes or generic server headers (e.g., `Server: nginx` on Port 443).

## Operational Translation
Transform `httpx -json` or other JSON-based recon tool findings into a signal list for the next phase: **Service Clustering**.
