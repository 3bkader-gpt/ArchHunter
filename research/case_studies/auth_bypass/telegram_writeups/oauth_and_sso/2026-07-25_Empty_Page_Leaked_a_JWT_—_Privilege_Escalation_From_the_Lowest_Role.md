# Empty Page Leaked a JWT — Privilege Escalation From the Lowest Role

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-07-25
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://deepvvm.medium.com/empty-page-leaked-a-jwt-privilege-escalation-from-the-lowest-role-9ab7f5861c59?source=rss------bug_bounty-5](https://deepvvm.medium.com/empty-page-leaked-a-jwt-privilege-escalation-from-the-lowest-role-9ab7f5861c59?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## Empty Page Leaked a JWT — Privilege Escalation From the Lowest Role


--


1


Listen


Share


## The Context


The platform lets brands and their partners collaborate inside a shared workspace: they run campaigns, settle commissions, and move large data files between each other’s systems. Everyone from the same company works inside a single organization, and an administrator invites teammates and assigns each of them a role that determines what they can access.


There are several roles, and they are not stacked tiers — each one is meant to unlock a specific part of the product:

- Account Administration
- Finance
- Advertiser Management
- Creative Management
- Technical
- Messaging — the most limited role, meant only for communication and outreach

I mention Messaging early because the entire finding depends on it. It is the weakest seat in the organization: if it can reach something, everyone can.


## Getting Familiar With the Product


Before testing anything, I spent time simply using the application. I registered an account, had myself invited into an organization as a Messaging user — deliberately the lowest role — and then went through every page, menu, and button available to that role while my proxy quietly recorded the traffic in the background.


Most of this was uneventful. A lot of pages returned nothing useful, several actions were blocked with permission errors, and for a while it looked like this low-privileged account simply couldn’t reach anything interesting. I kept going anyway, opening every option that would open.


## Understanding How Connections Works


One feature stood out as the sensitive one: Connections. It handles bulk data transfers between the platform and external systems, and it stores the FTP/SFTP credentials — usernames and passwords — used to authenticate those transfers. It also controls where data and earnings reports are delivered.


While watching the traffic, I noticed something important about its design. Almost everything else in the product talks to the platform’s own backend and is authorized by your session cookie, where your role is properly checked. A normal action in the console looked like this:


```
Host: partner.redacted.comCookie: <your session>
```


Connections, however, is powered by a separate third-party integration provider. Its requests don’t go to the platform at all — they go to a completely different host, and instead of your session cookie they carry a standalone JWT bearer token:


```
Host: api.external.comAuthorization: Bearer eyJ0eXAiOiJKV1Qi………
```


Two separate hosts means two separate systems, and authorization has to be enforced in both of them. As it turned out, only the first one actually checked my role.


## The Overlooked Page


Deep in the account settings, I found a menu item called “Unsubscribed Outreach Emails.” When I opened it, the page rendered empty — no rows, no meaningful controls. It looked like a surface that was only ever intended for Technical users and had been left visible to everyone by mistake.


I almost moved past it. But when I checked the recorded traffic, I saw that the page — in the process of loading its empty table — had sent a background request carrying a JWT bearer token:


```
GET /outreach-ui/api/partners/unsubscribed_emails/tabledata?page=1&pageSize=20 HTTP/2Host: partner.redacted.comAuthorization: eyJ0eXAiOiJKV1Qi………
```


> The page was empty. The request it made was not.


The page was empty. The request it made was not.


So a Messaging user — the most limited role in the organization — had just been handed a token. The obvious question: is this the same token Connections uses, and will the external API honor it regardless of my role?


## Diving Into the Requests


My first instinct was to try the token on the more obviously sensitive parts of the same third-party API. The API Access Tokens feature was the natural first target — it’s served by the exact same external host, so I assumed the JWT would work there too.


It didn’t. Every request came back 403 Forbidden. At that point it looked like the token might be properly scoped after all, and that the leak on its own wasn't going anywhere.


Before giving up on it, I decided to try a different function on that same API — Connections — instead of the one I’d fixated on. And the moment I replayed the request with the leaked token, the data came straight back:


```
GET /v1/ui/connections HTTP/2Host: api.external.comAuthorization: Bearer eyJ0eXAiOiJKV1Qi………
```


Response:


```
200 OK{  "connections": [    { "id": "…", "name": "…", "filePath": "…" }  ]}
```


> Refused by the API Access Tokens endpoints with a 403, fully trusted by the Connections endpoints with a 200 — the same token.


Refused by the API Access Tokens endpoints with a 403, fully trusted by the Connections endpoints with a 200 — the same token.


That inconsistency is exactly what made it a real finding. With the connection IDs in hand, I could reach the rest of the feature. I was able to change the email address that files and earnings reports are delivered to:


```
POST /v1/ui/credentials/validate HTTP/2Host: api.external.comAuthorization: Bearer eyJ0eXAiOiJKV1Qi………Content-Type: application/json
```


```
{ "answer": "attacker@example.com", "signupField": { "id": "<FIELD_ID>" } }
```


## A Practical Example


The most impactful request involved the SFTP/FTP credentials. The relevant endpoint did not simply read the existing secret — it generated a new one:


```
GET /v1/ui/credentials/generate?accountId=<ACCOUNT_ID>&connectionUserUsername=<USER>&signupFieldId=<FIELD_ID> HTTP/2Host: api.external.comAuthorization: Bearer eyJ0eXAiOiJKV1Qi………
```


Because this generates rather than reads, issuing a new credential invalidates the previous one. The legitimate owner’s password stops working, and the credential can be re-issued repeatedly.


From a single low-privileged account, I could therefore:

- Read connection data and partner PII such as email addresses (confidentiality)
- Redirect where sensitive data and earnings are delivered (integrity)
- Revoke the owner’s access to their own transfers by rotating their credentials (availability)

## Why This Happened


Two separate weaknesses combined to make this possible.

- An over-exposed page. The “Unsubscribed Outreach Emails” page was shown to every role, including Messaging, when it appears to have been intended only for Technical users. That is what leaked the token to a user who should never have held it.
- A token that outranked its holder. The external integration API accepted the token for privileged Connections operations without re-checking the caller’s role or binding the token to their session. The platform’s own interface enforced the role correctly and refused these actions for a Messaging user; the same actions, sent directly to the external API, went through.

> The 403 from the API Access Tokens endpoints is what makes this clear-cut: the external API could enforce authorization, and did in one place. Connections skipping that same check is the bug, not intended behavior.


The 403 from the API Access Tokens endpoints is what makes this clear-cut: the external API could enforce authorization, and did in one place. Connections skipping that same check is the bug, not intended behavior.


## The Takeaway


The lesson I keep coming back to is that an empty or unremarkable-looking page is not necessarily a dead end. The value here was never in what the page displayed — it was in the request it made in the background.


It’s also a reminder that:

- Role enforcement in a first-party interface does not guarantee the same enforcement in a third-party API sitting behind it.
- A token issued for one narrow purpose is often accepted far beyond it — always replay it across the whole feature.
- The lowest-privileged role is the best seat to test from. If it can reach something, everyone can.

If you found this write-up useful, I’d love to connect. Feel free to add me:

- X (Twitter): @deepvvm
- LinkedIn: Ali Alhassoun

More write-ups on the way — thanks for reading.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
