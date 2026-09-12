# Symfony

**What it is:** Symfony-specific exposures. The web profiler / `app_dev.php` front controller left reachable in production leaks config, env, and request data; the "secret fragment" bug turns a leaked `APP_SECRET` into RCE via the `_fragment` renderer.

## Where to look
- [ ] Fingerprint Symfony: `X-Debug-Token` / `X-Debug-Token-Link` response headers, `sf_redirect` cookie, Twig error pages, profiler toolbar.

## Test steps
- [ ] **Exposed profiler / dev front controller** — sensitive data disclosure:
```
/_profiler
/_profiler/empty/search/results?limit=10
/app_dev.php
/app_dev.php/_profiler
/app_dev.php/_profiler/
/app_dev.php/_profiler/phpinfo
/app_dev.php/_profiler/open?file=app/config/parameters.yml
/app/config/config_test.yml
/_fragment
/_internal
/_proxy
```
- [ ] `_profiler/open?file=` → local file read of config (`parameters.yml` = DB creds, `APP_SECRET`).
- [ ] **Secret fragment RCE:** leaked `APP_SECRET` lets you sign `/_fragment` requests → RCE. Tooling + writeup:
  - `https://github.com/ambionics/symfony-exploits`
  - `http://web.archive.org/web/20230708081739/https://www.ambionics.io/blog/symfony-secret-fragment`
- [ ] General Symfony RCE peek: https://medium.com/@bxrowski0x/3-symfony-rce-a-peek-behind-the-curtain-83da5433e149

## Tooling
- [ ] `eos` — Symfony scanner: `https://github.com/Synacktiv/eos`
- [ ] nuclei: bundled `symfony-template_1.yaml` .. `symfony-template_4.yaml` (this folder).
- [ ] Fuzz wordlist: `https://github.com/six2dez/OneListForAll/blob/main/dict/symphony_long.txt`

## Impact
Profiler exposure = config/env/PII leak; `APP_SECRET` leak = signed `_fragment` = RCE.

## Report notes
Show the profiler/phpinfo page or a config file read. For fragment RCE, prove signed request execution against your own marker; do not run destructive commands.
