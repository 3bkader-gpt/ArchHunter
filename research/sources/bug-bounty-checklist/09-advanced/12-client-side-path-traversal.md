# Client-Side Path Traversal (CSPT)

**What it is:** The **front-end** builds a request path from attacker-influenced input and doesn't normalize `../` — so `../` in your input walks the URL to a *different* endpoint than the developer intended. The traversal happens in the browser (JS `fetch`/`XHR`/axios), then the request is sent with the victim's session. Turns a reflected/stored value into CSRF, IDOR, token-leak, or a self-XSS-to-stored pivot. Almost no scanner models it because the bug is in client JS, not the server.

## Core mechanic
```javascript
// app JS — id comes from the URL / a stored field / a message
fetch(`/api/v2/users/${id}/avatar`)          // intended
// attacker sets id = "../../admin/deleteUser/1337"
fetch(`/api/v2/users/../../admin/deleteUser/1337/avatar`)  // browser normalizes → /admin/deleteUser/1337/avatar
```
The **browser** collapses `../` before sending, so the request lands on an endpoint the app never meant to call — with the victim's cookies/headers attached.

## Where to look
- Any JS that concatenates user input into a request path: `fetch("/api/"+x)`, axios `baseURL`+path, `router.push`, `<img src>`/`<a href>` built from data, template `${}` URLs.
- Sources: URL path/query/hash, `postMessage`, `localStorage`, a **stored** field (profile, filename, id) reflected into a later fetch (second-order CSPT).
- SPAs with a client-side router + a REST/GraphQL backend on the same origin.

## What it becomes
- [ ] **CSPT2CSRF (the big one):** traverse a *state-changing* request. If the app fetches `POST /api/items/${id}/... ` and you control `id`, walk it to `/api/account/delete` or `/api/role/grant` → the victim's browser fires the privileged request with their auth and any same-origin CSRF token the JS auto-attaches (defeats token-based CSRF because it's a same-origin request).
- [ ] **IDOR via traversal:** walk a read fetch to another user's/tenant's object path.
- [ ] **Token / response leak:** redirect the fetch to an endpoint whose JSON the page then renders/echoes to a place you can read (reflected into DOM, sent onward).
- [ ] **Reflected → stored pivot:** the traversed response is injected into the DOM (self-XSS) or stored, becoming a real XSS.
- [ ] **API-version / auth downgrade:** traverse from a guarded path prefix to an unguarded sibling.

## Test steps
- [ ] Find every client-built request path; inject `../`, `%2e%2e%2f`, `..%2f`, `%2e%2e/`, `....//`, encoded/double-encoded, and note where the browser (or the app's own normalizer) collapses it.
- [ ] Map reachable endpoints from the injection point (how many `../` to escape the fixed prefix; what verb the fetch uses).
- [ ] For CSRF impact, aim the traversal at a **state-changing** same-origin endpoint the JS calls with method+body you can influence.
- [ ] Check second-order: store `../..` in a field, trigger the page that fetches using it.

## 🎯 PoC pattern (CSPT → CSRF)
App JS on `target.com`:
```javascript
// "reportId" taken from ?report= in the URL
fetch(`/api/v3/reports/${reportId}/share`, {method:"POST", headers:{'X-CSRF':csrf}, body:...});
```
Attacker link the victim opens:
```
https://target.com/app#report=..%2f..%2faccount%2femail%2fchange%3fnew=attacker@evil.com%23
```
Browser normalizes `/api/v3/reports/../../account/email/change?...` → `/api/v3/account/email/change` — sent **POST**, **same-origin**, with the victim's session **and** the auto-attached `X-CSRF` header → email changed → ATO (`09-advanced/07`).

## Impact
CSRF that bypasses same-origin CSRF tokens, IDOR, privileged state change, token/response leak, XSS pivot. High when it reaches a state-changing or auth endpoint.

## Report notes
Show the client code building the path, the traversal input, the **normalized** request the browser actually sent (DevTools Network / proxy), and the state change. Prove on your own victim account. Distinguish from server-side path traversal (that's file read; this is request re-routing).

## Tools
Browser DevTools (Network — see the normalized URL), Burp (observe the outgoing request), manual JS review (`00-recon/05`), DOM Invader for source→fetch flows.

## Sources
Doyensec CSPT research; Maxence Schmitt "CSPT2CSRF"; PortSwigger client-side path traversal notes.

## Related
`05-client-side/01-csrf.md` · `01-access-control/01-idor-bola.md` · `09-advanced/01-second-order.md` · `09-advanced/07-account-takeover-chains.md` · `00-recon/05-js-analysis.md`
