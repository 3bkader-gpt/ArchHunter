# Strategic Ingestion Plan: Cloud & IAM Trust Reasoning

## 1. Executive Summary
The goal is to integrate Cloud-native identity and access management (IAM) principles into the **Architectural Reasoning Engine**. We will move beyond "Cloud Pentesting Checklists" to a first-principles model of **Identity Propagation**, **Workload Trust**, and **Cross-Account Authorization**. This ingestion will use AWS, Kubernetes, and Google Zanzibar as the primary sources for establishing the "ground truth" of modern, distributed trust boundaries.

## 2. High-Value Reasoning Domains (Offensive Primitives)
*   **Trust Boundary Mapping (IAM):**
    *   **AssumeRole/PassRole Logic:** Reasoning about the delegation of authority and the risks of "Permission Jumping."
    *   **Trust Policy Confusion:** Identifying where permissive `Principal` or `Condition` blocks allow unintended external access.
*   **Workload & Service Mesh Identity:**
    *   **Ephemeral Identity (SPIFFE/SVID):** Auditing the lifecycle and rotation of cryptographic identities for short-lived services.
    *   **Secure Naming & Policy Propagation (Istio):** Identifying desync between mesh-level authorization and the underlying workload state.
*   **Distributed Global Authorization (Zanzibar):**
    *   **External Consistency:** Reasoning about the gap between ACL updates and their global enforcement (New-content checks).
    *   **Relationship-Based Access (ReBAC):** Modeling transitive permission chains in complex object-graph systems.
*   **Metadata & Workload Impersonation:**
    *   **IMDS Exploitation (v1/v2):** Abstracting the "Metadata-to-Identity" bridge as a high-risk transition point.
    *   **OIDC/Federation Trust:** Identifying flaws in the mapping between external JWT claims and internal cloud roles.

## 3. Dangerous Ingestion Zones (High Noise Risk)
*   **CLI & Tooling Boilerplate:** Skip specific AWS/K8s CLI commands or setup tutorials.
*   **Manifest Samples:** Avoid ingesting large YAML blocks for RBAC or Istio configurations unless they represent a core reasoning failure.
*   **Compliance Checklists:** Exclude generic "Best Practices" or auditing framework filler.
*   **CloudGoat Setup Details:** Do not ingest the infrastructure code for labs; only distill the underlying **vulnerability logic** of the scenarios.

## 4. Taxonomy & Abstraction Strategy
*   **Integration:** Map Cloud/IAM concepts into the existing 4-pillar taxonomy:
    *   `auth_logic/iam_trust_boundaries.md`
    *   `state_management/distributed_auth_propagation.md`
    *   `infrastructure/workload_identity_failures.md`
*   **Abstraction Rule:** Use "Identity Context Decay" to describe how security metadata weakens as it passes through gateways, proxies, or event-driven workers.
*   **Bridge:** Connect "Transitive Trust Decay" (Methodology) to "Role Chaining" and "Cross-Account Trust."

## 5. Distributed Identity Strategy
*   **Workload Identity Federation:** Distill the reasoning for how a K8s Service Account translates into an AWS Role (The "OIDC Bridge").
*   **Consistency Gaps:** Apply DDIA-level consistency reasoning to global auth systems (Zanzibar "Zookies") to find windows for replaying revoked access.

## 6. Concepts to Exclude
*   Cloud service setup/management tutorials.
*   Terraform/HCL syntax details.
*   Vendor-specific cost or resource limit documentation.

## 7. Ingestion Roadmap
1.  **Phase 1 (IAM Primitives):** Expand Methodology with "Cloud Trust Boundary" logic and create the `iam_trust_boundaries.md` skill.
2.  **Phase 2 (Workload & Mesh):** Distill SPIFFE and Istio into the `workload_identity_failures.md` skill.
3.  **Phase 3 (Global Auth):** Distill Google Zanzibar logic into the `distributed_auth_propagation.md` skill.
4.  **Phase 4 (Cloud-Native Chains):** Update `complex_chains_privesc.md` with AssumeRole/PassRole and IMDS-to-Cloud escalation logic.

## 8. Readiness Assessment
*   **Maturity:** Critical (Cloud is the primary trust boundary for modern targets).
*   **Stability:** High (Core IAM logic is stable; service mesh identity is a maturing standard).
*   **Complexity:** High (Requires careful distillation to avoid becoming a "Cloud Tool" manual).

**VERDICT: PROCEED WITH TARGETED DISTILLATION. FOCUS ON IDENTITY PROPAGATION.**
