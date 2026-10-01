# I Wasn’t Looking for PII. I Just Cancelled an Invite. (IDOR → PII)

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-09-10
- **Source Channel:** CyberSec WriteUps
- **Original Source URL:** [https://medium.com/p/41d1df546edf](https://medium.com/p/41d1df546edf)

---

## Detailed Writeup & Technical Breakdown

## I Wasn’t Looking for PII. I Just Cancelled an Invite. (IDOR → PII)


--


1


Listen


Share


Hi, I’m El7xoot, a Bug Hunter and Security Researcher focused on web applications and APIs.


Sometimes the most interesting vulnerabilities don’t start with a suspicious endpoint.


Sometimes they start with something completely normal:


“Cancel invite.”


## It Started With a Workspace Invite


While testing a collaboration feature, I created an invitation and intercepted the request responsible for removing it.


The API looked roughly like this:


```
POST /v0.3/workspace/{workspaceId}/bulkUnshareHost: staging.example.com{  "stringifiedObjectParams": {    "collaboratorModelIds": ["inv3CVQuU9DiAirSF"]  },  "requestId": "reqruksi57yLNs5Mu",  "secretSocketId": "socUJq5A34dwpFfE8"}
```


The request contained an object identifier representing the invitation.


Nothing unusual.


But I noticed something interesting about the application’s identifiers:


```
invXXXXXXXXusrXXXXXXXX
```


Different prefixes represented different object types.


That made me wonder:


> What happens if the endpoint receives a user identifier instead of an invitation identifier?


What happens if the endpoint receives a user identifier instead of an invitation identifier?


So I changed only the object reference.


## The API Did Something It Shouldn’t


Instead of returning an error such as:


```
403 Forbidden
```


or:


```
400 Bad Request
```


the server returned information associated with the referenced user.


A simplified response looked like:


```
{  "name": "Victim User",  "email": "victim@example.com",  "profilePicture": "...",  "status": "active"}
```


At this point, the problem was no longer about cancelling an invitation.


The endpoint was effectively accepting an object belonging to a different object type and returning data without properly checking whether the authenticated user was authorized to access it.


## The Real Bug: Authorization


The application knew who I was.


But it didn’t properly verify whether I was allowed to access the object I supplied.


The vulnerable logic was effectively behaving like:


```
Authenticated user       ↓Receive object ID       ↓Find object       ↓Return data
```


Instead, it should have enforced something closer to:


```
Authenticated user       ↓Receive object ID       ↓Validate object type       ↓Verify ownership / workspace relationship       ↓Authorize access       ↓Return data
```


The important lesson here is:


An object ID is an identifier, not an authorization mechanism.


## Why This Was Interesting


The impact wasn’t limited to manipulating an invitation.


By abusing the endpoint’s object handling, an authenticated attacker could access user information outside the expected authorization boundary.


The exposed information included:

- Full name
- Email address
- Profile picture
- Account status

The vulnerability crossed an important security boundary:


A workspace-level action became an unintended user-data access primitive.


## The Takeaway


This is why I don’t stop testing when an API behaves exactly as expected.


I look at the assumptions behind it.


If an endpoint expects:


```
Invitation ID
```


I also ask:


> What happens if I give it a User ID?


What happens if I give it a User ID?


Sometimes changing one small assumption is enough to uncover a completely different class of vulnerability.


Never let object identifiers become authorization checks.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
