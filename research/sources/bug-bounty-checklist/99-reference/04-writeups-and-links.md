# Writeups, Checklists & References

## Source checklists (compiled into this repo)
- m0chan Bug Bounty Cheatsheet — https://blog.m0chan.co.uk/2019/12/17/Bug-Bounty-Cheetsheet.html
- HackMD checklist — https://hackmd.io/YX-Oz5YLQUSPvRChlUdZxw
- sehno Bug-bounty checklist — https://github.com/sehno/Bug-bounty/blob/master/bugbounty_checklist.md
- shubhdhungana bug_bounty_checklist — https://github.com/shubhdhungana/bug_bounty_checklist
- HackWithSingh checklist — https://checklist.hackwithsingh.com/
- AnLoMinus Bug-Bounty — https://github.com/AnLoMinus/Bug-Bounty
- gigachad80 Checklist — https://github.com/gigachad80/Checklist/blob/main/CHECKLIST.md
- hariprasaanth Web App Pentesting Checklist — https://hariprasaanth.notion.site/WEB-APPLICATION-PENTESTING-CHECKLIST-0f02d8074b9d4af7b12b8da2d46ac998
- cyber_dark Bug Bounty Web Checklist — https://medium.com/@cyber_dark/bug-bounty-web-checklist-0949ab394915
- InfosecWriteups methodology/toolkit — https://infosecwriteups.com/bug-bounty-hunting-methodology-toolkit-tips-tricks-blogs-ef6542301c65

## Case studies referenced in the class files
- Parameter tampering → product price manipulation — https://www.youtube.com/watch?v=3VMlV7j_yzg  (`02-business-logic/01`)
- Semrush Academy exam-result tampering (JSON `"1"`=true) — (`02-business-logic/08`)
- Profile IDOR vs SQLi (id 1001→1089 authz bug scanners miss) — (`01-access-control/01`)
- Shopping-cart payment-gate bypass (business logic) — (`02-business-logic/02`)
- App-layer auth-flag / ACL privilege escalation — (`01-access-control/03`, `02-business-logic/08`)
- Zoom session takeover ($15k): cookie tossing + cookie-nonce CSP XSS + OAuth dirty dancing + permission hijack + WAF-DoS — https://nokline.github.io/bugbounty/2024/06/07/Zoom-ATO.html (`04-auth-session/07`, `05-client-side/06`)
- Ultimate Double-Clickjacking PoC (bypasses XFO/frame-ancestors/SameSite) — https://jorianwoltjer.com/blog/p/research/ultimate-doubleclickjacking-poc (`05-client-side/03`)
- CSP Bypass Techniques (payload catalog) — https://github.com/bhaveshk90/Content-Security-Policy-CSP-Bypass-Techniques and https://hacktricks.wiki/en/pentesting-web/content-security-policy-csp-bypass/ (`05-client-side/06`)
- Clickjacking 2.0 / UI redressing in SPAs (2025) — https://instatunnel.my/blog/doubleclickjacking-modern-ui-redressing-attacks-explained (`05-client-side/03`)
- Session hijack via chained attack ($2500), therceman — https://infosecwriteups.com/bug-bounty-writeup-2500-reward-for-session-hijack-via-chained-attack-2a4462e01d4d (`04-auth-session/07`)

## Technique refresh (2024–2025, applied class-by-class)
- BOLA taxonomy (100+ disclosures), UUID/encoded-ID + GraphQL global-ID patterns — arxiv 2605.25865; Oboe "Advanced IDORs" (`01-access-control/01`)
- jsluice AST JS mining (Bishop Fox); ReconFTW JS module; katana `-jsl` (`00-recon/05`, `00-recon/03`)
- 2025 recon pipeline / thexrecon / reconftw — amrelsagaei Methodology-2025 (`00-recon/02`)
- SSRF vs IMDSv2 + ECS task-role creds (169.254.170.2) — HackTricks Cloud SSRF; Hacking-the-Cloud EC2 metadata SSRF; F5 Labs 2025 campaign (`03-injection/06`)
- mXSS/DOMPurify bypass — PortSwigger "Bypassing DOMPurify again with mutation XSS"; DOM clobbering — LazyHackers; WAFFLED parser-discrepancy WAF bypass — arxiv 2503.10846 (`03-injection/02`, `03-injection/01`)
- Deserialization gadget chains (Java ysoserial, PHP phpggc/phar, pickle, .NET ViewState/Json.NET) — PayloadsAllTheThings; Google Cloud "Hunting Deserialization Exploits"; SharePoint CVE-2025-53770/53771 (`03-injection/08`)
- GraphQL advanced (alias overloading DoS, batching brute, directive/CSRF, clairvoyance schema recovery) — escape.tech batch attacks; HackTricks GraphQL (`07-api/02`)
- CSWSH / WebSocket testing — PortSwigger CSWSH Academy; OWASP WSTG (`05-client-side/07`)
- Advanced DOM clobbering + DOMPurify `cid:`/`IN_PLACE`/attributes bypass — terjanq "Clobbering the clobbered"; Kévin Mizu mizu.re DOMPurify series (`05-client-side/08`)
- Host header injection (reset poisoning, cache, routing) — PortSwigger Host header Academy (`09-advanced/09`)

## New-class references (added 2025)
- **SAML** XSW1–8 / signature exclusion / comment-injection NameID (CVE-2017-11427 class) — PortSwigger SAML, Duo "Duo Finds SAML Vulnerabilities", SAML Raider, epi052 jwt/saml notes (`04-auth-session/10`).
- **gRPC / gRPC-Web / protobuf** — grpcurl reflection, `protoc --decode_raw`/protoscope, gRPC-Web Burp extension, "Hacking gRPC" (`07-api/06`).
- **Web LLM / AI** — OWASP LLM Top 10 + OWASP Agentic (ASI01–ASI10), PortSwigger "Web LLM attacks" Academy, Embrace-the-Red (markdown-image exfil, ASCII smuggling), Simon Willison prompt-injection series (`11-ai-llm/01`).
- **XS-Leaks** — xsleaks.dev wiki (oracles: timing, frame-count, cache, error events) (`09-advanced/11`).
- **Client-Side Path Traversal (CSPT)** — Doyensec CSPT research, "CSPT2CSRF" (Maxence Schmitt), PortSwigger notes (`09-advanced/12`).
- **HTTP desync 2024-25** — James Kettle "HTTP/1 must die" + client-side desync + browser-powered smuggling (`10-server-edge/02`).

## Standing references
- OWASP Web Security Testing Guide (WSTG); OWASP API Security Top 10; OWASP LLM Top 10 + Agentic Security (ASI).
- PortSwigger Web Security Academy (free labs per class).
- PayloadsAllTheThings (payloads per vuln) — github.com/swisskyrepo/PayloadsAllTheThings.
- HackTricks (technique encyclopedia); xsleaks.dev; can-i-take-over-xyz.
- HackerOne / Bugcrowd public disclosed reports (hacktivity) — pattern mine by class.

## Personal tooling (this box)
- pathfinder (`~/scripts`) — JS mining + soft-404 + anti-ban path discovery.
- sqli_hunter.py (`~/scripts`) — anti-ban + false-positive reduction.
- smuggler (`~/scripts`) — CL.TE/TE.CL/TE.TE + CRLF, timing-based detection.
- See recon env constraints memory before running network-heavy tooling.
