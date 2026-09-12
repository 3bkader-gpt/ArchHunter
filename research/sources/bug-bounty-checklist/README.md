# Bug Bounty Checklist — Zero to Deep Cuts

A working checklist for web/API bug hunting. Ordered the way a real engagement flows: recon first, then attack surface by class. Each bug class lives in its own file so you can grep, print, or drop into a report fast.

## How to use

1. Start in `00-recon/` — you cannot test what you have not mapped.
2. Pick a target feature, then walk the relevant class files.
3. Every file follows the same shape: **What it is → Where to look → Test steps → Payloads/PoC → Impact → Report notes**.
4. Most files also carry a **`Deep cuts`** section — the rarer, low-competition techniques and bypass matrices that pay when the obvious tests dupe. Read those once you've walked the basics.
5. `[ ]` checkboxes are meant to be copied into your engagement notes and ticked off.
6. `99-reference/` holds the tools list, wordlists, and writeup index. Response-vs-request verification discipline lives in `99-reference/05`.

## Directory map

| Dir | Class | Files |
|-----|-------|-------|
| `00-recon/` | Mapping the attack surface | scope, subdomains, content discovery, fingerprinting, JS mining |
| `01-access-control/` | AuthZ | IDOR/BOLA, the 20 ID-tamper methods, privilege escalation, forced browsing, **cross-tenant isolation** |
| `02-business-logic/` | Logic & money | price tamper, cart/checkout, coupons, refunds/currency, premium abuse, reviews, race conditions |
| `03-injection/` | Server injection | SQLi, XSS (+mXSS/clobber), SSTI, cmd injection, XXE, SSRF, NoSQL/misc, **deserialization**, **LFI/path-traversal** |
| `04-auth-session/` | AuthN | **`00` register+login one-path methodology (start here)**, login, 2FA/OTP, JWT, OAuth/SSO, password reset, session mgmt, session hijacking/fixation/cookie-tossing, JSON auth fuzzing, email/invite/reset flow abuse, **SAML (XSW/comment-injection/sig-strip)**, **session puzzling** |
| `05-client-side/` | Browser trust | CSRF, CORS, clickjacking (+double-clickjacking), postMessage, open redirect, security-headers bypass (CSP etc.), **WebSocket/CSWSH**, **DOM clobbering**, **XSSI** |
| `06-file-upload/` | Upload chains | extension/content-type bypass, XSS via SVG/PNG/EXIF, **post-upload processing (parsers/CSV/overwrite/download-authz)** |
| `07-api/` | API-specific | REST, GraphQL (advanced), mass assignment, rate limiting, HPP, **webhook/integration trust**, **gRPC/gRPC-Web/protobuf** |
| `08-infra/` | Infra & edge | subdomain takeover, request smuggling, cache poisoning, secrets |
| `09-advanced/` | Obscure / low-competition | second-order, prototype pollution, dependency confusion, parser differentials, dangling-markup/CSS injection, DNS rebinding, ATO chains, obscure catalog, host-header injection, state desync, **XS-Leaks**, **client-side path traversal (CSPT)**, **secondary-context/path-confusion** |
| `10-server-edge/` | Server / nginx / LB / CDN / WAF | nginx misconfig, LB/proxy desync & smuggling, CDN cache poisoning/deception, WAF & origin bypass, HTTP quirks/methods |
| `11-ai-llm/` | LLM/AI features | prompt injection (direct/indirect), system-prompt leak, chatbot IDOR, exfil channels, ASCII smuggling, tool/agent abuse, RCE via code tools (ASI01–ASI10) |
| `12-tech-specific/` | Product/framework playbooks | Django (debug→RCE), Symfony (profiler/secret-fragment), Jira/Confluence (CVE catalog), AEM (dispatcher bypass, JCR dump, Groovy RCE), Next.js/Nuxt (CVE-2025-29927, cache-poison DoS), ASP.NET/IIS (ViewState→RCE, short-name) |
| `99-reference/` | Support | tools, wordlists, writeup index, methodology loop, **field tips (operational one-liners)** |

## Triage priority (what pays)

1. **Access control (IDOR/BOLA, priv-esc)** — highest hit rate, clear impact.
2. **Business logic / money** — often uncontested, hard for scanners to find.
3. **Auth chains (2FA bypass, reset poisoning, OAuth)** — critical severity.
4. **SSRF / injection** — high severity when they land.
5. **Client-side (XSS, CSRF, CORS)** — bread and butter, watch for dupes.
6. **Low-competition / obscure** — SAML, gRPC, AI/LLM, XS-Leaks, CSPT, parser differentials, state desync, cache/desync. Fewer hunters, fresh surface; often the difference between a dupe and a bounty.
7. **Tech-specific (`12-`)** — when you fingerprint Django/Symfony/Jira/Confluence/AEM, walk the product playbook: known-CVE catalogs and default-surface misconfigs that scanners skip on unpatched instances.

## Golden rules

- **Two accounts, always.** Most authz bugs need attacker (UserA) + victim (UserB).
- **Change the ID to a *valid* other ID, not just to `'`.** Scanners chase SQLi and miss authz. `1001 → 1089` beats `1001 → 1001'`.
- **Read the response, not just the status.** `200` with someone else's data ≠ `403`.
- **Response edits are cosmetic; request edits are real.** Flipping `false→true` in a *response* only fools your UI. Prove it server-side (interception off, fresh request, independent session) — see `99-reference/05-response-manipulation-and-verification.md`.
- **Test the mobile/API endpoints.** Legacy `/api/v1/` often skips checks the web UI enforces.
- **Diff everything.** Same request as two users, side by side.
- **Stay in scope.** Check the program `99-reference/methodology.md` before you touch anything.
