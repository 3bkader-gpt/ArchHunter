# Deep Link & WebView Abuse

## Objective & Context
*   **Security Assumption Failure:** The app assumes deep link parameters come from its own notifications/website and that any URL handed to an internal WebView is one it authored.
*   **Trust Boundary Violation:** An attacker-controlled URI (`myapp://...` or `https://app.link/...`) crosses from the untrusted world (SMS, QR, browser, other apps) directly into privileged routing and WebView configuration decisions made client-side.

## Recognition Patterns
*   **Mechanism:** Android Manifest `intent-filter` with `VIEW` + `BROWSABLE`; iOS universal links / custom schemes in `Info.plist`; any in-app WebView that takes a URL parameter.
*   **Behaviors:**
    *   Deep links that carry object IDs (`myapp://invite?team_id=123&token=abc`) or URLs (`myapp://webview?url=...`).
    *   WebView configured with `setJavaScriptEnabled(true)` and/or `addJavascriptInterface(...)` / `WKScriptMessageHandler` bridges.
    *   Link validation done with naive string checks (`startsWith("https://target.com")`) or not at all.

## Attack Preconditions
*   A deep link scheme resolvable from attacker-controlled input (QR, SMS, email, another app's intent).
*   A WebView/bridge reachable through a link parameter, or an exported routing Activity.
*   The client performs the sensitive action without a server-side binding re-check.

## Step-by-Step Validation Strategy
1.  **Enumerate every deep link** from the Manifest (`adb shell am start -d "<uri>"`) and iOS universal-link list; build the parameter table (name → type → used-for).
2.  **Open-redirect / WebView hijack:** for every URL-taking parameter, fuzz `https://evil.com`, `javascript:alert(1)`, `file:///etc/hosts`, `intent://...` — check what the WebView loads and which protections (`shouldOverrideUrlLoading`, allow-lists) apply.
3.  **Bridge exposure:** if `addJavascriptInterface` exposes native methods, load a page under attacker control and call the bridge from JS (`AndroidBridge.getToken()`) — access to localStorage, auth tokens, or native calls = Critical.
4.  **Deep-link IDOR:** take an invite/share link issued for YOUR object (`myapp://invite?team_id=ATTACKER_TEAM&token=TOKEN`), swap the object ID to the victim's while keeping your token — if the app calls `GET /api/teams/VICTIM_TEAM/invite?token=TOKEN` without a binding check, the server trusts the client's pairing.
5.  **Path traversal via routing:** `targetapp://product/123/../../admin` — client-side router normalization may land on privileged screens.

## Common Weak Implementations
*   WebView URL allow-list bypassed with `@`-credentials tricks, dot-evolution, or secondary redirects after initial check.
*   `exported="true"` routing activity that forwards intent extras straight into the WebView.
*   Server accepts `(token, team_id)` pairs without verifying the token was issued for that team — the client "decided" the pairing.
*   JavaScript bridge annotated `@JavascriptInterface` exposing token/preferences getters with no caller validation.

## Escalation Paths
*   **In-app RCE context:** bridge abuse yields tokens/localStorage/native execution in the app sandbox.
*   **Zero-click ATO:** malicious link in SMS/email auto-processed by the app → invite/token theft without user interaction beyond opening a page.
*   **Cross-user data theft:** deep-link IDOR chains into the API's object graph.

## Detection Opportunities
*   Server-side: flag API calls whose (token, object-id) pairing was not the one issued (binding audit).
*   CI: lint Manifest/Info.plist for exported routers and URL-taking WebViews; require allow-list tests.

## Notes
*   **False Positives:** deep links that only navigate to non-sensitive screens with no parameter-driven state are N/A — demonstrate state change or data exposure.
*   **Constraints:** iOS universal links require the AASA file; test both cold-start and warm-start routing.
*   **Workflow:** [`Workflow/11_depth_first_mobile.md`](../../Workflow/11_depth_first_mobile.md) Phases 1 & 4 · **Related:** [`exported_component_abuse`](exported_component_abuse.md).
