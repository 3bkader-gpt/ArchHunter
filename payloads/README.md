# 🎯 Payloads, Wordlists & Pattern Hub

This directory contains targeted wordlists, reverse-proxy bypass headers, and GF regex patterns tailored for high-signal bug bounty hunting.

---

## 📁 Directory Structure

```
payloads/
├── README.md                 # This index and usage manual
├── headers/
│   └── 403_bypass_headers.txt # 5,865 reverse-proxy & gateway bypass headers
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

## 2. GF Regex Patterns (`gf_patterns/`)

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
