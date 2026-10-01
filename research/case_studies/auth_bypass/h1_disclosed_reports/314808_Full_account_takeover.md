# Report #314808: Full account takeover

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/314808](https://hackerone.com/reports/314808)
- **Program:** Reverb.com
- **Reporter:** @sandeep_hodkasia
- **Status:** RESOLVED
- **Severity:** high
- **Weakness:** Improper Access Control - Generic
- **Bounty:** Yes (Undisclosed Amount)
- **Submitted:** 2018-02-10T18:54:54.830Z
- **Disclosed:** 2020-03-19T15:26:51.759Z
- **Community Upvotes:** 411

---

## Executive Summaries

No formal disclosure summary provided.

---

## Full Vulnerability Description & Technical Reproduction Steps

Hello Team,

I got a security issue in reverb ios application which allows an attacker hack all users account.
Since iOS application is not in the scope but still I am reporting this, because this vulnerability may compromise all users account.
Please resolve this quickly. 

Desription:
Reverb ios application is not validating facebook `access_token` on the server side in login api, which allows an  attacker to hack all account using his own app access token.

Vulnerable request:
```
POST /api/auth/facebook HTTP/1.1
Host: reverb.com

{"fb_token":"[REDACTED-disclosed-report-token]"}
```
Here in vulnerable i used lyst app access token to login.

Steps to reproduce:
1. Replay vulnerable request in vulnerable request in burp suite
2. Use any other app access token .

Fix recommendation:
https://developers.facebook.com/docs/facebook-login/security

**(Bug in oauth flow)

## Impact

Attacker Can hack all users account using his own app access token
