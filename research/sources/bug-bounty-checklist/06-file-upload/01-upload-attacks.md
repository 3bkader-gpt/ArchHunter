# File Upload Attacks

**What it is:** Weak validation on uploads → web shell (RCE), stored XSS, path traversal, SSRF, DoS.

## Where to look
Avatars, documents, review photos, import, resume, KYC, logo, attachments, CSV/XML import.

## Extension / content-type bypass
- [ ] Double ext: `shell.php.jpg`, `shell.jpg.php`.
- [ ] Case: `.pHp`, `.PhP`. Alt exts: `.php5 .phtml .phar .pht .php7`.
- [ ] Null byte (older stacks): `shell.php%00.jpg`.
- [ ] Trailing chars: `shell.php.` , `shell.php ` , `shell.php::$DATA` (IIS).
- [ ] Content-Type spoof: send `image/png` with PHP body.
- [ ] Magic bytes: prepend `GIF89a;` / valid PNG header before code.
- [ ] Polyglot: valid image + embedded PHP/HTML.
- [ ] `.htaccess`/`web.config` upload to redefine handlers → execute innocuous ext.

## Beyond web shell
- [ ] SVG/PNG/EXIF/filename → stored XSS. **Full playbook + req/response pairs: `06-file-upload/02-xss-via-image-upload.md`.**
- [ ] HTML/`.html`/`.xhtml` upload served inline → stored XSS on the upload domain.
- [ ] Filename injection: `../../etc/x`, XSS in filename reflected in listing.
- [ ] Path traversal in `filename`/`path` field → write outside upload dir.
- [ ] ImageMagick/ffmpeg/LibreOffice processing → RCE (ImageTragick, video SSRF).
- [ ] Zip slip (`../` inside archive) on import/extract.
- [ ] Pixel-flood / decompression bomb = DoS (do not run on live).
- [ ] Overwrite others' files via predictable/IDOR upload path.

## Confirm execution safely
Upload a benign marker (`<?php echo 'pwn'.7*7; ?>` → outputs `pwn49`) and load it. No shells/persistence on live targets.

## Impact
RCE (critical), stored XSS, file overwrite, SSRF, info disclosure.

## Tools
Burp, `fuxploider`, manual, exiftool for polyglots.

## 🎯 PoC — Request → Response (double-extension web shell)

```http
POST /api/v1/avatar HTTP/1.1
Host: target.com
Authorization: Bearer <mine>
Content-Type: multipart/form-data; boundary=x

--x
Content-Disposition: form-data; name="file"; filename="avatar.php.jpg"
Content-Type: image/jpeg

GIF89a
<?php echo "PWN".(7*7); ?>
--x--
```
```http
HTTP/1.1 200 OK
{"url":"/uploads/9f2a1c/avatar.php.jpg"}
```
Request the stored file (Apache mis-maps `.php.jpg` → PHP):
```http
GET /uploads/9f2a1c/avatar.php.jpg HTTP/1.1
Host: target.com
```
```http
HTTP/1.1 200 OK
Content-Type: text/html

PWN49            ← code executed = RCE
```

## Deep cuts — multipart quirks, cloud, and TOCTOU
- [ ] **Multipart parser confusion:** two `filename=` params (safe + dangerous), duplicated `Content-Disposition`, mismatched/duplicate boundaries, `filename` vs `filename*` (RFC 5987) disagreement, newline/`;` in filename, `Content-Type` set per-part vs top-level — the validator reads one, storage uses the other.
- [ ] **Presigned / direct-to-cloud upload abuse:** apps that hand you an S3/GCS/Azure **presigned PUT** often don't pin `key`, `Content-Type`, or `Content-Disposition` — change the key to overwrite another object/path, set `Content-Type: text/html`, or drop ACL restrictions. Also request a presign for a path you shouldn't write.
- [ ] **"Upload from URL" = SSRF:** the import-by-URL / avatar-from-URL fetch is server-side (`03-injection/06`) — point at metadata/internal.
- [ ] **AV-scan TOCTOU:** file is live-servable in the window *before* the async scanner quarantines it, or the scan runs on the original but a converted/renamed copy is served — race upload vs scan.
- [ ] **Handler-redefinition uploads:** `.htaccess` (`AddType application/x-httpd-php .jpg`), `web.config`, `.user.ini`, `httpd.conf` fragment → make an innocuous ext execute; Tomcat `.jsp`/`.jspx`/`web.xml`, `.war`; ASP `.asp/.aspx/.ashx/.asmx/.soap/.config`; ColdFusion `.cfm`; Perl `.pl/.cgi`.
- [ ] **Magic-byte allowlist bypass:** prepend the *required* magic (`GIF89a`, `%PDF-`, PNG `\x89PNG`, JPEG `\xFF\xD8\xFF`) before the payload; or craft a real image that's also valid script (polyglot).
- [ ] **Windows/IIS name tricks:** `shell.php::$DATA`, `shell.phP` (case), reserved `CON`/`PRN`/`NUL`, alternate data streams, trailing dot/space stripped after the check.
- [ ] **Model/serialized uploads:** `.pkl/.pt/.h5/.joblib/.npy` to an ML pipeline, `.phar`/`.ser` to a fs-op sink → deserialization RCE (`03-injection/08`).
- [ ] **Quota/DoS:** decompression bomb, pixel-flood, deeply-nested zip — note, don't sustain on prod.

## Report notes
Show the uploaded file executing/rendering. For SVG-XSS show `alert(document.domain)`. For presigned/cloud abuse show the overwritten or arbitrarily-placed object. Delete your test artifact after proof if possible.
