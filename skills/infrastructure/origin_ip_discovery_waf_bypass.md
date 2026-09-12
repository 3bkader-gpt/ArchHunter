# Mechanism: Origin IP Discovery & WAF/CDN Bypass

## 1. Architectural Vulnerability Profile
*   **Vulnerability Class:** Direct Origin Exposure / Perimeter Bypass
*   **STRIDE Category:** Elevation of Privilege, Information Disclosure
*   **Trust Boundary Crossed:** Public Internet $\rightarrow$ Cloud WAF/CDN (Cloudflare/Akamai/AWS CloudFront) $\rightarrow$ Internal Origin Web Server
*   **Target Architectures:** Any web architecture placing a Reverse Proxy or CDN in front of an origin server without strict IP allowlisting (Security Groups / Ingress Rules).

---

## 2. Core Discovery Mechanisms

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                    منهجية كشف السيرفر الحقيقي (Origin IP) وتخطي الـ WAF           │
├─────────────────────────┬─────────────────────────────────────────────────────────┤
│ 1. Favicon Hash         │ • حساب MurmurHash3 لأيقونة الموقع والبحث في Shodan/Censys│
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 2. SSL Cert Archaeology │ • استعلام شهادات TLS التاريخية عبر Censys و SecurityTrails│
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 3. Subdomain CNAME Leak │ • فحص نطاقات البريد والسيرفرات المساعدة (mail, direct, vpn) │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 4. Outbound Connection  │ • إجبار السيرفر على الاتصال الخارجي عبر SSRF/Webhook     │
├─────────────────────────┼─────────────────────────────────────────────────────────┤
│ 5. Host Validation      │ • التحقق المباشر بإرسال Host Header للـ IP المكتشف      │
└─────────────────────────┴─────────────────────────────────────────────────────────┘
```

### 1. Favicon Hash Calculation (MurmurHash3)
*   Websites using custom `favicon.ico` often serve the exact same binary on the origin server as well as the CDN.
*   **Calculation Script:**
    ```python
    import mmh3, requests, codecs
    response = requests.get('https://target.com/favicon.ico', verify=False)
    favicon_b64 = codecs.encode(response.content, 'base64')
    hash_val = mmh3.hash(favicon_b64)
    print(f"Shodan Dork: http.favicon.hash:{hash_val}")
    print(f"Censys Dork: services.http.response.favicons.md5_hash:{hash_val}")
    ```

### 2. Historical SSL/TLS Certificate Mapping
*   Prior to enabling Cloudflare or when renewing SSL certificates, origin servers frequently generate direct TLS handshakes containing the domain name.
*   **Censys Search:**
    ```text
    services.tls.certificates.leaf_data.subject.common_name: "target.com" and not services.software.name: "Cloudflare"
    ```
*   **ViewDNS / SecurityTrails:**
    Inspect historical A records for IP addresses hosting the application before CDN onboarding.

### 3. Peripheral Subdomain Leaks
*   Subdomains not routed through the CDN proxy:
    *   `mail.target.com`, `smtp.target.com`, `mx.target.com`
    *   `direct.target.com`, `origin.target.com`, `cpanel.target.com`
    *   `vpn.target.com`, `dev.target.com`, `staging.target.com`

### 4. Outbound Interaction Leaks (SSRF / Webhook Callbacks)
*   If the application features:
    *   Avatar URL fetcher (`POST /api/user/avatar-url`)
    *   Webhook integrations (`POST /api/webhooks/test`)
    *   PDF generators (`POST /api/invoice/generate`)
*   Supply your Burp Collaborator or VPS address (`http://attacker.com/listen`). The incoming HTTP/DNS request reveals the **true outbound Origin IP**.

---

## 3. Origin Verification & Exploitation

### How to Verify the Discovered IP:
Send an HTTP request directly to the raw IP address with the target's original `Host` header:

```bash
# Direct TLS connection with Host header injection:
curl -s -k -H "Host: target.com" "https://<DISCOVERED_IP>/" -I

# Compare response title and content length with the live CDN:
curl -s "https://target.com/" -I
```

### Weaponized Impact of Origin Access:
1. **Zero WAF Protection:** SQLi, XSS, and RCE payloads reach backend parsers completely uninspected.
2. **No Rate Limiting:** Brute-force logins, OTPs, and password reset endpoints without IP bans.
3. **Internal Routing Exposure:** Access `/admin`, `/actuator/health`, `/metrics`, or debugging dashboards blocked at the Cloudflare layer.

---

## 4. Remediation & Defense
1. **Cloudflare Authenticated Origin Pulls (AOP):** Require client certificates from Cloudflare for every connection to origin.
2. **Ingress Firewall Allowlisting:** Restrict origin firewall (AWS Security Group / iptables) to allow incoming traffic *only* from verified CDN IP ranges.
3. **Do Not Expose Origin on Default Ports:** Block direct access to origin port 80/443 from non-CDN CIDRs.
