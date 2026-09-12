# Complex Chains & Privilege Escalation

## Mechanism Overview
Single vulnerabilities are often low-impact. Critical compromises occur when an attacker chains multiple "Informational" or "Medium" bugs to cross major trust boundaries.

## 1. High-Signal Chain Patterns

### Type A: Path Traversal -> Credential Theft -> Pivot
*   **Mechanism:** Gaining read access to local files (LFI/Traversal) to extract secrets (`.env`, `~/.aws/credentials`, `/etc/shadow`).
*   **Escalation:** Use the stolen keys to reach internal APIs or cloud consoles.

### Type B: Sandbox Escape -> Host Execution
*   **Mechanism:** Escaping a restricted environment (Docker, JS VM, Java Sandbox, eBPF) via kernel exploits or configuration injection.
*   **Escalation:** Moving from a single-tenant worker to host-level root access.

### Type C: Permission Model Bypass
*   **Mechanism:** Systematically breaking a language or framework's security boundary (e.g., Node.js 20 permission model) via module monkey-patching or path resolution overrides.
*   **Escalation:** Accessing restricted modules (e.g., `process`, `fs`) in a secure runtime.

### Type D: Feature Abuse -> Private Data Copy
*   **Mechanism:** Using legitimate features (Import/Export, Templates, Team Provisioning) to "Adopt" resources belonging to other users or organizations.
*   **Escalation:** Triggering a "Mass Copy" of private repositories or databases into an attacker-controlled workspace.

### Type E: Cloud Identity Pivoting (Cloud Primitive)
*   **Mechanism:** Using high-risk IAM permissions (`AssumeRole`, `PassRole`) to jump between execution contexts.
*   **Escalation:** Moving from a raw workload (EC2/Lambda) to a high-privilege Control-Plane principal via "Role Chaining" or "Service Injection."

## 2. Strategic Hunting Methodology

1.  **Identify the Boundary:** Map the "Edge" where you have control.
2.  **Locate the "Identity Provider":** Where is the source of truth for permissions?
3.  **Trace the Interaction Chain:** Follow the data from the edge to the deepest internal worker.
4.  **Target the Desync:** Find where one service trusts another but has a different view of the data's validity (Transitive Trust Decay).

## 3. Representative Escalation Logic

*   **Subdomain Takeover** -> Cookie Tossing -> CSRF -> Account Takeover.
*   **SSRF (IMDS)** -> Temporary Credentials -> AssumeRole Chaining -> Admin Console.
*   **Delegated Service Injection:** `Lambda:CreateFunction` + `iam:PassRole` -> Admin Role Execution -> Full Cloud Compromise.
*   **Workload Identity:** K8s Namespace Escape -> ServiceAccount Token -> OIDC Federation -> AWS IAM Admin.
*   **LFI** -> `/proc/self/environ` -> Secret Keys -> RCE.
*   **Prototype Pollution** -> SIEM Signal Feature -> Code Execution.

## 4. Operational Checklist
*   Does a "Read" bug allow access to "Write" credentials?
*   Can a "User" feature be used to initialize "Admin" resources?
*   Does a failure in a secondary system (e.g., Logging) leak primary system state?
*   Can you "smuggle" an identity header into an internal-only microservice?
