# Bug Bounty Skill Taxonomy

This knowledge base is organized into four core operational categories, mapped directly to an attacker's progression through a modern application architecture.

## 1. Auth & Logic (`skills/auth_logic/`)
Focuses on the breakdown of identity, authorization boundaries, and business rules.
*   **`saml_xsw_sso.md`**: SAML XML Signature Wrapping (XSW 1-8), signature stripping, and comment injection in enterprise SSO.
*   **`logic_idor_auth.md`**: Insecure Direct Object References, the 40 ID-tamper mutation catalog, destructive IDOR, and mass assignment.
*   **`pre_account_takeover.md`**: Pre-seeding accounts, OAuth account linking race conditions, and unverified identity takeover.
*   **`oauth_sso_integrity.md`**: Flaws in OAuth implementation, Audience Confusion, tenant hopping, and validation gaps.
*   **`iam_trust_boundaries.md`**: Exploiting identity delegation (AssumeRole), permission handing (PassRole), and trust-policy confusion in cloud environments.
*   **`auth_bypass_ato.md`**: Account Takeover via password resets, email verification bypass, OTP validation, and profile modification.

## 2. State Management (`skills/state_management/`)
Focuses on the async nature of the web, connection states, and boundary conditions.
*   **`business_logic_financial.md`**: Exploiting price/currency tampering, cart inventory locks (DoS), rounding errors, and multi-step checkout desync.
*   **`rate_limiting_evasion.md`**: Exploiting missing or weak rate limits via IP header rotation, path/method mutations, and OTP/password spraying.
*   **`race_conditions.md`**: Exploiting Time-of-Check to Time-of-Use (TOCTOU) and async logic.
*   **`websocket_state_abuse.md`**: Bypassing per-message authorization over stateful connections.
*   **`cross_subdomain_csrf.md`**: Leveraging permissive cookie scoping and weak peripheral subdomains.
*   **`cors_regex_bypass.md`**: Exploiting weak CORS validation to exfiltrate data.
*   **`stateful_auth_desync.md`**: Exploiting state and permission desynchronization across concurrent sessions and stateful protocols.
*   **`distributed_auth_propagation.md`**: Exploiting global consistency gaps, ReBAC graph-edge escalation, and stale ACL replays.
*   **`state_machine_integrity.md`**: Exploiting unexpected transitions and implicit state residue in protocol state machines.
*   **`async_workflow_integrity.md`**: Exploiting temporal trust drift, idempotency failures, key erosion (TTL), and at-least-once processing gaps.
*   **`consistency_failures.md`**: Exploiting eventual consistency, replication lag, clock skew (LWW logic), distributed replay gaps, and linearizability failures.
*   **`distributed_transaction_abuse.md`**: Exploiting failures in cross-service coordination (2PC, Sagas, TCC) and distributed locking.
*   **`cache_attacks.md`**: Exploiting CDN/backend discrepancies for poisoning and deception.

## 3. Infrastructure (`skills/infrastructure/`)
Focuses on core architectural flaws, routing, and backend systems.
*   **`nginx_server_edge_misconfigs.md`**: Exploiting NGINX off-by-slash alias traversal (`/static../`), unencoded CRLF in `$uri`, and proxy path normalization splits.
*   **`crlf_response_splitting.md`**: Dedicated HTTP Response Splitting, arbitrary header/cookie injection, and web cache poisoning.
*   **`cspt_client_side_path_traversal.md`**: Exploiting unvalidated user input in frontend `fetch()`/`axios()` calls to navigate to restricted internal APIs and trigger client-side CSRF.
*   **`webhook_integration_trust.md`**: Exploiting unverified HMAC signatures, blind outbound SSRF via webhook registration, and event replay attacks.
*   **`subdomain_takeover.md`**: Exploiting dangling DNS CNAME records and orphaned third-party SaaS/Cloud hostings (AWS S3, Bitly, Azure, Heroku).
*   **`broken_link_hijacking.md`**: Exploiting expired/unclaimed social handles, developer GitHub usernames in documentation, and abandoned external assets.
*   **`origin_ip_discovery_waf_bypass.md`**: Uncovering direct backend server IPs via Favicon MurmurHash3, TLS certificate logs, and Host header injection to bypass WAFs.
*   **`forbidden_403_bypass.md`**: Bypassing HTTP 403 Forbidden & 401 Unauthorized access controls via reverse proxy URL rewrite headers, Tomcat/Spring matrix path normalizations, method overrides, and client IP spoofing.
*   **`clickjacking_ui_redressing.md`**: Exploiting missing frame protection headers to hijack 1-click administrative actions.
*   **`parser_implementation_integrity.md`**: Exploiting arithmetic overflows, TLV pitfalls, recursive exhaustion, and schema versioning desync.
*   **`serialization_boundary_failures.md`**: Exploiting object reconstruction, lifecycle hijacking, and LWW metadata poisoning in stream-to-object logic.
*   **`parser_differential_abuse.md`**: Bypassing filters and exploiting proxy/backend ambiguities via request smuggling, character expansion, and semantic desync.
*   **`workload_identity_federation.md`**: Exploiting OIDC claim mapping, service mesh mTLS bypasses, and workload-to-cloud escalation.
*   **`backend_ssrf_rce.md`**: Pivoting from the web layer to internal networks and cloud metadata.
*   **`advanced_injection_rce.md`**: High-impact injection flaws, argument injection, and web shell execution leading to RCE.
*   **`server_side_template_injection.md`**: Server-Side Template Injection (SSTI) across Jinja2, Twig, FreeMarker, Mako, sandbox escapes, and RCE.
*   **`file_upload_rce.md`**: Modern file upload exploitation, Zip Slip directory traversal, SVG XSS/SSRF, polyglots, and web server configuration overwrite.
*   **`complex_chains_privesc.md`**: Privilege escalation through chained architectural vulnerabilities.
*   **`sql_injection.md`**: Exploiting raw SQL queries and ORM abstraction flaws.
*   **`graphql_attacks.md`**: Exploiting GraphQL introspection leaks, field suggestion wordlists, array-based query batching (2FA bypass), and nested recursive DoS.
*   **`prototype_pollution.md`**: Client-side (CSPP) and server-side (SSPP) prototype mutations leading to DOM XSS, admin flag overrides, and Node.js RCE gadgets.
*   **`infrastructure_misconfigurations.md`**: Path traversal filter bypasses and secrets leakage.
*   **`xss_variations.md`**: Cross-Site Scripting variations and modern bypasses.
*   **`cryptographic_failures.md`**: Exploiting length extensions, downgrade attacks, and padding oracles.

## 4. Emerging (`skills/emerging/`)
Focuses on new paradigms, AI integrations, and non-traditional attack surfaces.
*   **`llm_rag_privesc.md`**: Exploiting the gap between user intent and backend agent permissions, and bypassing AI chat quotas.

## 5. Operational Mapping
*   **`OPERATIONAL_MAP.md`**: The root-level flat index for rapid mechanism-based pivoting during a hunt.
