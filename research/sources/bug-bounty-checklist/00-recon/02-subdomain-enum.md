# Subdomain Enumeration

**What it is:** Finding every host under the in-scope apex/wildcard. More hosts = more surface. Forgotten/dev/staging subdomains are gold.

## Passive (no packets to target)
- [ ] Certificate transparency: `crt.sh`, `cert.sh`, censys.
- [ ] Aggregators: `subfinder`, `amass enum -passive`, `assetfinder`.
- [ ] `chaos` (ProjectDiscovery dataset), `github-subdomains`, `gau`/`waybackurls` hostnames.
- [ ] VirusTotal / SecurityTrails / Shodan / FOFA host graphs.

## Active
- [ ] DNS brute force: `puredns bruteforce` with a big wordlist + resolvers.
- [ ] Permutations: `dnsgen` / `altdns` / `gotator` on known subs, re-resolve.
- [ ] VHost brute force against known IPs (`ffuf -H "Host: FUZZ.example.com"`).
- [ ] Resolve all → live check with `httpx` (status, title, tech, CDN, CNAME).

## Chain
```bash
subfinder -d example.com -all -silent | anew subs.txt
amass enum -passive -d example.com | anew subs.txt
puredns resolve subs.txt -r resolvers.txt | anew resolved.txt
httpx -l resolved.txt -sc -title -tech-detect -cname -o live.txt
```

## Watch for
- Dangling CNAMEs → subdomain takeover (see `08-infra/01-subdomain-takeover.md`).
- Wildcard DNS → filter false positives with a random-sub baseline.
- Staging/dev/uat/internal hosts → weaker auth, debug endpoints.

## 2025 pipeline (layered, cross-validated)
```bash
# passive fan-out → resolve → live → permute → re-resolve
subfinder -d target.com -all -recursive -silent | anew subs.txt
amass enum -passive -d target.com | anew subs.txt
github-subdomains -d target.com | anew subs.txt
puredns resolve subs.txt -r resolvers.txt --write resolved.txt
gotator -sub resolved.txt -perm words.txt -depth 2 -numbers 5 | puredns resolve -r resolvers.txt | anew resolved.txt
httpx -l resolved.txt -sc -title -tech-detect -cname -ip -location -o live.txt
```
- [ ] **Custom permutation words:** build `words.txt` from the target's own subdomain tokens (`dev api stg uat internal admin v2 eu`) — generic wordlists miss org-specific naming.
- [ ] **TLS SAN + CT firehose:** `tlsx -san -cn -l resolved.txt` and `github.com/hakluke/hakip2host` on owned IPs to reverse hostnames.
- [ ] **Cross-validate:** union results from ≥3 sources; a host only one tool finds is worth manual confirm.
- [ ] **Wildcard filtering:** baseline a random-sub response; `puredns`/`dnsx` wildcard mode strips the false positives.
- [ ] **Automation frameworks:** `reconftw` / `thexrecon` chain all of the above; good for breadth, still hand-review the interesting hosts.

## Deep cuts — sources & tricks beyond the standard fan-out
- [ ] **PTR reverse sweep on owned CIDR:** `dnsx -ptr -l cidr_ips.txt -resp-only` — reverse DNS often names internal/staging hosts brute-forcing never hits.
- [ ] **Analytics-ID → domain pivot** (see `01-scope`): shared `G-`/`pub-` IDs surface sibling hosts on unrelated apex names.
- [ ] **`abuse.ch`, `virustotal`, `alienvault OTX`, `urlscan.io` graphs:** query domain → related hosts/IPs/subdomains from real traffic, not just CT.
- [ ] **SNI/vhost confirmation:** a wildcard cert covers `*.corp.target.com` but DNS resolves nothing — brute the `Host:`/SNI against the fronting IP (`ffuf -H Host:` / `httpx -sni`) to reach unlisted vhosts.
- [ ] **NSEC3 zone walking** for DNSSEC-signed zones (`nsec3walker`, `ldns-walk`) — full record dump, zero brute.
- [ ] **Recursive CT + apex permutation:** feed found subs back into `crt.sh` wildcard queries; `%.dev.target.com` etc. catches nested tiers.
- [ ] **Split-horizon leaks:** internal hostnames leak in `wayback`/`gau` URLs, JS config, email headers, and PDF/Office metadata — grep collected URLs for `.internal`, `.corp`, `.local`, `10.`, `192.168.`.
- [ ] **Cloud DNS zones:** enumerate Route53/Azure DNS/GCP zones tied to the org's cloud accounts (`cloud_enum`), and check `_domainkey`, `_dmarc`, `autodiscover`, `enterpriseenrollment` service records.
- [ ] **Favicon/JARM host clustering:** group all live IPs by favicon hash + JARM (`04-fingerprinting`) to find origin siblings sharing a build.

## Tools
`subfinder`, `amass`, `assetfinder`, `puredns`, `dnsx` (`-ptr`), `tlsx`, `httpx`, `dnsgen`, `gotator`, `shuffledns`, `github-subdomains`, `hakip2host`, `nsec3walker`, `reconftw`, `certstream`, `urlscan`/OTX APIs.
