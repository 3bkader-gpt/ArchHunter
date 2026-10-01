# Report #2122671: IDOR - Delete all Licenses and certifications from users account using CreateOrUpdateHackerCertification GraphQL query

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/2122671](https://hackerone.com/reports/2122671)
- **Program:** HackerOne
- **Reporter:** @harshdranjan
- **Status:** RESOLVED
- **Severity:** high
- **Weakness:** Insecure Direct Object Reference (IDOR)
- **Bounty:** Yes (Undisclosed Amount)
- **Submitted:** 2023-08-24T15:52:11.345Z
- **Disclosed:** 2023-08-29T14:30:10.014Z
- **Community Upvotes:** 392

---

## Executive Summaries

No formal disclosure summary provided.

---

## Full Vulnerability Description & Technical Reproduction Steps

**Summary:**
Hey team,

While editing our **Licenses and certifications** if we change the ID number we can delete other users **Licenses and certifications**. it simply can be done by editing the ID number in our graphql query.
If change the ID from 1 to X possible range then we can delete all the **Licenses and certifications** present between these.


### Steps To Reproduce

1. Log in to your own account in two browsers A and B with User A and User B
2. Create your own **Licenses and certifications* in both the account
3. Now edit your own **Licenses and certifications* and Intercept this using a Burp Proxy 
4. Now In the body change the **ID** number and you will be able to delete all the **Licenses and certifications** present in HackerOne 
5. For now change the ID to the **Licenses and certifications** ID of the Other account and it will be deleted.

PoC Video: ████

## Impact

Able to delete all the **Licenses and certifications** present in HackerOne
