# AI Security Assessments Need to Go Beyond the Model

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-09
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/f91d9993c388](https://medium.com/p/f91d9993c388)

---

## Full Article / Writeup Content

# AI Security Assessments Need to Go Beyond the Model


--


Listen


Share


## Why securing LLM, RAG and agentic AI requires looking at the entire system


One pattern I keep seeing in AI security discussions is that we spend a lot of time talking about the model.


Can it resist prompt injection? Will it reveal sensitive information? Does it refuse harmful requests?


Those questions matter. But once AI moves into a real enterprise environment, the model is only one component of a much larger system.


A production AI application may include an LLM, APIs, a vector database, internal documents, identity systems, RAG pipelines, memory, external tools, third-party services and increasingly, autonomous agents.


And that changes the security problem.


A reasonably safe model can still sit inside a very unsafe architecture.


That is why I think AI security assessments need to move away from being model-centric and become much more system-centric.


## The real attack surface is larger than the LLM


Consider a typical enterprise RAG application.


A user asks a question. The system authenticates the user, retrieves documents from a knowledge source, creates context, sends that context to a model, receives a response and may then pass that response into another business process.


There are security decisions happening at almost every step.


Who is the user?


Which documents are they allowed to retrieve?


Can the retrieved content contain malicious instructions?


Can information from one user or session leak into another?


What happens if the generated output is passed directly into another system?


None of these are purely “model security” questions.


They are architecture, identity, authorization, data protection and application security questions.


That distinction becomes even more important as AI applications become more connected.


## Start by understanding what AI systems actually exist


Before evaluating controls, I think the first challenge is simply visibility.


Many organizations are adopting AI faster than their governance processes can keep up.


You may have an approved enterprise chatbot, a few internal RAG systems, development teams experimenting with external models, employees using SaaS AI tools and business units building their own automation.


If nobody has a reliable inventory, security teams are already starting from behind.


An AI system inventory should answer basic questions such as what the system does, which model or provider it uses, where it is hosted, what data it can access, who owns it and how critical the use case is to the business.


It sounds simple.


In practice, it is often one of the most valuable parts of the assessment.


## RAG security is largely an authorization problem


RAG has made enterprise AI significantly more useful because it allows models to work with internal knowledge.


It also creates a new security boundary.


Imagine an employee asks a completely legitimate question, but the retrieval layer returns a confidential document that the employee should never have been able to access.


The model may behave perfectly.


The security failure already happened before the model generated a single token.


This is why retrieval authorization deserves much more attention than it often receives.


Security teams need to understand whether document permissions are respected during retrieval, whether vector indexes are properly isolated, whether data sources are classified and whether the system can accidentally expose information across users, departments or tenants.


Indirect prompt injection makes this even more complicated.


A malicious instruction may not come from the user at all. It may be hidden inside a retrieved document, webpage or other external content.


Once that content becomes part of the model context, the trust boundary has shifted again.


## Agentic AI changes the risk model even further


The jump from a chatbot to an AI agent is much bigger than it first appears.


A chatbot mainly produces information.


An agent may be able to act.


It might query a database, call an API, send an email, create a ticket, update a business record or trigger another workflow.


Agent security therefore starts to look a lot like privileged access management.


The agent needs an identity. Its permissions need to be scoped. Tool access needs boundaries. Sensitive actions may require human approval. Logs need to show not only what the model said, but what it attempted to do.


And the same principle we already apply elsewhere in security still holds:


An AI agent should not receive more privilege than it needs to complete its task.


## Prompt injection matters, but it should not dominate the entire conversation


Prompt injection is important.


It deserves testing.


But I think there is a risk of treating prompt injection as if it were the whole AI security problem.


It is not.


A mature assessment also has to look at identity, API security, secrets, data exposure, vendor dependencies, output handling, monitoring, incident response and lifecycle governance.


The objective should not be to build a magical filter that prevents every bad prompt.


That is probably unrealistic.


A stronger objective is to design the surrounding system so that unexpected model behavior cannot easily become a serious business or security incident.


That is a more familiar security principle: assume individual controls can fail, and design the system so that one failure does not become catastrophic.


## Testing also needs to become repeatable


AI security testing is still surprisingly ad hoc in many environments.


Someone tries a few jailbreak prompts. Another person checks for sensitive information. A developer tests whether a model refuses something obviously malicious.


That may find interesting issues, but it is difficult to compare results over time.


AI systems change frequently.


Models change. Prompts change. Retrieval sources change. Agent permissions change. New tools get connected.


A useful testing process therefore needs repeatable scenarios.


For a RAG system, that might include testing unauthorized retrieval, indirect prompt injection, poisoned documents, session isolation and source traceability.


For an AI agent, it might include excessive tool permissions, unsafe tool selection, privilege escalation paths, approval bypasses and whether actions are properly logged.


The objective is not simply to “hack the AI.”


It is to understand whether the system still behaves safely when something unexpected happens.


## Pass or fail is usually too simplistic


Another thing I find useful is thinking in terms of maturity rather than only compliance.


A control can technically exist and still be weak.


An organization may have logging, but not log agent actions.


It may have an AI inventory, but update it only once a year.


It may have incident response documentation, but no scenario for an AI agent performing an unauthorized action.


In those situations, marking the control as simply “pass” hides useful information.


A maturity score makes it easier to discuss where the organization is today, what needs improvement and which gaps matter most.


It also translates technical findings into something leadership can understand.


## What a system-level AI assessment should look at


When I step back and look at the whole problem, the assessment naturally expands beyond the model.


It needs to cover governance and ownership, AI system inventory, architecture and trust boundaries, data protection, identity and secrets, prompts and context, RAG and memory, models and supply chain, agent permissions, APIs and gateways, downstream outputs, monitoring, testing, incident response and third-party risk.


Different organizations will organize those areas differently.


That is fine.


The important point is that AI security should follow the entire path from user → application → data → model → tools → business action.


If we only assess the model in the middle, we are missing most of the system.


## A practical resource


While working through this problem, I ended up turning the assessment approach into a reusable toolkit for security consultants, GRC teams and organizations evaluating LLM, RAG and agentic AI systems.


The AI Security Assessment Toolkit 2026 includes 120 security controls across 15 domains, 60 non-destructive security test cases, maturity scoring, evidence tracking, RAG and agent inventories, risk and remediation tracking, an executive dashboard and client-ready reporting templates.


It is available here:


AI Security Assessment Toolkit 2026 https://www.etsy.com/listing/4571739668/ai-security-assessment-toolkit-2026-120


The toolkit is intended as a practical assessment resource, not as a certification or substitute for organization-specific risk, legal or compliance review.


## One question I would be interested to hear from other practitioners


As AI systems become more agentic and gain access to real business tools:


What do you think organizations are most likely to underestimate — data access, agent permissions, monitoring, or something else entirely?

---
*Archived in LLM Hacking Vault from verified community intelligence.*
