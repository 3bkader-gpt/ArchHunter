# CONCURRENCY TEST — RACE CONDITION

- **Category:** IDOR & Broken Access Control
- **Publication Date:** 2026-03-26
- **Source Channel:** GamarSec - Bug Bounty Tips
- **Original Source URL:** [https://target.com/reset-password](https://target.com/reset-password)

---

## Detailed Writeup & Technical Breakdown

CONCURRENCY TEST — RACE CONDITION

Send multiple reset requests simultaneously to trigger token mix-ups or state desynchronization.

Common tooling: Burp Turbo Intruder and race-condition extensions.



## INPUT TRUST TEST — REFERRER MANIPULATION

Example header tampering:

Referer: /reset?email=victim@gmail.com

In some flawed implementations, token generation or routing logic may depend on this value.



## IDENTITY NORMALIZATION TEST — EMAIL CANONICALIZATION BYPASS

Test normalization edge cases:

victim@gmail.com
victim+test@gmail.com
victim.test@gmail.com
victimgooglemail.com

Unicode homograph variation example:

victimvictіm24@gmail.com

## CSRF TEST — PASSWORD RESET CSRF

If endpoint lacks CSRF protection:

<form action="https://target.com/reset-password" method="POST">
<input name="password" value="hacked123">
</form>

Victim interaction may result in forced password change.



## ATTACK SURFACE EXPANSION — HIDDEN RESET ENDPOINTS

Enumerate undocumented endpoints:

/api/reset-password
/api/v2/reset
/internal/reset
/admin/reset
/graphql

Example scenario:

POST /api/su/resetPwd
username=admin



## ABUSE TEST — RATE LIMIT BYPASS

Send repeated reset requests to detect missing or weak throttling controls.

POST /forgot-password HTTP/1.1
Host: target.com
Content-Type: application/x-www-form-urlencoded

email=victim@gmail.com



## CONTROL EVASION TEST — HEADER SPOOFING

Test IP-related headers that may influence rate limiting or trust decisions:

X-Forwarded-For: 1.1.1.1
X-Real-IP: 1.1.1.1
X-Originating-IP: 1.1.1.1
Client-IP: 1.1.1.1
True-Client-IP: 1.1.1.1


A structured methodology for testing password reset flows significantly increases the chances of discovering impactful authentication vulnerabilities that can lead to full Account Takeover.


Thanks for reading. And i hope that you learned something new.

If you wanna following me on social media :-

https://t.me/wadgamaraldin (Telegram Channel For — Writeups — Blogs — Bug Bounty Tips — YouTube Videos )

https://www.linkedin.com/in/wadgamaraldeen/

https://twitter.com/wadgamaraldeen/

https://www.facebook.com/wadgamaraldeen/
About Me

Mustafa Adam

Bug Bounty Hunter

    HackerOne / Zerocopoter / Standoff365 / Google VRP / Private Programs
    Focus: Web Application Security

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
