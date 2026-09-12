# Infrastructure Misconfigurations & Boundary Flaws

## Objective & Context
Infrastructure misconfigurations occur when cloud assets, routing layers, and file systems are deployed with insecure defaults, dangling references, or missing boundary controls. These flaws often bypass application-layer security entirely.

## Recognition Patterns
*   **Cloud Assets:** S3 buckets, Azure Blobs, dangling CNAMEs.
*   **Exposed Services:** Admin panels, Jenkins, Grafana, Docker registries, Tomcat Manager.
*   **Parameters:** `url`, `file`, `path`, `include`, `template`.

## Attack Mechanisms & Heuristics

### 1. Subdomain Takeover
*   **Dangling DNS Records:** A CNAME record points to a third-party service (e.g., Shopify, Heroku, GitHub Pages) that has been deprovisioned.
*   **Execution:** The attacker creates an account on the third-party service and claims the dangling name.
*   **Impact:** Ability to serve malicious content, phish users, or—crucially—**set cookies scoped to the parent domain** (Cookie Tossing), leading to CSRF or session hijacking on the main application.

### 2. Path Traversal & Arbitrary File Read Filter Bypasses
*   **Classic Traversal:** Escaping directories using `../` or `..\` (Windows).
*   **Double URL Encoding (Superfluous Decoding):**
    *   `%252e%252e%252f` (`../`), `%252e%252e%255c` (`..\`)
    *   `%252e%252e/`, `..%252f`
*   **Non-Recursive Filter Stripping:**
    *   `....//....//....//etc/passwd` $\rightarrow$ when `../` is stripped once, becomes `../../../../etc/passwd`.
    *   `....\/` or `..././`
*   **Start-of-Path Validation Bypass:**
    *   `/var/www/images/../../../etc/passwd` (When backend requires path to start with `/var/www/images/`).
*   **Absolute Path Injection:**
    *   `/etc/passwd` or `C:\Windows\win.ini` (When application appends parameter directly to root instead of sanitizing).
*   **Null Byte Termination (Legacy Runtimes):**
    *   `../../../etc/passwd%00.png` or `../../../etc/passwd\0.jpg`
*   **Node.js & OS Quirks:** Bypassing `path.normalize()` on Windows using device names (`CON`, `PRN`, `AUX`).


### 3. Exposed Proxies & Internal Routing
*   **Open Proxies:** Finding an exposed port (e.g., Squid, SOCKS) that allows unauthenticated request forwarding.
*   **Impact:** Attacker tunnels through the proxy to access internal VPC resources, bypassing perimeter firewalls.

### 4. Information Disclosure & Secrets Leakage
*   **Debug Endpoints:** Exposing `server-status`, `debug.log`, or framework-specific debug pages (e.g., Django debug mode, Spring Boot Actuator).
*   **Source Control:** `.git` directories or exposed commits containing API keys, AWS credentials, or Slack tokens.
*   **Public Cloud Storage:** Misconfigured permissions on Google Drive links or S3 buckets containing sensitive PII or organizational secrets.

## Chaining Logic
*   `Subdomain Takeover` -> `Cookie Tossing` -> `Parent Domain Session Manipulation`
*   `Path Traversal` -> `Read Configuration Files (e.g., SECRET_KEY)` -> `Forge Session Cookies` -> `RCE`
*   `Exposed Jenkins Console` -> `Script Execution` -> `AWS IAM Credential Theft` -> `Cloud Compromise`

## Remediation & Validation
*   Implement continuous DNS monitoring for dangling records.
*   Use absolute, canonicalized paths and verify they reside within the expected base directory.
*   Restrict access to internal administrative interfaces using identity-aware proxies (e.g., Cloudflare Access, BeyondCorp).
