# I Modified Collections I Did Not Own: IDOR

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-07-26
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://scriptjacker.medium.com/i-modified-collections-i-did-not-own-idor-856fb856a90e?source=rss------bug_bounty-5](https://scriptjacker.medium.com/i-modified-collections-i-did-not-own-idor-856fb856a90e?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## I Modified Collections I Did Not Own: IDOR


--


Listen


Share


Hey Hackers, I am Parth Narula. A penetration tester, bug hunter, red teamer and overall a security researcher. I live for those moments where a bit of out-of-the-box thinking cracks open a critical vulnerability.


This is the story of an IDOR I found in a collection management feature. With one simple parameter change, I could reorder collections belonging to other users including private ones without owning them at all.


It started when I was examining the collection feature on a platform. Users could create collections, organize them, and control their visibility. I had two accounts open in separate browser tabs.


The first account was the victim. The victim had a collection named HTML with the ID 1541980 under /collection/1541980-i-html-i. It was a public collection sitting in their /my-collections dashboard.


The victim’s collection page is shown above.


The victim’s collections before the attack are shown above. The HTML collection is sitting in its original position, which is 3rd position.


The second account was mine, the attacker. On my account I had my own set of collections. MA TEST 27, MA TEST 29, MA TEST 30 and others. Completely separate from the victim.


My own collections are shown above.


When I intercepted the collection reordering request in Burp Suite, it looked like this.


```
PUT /apiweb/v1/collections/1622242.jsonHost: REDACTEDAuthorization: Token my_tokencollection[position]=2
```


The server responded with a 200 OK. The response confirmed the collection was mine and the position was updated to 2.


```
{"id": 1622242,"name": "MA TEST 27","acl": "private","owned": true,"position": 2}
```


The legitimate request on my own collection is shown above.


This worked perfectly for my own data. But then I asked myself the question I always ask.


> What if I swap the collection ID?


What if I swap the collection ID?


I took the exact same request and simply changed the collection ID from my own 1622242 to the victim’s 1541980. I kept everything else identical. My token, my headers, the same position value.


```
PUT /apiweb/v1/collections/1541980.jsonHost: REDACTEDAuthorization: Token my_tokencollection[position]=10
```


The server responded with 200 OK. But look closely at the response.


```
{"id": 1541980,"acl": "public","owned": false,"position": 10}
```


The malicious request on the victim’s collection is shown above.


This was the smoking gun. The server explicitly told me owned was false. Meaning it knew I did not own this collection. It even showed acl was public. Yet it still processed my request and updated the position to 10.


To confirm this was not just a misleading response, I switched back to the victim’s tab and refreshed their my collections page.


The HTML collection had moved. It was now sitting at position 10 in the victim’s own dashboard. A position I had forced from my attacker account.


This was a clear and critical issue. I had successfully modified another user’s collection ordering using an API endpoint that never validated ownership. The backend authenticated who I was, but never checked what I was allowed to touch.


## Lessons Learned

- Treat Every Object Reference as a Potential Vulnerability
- The Response Often Confesses the Sin
- Test State Changing Endpoints Across Account Boundaries
- Security testing must go beyond isolated features. Take a request that works on your own data and replay it against another user’s object IDs. This is where authorization flaws live.

I hope you learn something new. Follow for more amazing articles and give claps if you like this one :)


Need expert pentesting services? visit https://scriptjacker.in or let’s collaborate on your next project! 🤝


Want to learn from my experiences? Check out my articles on https://blogs.scriptjacker.in

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
