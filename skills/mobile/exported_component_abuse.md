# Exported Component & Inter-App Trust Abuse

## Objective & Context
*   **Security Assumption Failure:** The app assumes only itself (and trusted launchers) invokes its Activities, Services, Receivers, and Content Providers.
*   **Trust Boundary Violation:** Any component with `android:exported="true"` (or protected by nothing but a `signature`-less permission) is a zero-auth API endpoint reachable by any other app on the device or via ADB — a trust boundary the server never sees.

## Recognition Patterns
*   **Mechanism:** Manifest-declared components with `exported="true"`, implicit-intent receivers, `grantUriPermissions` providers, debuggable builds.
*   **Behaviors:**
    *   Activities that act on intent extras (`--es role admin`, URL params) without authenticating the caller.
    *   Content providers serving `query()`/`openFile()` on sensitive tables/files with no caller check.
    *   Receivers that trigger privileged actions (sync, export, unlock) from public intents.

## Attack Preconditions
*   An exported component that performs a state change, data read, or routing decision.
*   No signature-level permission, no caller-package validation, no user re-confirmation.

## Step-by-Step Validation Strategy
1.  **Inventory:** parse the Manifest — every `exported="true"` Activity/Service/Receiver/Provider becomes a test row.
2.  **Activity fuzzing (no traffic needed):**
    ```bash
    adb shell am start -n com.target/.ExportedActivity                     # empty extras
    adb shell am start -n com.target/.ExportedActivity --es "role" "admin" # malformed/admin extras
    adb shell am start -n com.target/.DeepLinkActivity -d "targetapp://product/123/../../admin"
    ```
    Compare behavior against the legitimate launch path — look for privilege screens, skipped auth, or crash-based info leak.
3.  **Content provider leakage:**
    ```bash
    adb shell content query --uri content://com.target.provider/secrets
    adb shell content query --uri content://com.target.provider/users --projection token
    ```
    Also test SQLi through the provider's `selection` argument and path traversal via `openFile()` (`../../databases/app.db`).
4.  **Intent hijack:** send implicit intents with matching actions — can an attacker-registered receiver capture tokens/PII the app broadcasts?
5.  **Backup/extract:** `adb backup` / root-pull `databases/` — unencrypted SQLite with JWTs, PII, or non-expiring tokens.

## Common Weak Implementations
*   `android:debuggable="true"` left in release builds (runtime patching of any component).
*   Providers with `grantUriPermissions="true"` and permissive path permissions.
*   Exported activities that trust intent extras for role/routing decisions — the "UI hidden" admin screen reachable by direct launch.
*   Broadcast tokens/PII via implicit intents (any app can listen).

## Escalation Paths
*   **Zero-auth data theft:** provider query paths expose PII/tokens without any server interaction.
*   **Privilege routing:** direct-launch admin screens combined with client-side trust abuse → [`client_side_trust_abuse`](client_side_trust_abuse.md).
*   **Pivot to deep links:** exported router forwards attacker extras into WebViews → [`deep_link_webview_abuse`](deep_link_webview_abuse.md).

## Detection Opportunities
*   CI Manifest lint: fail on `exported="true"` components without signature permissions or explicit justification.
*   Runtime: log every component invocation with the calling package; alert on unknown callers touching sensitive components.

## Notes
*   **False Positives:** exported components required by the platform (launchers, share targets) that expose no state change or sensitive data — N/A.
*   **Constraints:** some programs scope out "requires a malicious app on the same device" — check program policy; ADB-only PoCs often qualify as demonstrating the issue.
*   **Workflow:** [`Workflow/11_depth_first_mobile.md`](../../Workflow/11_depth_first_mobile.md) Phases 1, 3, 4.
