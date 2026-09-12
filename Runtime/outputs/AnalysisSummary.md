# Offensive Architectural Analysis Report

**Session:** session_default
**Timestamp:** 2026-08-25T15:12:55+03:00

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
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://api.target.com/v1/webhooks/callback https://api.target.com/v1/auth/token https://api.target.com/.well-known/openid-configuration https://api.target.com/v1/export/pdf https://s3.amazonaws.com/target-uploads/config.json https://staging.target.com/api/v1/debug https://events.target.com/v1/track https://api.target.com/v1/upload https://api.target.com/v1/account/reset-password https://api.target.com/v1/users https://target.com https://cdn.target.com/assets/app.js https://api.target.com/v1/cors-test https://admin.target.com/dashboard https://monitoring.target.com:9090/metrics https://internal-api.target.com:8443/v2/orders https://ws.target.com/realtime https://admin.target.com/api/users https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments https://grpc.target.com:50051/service.OrderService https://api.target.com/graphql https://staging.target.com https://api.target.com/v1/search]

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
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://api.target.com/v1/webhooks/callback https://api.target.com/v1/auth/token https://api.target.com/.well-known/openid-configuration https://api.target.com/v1/export/pdf https://api.target.com/v1/upload https://api.target.com/v1/account/reset-password https://api.target.com/v1/users https://target.com https://cdn.target.com/assets/app.js https://api.target.com/v1/cors-test https://api.target.com/v1/auth/oauth/authorize https://grpc.target.com:50051/service.OrderService https://api.target.com/graphql https://api.target.com/v1/search]

### 4. [🔴 HIGH] Identity Context Leak to Untrusted Node

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.70
- **Confidence:** 1.00
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Identity tokens/cookies propagated across services without re-validation at trust boundaries
- **Affected Nodes:** [https://internal-api.target.com:8443/v2/orders https://admin.target.com/api/users]

### 5. [🔴 HIGH] GraphQL Complex Query → Authorization Bypass

- **Mechanism:** `ACCESS_CONTROL_BYPASS`
- **Risk Score:** 0.65
- **Confidence:** 1.00
- **Skill Reference:** `skills/auth_logic/logic_idor_auth.md`
- **Rationale:** GraphQL endpoint detected — potential for query depth abuse, batch attacks, and field-level authorization bypass
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://api.target.com/v1/webhooks/callback https://api.target.com/v1/auth/token https://api.target.com/.well-known/openid-configuration https://api.target.com/v1/export/pdf https://s3.amazonaws.com/target-uploads/config.json https://staging.target.com/api/v1/debug https://events.target.com/v1/track https://api.target.com/v1/upload https://api.target.com/v1/account/reset-password https://api.target.com/v1/users https://target.com https://cdn.target.com/assets/app.js https://api.target.com/v1/cors-test https://admin.target.com/dashboard https://monitoring.target.com:9090/metrics https://internal-api.target.com:8443/v2/orders https://ws.target.com/realtime https://admin.target.com/api/users https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments https://grpc.target.com:50051/service.OrderService https://api.target.com/graphql https://staging.target.com https://api.target.com/v1/search]

### 6. [🔴 HIGH] WebSocket/Stateful Connection Desync

- **Mechanism:** `STATE_DESYNC`
- **Risk Score:** 0.60
- **Confidence:** 1.00
- **Skill Reference:** `skills/state_management/websocket_state_abuse.md`
- **Rationale:** Long-lived stateful connection detected — potential for per-message authorization bypass after initial handshake
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://api.target.com/v1/webhooks/callback https://api.target.com/v1/auth/token https://api.target.com/.well-known/openid-configuration https://api.target.com/v1/export/pdf https://s3.amazonaws.com/target-uploads/config.json https://staging.target.com/api/v1/debug https://events.target.com/v1/track https://api.target.com/v1/upload https://api.target.com/v1/account/reset-password https://api.target.com/v1/users https://target.com https://cdn.target.com/assets/app.js https://api.target.com/v1/cors-test https://admin.target.com/dashboard https://monitoring.target.com:9090/metrics https://internal-api.target.com:8443/v2/orders https://ws.target.com/realtime https://admin.target.com/api/users https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments https://grpc.target.com:50051/service.OrderService https://api.target.com/graphql https://staging.target.com https://api.target.com/v1/search]

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
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://api.target.com/v1/webhooks/callback https://api.target.com/v1/auth/token https://api.target.com/.well-known/openid-configuration https://api.target.com/v1/export/pdf https://s3.amazonaws.com/target-uploads/config.json https://staging.target.com/api/v1/debug https://events.target.com/v1/track https://api.target.com/v1/upload https://api.target.com/v1/account/reset-password https://api.target.com/v1/users https://target.com https://cdn.target.com/assets/app.js https://api.target.com/v1/cors-test https://admin.target.com/dashboard https://monitoring.target.com:9090/metrics https://internal-api.target.com:8443/v2/orders https://ws.target.com/realtime https://admin.target.com/api/users https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments https://grpc.target.com:50051/service.OrderService https://api.target.com/graphql https://staging.target.com https://api.target.com/v1/search]

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
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://admin.target.com/api/users]

### 11. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/dashboard]

### 12. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://internal-api.target.com:8443/v2/orders]

### 13. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://internal-api.target.com:8443/v2/orders]

### 14. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/payments]

### 15. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://ws.target.com/realtime]

### 16. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/dashboard]

### 17. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://admin.target.com/api/users]

### 18. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://admin.target.com/dashboard]

### 19. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://staging.target.com]

### 20. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/dashboard]

### 21. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/dashboard]

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
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://staging.target.com/api/v1/debug]

### 24. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://internal-api.target.com:8443/v2/payments]

### 25. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/api/users]

### 26. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://ws.target.com/realtime]

### 27. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://grpc.target.com:50051/service.OrderService]

### 28. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://admin.target.com/dashboard]

### 29. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://ws.target.com/realtime]

### 30. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://staging.target.com]

### 31. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/payments]

### 32. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://internal-api.target.com:8443/v2/payments]

### 33. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/api/users]

### 34. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://staging.target.com]

### 35. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://staging.target.com/api/v1/debug]

### 36. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/dashboard]

### 37. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://target.com https://monitoring.target.com:9090/metrics]

### 38. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://grpc.target.com:50051/service.OrderService]

### 39. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://grpc.target.com:50051/service.OrderService]

### 40. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://staging.target.com/api/v1/debug]

### 41. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://ws.target.com/realtime]

### 42. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://internal-api.target.com:8443/v2/orders]

### 43. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://grpc.target.com:50051/service.OrderService]

### 44. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://admin.target.com/api/users]

### 45. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://staging.target.com]

### 46. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://staging.target.com]

### 47. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://grpc.target.com:50051/service.OrderService]

### 48. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://internal-api.target.com:8443/v2/orders]

### 49. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://grpc.target.com:50051/service.OrderService]

### 50. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments]

### 51. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/dashboard]

### 52. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com]

### 53. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://staging.target.com/api/v1/debug]

### 54. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://monitoring.target.com:9090/metrics]

### 55. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://monitoring.target.com:9090/metrics]

### 56. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://staging.target.com/api/v1/debug]

### 57. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/api/users]

### 58. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://grpc.target.com:50051/service.OrderService]

### 59. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/dashboard]

### 60. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments]

### 61. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://admin.target.com/api/users]

### 62. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://staging.target.com]

### 63. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://admin.target.com/dashboard]

### 64. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://internal-api.target.com:8443/v2/payments]

### 65. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://monitoring.target.com:9090/metrics]

### 66. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://monitoring.target.com:9090/metrics]

### 67. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://grpc.target.com:50051/service.OrderService]

### 68. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://staging.target.com/api/v1/debug]

### 69. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/payments]

### 70. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/orders]

### 71. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://ws.target.com/realtime]

### 72. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com/api/v1/debug]

### 73. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://events.target.com/v1/track]

### 74. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://ws.target.com/realtime]

### 75. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/orders]

### 76. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://staging.target.com/api/v1/debug]

### 77. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/api/users]

### 78. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://ws.target.com/realtime]

### 79. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/users https://events.target.com/v1/track]

### 80. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://grpc.target.com:50051/service.OrderService]

### 81. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://monitoring.target.com:9090/metrics]

### 82. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://internal-api.target.com:8443/v2/orders]

### 83. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://staging.target.com]

### 84. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://events.target.com/v1/track]

### 85. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://internal-api.target.com:8443/v2/payments]

### 86. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://ws.target.com/realtime]

### 87. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://events.target.com/v1/track]

### 88. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/payments]

### 89. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com/api/v1/debug]

### 90. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com]

### 91. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://ws.target.com/realtime]

### 92. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/api/users]

### 93. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://grpc.target.com:50051/service.OrderService]

### 94. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/orders]

### 95. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/api/users]

### 96. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://staging.target.com/api/v1/debug]

### 97. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/payments]

### 98. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://events.target.com/v1/track]

### 99. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://events.target.com/v1/track]

### 100. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://ws.target.com/realtime]

### 101. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://admin.target.com/dashboard]

### 102. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://target.com https://grpc.target.com:50051/service.OrderService]

### 103. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://staging.target.com]

### 104. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → prometheus — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://monitoring.target.com:9090/metrics]

### 105. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://events.target.com/v1/track]

### 106. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://ws.target.com/realtime]

### 107. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://events.target.com/v1/track]

### 108. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://monitoring.target.com:9090/metrics]

### 109. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://admin.target.com/dashboard]

### 110. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com]

### 111. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://grpc.target.com:50051/service.OrderService]

### 112. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://staging.target.com]

### 113. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://monitoring.target.com:9090/metrics]

### 114. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://staging.target.com]

### 115. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://admin.target.com/dashboard]

### 116. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://monitoring.target.com:9090/metrics]

### 117. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://internal-api.target.com:8443/v2/payments]

### 118. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://monitoring.target.com:9090/metrics]

### 119. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://events.target.com/v1/track]

### 120. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://admin.target.com/api/users]

### 121. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://events.target.com/v1/track]

### 122. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/orders]

### 123. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/orders]

### 124. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://ws.target.com/realtime]

### 125. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/account/reset-password https://ws.target.com/realtime]

### 126. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/orders]

### 127. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://admin.target.com/api/users]

### 128. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://events.target.com/v1/track]

### 129. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/search https://events.target.com/v1/track]

### 130. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/payments]

### 131. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://ws.target.com/realtime]

### 132. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/api/users]

### 133. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://events.target.com/v1/track]

### 134. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://monitoring.target.com:9090/metrics]

### 135. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://staging.target.com]

### 136. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders]

### 137. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://staging.target.com/api/v1/debug]

### 138. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://monitoring.target.com:9090/metrics]

### 139. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudfront → envoy — potential interpretation desync
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://grpc.target.com:50051/service.OrderService]

### 140. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/orders]

### 141. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://admin.target.com/dashboard]

### 142. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com/api/v1/debug]

### 143. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://events.target.com/v1/track]

### 144. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://admin.target.com/api/users]

### 145. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/cors-test https://internal-api.target.com:8443/v2/orders]

### 146. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → nginx/1.21 — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/upload https://internal-api.target.com:8443/v2/payments]

### 147. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → apache/2.4 — potential interpretation desync
- **Affected Nodes:** [https://target.com https://staging.target.com/api/v1/debug]

### 148. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → prometheus — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/webhooks/callback https://monitoring.target.com:9090/metrics]

### 149. [🟡 Medium] Trust Boundary: Parser

- **Mechanism:** `PARSER_DIFFERENTIAL`
- **Risk Score:** 0.75
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Parser transition: cloudflare → envoy — potential interpretation desync
- **Affected Nodes:** [https://api.target.com/v1/export/pdf https://grpc.target.com:50051/service.OrderService]

### 150. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com/api/v1/debug]

### 151. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://events.target.com/v1/track]

### 152. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (envoy)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://grpc.target.com:50051/service.OrderService]

### 153. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com/api/v1/debug]

### 154. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (prometheus)
- **Affected Nodes:** [https://api.target.com/v1/users https://monitoring.target.com:9090/metrics]

### 155. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://ws.target.com/realtime]

### 156. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (prometheus)
- **Affected Nodes:** [https://target.com https://monitoring.target.com:9090/metrics]

### 157. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://target.com https://staging.target.com/api/v1/debug]

### 158. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/orders]

### 159. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/dashboard]

### 160. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/orders]

### 161. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/payments]

### 162. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/orders]

### 163. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (envoy)
- **Affected Nodes:** [https://target.com https://grpc.target.com:50051/service.OrderService]

### 164. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://admin.target.com/dashboard]

### 165. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/v1/users https://staging.target.com]

### 166. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://ws.target.com/realtime]

### 167. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://target.com https://staging.target.com]

### 168. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://internal-api.target.com:8443/v2/orders]

### 169. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (prometheus)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://monitoring.target.com:9090/metrics]

### 170. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/dashboard]

### 171. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://internal-api.target.com:8443/v2/payments]

### 172. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://events.target.com/v1/track]

### 173. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (apache/2.4)
- **Affected Nodes:** [https://api.target.com/graphql https://staging.target.com]

### 174. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (apache/2.4)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com]

### 175. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://ws.target.com/realtime]

### 176. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://events.target.com/v1/track]

### 177. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://ws.target.com/realtime]

### 178. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (apache/2.4)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://staging.target.com/api/v1/debug]

### 179. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://admin.target.com/api/users]

### 180. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (envoy)
- **Affected Nodes:** [https://api.target.com/v1/users https://grpc.target.com:50051/service.OrderService]

### 181. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://admin.target.com/api/users]

### 182. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (prometheus)
- **Affected Nodes:** [https://api.target.com/graphql https://monitoring.target.com:9090/metrics]

### 183. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/graphql https://internal-api.target.com:8443/v2/payments]

### 184. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://events.target.com/v1/track]

### 185. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/api/users]

### 186. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudfront) and backend (nginx/1.21)
- **Affected Nodes:** [https://cdn.target.com/assets/app.js https://admin.target.com/dashboard]

### 187. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://target.com https://admin.target.com/api/users]

### 188. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (nginx/1.21)
- **Affected Nodes:** [https://api.target.com/v1/users https://internal-api.target.com:8443/v2/payments]

### 189. [🟡 Medium] Trust Boundary: Gateway

- **Mechanism:** `REQUEST_SMUGGLING`
- **Risk Score:** 0.70
- **Confidence:** 0.60
- **Skill Reference:** `skills/infrastructure/parser_differential_abuse.md`
- **Rationale:** Protocol boundary between proxy (cloudflare) and backend (envoy)
- **Affected Nodes:** [https://api.target.com/graphql https://grpc.target.com:50051/service.OrderService]

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
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/payments]

### 197. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/payments]

### 198. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/dashboard]

### 199. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/api/users]

### 200. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://admin.target.com/api/users]

### 201. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/dashboard]

### 202. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/dashboard]

### 203. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://admin.target.com/api/users]

### 204. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://internal-api.target.com:8443/v2/orders]

### 205. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/orders]

### 206. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/login https://internal-api.target.com:8443/v2/orders]

### 207. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://admin.target.com/dashboard]

### 208. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/orders]

### 209. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/oauth/authorize https://internal-api.target.com:8443/v2/payments]

### 210. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/.well-known/openid-configuration https://admin.target.com/api/users]

### 211. [🟡 Medium] Trust Boundary: Identity

- **Mechanism:** `IDENTITY_LEAK`
- **Risk Score:** 0.60
- **Confidence:** 0.60
- **Skill Reference:** `skills/auth_logic/oauth_sso_integrity.md`
- **Rationale:** Cryptographic boundary managed by IdP — auth endpoint protects resource
- **Affected Nodes:** [https://api.target.com/v1/auth/token https://internal-api.target.com:8443/v2/payments]

