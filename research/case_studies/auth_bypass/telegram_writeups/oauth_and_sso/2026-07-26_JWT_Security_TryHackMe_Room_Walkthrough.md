# JWT Security TryHackMe Room Walkthrough

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-07-26
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://medium.com/@asoubea/jwt-security-tryhackme-room-walkthrough-1ac1a4bfc252?source=rss------bug_bounty-5](https://medium.com/@asoubea/jwt-security-tryhackme-room-walkthrough-1ac1a4bfc252?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## JWT Security TryHackMe Room Walkthrough


--


5


Listen


Share


lap link:https://tryhackme.com/room/jwtsecurity


## JWT Security: Understanding and Exploiting Vulnerable JSON Web Token Implementations


JSON Web Tokens (JWTs) are widely used for authentication and session management in modern APIs. This room explores how JWTs work, why they are popular, and how insecure implementations can lead to serious vulnerabilities such as token forgery, authentication bypass, and privilege escalation.


Throughout the room, we will examine common JWT security mistakes, including sensitive data exposure, signature validation flaws, weak secrets, algorithm confusion, token lifetime issues, and cross-service attacks. The goal is to understand both how these vulnerabilities are exploited and how developers can securely implement JWT-based authentication.


## Task 1 — Introduction


## Summary


The room begins by introducing JWT security and the importance of understanding token-based authentication.


JWTs are particularly important for penetration testers because they frequently appear in modern APIs and authentication systems.


An attacker who discovers a vulnerable JWT implementation may be able to manipulate authentication claims and escalate privileges.


The most important mindset when testing JWT authentication is:


> Never assume that a token is secure simply because it is signed.


Never assume that a token is secure simply because it is signed.


The implementation around the token is just as important as the cryptography itself.


## Questions & Answers


### Question 1


> I am ready to learn about JWTs!


I am ready to learn about JWTs!


### Answer: No answer needed


## Task 2 — Token-Based Authentication


### Summary


Modern applications increasingly rely on APIs to provide functionality to different clients.


Instead of building completely separate backend logic for a web application and a mobile application, developers can create a centralized API that both clients communicate with.


This creates an important security advantage: authentication and authorization logic can potentially be centralized.


However, traditional browser-based authentication commonly relies on cookies.


Cookies are automatically managed by browsers and automatically attached to requests matching their scope.


For APIs serving multiple types of clients, developers often use token-based authentication instead.


A simplified token-based authentication flow looks like this:


```
1. Client sends username and password           |           v2. Server authenticates the user           |           v3. Server generates a token           |           v4. Client stores the token           |           v5. Client sends token with future requests           |           v6. Server validates token           |           v7. Server determines user permissions
```


A common implementation is to store the token in browser-side storage such as LocalStorage.


The client-side JavaScript then retrieves the token and sends it in the request header:


```
Authorization: Bearer <JWT>
```


This is different from cookie authentication because the browser is no longer responsible for automatically managing the authentication state.


The application itself must retrieve and attach the token.


### API Structure


The lab API follows a simple pattern:


```
POST /api/v1.0/exampleX
```


The POST request is used to authenticate and receive a JWT.


The credentials follow this format:


```
{  "username": "user",  "password": "passwordX"}
```


For example:


```
curl -H 'Content-Type: application/json' \-X POST \-d '{ "username" : "user", "password" : "password1" }' \http://MACHINE_IP/api/v1.0/example1
```


After receiving the JWT, it can be sent in an authenticated request:


```
curl -H 'Authorization: Bearer [JWT_TOKEN]' \http://MACHINE_IP/api/v1.0/example2?username=user
```


The objective throughout the practical examples is to understand how vulnerable JWT implementations can allow a user to become an administrator.


### Attacker’s Methodology


When testing a JWT-based API, a useful workflow is:


### Step 1 — Identify the Authentication Mechanism


Determine whether the application uses:

- Cookies
- Session IDs
- JWTs
- OAuth tokens
- API keys

If a JWT is found, inspect it carefully.


### Step 2 — Decode the Token


JWTs are normally structured as:


```
HEADER.PAYLOAD.SIGNATURE
```


The first two components can generally be decoded without knowing the signing secret.


### Step 3 — Analyze the Claims


Look for claims such as:


```
{  "username": "user",  "admin": 0,  "role": "user"}
```


Ask yourself:

- Is authorization information stored inside the token?
- Is sensitive information exposed?
- Is an expiration time present?
- What algorithm is being used?
- Is the token intended for a specific application?

### Step 4 — Test Signature Validation


Determine whether changing claims causes the server to reject the token.


### Step 5 — Test Algorithm Handling


Check whether the server securely restricts the allowed signing algorithms.


### Step 6 — Investigate Secret Strength


If the token uses a symmetric algorithm such as HS256, determine whether the secret is weak enough to crack offline.


## Questions & Answers


### Question 1


> What is the common header used to transport the JWT in a request?


What is the common header used to transport the JWT in a request?


### Answer: Authorization: Bearer


Explanation


JWTs are commonly transported through the HTTP Authorization header using the Bearer authentication scheme. The server extracts the token from the header and validates it before processing the request.


Example:


```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```


## Task 3 — JSON Web Tokens


### Summary


A JWT is a compact token format used to transfer information between parties.


A JWT normally consists of three Base64URL-encoded components:


```
Header.Payload.Signature
```


Each component has a different purpose.


### 1. Header


The header contains metadata about the token.


A typical header may look like:


```
{  "typ": "JWT",  "alg": "HS256"}
```


The alg field specifies the signing algorithm.


This field is extremely important during security testing because insecure handling of it can lead to algorithm attacks.


### 2. Payload


The payload contains claims.


For example:


```
{  "username": "user",  "admin": 0}
```


Claims can represent information about:

- The user
- Roles
- Permissions
- Token lifetime
- Token audience
- Token issuer

The payload is encoded, not encrypted.


This is one of the most important concepts when working with JWTs.


Anyone who possesses the token can generally decode the header and payload.


Therefore, a JWT should never be treated as a secure container for secrets.


### 3. Signature


The signature allows the server to determine whether the token has been modified.


Conceptually:


```
Header + Payload       |       vSigning Algorithm + Key       |       vSignature
```


If an attacker changes the payload, the signature should no longer match.


For example:


```
{  "username": "user",  "admin": 0}
```


Changing:


```
"admin": 0
```


to:


```
"admin": 1
```


should invalidate the signature.


This is why the signature is central to JWT security.


### JWT Signing Algorithms


### None


The None algorithm means the JWT has no cryptographic signature.


This is normally unsafe for authentication because the server cannot use a signature to prove that the token was issued by a trusted party.


### Symmetric Signing — HS256


With symmetric signing, the same secret is used for signing and verification.


Conceptually:


```
Signing:Header + Payload + Secret        |        v      HS256        |        v    Signature
```


The server needs to know the secret to verify the token.


The security of the system therefore depends heavily on the secret’s strength.


### Asymmetric Signing — RS256


Asymmetric algorithms use a key pair:


```
Private Key     |     vSigns JWT     |     vJWT     |     vPublic Key     |     vVerifies JWT
```


The private key should remain secret.


The public key can normally be distributed to systems that need to verify the token.


This difference becomes extremely important when testing for algorithm confusion vulnerabilities.


### JWT vs JWE


A JWT is generally signed but not necessarily encrypted.


An encrypted JWT is called a:


```
JWE
```


This distinction matters because encoding does not provide confidentiality.


## Questions & Answers


### Question 1


> HS256 is an example of what type of signing algorithm?


HS256 is an example of what type of signing algorithm?


### Answer: Symmetric


Explanation


HS256 is a symmetric signing algorithm because the same shared secret is used to generate and verify the signature. Anyone who obtains the secret can potentially create valid tokens.


### Question 2


> RS256 is an example of what type of signing algorithm?


RS256 is an example of what type of signing algorithm?


### Answer: Asymmetric


Explanation


RS256 uses asymmetric cryptography. The private key is used to sign tokens, while the corresponding public key is used to verify them.


### Question 3


> What is the name used for encrypted JWTs?


What is the name used for encrypted JWTs?


### Answer: JWE


Explanation


JWE stands for JSON Web Encryption. Unlike a typical signed JWT, a JWE is designed to provide confidentiality by encrypting the token contents.


## Task 4 — Sensitive Information Disclosure


### Summary


One of the simplest JWT vulnerabilities occurs when developers place sensitive information inside the payload.


The key mistake is misunderstanding the difference between:


```
Encoded
```


and:


```
Encrypted
```


JWT payloads are normally Base64URL encoded.


They are not automatically encrypted.


Therefore, anyone who obtains the token can decode the payload.


Sensitive information that should never normally be placed in JWT claims includes:

- Passwords
- Password hashes
- API keys
- Database credentials
- Internal IP addresses
- Internal hostnames
- Secrets
- Flags
- Other confidential backend information

## Practical Example 1


### Step 1 — Authenticate


The first step is to authenticate against the API:


```
curl -H 'Content-Type: application/json' \-X POST \-d '{ "username" : "user", "password" : "password1" }' \http://MACHINE_IP/api/v1.0/example1
```


The server returns a JWT.


### Step 2 — Decode the Token


The token can be decoded manually or using a JWT decoder.


The important point is that we do not need the signing secret to read the payload.


A vulnerable implementation might create the token like this:


```
payload = {    "username": username,    "password": password,    "admin": 0,    "flag": "[redacted]"}access_token = jwt.encode(payload, self.secret, algorithm="HS256")
```


This is insecure because the password and flag are now available to the client.


## Step 3 — Understand the Security Impact


Even if the signature is perfectly implemented, the sensitive information is still exposed.


The signature protects integrity.


It does not automatically provide confidentiality.


Therefore:


```
Valid Signature ≠ Secret Payload
```


## Secure Development Approach


Instead of storing sensitive data in the JWT:


```
payload = jwt.decode(token, self.secret, algorithms="HS256")username = payload['username']flag = self.db_lookup(username, "flag")
```


The JWT contains only the information necessary to identify the user.


Sensitive information remains server-side.


## Questions & Answers


### Question 1


> What is the flag for example 1?


What is the flag for example 1?


### Answer: THM{9cc039cc-d85f-45d1-ac3b-818c8383a560}


Explanation


The vulnerability in this example is sensitive information disclosure through JWT claims. By decoding the payload, information that should have remained server-side can be recovered, including the flag.


## Task 5 — Signature Validation Mistakes


## Summary


The signature is supposed to prevent attackers from modifying JWT claims.


However, several implementation mistakes can undermine this protection.


The main issues covered in this section are:

- Signature verification disabled
- None algorithm downgrade
- Weak symmetric secrets
- Algorithm confusion

These vulnerabilities have different root causes, but they share the same fundamental problem:


> The server does not correctly enforce the cryptographic assumptions behind the JWT.


The server does not correctly enforce the cryptographic assumptions behind the JWT.


## Practical Example 2 — Missing Signature Verification


### Step 1 — Authenticate


Authenticate normally:


```
curl -H 'Content-Type: application/json' \-X POST \-d '{ "username" : "user", "password" : "password2" }' \http://MACHINE_IP/api/v1.0/example2
```


Receive the JWT.


### Step 2 — Test the Original Token


Send the token:


```
curl -H 'Authorization: Bearer [JWT_TOKEN]' \http://MACHINE_IP/api/v1.0/example2?username=user
```


### Step 3 — Remove the Signature


A JWT normally looks like:


```
HEADER.PAYLOAD.SIGNATURE
```


If signature validation is completely disabled, removing the signature may still result in the server accepting the token:


```
HEADER.PAYLOAD.
```


This is a critical finding.


It means the server is trusting the claims without proving that the token was legitimately signed.


## Step 4 — Modify the Claims


If the payload contains:


```
{  "username": "user",  "admin": 0}
```


the attacker may attempt to change it to:


```
{  "username": "admin",  "admin": 1}
```


If the server accepts this modified token, privilege escalation is possible.


### Vulnerable Code


A vulnerable implementation may look like:


```
payload = jwt.decode(    token,    options={'verify_signature': False})
```


The signature is explicitly not being verified.


### Secure Implementation


The server should verify the token:


```
payload = jwt.decode(    token,    self.secret,    algorithms="HS256")
```


For server-to-server authentication, additional controls such as certificates may also be appropriate.


## Practical Example 3 — None Algorithm Downgrade


### Step 1 — Understand the Attack


JWTs support the None algorithm.


The attack attempts to change the header from:


```
{  "alg": "HS256"}
```


to:


```
{  "alg": "None"}
```


The goal is to convince the server to accept a token without validating a cryptographic signature.


### Step 2 — Modify the Header


The JWT header can be decoded and modified.


For example:


```
{  "typ": "JWT",  "alg": "None"}
```


The resulting token is then submitted to the application.


If the server accepts it, signature validation may have been bypassed.


### Step 3 — Modify Authorization Claims


The attacker can then attempt to change:


```
"admin": 0
```


to:


```
"admin": 1
```


The objective is to determine whether the server trusts the forged claims.


### Vulnerable Implementation


A common design mistake is dynamically trusting the algorithm specified by the attacker-controlled JWT header:


```
header = jwt.get_unverified_header(token)signature_algorithm = header['alg']payload = jwt.decode(    token,    self.secret,    algorithms=signature_algorithm)
```


The application should never blindly trust the algorithm specified by an untrusted token.


### Secure Implementation


The application should explicitly define allowed algorithms:


```
payload = jwt.decode(    token,    self.secret,    algorithms=["HS256", "HS384", "HS512"])
```


The server should not allow an attacker to decide which cryptographic algorithm will be used for verification.


## Practical Example 4 — Weak Symmetric Secrets


### Step 1 — Identify the Algorithm


Suppose the JWT uses:


```
HS256
```


This means the token relies on a shared secret.


If the secret is weak, an attacker may attempt to crack it offline.


The attacker does not need to repeatedly send requests to the server.


Instead, the attacker can test candidate secrets locally.


### Step 2 — Save the JWT


Save the token into:


```
jwt.txt
```


## Step 3 — Obtain a JWT Secret Wordlist


For the lab, a common JWT secret list can be downloaded using:


```
wget https://raw.githubusercontent.com/wallarm/jwt-secrets/master/jwt.secrets.list
```


## Step 4 — Crack the Secret


Hashcat mode 16500 is used for JWTs:


```
hashcat -m 16500 -a 0 jwt.txt jwt.secrets.list
```


or by using John the Ripper


```
john --wordlist=jwt.secrets.list jwt.txt
```


If the secret is weak and appears in the wordlist, Hashcat may recover it.


In the lab, the recovered secret was:


```
secret
```


### Step 5 — Forge a New Token


Once the signing secret is known, an attacker can create a new token with modified claims.


For example:


```
import jwtsecret = "secret"payload = {    "username": "admin",    "admin": 1}access_token = jwt.encode(    payload,    secret,    algorithm="HS256")print(access_token)
```


The newly generated token can then be sent to the API.


The important lesson is:


> A weak symmetric secret can turn a cryptographically valid JWT implementation into an authentication bypass.


A weak symmetric secret can turn a cryptographically valid JWT implementation into an authentication bypass.


### Secure Development


JWT secrets should be:

- Long
- Random
- High entropy
- Generated securely
- Stored safely

Avoid predictable secrets such as:


```
secretpasswordjwtsecret123456
```


## Practical Example 5 — Algorithm Confusion


Algorithm confusion attacks are more subtle.


They occur when a server incorrectly allows both symmetric and asymmetric algorithms and mishandles the verification key.


For example:


```
Original:RS256Private Key -> SignPublic Key  -> Verify
```


An attacker may attempt:


```
Modified:HS256Public Key -> HMAC Secret
```


If the vulnerable server uses the public key as an HMAC secret, an attacker who knows the public key may be able to generate a valid signature.


### Step 1 — Authenticate


The application returns:

- A JWT
- An RSA public key

The original token uses:


```
RS256
```


### Step 2 — Change the Algorithm


The attacker changes:


```
{  "alg": "RS256"}
```


to:


```
{  "alg": "HS256"}
```


### Step 3 — Use the Public Key as the HMAC Secret


The vulnerable implementation may incorrectly treat the public key as an HMAC secret.


A conceptual exploit script looks like:


```
import jwtpublic_key = "ADD_KEY_HERE"payload = {    'username' : 'user',    'admin' : 0}access_token = jwt.encode(payload, public_key, algorithm="HS256")print (access_token)
```


The attacker can then modify the payload:


```
payload = {    "username": "admin",    "admin": 1}
```


and generate another token.


### Vulnerable Configuration


A dangerous implementation may allow both algorithm families together:


```
payload = jwt.decode(    token,    self.secret,    algorithms=[        "HS256",        "HS384",        "HS512",        "RS256",        "RS384",        "RS512"    ])
```


The problem is that the verification key can be interpreted differently depending on the selected algorithm.


### Secure Implementation


The application should separate symmetric and asymmetric verification logic:


```
header = jwt.get_unverified_header(token)algorithm = header['alg']payload = ""if "RS" in algorithm:    payload = jwt.decode(token, self.public_key, algorithms=["RS256", "RS384", "RS512"])elif "HS" in algorithm:    payload = jwt.decode(token, self.secret, algorithms=["HS256", "HS384", "HS512"])username = payload['username']flag = self.db_lookup(username, "flag")
```


The fundamental principle is to ensure that the selected algorithm can never cause the wrong type of key to be used.


## Questions & Answers


### Question 1


> What is the flag for example 2?


What is the flag for example 2?


### Answer: THM{6e32dca9-0d10-4156-a2d9-5e5c7000648a}


Explanation


Example 2 demonstrates a JWT implementation where signature verification is not properly enforced. This allows an attacker to modify authorization-related claims and potentially impersonate an administrator.


### Question 2


> What is the flag for example 3?


What is the flag for example 3?


### Answer: THM{fb9341e4-5823-475f-ae50-4f9a1a4489ba}


Explanation


Example 3 demonstrates an algorithm downgrade involving the None algorithm. If the application accepts this algorithm without requiring a valid cryptographic signature, attackers may be able to forge token claims.


### Question 3


> What is the flag for example 4?


What is the flag for example 4?


### Answer: THM{e1679fef-df56-41cc-85e9-af1e0e12981b}


Explanation


Example 4 demonstrates the danger of using a weak symmetric signing secret. Once the secret is recovered through offline cracking, the attacker can create new JWTs with arbitrary claims and valid signatures.


### Question 4


> What is the flag for example 5?


What is the flag for example 5?


### Answer: THM{f592dfe2-ec65-4514-a135-70ba358f22c4}


Explanation


Example 5 demonstrates algorithm confusion between asymmetric and symmetric signing. The vulnerability occurs when the server incorrectly allows the public key to be interpreted as an HMAC secret after changing the algorithm from RS256 to HS256.


## Task 6 — Token Lifetime


### Summary


A JWT should not remain valid forever.


JWTs commonly use the exp claim to specify when a token expires.


For example:


```
{  "username": "user",  "admin": 0,  "exp": 1785070000}
```


The exact value represents a timestamp.


The server should verify that the current time is before the expiration time.


### The Security Problem


If a JWT does not contain an expiration time, it may remain valid indefinitely.


This creates a serious problem if the token is stolen.


For example:


```
Attacker steals JWT       |       vToken has no expiration       |       vToken remains valid       |       vAttacker can continue using it
```


The longer a token remains valid, the larger the window available to an attacker.


### Practical Example 6


The vulnerable token provided in the lab was:


```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InVzZXIiLCJhZG1pbiI6MX0.ko7EQiATQQzrQPwRO8ZTY37pQWGLPZWEvdWH0tVDNPU
```


The important observation is that the payload does not contain an exp claim.


Therefore, assuming the signature remains valid, the token can continue to be accepted.


### Secure Implementation


A token lifetime can be created using Python:


```
lifetime = datetime.datetime.now() + datetime.timedelta(minutes=5)payload = {    'username' : username,    'admin' : 0,    'exp' : lifetime}access_token = jwt.encode(payload, self.secret, algorithm="HS256")
```


The appropriate lifetime depends on the application.


A banking application may require a much shorter lifetime than a low-risk internal application.


### Refresh Tokens


Another common approach is using short-lived access tokens combined with refresh tokens.


Conceptually:


```
Short-lived Access Token        |        vExpires quickly        |        vRefresh Token        |        vObtain new Access Token
```


This approach reduces the impact of a stolen access token while still allowing users to maintain a session without repeatedly entering their credentials.


## Questions & Answers


### Question 1


> What is the flag for example 6?


What is the flag for example 6?


### Answer: THM{a450ae48-7226-4633-a63d-38a625368669}


Explanation


The vulnerability in example 6 is the absence of an expiration claim. Because the token does not have an exp value, it can remain valid indefinitely as long as the signature is accepted.


## Task 7 — Cross-Service Relay Attacks


### Summary


JWTs are often used in environments where one authentication service provides tokens for multiple applications.


For example:


```
Authentication Server                    |          ---------------------          |                   |          v                   v       App A                App B
```


A JWT may contain an aud claim that specifies the intended application.


For example:


```
{  "username": "user",  "admin": 1,  "aud": "appB"}
```


The token is intended for appB.


If appA does not properly validate the audience, it may incorrectly accept the token.


This can lead to a Cross-Service Relay attack.


### Practical Example 7


The lab contains two applications:


```
example7_appAexample7_appB
```


The authentication request also requires an application parameter.


For example:


```
{  "username": "user",  "password": "password7",  "application": "appA"}
```


The resulting token contains an audience identifying appA.


The attacker can then test the token against both applications.


The interesting behavior is:


```
Token issued for appA       |       +----> appA: accepted       |       +----> appB: rejected
```


The attacker then requests a token for appB:


```
{  "username": "user",  "password": "password7",  "application": "appB"}
```


This token provides administrator privileges in the context of appB.


The next step is to test this token against both services.


If appA accepts the appB token without validating its audience, the attack becomes possible:


```
Token issued for appB       |       vContains admin privileges       |       vSent to appA       |       vappA fails to enforce "aud"       |       vPrivilege escalation
```


The vulnerability is not necessarily a problem with the JWT signature.


The token may be:

- Properly signed
- Completely authentic
- Cryptographically valid

The problem is that the wrong application accepts it.


### Secure Implementation


The application should explicitly validate the audience claim.


For example:


```
payload = jwt.decode(    token,    self.secret,    audience=["appA"],    algorithms="HS256")
```


The server should verify both:


```
Is this token authentic?        +Is this token intended for this application?
```


Both checks are required.


## Questions & Answers


### Question 1


> What is the flag for example 7?


What is the flag for example 7?


### Answer: THM{f0d34fe1-2ba1-44d4-bae7-99bd555a4128}


Explanation


Example 7 demonstrates a Cross-Service Relay vulnerability caused by incorrect audience validation. A token issued for one application can be accepted by another application, allowing privileges associated with the first application to be reused in the second.


If this summary helped you save some time (or a few brain cells ), don’t forget to follow and leave a 👏 Clap. It really helps and motivates me to keep making more cybersecurity notes like this ❤️

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
