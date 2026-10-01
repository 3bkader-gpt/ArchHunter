# Curated Bug Bounty Intelligence & Writeups

This repository contains **34 high-signal, fully verified bug bounty writeups and technical intelligence articles** extracted from premier red-team and bug bounty channels. Every article has been audited to eliminate promotional noise, truncated snippets, and low-quality summaries, preserving comprehensive technical methodologies and reproduction proofs.

---

## Breakdown by Vulnerability Class

### OAuth & SSO Vulnerabilities (14 Articles)

| Date | Title | Size | Link |
| :--- | :--- | :--- | :--- |
| `2026-02-14` | Password reset poisoning | 4.9 KB | [Read Writeup](./oauth_and_sso/2026-02-14_Password_reset_poisoning.md) |
| `2026-06-27` | I Found a High-Severity OAuth Account Takeover Vulnerability on IIT Madras’s Student Portal | 7.3 KB | [Read Writeup](./oauth_and_sso/2026-06-27_I_Found_a_High-Severity_OAuth_Account_Takeover_Vulnerability_on_IIT_Madras’s_Stu.md) |
| `2026-07-06` | Breaking Trust, Not Cryptography: A Critical JWT Authentication Design Flaw Worth $1,450 | 10.1 KB | [Read Writeup](./oauth_and_sso/2026-07-06_Breaking_Trust,_Not_Cryptography__A_Critical_JWT_Authentication_Design_Flaw_Wort.md) |
| `2026-07-25` | Empty Page Leaked a JWT — Privilege Escalation From the Lowest Role | 8.8 KB | [Read Writeup](./oauth_and_sso/2026-07-25_Empty_Page_Leaked_a_JWT_—_Privilege_Escalation_From_the_Lowest_Role.md) |
| `2026-07-26` | I Modified Collections I Did Not Own: IDOR | 4.5 KB | [Read Writeup](./oauth_and_sso/2026-07-26_I_Modified_Collections_I_Did_Not_Own__IDOR.md) |
| `2026-07-26` | JWT Security TryHackMe Room Walkthrough | 28.2 KB | [Read Writeup](./oauth_and_sso/2026-07-26_JWT_Security_TryHackMe_Room_Walkthrough.md) |
| `2026-07-26` | The Header That Signed Itself: Full Account Takeover in a Google SSO Flow | 11.9 KB | [Read Writeup](./oauth_and_sso/2026-07-26_The_Header_That_Signed_Itself__Full_Account_Takeover_in_a_Google_SSO_Flow.md) |
| `2026-07-27` | Two Simple but Amazing Pre-Account Takeover (ATO) Ideas | 5.9 KB | [Read Writeup](./oauth_and_sso/2026-07-27_Two_Simple_but_Amazing_Pre-Account_Takeover_(ATO)_Ideas.md) |
| `2026-08-23` | How Broken OAuth Flows Turn Into One-Click Account Takeovers | 20.6 KB | [Read Writeup](./oauth_and_sso/2026-08-23_How_Broken_OAuth_Flows_Turn_Into_One-Click_Account_Takeovers.md) |
| `2026-09-09` | The $0 Exploit: Account Takeover via a Single HTTP Redirect | 8.8 KB | [Read Writeup](./oauth_and_sso/2026-09-09_The_$0_Exploit__Account_Takeover_via_a_Single_HTTP_Redirect.md) |
| `2026-09-10` | From File Upload to Account Takeover: Chaining Stored XSS for Credential Exposure and Privilege Escalation | 14.2 KB | [Read Writeup](./oauth_and_sso/2026-09-10_From_File_Upload_to_Account_Takeover__Chaining_Stored_XSS_for_Credential_Exposur.md) |
| `2026-09-10` | I Wasn’t Looking for PII. I Just Cancelled an Invite. (IDOR → PII) | 4.1 KB | [Read Writeup](./oauth_and_sso/2026-09-10_I_Wasn’t_Looking_for_PII._I_Just_Cancelled_an_Invite._(IDOR_→_PII).md) |
| `2026-09-11` | JWT Internals: What’s Actually Inside That Token You Trust | 7.9 KB | [Read Writeup](./oauth_and_sso/2026-09-11_JWT_Internals__What’s_Actually_Inside_That_Token_You_Trust.md) |
| `2026-09-12` | How We Found a Critical Bug in India’s Income Tax Portal That Put 135M+ Users’ Sensitive Data at Risk | 8.9 KB | [Read Writeup](./oauth_and_sso/2026-09-12_How_We_Found_a_Critical_Bug_in_India’s_Income_Tax_Portal_That_Put_135M+_Users’_S.md) |

---

### JWT & Session Flaws (9 Articles)

| Date | Title | Size | Link |
| :--- | :--- | :--- | :--- |
| `2024-12-30` | Discovered 30 BOLA + IDOR vulnerabilities in a single subdomain (BBP). | 5.8 KB | [Read Writeup](./jwt_and_session_attacks/2024-12-30_Discovered_30_BOLA_+_IDOR_vulnerabilities_in_a_single_subdomain_(BBP).md) |
| `2026-06-14` | Client-side Authentication Bypass | 13.7 KB | [Read Writeup](./jwt_and_session_attacks/2026-06-14_Client-side_Authentication_Bypass.md) |
| `2026-06-25` | Privilege Escalation Through Named-Pipe Flaw | 5.8 KB | [Read Writeup](./jwt_and_session_attacks/2026-06-25_Privilege_Escalation_Through_Named-Pipe_Flaw.md) |
| `2026-06-28` | Authentication Bypass Bugs: The Beginner Friendly Money Maker | 3.1 KB | [Read Writeup](./jwt_and_session_attacks/2026-06-28_Authentication_Bypass_Bugs__The_Beginner_Friendly_Money_Maker.md) |
| `2026-07-28` | How I Found a Broken Access Control Vulnerability During a Penetration Test | 4.5 KB | [Read Writeup](./jwt_and_session_attacks/2026-07-28_How_I_Found_a_Broken_Access_Control_Vulnerability_During_a_Penetration_Test.md) |
| `2026-09-09` | CVE-2026–64857 — Session Fixation in Tirreno Authentication | 4.0 KB | [Read Writeup](./jwt_and_session_attacks/2026-09-09_CVE-2026–64857_—_Session_Fixation_in_Tirreno_Authentication.md) |
| `2026-09-09` | I Forged My Own Admin Token by Exploiting JWT Algorithm Confusion ($8,500 Bounty) | 8.9 KB | [Read Writeup](./jwt_and_session_attacks/2026-09-09_I_Forged_My_Own_Admin_Token_by_Exploiting_JWT_Algorithm_Confusion_($8,500_Bounty.md) |
| `2026-09-11` | How I Found an Account Takeover Hiding in a ‘Scan to Upload’ Button | 8.6 KB | [Read Writeup](./jwt_and_session_attacks/2026-09-11_How_I_Found_an_Account_Takeover_Hiding_in_a_‘Scan_to_Upload’_Button.md) |
| `2026-09-11` | JWT Exploits: Three Ways Trust Gets Misconfigured | 9.6 KB | [Read Writeup](./jwt_and_session_attacks/2026-09-11_JWT_Exploits__Three_Ways_Trust_Gets_Misconfigured.md) |

---

### IDOR & Broken Access Control (6 Articles)

| Date | Title | Size | Link |
| :--- | :--- | :--- | :--- |
| `2026-03-26` | CONCURRENCY TEST — RACE CONDITION | 2.8 KB | [Read Writeup](./idor_and_bac/2026-03-26_CONCURRENCY_TEST_—_RACE_CONDITION.md) |
| `2026-04-29` | web cache deception - quick view | 4.8 KB | [Read Writeup](./idor_and_bac/2026-04-29_web_cache_deception_-_quick_view.md) |
| `2026-05-26` | ATO-Via-Password-Reset-Test.md | 5.5 KB | [Read Writeup](./idor_and_bac/2026-05-26_ATO-Via-Password-Reset-Test.md) |
| `2026-06-26` | $1,100 Privilege Escalation: Group Leader Can Promote Anyone via Hidden Parameter | 6.3 KB | [Read Writeup](./idor_and_bac/2026-06-26_$1,100_Privilege_Escalation__Group_Leader_Can_Promote_Anyone_via_Hidden_Paramete.md) |
| `2026-07-26` | Frontend Security Is Not Enough: A Practical Demonstration of Broken Access Control in REST APIs | 3.2 KB | [Read Writeup](./idor_and_bac/2026-07-26_Frontend_Security_Is_Not_Enough__A_Practical_Demonstration_of_Broken_Access_Cont.md) |
| `2026-09-09` | My First Paid Bug Bounty: A Broken Access Control Vulnerability | 4.5 KB | [Read Writeup](./idor_and_bac/2026-09-09_My_First_Paid_Bug_Bounty__A_Broken_Access_Control_Vulnerability.md) |

---

### 2FA & MFA Bypass (5 Articles)

| Date | Title | Size | Link |
| :--- | :--- | :--- | :--- |
| `2025-05-31` | How Interesting 2FA Bypass Through Browser Feature Lead Me To Critical Vulnerability. | 5.9 KB | [Read Writeup](./2fa_and_mfa_bypass/2025-05-31_How_Interesting_2FA_Bypass_Through_Browser_Feature_Lead_Me_To_Critical_Vulnerabi.md) |
| `2026-05-01` | CVE-2026-41940: A Critical Authentication Bypass in cPanel | 19.4 KB | [Read Writeup](./2fa_and_mfa_bypass/2026-05-01_CVE-2026-41940__A_Critical_Authentication_Bypass_in_cPanel.md) |
| `2026-05-13` | How I Found Critical Zero-Click Account Takeover via Archived / Cached Password Reset Links And Got 💰 | 6.5 KB | [Read Writeup](./2fa_and_mfa_bypass/2026-05-13_How_I_Found_Critical_Zero-Click_Account_Takeover_via_Archived___Cached_Password_.md) |
| `2026-08-25` | The art of Race Condition:how a simple race condition can leads to ATO! | 4.8 KB | [Read Writeup](./2fa_and_mfa_bypass/2026-08-25_The_art_of_Race_Condition_how_a_simple_race_condition_can_leads_to_ATO!.md) |
| `2026-09-11` | BigBear 2.0: The Phishing Kit That Beats MFA Without a Password | 12.9 KB | [Read Writeup](./2fa_and_mfa_bypass/2026-09-11_BigBear_2.0__The_Phishing_Kit_That_Beats_MFA_Without_a_Password.md) |

---

## Summary of Key Technical Highlights

1. **Zero-Click & 1-Click Account Takeovers:**
   - Pre-Account Takeover chaining unvalidated email registrations with OAuth providers.
   - Race conditions in OTP verification windows allowing brute force within 500ms concurrent thread pools.
   - Google SSO signed header spoofing and state desynchronization.

2. **JWT Cryptographic & Design Flaws:**
   - RS256 to HS256 algorithm confusion forging superadmin tokens with JWKS public keys.
   - Empty page / internal endpoint token leaks leading to horizontal and vertical privilege escalation.
   - Alg `none` and missing signature validation in enterprise gateways.

3. **Enterprise IDOR & BAC:**
   - Multi-tenant tenant ID parameter manipulation across REST APIs.
   - Web cache deception exposing cached sensitive user profiles and tokens.
   - Hidden parameter pollution in group leader / invite workflows.

4. **Modern MFA Bypass & AiTM:**
   - Reverse proxy AiTM session cookie extraction bypassing FIDO/TOTP (Evilginx2 / BigBear 2.0).
   - Response status code manipulation and browser feature misuse during multi-step auth.
