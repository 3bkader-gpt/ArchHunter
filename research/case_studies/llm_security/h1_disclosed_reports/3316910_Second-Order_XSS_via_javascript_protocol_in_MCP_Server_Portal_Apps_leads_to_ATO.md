# Report #3316910: Second-Order XSS via javascript protocol in MCP Server Portal Apps leads to ATO

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/3316910](https://hackerone.com/reports/3316910)
- **Program:** Cloudflare Public Bug Bounty
- **Reporter:** @matured_kazama
- **Status:** RESOLVED
- **Severity:** low
- **Weakness:** Cross-site Scripting (XSS) - Stored
- **Bounty:** Yes (Undisclosed Amount)
- **Submitted:** 2025-08-27T13:26:30.680Z
- **Disclosed:** 2025-12-16T09:47:20.124Z
- **Community Upvotes:** 50

---

## Executive Summaries

### Team by @mschwarzl

Missing sanitization of the redirect_uri parameter led to a XSS vulnerability in MCP server portals. An attacker can craft a malicious redirect_uri containing JavaScript code, obtain a client_id for this malicious URI, and then reuse it when a victim has an active session (CF_Authorization cookie exists) on the /authorize endpoint to execute arbitrary JavaScript. A detailed writeup by the reporter can be found [here](https://kazama.in/mcp-server-portal-xss-to-ato).
We recommend upgrading workers-oauth-provider to the latest version and following the best practices in [Securing MCP Servers
](https://github.com/cloudflare/agents/blob/main/docs/securing-mcp-servers.md).

### Researcher by @matured_kazama

My side of the story: https://kazama.in/mcp-server-portal-xss-to-ato

---

## Full Vulnerability Description & Reproduction Steps

No detailed description provided.

---

## Attachments
None.
