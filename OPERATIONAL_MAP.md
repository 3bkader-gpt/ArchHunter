# OPERATIONAL MAP (Rapid Pivot Index)

This map is the central tactical routing engine for offensive operations. It links the 4 operational phases, master playbooks, automation scripts, ready payloads, and all 44 atomic mechanism skills into a unified graph.

---

## 🧭 Master Playbooks & Tooling Hubs
*   **Tactical 4-Phase Playbook:** [OPERATIONAL PLAYBOOK](Methodology/OPERATIONAL_PLAYBOOK.md)
*   **Bug Bounty Toolkit & Chained Pipelines:** [BUG BOUNTY TOOLKIT PLAYBOOK](Methodology/BUG_BOUNTY_TOOLKIT_PLAYBOOK.md)
*   **Hands-on Burp Suite Hunting Guide:** [PRACTICAL BURP HUNTING GUIDE](Methodology/PRACTICAL_BURP_HUNTING_GUIDE.md)
*   **Tactical Scripts & Automation Catalog (21 Scripts):** [scripts/README.md](scripts/README.md)
*   **Ready-to-Use Payloads & Wordlists:** [payloads/README.md](payloads/README.md)
*   **Disclosed Intelligence & Technical Research:** [research/README.md](research/README.md)

---

## 🔄 Core Execution Flow
*   **Phase 1 — Reconnaissance:** [Workflow 01 (Target Selection)](Workflow/01_target_selection.md) → [Workflow 02 (Passive Recon)](Workflow/02_passive_recon.md) → [Workflow 03 (Active Mapping)](Workflow/03_active_mapping.md) | *Tools: [scripts/full_subdomain_recon.sh](scripts/README.md#1-full_subdomain_reconsh--ps1), [scripts/run_toolkit_recon.sh](scripts/README.md#2-run_toolkit_reconsh--ps1)*
*   **Phase 2 — Mapping & Architecture:** [Workflow 04 (Fingerprint to Architecture)](Workflow/04_fingerprint_to_architecture.md) → [Workflow 05 (Attack Surface Expansion)](Workflow/05_attack_surface_expansion.md) → [Inference Layer](Architecture_Inference/index.md) | *Tools: [scripts/discover_api_endpoints.sh](scripts/README.md#5-discover_api_endpointssh--ps1)*
*   **Phase 3 — Mechanism Auditing:** [Workflow 06 (Manual Validation)](Workflow/06_manual_validation.md) *(See mechanism pivots below)*
*   **Phase 4 — Exploitation & Impact:** [Workflow 07 (Chain Building)](Workflow/07_chain_building.md) → [Workflow 08 (Impact Modeling)](Workflow/08_impact_modeling.md) → [Workflow 09 (Reporting)](Workflow/09_reporting.md) | *Pivots: [Complex Chains & Privilege Escalation](skills/infrastructure/complex_chains_privesc.md)*

---

## 1. Identity & Access

### **Enterprise SSO & SAML**
*   **Trust Boundary:** XML Signature validation, IdP assertion consumptions.
*   **Pivots:** [SAML XSW & SSO](skills/auth_logic/saml_xsw_sso.md) | [OAuth & SSO Integrity](skills/auth_logic/oauth_sso_integrity.md)

### **OAuth / SSO / OIDC**
*   **Trust Boundary:** Token validation (`iss`, `aud`), redirect URI enforcement, state parameter integrity.
*   **Pivots:** [OAuth & SSO Integrity](skills/auth_logic/oauth_sso_integrity.md) | [Auth Bypass & ATO](skills/auth_logic/auth_bypass_ato.md) | [Pre-Account Takeover](skills/auth_logic/pre_account_takeover.md)

### **IAM & Role Delegation**
*   **Trust Boundary:** AssumeRole trust policies, PassRole service boundaries.
*   **Pivots:** [IAM Trust Boundaries](skills/auth_logic/iam_trust_boundaries.md)

### **Workload Identity (IMDS & OIDC)**
*   **Trust Boundary:** Metadata service to execution context, OIDC claim mapping.
*   **Pivots:** [Workload Identity & Federated Trust](skills/infrastructure/workload_identity_federation.md) | [Backend SSRF](skills/infrastructure/backend_ssrf_rce.md)

### **Global ACLs & ReBAC (Google Zanzibar)**
*   **Trust Boundary:** Object-graph relationship chains and external consistency tokens.
*   **Pivots:** [Distributed Auth Propagation](skills/state_management/distributed_auth_propagation.md) | [Distributed Consistency Failures](skills/state_management/consistency_failures.md)

### **Cryptographic Primitives & State Tokens**
*   **Trust Boundary:** Weak MACs, missing signatures, length extensions, and CBC padding oracles.
*   **Pivots:** [Cryptographic Failures](skills/infrastructure/cryptographic_failures.md)

---

## 2. State & Concurrency

### **Financial Logic & Cart Workflows**
*   **Trust Boundary:** Client-submitted prices/currencies vs Server product catalog; Inventory reservation locks.
*   **Pivots:** [Financial Business Logic & Integrity](skills/state_management/business_logic_financial.md) | [Race Conditions](skills/state_management/race_conditions.md)

### **Async Workflows & Queues**
*   **Trust Boundary:** Request-time validation vs. Background execution state.
*   **Pivots:** [Async Workflow Integrity](skills/state_management/async_workflow_integrity.md) | [Race Conditions](skills/state_management/race_conditions.md)

### **Single Page Applications (SPA) & UI Integrity**
*   **Trust Boundary:** Browser execution vs. backend API enforcement; Frame-ancestor embedding boundaries; Prototype tree mutations.
*   **Pivots:** [XSS Variations](skills/infrastructure/xss_variations.md) | [Prototype Pollution](skills/infrastructure/prototype_pollution.md) | [Clickjacking & UI Redressing](skills/infrastructure/clickjacking_ui_redressing.md) | [Client-Side Path Traversal (CSPT)](skills/infrastructure/cspt_client_side_path_traversal.md) | [IDOR & Logic Flaws](skills/auth_logic/logic_idor_auth.md) | [Cross-Subdomain CSRF](skills/state_management/cross_subdomain_csrf.md) | [CORS Regex Bypass](skills/state_management/cors_regex_bypass.md)

### **Rate Limiting & Abuse Prevention**
*   **Trust Boundary:** Reverse Proxy / Gateway counter vs. Real Client Identity (IP, Session, Account).
*   **Pivots:** [Rate Limiting Evasion & Brute-Force](skills/state_management/rate_limiting_evasion.md) | [Race Conditions](skills/state_management/race_conditions.md)

### **WebSockets & Real-Time Sync**
*   **Trust Boundary:** Per-message authorization vs. initial handshake authentication.
*   **Pivots:** [WebSocket State Abuse](skills/state_management/websocket_state_abuse.md) | [Stateful Auth Desync](skills/state_management/stateful_auth_desync.md) | [Protocol State Machine Integrity](skills/state_management/state_machine_integrity.md)

### **Distributed Consistency & Replicas**
*   **Trust Boundary:** Consistency Model (Leader vs. Follower) and Clock Skew.
*   **Pivots:** [Distributed Consistency Failures](skills/state_management/consistency_failures.md)

### **Distributed Transactions & Coordination**
*   **Trust Boundary:** Cross-service transaction boundaries and distributed locks.
*   **Pivots:** [Distributed Transaction Abuse](skills/state_management/distributed_transaction_abuse.md) | [Async Workflow Integrity](skills/state_management/async_workflow_integrity.md)

### **Data Transformation & Caching**
*   **Trust Boundary:** Visual shape (Input) vs. Functional shape (Sink).
*   **Pivots:** [Parser Differential Abuse](skills/infrastructure/parser_differential_abuse.md) | [Cache Attacks](skills/state_management/cache_attacks.md)

---

## 3. Infrastructure & Boundary Violations

### **Webhooks & Third-Party Integrations**
*   **Trust Boundary:** Outbound event registration vs. Inbound unverified event execution.
*   **Pivots:** [Webhook & Integration Trust](skills/infrastructure/webhook_integration_trust.md) | [Backend SSRF](skills/infrastructure/backend_ssrf_rce.md)

### **Edge & Reverse Proxy Routing (NGINX, Envoy, Apache)**
*   **Trust Boundary:** Gateway ACLs, URI normalization, header parsing splits.
*   **Pivots:** [403 Forbidden & 401 Unauthorized Bypass](skills/infrastructure/forbidden_403_bypass.md) | [NGINX & Server-Edge Routing Misconfigs](skills/infrastructure/nginx_server_edge_misconfigs.md) | [CRLF Response Splitting](skills/infrastructure/crlf_response_splitting.md) | [Parser Differential Abuse](skills/infrastructure/parser_differential_abuse.md) | *Tools: [scripts/test_403_bypasses.ps1](scripts/README.md#7-test_403_bypassesps1)*

### **DNS & Third-Party SaaS Assets**
*   **Trust Boundary:** Authoritative DNS CNAME pointers vs. Decommissioned cloud namespace availability; Unclaimed social/repo handles.
*   **Pivots:** [Subdomain Takeover](skills/infrastructure/subdomain_takeover.md) | [Broken Link Hijacking](skills/infrastructure/broken_link_hijacking.md) | [Infrastructure Misconfigurations](skills/infrastructure/infrastructure_misconfigurations.md) | *Tools: [scripts/check_subdomain_takeover.sh](scripts/README.md#3-check_subdomain_takeoversh--ps1), [scripts/find_broken_links.ps1](scripts/README.md#10-find_broken_linksps1)*

### **WAF & Perimeter Defense**
*   **Trust Boundary:** Cloud CDN / WAF inspection rules vs. Direct Origin IP listening sockets.
*   **Pivots:** [Origin IP Discovery & WAF Bypass](skills/infrastructure/origin_ip_discovery_waf_bypass.md) | *Tools: [scripts/find_origin_ip.sh](scripts/README.md#4-find_origin_ipsh--ps1)*

### **Structured Data, APIs & Background Parsers**
*   **Trust Boundary:** Raw bytes -> Structured Objects -> Execution context.
*   **Pivots:** [GraphQL Attacks](skills/infrastructure/graphql_attacks.md) | [Parser Implementation Integrity](skills/infrastructure/parser_implementation_integrity.md) | [Serialization Boundary Failures](skills/infrastructure/serialization_boundary_failures.md) | *Tools: [scripts/audit_graphql_endpoints.ps1](scripts/README.md#8-audit_graphql_endpointsps1)*

### **Databases, Templates & Code Execution**
*   **Trust Boundary:** User input string -> Interpreter / Compiler / Execution engine.
*   **Pivots:** [SQL Injection & ORM Abstraction](skills/infrastructure/sql_injection.md) | [Server-Side Template Injection (SSTI)](skills/infrastructure/server_side_template_injection.md) | [File Upload & Web Shell RCE](skills/infrastructure/file_upload_rce.md) | [Advanced Injection & RCE](skills/infrastructure/advanced_injection_rce.md)

---

## 4. Emerging Paradigms

### **AI / LLM Agents & RAG Pipelines**
*   **Trust Boundary:** User prompt -> LLM context -> Backend agent execution permissions; Quota / Rate-limit validation.
*   **Pivots:** [LLM RAG Privilege Escalation](skills/emerging/llm_rag_privesc.md)
