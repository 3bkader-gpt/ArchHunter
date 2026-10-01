# How Interesting 2FA Bypass Through Browser Feature Lead Me To Critical Vulnerability.

- **Category:** 2FA & MFA Bypass
- **Publication Date:** 2025-05-31
- **Source Channel:** Bug Bounty Hub
- **Original Source URL:** [https://medium.com/@dishantsingh989/how-interesting-2fa-bypass-through-browser-feature-lead-me-to-critical-vulnerability-18f9c72a8f8d](https://medium.com/@dishantsingh989/how-interesting-2fa-bypass-through-browser-feature-lead-me-to-critical-vulnerability-18f9c72a8f8d)

---

## Detailed Writeup & Technical Breakdown

## How Interesting 2FA Bypass Through Browser Feature Lead Me To Critical Vulnerability.


--


4


Listen


Share


### Introduction:


Hello Hackers! I’m Dishant Singh a 16-year-old bug bounty hunter from India. I’m excited to share my recent finding regarding 2FA bypass on Hackerone’s Public Program. This bypass was quite unexpected and interesting that’s why i am sharing this to all of you. Let’s Dive Into it,


### What’s 2FA ?


2FA stands for “Two-Factor Authentication.” It is a security process that requires users to provide two different authentication factors before gaining access to a system, account, or application. The goal of 2FA is to enhance security by adding an additional layer of verification beyond just a username/email and password.


> Let’s call our target as “redacted.com” as i can’t disclose target here. Although this issue is resolved now but, still Program policy.


Let’s call our target as “redacted.com” as i can’t disclose target here. Although this issue is resolved now but, still Program policy.


### Discovery: 🔎


I was Looking for Low-Hanging fruit’s on login process. i had also enabled 2FA that time for my account i tried normal bypasses which were most probably known to most of us. Later while browsing and checking issues regarding sessions timeout. i noticed my browser BACK Button bypassed the 2FA process. After providing creds and clicking the back button in broswer bypassed the 2FA for my Account. I immediately recorded POC for it and Submitted it to Program through Hackerone Platform


### Steps To Reproduce:

- Login to account on https://redacted.com/dashboard/sign-in using credentials.

2. It will ask you to enter 2FA code.


3. Click on browser back button shown on upper-left corner of your broweser


4. You will see the 2FA is getting bypassed


### Program’s Reply:


> Hi @dishant_singhWe have deployed a fix for the issue! Now, some important information about the fix, please read carefully before trying to retest.At Redacted, the Auth system has two levels of trust. AAL1 and AAL2. When you login with username + password (but skip MFA like you do with the back button) - you are granted an AAL1 trusted token. This token has minimal access to the Redacted dashboard. This is by design. In this minimal level, you can see various areas of your user profile and interact with some functionality. You however can't view or interact with Projects or access sensitive areas such as creating new access tokens. When you do login with MFA, your access token is AAL2 and can access everything, it has full privileges.So what did we fix?It is still possible to use the back button and skip MFA, but you’ll be logged in with the minimal AAL1 token. When you reported this to us, we discovered that the AAL1 token allowed you to create new access tokens which had full privileges, this was a critical bug. Our fix has been to ensure that functionality is only available to AAL2 tokens. Even though your report was about "bypassing MFA", something that was built into the design, your report did help us identify the critical bug in access tokens. For that reason we are keeping this report as critical, great work!Thanks for helping make Redactedmore secure and we look forward to working with you more in the future. Please keep an eye on our program for exciting updates and changes as we grow.Kind regards,Redacted


Hi @dishant_singh


We have deployed a fix for the issue! Now, some important information about the fix, please read carefully before trying to retest.


At Redacted, the Auth system has two levels of trust. AAL1 and AAL2. When you login with username + password (but skip MFA like you do with the back button) - you are granted an AAL1 trusted token. This token has minimal access to the Redacted dashboard. This is by design. In this minimal level, you can see various areas of your user profile and interact with some functionality. You however can't view or interact with Projects or access sensitive areas such as creating new access tokens. When you do login with MFA, your access token is AAL2 and can access everything, it has full privileges.


So what did we fix?


It is still possible to use the back button and skip MFA, but you’ll be logged in with the minimal AAL1 token. When you reported this to us, we discovered that the AAL1 token allowed you to create new access tokens which had full privileges, this was a critical bug. Our fix has been to ensure that functionality is only available to AAL2 tokens. Even though your report was about "bypassing MFA", something that was built into the design, your report did help us identify the critical bug in access tokens. For that reason we are keeping this report as critical, great work!


Thanks for helping make Redactedmore secure and we look forward to working with you more in the future. Please keep an eye on our program for exciting updates and changes as we grow.


Kind regards,


Redacted


Thanks For Reading This And Giving your precious time to it. I hope all of you will like it. Moreover, it’s First Time me writing a Write-up for community and others sake. i hope all of you won’t mind any grammatical Mistakes in this article


Thank You


### Connect with Me:

- Twitter
- LinkedIn
- HackerOne
- Instagram

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
