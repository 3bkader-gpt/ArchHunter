# XSS Variations & Modern Bypasses

## Mechanism Overview
Cross-Site Scripting (XSS) occurs when untrusted data is rendered in a browser without proper encoding or sanitization. Modern XSS focuses on **DOM-based injection**, **CSP bypasses**, and **Blind XSS** in background admin panels.

## 1. High-Signal XSS Vectors

### DOM-Based XSS
*   **Mechanism:** JavaScript on the page reads data from a "Source" (e.g., `location.hash`) and passes it to a "Sink" (e.g., `innerHTML`, `eval()`).
*   **Offensive Pivot:** Look for `window.addEventListener('message', ...)` and `location.search` usage in JS files.
*   **Audit Goal:** Identify Sinks that execute code. Test with `javascript:alert(1)` and `<img src=x onerror=alert(1)>`.

### Blind XSS (The "Delayed Trigger")
*   **Mechanism:** Payload is stored in a database and rendered later in a separate application (e.g., an Admin Dashboard or Log Viewer).
*   **Offensive Pivot:** Inject payloads into `User-Agent`, `Referer`, `Contact Us` forms, and `Support Tickets`.
*   **Audit Goal:** Use an OAST collector (e.g., XSS Hunter, BXSS) to detect when and where your payload triggers.

### CSP & WAF Bypasses (AOSSA Logic)
*   **Mechanism:** Leveraging trusted domains or "Look-alike" characters to bypass filters.
*   **Failure:** A Content Security Policy (CSP) allow-lists a domain that hosts a JSONP endpoint or an Angular library (allowing for "Expression Injection").
*   **Audit Goal:** Identify "Gadgets" in allowed domains (e.g., `google.com/complete/search`).

---

## 2. Advanced Interpretation Gaps

### Unicode & Normalization Bypasses
*   **Mechanism:** Filters check for ASCII `<script>`, but the browser normalizes a Unicode character (e.g., `<` as `\uFF1C`) into a tag.
*   **Audit Goal:** Use Unicode homoglyphs and normalization tables to bypass regex-based WAFs.

### Multi-Step Injection
*   **Mechanism:** Payload A is safe, Payload B is safe, but when combined (e.g., via a "Profile Preview"), they form an executable script.

---

## 3. Escalation Logic
*   **XSS** -> **Session Cookie Theft** -> **Account Takeover**.
*   **XSS** -> **CSRF Token Extraction** -> **Sensitive Action Execution**.
*   **XSS** -> **DOM Defacement** -> **Phishing/Credential Harvesting**.

## 4. Operational Checklist
*   Does the app use `innerHTML`, `document.write`, or `eval()`?
*   Are there `postMessage` handlers in the JavaScript?
*   Is there a strict Content Security Policy?
*   Can you inject into fields that are likely viewed by admins (Logs, Tickets, Audit Trails)?
