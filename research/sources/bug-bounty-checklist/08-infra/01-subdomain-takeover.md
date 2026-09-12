# Subdomain Takeover

**What it is:** A subdomain's DNS points (CNAME/A) to a de-provisioned third-party resource you can re-claim → you serve content on the target's subdomain.

## Test steps
- [ ] From enum, list all CNAMEs (`httpx -cname`, `dnsx -cname`).
- [ ] Flag CNAMEs to services with claimable resources (S3, GitHub Pages, Heroku, Azure, Fastly, Shopify, Netlify, Surge, Cargo, Tumblr, Zendesk, Unbounce, Readme, Webflow, WPEngine).
- [ ] Fingerprint the takeover: signature error page ("NoSuchBucket", "There isn't a GitHub Pages site here", "no such app").
- [ ] Claim the resource on that provider and serve a proof file.
- [ ] Dangling A records / expired NS delegations too.
- [ ] Dangling CloudFront distributions.

## Confirm
`nuclei -t takeovers`, `subzy`, `subjack`, then manual claim of a benign `takeover-proof.txt`.

## Impact
Full control of a target subdomain: phishing, cookie theft (parent-domain cookies), OAuth redirect abuse, CORS trust abuse, bypass CSP allowlists.

## Report notes
Serve a unique proof file on the claimed subdomain (do not host malicious content). Screenshot the DNS chain + your controlled response. Remove your claim after triage if asked.

## 🎯 PoC — Request → Response (dangling S3 CNAME)

`assets.target.com` CNAMEs to a deleted bucket:
```http
GET / HTTP/1.1
Host: assets.target.com
```
```http
HTTP/1.1 404 Not Found
Content-Type: application/xml
Server: AmazonS3

<Error><Code>NoSuchBucket</Code>
<Message>The specified bucket does not exist</Message></Error>
```
`NoSuchBucket` fingerprint = claimable. Register the bucket name, upload proof:
```http
GET /takeover-proof.txt HTTP/1.1
Host: assets.target.com
```
```http
HTTP/1.1 200 OK
Server: AmazonS3

owned-by-researcher-<handle>      ← you now control the subdomain
```

## Deep cuts — takeover types past the classic CNAME
- [ ] **NS delegation takeover:** a subdomain delegated (`NS`) to a nameserver/zone no longer registered on the provider → claim the zone, control *all* records under it (higher impact than one CNAME).
- [ ] **Dangling A → released cloud IP:** an `A` record to a de-provisioned EC2/EIP/VM; re-request IPs on that provider until you get it (IP reuse). Also dangling `AAAA`.
- [ ] **Dangling MX:** an `MX` to a deprovisioned mail provider → receive the target subdomain's email (reset tokens, invites) — often missed.
- [ ] **Second-order / provider-custom-domain:** the CNAME points to a live service (GitHub Pages, Netlify, Vercel, Shopify, Zendesk, Helpscout, Statuspage, Frontify, etc.) where a custom domain is **unclaimed** — add the domain to *your* account there and serve content. Check each provider's "custom domain not configured" state, not just NXDOMAIN.
- [ ] **Broken-link / JS hijacking:** a live page loads a script/CSS/img from an expired external domain → buy the domain, serve JS = stored XSS on the target origin (no DNS control needed). Grep collected JS/HTML for third-party hosts, check which are unregistered.
- [ ] **CDN alternate-domain claim:** dangling CloudFront/Fastly/Azure (`*.cloudfront.net`, `*.azureedge.net`, `trafficmanager.net`, `cloudapp.azure.com`, `azurewebsites.net`) where the alternate CNAME/CNAME-target is unclaimed.
- [ ] **Impact ladder:** parent-domain cookie set/steal (`04-auth-session/07`), CSP/`script-src` allowlist abuse (host JS on a trusted subdomain), CORS trust (`05-client-side/02`), OAuth `redirect_uri` allowlist (subdomain), and phishing on a real target subdomain.

## Tools
`subjack`, `subzy`, `dnsReaper` (best signal), `nuclei` takeover templates, `dnsx`, `can-i-take-over-xyz` fingerprint list.
