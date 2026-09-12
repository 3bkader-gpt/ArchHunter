# Methodology Loop & Rules of Engagement

## The loop
```
1. SCOPE      read policy, record in/out-of-scope, screenshot it.
2. RECON      subdomains → live hosts → tech → content → params → JS.
3. MAP        pick a feature; understand the normal flow with 2 accounts + proxy.
4. ATTACK     walk the class files against that feature.
5. VERIFY     reproduce, minimize the PoC, confirm impact.
6. REPORT     clear title, steps, PoC, impact, remediation.
7. REPEAT     next feature / next host.
```

## Per-feature quick pass (fast triage)
- [ ] Any ID? → IDOR/BOLA (`01/01`, `01/02`).
- [ ] Any money/quantity/price? → business logic (`02/*`).
- [ ] Any input reflected/stored? → XSS/injection (`03/*`).
- [ ] Any auth transition? → auth chain (`04/*`).
- [ ] Any state-changing action? → CSRF (`05/01`).
- [ ] Any URL fetched server-side? → SSRF (`03/06`).
- [ ] Any upload? → upload chain (`06/*`).
- [ ] Any object write? → mass assignment (`07/03`).
- [ ] Any stored value read elsewhere later? → second-order (`09/01`).
- [ ] Any JSON merge / `?a[b]=c` params? → prototype pollution (`09/02`).
- [ ] Any allowlist/validator + separate executor? → parser differentials (`09/04`).
- [ ] Behind a CDN/proxy? → cache poisoning/deception + smuggling (`10/02`, `10/03`).
- [ ] `Server: nginx`? → alias traversal + path bypass (`10/01`).
- [ ] WAF present? → origin-IP find + inline bypass (`10/04`).
- [ ] Reflected headers (`X-Forwarded-*`)? → header trust + unkeyed cache poison (`10/02`, `10/03`).
- [ ] CSP/XFO/headers present? → try the matching bypass gadget (`05/06`).
- [ ] Sensitive single-click action? → clickjacking + double-clickjacking (`05/03`).
- [ ] Session cookie not rotated on login / broad `Domain`? → fixation + cookie tossing (`04/07`).
- [ ] Got XSS on a subdomain? → cookie tossing to escalate to parent domain (`04/07`).
- [ ] JSON auth endpoint (login/register/reset)? → fuzz body shape: type-swap/`$ne`/null/malformed/extra-keys (`04/08`).
- [ ] Serialized blob (cookie/param: `rO0AB`, `O:8:`, `gASV`, `__VIEWSTATE`, `$type`)? → deserialization (`03/08`).
- [ ] WebSocket endpoint? → CSWSH (no Origin check) + message IDOR/injection (`05/07`).
- [ ] App builds links/routes from `Host`/`X-Forwarded-Host`? → host-header injection (`09/09`).
- [ ] HTML injection but CSP/sanitizer blocks script? → DOM clobbering + dangling markup (`05/08`, `09/05`).
- [ ] GraphQL? → alias overloading, batching brute, directive/CSRF, introspection-bypass (`07/02`).
- [ ] Multi-tenant / workspaces / orgs? → cross-tenant isolation, both directions (`01/05`).
- [ ] Just disabled/deleted/reset/revoked something? → replay the stale request = state desync (`09/10`).
- [ ] Upload gets parsed/converted/previewed/exported later? → file-processing edge cases (`06/03`).
- [ ] Webhook receiver / integration config? → forged/replayed events, SSRF via URL (`07/05`).
- [ ] Invite / magic-link / email-change flow? → binding/reuse/wrong-recipient logic (`04/09`).
- [ ] Multi-step flow with a check-then-act gap? → multi-step race (`02/07`).
- [ ] SAML SSO (`SAMLResponse` POST)? → XSW / sig-strip / comment-injection NameID (`04/10`).
- [ ] gRPC / gRPC-Web / protobuf (`application/grpc*`)? → reflection dump + BOLA/mass-assign on hidden methods (`07/06`).
- [ ] AI/LLM feature (chatbot/summarizer/agent/RAG)? → prompt injection + tool abuse + cross-user leak (`11/01`).
- [ ] Client builds a fetch path from user input (`../`)? → client-side path traversal (`09/12`).
- [ ] Cross-origin state observable (timing/frame-count/cache)? → XS-Leaks (`09/11`).
- [ ] Redirect/header reflects `%0d%0a`? → CRLF / response splitting (`03/07`).

## Rules of engagement (non-negotiable)
- Stay strictly in scope. Re-check the policy every session (they change).
- Never test denial-of-service on live targets. Detect DoS potential, do not trigger it.
- Prove with the **least** intrusive action. No mass data extraction, no persistence, no lateral movement.
- Use accounts/resources you control as the "victim".
- Do not touch real users' data; one or two records to prove, then stop.
- No social engineering, no physical, unless the program explicitly allows.
- Rate-limit yourself; respect the target's infra. Use anti-ban tooling responsibly.
- Report promptly; do not disclose publicly before the program allows.
- **AI/LLM targets:** don't exfiltrate real users' data through the model; use your own accounts/exfil hosts; "the bot said something bad" is not a finding — tie it to disclosure/tool-action/state-change (`11/01`).
- **Supply-chain / dependency-confusion:** only with explicit program authorization; ship a benign beacon at most (`09/03`).
- **Desync / smuggling / cache:** demonstrate against your own follow-up request or with a cache-buster; never harvest third-party traffic or poison real keys (`08/02`, `10/02`, `10/03`).

## Good report = fast payout
Title (impact-first) → affected asset/endpoint → prerequisites → numbered repro steps → raw request/response PoC → impact (what an attacker gains) → suggested fix → CVSS if asked. One issue per report unless chained.
