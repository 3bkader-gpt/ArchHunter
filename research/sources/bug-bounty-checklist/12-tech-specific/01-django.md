# Django

**What it is:** Django-specific misconfigs and exposures. The headline is `DEBUG=True` in production, which leaks settings/env and can chain to RCE; plus debug-toolbar exposure and predictable API/health paths.

## Where to look
- [ ] Fingerprint Django: `csrftoken`/`sessionid` cookies, `X-Frame-Options: DENY` default, admin at `/admin/`, DRF browsable API, error-page style.
- [ ] Force an error (bad path, malformed param) → yellow Django debug page = `DEBUG=True` = settings + env + traceback leak.

## Test steps
- [ ] **Debug mode → RCE:** `DEBUG=True` traceback exposes `SECRET_KEY`, DB creds, installed apps. With `SECRET_KEY` you can forge sessions / signed cookies; chains to RCE in some setups. Ref: https://medium.com/@syedabuthahir/django-debug-mode-to-rce-in-microsoft-acquisition-189d27d08971
- [ ] **Exposed django-debug-toolbar / debug panel:** ref H1 report https://hackerone.com/reports/2078707
- [ ] Probe common exposed/health/config paths:
```
/app/tmp/healthcheck.json
/fxa-rp-events
/healthcheck
/oidc
/bet_api
/rest-api/
/api-soap/
/api/v1/ums/
/api/v1/dms/
/api/v1/transaction/
/api/v1/log/
/api/v1/reports/
/api/v1/organization/
/api/v1/legal_entity/
/api/v1/tpdr/
/api/v1/integral_docs/
/api/v1/countries
```
- [ ] `/admin/` reachable → default creds / brute (rate-limited?), user enum via login timing.
- [ ] DRF: append `?format=json`, check `/api/` browsable root for unauthenticated endpoints and mass-assignment (`07-api/03`).

## Tooling
- [ ] nuclei: bundled `exposing-django.yaml` (this folder).
- [ ] Fuzz wordlist: `https://github.com/six2dez/OneListForAll/blob/main/dict/django_long.txt`

## Impact
Debug leak → `SECRET_KEY` → session/cookie forgery → account takeover / RCE depending on stack.

## Report notes
Screenshot the debug page with `SECRET_KEY`/DB creds redacted but provably present. For toolbar/panel, show the SQL/settings panel. Do not dump full env publicly.
