# How We Found a Critical Bug in India’s Income Tax Portal That Put 135M+ Users’ Sensitive Data at Risk

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-09-12
- **Source Channel:** CyberSec WriteUps
- **Original Source URL:** [https://medium.com/p/6fda13f5a2bd](https://medium.com/p/6fda13f5a2bd)

---

## Detailed Writeup & Technical Breakdown

## How We Found a Critical Bug in India’s Income Tax Portal That Put 135M+ Users’ Sensitive Data at Risk


--


Listen


Share


How filing my income tax return for the first time led us to discover an IDOR in India’s Income Tax e-Filing portal.


It started with something completely ordinary.


I was filing my income tax return for the first time.


Like most people, I was just trying to get through the process without messing anything up.


But there is one habit that is difficult to switch off when you’re a security researcher:


I intercept requests.


Almost automatically.


So, while using the Income Tax e-Filing portal, I opened Burp Suite and started looking at what was happening behind the scenes.


I wasn’t looking for a vulnerability.


I wasn’t running a fancy scan.


I was just curious.


And then I noticed something interesting.


A PAN number was being passed from the client in an HTTP POST request.


Immediately, the security-researcher part of my brain kicked in:


> “What happens if I change it?”


“What happens if I change it?”


So I changed my PAN to my friend’s PAN and sent the request.


And then — Boom.


I got his data.


## Wait… what just happened?


At first, I wasn’t even sure what I was looking at.


Maybe it was cached data.


Maybe the application had mixed something up.


Maybe there was some additional check that would kick in later.


So we started looking at the behavior more carefully.


What we found was surprisingly simple.


I was authenticated to the Income Tax portal as myself. But the backend was taking the PAN supplied in the request and using it to retrieve the corresponding user’s information.


It wasn’t properly checking whether I was actually authorized to access the data belonging to that PAN.


That is the core of an Insecure Direct Object Reference, or IDOR.


In simple terms:


```
User A  |  | Authenticated request  | PAN = User A  vServer  |  | Returns User A's data
```


But by changing the identifier:


```
User A  |  | Authenticated request  | PAN = User B  vServer  |  | Returns User B's data
```


The server knew who we were.


It just wasn’t properly checking what we were allowed to access.


And that distinction is everything.


## This wasn’t just someone’s name and email


My good friend hacker Akshay helped me with all the process and reporting, the moment we realized the response contained actual taxpayer information, the severity changed completely.


The data that could be exposed included highly sensitive information such as names, addresses, dates of birth, phone numbers, email addresses, bank account information and Aadhaar numbers. The issue also affected information associated with companies registered on the portal.


This wasn’t a random application.


According to reporting at the time, the Income Tax e-Filing portal had more than 135 million registered users, while around 76 million individuals had filed returns for FY 2024–25.


That is when a “simple IDOR” stops sounding simple.


A missing authorization check in a small application might expose a handful of records.


A missing authorization check in a platform holding sensitive tax information at this scale could potentially become a massive privacy incident.


And to be precise: 135 million was the number of registered users, not the number of people confirmed to have had their data accessed. The exact number of impacted users was not publicly established.


## The scary part? There was nothing sophisticated about it.


This wasn’t a zero-day.


It wasn’t an elaborate exploit chain.


There was no SQL injection, remote code execution, or privilege escalation through some obscure vulnerability.


It was essentially:


Log in → intercept request → change PAN → get another user’s data.


That is what makes access-control vulnerabilities so dangerous.


They can be incredibly easy to exploit while having consequences that are anything but small.


And that’s also why IDORs are easy to underestimate.


Developers may spend enormous effort securing authentication, encryption and infrastructure, but one missing authorization check can still completely break the application’s security boundary.


## We had to decide how far to test


This was the point where we stopped thinking like curious users and started thinking like security researchers.


Once you’ve confirmed that a vulnerability exists, there is always a temptation to answer the question:


“How much can I get?”


That’s the wrong question.


The right question is:


“What is the minimum I need to prove the impact?”


We wanted to establish that the issue was real, reproducible, and serious without unnecessarily accessing people’s private information.


So the objective became validation, not harvesting.


That distinction matters enormously when the vulnerability involves real people’s financial and identity data.


## Reporting the vulnerability


Once we were confident about what we had found, we reported the issue to CERT-In, India’s national incident-response agency.


The issue was then taken up with the Income Tax Department.


TechCrunch later reported that CERT-In had acknowledged the issue and that the Income Tax Department was working on a fix.


For us, this was the point where control of the situation moved out of our hands.


We had found the problem.


Now the people responsible for the system had to fix it.


## Then came the waiting


One of the strange things about vulnerability disclosure is that finding the bug is sometimes the easiest part.


The harder part is waiting.


You know exactly what the vulnerability can do.


But you don’t know how long it has existed.


You don’t know whether anyone else has discovered it.


And you don’t know whether someone has already abused it.


Those questions are particularly uncomfortable when you’re dealing with sensitive government data.


Public reporting later confirmed that the vulnerability had been fixed, but it remained unclear how long the bug had existed or whether malicious actors had accessed or misused taxpayer data before the fix.


## The fix


By early October, we were able to verify that the behavior we had originally demonstrated was no longer working.


The vulnerability had been patched.


TechCrunch published its investigation on October 7, 2025, after independently verifying the issue and confirming that it had been fixed.


https://techcrunch.com/2025/10/07/security-bug-in-indias-income-tax-portal-exposed-taxpayers-sensitive-data/


For us, that was the outcome that mattered.


The vulnerability was closed.


## What this taught me


I’ve found plenty of bugs over the years that were technically more complicated than this one.


But this one stuck with me.


Because it was a reminder that security failures don’t always look like sophisticated hacking.


Sometimes they look like a developer forgetting one authorization check.


The application can authenticate you correctly.


It can know exactly who you are.


It can have a secure login flow.


It can encrypt data.


It can have firewalls and monitoring and all the other things we associate with security.


And yet, if the backend doesn’t ask one simple question —


> “Is this user actually authorized to access this particular resource?”


“Is this user actually authorized to access this particular resource?”


— everything else can become irrelevant.


That’s the fundamental difference between authentication and authorization.


Authentication: Who are you?


Authorization: What are you allowed to access?


In this case, the first question was being answered.


The second one wasn’t being enforced properly.


The most dangerous vulnerabilities aren’t always the most complicated ones. Sometimes they’re the simplest.


And sometimes all it takes to find them is being curious enough to ask:


> “What happens if I change this?”


“What happens if I change this?”


But discovering the vulnerability is only half the job.


The other half is knowing when to stop, proving the impact responsibly, and getting the issue fixed.


That’s what security research should be about.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
