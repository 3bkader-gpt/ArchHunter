# Clickjacking / UI Redressing (incl. Double-Clickjacking)

**What it is:** Trick a victim into interacting with a target app they're logged into, while they think they're clicking your page. Classic = transparent iframe overlay. Modern = no iframe at all (double-clickjacking) which defeats `X-Frame-Options` and `frame-ancestors`.

## Classic iframe clickjacking
- [ ] Missing `X-Frame-Options` **and** no `frame-ancestors` CSP → framable.
- [ ] Frame a **sensitive single-click** action (delete account, change email, transfer, OAuth consent, disable 2FA).
- [ ] Test framed with the victim logged in.
```html
<style>iframe{opacity:0.0001;position:absolute;top:-95px;left:-100px;width:1200px;height:1200px;z-index:2}
       button{position:absolute;top:300px;left:300px;z-index:1}</style>
<button>Claim your prize</button>
<iframe src="https://target.com/settings/delete-account"></iframe>
```
Victim clicks the visible button; the invisible "Delete" lands under the cursor.

## Double-Clickjacking (bypasses XFO + frame-ancestors + SameSite)
No iframe → framing headers don't apply. Uses **popup windows + timing**.

**How it works:**
1. Attacker page opens a small **popunder** of the target, then triggers a browser UI element (fake sign-in prompt) that steals focus → popup hides underneath.
2. Show a fake **Cloudflare Turnstile / captcha** or a click-spam game (Flappy-Bird overlay) to condition rapid double-clicks in one spot.
3. Track the cursor with `mousemove`; reposition the popup with `window.moveTo()` to sit under the next click.
4. `moveTo()` is blocked cross-origin → redirect the popup to a **same-origin intermediate page**, move it, then redirect back to the target (page load latency covers the swap).
5. `window.open("", "popup")` (existing name) refocuses instantly **without new user activation**.
6. On the second click of the double-click, the target's authorize/confirm button is exactly under the cursor → action fires in the target's real, framing-immune window.

**Positioning math:**
```
x = screenX - button.x - button.width/2
y = screenY - button.y - button.height/2 - navbarHeight
```
**Targets:** OAuth "Authorize", permission grants, "Confirm" account changes, one-click ATO.

**Why it matters:** Sites that "fixed" clickjacking with XFO/`frame-ancestors`/`SameSite` are still vulnerable. Under-reported class in 2025.

## Other UI-redress variants
- **Drag-and-drop clickjacking:** get the victim to drag text/an object into a hidden field/iframe → submit attacker content (self-XSS trigger, CSRF-with-data, fill a form as the victim).
- **Cursorjacking:** visually offset the real cursor from its true position (historically Flash/Firefox bugs).
- **Temporal / bait-and-switch:** legitimate "Pay/Allow" button swapped in just before the click.
- **Nested clickjacking / history-nav:** frame within frame, or drive `history.back()` to reach a sensitive state.
- **Mobile tapjacking:** transparent overlay over an app's tap target.
- **Reverse tabnabbing:** `target=_blank` w/o `rel=noopener` → opened page rewrites `window.opener.location` to phishing (COOP missing enables it).

## Detection
- [ ] `curl -sI | grep -i -e x-frame-options -e content-security` → absent/loose = classic framable.
- [ ] Even if XFO/`frame-ancestors` present → still test **double-clickjacking** (they don't stop it).
- [ ] Missing **COOP** (`Cross-Origin-Opener-Policy`) → popup/opener control easier.

## Impact
Only real on **meaningful, low-friction** actions. Read-only framable page = usually informational. OAuth authorize / account change / 2FA disable = valid, sometimes critical.

## Report notes
Provide a working PoC that fires a **sensitive** action for a logged-in victim. For double-clickjacking, note it bypasses their existing XFO/`frame-ancestors`. State the exact action achieved.

## 🎯 Header check — Request → Response
```http
HEAD /settings/delete-account HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Content-Type: text/html
# (no X-Frame-Options, no Content-Security-Policy: frame-ancestors)  ← classic clickjacking possible
```
If `X-Frame-Options: DENY` or `frame-ancestors 'self'` present → classic framing blocked, but **still test double-clickjacking** (headers don't stop it).

## Deep cuts — defeats & higher-value targets
- [ ] **Partial/typo protections:** `frame-ancestors` present but scheme-loose (`http:` allowed), or only on the apex not `www`/subdomains; XFO set on the page but **not** on the sensitive `POST` target/iframe-able API; `ALLOW-FROM` (ignored by Chrome/Firefox) = effectively unprotected.
- [ ] **Sandbox iframe to keep interactivity:** `<iframe sandbox="allow-forms allow-scripts allow-same-origin">` can still submit framed forms while stripping top-nav frame-busters.
- [ ] **Auto-approving consent = 1-click ATO:** first-party OAuth apps that skip the consent screen (or "Authorize" pre-selected) make a single framed click grant tokens — highest-value clickjack target (`04-auth-session/04`).
- [ ] **Double-clickjacking prerequisites:** works when **COOP is missing** (popup/opener control) — check `Cross-Origin-Opener-Policy`; note the target's XFO/`frame-ancestors` are irrelevant to it.
- [ ] **Drag-and-drop data injection:** frame the target, have the victim drag your text into a hidden same-origin field → seed self-XSS/CSRF-with-data without a click on a button.
- [ ] **Reverse tabnabbing:** `target=_blank` without `rel=noopener` + missing COOP → the opened page rewrites `window.opener.location` to a phishing clone.
- [ ] **Mobile tapjacking / overlay:** transparent overlay over a webview tap target (Android `SYSTEM_ALERT_WINDOW`-style on hybrid apps).

## Sources
- Jorian Woltjer — Ultimate Double-Clickjacking PoC; InstaTunnel "Clickjacking 2.0" (2025); Huang et al. "Clickjacking: Attacks and Defenses"; HackTricks Clickjacking.
