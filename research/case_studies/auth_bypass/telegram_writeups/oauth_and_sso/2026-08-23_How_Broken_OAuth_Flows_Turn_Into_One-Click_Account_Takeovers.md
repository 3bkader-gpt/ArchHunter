# How Broken OAuth Flows Turn Into One-Click Account Takeovers

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-08-23
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://medium.com/@tanvir.infosec/how-broken-oauth-flows-turn-into-one-click-account-takeovers-a13a67aa36c0?source=rss------bug_bounty-5](https://medium.com/@tanvir.infosec/how-broken-oauth-flows-turn-into-one-click-account-takeovers-a13a67aa36c0?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## How Broken OAuth Flows Turn Into One-Click Account Takeovers


--


Listen


Share


> A practical guide to the missing relationship that causes most real-world OAuth vulnerabilities.


A practical guide to the missing relationship that causes most real-world OAuth vulnerabilities.


OAuth vulnerabilities are rarely caused by OAuth itself.


More often, the protocol is implemented correctly — except for one missing relationship:


> “This authorization response must belong to the login transaction that started in this browser.”


“This authorization response must belong to the login transaction that started in this browser.”


Break that relationship, and an apparently harmless OAuth callback can become login CSRF, an account-linking vulnerability, session confusion, or — combined with other weaknesses — a full account takeover.


This piece uses a fictional application, PhotoVault, and a deliberately vulnerable OAuth implementation to walk through the mechanics. It’s written for people securing systems they own or are authorized to test. The framing borrows its title from a well-known genre of OAuth token-leakage research (Frans Rosén’s “dirty dancing” writeups on Detectify are the classic reference point); this piece takes a different angle — transaction binding rather than token-leakage gadgets — using original examples throughout.


In this piece:

- Why the authorization code alone proves nothing
- The missing relationship that causes most OAuth bugs
- Login CSRF vs. account linking vs. account takeover — and why they’re not the same thing
- How state, PKCE, and OIDC nonce actually protect you
- A transaction-based architecture you can build
- An audit checklist for reviewing any OAuth implementation

## 1. The Scenario


PhotoVault lets users log in with email/password or “Continue with ExampleID.” It uses standard OAuth/OIDC:


```
Browser → PhotoVault → ExampleID (auth) → PhotoVault /oauth/callback → session created
```


In a secure implementation, PhotoVault needs to answer one question before trusting anything in that callback:


> Is this authorization response actually the response to the OAuth transaction this browser initiated?


Is this authorization response actually the response to the OAuth transaction this browser initiated?


That sounds obvious. But a lot of real-world code effectively does this:


```
@app.get("/oauth/callback")def callback(code):    tokens = exchange_code(code)    user = get_user_from_tokens(tokens)    session.login(user)    return redirect("/dashboard")
```


Notice what’s missing: no state, no PKCE verification, no binding between the browser's original login attempt and this callback. That's where the interesting behavior begins.


## 2. What OAuth Is Actually Doing


The authorization code flow has two phases.


Phase A — Authorization. The client sends the browser to an authorization server:


```
GET /authorize?    client_id=photovault&    redirect_uri=https%3A%2F%2Fphotovault.example%2Foauth%2Fcallback&    response_type=code&    scope=openid%20profile
```


The user authenticates, and the authorization server redirects back with a code:


```
HTTP/1.1 302 FoundLocation: https://photovault.example/oauth/callback?code=AUTHORIZATION_CODE
```


That code isn’t a credential — it’s an artifact the client exchanges at the token endpoint:


```
authorization code → token endpoint → access token / ID token → session
```


RFC 6749 requires that codes be bound to the client and redirect URI, expire quickly, and never be reused. The security property that matters here: the code should only be usable in the context it was issued for.


## 3. Where “Dirty Dancing” Enters


Two users, PhotoVault:

- Alice — the victim
- Mallory — the attacker

The dangerous scenario usually isn’t Mallory stealing Alice’s password. It’s the application accidentally letting Mallory’s OAuth authorization response land inside Alice’s browser session.


The browser doesn’t inherently know whose response is whose — the application has to enforce that. That’s exactly what state, PKCE, OIDC nonce, strict redirect URI validation, and transaction binding are for.


RFC 9700 explicitly requires clients to prevent CSRF and authorization-code injection, naming state, PKCE, and nonce as the relevant defenses.


## 4. The Vulnerable Version


```
@app.get("/login/exampleid")def login():    url = (        "https://id.example/authorize"        "?client_id=photovault"        "&response_type=code"        "&redirect_uri=https://photovault.example/oauth/callback"        "&scope=openid%20profile"    )    return redirect(url)
```


```
@app.get("/oauth/callback")def callback(code):    token_response = oauth.exchange_code(code)    identity = token_response["id_token"]    user = find_or_create_user(identity)    session["user_id"] = user.id    return redirect("/dashboard")
```


Ask the obvious security question: what proves that code came from a login transaction this browser initiated?


Nothing does.


## 5. The Missing Relationship


A secure flow generates and stores a state value, sends it in the authorization request, and checks it comes back unchanged:


```
Original state:  9f7c...a31Callback state:  9f7c...a31   → match, accept
```


Without that check, an attacker-controlled authorization result can be processed as if it were the victim’s — this is the fundamental bug class underlying almost everything below.


## 6. From CSRF to Account Linking


Where this gets serious is in account-linking flows, not just login. Consider a “Link ExampleID” feature in account settings:


```
@app.get("/oauth/link/callback")def link_callback(code):    tokens = exchange_code(code)    identity = get_identity(tokens)    link_identity(        current_user=session["user_id"],        external_identity=identity    )    return redirect("/settings")
```


This code says: “whatever identity arrives at this callback gets linked to whoever is currently logged in.” If the OAuth transaction itself isn’t bound to the user who started it, that’s a dangerous assumption.


A safer design tracks an explicit transaction:


```
transaction_id ├─ browser/session binding ├─ expected provider ├─ expected redirect URI ├─ PKCE verifier ├─ nonce ├─ expiration └─ intended operation = LINK
```


The callback must satisfy all of these before it’s allowed to mutate anything.


## 7. Authentication vs. Authorization — Not the Same Question


This distinction matters more than most people give it credit for:


Operation Question it answers Login “Which user is this?” Account link “Modify the currently authenticated account by adding this external identity.”


Login just identifies someone. Account linking mutates persistent state. The more powerful the side effect, the stronger the transaction binding needs to be.


## 8. Why One Click Can Be Enough


Browser-based OAuth flows are just redirects — completely normal browser behavior. A victim doesn’t need to type or paste anything; a link click can be sufficient.


```
attacker-controlled OAuth transaction              +victim's authenticated browser              +callback lacking transaction binding              =unexpected security state change
```


The actual impact varies by application — it could be login CSRF, account linking, session confusion, authorization-code injection, unintended consent, or privilege confusion. A full account takeover usually requires an additional step — typically an attacker-controlled identity getting linked in a way that later lets the attacker authenticate as the victim. Don’t assume “missing state" automatically equals "account takeover" — trace the actual chain:


```
OAuth flaw → unexpected identity/session relationship → account-state change    → authentication path → potential account takeover
```


## 9. Defense 1: state, Done Properly


```
state = secrets.token_urlsafe(32)session["oauth_state"] = state
```


Then on callback:


```
received_state = request.args["state"]expected_state = session.get("oauth_state")
```


```
if not expected_state:    reject()if not secrets.compare_digest(received_state, expected_state):    reject()del session["oauth_state"]
```


The value must be unpredictable, tied to the correct session, validated, single-use, and short-lived. RFC 9700 describes exactly this: a one-time value securely bound to the user agent.


A common false sense of security: just checking that state is present, not that it matches a server-generated value:


```
# This proves nothing:if request.args.get("state"):    accept()
```


Or worse — storing whatever the client sends and comparing it against itself:


```
session["state"] = request.args["state"]if request.args["state"] == session["state"]:    accept()  # attacker controls both sides of this comparison
```


The correct mental model: server generates the secret → stores it → sends it out → the same value must come back. Not: client supplies a value → server remembers it → server accepts it.


## 10. Defense 2: PKCE


PKCE binds the authorization code to whoever started the request, independent of state.


```
code_verifier (random secret, kept client-side)        ↓ SHA-256, base64urlcode_challenge (sent in the authorization request)
```


The authorization request carries only the challenge. The token request later carries the verifier, and the server checks SHA256(verifier) == challenge. An attacker who intercepts the authorization code but never had the verifier can't redeem it.


Modern guidance recommends PKCE for public clients and confidential clients, with S256 as the preferred method — and importantly, PKCE is no longer just a mobile-app recommendation. RFC 9700 explicitly extends its protection to web applications. A modern web app should default to:


```
Authorization Code + PKCE + state/nonce as appropriate + strict redirect URI
```


## 11. Putting It Together: A Secure Implementation


Starting the transaction:


```
state = secrets.token_urlsafe(32)verifier = secrets.token_urlsafe(64)challenge = base64url(sha256(verifier.encode()))
```


```
oauth_transaction = {    "state": state,    "code_verifier": verifier,    "created_at": now(),    "purpose": "login",}# bind oauth_transaction to the browser session
```


Validating the callback:


```
transaction = session.get("oauth_transaction")if not transaction:    reject()
```


```
if not constant_time_equal(state, transaction["state"]):    reject()if now() > transaction["created_at"] + timedelta(minutes=5):    reject()tokens = token_endpoint.exchange(    code=code,    code_verifier=transaction["code_verifier"],    redirect_uri=EXPECTED_REDIRECT_URI,)del session["oauth_transaction"]
```


The resulting chain is much stronger — every step from browser to authenticated identity is explicitly verified, not assumed.


## 12. Don’t Forget OIDC nonce


If you’re using OpenID Connect, the ID token itself carries a nonce that must match what you sent in the authentication request. It's a second, independent binding — RFC 9700 treats it as a CSRF-relevant protection when used this way.


## 13. Redirect URIs and the return_to Trap


Authorization servers should use exact redirect URI matching — https://photovault.example/oauth/callback, not a wildcard like https://photovault.example/*. Loose matching or normalization quirks can route authorization responses somewhere unintended, and RFC 9700 specifically warns that open redirectors can be used to exfiltrate codes and tokens.


A related, very common mistake lives entirely inside the application:


```
@app.get("/oauth/callback")def callback(code, return_to):    authenticate(code)    return redirect(return_to)   # open redirect
```


If return_to can point anywhere, your OAuth implementation can be flawless and you'll still have an open redirect. Use an allowlist instead:


```
ALLOWED_DESTINATIONS = {"/dashboard", "/settings", "/profile"}
```


```
if return_to not in ALLOWED_DESTINATIONS:    return_to = "/dashboard"
```


Or better: don’t carry arbitrary destinations through the OAuth response at all.


## 14. How to Audit an OAuth Implementation


Don’t start by reading line by line — draw the trust boundaries first:


```
┌──────────────────┐        │ Identity Provider │        └─────────┬─────────┘                   │ authorization                   ▼┌─────────┐   ┌───────────┐   ┌──────────┐│ Browser │──▶│Application│──▶│ Database │└─────────┘   └───────────┘   └──────────┘
```


Then ask, for every OAuth-touching endpoint:

- Who controls state?
- Who controls redirect_uri?
- Who generates code_verifier?
- Who decides which local account gets authenticated?
- Who decides which external identity gets linked?
- Can any of those decisions be influenced by the browser?

A surprising number of real OAuth bugs fall out of just answering these six questions honestly.


A useful follow-up: for every /oauth/callback, write down exactly what executes after it — exchanging the code, validating identity, creating a session, writing to the database — and classify each action by how powerful its side effect is (authentication, authorization grant, account mutation, financial mutation). The more powerful the effect, the stronger the transaction binding needs to be.


## 15. Three Outcomes That Get Confused


Login CSRF — the attacker causes the victim’s browser to become authenticated as the attacker. Still serious, especially if the victim then enters sensitive data believing they’re in their own account.


Account linking — the attacker causes their own external identity to become associated with the victim’s account. How serious this is depends entirely on how the app treats linked identities afterward.


Account takeover — requires an actual path from attacker-controlled state to future authentication as the victim:


```
OAuth flaw → external identity linked → app trusts linked identity   → attacker authenticates using that identity → victim account
```


Whether that full chain exists has to be demonstrated, not assumed — this is where a lot of bug reports overstate severity.


## 16. Testing This Safely


If you’re testing an application you own, build a proper test harness: a victim test account, an attacker test account, and a test OAuth provider. Log transaction IDs, state, session IDs, client ID, redirect URI, issuer, nonce, PKCE challenge, timestamp, and result — but never log passwords, tokens, client secrets, or authorization codes outside a tightly controlled environment.


The goal isn’t to obtain someone else’s credential — it’s to answer one question:


> Can one OAuth transaction be accepted in the context of a different browser transaction?


Can one OAuth transaction be accepted in the context of a different browser transaction?


A good way to structure this is a transaction-comparison table:


Property Transaction A Transaction B Browser session Victim Attacker OAuth provider ExampleID ExampleID state A B PKCE verifier A B Authorization code A B Purpose Login Login Expected account Victim Attacker


Then try mismatched combinations — Browser A + State B + Code B, or Browser A + State A + Code B — and confirm the application rejects every one of them.


## 17. Multi-Provider Apps: Mix-Up Attacks


If PhotoVault supports Google, GitHub, Microsoft, and Apple, the app needs to know not just “which user,” but “which provider.” Without that check, a response from one identity provider could be misinterpreted in the context of another. RFC 9700 recommends verifying the authorization server’s iss (issuer) claim as a defense against exactly this — so your stored transaction should include the expected provider and issuer, and the callback should check both.


## 18. A Production-Grade Architecture


Instead of scattering OAuth state across controllers, centralize it:


```
class OAuthTransaction:    id    session_id    provider    issuer    purpose    state_hash    nonce_hash    pkce_verifier    created_at    expires_at    consumed_at
```


```
/start → create transaction → Authorization Server → /callback    → load transaction → verify session, state, issuer, nonce, PKCE    → exchange code → consume transaction → complete operation
```


Two properties matter here beyond validation: transactions should be single-use (mark them consumed_at and reject any repeat callback — codes themselves must also be single-use per RFC 6749) and expiring (a five-minute window is a reasonable starting point, tuned to your risk tolerance).


## 19. Don’t Trust “It’s Handled by the Library”


Frameworks often hide state generation, PKCE, nonce, and callback validation behind a single call like oauth.login(). Convenient — but dangerous if you don't know what it actually guarantees. Before shipping, explicitly confirm: does it generate state? Where's it stored? Is PKCE mandatory or optional? How is the issuer validated? Don't assume — read the source or the docs until you know.


## 20. OAuth Security Checklist


Authorization request

- [ ] response_type=code
- [ ] Exact redirect URI
- [ ] state present and unpredictable
- [ ] PKCE with S256
- [ ] OIDC nonce where applicable
- [ ] Correct issuer/provider

Callback

- [ ] state validated against stored value
- [ ] Transaction exists and belongs to this browser/session
- [ ] Transaction not expired
- [ ] Transaction not already consumed
- [ ] Issuer validated
- [ ] nonce validated where applicable
- [ ] Code exchanged with the matching PKCE verifier
- [ ] Redirect URI consistent throughout

Authorization server config

- [ ] Exact redirect URI matching (no wildcards)
- [ ] PKCE supported and enforced when supplied
- [ ] PKCE downgrade prevented
- [ ] Authorization codes single-use and short-lived

RFC 9700 covers all of these: exact redirect matching, PKCE enforcement and downgrade prevention, CSRF, and authorization-code injection.


## 21. The Core Lesson


It’s tempting to reduce all of this to “always use state." The real principle is broader:


> Every security-sensitive OAuth response must be cryptographically or transactionally bound to the operation that created it.


Every security-sensitive OAuth response must be cryptographically or transactionally bound to the operation that created it.


Think of it as a chain:


```
Browser → login transaction → authorization request → authorization server   → authorization code → token exchange → identity → application account → session
```


A vulnerability appears the moment one link detaches — a code with no transaction binding lands in the wrong browser, an external identity with no account-binding check gets attached to the wrong local account, a callback with no redirect validation sends the victim somewhere attacker-controlled, or a code exchanged with no PKCE opens a window for interception or injection.


When you review an OAuth implementation, five questions do most of the work:

- Who started this OAuth transaction — which browser, which session?
- What proves that — state, PKCE, nonce, transaction binding?
- Which identity provider actually generated this response?
- Which local account will this affect?
- What happens if I mix pieces from two legitimate transactions?

A robust implementation fails closed on every mismatch. That’s the whole game.


For deeper implementation guidance, the strongest current references are the IETF’s OAuth 2.0 Security Best Current Practice (RFC 9700) and the OWASP OAuth 2.0 Cheat Sheet.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
