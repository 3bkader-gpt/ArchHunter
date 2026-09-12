# 02 — Signal Ingestion Pipeline

## Goal
Parse disjointed JSON outputs from various recon tools and normalize them into discrete `ArchitecturalSignal` objects.

## Data Sources & Extraction Logic

### 1. HTTPx (Protocol & Infrastructure Signals)
*   **Input:** `httpx -json`
*   **Extraction:** 
    *   `port` / `scheme`: Identifies transport (gRPC, HTTP/2, WS).
    *   `headers`: Maps `Via`, `X-Forwarded-For`, `Server`, `X-Powered-By`.
    *   `tls`: Maps JARM fingerprints, SANs, and Issuer metadata.
    *   `jarm`: Used to cluster identical backend deployments behind different IPs.

### 2. Katana (State & Async Signals)
*   **Input:** `katana -json`
*   **Extraction:**
    *   `endpoint`: Identifies API structure (`/graphql`, `/v1/`, `/webhook`).
    *   `params`: Maps state-changing endpoints (`?id=`, `?redirect=`).
    *   `method`: Identifies GraphQL mutations vs queries or REST state changes.

### 3. Arjun & x8 (Parameter Signals)
*   **Input:** `arjun` / `x8` output
*   **Extraction:**
    *   `params`: Maps hidden parameters (`?admin=`, `?debug=`, `?role=`).

## Normalization Schema
```json
{
  "signal_id": "sig_92jf29",
  "source_node": "api.target.com",
  "signal_category": "IDENTITY_PROVIDER",
  "confidence": 0.85,
  "raw_evidence": { "header": "x-amzn-oidc-data" }
}
```
