# CHAINING WORKSHEET — [TARGET_NAME]

> **Session:** [DATE] · **Workflow:** [`Workflow/07_chain_building.md`](../Workflow/07_chain_building.md) § Business-Logic Chains
> **Rule:** never report the 3 lows before trying the chain. Review this sheet every Friday before closing the week.

## 1. Open "Non-Issues" Inventory
Everything found so far that alone is Info/Low. No item leaves this table until it is either chained or reported as-is with a chain attempt documented.

| # | Finding | Severity | Endpoint/Asset | State/Role dependency | Chain attempt? |
|---|---|---|---|---|---|
| 1 | Arbitrary `Host` header accepted | Low | | | |
| 2 | Reset email renders `Host` in link | Low | | | |
| 3 | Rate limit keyed on `X-Forwarded-For` | Info | | | |
| 4 | SVG upload allowed | Info | | | |
| 5 | | | | | |

## 2. Chain Sketches
Combine the primitives above. Template: primitive A (sets state) + primitive B (crosses boundary) + primitive C (removes friction) = impact.

### Chain candidate: [e.g. ATO via Host Header Poisoning]
- **Primitives:** #1 + #2 + #3
- **Flow:** spoof `Host` on reset → victim's token lands on attacker host → rate-limit bypass enables iteration on the token form
- **Missing link:** [what would complete it — test next]
- **Status:** untested / tested-failed / confirmed

### Chain candidate: [e.g. Stored XSS via upload + CSP gap]
- **Primitives:** #4 + [#7 error page without CSP]
- **Flow:** attacker-hosted SVG → privileged victim routed through CSP-less error page → script executes in-app
- **Status:**

### Chain candidate: (state-dependent IDOR)
- **Primitives:** [create as A] + [ID swap in-flight] + [token not bound to object]
- **From state map:** which transitions accept an ID that differs from the token's origin?
- **Status:**

## 3. Race Windows
From the state map: which transitions are async / not idempotent? Candidates for last-byte sync bursts ([`race_conditions`](../skills/state_management/race_conditions.md)).

| Endpoint | Why raceable (no lock / async / non-idempotent) | Burst result |
|---|---|---|
| `POST /api/redeem` | credit insert without unique constraint | |
| | | |

## 4. Outcome Log

| Chain | Final severity | Reported? | Report link |
|---|---|---|---|
| | | | |
