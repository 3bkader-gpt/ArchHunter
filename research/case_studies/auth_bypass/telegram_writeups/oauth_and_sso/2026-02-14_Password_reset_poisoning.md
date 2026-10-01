# Password reset poisoning

- **Category:** OAuth & SSO Vulnerabilities
- **Publication Date:** 2026-02-14
- **Source Channel:** GamarSec - Bug Bounty Tips
- **Original Source URL:** [https://portswigger.net/web-security/host-header/exploiting/password-reset-poisoning](https://portswigger.net/web-security/host-header/exploiting/password-reset-poisoning)

---

## Detailed Writeup & Technical Breakdown

- Web Security Academy
- HTTP Host header attacks
- Exploiting
- Password reset poisoning

## Password reset poisoning


Password reset poisoning is a technique whereby an attacker manipulates a vulnerable website into generating a password reset link pointing to a domain under their control. This behavior can be leveraged to steal the secret tokens required to reset arbitrary users' passwords and, ultimately, compromise their accounts.


### Research


This technique was first documented in 2013 by our Director of Research, James Kettle.


Check out our Research page for full write-ups and video presentations of more innovative techniques discovered by James and the rest of the team.


## How does a password reset work?


Virtually all websites that require a login also implement functionality that allows users to reset their password if they forget it. There are several ways of doing this, with varying degrees of security and practicality. One of the most common approaches goes something like this:

- The user enters their username or email address and submits a password reset request.
- The website checks that this user exists and then generates a temporary, unique, high-entropy token, which it associates with the user's account on the back-end.
- The website sends an email to the user that contains a link for resetting their password. The user's unique reset token is included as a query parameter in the corresponding URL:
                
https://normal-website.com/reset?token=0a1b2c3d4e5f6g7h8i9j

The website sends an email to the user that contains a link for resetting their password. The user's unique reset token is included as a query parameter in the corresponding URL:

- When the user visits this URL, the website checks whether the provided token is valid and uses it to determine which account is being reset. If everything is as expected, the user is given the option to enter a new password. Finally, the token is destroyed.

This process is simple enough and relatively secure in comparison to some other approaches. However, its security relies on the principle that only the intended user has access to their email inbox and, therefore, to their unique token. Password reset poisoning is a method of stealing this token in order to change another user's password.


## How to construct a password reset poisoning attack


If the URL that is sent to the user is dynamically generated based on controllable input, such as the Host header, it may be possible to construct a password reset poisoning attack as follows:

- The attacker obtains the victim's email address or username, as required, and submits a password reset request on their behalf. When submitting the form, they intercept the resulting HTTP request and modify the Host header so that it points to a domain that they control. For this example, we'll use evil-user.net.
- The victim receives a genuine password reset email directly from the website. This seems to contain an ordinary link to reset their password and, crucially, contains a valid password reset token that is associated with their account. However, the domain name in the URL points to the attacker's server:
                
https://evil-user.net/reset?token=0a1b2c3d4e5f6g7h8i9j

The victim receives a genuine password reset email directly from the website. This seems to contain an ordinary link to reset their password and, crucially, contains a valid password reset token that is associated with their account. However, the domain name in the URL points to the attacker's server:

- If the victim clicks this link (or it is fetched in some other way, for example, by an antivirus scanner) the password reset token will be delivered to the attacker's server.
- The attacker can now visit the real URL for the vulnerable website and supply the victim's stolen token via the corresponding parameter. They will then be able to reset the user's password to whatever they like and subsequently log in to their account.

In a real attack, the attacker may seek to increase the probability of the victim clicking the link by first warming them up with a fake breach notification, for example.


Even if you can't control the password reset link, you can sometimes use the Host header to inject HTML into sensitive emails. Note that email clients typically don't execute JavaScript, but other HTML injection techniques like dangling markup attacks may still apply.


### Find HTTP Host header vulnerabilities using Burp Suite

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
