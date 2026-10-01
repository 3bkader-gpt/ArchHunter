# How a Single Copied Function Gave Me Pre-Auth RCE in an LLM DevOps Platform — and What Happened When I Reported It

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-06-24
- **Source Channel:** Daily Bounty Writeups
- **Original Reference URL:** [https://medium.com/@cihananthony/how-a-single-copied-function-gave-me-pre-auth-rce-in-an-llm-devops-platform-and-what-happened-47fa7714e10d?source=rss------bug_bounty-5](https://medium.com/@cihananthony/how-a-single-copied-function-gave-me-pre-auth-rce-in-an-llm-devops-platform-and-what-happened-47fa7714e10d?source=rss------bug_bounty-5)

---

## Full Article / Writeup Content

# How a Single Copied Function Gave Me Pre-Auth RCE in an LLM DevOps Platform — and What Happened When I Reported It


--


Listen


Share


## The discovery, confirmation, and frustrating disclosure of a critical code-injection flaw in Bisheng (dataelement/bisheng)


There is a particular kind of vulnerability that feels less like a discovery and more like a moment of recognition. You are reading source code, and a pattern goes by that you have seen before — somewhere it caused real damage — and here it is again, unbothered, in a different project, waiting.


That is how this finding began. A code-validation routine that executes the very code it is supposed to be checking, reachable by anyone on the network with no authentication, in a platform built to sit inside corporate environments and orchestrate LLM workflows over sensitive documents.


But the discovery turned out to be only half the story. The other half — what happened after I reported it — is the part I think is actually worth your time, because it is a small case study in how the disclosure process can leave everyone worse off even when the bug gets fixed.


This post walks through both. I have deliberately held back the fully weaponized exploit chain. The goal is to explain the bug well enough that defenders understand the risk and developers stop shipping the pattern — not to hand anyone a turnkey attack.


## What Bisheng is


Bisheng is an open-source “LLM DevOps” platform; think RAG pipelines, agent orchestration, document indexing, and model management, packaged for enterprise deployment. The kind of system that ends up on an internal network, wired into object storage, a database, a vector store, and a pile of API keys and OAuth tokens for connected SaaS. That deployment profile matters. It is exactly the sort of target where a single code-execution primitive turns into access to everything the platform touches.


## The pattern I recognized


The bug lives in a function whose entire job is to validate user-submitted Python, to check that imports resolve and that a function definition is syntactically sound. Validation, on its face, sounds harmless. The problem is in how it was implemented.


The routine parses the submitted code into an abstract syntax tree (AST), walks the tree, and for every function definition it finds, it compiles that node and executes it:


Python


```
code_obj = compile(ast.Module(body=[node], type_ignores=[]), '<string>', 'exec')exec(code_obj)
```


If you have spent any time around Python internals, an alarm just went off. And if you followed AI-infrastructure security in 2025, you have seen this exact alarm before.


This is the same pattern as CVE-2025–3248 in Langflow: a CVSS 9.8 unauthenticated RCE in a /api/v1/validate/code endpoint, disclosed in April 2025, patched in Langflow 1.3.0 by adding authentication and rejecting dangerous AST nodes. That vulnerability was actively exploited in the wild to deploy the Flodrix botnet, using a public proof-of-concept, within weeks of disclosure.


Bisheng’s endpoint is named the same way. The vulnerable function reads as though it was lifted from Langflow’s pre-1.3.0 code, and the upstream fix never came along for the ride.


## Why “we don’t run the body” is not a defense


The natural objection, and I suspect the original author’s mental model, is: executing a function definition doesn’t run the function’s body. The body only runs when you call it. So compiling and exec-ing a def is safe.


The body, yes. Everything else, no.


When Python executes a function definition, it eagerly evaluates several expressions that are part of the definition itself, before the function is ever called:

- Default argument values — def f(x=EXPR): ... evaluates EXPR at definition time
- Keyword-only defaults — def f(*, x=EXPR): ...
- Decorators — @EXPR above a def runs immediately
- Annotations — in standard CPython without from __future__ import annotations, annotation expressions are evaluated too

Any one of those is an execution sink. You do not need anyone to call your function. You just need it to be defined. And defining it is precisely what the “validator” does for you.


So a submitted snippet whose only notable feature is a default argument that performs an action will perform that action the instant the validator processes it. No call required. No authentication required.


## Tracing the authentication boundary


A code-execution sink is only a pre-auth RCE if an unauthenticated request can actually reach it. So I traced the request path layer by layer:

- The application’s middleware turned out to be logging-only, no auth enforcement there.
- The top-level /api/v1 router declared no dependencies.
- The validate sub-router declared no dependencies.
- The endpoint handler itself took no authentication dependency.

To be sure this was an oversight rather than an intentional public endpoint, I compared it against its siblings. Every other router in the same /api/v1 tree — flows, assistants, datasets, audit, and the rest — required a logged-in user, enforced either at the router or the handler. The validation endpoint was the lone exception. One missing dependency, and a code-execution sink became reachable by anyone who could send it an HTTP request.


That is the whole vulnerability: an execution sink that should never have existed, sitting behind an authentication check that was never applied.


## Confirming it for real


Source review tells you a bug is plausible. A lab tells you it is real. I do not report critical findings on theory alone, so I stood up a self-contained Bisheng deployment on an isolated Ubuntu Server VM — backend, database, cache, and object storage — and went looking for proof.


I started with the most boring possible test: a syntactically valid, completely inert function definition. The endpoint accepted it without a session, a cookie, or an authorization header, and returned its normal validation response. That confirmed reachability and the missing authentication in one shot, with zero side effects.


From there I escalated carefully, using innocuous, self-contained proofs rather than destructive actions:

- A benign marker written to a path inside the container, then read back out-of-band, proved that submitted code genuinely executed on the server.
- A controlled callback to a listener I owned proved the backend had outbound network egress — and, critically, that the command ran inside the backend container, not on my testing host. That distinction is the difference between “interesting” and “remote code execution.”
- Reading the process tree showed my injected work appearing as a child of the application’s worker process, cleanly confirming the call chain end to end: HTTP request → handler → validator → AST execution → my code.

That sequence, reachable, executes, executes there, executes as part of the app, is what I consider a complete confirmation.


## Why it was worse than the bug alone


The lab also surfaced two deployment realities that turn a serious bug into a catastrophic one:

- The backend ran as root inside its container. The official image dropped no privileges, so code execution meant root-in-container immediately — no further escalation needed.
- Service credentials lived in the environment. Standard configuration exposed object-storage admin credentials and a database connection string to any process on the backend. A single successful execution therefore reaches well beyond the application: object storage, the database, and the internal data services the platform depends on.

Stack those together and the impact is total compromise of the platform and the data it holds — RAG-indexed documents, chat history, tool and assistant configurations, and the credentials for everything Bisheng connects to. In an enterprise deployment, that is often the crown jewels.


## Scoring it


This lands as CVSS 9.8 (Critical) — AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H. Network-reachable, low complexity, no privileges, no user interaction, with full impact to confidentiality, integrity, and availability. The classification is CWE-94: Improper Control of Generation of Code ("Code Injection").


## The fix I proposed


I recommended defense in two layers, because either alone is insufficient:


1. Require authentication on the endpoint — matching the pattern already used by every other route in the same tree, and ideally restricting it to administrators. This alone removes the pre-auth nature of the flaw.


2. Stop executing the code. This is the part that matters most. Validation does not require execution. Whether imports resolve can be answered with a static module lookup that does not import-and-run anything. Whether a function is syntactically valid is already answered by parsing it into an AST. The exec() provides no validation value that static analysis cannot — it only provides an execution primitive. Even behind authentication, it should be removed entirely, so that an administrator-account compromise does not silently include code execution as a bundled feature.


The broader lesson is the one Langflow’s incident already taught, and which this finding underlines: “validate this code” should never mean “run this code.” If a feature needs to execute untrusted input, that has to be a deliberate, sandboxed, isolated design decision — not an accident of how Python evaluates a function signature.


## Then the disclosure went sideways


Here is where the story stops being a tidy technical narrative.


On the same day I submitted my private report to the vendor, an unrelated GitHub user — handle Ro1ME, someone I have no connection to and have never communicated with — opened a public issue on the Bisheng repository describing the same vulnerability in the open. I did not coordinate with them, and I had no advance knowledge they were going to do it. By the time my private report landed, the bug was already public.


That, by itself, is just the chaos of independent discovery. It happens. Two people find the same obvious-in-hindsight pattern around the same time, and one of them chooses full disclosure. I still believe the private, coordinated route was the right call on my end, and I would make it again.


What happened next is the part I want to be pointed about.


The vendor never engaged with my private report. No acknowledgment, no questions, no coordination. Instead, the issue was patched silently — the vulnerable code was changed in the repository, and that was the end of it. As of this writing:

- No security advisory was published.
- No CVE was requested or assigned.
- No release notes flagged the change as a security fix.
- No credit was given to either reporter — not to me, and not to the person who filed publicly.

I want to be clear about why this bothers me, because it is not about credit. Credit is nice; it is not the point. The point is the operators.


## Why a silent patch is a problem, not a courtesy


When a maintainer fixes a critical vulnerability quietly — no advisory, no CVE, no security-flagged release — the fix only protects the people who happen to pull the latest code for unrelated reasons. Everyone else is left exactly where they were, with no signal that they are exposed and no reason to prioritize an upgrade.


Consider who that leaves behind:

- The enterprise running a pinned version in production, because that is what responsible change management looks like. They upgrade deliberately, on a schedule, when they have a reason. A silent patch gives them no reason. They stay vulnerable, and they do not know it.
- The team that vendored or forked the code months ago. Without a CVE or advisory, nothing in their dependency-scanning or vulnerability-management tooling will ever light up. The flaw is invisible to exactly the automated systems built to catch it.
- The downstream project that copied the same pattern — the way this very bug appears to have been inherited from Langflow. A CVE is how that knowledge propagates. Without one, the next maintainer has no breadcrumb to follow.

A CVE and an advisory are not bureaucratic trophies. They are the distribution mechanism for the knowledge that you need to act. They are how a fix in a repository becomes a fix in the world. Skipping them does not make the vulnerability less real for the thousands of deployments that never saw the commit — it just makes it silent, which from a defender’s chair is strictly worse than loud.


And in this case the bug was already public on the issue tracker. So the silent patch achieved the worst of both arrangements: attackers had a public pointer to the vulnerability, while defenders got no formal notification it had ever existed. The asymmetry ran exactly the wrong direction.


## What I would have wanted instead


None of this required heroics from the vendor. Coordinated disclosure that serves users looks like:

- Acknowledge the report. Even a one-line “received, looking into it” closes the loop and tells a reporter the channel works.
- Request a CVE when the fix ships — through the GitHub Security Advisory flow, which makes this nearly frictionless for an open-source maintainer.
- Publish an advisory that names affected versions and the fixed version, so operators can make an informed decision.
- Flag the release as containing a security fix, so the people doing diligent, scheduled upgrades know this one matters.

That is the whole ask. It is not expensive. It is the difference between a fix that protects the people who pulled main last Tuesday and a fix that protects the install base.


To the credit of the outcome: the vulnerable code is fixed in current Bisheng. If you run it, update to a current build. But “it’s fixed if you happen to be current” is a low bar for a pre-authentication, CVSS-9.8 code-execution flaw in software marketed to enterprises and Fortune 500 deployments.


## Takeaways


A few things worth carrying forward, for researchers and maintainers both:

- Patterns travel. When a vulnerability class is disclosed in one popular project, the same code — sometimes literally copied — is very likely living in adjacent projects that share lineage or design. Checking whether a known-bad pattern reappears elsewhere is some of the highest-leverage review you can do.
- AI infrastructure is conventional infrastructure. Strip away the LLM framing and this is a textbook code-injection bug behind a missing auth check. The novelty is in the deployment context and the value of what these platforms hold, not in the bug itself.
- Validation is not execution. If you find yourself reaching for exec, eval, or compile on input you did not write, stop and ask what you are actually trying to verify — there is almost always a static way to answer it.
- A fix without an advisory is half a fix. For maintainers: patching the code protects the people who pull it. A CVE and an advisory protect everyone else. The administrative half of disclosure is not optional ceremony — it is how the fix reaches the install base. If you take away one thing from this post, let it be that.
- Report privately anyway. The vendor’s response here was disappointing, but it does not change the calculus. Coordinated disclosure is still the approach that gives users the best chance, and a maintainer choosing not to meet you halfway is a reflection on them, not a reason to stop doing it right.

This research was conducted in an isolated lab environment as part of authorized security work, and disclosed to the vendor and CERT/CC under coordinated-disclosure practice. Nothing here was tested against systems I did not own or have explicit permission to assess.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
