# 01 — Strategic Target Selection & Business Deconstruction (Phase 0)

## Operational Goal
Identify targets with the highest logical density, payout reliability, and monetization surface. Avoid "Payload Sinks" (hardened static marketing sites) in favor of "Mechanism Hubs" (complex SaaS dashboards, multi-tenant B2B portals, and active API gateways).

---

## 1. Program Strategy: Bug Bounty (BBP) vs. Vulnerability Disclosure (VDP) vs. Pentest

| Criteria | Bug Bounty Program (BBP) | Vulnerability Disclosure (VDP) | Penetration Test (Pentest) |
|---|---|---|---|
| **Primary Reward** | Cash Bounties ($$$), Badges | Hall of Fame, Points, Swag | Flat Consulting Fee / Contract |
| **Philosophy & Filter** | **Real Security Bugs with Real Impact** (Zero tolerance for scanner noise/best practices) | Reputation building, testing pipelines | Comprehensive audit (vulnerabilities + hygiene/weaknesses) |
| **Excluded / Low Value** | Old software banners, missing headers, informational issues without impact | Informational issues usually accepted for HoF | Required in compliance deliverables |
| **Competition Level** | Very High (Full-time offensive specialists) | Low to Medium | Fixed internal/vendor team |
| **Default Doctrine** | **For ArchHunter, the default doctrine is BBP:** We only report demonstrated, weaponized business damage. |

### 💡 High-Yield Program Selection Heuristics:
1. **Response Efficiency & Triage Speed:** Filter for programs with `< 5 days` average time to first response and bounty award. Avoid unresponsive programs with high dispute ratios.
2. **Freshness Index:** Hunt on programs updated within the last **30 days** or recently added domains to avoid duplicate exhaustion.
3. **Scope Geometry:** Prioritize wildcard scopes (`*.target.com`) with API access over restrictive single-URL static assets.

---

## 2. Authorization Is Not Optional & The Scope Traps

> [!CAUTION]
> ### ⚠️ The "Same Company" Trap
> **Being owned or operated by the same parent organization does NOT automatically make an asset in-scope.**
> Testing unlisted subsidiaries or newly acquired infrastructure without explicit written authorization is an immediate path to report disqualification, N/A rating, or platform bans.

### Pre-Engagement Authorization Checklist:
Before sending a single request:
1. **Program Policy:** Read explicit boundaries on HackerOne/Bugcrowd.
2. **Target In-Scope List:** Verify exact domain/CIDR match (do not assume subdomains unless wildcard `*.` is specified).
3. **Excluded Vulnerability Types:** Verify program out-of-scope clauses (e.g., DoS, volumetric brute force, automated scanner dumps, self-XSS).
4. **Rate Limits & Automation Rules:** Adhere to safe concurrency limits (e.g., maximum 5–10 req/sec unless otherwise allowed).
5. **State-Changing / Destructive Boundaries:** Never test destructive actions (data wipe, invoice deletion, account takeover) on live users. Use your own Account A vs Account B.

---

## 3. Offensive Mindset: Asymmetry & Inconsistency Hunting

The attacker's biggest advantage is **Asymmetry**: you do not need to test everything equally. Focus ruthlessly on areas of high logical density and architectural friction.

### A. Reverse-Engineer Developer Assumptions (Inconsistency Hunting)
Developers frequently make invalid assumptions about trust boundaries. Ask:
* *Does a newly introduced feature have the same authorization controls as mature features?*
* *Is an older, deprecated API version (`/v1/`, `/v2-beta/`) still active with relaxed authorization?*
* *Does an alternate endpoint access the same backend database entity with weaker checks?*
* *Can two distinct workflows be intertwined in an unanticipated sequence?*

### B. Client Environment Asymmetry (`Web` vs `Mobile` vs `Admin`)
Never restrict your audit to the primary Web UI. Modern systems route traffic from distinct client ecosystems into shared microservices:
```
Web Browser Application  ───► API Gateway (Strict validation, modern WAF)
Mobile App (iOS / Android)──► API Gateway (Legacy endpoints, unpinned tokens, permissive schemas)
Internal / Admin Panel    ───► Private API  (Implicit trust, missing object-level checks)
```
* **Audit Action:** Decompile mobile client APKs/IPAs via **JADX** to discover undocumented endpoints or test if mobile API paths bypass Web WAFs or rate limits.

---

## 4. The 6-Point Target Gate & Fail-Fast Criteria

Before investing deep hours into any target, run the **Target Gate**. If the target fails an essential gate, **do not force it — move on to a better target**:

1. **Self-Registration & Core Access:** Can you freely register and access the core product? If you require sales calls, manual corporate verification, enterprise contracts, or unavailable local phone numbers $\rightarrow$ **Abandon immediately**.
2. **Crowdedness Filter:** If thousands of hunters are competing on the same trivial marketing forms and obvious login pages, duplicate risk approaches 100%. Seek depth or authenticated complexity.
3. **Requirement of a Real Attack Angle:** *"I will test everything carefully"* is **not** an angle. A valid angle is: a newly released feature, an unmapped mobile API version, a newly registered subsidiary domain, or a complex object conversion pipeline.
4. **Recent Activity Verification:** Check resolved report dates and bounty awards on HackerOne/Bugcrowd. A program with high historical stats that has not awarded a bounty in 6 months is often effectively abandoned or disputed.
5. **Disclosure History Audit:** Read public reports to understand what the security team values, what CVSS scores they push back on, and what attack surfaces have already been exhausted.
6. **High-Value Functionality Presence:** Verify whether the target actually handles money, executes file conversions, exposes private APIs, or transfers objects across tenants.

---

## 5. Identifying High-Value Surfaces: Object Movers & Untrusted Processors

Focus your architectural reasoning on surfaces that execute state transformations or call backend microservices:

### A. Object Movers (Primary BOLA / IDOR / SSRF Hotspots)
Features that manipulate, migrate, or duplicate persistent entities:
* `Import` / `Export` (CSV, JSON, XML, PDF, ZIP).
* `Clone` / `Fork` / `Duplicate` operations across workspaces or templates.
* `Restore` / `Backup` workflows.
* `Bulk Actions` (bulk invite, bulk delete, multi-tenant resource tagging).
* `File Uploads` & cloud storage sync (S3/GCS presigned URLs).

### B. Untrusted Input & Media Processors (RCE / SSRF / Injection)
* Document & image converters (ImageMagick, LibreOffice, headless Chrome/Puppeteer).
* Archive extraction (ZipSlip, symbolic link traversal).
* Webhook delivery and custom URL callback engines.
* Sandbox code execution or markdown/template rendering engines.

### C. Internal Functionality Reachable by Normal Users
* Internal microservice gateways, backend proxying endpoints, and unauthenticated administrative routes.
* **Golden Rule:** *Do not stop at proving you reached an internal service; prove what sensitive data or privileged actions you can actually invoke.*

---

## 6. Priority Matrix: High-Yield vs. Crowded Bug Classes

| Priority Tier | Vulnerability / Mechanism Class | Duplicate Risk | Payout Potential | Strategic Value |
|---|---|---|---|---|
| **Tier 1 (High Priority)** | Authorization (BOLA/IDOR), Business Logic, Object Transfers, SSRF, Multi-step Workflows, Cross-Tenant Leaks | Low to Medium | **High / Critical ($$$$)** | Mechanism-driven; scanners cannot find these. |
| **Tier 2 (High Priority)** | Financial state manipulation, Race conditions, Privilege escalation, Account takeover chains | Low | **High / Critical ($$$$)** | Requires multi-account state modeling. |
| **Tier 3 (Deprioritized)** | Basic reflected XSS on public forms, CSRF on low-impact actions, Clickjacking, Open Redirects | **Extremely High** | Low / Disputed ($) | Crowded; thousands of scanners test these daily. |

### ⚠️ The Same Root Cause Rule (Duplicate Shield)
> **Same root cause usually means the same bug.**  
> Discovering a second endpoint or an alternate parameter that fails due to the same underlying flawed middleware or missing authorization check does **not** constitute a new vulnerability. Submitting both will result in a Duplicate rating and damage your triage reputation. Chain them into one comprehensive impact report instead.

---

## 7. Time Budgeting Protocol: The 30–60 Min Triage & When to Rotate

Time is your scarcest asset. Treat every target through disciplined time windows:

```
[Target Discovery] ──► [30–60 Min Initial Triage] ──► Passes Gate? ──┬─► YES: 2–3 Focused Deep Sessions (2–4 hrs each)
                                                                     └─► NO : Immediate Rotation (Next Target)
```

### When to Rotate (Move to Another Target):
* The program triage has become dormant (no payouts/responses in months).
* Critical high-value workflows require credentials or corporate tiers you cannot obtain.
* The primary logical attack surface has been thoroughly audited with verified negative controls.
* Multiple focused sessions yield zero architectural anomalies or viable hypotheses.

### When NOT to Rotate:
* *"I tested for one evening and found nothing."* — A clean, rigorous audit of a high-value mechanism is foundational intelligence. Do not jump erratically between 5 programs a day.

---

## 8. Phase 0: Business Model Deconstruction & 12-Point Pre-Flight Checklist

### Foundational Business Deconstruction:
- [ ] **How does this company make money?** (SaaS subscription tiers, transaction fees, API call quotas, e-commerce checkout).
- [ ] **What is the most sensitive asset in their database?** (Customer PII, payment tokens, internal team documents, API keys, private tickets).
- [ ] **What roles and tenant boundaries exist?** (Org A vs Org B, Admin vs Member, Low privilege vs Superuser).
- [ ] **Which features have high logical complexity?** (Member invitations, webhook callbacks, CSV/PDF bulk exports, passwordless/OAuth login, custom role creation).

### The 12-Point Target Pre-Flight Gate:
1. [ ] I can create test accounts with zero blockers.
2. [ ] I can reach high-value authenticated functionality.
3. [ ] The program is actively awarding bounties within the last 30–60 days.
4. [ ] I reviewed past disclosed reports to identify validated patterns.
5. [ ] I have a specific, non-generic **Attack Angle**.
6. [ ] I mapped all **Object Movers** (`import`, `export`, `clone`, `restore`).
7. [ ] I mapped all **Money Movers** (checkout, coupons, balances, refunds).
8. [ ] I identified backend media/untrusted input processors.
9. [ ] I prioritized Tier 1 mechanism classes over crowded scanner noise.
10. [ ] I set up Account A (Attacker) and Account B (Victim) in separate tenants.
11. [ ] I configured the mandatory researcher HTTP header.
12. [ ] I allocated a clear 30–60 min triage window before committing deep hours.

---

## 9. Preparation & Two-Account Setup
1. Create **Account A (Attacker)**: `attacker@wearehackerone.com` in Org A.
2. Create **Account B (Victim)**: `victim@wearehackerone.com` in Org B.
3. Configure **Burp Suite Autorize / Match & Replace** following **[PRACTICAL_BURP_HUNTING_GUIDE.md](../Methodology/PRACTICAL_BURP_HUNTING_GUIDE.md)**.

---

## Transition to Recon
Proceed to **[02 — Passive Recon](02_passive_recon.md)** with a clear operational focus on mapping live SaaS applications, API gateways, and cloud origins.

