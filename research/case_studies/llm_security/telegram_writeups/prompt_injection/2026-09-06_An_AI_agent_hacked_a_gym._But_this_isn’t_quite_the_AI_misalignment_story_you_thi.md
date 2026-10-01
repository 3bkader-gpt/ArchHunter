# An AI agent hacked a gym. But this isn’t quite the AI misalignment story you think it is.

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-06
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/ba688288b5bb](https://medium.com/p/ba688288b5bb)

---

## Full Article / Writeup Content

# An AI agent hacked a gym. But this isn’t quite the AI misalignment story you think it is.


--


Listen


Share


A few weeks ago, a recent Australian case has been described as perhaps the country’s first known example of a personal AI agent autonomously hacking a live system.It’s quite a captivating story... especially when you dive deeper into the details!


While there have been other very high profile AI agent cyber breaches in the zeitgeist of recent. (which, we most definitely will be weighing in on shortly), this one struck me, as I found the attack modalities and the human factors element as well quite fascinating.


So… what happened, you ask?


Hold your horses, I’ll tell you. That’s why I’m here! ☺️


It all starts out pretty mundane. Back in August 2026 it was reported by ABC Australia that a user asked an OpenClaw AI agent (integrated with Claude Opus 4.6) whether it could move him up a gym-class waiting list and in pursuing that objective, the agent reportedly discovered a weakness in the gym’s booking API, cancelled another customer’s reservation and moved the user further up the queue. It later discovered that it couldn’t undo what it had done.


At first glance, this sounds like another classic example of the AI alignment problem: an autonomous system behaving in a way its human operator did not intend.


Well… there’s some nuance. Plenty nuance.


I’ll explain.


Is this another AI alignment problem? ..Yes.


Did the AI agent do what it wasn’t told to do? ‘Go rogue’? ..Well, ..Yes & No.


Sort of.


Was this dangerous? Yes! — Well, it was a somewhat controlled experiment, but applicably a potentially very dangerous situation.


I’ll Explain.


Firstly, and most importantly, the agent didn’t spontaneously decide to attack the gym. A specific gym in Australia highly qualifies as a high value or interesting target. No offense to the company running the gym, ...or to Australia.


Nor is there evidence that it developed some competing objective, deliberately deceived its user, sought power or otherwise behaved contrary to human interests in the stronger sense usually associated with AI misalignment.


That being said, while not your typical AI misalignment case, there are elements of misalignment here.


So, diving deeper,


A highly capable agent was given an ambiguous objective, access to tools and a vulnerable external system. It then found a technically successful route to achieving that objective.


Seen as a systems / human factors problem, there were at least six failure modes. (P.S: This is an ‘armchair opinion’, as I have not actively assessed these systems hands-on myself; however, I have plenty years of experience doing these sorts of analyses).


## 1. Intent ambiguity


“Can you move me to the top?” is not necessarily the same instruction as “take whatever actions are required to move me to the top”.The system failed to distinguish a question about possibilities from authority to execute. You can frame this as a human factors issue as well. It’s quite clear to see how not giving a specific enough set of instructions can lead to unexpected interpretations, and hence unforeseen sets of follow-on actions by an AI agent.


## 2. Planning and action were conflated


An agent should be able to investigate an option without automatically being permitted to perform it.Discovering that another person’s reservation could be cancelled should not imply permission to cancel it. There is also a ‘moral’ issue here. An AI agent does not understand right and wrong, ethics and morality the ways you and I do. It may appear to, but remember, it’s just lines of code (I broke that part down over simplistically, but you get the point!) Anthropic have experimented with including a form of a constitution for their AI agents to follow in system prompts. In fact, this isn’t unique to Anthropic. Other major AI foundation model vendors also include forms of constraints and guidelines within their system prompts to ensure forms of alignment.


It’s smart. It works. Until it doesn’t.


You don’t know what you don’t know, I guess. Or framing differently, and a bit more technically — there will always be edge cases of possibility in the event space beyond the history of what has previously occurred or has been observable even in simulation to anticipate certain emerging behaviours of a AI agent, some of which may be malicious or misaligned with human intended goals.


## 3. There was no consequential-action gate


The proposed action affected a third party and altered a live production system.That is exactly the kind of boundary at which an agent should stop and seek explicit approval, or refuse the action altogether where authorisation does not exist. I need not explicate any further on this one. It’s pretty obvious. Don’t do bad stuff just because it may be a probabilistically viable means to achieving the (hopefully) good or noble goal!


## 4. The agent had excessive effective authority


We increasingly give AI systems the ability not just to recommend actions, but to execute them through browsers, APIs, code and other toolsl like MCP or A2A protocols.Capability without appropriately constrained authority becomes a control problem.


This is where I always mention in advising on these sorts of systemic builds, “A little bit of human friction deliberately designed into the system isn’t actually a bad thing.”. A break point deliberately designed into a system and a human-in-the-loop to approve certain actions, goes a long way. I guess this applies less in this case though, given the setup, seeing as the user was deliberately trying to find vulnerabilities.


## 5. The external system itself had inadequate security controls


This point is easy to overlook because AI is the novel part of the story.The AI didn’t create the vulnerability.If one authenticated customer could manipulate another customer’s reservation, the underlying system already had a serious authorisation weakness. The agent simply discovered it.And this may be one of the most consequential implications of increasingly capable agents: vulnerabilities that were once protected partly by obscurity, technical complexity or the effort required to find them may no longer enjoy that protection. I mean, we’ve seen plenty of this reported in the media already over the last few weeks in 2026!


## 6. The action was not safely reversible


Perhaps most strikingly, the agent performed the action before establishing whether it could undo it.


It cancelled another person’s booking and only afterwards discovered that it could not restore it when he asked it to. Don’t worry, he alerted the company via a responsible disclosure email.


For autonomous systems operating in the real world, reversibility should be treated as a control property, not an afterthought.


What interests me most about this case is that the agent was, in one respect, extremely successful.


Viewed purely as an adversarial test, it discovered a genuine weakness, demonstrated exploitability and identified a real-world consequence.The problem is that it conducted that test against a live system, without authorisation, using an innocent third party as the proof of concept.


And that points towards a broader shift in cybersecurity.Historically, organisations might implicitly ask:

- Could a technically capable attacker discover this vulnerability?

Increasingly, the question may need to become:

- Could a capable AI agent discover and exploit this vulnerability while pursuing an otherwise ordinary user’s objective?

Those are very different threat models. And the human (prompter) has a part to play in this as well!


The same distinction matters when looking at broader Responsible AI concepts. For a conventional chatbot, misunderstanding the user often produces a bad answer.


For an agent, misunderstanding the user can produce a state change in the world while interacting with real systems and potentially adversarially impacting real persons lives.


The risk chain becomes:Intent → prompt clarity → reasoning → planning → tool use → external system → consequence


Every transition in that chain is a potential control point. So I don’t think this case demonstrates that AI suddenly developed malicious intent.


It demonstrates something more immediate:


High capability + agency + ambiguous objectives + excessive permissions + insecure external systems can already produce unintended real-world harm without anybody explicitly intending that harm.


This is overly simplified for broader understanding. Especially the reasoning → planning → tool use → external system part. There are many known cases, configurations and/or operating modes where that key middle layer is shown to fail at a dramatically higher probability, simply by introducing complex multi-agent system configurations, or ‘long token usage’ type problems, etc. Myriad possibilities here.


That being said, this is not the technology of tomorrow. This is TODAY’s AI Capability! Oh, and it’s the worst it’s ever going to be today!


(As I draft this, GPT 6 Astra has been launched by OpenAI to much fanfare, claiming AGI capabilities.


AGI. Not sure I believe that. Degrees of escalation on how much more performant than the models we were familiar with 2 weeks ago, but I digress, testing and story for another day).


One of the most poignant quotes I found directly from the “user” himself — Andrew Bird, on his own blog post on the matter, deleted, but still available on the web archive, is, “..if you give an AI agent permission to go do the thing, it will often discover paths you did not explicitly ask it to look for.”


The systems problem is already here.


We don’t need to wait for some hypothetical future “rogue AI” for agent assurance to matter.


Happy AI-ing, people!


P.E II

---
*Archived in LLM Hacking Vault from verified community intelligence.*
