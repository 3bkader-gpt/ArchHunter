# JWT Internals: What’s Actually Inside That Token You Trust

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-09-11
- **Source Channel:** CyberSec WriteUps
- **Original Source URL:** [https://medium.com/p/28c4fbb9e451](https://medium.com/p/28c4fbb9e451)

---

## Detailed Writeup & Technical Breakdown

## JWT Internals: What’s Actually Inside That Token You Trust


## It’s just base64 and a bit of math.


--


Listen


Share


Paste any JWT into jwt.io, or just split it on the dots and base64url-decode each piece yourself. What you get back is two plain JSON objects and a chunk of binary that looks like noise: header.payload.signature


That’s a JWT. Three parts, each with one job. Once you actually understand what each part is responsible for, you get why JWTs behave the way they do, and why they break the way they do too.


## Why JWT Exists in the First Place


Before JWT became the default answer to “how do I handle auth”, most systems worked something like this: a user logs in, the server creates a session, stores it somewhere it controls (a database, Redis, whatever), and hands the browser a small cookie holding just a session ID. Every request after that, the server takes that ID and looks the session up before it can do anything at all.


That works fine right up until you have more than one server. Now that lookup has to happen against a shared store that every service can reach. Add a mobile app, a handful of backend services that all need to trust the same login, maybe a third party that needs to accept your users’ identity too, and that one shared session store turns into a bottleneck and a dependency everyone needs to worry about.


JWT’s whole pitch is simple: what if the token just proved itself? Instead of handing out a meaningless ID that only means something once you’ve looked it up, you hand the client a token that already contains the claims (who they are, what they can do, when it expires) plus a signature over all of it. Any server that knows how to check that signature can verify the token completely on its own.


That’s the “stateless” part people keep mentioning. It’s a stateless way for any service, anywhere, to verify who’s making a request and what they’re allowed to do, without needing to ask anyone else first.


## The Anatomy: Three Parts, Three Jobs


i) Header: tells the verifier how to check the signature.


```
{ "alg": "HS256", "typ": "JWT" }
```


ii) Payload: the actual claims, whatever the issuer wants to say about whoever the token belongs to.


```
{  "sub": "1234",  "trainer": "Ash",  "role": "trainer",  "iat": 1716239022,  "exp": 1716242622}
```


iii) Signature: a cryptographic proof over the first two parts. We’re about to spend a whole section on this one, because it’s the crux on why JWT works.


Notice what’s missing here first, though: encryption.


Header and payload are just base64url encoded, which is not a cipher. Anyone holding the token can read every claim inside it. So if you’ve ever kept something sensitive into a JWT payload assuming it was safely “encoded,” I’ve got some bad news, it wasn’t. The actual design goal is to be readable and tamper evident, not confidential.


## What the Signature Is (and Isn’t)


The signature isn’t computed over the JSON. It’s computed over the literal ASCII string you get by gluing the two encoded parts together with a dot:


```
signing_input = base64url(header) + "." + base64url(payload)
```


Whatever signs the token runs that exact string through an algorithm, and the output becomes the third segment. Two ways that can happen:

- HMAC (Eg: HS256): one shared secret. The signature is just HMAC-SHA256(secret, signing_input), a keyed hash. Whoever has the secret can produce it, and whoever has the same secret can reproduce it and compare. Fast and simple, but that secret now has to live on every server doing verification.
- RSA / ECDSA (Eg: RS256, ES256): a private key produces the signature, a public key checks it. sign(privateKey, signing_input) on one side, verify(publicKey, signature, signing_input) on the other. This is what makes JWTs work so well for OAuth and SSO. One identity provider signs with a key it never shares, and any number of downstream services verify using a key that's meant to be public.

So, what the signature actually is: proof that whoever produced it held the right key at that moment, and proof that the header and payload are identical to what that key signed. Change a single character anywhere in either part and the signature stops matching. That’s the guarantee.


What it is not:

- It’s not encryption. It proves the payload wasn’t altered, it does nothing to hide what’s in it.
- It’s not proof of a specific person’s identity. It’s proof that someone holding a particular key produced this token. If that key leaks, the signature is just as “valid” coming from whoever stole it.
- It’s not proof the claims are true or sensible. If an issuer signs a token saying a free-tier user has admin access, the signature will verify that just as faithfully as it would verify a correct token. Garbage in, faithfully verified garbage out.

## How a Verifier Actually Checks a Token


Every major language has a mature library for it:

- jsonwebtoken or the more spec-complete jose in Node.js
- PyJWT or authlib in Python
- jjwt or Nimbus JOSE+JWT in Java

They all do the same job under slightly different APIs, and it's worth knowing what they're actually doing, because the abstraction hides a few decisions that matter a lot. The general steps are given below:

- Split the token on its two dots: If there are not exactly three segments, it means it’s not a JWT, reject immediately.
- Decode the header, read alg (and often kid): Next, base64url-decode the header as JSON, alg tells you which crypto primitive to run in step 4, and kid, if present, tells you which key to use when there's more than one. More on kid in Part 2, it's its own attack surface.
- Decode the payload: Next, decode the second segment(payload) the same way, you get the claims as plain JSON, with no schema validation applied yet.
- Recompute the signature with the server’s own key: Take the key you were given (a HS256 secret, a RS256 public key, or a resolver callback) along with the alg from step 2, you can recompute a signature over the original signing input.
- Compare the two signatures in constant time: This is where tampering actually gets caught. If someone changed even a single character in the header or payload, the recomputed signature won’t match, because they don’t have the secret or private key needed to produce a matching one. That mismatch is the whole security guarantee JWT gives you.
- If it matches, hand back the claims: The request is successful. No database round trip anywhere. Just math, every request.

## Next Up


Part 2 is where we stop talking about how JWT is supposed to work and go exploit three real misconfigurations, live, against an actual running app.

- A HS256 secret weak enough to brute-force offline.
- An algorithm mix-up that turns a public key into an attacker’s own forging tool.
- A verifier that trusts a key the token brought along with it, sitting in its own header.

None of these are flaws in JWT itself, they’re flaws in how it gets configured, which is exactly why they show up again and again. I built a small hands-on lab to walk through all three.


For now, go find a JWT you have lying around and read what’s sitting in the payload. You might learn something about what your own app has been trusting. 👀


You can check out Part 2 below:


## JWT Exploits: Three Ways Trust Gets Misconfigured


### This is the 2nd part in a two-part series on JWT security. If you haven’t read Part 1<ADD LINK> of this series, I…


medium.com

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
