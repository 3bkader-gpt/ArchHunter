# gRPC / gRPC-Web / Protobuf

**What it is:** RPC over HTTP/2 with Protobuf payloads. Often assumed "internal/typed → safe", so authz, rate-limiting, and input validation are weaker than the REST surface. Same bug classes (IDOR/BOLA, mass assignment, injection, authz) but hidden behind binary framing that scanners and most hunters skip.

## Where to look
- Content-types: `application/grpc`, `application/grpc-web`, `application/grpc-web+proto`, `application/grpc-web-text` (base64). Paths look like `/package.Service/Method` (e.g. `/user.v1.UserService/GetUser`).
- HTTP/2 required for native gRPC; gRPC-Web rides HTTP/1.1 through a proxy (Envoy, grpc-web proxy) — that's what a browser SPA talks to.
- Reflection endpoint `grpc.reflection.v1alpha.ServerReflection` — if enabled, dumps the entire service/method/message schema. Jackpot.
- `.proto` files leaked in JS bundles, mobile APKs, `/proto`, source repos, or `.js`/`.ts` generated stubs (grpc-web client).

## Recon / tooling
- [ ] **List services via reflection:** `grpcurl -plaintext host:443 list` then `list <Service>` and `describe <Method>`.
- [ ] No reflection? Recover schema from **generated JS stubs** (grpc-web `*_pb.js` / `*_grpc_web_pb.js`) or **APK** (`proto-dump`, `pbtk`, `protodump` on the binary).
- [ ] **Convert to Postman/Burp:** Burp extension **gRPC-Web** (Baeldung/blackout) or **grpc-coder** to decode/encode frames inside Repeater. `protoscope` to read/write raw wire format without the `.proto`.
- [ ] Decode a captured frame blindly: `protoc --decode_raw < frame.bin` — recovers field numbers + types even without the schema.

## Wire-format notes (attack blind, no .proto)
- gRPC length-prefixed message = 1 byte compressed-flag + 4-byte big-endian length + protobuf body.
- gRPC-Web-text = base64 of that; trailers appended as a second frame (flag `0x80`).
- Protobuf fields are `(field_number << 3) | wire_type`. You can **add unknown fields** by hand (mass assignment) and flip types with `protoscope` even without the schema.

## Test steps
- [ ] **BOLA/IDOR:** swap IDs in request messages (`user_id`, `account_id`) to another valid tenant's — same as REST, but per-method authz is frequently missing on gRPC because "only our frontend calls it". See `01-access-control/01-idor-bola.md`.
- [ ] **Method-level authz gap:** enumerate *all* methods from reflection/stubs and call admin/internal ones directly (`DeleteUser`, `SetRole`, `Internal*`, `Debug*`) — SPA never exposes them but the server accepts them.
- [ ] **Mass assignment / unknown fields:** add protobuf fields not in the client (`is_admin`, `role`, `verified`, `balance`). Protobuf silently accepts unknown fields; server may bind them. Add field numbers past what the UI sends and probe.
- [ ] **Injection into message fields:** SQLi/NoSQLi/SSRF/command-injection payloads inside string fields — validation often lives in the REST layer, not here.
- [ ] **Enum / oneof abuse:** send out-of-range enum ints, or set multiple `oneof` members, to hit unhandled server branches.
- [ ] **Type confusion:** flip a field's wire type (e.g. int→bytes) with protoscope to trigger parser edge cases / crashes.
- [ ] **Rate-limit / anti-automation bypass:** gRPC endpoints frequently unmetered vs the REST twins — replay auth-sensitive calls (OTP verify, login, coupon) here.
- [ ] **gRPC-Web ↔ native desync:** the Envoy/grpc-web proxy translates; test authz enforced at proxy but not backend, oversized messages, or trailer smuggling.
- [ ] **Reflection left on in prod** = info-disclosure finding on its own (leaks internal service map, method names, message shapes).
- [ ] **Metadata (gRPC headers) trust:** spoof `authorization`, `x-user-id`, `x-tenant`, `cookie` in call metadata — backends sometimes trust proxy-injected metadata that you can now set directly.
- [ ] **Streaming abuse:** long-lived server/bidi streams for DoS; unbounded message size (`grpc.max_receive_message_length`).
- [ ] **Deserialization / language sinks:** protobuf → app object mapping feeding unsafe deserialization; see `03-injection/08-deserialization.md`.

## Payloads / PoC
Enumerate + call a method with grpcurl (reflection on):
```bash
grpcurl -plaintext api.target.com:443 list
grpcurl -plaintext api.target.com:443 describe user.v1.UserService.GetUser
grpcurl -plaintext -d '{"user_id":"1089"}' \
  -H "authorization: Bearer <attacker_jwt>" \
  api.target.com:443 user.v1.UserService.GetUser        # IDOR: 1089 = victim
```
Mass-assignment via unknown field (schema-less, protoscope):
```
1: {"attacker@evil.com"}     # email (field 1, known)
9: 1                          # unknown field 9 → is_admin? probe values
```
gRPC-Web frame decode from a captured base64 body:
```bash
echo 'AAAAAAd...' | base64 -d | protoc --decode_raw
```

## Impact
Cross-tenant data access (BOLA), privilege escalation via hidden methods + mass assignment, injection, auth/rate-limit bypass on the unmetered surface, internal schema disclosure via reflection.

## Report notes
Show the decoded request/response (protoc --decode_raw output), the method called, and that a low-priv/attacker identity got victim data or a state change. Note whether reflection was on (how you found the method) or whether you recovered the schema from stubs/APK. Map the gRPC bug back to its severity as if it were the REST equivalent — triagers under-rate binary PoCs, so make it legible.
