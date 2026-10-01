# How I Found an Account Takeover Hiding in a ‘Scan to Upload’ Button

- **Category:** JWT & Session Flaws
- **Publication Date:** 2026-09-11
- **Source Channel:** CyberSec WriteUps
- **Original Source URL:** [https://medium.com/p/c3aa5e4a0e3c](https://medium.com/p/c3aa5e4a0e3c)

---

## Detailed Writeup & Technical Breakdown

## How I Found an Account Takeover Hiding in a ‘Scan to Upload’ Button


--


Listen


Share


Program name, domain, and a few other identifying details in this writeup have been redacted at my request — the rest is exactly how it went down.


I want to write this one differently than most of others writeups. Not “here’s the vuln, here’s the CVSS score, here’s the fix.” I want to walk through how I actually found this, what made me stop and poke at it instead of scrolling past, and what the hunt itself felt like — because I think that part is more useful to other hunters than the bug itself.


## Where my head was at


I was going through [REDACTED_PLATFORM], a marketplace where private sellers list watches. I wasn't hunting for anything specific that day — I was just going through every flow slowly, the boring way. Create a listing, edit a listing, upload photos, change settings. A lot of bug hunting is just doing normal user things very slowly and paying attention to what the app is doing behind your back while you do them.


At one point in the listing flow, the site asks you to upload some verification images — proof you actually own the watch. And it offers a nice little convenience feature: “continue on your phone.” Tap it, and a QR code pops up. Scan it with your phone, and you land straight on the upload page, no login needed on the phone.


That’s the moment that got my attention. Not because it looked broken — it looked completely normal, even thoughtful UX. But “no login needed on the phone” is exactly the kind of sentence that makes me slow down. Somewhere, some URL had to carry enough authority to let a brand-new device skip login. So I wanted to know: what is that URL actually made of, and how much power does it actually have?


## Pulling the thread


I intercepted the request instead of scanning the code with my phone. That gave me the actual URL the QR code was encoding. It looked roughly like this (values changed):


https://[REDACTED_PLATFORM]/private-seller/images-upload.htm?hideListingImages=1&code=<TOKEN>&SETLANG=en_US&tokenType=PrivateSellerImageUpload&watchId=<ID>


Reading it, my assumption was: this should be a narrow, single-purpose token. Its name is literally PrivateSellerImageUpload. It should let you upload images for this one listing and nothing else. That's the whole point of scoping a token — you hand someone a key that only opens one door.


So the natural test was the simplest one I could think of: what happens if I open this exact URL with zero session at all? Full logout, fresh incognito window, no cookies, nothing. If the scoping is done right, I should land on an upload page and be able to do exactly one thing — upload a photo — and nothing else.


I opened it.


## The moment it clicked


The upload page loaded fine, like I expected. But then I did what I always do after landing somewhere new with a suspicious token: I just… clicked around. Went to the account page. Went to another listing. Refreshed.


I was logged in. Fully. As the seller. In a browser that, thirty seconds earlier, had never touched this account.


I remember just sitting there for a second re-reading the URL bar to make sure I hadn’t messed up my own test. Nothing about what I’d done should have authenticated me as anyone. I hadn’t entered a password. I hadn’t clicked “log in.” I’d opened a link that was supposed to say “you may upload a photo here,” and the app had quietly decided that also meant “you may now be this person.”


That’s not the whole bug, honestly. Everything after this was me trying to understand how bad it actually was.


## Chasing it further


Once I know something’s wrong, I don’t stop at the first proof — I try to break my own understanding of it. A few questions I kept asking myself, and what I found chasing each one:


“Okay, but surely logging out kills it?” I logged out of the real account from a different browser, then went back to the browser that had opened the QR link. Still logged in. No revocation, nothing. The account owner had no way to kick this session out even if they knew about it.


“Does the token actually expire, or does it just look like it does?” I reloaded the listing page a bunch of times to see what happened to the token. Every reload minted a brand new code — but the old ones didn't die. I ended up with a handful of different URLs, generated minutes apart, all still working. So it wasn't one link with one lifetime — it was an ever-growing pile of valid links.


“What’s actually inside this token?” I decoded it out of curiosity more than anything. It came apart into what looked like UUID pairs — the kind of thing you’d expect to represent a persistent account identifier, not a short-lived, single-use ticket. That told me this probably wasn’t designed as a real ephemeral capability token at all — it behaved much more like a durable, reusable credential wearing a “temporary upload link” costume.


“Is this a one-way thing, or can it flip?” This is the part I’m most proud of finding, because it wasn’t the obvious next step — I only found it because I was testing the flow from the opposite direction, as the attacker’s side instead of the victim’s. I was already logged into my own account in a browser, and out of curiosity I opened a different account’s upload link in that same, already-authenticated browser. I expected an error, or a prompt, or something. Instead, my session silently flipped into the other account. No warning. No “you’re about to switch accounts, confirm?” Just a quiet swap under the hood.


That last one is the finding that turned this from “a scoping bug” into something with a genuine social angle: you don’t need to steal anything from someone to hand them a working key into your account. You just need them to click a link you send them — “hey can you check if this upload is working” is a completely ordinary sentence to say to a coworker, a family member, or customer support.


## What made this one hard, and worth writing about


None of the individual steps here required exotic tooling — no fuzzers, no custom scripts, nothing clever in terms of technique. What actually found this bug was slowing down at the one moment in the flow that quietly said “no login required” and refusing to just accept that at face value. Every convenience feature that skips a login step is doing so by handing some artifact enough trust to stand in for one — and the only way to know if that trust is properly scoped is to go take the artifact somewhere it isn’t supposed to work and see what happens.


The other habit that mattered here was testing in both directions. Most people, myself included on a bad day, test a bug like “can I use this to get into someone else’s stuff” and stop there. The account-context-swap only showed up because I also asked “what happens if I’m already someone, and I touch your link.” That second direction is easy to skip and it’s often where the more interesting, more human-exploitable version of a bug is hiding.


## Reporting it, and sticking with it


I wrote it up, sent it in, and then spent a long stretch going back and forth answering questions, sending fresh proof-of-concept links, recording screen captures, and re-explaining the mechanics a few different ways until it landed. That part isn’t glamorous, but it’s a real part of hunting too — a good find is only worth something if you can actually get the people on the other end to see it the way you see it. Eventually it did land, the program fixed it, and I retested to confirm the fix actually closed it.


## The takeaway I keep coming back to


Any time a product hands you convenience by skipping a login step — QR codes, magic links, “continue on another device,” email-based confirmation links — there’s a token somewhere doing the job your password normally does. The interesting question is never “can I find this token,” it’s “what does this token actually let me do, versus what it’s supposed to let me do.” That gap is where this entire bug lived, from the first click to the last.

---
*Archived in Auth Bypass Vault from verified bug bounty community intelligence.*
