# Workload Identity & Federated Trust

## Mechanism Overview
Modern architectures replace static credentials with **Workload Identities** (e.g., SPIFFE SVIDs, Kubernetes ServiceAccounts). Trust is established via **OIDC Federation**, where a cloud provider (AWS/GCP) trusts an external identity provider (Kubernetes, GitHub) to issue short-lived tokens that can be exchanged for cloud roles.

## 1. OIDC Trust Bridging Failures
Vulnerabilities occur in the mapping between external JWT claims and internal cloud permissions.

### **The "Claim Spoofing" Pattern**
*   **Mechanism:** A cloud role trust policy allows a Kubernetes cluster to assume it. The policy checks the `sub` (subject) claim: `system:serviceaccount:default:my-app`.
*   **Failure:** The trust policy is too broad (e.g., uses a wildcard `system:serviceaccount:*`) or fails to validate the `aud` (Audience) or `iss` (Issuer). An attacker in a different namespace or cluster can assume the same role by naming their service account `my-app`.
*   **Offensive Pivot:** Identify OIDC trust policies with permissive conditions. Target "Multi-tenant" clusters where namespace isolation is the only boundary.

### **Federation Context Loss**
*   **Logic:** An identity is translated from "Internal Mesh Identity" to "External Cloud Identity."
*   **Failure:** During translation, original request context (e.g., source IP, original user ID) is discarded. The cloud provider only sees the "Workload Identity," not the user who triggered the action.
*   **Audit Goal:** Check if "Workload-to-Cloud" role assumption is triggered by untrusted user input.

---

## 2. Service Mesh & Sidecar Trust (Istio/SPIFFE)
Service meshes use mutual TLS (mTLS) to identify workloads. Trust is often delegated to a "Sidecar" proxy.

### **Sidecar-to-Workload Desync**
*   **Mechanism:** The Sidecar proxy (Envoy) handles authorization based on mTLS. The application code assumes that if a request reached it, it must be authorized.
*   **Failure:** If an attacker can bypass the sidecar (e.g., via a vulnerability in the host network or a container escape), they can send raw requests directly to the application's port, bypassing mesh-level `AuthorizationPolicies`.
*   **Audit Goal:** Identify service ports that are exposed on `0.0.0.0` rather than `127.0.0.1` inside a mesh.

---

## 3. Ephemeral Identity Replay
Workload identities are short-lived, but the sessions they create may persist.

### **Token Persistence Gap**
*   **Mechanism:** A workload uses a short-lived SPIFFE/SVID token to establish a connection.
*   **Failure:** The token expires, but the **TCP connection or Session** remains active and privileged.
*   **Offensive Pivot:** Establish a long-lived gRPC or WebSocket stream using a temporary workload identity. Test if the connection is revoked when the identity expires.

---

## 4. Workload-to-Cloud Escalation Logic
*   **Namespace Escape** -> **ServiceAccount Token Theft** -> **Assume Cloud Role**.
*   **OIDC Claim Manipulation** -> **Assume Cross-Account Admin Role**.
*   **Mesh Policy Drift** -> **Unauthorized Service-to-Service Request**.

## 5. Workload Identity Audit Checklist
When auditing a containerized or mesh-driven architecture, verify these primitives:

1.  **Claim Specificity:** Are OIDC trust policies restricted to specific namespaces and service account names?
2.  **Issuer Validation:** Does the cloud provider verify the OIDC provider's cryptographic signature?
3.  **Bypass Surface:** Can the workload be reached directly, skipping the mesh proxy?
4.  **Credential Scope:** Are SVIDs/Tokens scoped to specific "Audiences" to prevent replay across different services?

## Recognition Patterns
*   **JWT Claims:** Look for `sub: system:serviceaccount:...` or `repository: owner/repo`.
*   **Trust Policies:** Look for `Action: sts:AssumeRoleWithWebIdentity`.
*   **Mesh Headers:** Look for `X-Forwarded-Client-Cert` or `istio-attributes`.
