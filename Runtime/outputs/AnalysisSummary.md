# Offensive Architectural Analysis Report

**Session:** session_default
**Timestamp:** 2026-10-01T14:59:42+03:00

## Summary

| Metric | Count |
|--------|-------|
| Nodes | 29 |
| Edges | 235 |
| Trust Boundaries | 203 |
| Hypotheses | 211 |
| 🔴 Tier 1 (High) | 8 |
| 🟡 Tier 2 (Medium) | 203 |
| ⬜ Tier 3 (Low) | 0 |

## Attack Hypotheses

### 1. [🔴 HIGH] H2 Gateway → H1.1 Backend Request Smuggling

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.90
- **Confidence:** 1.00
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** H2 gateway fronting H1.1 backend detected — classic CL/TE or TE/CL desync vector
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments https://ws.target.com/realtime https://admin.target.com/api/users https://s3.amazonaws.com/target-uploads/config.json https://api.target.com/v1/search https://api.target.com/v1/auth/login https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders https://api.target.com/v1/webhooks/callback https://cdn.target.com/assets/app.js https://api.target.com/v1/upload https://admin.target.com/dashboard https://staging.target.com https://api.target.com/v1/auth/oauth/authorize https://api.target.com/v1/account/reset-password https://api.target.com/v1/cors-test https://api.target.com/v1/export/pdf https://monitoring.target.com:9090/metrics https://grpc.target.com:50051/service.OrderService https://events.target.com/v1/track https://staging.target.com/api/v1/debug https://api.target.com/v1/auth/token https://target.com https://api.target.com/graphql]

### 2. [🔴 HIGH] Async Queue → Trust Drift RCE

- **Mechanism:** `ASYNC_TRUST_DECAY`
- **Risk Score:** 0.85
- **Confidence:** 1.00
- **Skill Reference:** `skills/state_management/async_workflow_integrity.md`
- **Rationale:** Async workflow detected with background processing — potential for validation bypass between request-time and worker execution
- **Affected Nodes:** [https://events.target.com/v1/track]

### 3. [🔴 HIGH] Multi-Server Parser Differential

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.70
- **Confidence:** 1.00
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Multiple different server types detected on same domain — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://api.target.com/v1/search https://api.target.com/v1/auth/login https://api.target.com/.well-known/openid-configuration https://api.target.com/v1/webhooks/callback https://cdn.target.com/assets/app.js https://api.target.com/v1/upload https://api.target.com/v1/auth/oauth/authorize https://api.target.com/v1/account/reset-password https://api.target.com/v1/cors-test https://api.target.com/v1/export/pdf https://grpc.target.com:50051/service.OrderService https://api.target.com/v1/auth/token https://target.com https://api.target.com/graphql]

### 4. [🔴 HIGH] Identity Context Leak to Untrusted Node

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.70
- **Confidence:** 1.00
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Identity tokens/cookies propagated across services without re-validation at trust boundaries
- **Affected Nodes:** [https://admin.target.com/api/users https://internal-api.target.com:8443/v2/orders]

### 5. [🔴 HIGH] GraphQL Complex Query → Authorization Bypass

- **Mechanism:** `ACCESS_CONTROL_BYPASS`
- **Risk Score:** 0.65
- **Confidence:** 1.00
- **Skill Reference:** `skills/auth_logic/logic_idor_auth.md`
- **Rationale:** GraphQL endpoint detected — potential for query depth abuse, batch attacks, and field-level authorization bypass
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments https://ws.target.com/realtime https://admin.target.com/api/users https://s3.amazonaws.com/target-uploads/config.json https://api.target.com/v1/search https://api.target.com/v1/auth/login https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders https://api.target.com/v1/webhooks/callback https://cdn.target.com/assets/app.js https://api.target.com/v1/upload https://admin.target.com/dashboard https://staging.target.com https://api.target.com/v1/auth/oauth/authorize https://api.target.com/v1/account/reset-password https://api.target.com/v1/cors-test https://api.target.com/v1/export/pdf https://monitoring.target.com:9090/metrics https://grpc.target.com:50051/service.OrderService https://events.target.com/v1/track https://staging.target.com/api/v1/debug https://api.target.com/v1/auth/token https://target.com https://api.target.com/graphql]

### 6. [🔴 HIGH] WebSocket/Stateful Connection Desync

- **Mechanism:** `STATE_DESYNC`
- **Risk Score:** 0.60
- **Confidence:** 1.00
- **Skill Reference:** `skills/state_management/websocket_state_abuse.md`
- **Rationale:** Long-lived stateful connection detected — potential for per-message authorization bypass after initial handshake
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments https://ws.target.com/realtime https://admin.target.com/api/users https://s3.amazonaws.com/target-uploads/config.json https://api.target.com/v1/search https://api.target.com/v1/auth/login https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders https://api.target.com/v1/webhooks/callback https://cdn.target.com/assets/app.js https://api.target.com/v1/upload https://admin.target.com/dashboard https://staging.target.com https://api.target.com/v1/auth/oauth/authorize https://api.target.com/v1/account/reset-password https://api.target.com/v1/cors-test https://api.target.com/v1/export/pdf https://monitoring.target.com:9090/metrics https://grpc.target.com:50051/service.OrderService https://events.target.com/v1/track https://staging.target.com/api/v1/debug https://api.target.com/v1/auth/token https://target.com https://api.target.com/graphql]

### 7. [🟡 Medium] Trust Boundary: Workload

- **Mechanism:** `CLOUD_IDENTITY_THEFT`
- **Risk Score:** 0.90
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/workload_identity_federation.md`
- **Rationale:** Workload Identity Bridge between application runtime and cloud control plane
- **Affected Nodes:** [https://s3.amazonaws.com/target-uploads/config.json]

### 8. [🔴 HIGH] Multi-Region JWT → Stale Revocation Window

- **Mechanism:** `CONSISTENCY_FAILURE`
- **Risk Score:** 0.62
- **Confidence:** 0.83
- **Skill Reference:** `skills/state_management/consistency_failures.md`
- **Rationale:** Multi-region architecture with JWT tokens — potential for stale token acceptance during replication lag
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments https://ws.target.com/realtime https://admin.target.com/api/users https://s3.amazonaws.com/target-uploads/config.json https://api.target.com/v1/search https://api.target.com/v1/auth/login https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders https://api.target.com/v1/webhooks/callback https://cdn.target.com/assets/app.js https://api.target.com/v1/upload https://admin.target.com/dashboard https://staging.target.com https://api.target.com/v1/auth/oauth/authorize https://api.target.com/v1/account/reset-password https://api.target.com/v1/cors-test https://api.target.com/v1/export/pdf https://monitoring.target.com:9090/metrics https://grpc.target.com:50051/service.OrderService https://events.target.com/v1/track https://staging.target.com/api/v1/debug https://api.target.com/v1/auth/token https://target.com https://api.target.com/graphql]

### 9. [🔴 HIGH] Internal Service → SSRF to Cloud Metadata

- **Mechanism:** `CLOUD_IDENTITY_THEFT`
- **Risk Score:** 0.58
- **Confidence:** 0.83
- **Skill Reference:** `skills/infrastructure/backend_ssrf_rce.md`
- **Rationale:** Internal service port exposed — potential for SSRF pivot to cloud metadata or internal APIs
- **Affected Nodes:** []

### 10. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/orders]

### 11. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://admin.target.com/dashboard]

### 12. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://staging.target.com]

### 13. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://ws.target.com/realtime]

### 14. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://events.target.com/v1/track]

### 15. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://grpc.target.com:50051/service.OrderService]

### 16. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://ws.target.com/realtime]

### 17. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com]

### 18. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://staging.target.com/api/v1/debug]

### 19. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://monitoring.target.com:9090/metrics]

### 20. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → envoy — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://grpc.target.com:50051/service.OrderService]

### 21. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://ws.target.com/realtime]

### 22. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://staging.target.com/api/v1/debug]

### 23. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://internal-api.target.com:8443/v2/payments]

### 24. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/api/users]

### 25. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://events.target.com/v1/track]

### 26. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/dashboard]

### 27. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/dashboard]

### 28. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://monitoring.target.com:9090/metrics]

### 29. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/api/users]

### 30. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://monitoring.target.com:9090/metrics]

### 31. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://staging.target.com]

### 32. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://target.com https://monitoring.target.com:9090/metrics]

### 33. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/orders]

### 34. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://admin.target.com/dashboard]

### 35. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://admin.target.com/dashboard]

### 36. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://grpc.target.com:50051/service.OrderService]

### 37. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://grpc.target.com:50051/service.OrderService]

### 38. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/orders]

### 39. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://monitoring.target.com:9090/metrics]

### 40. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://monitoring.target.com:9090/metrics]

### 41. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://staging.target.com/api/v1/debug]

### 42. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://grpc.target.com:50051/service.OrderService]

### 43. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://admin.target.com/dashboard]

### 44. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/payments]

### 45. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://ws.target.com/realtime]

### 46. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com]

### 47. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://staging.target.com/api/v1/debug]

### 48. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://ws.target.com/realtime]

### 49. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://admin.target.com/dashboard]

### 50. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/api/users]

### 51. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://staging.target.com/api/v1/debug]

### 52. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://ws.target.com/realtime]

### 53. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://events.target.com/v1/track]

### 54. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://internal-api.target.com:8443/v2/orders]

### 55. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/orders]

### 56. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://ws.target.com/realtime]

### 57. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → prometheus — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://monitoring.target.com:9090/metrics]

### 58. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://ws.target.com/realtime]

### 59. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://internal-api.target.com:8443/v2/orders]

### 60. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/orders]

### 61. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/api/users]

### 62. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://events.target.com/v1/track]

### 63. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/payments]

### 64. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://grpc.target.com:50051/service.OrderService]

### 65. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://staging.target.com/api/v1/debug]

### 66. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://staging.target.com]

### 67. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://admin.target.com/api/users]

### 68. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/api/users]

### 69. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/payments]

### 70. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://grpc.target.com:50051/service.OrderService]

### 71. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://admin.target.com/api/users]

### 72. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://monitoring.target.com:9090/metrics]

### 73. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://events.target.com/v1/track]

### 74. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://internal-api.target.com:8443/v2/payments]

### 75. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com]

### 76. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://internal-api.target.com:8443/v2/orders]

### 77. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://admin.target.com/api/users]

### 78. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://staging.target.com]

### 79. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://monitoring.target.com:9090/metrics]

### 80. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments]

### 81. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://staging.target.com]

### 82. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://monitoring.target.com:9090/metrics]

### 83. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://staging.target.com]

### 84. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://staging.target.com/api/v1/debug]

### 85. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://staging.target.com/api/v1/debug]

### 86. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://grpc.target.com:50051/service.OrderService]

### 87. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://grpc.target.com:50051/service.OrderService]

### 88. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/dashboard]

### 89. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com/api/v1/debug]

### 90. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://monitoring.target.com:9090/metrics]

### 91. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://ws.target.com/realtime]

### 92. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://monitoring.target.com:9090/metrics]

### 93. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://events.target.com/v1/track]

### 94. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://grpc.target.com:50051/service.OrderService]

### 95. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://grpc.target.com:50051/service.OrderService]

### 96. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://admin.target.com/api/users]

### 97. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com/api/v1/debug]

### 98. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://monitoring.target.com:9090/metrics]

### 99. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://grpc.target.com:50051/service.OrderService]

### 100. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://staging.target.com]

### 101. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://staging.target.com]

### 102. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://internal-api.target.com:8443/v2/orders]

### 103. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://internal-api.target.com:8443/v2/payments]

### 104. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://monitoring.target.com:9090/metrics]

### 105. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/payments]

### 106. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/dashboard]

### 107. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://internal-api.target.com:8443/v2/payments]

### 108. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://events.target.com/v1/track]

### 109. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://grpc.target.com:50051/service.OrderService]

### 110. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://admin.target.com/api/users]

### 111. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://ws.target.com/realtime]

### 112. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://events.target.com/v1/track]

### 113. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://events.target.com/v1/track]

### 114. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://internal-api.target.com:8443/v2/orders]

### 115. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/api/users]

### 116. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://internal-api.target.com:8443/v2/payments]

### 117. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://events.target.com/v1/track]

### 118. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://ws.target.com/realtime]

### 119. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://staging.target.com]

### 120. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://ws.target.com/realtime]

### 121. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/payments]

### 122. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://target.com https://grpc.target.com:50051/service.OrderService]

### 123. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders]

### 124. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments]

### 125. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://ws.target.com/realtime]

### 126. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://staging.target.com]

### 127. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/orders]

### 128. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://admin.target.com/dashboard]

### 129. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://events.target.com/v1/track]

### 130. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com/api/v1/debug]

### 131. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://admin.target.com/api/users]

### 132. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/api/users]

### 133. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/orders]

### 134. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://internal-api.target.com:8443/v2/payments]

### 135. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://staging.target.com/api/v1/debug]

### 136. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/payments]

### 137. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://events.target.com/v1/track]

### 138. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/dashboard]

### 139. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/dashboard]

### 140. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://admin.target.com/api/users]

### 141. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://staging.target.com/api/v1/debug]

### 142. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://internal-api.target.com:8443/v2/orders]

### 143. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://events.target.com/v1/track]

### 144. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://staging.target.com/api/v1/debug]

### 145. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://ws.target.com/realtime]

### 146. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/dashboard]

### 147. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://admin.target.com/dashboard]

### 148. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://events.target.com/v1/track]

### 149. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://staging.target.com]

### 150. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com]

### 151. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com]

### 152. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/orders]

### 153. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://ws.target.com/realtime]

### 154. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (prometheus)
- **Affected Nodes:** [https://api.target.com/graphql https://monitoring.target.com:9090/metrics]

### 155. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/orders]

### 156. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (apache/2.4)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com/api/v1/debug]

### 157. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/payments]

### 158. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/payments]

### 159. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://ws.target.com/realtime]

### 160. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://target.com https://staging.target.com]

### 161. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://ws.target.com/realtime]

### 162. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/payments]

### 163. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com/api/v1/debug]

### 164. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://events.target.com/v1/track]

### 165. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://admin.target.com/api/users]

### 166. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/orders]

### 167. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://events.target.com/v1/track]

### 168. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (envoy)
- **Affected Nodes:** [https://api.target.com/v1/users https://grpc.target.com:50051/service.OrderService]

### 169. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (prometheus)
- **Affected Nodes:** [https://target.com https://monitoring.target.com:9090/metrics]

### 170. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://events.target.com/v1/track]

### 171. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (prometheus)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://monitoring.target.com:9090/metrics]

### 172. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (apache/2.4)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com]

### 173. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (envoy)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://grpc.target.com:50051/service.OrderService]

### 174. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/dashboard]

### 175. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com/api/v1/debug]

### 176. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (prometheus)
- **Affected Nodes:** [https://api.target.com/v1/users https://monitoring.target.com:9090/metrics]

### 177. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/dashboard]

### 178. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (envoy)
- **Affected Nodes:** [https://target.com https://grpc.target.com:50051/service.OrderService]

### 179. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/api/users]

### 180. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/api/users]

### 181. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/api/users]

### 182. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://ws.target.com/realtime]

### 183. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (envoy)
- **Affected Nodes:** [https://api.target.com/graphql https://grpc.target.com:50051/service.OrderService]

### 184. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://target.com https://staging.target.com/api/v1/debug]

### 185. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://admin.target.com/dashboard]

### 186. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/orders]

### 187. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://events.target.com/v1/track]

### 188. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/dashboard]

### 189. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments]

### 190. [🟡 Medium] Trust Boundary: Async

- **Mechanism:** `ASYNC_TRUST_DECAY`
- **Risk Score:** 0.65
- **Confidence:** 0.60
- **Skill Reference:** `skills/state_management/async_workflow_integrity.md`
- **Rationale:** Temporal boundary — data moved from request-time to background worker
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://api.target.com/v1/webhooks/callback]

### 191. [🟡 Medium] Trust Boundary: Async

- **Mechanism:** `ASYNC_TRUST_DECAY`
- **Risk Score:** 0.65
- **Confidence:** 0.60
- **Skill Reference:** `skills/state_management/async_workflow_integrity.md`
- **Rationale:** Temporal boundary — data moved from request-time to background worker
- **Affected Nodes:** [https://events.target.com/v1/track https://api.target.com/v1/integrations/slack/webhook]

### 192. [🟡 Medium] Trust Boundary: Async

- **Mechanism:** `ASYNC_TRUST_DECAY`
- **Risk Score:** 0.65
- **Confidence:** 0.60
- **Skill Reference:** `skills/state_management/async_workflow_integrity.md`
- **Rationale:** Temporal boundary — data moved from request-time to background worker
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://api.target.com/v1/integrations/slack/webhook]

### 193. [🟡 Medium] Trust Boundary: Async

- **Mechanism:** `ASYNC_TRUST_DECAY`
- **Risk Score:** 0.65
- **Confidence:** 0.60
- **Skill Reference:** `skills/state_management/async_workflow_integrity.md`
- **Rationale:** Temporal boundary — data moved from request-time to background worker
- **Affected Nodes:** [https://events.target.com/v1/track https://api.target.com/v1/webhooks/callback]

### 194. [🟡 Medium] Trust Boundary: Async

- **Mechanism:** `ASYNC_TRUST_DECAY`
- **Risk Score:** 0.65
- **Confidence:** 0.60
- **Skill Reference:** `skills/state_management/async_workflow_integrity.md`
- **Rationale:** Temporal boundary — data moved from request-time to background worker
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://api.target.com/v1/integrations/slack/webhook]

### 195. [🟡 Medium] Trust Boundary: Async

- **Mechanism:** `ASYNC_TRUST_DECAY`
- **Risk Score:** 0.65
- **Confidence:** 0.60
- **Skill Reference:** `skills/state_management/async_workflow_integrity.md`
- **Rationale:** Temporal boundary — data moved from request-time to background worker
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://api.target.com/v1/webhooks/callback]

### 196. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/dashboard]

### 197. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/dashboard]

### 198. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments]

### 199. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/orders]

### 200. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/api/users]

### 201. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/payments]

### 202. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders]

### 203. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/dashboard]

### 204. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/orders]

### 205. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/payments]

### 206. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/payments]

### 207. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/orders]

### 208. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/api/users]

### 209. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/dashboard]

### 210. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/api/users]

### 211. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/api/users]

