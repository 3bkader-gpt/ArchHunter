# 09 — Reporting & Triage (The Impact-First Doctrine)

> **Core Axiom:** The goal of a bug bounty report is simple: **Make the triager understand the bug, reproduce it, and see the real impact in under two minutes.** Evidence always trumps theoretical claims.

---

## 1. Duplicate & Root Cause Pre-Check
Before drafting your report:
1. **Search Disclosed Reports:** Search HackerOne/Bugcrowd Hacktivity for the program.
2. **Search Affected Endpoint & Parameters:** Identify past reports targeting the same feature or API route.
3. **Inspect Public Repositories:** If target is open-source or has public packages, check GitHub issues, merged PRs, commit messages, and security advisories.
4. **The Same Root Cause Shield:**
   - **A new endpoint does not automatically mean a new vulnerability.**
   - If an authorization middleware is missing across 10 endpoints, submitting 10 reports will result in 1 Bounty + 9 Duplicates (or reputation penalties). Group them into a single comprehensive report highlighting systemic impact.

---

## 2. The Anti-Speculation Doctrine ("Only Claim What You Proved")
Never exaggerate or hypothesize impact:
- ❌ **Banned Language:** *"Could potentially allow an attacker to..."*, *"May lead to full compromise..."*, *"Could be chained to..."*
- ✅ **Proven Language:** State exactly what was confirmed and verified in state.

| ❌ Unacceptable Speculation | ✅ Verified Factual Proof |
| :--- | :--- |
| "This could potentially allow an attacker to access arbitrary user data." | "An authenticated unprivileged user can change the `user_id` parameter and retrieve another tenant's private order history and PII." |
| "This endpoint might allow remote code execution through template injection." | "Template injection confirmed: Server executed mathematical evaluation `${{7*7}}` returning `49` in the rendered header." |

> [!IMPORTANT]
> If you could not safely prove a higher impact without risking system damage or violating terms, **state that boundary explicitly** in the report. Triagers respect professional restraint far more than inflated speculation.

---

## 3. The Professional Title Formula

Use this exact structure for all report titles:
$$\mathbf{[Bug\ Class]\ in\ [Endpoint/Feature]\ allows\ [Attacker]\ to\ [Impact]}$$

### Examples:
- ✅ `IDOR in /api/v2/invoices/{id} allows authenticated users to access other customers' invoices`
- ✅ `Missing authorization on /api/admin/users allows normal users to create admin accounts`
- ✅ `SSRF in image import (/v1/media/fetch) allows HTTP requests to AWS cloud metadata endpoint`
- ❌ `IDOR vulnerability` *(Lazy, no context)*
- ❌ `Broken access control` *(Too generic)*
- ❌ `Critical security issue found on website` *(Zero technical signal)*

---

## 4. Standard Report Anatomy
Always use the standardized [VULNERABILITY_REPORT_TEMPLATE.md](file:///d:/Hack/bug_bounty/templates/VULNERABILITY_REPORT_TEMPLATE.md):
1. **Strategic Summary:** 2-3 sentences: What is broken, where, who can exploit it, and what exact business damage results.
2. **Vulnerability Type & CVSS:** Accurate CWE, OWASP category, and honest CVSS v3.1/4.0 vector string.
3. **Affected Asset & Endpoint:** Full URI, HTTP method, and affected parameter.
4. **Steps to Reproduce:** Numbered, clear, and deterministic. Must work from a fresh session.
5. **Raw HTTP Request:** Copy-paste friendly with research header (`X-HackerOne-Researcher: qalbaz_0x`).
6. **Raw HTTP Response:** Actual server response proving the state mutation or data breach (not just a cropped screenshot).
7. **Business Impact:** Grounded in financial loss, PII leakage, or integrity breach.
8. **Remediation:** Architectural fix addressing the root cause, not just a surface regex filter.

---

## 5. The Two-Account Rule for Authorization Bugs
For BOLA, IDOR, privilege escalation, or logic flaws, always conduct the test with two distinct accounts:
- **Account A (Attacker):** The account making unauthorized requests.
- **Account B (Victim):** The account owning the private data or resource.

### The Proof Sequence:
$$\text{Account A} \xrightarrow{\text{Normal UI}} \text{Access Denied / Not Visible}$$
$$\text{Account A} \xrightarrow{\text{Manipulated Request with Account B's ID}} \text{200 OK + Account B's Data}$$
$$\text{Account B} \xrightarrow{\text{Verification}} \text{State confirmed mutated / leaked}$$

---

## 6. Evidence Hygiene Protocol
Before attaching screenshots, HAR captures, or HTTP payloads:

### Pre-Submission Scrubbing:
- [ ] Redact all active session cookies (`Set-Cookie`, `Cookie`).
- [ ] Redact `Authorization: Bearer <TOKEN>` or API keys.
- [ ] Redact CSRF tokens and internal API credentials.
- [ ] Mask any non-test personal information (PII).
- [ ] Ensure request headers include `X-HackerOne-Researcher: qalbaz_0x`.

### Post-Submission Account Hygiene:
1. Log out and back into testing accounts to invalidate previous session identifiers.
2. Change test account passwords if exposed in traffic logs or recordings.
3. Keep raw unredacted Burp project / HTTP history archived privately in case triage requests full debug captures.

---

## 7. The 13 Standalone Rejections Blacklist
Do **NOT** submit these items alone unless they are chained to demonstrate direct, measurable business harm:
1. Missing Content Security Policy (CSP).
2. Missing HTTP Strict Transport Security (HSTS).
3. Missing generic security headers (`X-Frame-Options`, `X-Content-Type-Options`).
4. Missing or weak SPF, DKIM, or DMARC records.
5. Public GraphQL introspection enabled alone without sensitive private queries.
6. Software or server version disclosure alone.
7. Clickjacking on static, non-sensitive, or unauthenticated pages.
8. Self-XSS (without automated trigger, CSRF injection, or drag-and-drop PoC).
9. Open redirect with no meaningful secondary impact (OAuth token theft or SSRF pivot).
10. Blind SSRF with DNS callback only and no backend response or internal network access.
11. Missing `HttpOnly` or `Secure` cookie flags alone without demonstrable exfiltration.
12. Logout CSRF.
13. Session token not invalidated immediately on client-side logout.

---

## 8. Triage Defense Protocol (Evidence-Based Pushback)
When a triager pushes back, **never argue emotionally**. Respond strictly with objective evidence:

| Triager Objection | Tactical Evidence Counter-Response |
| :--- | :--- |
| **"Authentication is required."** | *"The vulnerability requires only a self-registered, unprivileged free account. No administrative privileges, special enterprise roles, or user interaction are required to exploit the flaw."* |
| **"Limited business impact."** | Provide exact inventory of compromised fields: *"The response returns 14 private fields including unhashed SSN, home address, and payment card tokens for tenant UUID `[X]`. Furthermore, sequentially incrementing `{id}` enables complete tenant database scraping."* |
| **"Not exploitable / Cannot reproduce."** | Provide a clean cURL command with negative controls: *"Here is the complete cURL command executable from an unauthenticated terminal. Notice that modifying parameter `X` to value `Y` produces a deterministic `200 OK` with leaked record, whereas `Z` produces `404`."* |
| **"Duplicate of an earlier report."** | *"Understood. Could you kindly share the date and root cause of the previous report? Our finding targets the underlying microservice `[Service]` which fails validation differently than frontend endpoint `[Route]`. If the root cause is identical, we will gladly accept the duplicate determination."* |

---

## 9. Post-Fix Retest Protocol
When the program requests retesting after a fix:
1. **Re-run the Original PoC:** Confirm whether the original payload is completely mitigated (`403 Forbidden` or `404 Not Found`).
2. **Test Root Cause vs Filter Bypass:**
   - Did the team fix the underlying authorization logic (`resource.owner_id == user.id`), or did they just block specific characters or blacklist the path?
   - Try HTTP method tampering (`POST` $\rightarrow$ `PUT`, `PATCH`, `GET`).
   - Try alternative Content-Types (`application/json` $\rightarrow$ `application/x-www-form-urlencoded`, `multipart/form-data`).
   - Try path normalization tricks (`/api/v2/invoices/..;/123`).
3. **Honest Reporting:** If the root cause is truly fixed, congratulate the team and close the ticket promptly. If a bypass exists, explain the bypass concisely within the retest ticket.

---

## 10. Post-Submission Momentum & Portfolio Mindset
- **Never stop hunting while waiting for triage.** A report in triage is out of your control.
- Maintain your local target log in `templates/TARGET_SESSION_TEMPLATE.md`.
- Record findings by state: `[OPEN]`, `[TRIAGED]`, `[RESOLVED]`, `[DUPLICATE]`, `[INFORMATIVE]`.
- Rotate your attack surface: If an asset is paused or in remediation, shift immediately to the next priority target.

---

## 11. Final 14-Point Pre-Submit Quality Gate
Before clicking "Submit Report", verify every check:
- [ ] 1. Title strictly follows formula: `[Bug Class] in [Endpoint/Feature] allows [Attacker] to [Impact]`.
- [ ] 2. Summary explains the issue clearly in plain English without jargon.
- [ ] 3. Endpoint and parameters are verified and 100% in-scope.
- [ ] 4. Steps to reproduce are numbered and tested from a fresh private browsing session.
- [ ] 5. Raw HTTP request is included and copy-paste friendly.
- [ ] 6. Raw HTTP response is included and proves the impact.
- [ ] 7. Two accounts were used to prove authorization/IDOR boundaries.
- [ ] 8. Negative control test was confirmed (Baseline vs Manipulated vs Negative).
- [ ] 9. Impact is specific, factual, and verified (no "could potentially").
- [ ] 10. CVSS score matches the exact demonstrated privileges and damage.
- [ ] 11. Remediation advice is architectural and concise.
- [ ] 12. Evidence hygiene passed: All session tokens, passwords, and sensitive PII are scrubbed.
- [ ] 13. Not on the 13 Standalone Rejections Blacklist.
- [ ] 14. Target program disclosed reports searched to minimize duplicate probability.

---
[WORKFLOW COMPLETE: MISSION ACCOMPLISHED]
