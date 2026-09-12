# 🔬 Research, Intelligence & Theoretical Foundations

This directory aggregates theoretical security papers, cloud-native authorization architectures, disclosed vulnerability reports, and a master archive of 5,759 categorized writeup links.

---

## 📁 Repository Layout

```
research/
├── README.md                          # This index and research guide
├── writeup_links_archive.json         # 5,759 unique technical writeups categorized by bug class
├── hackerone_disclosed_reports_2026.txt # 200 real-world disclosed HackerOne bug reports
├── writeups/                          # Full-text analyzed deep-dive writeups
├── sources/
│   └── bug-bounty-checklist/          # Comprehensive attack surface checklist & Obsidian Canvas
└── [Architectural Papers & Specs]     # Zanzibar, SPIFFE, Istio, Kubernetes, AWS IAM
```

---

## 1. Architectural Foundations & Distributed Auth

These papers and documentation files form the foundation for our **Architecture Inference** engine and identity skills:

*   **Google Zanzibar (ReBAC & Distributed ACLs):**
    - [`google-zanzibar-paper.pdf`](google-zanzibar-paper.pdf) & [`google-zanzibar.md`](google-zanzibar.md)
    - *Governing Skill:* [`skills/state_management/distributed_auth_propagation.md`](../skills/state_management/distributed_auth_propagation.md)
*   **Workload Identity & Service Mesh:**
    - [`spiffe-overview.md`](spiffe-overview.md) & [`istio-security-concepts.md`](istio-security-concepts.md)
    - *Governing Skill:* [`skills/infrastructure/workload_identity_federation.md`](../skills/infrastructure/workload_identity_federation.md)
*   **Kubernetes Access Control:**
    - [`kubernetes-api-access-control.md`](kubernetes-api-access-control.md)
    - Focuses on API server admission controllers, Webhook Token Authenticators, and RBAC impersonation.
*   **AWS IAM & Cloud Trust Boundaries:**
    - [`aws_introduction.md`](aws_introduction.md), [`aws-iam-introduction.md`](aws-iam-introduction.md), [`aws-security-blog.md`](aws-security-blog.md)
    - *Governing Skill:* [`skills/auth_logic/iam_trust_boundaries.md`](../skills/auth_logic/iam_trust_boundaries.md)

---

## 2. Security Labs & Threat Research

*   **CloudGoat Scenarios:**
    - [`cloudgoat-readme.md`](cloudgoat-readme.md) — Rhino Security Labs' "Vulnerable by Design" AWS deployment templates.
*   **Cloud Security Research Feeds:**
    - [`rhino-security-labs-aws.md`](rhino-security-labs-aws.md)
    - [`aqua-nautilus-research.md`](aqua-nautilus-research.md)
    - [`wiz-research-tag.md`](wiz-research-tag.md)

---

## 3. Threat Checklists (`sources/bug-bounty-checklist/`)

A cloned, fully indexed repository containing Obsidian canvas files and checklists covering:
- Recon, Access Control, Business Logic, Injection, Auth & Session, Client-Side, File Upload, API, Server-Edge, and AI/LLM attack surfaces.
- Visual Canvas maps: `AttackFlow.canvas` and `MethodologyMap.canvas`.

---

## 4. Disclosed Vulnerability Intelligence

*   **HackerOne Disclosed Reports Dataset:**
    - [`hackerone_disclosed_reports_2026.txt`](hackerone_disclosed_reports_2026.txt) — 200 real-world disclosed reports from HackerOne programs (GitLab, Shopify, Uber, Yahoo, Twitter, etc.) with titles, URLs, and bounty amounts.
*   **Master Writeups Link Archive:**
    - [`writeup_links_archive.json`](writeup_links_archive.json) — 5,759 unique writeup, tool, and article links consolidated and deduplicated across 6 core channels (GamarSec, Daily Bounty, CyberSec, Bug Bounty Toolkit, Bug Bounty Hub, Ahmed Najeh).
*   **Full-Text Analyzed Case Studies (`writeups/`):**
    - [`From_NA_to_💰$$$_How_a_4-Month_Dead_Report_Became_My_First_Bug_Bounty_Win.md`](writeups/From_NA_to_💰$$$_How_a_4-Month_Dead_Report_Became_My_First_Bug_Bounty_Win.md) — How to prove server-side impact and overturn false "Not Applicable" triage decisions.
    - [`One_.svg_and_a_CDN_How_a_File_Extension_Leaked_Strangers'_PII.md`](writeups/One_.svg_and_a_CDN_How_a_File_Extension_Leaked_Strangers'_PII.md) — Web Cache Deception via extension manipulation (`.svg`) leaking victim PII.
    - [`⚡_BugScanner_Explained__Automated_Web_Recon_&_Vulnerability_Scanning_for_Bug_Bou.md`](writeups/⚡_BugScanner_Explained__Automated_Web_Recon_&_Vulnerability_Scanning_for_Bug_Bou.md) — Architecture of automated recon and vulnerability scanning systems.
