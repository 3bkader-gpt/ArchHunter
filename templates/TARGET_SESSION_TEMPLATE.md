# TARGET ENGAGEMENT SESSION: [TARGET_NAME]

> **Target Domain:** `example.com`  
> **Engagement Date:** `YYYY-MM-DD`  
> **Platform / Program:** `HackerOne / Intigriti / Bugcrowd`  
> **Mandatory Header:** `X-HackerOne-Researcher: qalbaz_0x`  
> **Attack Angle:** `[e.g., Mobile API v1 parity / GraphQL bulk mutations / S3 invoice PDF converter]`

---

## 1. Scope, Gate & Rules of Engagement

### 12-Point Target Gate Checklist:
- [ ] 1. Registration verified with zero sales/corporate blockers.
- [ ] 2. Reached high-value authenticated dashboard.
- [ ] 3. Program actively resolved reports in the last 30–60 days.
- [ ] 4. Reviewed public disclosed reports for common patterns.
- [ ] 5. Specific, non-generic **Attack Angle** defined above.
- [ ] 6. Mapped Object Movers (`import`, `export`, `clone`, `restore`).
- [ ] 7. Mapped Money Movers (billing, checkout, credits, refunds).
- [ ] 8. Mapped backend file/media/untrusted processors.
- [ ] 9. Focused on Tier 1 mechanism classes (avoided scanner noise).
- [ ] 10. Account A & B verified in distinct tenants.
- [ ] 11. Mandatory researcher header active in proxy.
- [ ] 12. 30–60 min initial triage completed with GO decision.

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

## 5. Ruled-Out Hypotheses & Closed Attack Surfaces (Negatives Tracker)

> **The Standing Discipline Rule:** *Write down negatives, not just findings.*  
> Documenting validated secure controls prevents duplicate testing, saves 50% of research time, and builds an audit trail.

| # | Endpoint / Feature | Role Tested | Test Performed & Payload | Observed Server Defense | Verdict |
|---|---|---|---|---|---|
| 1 | `GET /api/v1/admin/users` | Member (Org A) | Swapped bearer token to Member | Returned strict `403 Forbidden` with verified middleware check | `CLOSED` |
| 2 | `POST /api/v1/checkout/apply_discount` | Member (Org A) | Replayed 20 concurrent requests (Race) | DB transaction lock held; coupon applied exactly once | `CLOSED` |

---

## 6. Confirmed Findings (Ready for Report)

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
