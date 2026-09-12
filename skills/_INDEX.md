# Bug Bounty STRIDE Index

This index maps the STRIDE threat modeling categories directly to the 44 curated mechanism manuals within the knowledge base.

## Spoofing (Authenticity)
*   [`auth_logic/saml_xsw_sso.md`](auth_logic/saml_xsw_sso.md) - Forging identity via SAML XML Signature Wrapping (XSW 1-8) and comment injection.
*   [`auth_logic/oauth_sso_integrity.md`](auth_logic/oauth_sso_integrity.md) - Forging identity via SSO collisions, Audience Confusion, and OAuth redirect flaws.
*   [`auth_logic/pre_account_takeover.md`](auth_logic/pre_account_takeover.md) - Pre-seeding unverified accounts & OAuth auto-link identity hijack.
*   [`infrastructure/subdomain_takeover.md`](infrastructure/subdomain_takeover.md) - Full domain & cookie hijacking via dangling cloud CNAME records (S3, Bitly, Azure).
*   [`infrastructure/broken_link_hijacking.md`](infrastructure/broken_link_hijacking.md) - Hijacking unclaimed social handles, developer GitHub usernames in docs, and external assets.
*   [`state_management/cross_subdomain_csrf.md`](state_management/cross_subdomain_csrf.md) - Forging requests from malicious subdomains via permissive cookies and cross-form CSRF token replay.
*   [`auth_logic/auth_bypass_ato.md`](auth_logic/auth_bypass_ato.md) - Spoofing identity via password resets, JWT architectural flaws, and OTP bypass.

## Tampering (Integrity)
*   [`auth_logic/logic_idor_auth.md`](auth_logic/logic_idor_auth.md) - Modifying other users' resources via the 40 ID-tamper mutations, destructive IDOR, and mass assignment.
*   [`state_management/business_logic_financial.md`](state_management/business_logic_financial.md) - Tampering with price, currency, cart inventory locks, and multi-step checkout desync.
*   [`infrastructure/webhook_integration_trust.md`](infrastructure/webhook_integration_trust.md) - Forging unverified webhook events and replaying payment/credit webhooks.
*   [`infrastructure/crlf_response_splitting.md`](infrastructure/crlf_response_splitting.md) - Forcing arbitrary HTTP response headers, cookie injection, and response body splitting.
*   [`infrastructure/cspt_client_side_path_traversal.md`](infrastructure/cspt_client_side_path_traversal.md) - Forcing client-side state mutations via path traversal in fetch/axios calls.
*   [`infrastructure/clickjacking_ui_redressing.md`](infrastructure/clickjacking_ui_redressing.md) - Forcing state-changing actions via transparent UI redressing overlays.
*   [`state_management/rate_limiting_evasion.md`](state_management/rate_limiting_evasion.md) - Tampering with resource counters via IP header spoofing and path mutations.
*   [`state_management/race_conditions.md`](state_management/race_conditions.md) - Tampering with state by exploiting async boundaries.
*   [`state_management/stateful_auth_desync.md`](state_management/stateful_auth_desync.md) - Tampering with multi-session environments and stateful protocols.
*   [`state_management/distributed_auth_propagation.md`](state_management/distributed_auth_propagation.md) - Tampering with global permission state and ReBAC graphs.
*   [`state_management/state_machine_integrity.md`](state_management/state_machine_integrity.md) - Tampering with protocol flow via state confusion.
*   [`state_management/async_workflow_integrity.md`](state_management/async_workflow_integrity.md) - Tampering with background job state, exploiting validation latency, and bypassing idempotency.
*   [`state_management/consistency_failures.md`](state_management/consistency_failures.md) - Tampering with state via replication lag, clock skew, and linearizability gaps.
*   [`state_management/distributed_transaction_abuse.md`](state_management/distributed_transaction_abuse.md) - Tampering with cross-service state via coordination failures and reservation exhaustion.
*   [`infrastructure/parser_implementation_integrity.md`](infrastructure/parser_implementation_integrity.md) - Tampering with structured data via arithmetic overflows, schema desync, and TLV pitfalls.
*   [`infrastructure/serialization_boundary_failures.md`](infrastructure/serialization_boundary_failures.md) - Tampering with object reconstruction to create malicious state and poisoning LWW metadata.
*   [`infrastructure/parser_differential_abuse.md`](infrastructure/parser_differential_abuse.md) - Tampering with proxy and backend parsing logic via smuggling and semantic transformation.
*   [`infrastructure/cryptographic_failures.md`](infrastructure/cryptographic_failures.md) - Tampering with cryptosystems via length extension and reflection.
*   [`infrastructure/sql_injection.md`](infrastructure/sql_injection.md) - Tampering with database queries via ORM or raw injection.
*   [`infrastructure/prototype_pollution.md`](infrastructure/prototype_pollution.md) - Tampering with global object prototypes to trigger DOM XSS and Node.js RCE gadgets.
*   [`infrastructure/server_side_template_injection.md`](infrastructure/server_side_template_injection.md) - Tampering with template expressions leading to sandbox escape and command execution.
*   [`infrastructure/file_upload_rce.md`](infrastructure/file_upload_rce.md) - Tampering with server storage via Zip Slip archive traversal, SVG injection, and polyglot web shells.
*   [`infrastructure/xss_variations.md`](infrastructure/xss_variations.md) - Client-side script injection, DOM clobbering, mutation XSS (mXSS), and CSP bypass techniques.
*   [`infrastructure/advanced_injection_rce.md`](infrastructure/advanced_injection_rce.md) - High-impact command injection, argument injection, and web shell execution leading to RCE.

## Repudiation (Non-repudiability)
*   [`state_management/cross_subdomain_csrf.md`](state_management/cross_subdomain_csrf.md) - Forcing non-attributable victim actions.
*   [`infrastructure/clickjacking_ui_redressing.md`](infrastructure/clickjacking_ui_redressing.md) - Non-attributable UI framed actions.

## Information Disclosure (Confidentiality)
*   [`infrastructure/nginx_server_edge_misconfigs.md`](infrastructure/nginx_server_edge_misconfigs.md) - Disclosing parent directory secrets via NGINX off-by-slash alias traversal (`/static../`).
*   [`infrastructure/graphql_attacks.md`](infrastructure/graphql_attacks.md) - Disclosing backend schema, hidden types, and sensitive data via Introspection and verbose errors.
*   [`infrastructure/cspt_client_side_path_traversal.md`](infrastructure/cspt_client_side_path_traversal.md) - Exfiltrating internal API data via frontend fetch traversal.
*   [`infrastructure/webhook_integration_trust.md`](infrastructure/webhook_integration_trust.md) - Disclosing cloud metadata and internal ports via blind Webhook SSRF.
*   [`state_management/cors_regex_bypass.md`](state_management/cors_regex_bypass.md) - Exfiltrating sensitive JSON data across origins.
*   [`emerging/llm_rag_privesc.md`](emerging/llm_rag_privesc.md) - Leaking cross-tenant data via AI chatbots.
*   [`infrastructure/origin_ip_discovery_waf_bypass.md`](infrastructure/origin_ip_discovery_waf_bypass.md) - Disclosing backend origin IP via Favicon Hash and TLS history.
*   [`infrastructure/backend_ssrf_rce.md`](infrastructure/backend_ssrf_rce.md) - Disclosing internal metadata and cloud keys via server-side requests.
*   [`infrastructure/infrastructure_misconfigurations.md`](infrastructure/infrastructure_misconfigurations.md) - Disclosing secrets via path traversal and exposed `.git`.
*   [`state_management/cache_attacks.md`](state_management/cache_attacks.md) - Disclosing sensitive PII via Web Cache Deception and static extension confusion (`.svg`).
*   [`infrastructure/xss_variations.md`](infrastructure/xss_variations.md) - Exfiltrating session cookies, localStorage tokens, DOM data, and CSRF nonces via injected JavaScript.

## Denial of Service (Availability)
*   [`state_management/rate_limiting_evasion.md`](state_management/rate_limiting_evasion.md) - Exhausting server resources and brute-forcing passwords/OTPs without rate limits.
*   [`state_management/business_logic_financial.md`](state_management/business_logic_financial.md) - Resource & Inventory lock via Cart Reservation DoS.
*   [`infrastructure/graphql_attacks.md`](infrastructure/graphql_attacks.md) - Deep recursive nested queries causing server thread and memory exhaustion.
*   [`state_management/cache_attacks.md`](state_management/cache_attacks.md) - Application-level DoS via Web Cache Poisoning.
*   [`infrastructure/parser_implementation_integrity.md`](infrastructure/parser_implementation_integrity.md) - Recursive exhaustion (e.g. Billion Laughs).

## Elevation of Privilege (Authorization)
*   [`auth_logic/saml_xsw_sso.md`](auth_logic/saml_xsw_sso.md) - Elevating to administrator via SAML signature wrapping.
*   [`auth_logic/pre_account_takeover.md`](auth_logic/pre_account_takeover.md) - Elevation via pre-registered account hijacking.
*   [`infrastructure/subdomain_takeover.md`](infrastructure/subdomain_takeover.md) - Escalating from dangling CNAME to wildcard cookie and session hijacking.
*   [`auth_logic/logic_idor_auth.md`](auth_logic/logic_idor_auth.md) - Elevating privileges by tampering with hidden role parameters and mass assignment.
*   [`infrastructure/clickjacking_ui_redressing.md`](infrastructure/clickjacking_ui_redressing.md) - Escalating privileges via 1-click administrative consent framing.
*   [`infrastructure/origin_ip_discovery_waf_bypass.md`](infrastructure/origin_ip_discovery_waf_bypass.md) - Bypassing WAF perimeter to execute direct uninspected backend attacks.
*   [`infrastructure/forbidden_403_bypass.md`](infrastructure/forbidden_403_bypass.md) - Bypassing HTTP 403 Forbidden & 401 Unauthorized access controls via URL rewriting, reverse proxy path normalization, and header spoofing.
*   [`auth_logic/iam_trust_boundaries.md`](auth_logic/iam_trust_boundaries.md) - Escalating privileges via AssumeRole chaining and PassRole service injection.
*   [`infrastructure/workload_identity_federation.md`](infrastructure/workload_identity_federation.md) - Escalating from workload/container contexts to cloud-native roles via OIDC and mTLS bypasses.
*   [`state_management/distributed_auth_propagation.md`](state_management/distributed_auth_propagation.md) - Escalating privileges through transitive graph-relationships and global consistency gaps.
*   [`state_management/websocket_state_abuse.md`](state_management/websocket_state_abuse.md) - Escalating privileges within an active stateful connection.
*   [`emerging/llm_rag_privesc.md`](emerging/llm_rag_privesc.md) - Using high-privilege backend AI agents for unauthorized actions, persistent context poisoning, and quota bypass.
*   [`infrastructure/server_side_template_injection.md`](infrastructure/server_side_template_injection.md) - Escalating from template injection to full remote system command execution.
*   [`infrastructure/file_upload_rce.md`](infrastructure/file_upload_rce.md) - Escalating from unvalidated file upload to web shell code execution.
*   [`infrastructure/advanced_injection_rce.md`](infrastructure/advanced_injection_rce.md) - Achieving operating system host compromise, container breakout, and remote root shell execution.
*   [`infrastructure/complex_chains_privesc.md`](infrastructure/complex_chains_privesc.md) - Vertical and horizontal privilege escalation through chained flaws.
*   [`infrastructure/serialization_boundary_failures.md`](infrastructure/serialization_boundary_failures.md) - Achieving RCE via object injection and gadget chains.

