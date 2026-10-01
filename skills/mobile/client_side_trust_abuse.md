# Client-Side Trust Abuse (Local Business Logic)

## Objective & Context
*   **Security Assumption Failure:** The app assumes the client computes business-critical values honestly (prices, entitlements, feature flags) and that local biometric/PIN gates represent real server-verified authorization.
*   **Trust Boundary Violation:** Business logic runs in an environment the attacker fully controls (Frida-patched process, repackaged APK); decisions made client-side are honored by the backend without independent re-verification.

## Recognition Patterns
*   **Mechanism:** Fintech/shopping/premium apps that compute `total = price * qty` locally; entitlement flags (`isPremium`, `isSubscribed`, `credits`) stored or evaluated on-device; biometric/PIN gates guarding transfers or export.
*   **Behaviors:**
    *   Checkout request carries a computed `total` rather than product IDs + quantities.
    *   Premium features toggle instantly on flag change with no server round-trip.
    *   Local auth gates unlock flows the server would re-authorize anyway (or worse — never does).

## Attack Preconditions
*   Instrumentation access (Frida on rooted/emulated device, or repackaged APK with `apk-mitm`).
*   At least one client-side computed or stored value that the server consumes as authoritative.

## Step-by-Step Validation Strategy
1.  **Storage sweep:** hook `SharedPreferences.putString` / SQLite writes; dump `isPremium`, `role`, `credits`, `trialEnds` — flip each and observe what unlocks.
2.  **Crypto/serialization pre-plaintext:** hook `javax.crypto.Cipher.doFinal` (and `java.security.Signature.sign`) to view payloads *before* encryption — local "encryption" is not transport security.
3.  **Price/total tampering:** locate the checkout builder (jadx/`libapp.so`); hook the function producing `total` and return `1`. If the server charges `1`, the client computes authoritative money values.
4.  **Entitlement patching:** patch local `isPremium()`/`couponValid()` to return `true`; if premium features run, confirm whether any server-side entitlement check ever fires (watch the traffic for a denial).
5.  **Biometric/local gate bypass:** hook `BiometricPrompt.authenticate` callbacks to always succeed; if the app proceeds to the sensitive flow, verify whether the server requires a fresh re-auth proof or just a session header.
6.  **Repackage persistence:** rebuild the APK with the patched checks for flows that need no runtime hooks (no integrity check → permanent bypass).

## Common Weak Implementations
*   Server accepts `{"total": 1}` instead of recomputing from line items.
*   Entitlement gating purely client-side (flag flip unlocks paid features; no server validation on feature APIs).
*   "Offline license" checks implemented in Java/Dart without native attestation.
*   Biometric gate as UI-only guard; the transfer API accepts the same session token without step-up auth.

## Escalation Paths
*   **Direct financial loss:** free purchases, negative quantities, discounted totals charged at `1`.
*   **Premium/subscription theft:** paid features unlocked across the install base (cost + revenue impact).
*   **Chain to ATO:** local token storage readable + non-expiring session → replay from another device. → [`exported_component_abuse`](exported_component_abuse.md) for storage access paths.

## Detection Opportunities
*   Server-side: recompute all monetary/entitlement values from canonical data; reject requests where client-computed fields diverge.
*   Require server-issued, short-lived proof tokens after step-up auth; never trust a "biometric passed" client assertion.
*   Play Integrity / App Attest verification on sensitive API routes.

## Notes
*   **False Positives:** purely cosmetic client-side changes (theme, layout) are N/A — impact requires the server honoring tampered values.
*   **Constraints:** requires rooted/emulator or repackaging — confirm program scope; some programs exclude "requires client tampering" unless it exposes server-side weaknesses (it usually does here).
*   **Workflow:** [`Workflow/11_depth_first_mobile.md`](../../Workflow/11_depth_first_mobile.md) Phase 3.
