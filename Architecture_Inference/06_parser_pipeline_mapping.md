# 06 — Parser Pipeline Mapping

## Goal
Map the sequence of parsers and interpretation layers (Proxies, WAFs, Middleware, Backends) to identify interpretation desyncs.

## Pipeline Inference Heuristics

### 1. The "Ambiguity Response" Test
*   **Signal:** Sending a double-newline `\n\n` in a header results in a 400 from the CDN but a 200 from the direct IP.
*   **Inference:** Discovered a **Parser Boundary** where the CDN and Backend disagree on message termination.
*   **Offensive Pivot:** [Parser Differential Abuse](../skills/infrastructure/parser_differential_abuse.md).

### 2. Transformation Layer Identification
*   **Signal:** Input containing `<` is reflected as `&lt;` on the first request, but as `<` on a subsequent `/preview` endpoint.
*   **Inference:** A **Normalization Gap** exists between the write-parser and the read-parser.
*   **Offensive Pivot:** [Semantic Transformation Abuse](../skills/infrastructure/parser_differential_abuse.md).

### 3. Protocol Downgrade Clues
*   **Signal:** The site supports HTTP/2 but response headers include `X-Backend-Server: HTTP/1.1`.
*   **Inference:** An **H2-to-H1.1 Downgrade Gateway** exists. 
*   **Offensive Pivot:** Inject newlines in HTTP/2 headers to smuggle requests.

### 4. RFC Specification Divergence (The Protocol 0-Day Seed)
*   **Root Cause:** RFCs define the strict contract of the internet (RFC 7230/9110 HTTP/1.1, RFC 7540/9113 HTTP/2, RFC 3986 URI Generic Syntax, RFC 6455 WebSockets). Zero-day parser differential flaws arise when developers or proxy engines either fail to implement strict RFC rules or resolve RFC ambiguities differently.
*   **Audit Pivot:** Compare how the edge proxy and backend servlet handle:
    - Bare line feeds (`\n` vs `\r\n`) in header values.
    - Multiple duplicate headers (`Content-Length: 10`, `Content-Length: 20`).
    - Obsolete line folding (leading spaces/tabs on header continuation lines).
    - Trailing dots in hostnames (`target.com.`).

## Parser Interaction Matrix

| Proxy Layer | Backend Layer | Likely Desync Surface |
| :--- | :--- | :--- |
| **Cloudflare** | **Apache/PHP** | URL Normalization / Delimiters. |
| **AWS ALB** | **Lambda (JS)** | JSON Parser (Duplicate Keys). |
| **Nginx** | **gRPC/Go** | Length-field / HTTP/2 Trailers. |

## Operational Output
A **Parser Sequence Map**. This feeds the final **DFD Generation**.
