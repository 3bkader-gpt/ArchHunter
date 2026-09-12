# TARGET ENGAGEMENT SESSION: [TARGET_NAME]

> **Target Domain:** `example.com`  
> **Engagement Date:** `YYYY-MM-DD`  
> **Platform / Program:** `HackerOne / Intigriti / Bugcrowd`  
> **Mandatory Header:** `X-HackerOne-Researcher: qalbaz_0x`

---

## 1. Scope & Rules of Engagement

### In-Scope Assets
- `*.example.com`
- `api.example.com`
- `auth.example.com`

### Out-of-Scope Assets & Actions
- `blog.example.com` (Third-party hosted)
- No Denial of Service (DoS) or volume brute-forcing.
- No social engineering or physical attacks.

---

## 2. Accounts & Identity Matrix

| Role Label | Username / Email | Tenant / Org | Session Identifier / Profile |
|---|---|---|---|
| **ADMIN** | `admin_user@wearehackerone.com` | Org A (Primary) | Browser Profile 1 / Context A |
| **MEMBER** | `member_user@wearehackerone.com` | Org A (Primary) | Browser Profile 2 / Context B |
| **TENANT_B** | `tenant_b@wearehackerone.com` | Org B (Secondary) | Browser Profile 3 / Context C |
| **ANONYMOUS** | *Unauthenticated* | N/A | Incognito / Clean curl |

---

## 3. 4-Phase Progress Tracker

- [ ] **Phase 1: Reconnaissance**
  - [ ] Passive Recon (ASN, WHOIS, Historical URLs)
  - [ ] Active Recon (Subfinder, DNSx, HTTPx)
  - [ ] JS Intelligence & Secrets Triage
- [ ] **Phase 2: Mapping & Architecture Inference**
  - [ ] Burp Suite Passive Crawling & Workflow Mapping
  - [ ] Run Reasoning Runtime (`go run cmd/runtime/main.go ...`)
  - [ ] Review `MachineReadableDFD.json` and Trust Boundaries
- [ ] **Phase 3: Vulnerability Analysis & Mechanism Auditing**
  - [ ] 8-Way Authorization Comparison Matrix (IDOR/BOLA)
  - [ ] Server-Side & Parser Auditing (SSRF, Smuggling)
  - [ ] Stateful & Race Auditing (Async workflows, WebSockets)
- [ ] **Phase 4: Exploitation & Impact**
  - [ ] Weaponized PoC verification
  - [ ] 10-Point Validation Gate passing
  - [ ] Report drafting & submission

---

## 4. Active Lead Tracking & Lifecycle

*Status values: `hypothesis` | `testing` | `likely` | `confirmed` | `rejected` | `duplicate` | `out-of-scope`*

| # | Lead / Mechanism | Affected Asset / Endpoint | Evidence & Observation | Expected Secure Behavior | Smallest Next Experiment | Impact / Severity | Status |
|---|---|---|---|---|---|---|---|
| 1 | *Example: IDOR on Invoice Download* | `GET /api/v1/invoices/1042/pdf` | Returns invoice of Org B when requested by Member Org A | Should return 403 Forbidden | Test with `PUT /api/v1/invoices/1042` to check write permissions | High (Cross-Tenant Financial Leak) | `testing` |
| 2 | *Example: CloudFront -> Nginx Smuggling* | `https://api.example.com/v1/` | H2 Frontend + H1.1 Backend detected | Strict RFC 7230 parser alignment | Send dual CL-TE probe with Burp Repeater | Critical (Request Smuggling / Cache Poisoning) | `hypothesis` |

---

## 5. Confirmed Findings (Ready for Report)

### Finding #1: [TITLE]
- **Vulnerability Class:** `Broken Object Level Authorization (BOLA)`
- **Affected Endpoint:** `https://api.example.com/v1/...`
- **CVSS Score:** `8.5 (High)`
- **10-Point Validation Gate:** `PASSED`
- **Minimal PoC:**
  ```http
  GET /api/v1/invoices/1042/pdf HTTP/1.1
  Host: api.example.com
  Authorization: Bearer <MEMBER_ORG_A_TOKEN>
  X-HackerOne-Researcher: qalbaz_0x
  ```
- **Business Impact:** Demonstrated cross-tenant data exfiltration across 10,000+ invoices.
