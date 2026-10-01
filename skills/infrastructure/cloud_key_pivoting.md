# Cloud Key Pivoting (AppSync / Firebase Intelligence)

## Objective & Context
*   **Security Assumption Failure:** Teams treat embedded cloud SDK keys as "public identifiers by design" and stop looking. The key's *authorization to call metadata endpoints* — not its secrecy — is the vulnerability: it turns client-side artifacts into an infrastructure mapping oracle.
*   **Trust Boundary Violation:** A single extracted key crosses from "hardcoded secret triage" into the org's **backend topology**: which auth flows exist, what the data model looks like, which sibling apps share the project, and which backing services the resolvers map to.

> [!IMPORTANT]
> **Scope doctrine:** querying AppSync/Firebase endpoints *with* extracted keys, and probing bucket ACL differentials, crosses from passive OSINT into **active testing using discovered credentials**. "The domain is in scope" is not the same as "key/credential testing is permitted" — confirm the program's policy explicitly before any authenticated call, and prefer read-only metadata operations (introspection, provider fingerprint) over data operations.

## Recognition Patterns
*   **Mechanism:** JS bundles / APKs / public repos containing `apiKey` for Firebase, AppSync GraphQL endpoints (`https://<id>.appsync-api.<region>.amazonaws.com/graphql`) with `x-api-key`, or AWS Amplify config blocks.
*   **Behaviors:**
    *   `aws-exports.js` / `amplifyconfiguration.json` shipped to the client.
    *   Firebase `apiKey` + `projectId` + `authDomain` in plain config.
    *   Key also found in *other* repos/clients (mobile + web + internal tools sharing one backend).

## Step-by-Step Validation Strategy

### 1. AppSync introspection via the API key
Introspection is "often on even when disabled on the primary endpoint" — with the key, POST a standard introspection query to `/graphql`:
```http
POST /graphql HTTP/1.1
Host: <id>.appsync-api.<region>.amazonaws.com
x-api-key: <KEY>

{"query": "query IntrospectionQuery { __schema { types { name fields { name } } } }"}
```
A full schema response = every type, mutation, and resolver — usually mirroring internal data models (user tables, admin fields, internal service names) far beyond the frontend surface.

### 2. Field-name leakage without introspection
If introspection is blocked, diff the JS bundle for every `gql`/`graphql` tagged template literal — reconstruct partial schema from client-side queries. Cluster the field names: naming conventions reveal sibling services (`internalUser`, `adminAudit`, `vendorPortal`) that never appear in any URL.

### 3. Firebase auth-provider fingerprinting (passive-first)
`firebaseio.com/.json` reads are blocked by default rules now, but the **Identity Toolkit** endpoints combined with the key fingerprint *which auth providers are enabled* — flows invisible from the UI:
```bash
curl -s "https://identitytoolkit.googleapis.com/v1/projects?key=<KEY>" \
     -H "Content-Type: application/json" -d '{}'   # error message enumerates enabled providers
# signUp / signInWithPassword / sendOobCode behavior deltas → email, phone, SSO flows
```
Enabled-but-unlinked providers (e.g. email/password on an SSO-only product) are classic pre-account-takeover ground. → [`pre_account_takeover`](../auth_logic/pre_account_takeover.md)

### 4. Project-ID cross-referencing
Keys/config embed identifiers (`projectId`, AppSync API ID in the endpoint host). Search GitHub/GitLab/npm **for that exact string** — other repos (internal tools, test harnesses, writeups) referencing the same ID surface sibling apps on the same backend, each with its own weaker attack surface.

### 5. Resolver → backing-infrastructure inference
AppSync resolvers typically map to Lambda/DynamoDB/OpenSearch. Resolver names recovered via schema (or error messages) often leak the backing service directly (`getVendorAuditLog` → a `vendor-audit-*` DynamoDB/stream family). Feed those names into Shodan/Censys/GitHub as search terms for the org's broader AWS footprint. → [`Workflow/12`](../../Workflow/12_next_level_recon.md) Phase 1

## Common Weak Implementations
*   Introspection left enabled on the keyed `/graphql` route while disabled on the "public" web route.
*   One Firebase/AppSync project shared across marketing site, mobile app, and admin tooling — key from any one unlocks metadata about all.
*   Auth providers (email/password, phone) enabled in Firebase but assumed-irrelevant because the UI never renders them.
*   Amplify config shipped with `AWS_APPSYNC_API_KEY` plus staging endpoint URLs in the same bundle.

## Escalation Paths
*   **Shadow data model:** schema reconstruction exposes objects/fields to target with other IDOR/authz techniques ([`logic_idor_auth`](../auth_logic/logic_idor_auth.md)).
*   **Pre-ATO:** dormant auth providers + [`pre_account_takeover`](../auth_logic/pre_account_takeover.md) registration flows.
*   **Sibling-app pivot:** same project ID powering a weaker internal/vendor portal — the key is the *correlation link* between unrelated-looking assets.

## Detection Opportunities
*   AppSync: disable introspection per-API (not per-route); alert on introspection queries carrying client-scoped API keys.
*   CI: fail builds containing live `apiKey`/`projectId` pairs in bundles; prefer runtime-injected config.
*   Firebase: audit enabled sign-in providers quarterly against the product's documented auth flows.

## Notes
*   **False Positives:** a Firebase key alone (no enabled flows beyond the UI, no sibling projects) is low-value — the finding is the *mapping*, not the key string. Report impact, not existence.
*   **Constraints:** AppSync API-key auth mode must be enabled (Cognito/IAM-only endpoints ignore `x-api-key`); identitytoolkit responses are version-dependent.
*   **Cross-reference:** [`shadow_api_exploitation`](../auth_logic/shadow_api_exploitation.md) (undocumented surface), [`graphql_attacks`](graphql_attacks.md) Vector E (persisted-query replay), [`Workflow/12`](../../Workflow/12_next_level_recon.md) Phase 3 (repo project-ID search).
