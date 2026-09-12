# Wordlists & Payloads

## Content discovery
- SecLists `Discovery/Web-Content/` — `raft-large-*`, `directory-list-2.3`, `common.txt`.
- `Assetnote` wordlists (`httparchive_*`, `apiroutes`) — modern, high-signal.
- API: `SecLists/.../api/`, `kiterunner` routes (`routes-large.kite`).
- Backups/config: `raft-*-files`, custom `.bak .old .zip .sql .env .git`.

## Subdomain brute
- SecLists `Discovery/DNS/` — `subdomains-top1million-*`, `n0kovo_subdomains`.
- Resolvers: fresh trusted resolver list (update often).

## Params
- SecLists `Discovery/Web-Content/burp-parameter-names.txt`, Arjun's built-in.

## Payloads (SecLists `Fuzzing/` + PayloadsAllTheThings)
- `PayloadsAllTheThings/` — per-class payloads (SQLi, XSS, SSTI, SSRF, XXE, etc.).
- `SecLists/Fuzzing/` — polyglots, special chars, unicode.
- `Fuzzdb` — attack patterns, known files.

## Custom / self-built
- Target-specific wordlist: mine JS + historical URLs + response bodies, dedupe (`anew`), feed back.
- Tailor extensions to the fingerprinted stack (PHP→`.php .phtml`, ASP→`.aspx .asmx`).

## Aggregated / high-signal packs
- **OneListForAll** (`onelistforallmicro/short`) — merged content-discovery superlist.
- **Assetnote** `wordlists.assetnote.io` — `httparchive_*`, `apiroutes`, `swagger` (kept fresh from real traffic).
- **bug-bounty-wordlists** (chvancooten), **fuzzdb**, **jhaddix all.txt / content_discovery_all**.
- **API/GraphQL:** `kiterunner` `.kite` routes, `graphql` field/introspection lists, `swagger`/`openapi` path packs.
- **Params:** `Arjun` built-in, `SecLists burp-parameter-names`, `x8` params.

## Class-specific payload sets (reusable Intruder/Match&Replace lists)
- **ID-tamper wrappers** (`01-access-control/02`, methods 1–40) + **price-tamper values** (`02-business-logic/01`).
- **JSON auth-shape mutations** (`04-auth-session/08`) — type-confusion/`$ne`/null/malformed/proto-pollution.
- **SSRF bypass IPs/encodings** (`03-injection/06`, `09-advanced/06`) + **cloud-metadata URL pack**.
- **Open-redirect & host-header bypass matrix** (`05-client-side/05`, `09-advanced/09`).
- **403/401 path-bypass permutations** (`10-server-edge/04`) — feed `byp4xx`.
- **Unkeyed cache headers** (`X-Forwarded-*`, etc.) for Param Miner (`10-server-edge/03`).
- **Unicode/normalization confusables** (`09-advanced/04`) — homoglyphs, NFKC-collapsing chars, zero-width.
- **SSTI/deserialization fingerprint polyglots** (`03-injection/03`, `03-injection/08`).
- **LLM jailbreak / injection corpora** (garak/promptmap sets, unicode-tag smuggling) (`11-ai-llm/01`).

## Note
Build a **target-specific** list every engagement: mine JS + historical URLs + response bodies, `anew`-dedupe, tailor extensions to the fingerprinted stack, feed back into fuzzers.
