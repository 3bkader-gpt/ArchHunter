# Tools Arsenal

## Recon
| Tool | Use |
|------|-----|
| `amass`, `subfinder`, `assetfinder` | subdomain enum |
| `puredns`, `shuffledns`, `dnsx` | resolve / brute DNS |
| `httpx` | probe live hosts, tech, cname, status |
| `asnmap`, `whois` | ASN → CIDR, org intel |
| `katana`, `hakrawler`, `gospider` | crawl |
| `gau`, `waybackurls`, `urlfinder` | historical URLs |
| `crt.sh`, `censys`, `shodan`, `fofa` | passive datasets |
| `dnsgen`, `gotator`, `altdns` | permutations |

## Content / param discovery
| `ffuf`, `feroxbuster` | dir/file brute |
| `arjun`, `x8`, `paramspider` | hidden params |
| `git-dumper` | dump exposed `.git` |
| pathfinder (`~/scripts`) | JS mining + soft-404 + anti-ban path discovery |

## JS / secrets
| `linkfinder`, `xnLinkFinder`, `jsluice` | endpoints from JS |
| `sourcemapper`, `getjs` | pull/rebuild JS |
| `trufflehog`, `gitleaks`, `secretfinder` | secret hunting |
| `retire.js` | vulnerable JS libs |

## Proxy / core
| Burp Suite (+ **Autorize, AuthMatrix, Turbo Intruder, Param Miner, InQL, DOM Invader, HTTP Request Smuggler, Collaborator**) | main workbench |
| `mitmproxy`, `caido` | alt proxies |

## Injection / exploitation
| `sqlmap`, `ghauri`, `~/scripts/sqli_hunter.py` | SQLi (last one: anti-ban + FP reduction) |
| `dalfox`, `XSStrike`, `kxss` | XSS |
| `tplmap`, `SSTImap` | SSTI |
| `commix` | command injection |
| `XXEinjector` | XXE |
| `SSRFmap`, `gopherus` | SSRF |
| `nosqlmap` | NoSQL |
| `jwt_tool`, `hashcat` | JWT forge/crack |
| `~/scripts` smuggler | CL.TE/TE.CL/TE.TE + CRLF (timing detect) |

## Scanning / templates
| `nuclei` | templated vuln/CVE/exposure/takeover scan |
| `subjack`, `subzy` | subdomain takeover |
| `interactsh` | OOB (DNS/HTTP) callbacks |
| `graphw00f`, `clairvoyance`, `graphql-cop` | GraphQL |
| `fuxploider` | file upload |

## Fingerprint / edge / new-class tooling
| Tool | Use |
|------|-----|
| `wafw00f`, `jarm`, `nuclei -tags tech,cve` | WAF / TLS / stack fingerprint (`00-recon/04`) |
| `dnsReaper`, `nuclei -t takeovers` | subdomain takeover (best signal) (`08-infra/01`) |
| `web-cache-vulnerability-scanner` (wcvs), Param Miner | cache poisoning/deception (`08-infra/03`, `10-server-edge/03`) |
| `h2csmuggler`, `smuggler.py`, Burp HTTP Request Smuggler, Turbo Intruder | smuggling / desync / races (`08-infra/02`, `10-server-edge/02`, `02-business-logic/07`) |
| `wsrepl`, `websocat`, `wscat` | WebSocket / CSWSH (`05-client-side/07`) |
| `ppmap`, `pp-finder`, DOM Invader | prototype pollution + DOM clobbering (`09-advanced/02`, `05-client-side/08`) |
| **SAML Raider** (Burp), `xmlsec1`, SAML-tracer | SAML XSW / sig-strip (`04-auth-session/10`) |
| `grpcurl`, `protoscope`, `protoc --decode_raw`, `pbtk`/`protodump` | gRPC / protobuf (`07-api/06`) |
| `garak`, `promptmap`, unicode-tag encoder | LLM/prompt-injection fuzzing (`11-ai-llm/01`) |
| `singularity`, `rbndr`/`nip.io`/`sslip.io` | DNS rebinding (`09-advanced/06`) |
| `noseyparker`, `mantra` | fast secret scanning (history / JS) (`08-infra/04`, `00-recon/05`) |
| `byp4xx` | 403/401 bypass matrix (`01-access-control/04`, `10-server-edge/04`) |
| `caido` | modern proxy (Burp alternative) |
| `apktool`, `jadx`, `frida`, `objection`, `MobSF` | mobile (deep-link scope, API extraction) (`00-recon/01`) |

## Wordlists → see `02-wordlists.md`
