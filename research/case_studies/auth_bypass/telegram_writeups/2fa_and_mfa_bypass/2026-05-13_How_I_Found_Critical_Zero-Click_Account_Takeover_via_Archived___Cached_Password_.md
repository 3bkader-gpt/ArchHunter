# How I Found Critical Zero-Click Account Takeover via Archived / Cached Password Reset Links And Got 💰

- **Category:** 2FA & MFA Bypass
- **Publication Date:** 2026-05-13
- **Source Channel:** GamarSec - Bug Bounty Tips
- **Original Source URL:** [https://wadgamaraldeen.medium.com/critical-zero-click-account-takeover-via-archived-cached-password-reset-links-6ce7c9bef962](https://wadgamaraldeen.medium.com/critical-zero-click-account-takeover-via-archived-cached-password-reset-links-6ce7c9bef962)

---

## Detailed Writeup & Technical Breakdown

## How I Found Critical Zero-Click Account Takeover via Archived / Cached Password Reset Links And Got 💰


--


3


Listen


Share








Hello Hunters, This is a new Write up about another exiting finding ,Its about How i found a Zero-Click Account Takeover via Archived / Cached Password Reset Links


Lets start …


## Summary


I identified A critical vulnerability in the password reset mechanism of `redacted.com` that enables full account takeover without any user interaction.


Password reset links were found to be publicly exposed via third-party archival platforms (e.g., VirusTotal) and remain valid indefinitely.


This vulnerability allows any attacker to:- Reuse exposed reset links- Set a new password- Gain full access to victim accounts


## No email access, OTP, or victim interaction required → Zero-Click Account Takeover


## How It Happened


While performing reconnaissance on authentication flows, I shifted focus from typical attack vectors (Host Header Injection, reset poisoning, etc.) to external exposure surfaces.


Instead of targeting the application directly, I analyzed how password reset links behave once they leave the system.


This led to discovering publicly indexed reset URLs.


## Phase 1 — Discovery via External Indexing


I used Orwa’s Awesome script :- virustotalx :- https://github.com/orwagodfather/virustotalx for URLs Recon.


Multiple password reset URLs were identified via third-party indexing platforms.


Example pattern:


https://redacted.com/blablabla/Account/PasswordReset/{GUID}/{Company}/{Username}


These links contain:- Reset token (GUID)- Company identifier- Username / email


## Phase 2 — Token Validation


### Request


GET /blablabla/blablabla/PasswordReset/44dfdff765/company-name/user-name@something.com HTTP/1.1Host: redacted.com


### Response


HTTP/2 200 OKContent-Type: text/html


The server returned a fully functional password reset page.


Observations:- No expiration enforced- No authentication required- No secondary verification


## Phase 3 — Password Reset


### Request


POST /blablabla/Account/PasswordResetblablabla/545g4565tt4/company-name/employee%40something.com HTTP/2Host: redacted.comContent-Type: application/x-www-form-urlencoded


CompanyLogin=company-nameUserName=empolyee-name%40something.com&Password=NewP@ssw0rd123NewPassword=NewP@ssw0rd123&ConfirmPassword=NewP@ssw0rd123


### Response


HTTP/2 200 OK


“Your password was successfully reset.”


## Phase 4 — Account Takeover


### Request


POST /blablabla/Accountblablabla/LogOn/company-name/company-name@something.com HTTP/2Host: redacted.comContent-Type: application/x-www-form-urlencoded


CompanyLogin=company-nameUserName=empolyee-name%40something.com&Password=NewP@ssw0rd123


### Response


HTTP/2 302 FoundLocation: /blablabla/Home/Index


Result: Successful login and full account takeover


## Critical Observation


This attack requires:- No phishing- No victim interaction- No credentials- No brute force


## Only a leaked reset link


## Phase 5 — Mass Exposure


Multiple additional reset links were identified publicly:


https://redacted.com/blablabla/blablabla/PasswordReset/79yyuy67c65-.../company1/user1@somethin.com


https://redacted.com/blablabla/blablabla/PasswordReset/23swede82c65-.../company2/user2@somethin.com


https://redacted.com/blablabla/blablabla/PasswordReset/889e82c65-.../company3/user3@somethin.com


.


.


.


https://redacted.com/blablabla/blablabla/PasswordReset/99e82c65-.../company-number/user-blablabla@somethin.com


These were NOT exploited.


## The vulnerability had been validated by The Hackerone Triage team and by The Company Internal Engineering Team and got Rewarded.


## Root Cause


- Password reset tokens do not expire- Tokens remain valid after exposure- Reset URLs are indexed by external services- No OTP or secondary verification- Sensitive data exposed in URL- Missing cache-control protections


Missing headers:


Cache-Control: no-storePragma: no-cacheX-Robots-Tag: noindex, noarchive


## Impact


An attacker can:- Reset passwords of arbitrary users- Gain full authenticated access- Access sensitive company data- Perform lateral movement across tenants


Multi-tenant compromise risk


## Severity


Critical


Reason:- Authentication bypass- Zero-click exploitation- Mass exploitation potential- No user interaction required


## Recommended Remediation


### Token Security- Expire tokens within 15–30 minutes- Invalidate after first use


### Prevent Indexing


Cache-Control: no-storePragma: no-cacheX-Robots-Tag: noindex, noarchive


### Flow Hardening- Require OTP before password change- Bind tokens to session / IP / User-Agent


### URL Design- Remove sensitive data from URLs- Use opaque tokens


### Monitoring- Detect abnormal reset activity- Alert on bulk reset attempts


### Incident Response- Invalidate all existing tokens- Force password resets- Review logs for abuse


## Conclusion


This vulnerability enables silent, large-scale account compromise due to publicly exposed and long-lived password reset tokens.


Immediate remediation is strongly recommended.


## Ethical Note


- Only one account was used for validation- No data was modified- All other exposed links were not tested


Thanks for reading. And i hope that you learned something new.


If you wanna following me on social media :-


https://t.me/wadgamaraldin (Telegram Channel For — Writeups — Blogs — Bug Bounty Tips — YouTube Videos )


https://www.linkedin.com/in/wadgamaraldeen/


https://twitter.com/wadgamaraldeen/


https://www.facebook.com/wadgamaraldeen/


## About Me


Mustafa Adam


Bug Bounty Hunter

- HackerOne / Zerocopoter / Standoff365 / Google VRP / Private Programs
- Focus: Web Application Security

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
