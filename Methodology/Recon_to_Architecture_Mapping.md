# Recon-to-Architecture Mapping & Heuristics

## Operational Philosophy
Raw reconnaissance data (subdomains, IPs, headers, screenshots) is operationally useless until it is translated into an architectural mental model. A professional hunter does not attack an IP address; they attack the *parser* behind the IP. This guide defines how to transform raw recon into a Data Flow Diagram (DFD) and identify Trust Boundaries.

## 1. Transforming Recon into Architectural Models

### Step 1: Grouping by Shared Identity Providers (IdP)
**Raw Recon:** You find `app.target.com`, `admin.target.com`, and `api.target.com`. They all redirect to `auth.target.com` (or Okta/Auth0) for login.
**Architecture Translation:** 
*   These are not separate targets; they are **clients in the same SSO ecosystem**. 
*   **Trust Boundary:** The OAuth token validation. 
*   **Attack Path:** Tokens issued for `app.target.com` may be improperly accepted by `api.target.com` (Audience Confusion).

### Step 2: Interpreting SPA Fingerprints (Single Page Applications)
**Raw Recon:** `app.target.com` serves a large React/Vue/Angular bundle and makes requests to `api.target.com`.
**Architecture Translation:**
*   `app.target.com` is just static file hosting (S3/CloudFront). It has NO backend execution context.
*   `api.target.com` is the actual execution boundary.
*   **Trust Boundary:** The browser executing the SPA vs. the backend API.
*   **Attack Path:** Do not look for Server-Side Injection on `app.target.com`. Look for Client-Side XSS in the SPA, and look for IDOR/Broken Access Control on the API.

### Step 3: Deconstructing Cross-Subdomain Trust
**Raw Recon:** `marketing.target.com` is hosted on WordPress/WPEngine, while `app.target.com` is the core SaaS application.
**Architecture Translation:**
*   Cookies scoped to `.target.com` will be sent to `marketing.target.com`.
*   **Trust Boundary:** Cookie scoping and Same-Origin Policy (SOP).
*   **Attack Path:** A vulnerability (like XSS or Subdomain Takeover) on the weak marketing site can be used to toss cookies or steal sessions from the secure core app.

### Step 4: The Hidden Parser Identification
**Raw Recon:** An endpoint accepts a file upload (e.g., PDF, image, CSV) or an XML/JSON payload.
**Architecture Translation:**
*   "Data cannot move itself." There is a background worker or library parsing this input.
*   **Trust Boundary:** The transition from raw bytes to structured memory objects.
*   **Attack Path:** ImageMagick exploits for images, XXE for XML, Deserialization for complex objects, or blind SSRF if the parser fetches external resources (e.g., PDF generation).

### Step 5: Background Worker & Async Workflow Inference
**Raw Recon:** You submit a form, and the response is immediate, but an email arrives 2 minutes later, or a report generation takes 30 seconds.
**Architecture Translation:**
*   The web server is dropping a message into a queue (Kafka, RabbitMQ, SQS). A separate, disconnected worker process is picking it up.
*   **Trust Boundary:** The queue message schema. The worker likely executes in a *different* network segment with *higher* privileges than the web server.
*   **Attack Path:** Blind SSRF, Command Injection, or Deserialization. The web server might filter input, but the worker might assume queued messages are "safe" (internal trust).

## 2. Advanced Attack Surface Heuristics

### Wildcard Scope Triage
*   **Heuristic:** If `*.target.com` is in scope, sort subdomains not by popularity, but by **technological divergence**.
*   **Logic:** The core app (`app.target.com`) is heavily audited. The forgot-about acquisition (`legacy-api.target.com`) or staging environment (`staging-api.target.com`) running outdated frameworks is where the perimeter is weak. Look for divergent server headers (e.g., IIS instead of Nginx).

### Header-Based Infrastructure Fingerprinting
*   **Heuristic:** Headers tell you the routing path.
*   **Logic:** 
    *   `X-Amz-Cf-Id` -> AWS CloudFront is in front. (Look for Cache Deception/Poisoning).
    *   `Server: Envoy` or `Server: Kong` -> Modern service mesh. (Look for HTTP Request Smuggling or routing discrepancies).
    *   `X-Powered-By: Express` vs `X-Powered-By: PHP` on the same subdomain -> Path-based routing to different microservices.

### Screenshot-Driven Prioritization
*   **Heuristic:** Use tools like `gowitness` or `aquatone`. Don't look at the text; look at the **authentication paradigm**.
*   **Logic:** 
    *   Standard login page -> Likely integrated with SSO. Harder.
    *   Basic Auth popup -> Legacy internal tool. High value.
    *   Default framework pages (Spring Boot, Tomcat, Jenkins) -> Misconfiguration. High value.
    *   "Sign up" enabled on a corporate dashboard -> Registration bypass potential.

### TLS Neglect Heuristics
*   **Heuristic:** Subdomains with invalid, expired, or mismatched TLS certificates are goldmines.
*   **Logic:** If the ops team forgot to renew the cert, they forgot to patch the server. These are orphaned assets.

### State-Machine Discovery (The Multi-Step Flow)
*   **Heuristic:** Any process requiring 3+ steps (e.g., Cart -> Shipping -> Payment -> Confirm) relies on server-side state.
*   **Logic:** The server must remember what happened in Step 1 when executing Step 3. 
*   **Attack Path:** State Desynchronization. What happens if you do Step 1, then Step 3? What if you do Step 1, wait for session expiry, and do Step 2? What if you drop the flow and start a concurrent one?

## 3. The "Recon to Model" Checklist

When you finish running Subfinder/Httpx/Nmap, answer these questions:
1.  **Identity:** Where is the IdP? How many subdomains share the same session cookie?
2.  **Routing:** What is the gateway/CDN? Are requests being routed by path (`/api/v1/*` goes to a different server than `/images/*`)?
3.  **Parsers:** Where does user input get transformed? (Image uploads, JSON decoding, Markdown rendering).
4.  **Async:** Which actions are processed out-of-band? (Webhooks, email generation, export functions).

*Model these 4 elements, and you have your attack map.*
