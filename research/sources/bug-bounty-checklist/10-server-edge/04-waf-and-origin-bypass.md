# WAF & Origin-IP Bypass

**What it is:** The WAF/CDN sits in front. Reach the origin directly (skip WAF) or bypass WAF inline → your payloads land.

## Find the origin IP (bypass CDN entirely)
- [ ] Historical DNS: SecurityTrails, `crt.sh`, DNSDumpster — pre-CDN A records.
- [ ] SPF/MX/mail records often point at real infra (`_spf`, mail subdomain).
- [ ] Favicon hash → Shodan `http.favicon.hash:<h>` finds the naked origin.
- [ ] `nrich`/Shodan/Censys for the cert (SAN) on raw IPs.
- [ ] Subdomains not proxied (`dev`, `origin`, `direct`, `mail`, `ftp`) resolve to real IP.
- [ ] Server-side request (SSRF/webhook/PDF) leaks the origin IP back to you.
- [ ] Verify: `curl -H 'Host: target.com' http://<origin-ip>/` returns the app → WAF bypassed.

## Bypass WAF inline (when you can't skip it)
- [ ] Case/encoding: `SeLeCt`, URL/double-URL/unicode/hex, `%2553` double-encode.
- [ ] Whitespace/comment: `/**/`, `%09 %0a %0c %a0`, `+`, nested `/*!50000...*/`.
- [ ] Payload splitting across params (HPP) so no single value trips a rule.
- [ ] Content-type swap (JSON↔XML↔form) — WAF inspects one, app parses another.
- [ ] Chunked / oversized body — WAF skips inspection past a size limit.
- [ ] JSON tricks: unicode-escaped keywords `SELECT`, extra whitespace, nesting.
- [ ] Header-based delivery (payload in `X-Forwarded-For`, `Referer`, `User-Agent`).
- [ ] HTTP/2 / smuggling to slip past an HTTP/1 WAF (see `02`).
- [ ] Path confusion so the WAF rule (bound to `/api`) misses (`/API`, `//api`, `/./api`).
- [ ] Null byte / overlong UTF-8 to break the rule tokenizer.
- [ ] Bypass IP allowlist/rate-limit with `X-Forwarded-For` spoof (see `07-api/04`).

## Fingerprint the WAF
`wafw00f target.com` → tailor bypass to Cloudflare / Akamai / Imperva / AWS WAF / F5.

## Impact
Reaching the origin re-enables every server-side bug the WAF was masking (SQLi, RCE, SSRF). Direct origin access can itself be a finding.

## Report notes
Show the payload blocked via the WAF and succeeding via origin/bypass. For origin exposure, show the app responding on the raw IP with the correct `Host`.

## Deep cuts — more origin-find paths & inline evasion
- [ ] **Origin discovery expanded:** Censys/Shodan cert-SAN search on raw IPs, scan the org's cloud IP ranges (`asnmap`→`naabu`) sending the real `Host`+SNI and diffing the app response, GitHub/code search for hardcoded IPs, `_spf`/`_dmarc`/`mail`/`autodiscover` records, staging/`origin`/`direct`/`api-origin` unproxied subdomains, and SSRF/webhook/PDF-render leaking the egress/origin IP back to you.
- [ ] **Confirm + weaponize origin:** `curl -H 'Host: target.com' --resolve target.com:443:<origin> https://target.com/` — if the app answers and **Authenticated Origin Pulls / mTLS / IP-allowlist-to-CDN is missing**, every WAF-masked bug (SQLi/RCE/SSRF/rate-limit) is back in play. Missing origin lockdown is itself reportable.
- [ ] **Inline WAF evasion matrix:** best-fit/overlong/double unicode, SQL/HTML comment injection, JSON-unicode-escaped keywords, chunked or >inspection-limit body, content-type swap (JSON↔XML↔form↔multipart, `09-advanced/04`), HPP payload splitting, header-delivered payloads, HTTP/2 or smuggling past an HTTP/1 WAF (`02`), and path-case/`//`/`/./` so a route-bound rule misses.
- [ ] **Rule-scope gaps:** WAF applied to `POST` not `PUT`, to `/api` not `/API`, to body not query (or vice-versa), or bypassed on a non-proxied subdomain/legacy path.
- [ ] **Rate-limit/IP-allowlist bypass:** `X-Forwarded-For`/`CF-Connecting-IP` spoof if the origin trusts them post-CDN (`07-api/04`).
- [ ] **Cloudflare specifics:** resolve via `1.1.1.1` vs authoritative, check for `__cf` origin leaks, and Cloudflare-only headers (`cf-ray`) absent on the origin = you're through.

## Tools
`wafw00f`, `byp4xx`, Shodan/Censys, SecurityTrails, `asnmap`+`naabu`, `favicon-hash`, `nuclei`.
