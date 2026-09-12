# Parser Differential & Transformation Abuse

## Mechanism Overview (AOSSA Ch 8/12/16)
Vulnerabilities occur when an architecture involves multiple processing layers (e.g., CDN -> Proxy -> WAF -> Backend API) that interpret protocol boundaries, character encodings, or data shapes differently. When Layer A and Layer B disagree on what a message *means* or where it *ends*, an attacker can smuggle payloads or bypass security filters.

## 1. Boundary Desynchronization & Smuggling
Occurs when different parsers rely on conflicting length indicators or delimiters.

### **Conflicting Length Mismatch**
*   **Mechanism:** A protocol allows multiple ways to specify length (e.g., HTTP `Content-Length` vs `Transfer-Encoding`, or custom TLVs).
*   **Failure:** The proxy uses Indicator A to determine the message end, while the backend uses Indicator B. The "surplus" bytes are interpreted by the backend as the beginning of the *next* request.
*   **Audit Goal:** Send messages with conflicting boundary definitions.

### **Delimiter Smuggling & Interpretation Desync**
*   **Mechanism:** Injecting a delimiter that is ignored by the front-end but honored by the backend.
*   **Failure:** `user=alice\nRole:admin`. A high-level WAF treats this as a single string. A low-level backend splits it into two headers.
*   **Offensive Pivot:** Target trailer fields, extension headers, or inject `\0` (NUL) to cause high-level vs C-library desyncs.

## 2. Semantic Mismatch (Differential Parsing)
Failures arising from how different languages or libraries parse the same structured data.

### **JSON/XML Duplicate Key Confusion**
*   **Mechanism:** Two components use different parsers for the same data payload.
*   **Failure:** Attacker sends `{"id": 1, "id": 2}`. The WAF checks the first key (sees `1`, allows it), but the backend uses the second key (processes `2`).
*   **Audit Goal:** Identify "Parser Conflicts" by mutating JSON arrays, duplicate keys, and malformed types.

### **Protocol Downgrade Ambiguity (HTTP/2 & HTTP/3 to HTTP/1.1 Smuggling)**
*   **Mechanism:** Edge proxies receive binary HTTP/2 frames and downgrade them to HTTP/1.1 plaintext streams to communicate with internal backend microservices.
*   **Failure Modes:**
    1.  **H2.CL Desync:** The frontend uses the HTTP/2 `DATA` frame length to delineate the body, but passes a forged `content-length` header to the backend. The backend reads only `content-length` bytes, treating the remainder as the prefix of the next request.
    2.  **H2.TE Desync:** The attacker sends `transfer-encoding: chunked` in an HTTP/2 request. HTTP/2 forbids `transfer-encoding`, but edge proxies often fail to strip it during downgrade. The backend prioritizes `Transfer-Encoding` over `Content-Length`, enabling classic HTTP/1 request smuggling.
    3.  **CRLF Injection in HTTP/2 Headers / Pseudo-Headers:**
        *   HTTP/2 headers are binary length-value strings, allowing literal `\r\n` characters in header values (e.g. `:path: /test\r\nInjected-Header: evil` or `foo: bar\r\n\r\nGET /admin HTTP/1.1`).
        *   When downgraded to plaintext HTTP/1.1, the injected newlines split the stream into separate HTTP requests (Request Tunneling).

## 3. Transformation & Canonicalization Abuse
The sequence of `Decode -> Filter -> Interpret` is critical.

### **Double-Decoding Bypass**
*   **Mechanism:** An application filters dangerous strings (e.g., `../`), but then passes the string to another layer that decodes it *again*.
*   **Failure:** Attacker sends `%252e%252e%252f`. Layer 1 decodes to `%2e%2e%2f` (passes filter). Layer 2 decodes to `../` (LFI).
*   **Audit Goal:** Test nested encodings (`%25`, `&amp;amp;`) on every input.

### **Unicode Normalization & Case-Folding**
*   **Mechanism:** Filtering happens *before* Unicode normalization.
*   **Failure:** Two different Unicode characters fold to the same ASCII character (e.g., Turkish `İ` and `i`). The filter allows "admİn". The backend normalizes it to "admin", resulting in Account Takeover.

### **Character Expansion Overflows**
*   **Mechanism:** When data is escaped or encoded, it grows.
*   **Failure:** Unicode `&` to `&amp;` is 5x expansion. If a buffer uses a fixed expansion factor, this causes a Heap/Stack Overflow.

## 4. Smuggling Escalation Logic
*   **Cache Poisoning:** Smuggling a request that causes the backend to serve an XSS payload, which is then cached by the CDN.
*   **WAF Bypass:** Smuggling internal administrative commands past the proxy because it only inspected the "outer" benign request.
*   **Data Exfiltration:** Leaving a "half-open" request on the backend so the *next* legitimate user's request is appended to the attacker's smuggled payload (stealing session cookies).
