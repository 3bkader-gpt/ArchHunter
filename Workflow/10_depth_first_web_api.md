# 10 — Depth-First Web & API (State Machines, AuthZ, Business Logic)

> **Doctrine:** [`Methodology/DEPTH_FIRST_DOCTRINE.md`](../Methodology/DEPTH_FIRST_DOCTRINE.md) · **Precondition:** Workflows 03-05 mapped the surface · **Artifacts:** `templates/STATE_MACHINE_MAP_TEMPLATE.md`, `templates/AUTHZ_MATRIX_TEMPLATE.md`

## Operational Goal
Stop hunting for *bugs*; hunt for *how the application is supposed to work*, then break the assumptions. Where automation does breadth (10,000 URLs × 100 payloads), this workflow does depth (few features × full understanding).

## Phase 1 — Map the State Machine (Not Just Endpoints)

1. Provision 3 accounts: **Victim**, **Attacker**, **Admin** (per program rules).
2. For every major feature (Auth, Profile, Teams/Orgs, Payments, Uploads, API Keys) document in the `STATE_MACHINE_MAP`:
   - **Object states:** e.g. `invite: sent → pending → accepted → revoked`
   - **Roles that touch it at each state**
   - **Backend side effects on transition:** emails, webhooks, cache purges, new API calls
3. **Shadow API diff:** import the public OpenAPI spec, then diff it against the JS bundle's `fetch()` calls. Anything in JS but not in the spec = shadow API → test its authz hardest. See [`shadow_api_exploitation`](../skills/auth_logic/shadow_api_exploitation.md).

**Tools:** Burp/Caido proxy + Logger++, **active scanning OFF**. You are manually mapping.

## Phase 2 — AuthZ Is King: Test Every Function Twice

90% of high-paying bugs are Broken Access Control because it needs 2 authenticated contexts. For **every** captured request, fill the `AUTHZ_MATRIX`:

| Check | Method |
|---|---|
| **BOLA/IDOR** | Replay as Attacker with Victim's `id` — for POST/PUT/PATCH/DELETE, not just GET |
| **BFLA** | Replay the admin's endpoint with the viewer's cookie/token — UI hiding a button is not access control |
| **State-dependent IDOR** | Create as Attacker → swap ID to Victim's → act (`POST /api/teams/ATTACKER_ID/invite` → `VICTIM_ID`) |
| **Mass assignment** | Add `{"role":"admin","price":0,"isVerified":true}` to PUT/PATCH bodies; diff fields the frontend *sends* vs the backend *accepts* |

**Skill:** [`logic_idor_auth`](../skills/auth_logic/logic_idor_auth.md) · **Cross-tenant rule:** a finding that stays self-inflicted is N/A — prove cross-account reach.

## Phase 3 — Business Logic & Race Conditions

Checklist (un-automatable — requires understanding *intended* logic):
- **Coupon/Credit/Quantity:** apply → remove → re-apply; 100% coupon + remove the item but keep the discount.
- **Workflow bypass:** `/step1 → /step2 → /step3` — call `/step3` directly; reuse a token/nonce twice.
- **Races:** 20 parallel `POST /api/redeem-giftcard` / `claim-username` via Turbo Intruder / last-byte sync. → [`race_conditions`](../skills/state_management/race_conditions.md)
- **Parser differentials:** `application/json` vs `text/json`, duplicate keys `{"id":1,"id":2}`, type confusion `{"price":"10"}` vs `{"price":10}`. → [`parser_differential_abuse`](../skills/infrastructure/parser_differential_abuse.md)

## Phase 4 — Web Deep Dive: The JS Is the Source Code

1. Extract bundles (`app.js`, `main.chunk.js`) — [`analyze_js_bundle.sh`](../scripts/analyze_js_bundle.sh) / [`.ps1`](../scripts/analyze_js_bundle.ps1).
2. **Sinks & gadgets:** `innerHTML`, `dangerouslySetInnerHTML`, `postMessage`, `addEventListener('message'`, `localStorage`, `serviceWorker`, `JSON.parse`.
3. **Prototype pollution gadgets:** `__proto__`, `constructor.prototype` — pollution + sink gadget = exploitable. → [`prototype_pollution`](../skills/infrastructure/prototype_pollution.md)
4. **Client-side path traversal:** `fetch("/api/user/..%2f..%2fadmin")` — client router may normalize differently than the server. → [`cspt_client_side_path_traversal`](../skills/infrastructure/cspt_client_side_path_traversal.md)
5. **Cache behavior:** `X-Forwarded-Host: evil.com` + `X-Forwarded-Scheme: https` on every page — does the reset email or `og:url` point to evil? Does the CDN cache it? → [`cache_attacks`](../skills/state_management/cache_attacks.md)

## Weekly Cadence
Mon-Tue: one feature mapped → Wed: authz matrix → Thu: JS + logic abuse → Fri: races + chaining → [`07_chain_building`](07_chain_building.md).

## Transition
Chain findings (technical or business-logic) in **[07 — Chain Building](07_chain_building.md)**; report via **[09 — Reporting](09_reporting.md)**.
