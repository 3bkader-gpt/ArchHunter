# 05 — Mechanism Correlation Engine

## Goal
Map the extracted Trust Boundaries directly to the actionable offensive primitives located in the `skills/` directory.

## Correlation Matrix

| Inferred Trust Boundary | Correlated Reasoning Skill | Trigger Condition |
| :--- | :--- | :--- |
| `BOUNDARY_IDENTITY_TRANSLATION` | `auth_logic/oauth_sso_integrity.md` | Presence of OIDC, SAML, or `X-Forwarded-User` headers. |
| `BOUNDARY_PARSER_DESYNC` | `infrastructure/parser_differential_abuse.md` | H2->H1 downgrade, or differing `Server` headers between Edge/Compute. |
| `BOUNDARY_TEMPORAL_DRIFT` | `state_management/async_workflow_integrity.md` | Presence of queues (Kafka/RabbitMQ) or `202 Accepted` status codes. |
| `BOUNDARY_WORKLOAD_ESCALATION` | `infrastructure/workload_identity_federation.md` | K8s service accounts mapped to AWS/GCP IAM roles. |
| `BOUNDARY_DISTRIBUTED_CONSISTENCY` | `state_management/consistency_failures.md` | Multi-region subdomains (`us-east`, `eu-west`) serving identical content. |
| `BOUNDARY_REBAC_GRAPH` | `state_management/distributed_auth_propagation.md` | Presence of GraphQL nodes with recursive user-group relationships. |

## Execution Logic
For every Boundary tagged in Phase 04, the engine generates an `AttackHypothesis` object referencing the linked skill, the specific nodes involved, and the rationale for the hypothesis.
