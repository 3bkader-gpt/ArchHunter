# Your AI agent has approval. Is it still allowed to act?

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-10
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/4db619876c54](https://medium.com/p/4db619876c54)

---

## Full Article / Writeup Content

# Your AI agent has approval. Is it still allowed to act?


--


Listen


Share


Introducing Permission to Act: Operating AI Agents in the Enterprise, a new book By ClausePass27001.


At 09:12, a purchaser approves six pump seal kits for €1,440. At 09:14, the supplier record changes. At 09:15, an AI agent attempts to submit the order.


The price is unchanged. The approval is only three minutes old. Should the purchase go through?


This is the opening problem in our new book, Permission to Act: Operating AI Agents in the Enterprise. The company, Westmere Maintenance, is fictional. The purchasing decision is deliberately ordinary: a small order, a familiar supplier, someone who has already said yes.


In Westmere’s policy, the supplier change invalidates the pending request. The order must wait for review. A system that submits it anyway has allowed an earlier decision to authorize a different state of affairs.


That interval between approval and action is where the book begins. Across 40 pages, we follow what happens as the same purchase passes through people, tools, queues and services that each hold part of its history.


## What, exactly, did the person approve?


For an enterprise AI agent, permission needs to identify the specific operation it can carry out and remain valid when that operation is committed.


“Purchase approved” leaves too much unsaid. The approval in Westmere’s case refers to particular items, quantities, a supplier and its record version, a delivery site, a currency and a total. It also has an approver, an intended workload, an expiry and a way to withdraw it.


The system accepting the purchase has to enforce those conditions. If the supplier changes while work is waiting, the agent cannot decide that the change is harmless. If the final tool request names a different delivery site, it cannot reuse approval for the original one.


This is familiar territory for people operating consequential systems. In a public discussion about testing distributed systems, Hacker News commenter mrothroc wrote:


> The hard part of reliability is understanding the failure modes in the context of the business.


The hard part of reliability is understanding the failure modes in the context of the business.


For Westmere, that context includes a supplier-control process, spending limits and the person who will investigate an unexpected order. Those details determine what a useful agent is allowed to do.


They also shape the response to prompt injection. A supplier attachment might contain text claiming that a change is “already approved.” Westmere’s design requires approval through an authenticated purchasing interface; a claim inside a document cannot create it.


The UK National Cyber Security Centre’s explanation of prompt injection describes why instructions inside untrusted material can influence a model. The book follows the practical consequence: the purchasing service must enforce its authority rules even when the model produces a misleading proposal.


## A missing response can leave a real order behind


Now suppose a valid order reaches the purchasing service, but its response never reaches the agent.


The agent has a timeout. The supplier may have an order.


That uncertainty changes the next permitted action. Submitting a fresh purchase could buy the same parts twice. Reporting failure could persuade a member of staff to place a replacement order manually.


Westmere keeps the outcome unresolved while it checks the original purchase. The intended operation retains one stable identifier. Its budget reservation remains in place. Reconciliation looks for an authoritative record of what happened.


This depends on the purchasing integration. It must recognize repeated attempts for the same intent and prevent them from creating additional purchases at the point where the effect occurs. Amazon’s Builders’ Library explains the request identifiers and service behavior needed for safe retries.


In the book’s operating procedure, the agent cannot invent a new purchase while the original outcome remains unknown. If the integration cannot support an enforceable execution and reconciliation design, Westmere keeps automated submission disabled and uses the agent to prepare drafts.


That limitation belongs in the project’s scope and budget from the beginning.


## What a 98.75% success rate leaves out


One chapter examines a candidate that produces the expected result in 395 of 400 trials.


Those are constructed teaching results: 80 cases, each run five times. They are not production measurements or a benchmark of a commercial product.


The headline looks encouraging. The failed trials make the release decision much clearer.


Two valid requests were unnecessarily sent back for clarification. One trial allowed an expired approval. Two attempted a new purchase while the original outcome was still unknown.


Under Westmere’s policy, those last three failures prevent the candidate from receiving wider purchasing authority. Combining them with routine clarification errors in a single percentage hides the distinction the deployment decision depends on.


The book shows how to inspect the attempted action, the approval checks and the resulting system state. Anthropic’s guidance on agent evaluations makes a related distinction between the transcript of a run and its actual outcome in the environment.


For the team reviewing a pilot, a useful result identifies which conditions failed, how the failure occurred and which version of the complete service was tested.


## Someone still has to handle the exceptions


The economics chapter follows the work left with people.


In a separate hypothetical projection, Westmere processes 2,000 requests a month. Its existing process costs €18,000 in human work. With the proposed agent service, ordinary requests require four minutes of human attention; exceptions require sixteen.


At a 20% exception share, the projected monthly operating cost is €14,140, including human processing, model and tool usage, the platform, maintenance and support.


Raise the exception share to 45%, with the other assumptions unchanged, and that cost reaches €18,640. The proposed service becomes more expensive than the existing process.


These figures are teaching inputs. Their purpose is to expose the measurements a real pilot needs: how much work qualifies, how often it becomes an exception, and how long people spend resolving the whole request.


The book also distinguishes released staff capacity from cash savings. Time becomes financially useful when the organization can apply it to something: absorbing growth, clearing a backlog or avoiding paid overtime. Faster processing alone does not reduce payroll.


And a monthly average cannot staff a busy afternoon. Reviewers need enough capacity, the right authority and a usable fallback when automated dispatch is suspended.


## Stopping the agent leaves work to resolve


A stop control prevents new work from crossing a defined boundary. Orders already dispatched still need to be accounted for.


Westmere’s incident chapter returns to a purchase that the external service has accepted but the local system still records as unknown. It also examines credentials that may remain usable after the agent’s session ends.


The response has to reach those remaining effects and permissions. Someone must establish which orders exist, reconcile reserved spending, prevent duplicates and verify that the relevant access is disabled or expired.


Restart requires its own decision. The incident and purchasing owners need evidence about the repaired service, the outstanding work, current authority and available human coverage before dispatch resumes.


That is why the book follows a purchase beyond the moment a tool reports success.


## A practical reference for the team running AI services


We wrote Permission to Act for the people accountable for an AI service and the people building and operating it.


Its nine chapters connect the first delegation to the next decision about authority. Four diagrams explain the operating design, and the appendix provides four procedures to return to during implementation: first dispatch, reconciliation of an uncertain order, stopping new dispatch and resuming it.


A CTO can use the case to examine what a proposed integration must enforce. A security lead can trace approval and access through to the attempted action. An operations lead can examine the review queue and recovery work. An engineer can turn the failure cases into checks against the actual service.


The design is a proposal to adapt and test against your own systems. Its example limits and policies belong to Westmere.


An order that waits for fresh approval can be a successful result. Permission to Act explains the decisions and evidence behind that result, and what an enterprise needs before allowing its agents to do more.


Read Permission to Act: Operating AI Agents in the Enterprise.https://www.linkedin.com/feed/update/urn:li:activity:7503821973299310592


Published by ClausePass27001.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
