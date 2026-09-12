# 04 — Identity Propagation Mapping

## Goal
Map how user and workload identities are passed, transformed, and trusted across the architecture.

## Propagation Inference Heuristics

### 1. The "Token Hand-off" Detection
*   **Signal:** An Edge gateway returns a JWT, but subsequently, the frontend sends a `SessionID` to a sub-API.
*   **Inference:** An **Identity Transformation** is happening. The backend is likely mapping JWT claims to an internal session store.
*   **Risk:** [Contextual Drift](../skills/auth_logic/oauth_sso_integrity.md).

### 2. Header-Based Identity Spoofing
*   **Signal:** Discovery of headers like `X-User-ID`, `X-Authenticated-User`, or `X-Forwarded-Client-Cert`.
*   **Inference:** The architecture uses **Internal Identity Headers** (The "Trusted Subsystem" pitfall).
*   **Risk:** If these headers can be injected via SSRF or Proxy Smuggling, full identity takeover is possible.

### 3. Workload Identity Translation (OIDC)
*   **Signal:** Presence of `.well-known/openid-configuration` with issuers like `kubernetes.default.svc.cluster.local`.
*   **Inference:** The system uses **Workload Identity Federation**. 
*   **Risk:** [OIDC Claim Spoofing](../skills/infrastructure/workload_identity_federation.md).

## Identity Flow Model

| Step | Interaction | Inferred Trust Assumption |
| :--- | :--- | :--- |
| **Step 1: Handshake** | Browser -> IdP | Assumes the IdP is the sole issuer of identity. |
| **Step 2: Propagation** | Edge Gateway -> Backend | Assumes the "Edge" has already performed all validation. |
| **Step 3: Persistence** | Backend -> Database | Assumes the database connection is "owned" by the user in the header. |

## Operational Output
An **Identity Graph** for the target, showing where tokens are exchanged for headers. This feeds the **Async & Distributed Inference**.
