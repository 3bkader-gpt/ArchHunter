# Tech Fingerprinting

**What it is:** Identifying the stack (server, framework, CMS, WAF, libs, versions) so you pick attacks that actually apply.

## Checklist
- [ ] HTTP headers: `Server`, `X-Powered-By`, `X-AspNet-Version`, `Via`, `X-Generator`.
- [ ] Cookies: `PHPSESSID`, `JSESSIONID`, `laravel_session`, `connect.sid`, `_rails_session`.
- [ ] Framework tells: error pages, 404 style, favicon hash (`shodan`), JS bundle names.
- [ ] CMS: WordPress (`/wp-json`, `/wp-content`), Drupal (`/CHANGELOG.txt`), Joomla.
- [ ] CDN/WAF: Cloudflare, Akamai, Imperva, AWS WAF (affects payload encoding + rate).
- [ ] Version → known CVEs (`nuclei`, `searchsploit`, vendor advisories).
- [ ] Favicon hash pivot: `curl favicon | md5` → search Shodan `http.favicon.hash`.

## Tools
`whatweb`, `wappalyzer`, `nuclei -t technologies`, `httpx -tech-detect`, `retire.js` for JS libs.

## Favicon hash pivot (find origin / siblings)
```bash
curl -s https://target.com/favicon.ico | \
  python3 -c 'import sys,mmh3,codecs;print(mmh3.hash(codecs.encode(sys.stdin.buffer.read(),"base64")))'
# → Shodan  http.favicon.hash:<value>   /  FOFA  icon_hash="<value>"
```
Same favicon on a bare IP = the origin behind the CDN → `04-waf-and-origin-bypass.md`.

## Version → exploit workflow
- [ ] `nuclei -tags tech,cve -l live.txt` — tech detect + known-CVE match in one pass.
- [ ] `retire.js` / `nuclei -tags exposure` on JS libs for vulnerable frontend deps.
- [ ] Map the exact version to advisories; note EOL frameworks (unpatched by definition).
- [ ] `cdncheck` to separate CDN-fronted from direct-origin hosts (changes rate + payload strategy).

## Deep cuts — fingerprint what the headers hide
- [ ] **WAF identification:** `wafw00f -a target.com` → names the WAF (Cloudflare/Akamai/Imperva/F5/AWS) so you pick the right encoding + rate strategy (`10-server-edge/04`).
- [ ] **TLS fingerprint (JARM/JA3S):** `jarm target.com:443` clusters servers by TLS stack — same JARM on a bare IP as the CDN-fronted host = candidate origin. JA3S/`ja4` also distinguishes real origin from WAF edge.
- [ ] **HTTP/2 + ALPN + header-order tells:** `curl -sI --http2`; frameworks emit distinctive header casing/order and pseudo-header handling. `nghttp -nv` for h2 settings fingerprint.
- [ ] **Error-forcing for stack leaks:** send malformed JSON, oversized cookie, bad `Content-Type`, array where scalar expected → stack traces name the framework + version (Rails, Django `DEBUG`, .NET YSOD, Laravel Ignition, Express default error).
- [ ] **Framework version-leak paths:** WordPress `/readme.html` + `/wp-json` (`generator`), Drupal `/CHANGELOG.txt`, Joomla `/administrator/manifests/files/joomla.xml`, Next.js `/_next/static/.../_buildManifest.js`, Angular `runtime.*.js`, Vite `@vite/client`.
- [ ] **Cloud/origin tells:** `Server: AmazonS3`, `x-amz-*`, `x-goog-*`, `x-azure-ref`, `x-served-by`(Fastly), `x-cache`, `x-vercel-id`, `via: 1.1 varnish` → routes you toward the right cache/edge attacks.
- [ ] **Language/runtime from cookies + timing:** session cookie name → language; response timing + `Date` header skew can hint at load-balanced multi-origin.
- [ ] **CDN vs origin split:** `cdncheck`/`asnmap` to label each host; a same-cert host on a non-CDN ASN is the origin (`10-server-edge/04`).

## Why it matters
A `.NET` viewstate, a Rails app, and a WordPress site have completely different bug classes. Fingerprint first so you are not fuzzing SQLi into a static S3 site. The version you find here is the shortlist of CVEs you test next. WAF + TLS fingerprint decide *how* you send the payload; framework + version decide *which* payload.
