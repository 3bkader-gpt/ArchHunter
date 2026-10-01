# Your AI Agent Can Take Action. Who Gave It Permission?

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-12
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/98f325f5edeb](https://medium.com/p/98f325f5edeb)

---

## Full Article / Writeup Content

# Your AI Agent Can Take Action. Who Gave It Permission?


--


Listen


Share


What developers and leaders need to know about AI agent security, permissions, and guardrails across six major enterprise platforms.


This article was developed with AI assistance for drafting, editing, and source review. The refund scenario is illustrative.


Imagine a customer asks for a refund.


An AI agent finds the order, checks the policy, calculates the amount, and sends the money back. The whole process takes seconds. For the customer, it feels effortless.


Now change one detail.


The customer’s message asks for the refund to go to a different bank account, even though company policy requires the original payment method. The agent follows the request. Its final response sounds reassuring and reports the correct amount, but the transaction violates the payment rule.


The problem happened before anyone read the answer.


This is what makes enterprise AI agents such an interesting — and demanding — design challenge. Once software can interpret a request and act on it, we have to decide how much authority it should have, where that authority ends, and what happens when it makes a mistake.


My recommendation is straightforward: let the agent propose an action, then make it earn permission to execute.


That principle connects much of the work happening across the major enterprise AI platforms. Their approaches differ, and some features have significant limitations. But together they offer useful lessons for anyone building an agent platform today.


The platform descriptions below reflect public documentation, not testing of a particular customer deployment. The design recommendations are my own; legal applicability depends on the use case, jurisdiction, and organization’s role.


## A good answer is only part of the job


A chatbot that gives a poor answer can mislead someone. An agent with access to business systems can also change a record, share a document, send a message, or grant access.


That creates a second question after “Is this answer correct?”


“Is this action authorized?”


Those questions can have different answers. An agent might correctly identify a confidential document and still have no right to send it to the person asking for it. It might calculate a refund correctly and still exceed its spending authority.


External content makes this harder. An email, webpage, or tool result can contain instructions intended to redirect the agent. This is usually called prompt injection. Anthropic’s discussion of trustworthy agents explains why protection needs to exist at several levels and why even combined safeguards cannot guarantee success.


The practical response is to limit what a mistake can reach. If the agent cannot access unrelated accounts or send data to arbitrary destinations, a reasoning failure has fewer opportunities to become a damaging action.


## What “compliance” actually means here


Compliance can become a catch-all word in AI discussions. It helps to make it concrete.


For a particular agent, we need to know which obligations apply, what controls support those obligations, and what evidence shows the controls are working.


Security is part of that picture. So are privacy, fair treatment, human oversight, contracts, and accountability.


A vendor’s certification can provide useful assurance about the service within its assessed scope. Your organization still has to evaluate how it uses that service. A meeting-summary assistant and an agent influencing hiring decisions deserve different assessments, even when they use the same model.


Frameworks can give this work structure. NIST’s Generative AI Profile helps organize risk management. ISO/IEC 42001 addresses an organization’s AI management system. OWASP’s agentic guidance helps teams think through threats such as tool misuse, excessive privileges, poisoned memory, and cascading failures.


The useful chain is simple:


An obligation leads to a control. The control needs a test. The test needs evidence. Someone owns the result.


## How the major platforms are approaching it


There is no single control that every platform implements in the same way. The differences become clearer when we look at where each ecosystem places its controls.


## Salesforce: follow the action into the CRM


Salesforce connects Agentforce with CRM permissions and Trust Layer capabilities, including grounding, prompt defenses, and audit information.


The important detail is the action underneath the conversation. If an agent invokes a Flow or Apex action, its execution context and downstream effects matter. A safe-sounding instruction cannot repair an overly powerful business action.


There is also a specific caveat in Salesforce’s Agentforce trust documentation: Einstein Trust Layer pattern-based and field-based LLM data masking is disabled for agents. This limitation should not be generalized to every Salesforce data-masking feature. External-model zero retention also does not mean the application keeps no audit data.


The lesson is to check the exact feature and action you are using. Broad platform descriptions can hide exceptions that matter to your deployment.


## Google Cloud: create a controlled route to tools


Google’s approach includes agent identity, a registry, a gateway, and Model Armor for content screening. The gateway provides a place to govern agent communications, while content screening addresses a different part of the problem.


Google’s release notes show these capabilities evolving through separate releases. Their availability and configuration requirements need to be checked individually.


Model Armor also documents limits, including single-turn inspection and restrictions on encoded content and supported media. That matters when an agent works across a long conversation or processes attachments.


The lesson is to combine content checks with permissions and controlled execution. A request that was skipped, unsupported, or unsuccessfully scanned needs an explicit status and handling rule. For consequential actions, a scan or policy-service error should stop execution or trigger review.


## Microsoft: connect agent identity with information governance


Microsoft brings together Copilot Studio, Entra identities, and Purview capabilities such as classification, retention, auditing, and investigation.


This can be useful when an organization’s information already lives inside Microsoft systems. But the details depend on how the agent is deployed.


The Copilot Studio identity guidance currently limits the described runtime scope and Conditional Access enforcement to Microsoft Teams; other channels follow existing connector authentication flows. Purview’s Copilot Studio documentation also ties some protections to particular knowledge sources and channels.


The lesson is to test the combination you will actually use: the agent, its connection, the source data, the policy, and the channel. Seeing a policy enabled in an administration screen is only the beginning.


## AWS: separate policy decisions from content detection


AWS offers an especially useful distinction through AgentCore Policy and Bedrock Guardrails.


AgentCore Policy evaluates tool access through Gateway, outside the agent’s own reasoning. Content guardrails can supply additional signals.


Another feature, Automated Reasoning checks, checks consistency against modeled policies. It operates in detect mode: the application must decide what to do with its findings.


The lesson is to connect every detection to an appropriate action. A warning in a log will not stop a transaction. And blocking a response after a tool has executed will not undo the tool’s side effects.


## Anthropic and Claude: permission settings have real consequences


Claude’s Agent SDK offers tool permissions and hooks. These are useful controls, but their evaluation order matters.


The permission documentation explains that auto-approved tool calls can bypass the canUseTool approval callback. The documentation recommends a PreToolUse hook for checks that must run before other permission decisions. Protect that hook and its configuration from agent modification.


That is an easy detail to miss. A developer can write a careful approval function and assume it sees every action when the configured execution path says otherwise.


The lesson is to test effective permissions. Keep the agent from changing its own controls, limit its credentials, and check what any delegated agent inherits.


## OpenAI: choose the product surface and connection model carefully


OpenAI’s workspace agents and ChatGPT agent have different controls and evidence boundaries.


The Workspace Agents documentation warns that publishing an agent with a creator’s personal connection can let other users access data or act through that connection as the creator.


The separate ChatGPT agent documentation describes a logging limit: conversations appear in Compliance API logs, while individual agent actions do not.


The lesson is to establish what evidence you need before choosing a deployment path. If your business requires a record of every consequential action, prove that your chosen application can provide it.


## Three shifts worth watching


The first is explicit agent identity. Enterprises need to distinguish the person requesting work from the software carrying it out. They also need a way to limit and revoke that software’s authority.


The second is control over sequences of actions. A series of small transactions can exceed a total limit. A valid action may require an earlier approval. Those rules need trusted workflow state, rather than the agent’s recollection of what happened.


The third is closer attention to evidence and data custody. Organizations want to investigate misuse while controlling where sensitive monitoring data lives. Anthropic’s September 2026 Enterprise Frontier Safeguards announcement points in that direction, although its phased rollout was still ahead at this article’s research cutoff.


Agent-specific governance is also becoming more explicit. Singapore’s IMDA framework for agentic AI emphasizes human accountability. NIST’s AI Agent Standards Initiative addresses emerging interoperability and security needs.


These developments are worth following. They should inform a design that can adapt as standards and products mature.


## What I would build first


I would start with one useful workflow and five questions.


Who owns this agent?


Give it a named business owner, a defined purpose, and a clear way to suspend it. Include scheduled work and delegated agents in that inventory.


What can it read and change?


Keep access narrow. Apply permissions before data enters the model and again when an action reaches the destination system. Give the agent a specific business tool when the job does not require unrestricted code execution or network access.


Which actions need review?


Show the reviewer the actual proposed change, its recipient or target, and its consequences. Tie approval to the exact actor, action, target, parameters, policy version, and expiry. Recheck authorization immediately before execution. If the amount, destination, or scope changes, obtain a new decision.


How do we know what happened?


Record the policy decision, approval reference, action, and confirmed outcome. A tool call is an attempt. Acceptance may only mean the request was queued, so confirm the final status in the authoritative system. Link that outcome to the policy version and approval, and protect the evidence from agent modification. Keep sensitive content out of routine logs where possible.


How do we stop and recover?


Test suspension, credential revocation, and unfinished work. Decide how to handle an uncertain result before allowing retries. Some effects can be reversed; others, such as a disclosed document, require containment.


You may already have most of these capabilities in your identity, workflow, API, and monitoring systems. Reuse them before building a new platform.


## Back to the refund


Suppose the agent can issue refunds up to $100 automatically. Larger amounts require approval, and this agent may refund only to the original payment method. These are example business rules, not regulatory thresholds.


A customer requests $180.


The agent prepares the proposal. Trusted application logic checks the order, previous refunds, amount, and payment destination. A reviewer approves the exact transaction.


Then the agent tries to change the recipient.


The earlier approval no longer applies. The execution layer rejects the change.


Now imagine the refund succeeds but the response times out. The application checks the payment system’s authoritative transaction status and reuses the same idempotency key for any permitted retry. If the outcome remains unknown, it pauses for reconciliation instead of creating another refund.


Neither protection depends on the agent remembering to behave. Both are part of how the system executes work.


## Test the consequences


A convincing demonstration should include things going wrong.


Try a request from the wrong user. Put a malicious instruction in a retrieved document. Change an action after approval. Revoke access during a task. Simulate a timeout after a successful transaction.


Then inspect the business system.


Was data disclosed? Did a record change? Was money sent twice? Did the old approval still work?


Measure legitimate work too. A control that blocks every request may prevent harm, but it also prevents the service from doing its job. Track successful tasks, false blocks, unauthorized effects, review quality, and recovery time together.


Passing a finite set of tests is evidence of performance under those conditions. Keep gathering evidence as the workflow changes.


## Let autonomy grow with the evidence


Begin with reading or drafting. Add narrowly defined actions. Introduce approval for consequential changes. Expand autonomy gradually as you learn how the complete system behaves.


Legal requirements need the same attention to detail. Classify the use case, identify the relevant jurisdiction and actor role, and keep the assessment current. For example, the European Commission’s July 2026 AI Omnibus announcement explains an enacted change to parts of the high-risk timetable. An older checklist can therefore carry outdated assumptions.


The most valuable enterprise agent is one whose authority you can explain and whose actions you can verify.


When someone asks why a transaction happened, the answer should be available: who requested it, which rule allowed it, whether review was required, and what the system actually did.


That is a much stronger foundation for trust than a reassuring final message.


Which action would you never let an AI agent take without fresh approval—and why? Share a concrete example in the responses.


## Sources and scope notes

- Anthropic. Trustworthy agents in practice. April 9, 2026. Layered agent safeguards and residual risk.
- OWASP. Top 10 for Agentic Applications 2026. December 9, 2025. Agent threat categories.
- ISO. ISO/IEC 42001:2023. Public management-system scope.
- ISO. ISO/IEC 23894:2023. Public risk-management scope.
- NIST. Generative Artificial Intelligence Profile, AI 600–1. July 26, 2024. Voluntary risk framework companion.
- Google Cloud. Agent Gateway overview. Controlled connectivity.
- Microsoft. Agent identities and authentication. Updated August 27, 2026. Identity/channel limitations.
- AWS. AgentCore Policy general availability. March 3, 2026.
- AWS. AgentCore Policy core concepts. Policy/session semantics.
- OWASP. Agent Control Standard. September 1, 2026. Runtime-control guidance.
- Anthropic. Developing Enterprise Frontier Safeguards with our customers. September 1, 2026. Announced staged rollout.
- IMDA. Model AI Governance Framework for Agentic AI launch. January 22, 2026.
- NIST. AI Agent Standards Initiative. February 2026 initiative; current program page.
- NIST. Identity and authority for software agents concept paper. February 2026.
- AI Agent Index research team. The 2025 AI Agent Index. FAccT 2026 paper. Public safety-disclosure study.
- European Commission. Regulatory framework for AI. Current overview.
- European Commission. AI Omnibus enters into force. July 27, 2026.
- European Union. Regulation (EU) 2026/1744. July 8, 2026 act, published July 24. Amending regulation; operative text checked against EUR-Lex.
- European Commission. AI Act implementation timeline. Current transitions.
- European Union. GDPR, Regulation (EU) 2016/679. Articles 5, 6, 9, 22, 25, 28, 32, 35 and Chapter V.
- EDPB. Automated decision-making and profiling guidance. Endorsed May 25, 2018.
- EDPB/EDPS. Joint Opinion 2/2026 on Digital Omnibus. February 2026. Proposal analysis.
- FTC. Artificial intelligence enforcement and policy portal. Current enforcement examples.
- White House. Federal agency AI use and procurement policies. April 7, 2025 announcement.
- White House. National AI legislative framework. March 20, 2026. Legislative recommendations.
- Colorado General Assembly. SB26–189. Signed May 14, 2026. Summary and legislative history.
- CPPA. CCPA regulatory updates. Adopted rules.
- CPPA. 2026 statute and regulation compilation. Including section 7200.
- Texas Legislature. HB149 enrolled bill summary. Effective January 1, 2026.
- California Governor. AI safeguards signing announcement. September 9, 2026.
- Salesforce. Trust and Agentforce. Permissions, masking exception, audit storage.
- Salesforce Developers. Summer ’26 developer guide. June 2026. GA/Beta/Preview distinctions.
- Google Cloud. Gemini Enterprise Agent Platform release notes. Entries through September 9, 2026 used.
- Google Cloud. Model Armor overview. Updated September 10, 2026. Filters, enforcement, limitations.
- Microsoft. Migrate agents to Entra Agent ID, preview. Migration status.
- Microsoft. Copilot Studio security and governance. Updated August 7, 2026.
- Microsoft. Purview for Copilot Studio. May 1, 2026. Source/channel-dependent capabilities.
- AWS. Guardrails in AgentCore policies. Scoring, enforcement and output suppression.
- AWS. Automated Reasoning checks. Detect mode and modeled-policy limits.
- AWS. Contextual grounding checks. Supported use cases and streaming caveats.
- Anthropic. Claude Agent SDK permissions. Permission order and callback coverage.
- Anthropic. Self-hosted sandbox security model. Execution trust boundaries.
- OpenAI. Workspace Agents for Enterprise and Business. Access and personal-connection warning.
- OpenAI. ChatGPT agent. Product-specific Compliance API scope.
- OpenAI. Enterprise privacy. Updated January 8, 2026.
- NVIDIA NeMo Guardrails. Security policy. Required enclosing security layer; living development-branch source.
- Open Policy Agent. Documentation overview. General-purpose policy engine.
- Model Context Protocol. Security best practices. Versioned July 28, 2026 documentation.

## About the author


Ashutosh Rana is an enterprise architect focused on regulated AI, multi-agent governance, and enterprise CRM.


Building or evaluating an AI agent? Use this article’s five questions as a review checklist: ownership, access, approval, evidence, and recovery.


Follow Ashutosh Rana on Medium for more writing on enterprise AI and governance.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
