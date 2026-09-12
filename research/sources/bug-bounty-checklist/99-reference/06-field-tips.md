# Field Tips — operational one-liners

Loose, high-signal tricks from field notes that don't own a class file. Cross-referenced where a full writeup lives elsewhere.

## Source / VCS leaks
- [ ] **`.svn` source dump:** find `/.svn/` or `/.svn/wc.db` → dump full source with `svn-extractor` (`https://github.com/anantshri/svn-extractor`): `./svn-extractor.py --url http://target --match database.php`.
- [ ] **Webpack sourcemaps:** `.js.map` present → reconstruct original source with `unwebpack-sourcemap` (`https://github.com/rarecoil/unwebpack-sourcemap`). $25k example: https://blog.prodefense.io/little-bug-big-impact-25k-bounty-9e47773f959f
- [ ] **`wp-config.php` backups:** base file 404 but `wp-config.php.swp`, `wp-config.php.bak`, `wp-config.php~`, `wp-config.php.save` may return 200 → DB creds. Hex-decode if encoded.

## Path / case bypass
- [ ] **Case-permutation bypass** of blocked admin paths: `phpmyadmin` 301 but `PHPMyAdmin` / `PHPMYADMIN` / `phpMYadmin` 200; same for `/phpmyadmin/setup/index.php`. Try mixed case on any 403/301 sensitive path (see also `10-server-edge/04`).

## SQLi in odd places
- [ ] **`sitemap.xml` params:** `target.com/sitemap.xml?offset=1;SELECT IF((8303>8302),SLEEP(9),2356)#` — time-based. sqlmap: `-p offset --dbms=MySQL --test-filter="MySQL >= 5.0.12 stacked queries"`.
- [ ] **Parameter-name injection** (not just the value): `someparam[id) VALUES (NULL); WAITFOR DELAY '0:0:5';--]=test`.

## Default creds (check on any login/panel)
- [ ] Oracle PeopleSoft: `PSADMIN:PSADMIN`, `PS:PS`, `PSEM:PSEM` — dork `intitle:"Oracle+PeopleSoft+Sign-in"`.
- [ ] Generic: `admin:admin`, `admin:password` — Shodan `ssl:"target" http.title:"dashboard"`.

## Client-side
- [ ] **Cookie bomb DoS:** if a parameter reflects into a `Set-Cookie`, inject many commas / oversized value → cookie exceeds request-header limit → self-DoS for the victim until cookie expires.
- [ ] **Priv-esc via JS role hunt:** intercept register/login response with `"role":"ROLE_USER"`, grep JS bundles for the admin value (e.g. `admin_role`), match-and-replace → escalate. Verify server-side, not just UI (`01-access-control/03`, `99-reference/05`).
- [ ] **XSS via JWT param:** `url/dest?jwt=<token>` where `jwt=` is decoded and rendered → put an XSS payload inside a JWT claim.

## Recon extraction
- [ ] **AlienVault URL harvest:** `gron "https://otx.alienvault.com/otxapi/indicator/hostname/url_list/$sub?limit=100&page=1" | grep '\burl\b' | gron --ungron | jq | egrep -wi 'url' | awk '{print $2}' | sed 's/"//g' | sort -u`.
- [ ] **GitHub dorks for secrets:** `org:target password/pass/pwd`, `"target.atlassian" password`, `"target.okta" password`, CSV leaks `org:target extension:csv admin`.
- [ ] **Grabbed-URL grep for cloud docs:** curl a URL list, grep responses for `docs.google`, `/spreadsheets/d/`, `/document/d/`.

## Stack-driven prioritization
- [ ] **Rails** → integer autoincrement IDs in `/type/RECORD_ID` URLs → prioritize IDOR (`01-access-control/01`).
- [ ] **AngularJS** → test `{{7*7}}` for client-side template injection (49 rendered); scanner: `angularjs-csti-scanner`.
- [ ] **ASP.NET with XSS protection** → deprioritize XSS, hit other classes first.
