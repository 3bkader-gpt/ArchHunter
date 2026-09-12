# 09 — Reporting (The Impact-First Report)

## Operational Goal
Deliver high-value communication that enables rapid remediation and demonstrates elite technical quality. Lead with the **Inability to Protect** rather than the "Exploit."

## Report Structure
1.  **Strategic Summary:** 2 sentences on the mechanism and the result.
2.  **Critical Impact:** Clear definition of the compromised trust boundary.
3.  **Detailed Attack Path:** The architectural sequence (the "Chain").
4.  **Clinical Reproduction:** Concise, scriptable steps (`curl`, Python, Burp project).
5.  **Root Cause Analysis:** Identify the specific architectural failure (e.g., "Transitive Trust Decay" or "Linearizability Gap").
6.  **Remediation:** Provide the specific architectural fix, not just a "Patch."

## Quality Checklist
*   Are reproduction steps reproducible from a clean environment?
*   Is all PII redacted or blurred in screenshots?
*   Is the CVSS score honest and grounded in business impact?

## Outcome: The Bounty
Successful communication of risk leading to professional remediation and reward.

---
[WORKFLOW COMPLETE: MISSION ACCOMPLISHED]
