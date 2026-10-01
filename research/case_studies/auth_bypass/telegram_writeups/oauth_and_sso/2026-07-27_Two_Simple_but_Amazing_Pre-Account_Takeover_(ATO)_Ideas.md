# Two Simple but Amazing Pre-Account Takeover (ATO) Ideas

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-07-27
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://medium.com/@mo_0xnaser/two-simple-but-amazing-pre-account-takeover-ato-ideas-b4a98311a5e9?source=rss------bug_bounty-5](https://medium.com/@mo_0xnaser/two-simple-but-amazing-pre-account-takeover-ato-ideas-b4a98311a5e9?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## Two Simple but Amazing Pre-Account Takeover (ATO) Ideas


--


Listen


Share






Hello everyone! 👋


My name is Mohamed Naser, and today I’d like to share two real-world Pre-Account Takeover (ATO) ideas that I discovered while hunting on two different bug bounty programs.


Both bugs were surprisingly simple, yet they demonstrate how small implementation mistakes can lead to unexpected security issues.


So, let’s dive in!


## 1. Pre-Account Takeover via OAuth Misconfiguration


While testing the first application, I noticed something interesting.


When changing the email address from the account settings, the application updated the email immediately without requiring any verification link or confirmation code.


At that moment I stopped and thought:


> “Hmm… this feels a little suspicious. 🤔”


“Hmm… this feels a little suspicious. 🤔”


After digging deeper, I discovered that the application also supported OAuth authentication.


## What is OAuth?


OAuth is an authentication mechanism that allows users to sign in using existing accounts such as:

- Google
- Facebook
- Apple

Instead of creating a new username and password, users simply click “Continue with Google” (or another provider), and the website authenticates them.


Unfortunately, OAuth integrations are a common source of security vulnerabilities when implemented incorrectly.


Let’s look at one example.


## Attack Scenario


Assume the attacker performs the following steps:

- Create a normal account using:
- Email: attacker@gmail.com
- Password: P@ssw0rd

2. Log out.


3. login back in using Google OAuth.


4. Navigate to Account Settings.


5. Change the account email from:


```
attacker@gmail.com
```


to


```
victim@gmail.com
```


No verification email.


No confirmation code.


Nothing.


The application immediately accepts the new email.


> Important NoteAt this point, the victim has never registered an account using victim@gmail.com.


Important Note


At this point, the victim has never registered an account using victim@gmail.com.


## Victim’s Behavior


Later, the victim visits the website and attempts to create a new account using:


```
victim@gmail.com
```


Instead of allowing registration, the application displays:


```
This account already exists.
```


The victim is redirected to the login page.


Since they believe an account already exists, they simply click Forgot Password, receive a reset link, set a password, and begin using the account normally.


Everything looks perfectly fine…


Or does it? 😄


## Where Is the Vulnerability?


Remember that the attacker originally authenticated using Google OAuth.


OAuth authentication is still linked to the original account.


That means:

- The victim now accesses the account using email and password.
- The attacker can still access the exact same account by signing in with Google OAuth with attacker@gmail.com email.

Congratulations…


The application has unintentionally created a shared account between the attacker and the victim.


This results in a Pre-Account Takeover (Pre-ATO).


## Report Result

- Severity: Medium
- Status: Duplicate

Sometimes that’s bug bounty life. 😅


## 2. Pre-Account Takeover through an Insecure User Invitation Mechanism


The second bug was found in another application that provides:

- AI image generation
- Ready-made design templates
- Team collaboration

The platform offers a 14-day free trial, and each trial account includes two team licenses.


## What Is a License?


A license allows the account owner to invite another user so both users can access the premium features.


Sounds straightforward…


Until the invitation workflow goes wrong.


## The Problem


When a user receives an invitation, they:

- Accept the invitation.
- Log in normally.
- Access the shared workspace.

So far, everything works as expected.


However, if the workspace owner later removes that user from the organization, something unexpected happens.


The removed user’s account becomes locked and cannot be accessed without being added back by an administrator.


No matter what the user tries — logging in again, resetting the password, or using different authentication methods — the account remains inaccessible.


## Attack Scenario


An attacker can abuse this workflow as follows:

- Invite a new user.
- Wait until the user logs in and activates the account.
- Remove the user from the organization. {image}
- The victim’s account becomes locked.
- Repeat the process with additional users.

This creates a denial-of-access scenario for newly invited accounts due to the insecure invitation mechanism.


## Report Result

- Severity: Informative
- Status: Closed

## Final Thoughts


These two cases show that Pre-Account Takeover vulnerabilities don’t always require complicated attack chains.


Sometimes, all it takes is:

- A missing email verification.
- A poorly designed invitation workflow.
- A small authentication oversight.

Simple bugs.


Simple logic.


But surprisingly interesting security lessons.


Happy hunting! 🚀

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
