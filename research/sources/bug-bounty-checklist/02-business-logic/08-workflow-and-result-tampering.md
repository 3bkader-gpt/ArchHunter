# Workflow, State & Result Tampering

**What it is:** Abusing multi-step flows and trusting client-submitted results. Skip steps, replay, or submit the "correct" outcome directly.

## Result / exam / quiz tampering
- [ ] Submit the graded result directly instead of answering (server trusts the answer body).
- [ ] Example (Semrush Academy): retake exam, then replay the last request with correct answers; body was JSON where `"1"`=true, `""`=false → set all correct → instant certificate.
```
{"answers":{"503":"","505":"1","591":"1","1340":"1","1351":"1","1358":"1","1365":"1", ...}}
```
- [ ] Skip verification/KYC steps by calling the completion endpoint.

## State-machine abuse
- [ ] Perform actions out of order (checkout before payment, ship before pay).
- [ ] Replay a one-time transition (approve twice, submit twice).
- [ ] Revert a locked state (`completed → editing`) to change data post-lock.
- [ ] Reach a state the UI never offers by setting `status`/`step` directly.

## Auth flag / ACL tampering (app layer)
- [ ] Observe request+response for permission params (name-value, JSON, XML, cookie).
- [ ] Suspicious ACL param → decode value (hex/binary/string), tamper flags (`1↔0`, `Y↔N`).
- [ ] Fuzz logically + brute + deduce to crack the scheme → escalate / bypass authorization.

## Impact
Free certifications, privilege gain, integrity break, authZ bypass.

## 🎯 PoC — Request → Response (submit graded result directly)

Skip answering; POST the "all correct" body straight to the grade endpoint:
```http
POST /api/v2/exams/exm_55/submit HTTP/2
Host: api.target.com
Authorization: Bearer <mine>
Content-Type: application/json

{"answers":{"503":"1","505":"1","591":"1","1340":"1","1358":"1","1365":"1"}}
```
```http
HTTP/2 200 OK
Content-Type: application/json

{"score":100,"passed":true,"certificate_url":"/certs/exm_55/me.pdf"}
```
Server graded client-submitted answers with no server-side answer key = instant certificate.

## Deep cuts — state-machine & trust-boundary tampering
- [ ] **Signed/HMAC state-token tamper or swap:** flows carry a `state`/`step`/`resume` token that's base64-JSON (not signed) or signed-but-not-bound → edit `step:3`, or reuse a later-step token from another flow to jump ahead.
- [ ] **Idempotency-key reuse for state advance:** replay the key of a completed step to re-trigger or skip a transition.
- [ ] **Webhook/callback replay to advance state:** re-send a captured provider webhook (payment/KYC/identity) or forge it (weak/absent signature) to flip `pending→approved` (`07-api/05`).
- [ ] **Self-approval in multi-actor flows:** approve your own request where maker≠checker is assumed but not enforced (submit as A, approve as A via the approver endpoint).
- [ ] **KYC / verification bypass via completion callback:** call the "verification complete" endpoint directly, or reuse another (your) verified session's token.
- [ ] **E-sign / agreement / consent skip:** reach the post-signature state without the signing step; toggle `agreed:true`/`signed_at`.
- [ ] **Backward transition (unlock locked data):** `completed→draft`, `shipped→pending`, `submitted→editing` to change data after the lock point.
- [ ] **Referral/attribution tamper:** set the `referrer`/`utm`/`attributed_to` to yourself post-hoc to claim credit for others' conversions.
- [ ] **Time-window tamper:** back/forward-date `submitted_at`, `expires_at`, `scheduled_for` to land inside a closed window (contest entry, early access, deadline).
- [ ] **Result trust (extend the exam example):** any client-submitted score/outcome/computed value — game scores, quiz grades, fitness/points totals, tax/loan calc results — resubmit the ideal outcome.

## Report notes
Show the tampered result/state accepted server-side and the reward granted (certificate, approval, access). For state-machine bugs, diagram the legal transitions and the illegal one you forced.
