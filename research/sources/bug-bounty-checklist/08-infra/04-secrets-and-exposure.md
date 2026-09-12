# Secrets, Misconfig & Info Exposure

**What it is:** Leaked credentials, exposed config, and debug surfaces. Low-effort, high-value.

## Where to look
- [ ] `.git/`, `.svn/`, `.env`, `.DS_Store`, backup archives (`00-recon/03`).
- [ ] Exposed dashboards: `/actuator`, `/metrics`, `/debug`, `/phpinfo`, `/server-status`, `/.well-known`.
- [ ] Cloud buckets: open S3/GCS/Azure (list + read + sometimes write). `s3://` guessing from asset URLs.
- [ ] **Public source**: GitHub/GitLab/Postman/Trello/Pastebin for org keys, `trufflehog`, `gitleaks`, github dorks.
- [ ] JS/mobile app hardcoded keys (`00-recon/05`).
- [ ] Heapdumps/`/actuator/heapdump`, thread dumps.
- [ ] Error pages / stack traces leaking paths, versions, SQL.
- [ ] `robots.txt`, `sitemap.xml`, source maps revealing hidden paths.
- [ ] Verbose API errors, debug flags (`?debug=1`, `?test=1`).
- [ ] Default creds on admin/CI/monitoring panels.

## Verify key impact (safely)
- AWS key → `aws sts get-caller-identity` only (identity, no data touch).
- Google Maps/API key → check if it bills / is restricted.
- Firebase → test open read rules on a test path.
- Slack/webhook → do not post; report the leak.

## Impact
Ranges from info disclosure to full cloud compromise depending on the secret.

## Tools
`trufflehog`, `gitleaks`, `git-dumper`, `nuclei` exposures/misconfig, cloud CLIs, `s3scanner`.

## 🎯 PoC — Request → Response (exposed .git → source + secrets)

```http
GET /.git/config HTTP/2
Host: target.com
```
```http
HTTP/2 200 OK
Content-Type: text/plain

[core]
	repositoryformatversion = 0
[remote "origin"]
	url = https://github.com/target/backend.git
```
`.git` served → `git-dumper` reconstructs the repo. Then confirm a leaked AWS key minimally:
```bash
aws sts get-caller-identity --profile leaked
```
```json
{"UserId":"AIDA...","Account":"1234567890","Arn":"arn:aws:iam::1234567890:user/ci-deploy"}
```
Identity only — no data touched.

## Secret → minimal-proof map (by type)
```
AWS akia/asia    aws sts get-caller-identity            (identity only; check role via iam:GetUser deny is fine)
GCP sa json      gcloud auth activate + gcloud projects list --limit=1
Azure            az login --service-principal ... ; az account show
GitHub PAT ghp_  GET /user + X-OAuth-Scopes header (reveals scope, incl. repo/admin)
Slack xox        auth.test (identity) — never post
Stripe sk_live   /v1/balance (read) — restricted rk_ vs full sk_ matters; note mode
SendGrid/Mailgun scopes/whoami read — do NOT send mail
Twilio           /Accounts.json read — SMS costs money, don't send
Google API AIza  check which API + referer/IP restriction (Maps bills)
Firebase         read a test path against open rules; check write rules
JWT signing key  forge a token → sign-in (auth impact) — link 04-auth-session/03
DB URI           note reachability; do not connect/dump on live
npm/Docker/CI    registry whoami; do not publish/pull private
.NET machineKey  ViewState forge → RCE  (link 03-injection/08)
```

## Deep cuts — where secrets actually hide
- [ ] **Git history & deleted commits:** `trufflehog git --since-commit`, `noseyparker` on full history, and the **GitHub Events/commit API** for force-pushed/"deleted" commits still retrievable by SHA; dangling blobs.
- [ ] **Org-wide sweep:** `trufflehog github --org`, `github-dorks`, gists, forks, and *employees'* personal repos (found via `00-recon/01` LinkedIn→GitHub pivot).
- [ ] **Source maps & bundles:** `.js.map` → original source with inline config/keys (`00-recon/05`); `__NEXT_DATA__`, `/config.json`, `env.js`, `window.__ENV`.
- [ ] **Other paste/collab surfaces:** Postman public workspaces, Apiary, Pastebin, Trello, JSFiddle, public S3/GCS index listings, Docker Hub image layers (`docker history`/`dive`), CI logs (Travis/CircleCI/GH Actions artifacts).
- [ ] **S3/GCS/Azure beyond read:** test `s3 ls`, then `s3 cp` a benign object (write), and public-ACL set — write/ACL is a much stronger finding than read (`06-file-upload/03` presigned link).
- [ ] **Actuator/heapdump mining:** `/actuator/heapdump` → `jhat`/`jvisualvm`/strings for live tokens & sessions; `/actuator/env` masks but `/configprops`/`/mappings` leak; Spring `/actuator/gateway/routes` → SSRF.
- [ ] **Verbose errors & headers:** stack traces (paths, versions, SQL), `X-Powered-By`, `Server`, debug flags (`?debug=1`), GraphQL error leaks.

## Report notes
Prove the secret works with the least intrusive call (see map). Never pivot into data/systems beyond identity confirmation. State scope/mode (restricted vs full, test vs live). Rotate-worthy secrets → flag urgency and note it may be live in the report.
