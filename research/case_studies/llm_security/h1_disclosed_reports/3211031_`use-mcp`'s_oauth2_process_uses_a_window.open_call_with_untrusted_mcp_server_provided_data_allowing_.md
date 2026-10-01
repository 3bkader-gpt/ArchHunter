# Report #3211031: `use-mcp`'s oauth2 process uses a window.open call with untrusted mcp server provided data allowing for code execution under the page using it

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/3211031](https://hackerone.com/reports/3211031)
- **Program:** Cloudflare Public Bug Bounty
- **Reporter:** @null_smashmaster0045
- **Status:** RESOLVED
- **Severity:** medium
- **Weakness:** Cross-site Scripting (XSS) - Generic
- **Bounty:** $$550
- **Submitted:** 2025-06-19T17:24:47.873Z
- **Disclosed:** 2025-09-30T08:15:45.546Z
- **Community Upvotes:** 75

---

## Executive Summaries

### Team by @mschwarzl

The `authorizeEndpoint` parameter from `use-mcp` version was susceptible to XSS.  Sanitization of that parameter has been added in version  0.0.10 of use-mcp. A skilled attacker was able to turn this XSS into code execution on the client (https://verialabs.com/blog/from-mcp-to-shell/#xss---rce-abusing-mcps-stdio-transport). 

The researcher was rewarded 550$ for this finding.

---

## Full Vulnerability Description & Reproduction Steps

No detailed description provided.

---

## Attachments
None.
