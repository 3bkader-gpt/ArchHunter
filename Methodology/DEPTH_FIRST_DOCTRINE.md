# Depth-First Doctrine — Win on Depth, Not Breadth

> **Status:** Core doctrine · **Supersedes:** breadth-first reflexes · **Reads in:** ~10 minutes
> **Related:** [`claude.md`](../claude.md) · [`Workflow/10-12`](../Workflow/) · [`OPERATIONAL_PLAYBOOK.md`](OPERATIONAL_PLAYBOOK.md)

---

## 1. The Premise

Bug hunting is not dead — the *low-hanging fruit* is dead. Automation (nuclei, Burp scanner, AI agents) has industrialized:

```
recon → known payload list → known bug class → known location → report
```

An AI agent is a **pattern matcher**: it finds known bug classes in known places. It is structurally bad at:
- **Novel variants** — a new primitive or bypass with no signature yet.
- **Stateful chaining** — combining 3-4 "non-issues" across features into one critical.
- **Business logic** — it does not know what the application *should* do, so it cannot see when that is broken.

**ArchHunter's position:** this is exactly the architectural-reasoning thesis. Where scanners fuzz payloads, we map mechanisms, state machines, and trust boundaries — then break the assumptions. This doctrine operationalizes that position into a repeatable hunting method.

## 2. The Core Mindset Shift

| | Automation / AI agents | Depth-first hunter (ArchHunter) |
|---|---|---|
| Unit of work | 10,000 URLs × 100 payloads | 10 features × 100% understanding |
| Seeks | Bugs | **How the application is supposed to work** — then breaks the assumptions |
| Reads | Error messages | JS bundles, state transitions, role graphs, cache behavior |
| Chaining | Reports 3× Info/Low and moves on | Chains Info + Low + Low → High/Critical |
| Winner takes | Same 100 public programs as every other agent | Private programs, new features (<48h), thick clients, forgotten infra |

**Decision rule:** if a scanner could have found it, do not spend your hour on it. Spend the hour where a scanner cannot go: multi-session authz, state transitions, parser differentials in business payloads, second-order effects.

## 3. The Four Depth-First Attack Surfaces

### 3.1 A New Variant of a Known Class
AI knows `?q=<svg onload=alert(1)>`. It does not invent bypasses. Novel = reading how a framework/cache/parser *actually works* and finding the gap between documentation and implementation.
- Client-Side Path Traversal (`fetch()` + `../` in client routing) → [`skills/infrastructure/cspt_client_side_path_traversal.md`](../skills/infrastructure/cspt_client_side_path_traversal.md)
- Cache poisoning via headers the cache ignores but the origin trusts → [`skills/state_management/cache_attacks.md`](../skills/state_management/cache_attacks.md)
- CL.0 / TE.0 smuggling variants → [`skills/infrastructure/parser_differential_abuse.md`](../skills/infrastructure/parser_differential_abuse.md)
- Prototype pollution *gadgets* (pollution is Info; the gadget is the Critical) → [`skills/infrastructure/prototype_pollution.md`](../skills/infrastructure/prototype_pollution.md)

### 3.2 Chaining "Non-Issues" Into High Impact
Agents are not good at stateful chaining across 4-5 features. We are:
- Arbitrary `Host` header (Low) + reset link uses `Host` (Low) + rate-limit bypass (Info) = **ATO via Host Header Poisoning**
- SVG upload (Info) + missing CSP on error page (Info) = **Stored XSS**
- See [`Workflow/07_chain_building.md`](../Workflow/07_chain_building.md) § "Business-Logic Chains" and the [`CHAINING_WORKSHEET`](../templates/CHAINING_WORKSHEET_TEMPLATE.md).

### 3.3 Business Logic & State-Machine Bugs
The highest-paying class today, and the least automatable:
- Coupon applied → item removed → coupon stays applied at checkout.
- Invite accepted as `viewer` with the role field swapped to `admin` in-flight.
- Gift card redeemed 20× in parallel (no DB lock).
- Multi-step workflow IDOR: create as A, swap the ID while acting as B.

**Method:** [`Workflow/10_depth_first_web_api.md`](../Workflow/10_depth_first_web_api.md) Phase 1-3 · artifacts: [`STATE_MACHINE_MAP`](../templates/STATE_MACHINE_MAP_TEMPLATE.md), [`AUTHZ_MATRIX`](../templates/AUTHZ_MATRIX_TEMPLATE.md) · skills: [`state_machine_integrity`](../skills/state_management/state_machine_integrity.md), [`race_conditions`](../skills/state_management/race_conditions.md), [`logic_idor_auth`](../skills/auth_logic/logic_idor_auth.md), [`rate_limiting_evasion`](../skills/state_management/rate_limiting_evasion.md).

### 3.4 Architectural / Second-Order Bugs
Payload stored in one service, executed in another 10 minutes later. Trust decisions split across 3 services (OAuth/SAML/WebSocket/postMessage). AI-era variants: prompt injection → SSRF → RCE, vector-DB IDOR, LLM tool-call leakage.
- Skills: [`async_workflow_integrity`](../skills/state_management/async_workflow_integrity.md), [`oauth_sso_integrity`](../skills/auth_logic/oauth_sso_integrity.md), [`saml_xsw_sso`](../skills/auth_logic/saml_xsw_sso.md), [`websocket_state_abuse`](../skills/state_management/websocket_state_abuse.md), [`mcp_agent_tool_poisoning`](../skills/emerging/mcp_agent_tool_poisoning.md), [`indirect_prompt_injection_exfiltration`](../skills/emerging/indirect_prompt_injection_exfiltration.md).

## 4. Hunt Where Automation Cannot Run

1. **Private programs** — not in any agent's default target list.
2. **Mobile / thick clients** — 99% of agents never see the real surface (deep links, exported components, native trust decisions). → [`Workflow/11_depth_first_mobile.md`](../Workflow/11_depth_first_mobile.md)
3. **Brand-new features (<48h)** — shipped before the hardening pass.
4. **Forgotten infrastructure** — acquisitions, staging parity, historical DNS, shadow APIs. → [`Workflow/12_next_level_recon.md`](../Workflow/12_next_level_recon.md)

## 5. How Novel Techniques Are Actually Found (The System)

1. **Pick one technology and go deep.** Next.js routing, Cloudflare cache internals, Okta OAuth implementation. The novel technique lives in the gap between documentation and implementation.
2. **Read the last 12 months of disclosed reports and PortSwigger Research — for methodology, not payloads.** Always ask: *"why did the scanner miss this?"* (Fresh supply lands in [`research/case_studies/`](../research/case_studies/INDEX.md) via `scripts/intel/`.)
3. **Build a lab.** Local Docker apps with one weird feature each; break it offline first. Smuggling variants were found this way, not by fuzzing.
4. **Know one target better than its developer.** Two weeks of the weekly cadence on one program beats a year of breadth.

## 6. The Weekly Cadence (One Program, One Feature)

| Day | Work |
|---|---|
| Mon-Tue | Map the feature (states × roles × side effects) → `STATE_MACHINE_MAP` |
| Wed | AuthZ matrix: every endpoint × every role × every ID → `AUTHZ_MATRIX` |
| Thu | JS review + business-logic abuse on the same feature |
| Fri | Races + chaining: combine the 3 lows into one High → `CHAINING_WORKSHEET` |

## 7. Doctrine Rules (Absolutize)

1. **Breadth is the engine's job; depth is yours.** Let ArchHunter's Runtime enumerate the surface — you pick the two features that matter.
2. **Never report the 3 lows before trying the chain.**
3. **Every mapping artifact must exist before testing starts** (state map → matrix → probes). No artifact, no testing.
4. **For every captured request ask:** what states/roles/other services does this touch? Who else can reach it, and in what state?
5. **Undocumented beats documented:** anything in the JS bundle or APK that is missing from the public spec is a shadow API — test its authz hardest. → [`shadow_api_exploitation`](../skills/auth_logic/shadow_api_exploitation.md)
