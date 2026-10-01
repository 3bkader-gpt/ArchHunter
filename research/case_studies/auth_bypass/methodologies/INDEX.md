# Methodology, Cheatsheets & Tactical Guides Index

A structured library of **7 battle-tested guides and exploit cheatsheets** covering modern authentication architectures, cryptographic flaws, access controls, and boundary proxy defenses.

---

## Guides Directory

| Guide | Description | Key Focus Areas |
| :--- | :--- | :--- |
| [**Authentication Testing Methodology**](./auth_testing_methodology.md) | 5-Phase structured testing framework | Reconnaissance, Parameter manipulation, 2FA bypass, SSO flows, Session management |
| [**OAuth, JWT & Session Cheatsheet**](./oauth_jwt_session_cheatsheet.md) | Ready-to-use matrix of exploit techniques | `redirect_uri` manipulation, `state` spoofing, JWT headers (`none`, `kid`, `jwk`), Cookie flags |
| [**IDOR & Access Control Patterns**](./idor_access_control_patterns.md) | Concrete exploitation patterns for IDOR & BAC | Numeric & UUID evasion, HTTP method tampering, Mass assignment, Multi-tenancy |
| [**SAML 2.0 & Enterprise SSO Guide**](./saml_sso_exploitation_guide.md) | Enterprise single sign-on auditing | XML Signature Wrapping (XSW 1-8), Signature stripping, Comment injection, SAML Raider |
| [**GraphQL Auth Bypass Patterns**](./graphql_auth_bypass_patterns.md) | Modern GraphQL security | Query batching & alias multiplexing (2FA brute force), Relay Global IDs, `@auth` directive bypass |
| [**Reverse Proxy & Header Bypasses**](./reverse_proxy_header_auth_bypass.md) | Edge gateway & proxy barrier evasion | Spring Boot semicolon matrix (`/..;/`), URL normalization, Hop-by-hop headers, IP spoofing |
| [**Web Cache Deception & Host ATO**](./web_cache_deception_and_host_header_ato.md) | Cache and host header exploitation | Static extension confusion (`.css`, `.avif`), Delimiter tricks, Password reset poisoning ATO |

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
