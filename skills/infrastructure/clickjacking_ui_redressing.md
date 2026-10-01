# Clickjacking & UI Redressing

## Objective & Context
*   **Security Assumption Failure:** The system assumes that because a request originates from the victim's authenticated browser session with a valid CSRF token, the user intentionally initiated it. Visual layer integrity is treated as out of scope for server-side authz.
*   **Trust Boundary Violation:** State-changing endpoints can be driven from a framed attacker-controlled context; the server never verifies that the user *saw and intended* the action, only that the browser sent it.

## Recognition Patterns
*   **Mechanism:** Any one-click state change reachable while authenticated: email/phone change, OAuth grant approval, 2FA disable, "accept invite", delete/transfer resource, password change, privacy toggle, payment confirmation.
*   **Behaviors:**
    *   Missing or permissive anti-framing headers on the action pages: no `X-Frame-Options`, no CSP `frame-ancestors`, or values like `X-Frame-Options: ALLOW-FROM` (obsolete) / `frame-ancestors https://*.example.com` (wide).
    *   Framing protections applied only to the login page or marketing site, not to the authenticated app routes, modals, or embedded editors.
    *   JavaScript-only frame-busting (`if (top !== self) top.location = ...`) as the sole defense.
    *   Action completes via a single GET (state change on GET) or simple POST with no re-authentication or typed confirmation.

## Attack Preconditions
*   Victim is authenticated to the target in the same browser that loads the attacker page.
*   The action is a simple request (no CAPTCHA, no re-entered password, no unique canvas/visual secret that cannot be hidden).
*   The target page is frameable, or frameable subresources (modals, widgets, OAuth consent screens) can drive it.

## Step-by-Step Validation Strategy
1.  **Framing Test:** For each sensitive action page, fetch it and inspect response headers for `X-Frame-Options` / CSP `frame-ancestors`. Then actually embed it in `<iframe src="...">` on a local test page across origins and confirm it renders and accepts input.
2.  **Frame-Busting Analysis:** If JS busting exists, verify it survives: `sandbox` attribute with `allow-top-navigation` removed, `<iframe csp>` restrictions, interrupting the navigation via `beforeunload`, or rendering inside `about:blank`-nested frames.
3.  **Overlay Redress:** Build a proof-of-concept page: target iframe set to `opacity: 0.001`, layered under enticing buttons (`position: absolute; z-index`), aligned so a benign click lands on the hidden "Confirm transfer"/"Disable 2FA" control. Verify the action fires with the victim's session.
4.  **Multi-Step Chain:** For actions requiring two steps (select → confirm), chain iframes: pre-position step 2's confirmation page so the second click completes it, or use successive decoy buttons. Log each completed step server-side.
5.  **Input-Field Injection (drag&drop / text-injection variant):** Where the flow needs a typed value, use `contenteditable`/drag-and-drop or the classic "text field clickjacking" trick (iframe steals keystrokes into a hidden input) to pre-fill e.g. a new email address.
6.  **Subresource Sweep:** Frame OAuth consent screens, "checkout now" modals, embedded editors, and per-tenant subdomains — per-route protections frequently miss these.
7.  **State Change on GET:** If a GET (e.g., `/confirm?token=...`) mutates state, pair with missing framing headers or link prefetch — no click needed at all.

## Common Weak Implementations
*   `X-Frame-Options: SAMEORIGIN` only on top-level app routes; legacy per-tenant subdomains or error/consent pages unprotected.
*   `ALLOW-FROM` directives (unsupported by modern browsers) treated as effective protection.
*   CSP `frame-ancestors` absent while `Content-Security-Policy` is present for other directives (script-src only).
*   JavaScript frame-busting as the only control — broken by `sandbox`, `loading=lazy` tricks, or disabled JS paths that still expose the action.
*   Sensitive actions behind a modal inside a frameable SPA route — teams assume the modal, not the route, is the boundary.

## Escalation Paths
*   **Account Takeover:** Redressed "change email → forgot password" or "disable 2FA" chains yield full pre-authenticated ATO without ever touching a credential.
*   **OAuth Consent Hijack:** Framing the provider's grant approval screen to silently approve a malicious client's scopes.
*   **Financial Impact:** One-click purchase/transfer/payout confirmations executed against the victim's session.
*   **Stored Vector:** If the attacker can make the victim's *own* app frame attacker content (e.g., via user-uploaded HTML), the clickjacking page needs no external hosting.

## Detection Opportunities
*   Instrument state-changing endpoints to log the `Sec-Fetch-Site`, `Sec-Fetch-Frame`, and `Referer` of the initiating navigation; alert on `cross-site` framed initiators.
*   Canary: a hidden-but-clickable control (invisible to users, framed-loadable) that, when triggered, flags redress attempts.
*   CI header-linting: fail builds when authenticated action routes lack `frame-ancestors 'none'`/`'self'`.

## Notes
*   **False Positives:** Framable pages with zero state-changing capability (static content, already-public data) are informational only; always demonstrate a concrete action chain.
*   **Constraints:** Requires user interaction and a motivated lure; single-frame PoCs against re-auth-gated actions will not fire — map the full action chain first.
*   **Cross-reference:** `skills/state_management/cross_subdomain_csrf.md` for the same-site framing cousin; `skills/_TAXONOMY.md` Tampering section; wordlists in `payloads/wordlists/` for endpoint discovery of action routes.
