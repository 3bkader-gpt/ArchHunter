# Scope & Asset Discovery

**What it is:** Defining exactly what you are allowed to hit, then enumerating everything the target owns inside that boundary. Getting this wrong = wasted time or a ban.

## Where to look
- Program policy page: in-scope domains, out-of-scope traps, allowed test types, safe-harbor.
- ASN / IP ranges owned by the org (`whois`, BGP tools).
- Acquisitions — new companies often inherit old, weak infra.
- Cloud footprint: S3/GCS buckets, Azure blobs, CloudFront/Fastly distros.

## Checklist
- [ ] Read the full policy. Note explicit **out-of-scope** assets (record them so you never touch them).
- [ ] List apex domains and wildcard scopes (`*.example.com`).
- [ ] Pull ASN → CIDR ranges: `amass intel -asn <ASN>` / `whois -h whois.radb.net`.
- [ ] Reverse-whois on org name & registrant email for sibling domains.
- [ ] Find acquisitions (Crunchbase, Wikipedia) and check if they are in scope.
- [ ] Enumerate cloud assets (buckets, functions, container registries).
- [ ] Build a live-asset inventory (domain, IP, tech, owner-confidence) before testing.

## Advanced asset pivots
- [ ] **Favicon hash pivot:** `curl -s target/favicon.ico | python3 -c 'import sys,mmh3,codecs;print(mmh3.hash(codecs.encode(sys.stdin.buffer.read(),"base64")))'` → Shodan `http.favicon.hash:<h>` finds sibling infra sharing the icon (staging, origin behind CDN).
- [ ] **TLS SAN scrape:** pull cert Subject Alt Names from every live IP (`tlsx -san -cn`) → new in-scope hostnames.
- [ ] **Cloud enumeration:** `cloud_enum -k <org>` / `s3scanner` for S3/GCS/Azure blobs; `cf-check`/`cdncheck` to tag CDN vs origin.
- [ ] **ASN → CIDR automation:** `asnmap -d target.com | naabu -p 80,443,8080,8443 | httpx` to sweep owned ranges.
- [ ] **Acquisition graph:** re-run the whole pipeline on each acquired brand; new buys inherit legacy, unpatched infra.
- [ ] **GitHub org recon:** `github-subdomains`, `trufflehog github --org=<org>` for leaked hosts + secrets.

## Discipline
Keep a single source-of-truth inventory (CSV: host, IP, tech, CDN, owner-confidence, in/out-of-scope). Tag out-of-scope explicitly so automation never touches it. Re-screenshot the policy each session.

## Tools
`amass intel`, `whois`, `asnmap`, `naabu`, `tlsx`, `cdncheck`, `cloud_enum`, `s3scanner`, `crt.sh`, `chaos`, `github-subdomains`, `trufflehog`.

## Deep cuts — asset-graph pivots most hunters skip
- [ ] **Analytics/AdSense ID pivot:** pull `UA-`, `G-`, `GTM-`, `pub-` IDs from page source → `spyonweb.com`, `builtwith.com/relationships`, `dnslytics` reverse-analytics → sibling domains sharing the same tracking account (strong ownership signal for wide scopes).
- [ ] **Mobile deep-link scope:** fetch `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` → reveals in-scope universal-link paths, app bundle IDs, and associated API hosts. Deep-link paths often map to unauth'd or weakly-checked handlers.
- [ ] **Passive DNS history:** `securitytrails`, `dnsdb`, `viewdns` → old A records expose origin IPs before the CDN was added (origin-bypass seed for `10-server-edge/04`).
- [ ] **DNSSEC NSEC/NSEC3 walking:** if the zone is signed, `ldns-walk @ns target.com` / `nsec3walker` enumerates records without brute force.
- [ ] **IPv6 sweep:** orgs firewall v4 and forget v6 — resolve `AAAA`, scan the /64, hosts often unfiltered.
- [ ] **SPF/DMARC/MX mining:** `dig TXT` SPF `include:` chains list third-party senders + owned mail infra; DMARC `rua=` mailbox can leak an internal domain.
- [ ] **CT-log live monitor:** subscribe to `certstream`/`crt.sh` for the apex → catch new subdomains the moment a cert is issued (first-mover on fresh deploys).
- [ ] **RDAP over legacy WHOIS:** `rdap.org/domain/target.com` gives structured registrant + related-entity data that whois rate-limits/redacts.
- [ ] **Reverse-image/logo & trademark search** for acquisitions the org hasn't publicly announced yet.

## Report notes
Always cite the scope line that makes the asset in-scope. Screenshot the policy at test time (policies change). For a pivoted asset (favicon/analytics/cert), state the ownership evidence chain so triage can't wave it off as out-of-scope.
