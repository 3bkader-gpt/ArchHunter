# The art of Race Condition:how a simple race condition can leads to ATO!

- **Category:** 2FA & MFA Bypass
- **Publication Date:** 2026-08-25
- **Source Channel:** Daily Bounty Writeups
- **Original Source URL:** [https://medium.com/@tomahawk0ctf/the-art-of-race-condition-how-a-simple-race-condition-can-leads-to-ato-f02157210897?source=rss------bug_bounty-5](https://medium.com/@tomahawk0ctf/the-art-of-race-condition-how-a-simple-race-condition-can-leads-to-ato-f02157210897?source=rss------bug_bounty-5)

---

## Detailed Writeup & Technical Breakdown

## The art of Race Condition:how a simple race condition can leads to ATO!


--


Listen


Share


when i was do some bug bounty on a web application target, I decided to move to the Password Reset / Forgot Password function and deeg deep in to it. While standard security controls like rate-limiting and lockout mechanisms were strictly enforced, a deeper logic flaw involving concurrent requests allowed me to bypass the OTP validation limits and achieve a full Account Takeover (ATO).


## Understanding the flow


When i analyzed the forgot password flow, I mapped out the core steps implemented by the application:

- Initiate Request: Enter the account email into the forgot password endpoint.
- OTP Generation: A 6-digit numeric OTP is sent to the user.
- Validation Limits: The application strictly enforced a maximum of 5 failed attempts per OTP to prevent brute-forcing.

I initially tested all the usual vectors:

- Rate-Limiting: Robustly implemented on the verification endpoint (blocked after multiple rapid requests).
- Response Manipulation: Handled properly (the system was validation perfectly for the otp from the Response Manipulation).
- Old OTP Invalidation: Tested whether previously generated OTPs remained valid after requesting a new one. (They correctly expired individually).

## The Vulnerability: Race Condition & State Confusion


Since standard methods failed, I shifted focus to how the application handles multiple active OTP states concurrently.


I observed that when triggering a (Resend Code) multiple times the backend generated new valid 6-digit codes. However, due to a flaw in how session states or token bindings were handled concurrently:

- Global Endpoint Rate Limit: The application enforced a maximum threshold of 500 requests on the endpoint before triggering a block.
- Generating Multiple Codes at once : By sending a parallel burst of requests to the resend/generate endpoint (taking advantage of the allowed endpoint threshold), multiple valid OTPs were generated simultaneously for the same session.
- The Race Condition : When these multiple valid OTPs were injected or tested within the same packet window (or mapped to concurrent states), all of the concurrently generated OTPs remained valid, rather than invalidating the previous ones immediately upon a new generation request.
- Bypassing the 5-Attempt Limit: Because I could accumulate a pool of valid OTPs through parallel generation without triggering the lockout too fast (staying under global endpoint limits), I had a high probability matrix to test valid codes directly without hitting the 5-tries block on a single dead-end code.

> Root Cause: The backend failed to atomically invalidate older active tokens upon generating a new one when requests were hurled concurrently, leading to a multi-token validity state tied loosely to the session/CSRF context.


Root Cause: The backend failed to atomically invalidate older active tokens upon generating a new one when requests were hurled concurrently, leading to a multi-token validity state tied loosely to the session/CSRF context.


## Impact

- Full Account Takeover (ATO): An attacker can compromise any user account without needing prior session access, purely by manipulating the OTP generation state through a race condition and bypassing the brute-force restriction limits.

## Remediation / Recommendations

- Atomic Token Invalidation: Ensure that whenever a new OTP is requested, all previously active OTPs for that user/session are immediately and atomically invalidated.
- Strict Rate Limiting on Generation: Implement tight rate-limiting not just on the verification endpoint, but also on the generation/resend endpoint to prevent flooding the database with active tokens.
- Lockout Synchronization: Tie the failure counter globally to the session/identifier rather than individual tokens if multiple tokens are somehow allowed.

## The End

- at the end i just want to say somthing to remind my self and you that the comfort zone is always the most dangerous thing
- be free to tack a look in my linkedin profile www.linkedin.com/in/youssef-aly-abdelsalam-5b1b713a3and see the other writeups

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
