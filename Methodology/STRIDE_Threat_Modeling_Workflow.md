# Advanced STRIDE Threat Modeling Workflow

## Operational Philosophy
Threat modeling is the translation of reconnaissance into exploitation intent. It is not a theoretical compliance exercise. It is the process of mapping an application's architecture, identifying implicit trust assumptions, and designing nightmare scenarios that break those assumptions. 

## Phase 1: Architectural Deconstruction & The Four-Question Framework
Before looking for vulnerabilities, map the application's architecture. Use the Four-Question framework:
1. What are they building? (Decomposition & DFDs)
2. How can we break it? (STRIDE-per-interaction)
3. How do we prove impact? (Exploitation & Nightmare Scenarios)
4. Did we break the core trust boundary? (Validation)

### 1. Component & Data Flow Mapping
*   **Identify the Core:** What is the primary function? (e.g., Grammar correction, financial ledger, file sharing).
*   **Map the Periphery:** Identify supporting microservices, CDNs, API gateways, and external integrations.
*   **Trace the Data:** How does data move from the client, through the APIs, to the database, and back? Apply the heuristic: *"Data cannot move itself"*. Every data movement implies a parser or process.

### 2. Trust Boundary Identification
Where does the server stop verifying and start trusting? Trust boundaries cluster threats.
*   **Execution Boundaries:** User-space to kernel-space, or unprivileged container to host.
*   **Parsing Boundaries:** Unstructured data to structured objects (Deserialization, XXE).
*   **Identity Boundaries:** Does the server trust the `user_id` provided in the JSON body, or does it derive it from the session token? Does the server assume that a valid OAuth token from the "mobile app" is authorized to access the "admin API"?
*   **Stateful Trust (WebSockets):** Does the application authenticate the initial handshake but fail to authorize subsequent frames?

### 3. STRIDE-per-Interaction Profiling
Do not attack components blindly; attack the interactions across trust boundaries.
*   **External Entities:** Spoofing and Repudiation. (Can we impersonate them?)
*   **Processes:** All STRIDE. (Can we crash the parser? Can we extract its memory?)
*   **Data Flows:** Tampering, Info Disclosure, DoS. (Is the transport integrity-checked?)
*   **Data Stores:** Tampering, Info Disclosure, Repudiation, DoS. (Are row-level permissions enforced?)

## Phase 2: Nightmare Scenario Generation
Work backward from the highest impact.

1.  **Define the Crown Jewels:** What is the most sensitive data or the most powerful action?
2.  **Construct the Nightmare:** "An attacker can force a victim to share their private financial documents without interaction."
3.  **Map to STRIDE:**
    *   **Spoofing:** Can we forge the victim's request? (CSRF via CORS failure).
    *   **Tampering:** Can we manipulate the share permissions? (IDOR on the share endpoint).
    *   **Elevation of Privilege:** Can we access a higher-tier function? (LLM RAG injection).

## Phase 3: Targeted Exploitation (The Attack Plan)
Translate the nightmare scenarios into specific, actionable test cases.

### 1. The IDOR Matrix
If the application relies on numeric IDs or predictable UUIDs:
*   Test *every* REST parameter.
*   Test *hidden* JSON parameters (e.g., adding `"role": "admin"` to a PUT request).
*   Test inconsistent authorization (e.g., View works, but does Export check ownership?).

### 2. The Auth-Context Matrix
If the application uses OAuth/SSO across multiple domains:
*   Test token replay across different tenants.
*   Test partial or truncated tokens.
*   Test validation of `aud` and `iss` claims.

### 3. The State Desync Matrix
If the application uses WebSockets or complex multi-step flows:
*   Test sending action frames without initialization frames.
*   Test race conditions on state-changing endpoints.

## Phase 4: The Recon-Exploit Loop
1.  **Test:** Execute the targeted plan.
2.  **Observe:** Did the server respond with a `403`, a `500`, or a `200`? Does the error message reveal internal state?
3.  **Refine:** Adjust the threat model based on the response. (e.g., "The server blocks standard IDOR, but what if I wrap the ID in an array?").
4.  **Iterate:** Continue testing until the trust boundary is broken.
