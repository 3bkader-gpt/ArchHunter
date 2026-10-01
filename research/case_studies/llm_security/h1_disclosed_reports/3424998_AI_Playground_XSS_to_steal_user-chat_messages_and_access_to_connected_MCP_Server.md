# Report #3424998: AI Playground XSS to steal user-chat messages and access to connected MCP Server

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/3424998](https://hackerone.com/reports/3424998)
- **Program:** Cloudflare Public Bug Bounty
- **Reporter:** @matured_kazama
- **Status:** RESOLVED
- **Severity:** low
- **Weakness:** Cross-site Scripting (XSS) - Reflected
- **Bounty:** Yes (Undisclosed Amount)
- **Submitted:** 2025-11-13T22:29:19.704Z
- **Disclosed:** 2026-02-26T18:56:53.331Z
- **Community Upvotes:** 60

---

## Executive Summaries

### Team by @3shna

Reflected XSS was found in the AI Playground OAuth handler (CVE-2026-1721) due to unescaped interpolation of the error_description parameter into a <script> tag by the researcher.
A targeted attacker could execute JavaScript to access session-based chat history or interact with connected MCP servers on the victim's behalf during the user's session following a user interaction to click a phishing link.
This issue is patched now and users of the open-source Agents SDK should upgrade to v0.3.10

Disclosed responsibly by Nishant Kumawat via Cloudflare Bug Bounty program on Hackerone

### Researcher by @matured_kazama

Full Writeup: https://kazama.in/ai-playground-xss-to-mcp-takeover

---

## Full Vulnerability Description & Reproduction Steps

No detailed description provided.

---

## Attachments
None.
