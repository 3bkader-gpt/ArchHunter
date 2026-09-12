# IAM Trust Boundaries & Identity Delegation

## Mechanism Overview
Cloud-native security relies on Identity and Access Management (IAM) to define trust. Unlike traditional network perimeters, IAM creates **Logical Trust Boundaries** where permissions are delegated, assumed, or inherited across services, accounts, and organizations.

## 1. Identity Delegation (The AssumeRole Pattern)
Identity delegation allows one principal (User, Service, Role) to temporarily adopt the permissions of another.

### **Role Chaining & Transitive Trust**
*   **Mechanism:** Principal A assumes Role B. Role B has permission to assume Role C.
*   **Failure:** The developer assumes that granting A permission to B is safe, forgetting that B provides a path to C.
*   **Offensive Pivot:** Map the "AssumeRole Graph." Identify roles that act as bridges to higher-privileged contexts.

### **Trust Policy Confusion (Confused Deputy)**
*   **Mechanism:** A `Trust Policy` (or `AssumeRolePolicyDocument`) defines *who* can assume a role.
*   **Failure:** A trust policy uses a wildcard `Principal: "*"` with weak or missing `Condition` blocks (e.g., missing `ExternalId`). This allows *any* AWS user to assume the role.
*   **Audit Goal:** Inspect Trust Policies for over-permissive principals. Target cross-account trust boundaries.

---

## 2. Permission Delegation (The PassRole Pattern)
`iam:PassRole` allows a user to "hand over" a role to a service (e.g., EC2, Lambda) so that the service can act on their behalf.

### **Role-to-Service Escalation**
*   **Mechanism:** A user creates a Lambda function and passes an "Admin" role to it.
*   **Failure:** The user only has "Lambda:CreateFunction" and "iam:PassRole", but they can effectively gain Admin rights by executing code inside the Lambda.
*   **Offensive Pivot:** Identify any service-creation permission (EC2, Lambda, ECS, Glue) paired with `iam:PassRole`.

---

## 3. Metadata-to-Identity Bridges
The transition from a resource (e.g., an EC2 instance) to its identity (e.g., an IAM Instance Profile).

### **IMDS Token Replay (v1 vs v2)**
*   **Mechanism:** The Instance Metadata Service (IMDS) provides temporary credentials to workloads.
*   **Failure:** IMDSv1 is vulnerable to SSRF (simple GET request). IMDSv2 requires a `PUT` token, but this can still be bypassed if the workload has a header-injection vulnerability or if the hop-limit allows container-to-host bypasses.
*   **Audit Goal:** Use SSRF to reach `http://169.254.169.254/latest/meta-data/iam/security-credentials/`.

---

## 4. Identity Context Decay
As an identity moves through transformation layers, security metadata is lost.

### **Session-Policy Desync**
*   **Mechanism:** When assuming a role, a `Session Policy` can further restrict permissions.
*   **Failure:** Downstream systems trust the "Role" but are unaware of the "Session Policy" restrictions applied at the handshake.
*   **Audit Goal:** Check if internal authorization engines re-evaluate the full session context or only the base role permissions.

---

## 5. IAM Audit Checklist
When auditing a cloud architecture, verify these delegation primitives:

1.  **Trust Direction:** Does Account A trust Account B, or vice-versa? Is the trust mutual or one-way?
2.  **Condition Strictness:** Do trust policies use `aws:PrincipalArn`, `aws:SourceVpc`, or `ExternalId` to narrow the boundary?
3.  **Role Chaining Depth:** How many "hops" are allowed? Is there a loop?
4.  **Credential Lifecycle:** Are temporary credentials (STS) scoped to the minimum required time and permissions?

## Recognition Patterns
*   **AWS:** Look for `arn:aws:iam::...` and `AssumeRole` calls.
*   **Kubernetes:** Target `ServiceAccount` to IAM Role mappings (OIDC).
*   **GCP:** Target `Service Account Impersonation` and `Workload Identity`.
