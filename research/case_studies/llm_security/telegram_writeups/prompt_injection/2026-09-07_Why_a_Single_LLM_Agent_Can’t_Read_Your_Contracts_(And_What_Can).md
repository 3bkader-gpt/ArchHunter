# Why a Single LLM Agent Can’t Read Your Contracts (And What Can)

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-07
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/1bd8e11f325d](https://medium.com/p/1bd8e11f325d)

---

## Full Article / Writeup Content

# Why a Single LLM Agent Can’t Read Your Contracts (And What Can)


--


Listen


Share


Ask most teams how they’re using LLMs for contract review, and you’ll hear some version of the same architecture: hand the whole document to one capable model, ask it to extract clauses, flag risk, and summarize obligations, and hope it holds all of that in its head at once. In an agentic CLM architecture I designed for a Fortune 10 pharmaceutical distribution enterprise — integrating agentic reasoning with their enterprise Contract Lifecycle Management (CLM) system on Azure, and still being built out — that approach hit a ceiling fast, and not because the underlying model wasn’t good enough. It’s a structural problem: asking one generalist agent to simultaneously be a clauseextraction expert, a compliance analyst, a risk scorer, and a summarizer means something gives, and what gives first is precision, consistency, and the ability to explain why it reached a conclusion. Here’s the architecture designed to replace it, what the interim numbers look like, and the parts of the redesign that had nothing to do with model architecture at all.


## The single-agent ceiling


Enterprise contracting is a rough environment for a single generalist LLM call. Dense, ambiguous language; jurisdiction-specific obligations; and consequences — regulatory exposure, financial penalty, audit failure — where “good enough” accuracy isn’t good enough. Recent empirical work on LLM-based contract analysis backs this up with something specific: inter-run inconsistency and sharp accuracy degradation on complex agreement types, which is why legal-specific evaluation increasingly weights false negatives by downstream severity instead of treating every misclassification as equally costly (Suplicy Barbosa et al., 2026). There’s a name for the failure mode that matters most here — trajectory collapse, a term Google researchers coined in recent work on agentic legal discovery (Sinha et al., 2026): an early misclassification propagates silently through a multi-step pipeline until it surfaces embedded in hundreds of downstream decisions. A single agent has no natural checkpoint where that gets caught.


## The architecture: coordinator + specialists, not one model doing everything


The architecture designed to replace the single-agent approach decomposes the problem the way you’d staff a review team, not the way you’d scale a model:


● A coordinating agent layer that routes each contract’s sub-tasks — extraction, classification, riskscoring, summarization — to specialized agents, and decides which specialists a given document even needs.


● Specialized agents, each scoped to one job, so a clause-extraction agent isn’t also trying to reason about regulatory risk in the same pass.


● A source-linked audit trail, written for every agent decision, so any flagged clause or classification traces back to its source text and the agent’s rationale.


● Deterministic escalation rules, evaluated independently of model confidence, that decide which outputs must go to a human compliance reviewer before anything gets written back to the system of record. Simplified, the flow looks like this:


The important design choice isn’t in any one function — it’s that escalation_rules.requires_review() is a fixed rule set tied to risk category, not a threshold on the model’s own confidence score. More on why below.


## Why deterministic escalation beats confidence-based routing


Most agentic systems treat human review as a fallback for low-confidence outputs. This one treats it as a first-class design element instead: certain clause categories or risk classifications always route to a human compliance reviewer, regardless of what the model reports about its own confidence. That’s a deliberate rejection of confidence-gating, and it matters because model confidence and correctness aren’t the same thing — a model can be fluently, confidently wrong about a legal classification (call it the “fluency trap”). Similar thinking shows up in recent work on agentic legal discovery, which intercepts error propagation at defined pipeline stages structurally rather than waiting for the model to flag its own uncertainty (Sinha et al., 2026). Regulatory risk criteria, not statistical ones, decide what gets escalated.


## The part nobody budgets for: legacy system integration


If you’re picturing most of the engineering effort going into the agent orchestration, that hasn’t been the case so far. A significant share of the effort to date has gone into integrating with the existing CLM platform as the system of record — making sure every agent output was traceable back to source documents and existing contract-management processes rather than floating as a disconnected AI layer. This is worth saying plainly because it’s underrepresented in the orchestration-and-benchmark-heavy literature: in regulated enterprise settings, integration effort can exceed the reasoning-architecture effort itself. If you’re scoping a similar project, budget accordingly — the interesting agent design is not where the schedule risk lives.


## Measuring the right things


Standard NLP or agent-benchmark accuracy metrics turned out to be the wrong yardstick. Evaluation instead centered on:


● False-negative rate on high-risk clause categories — not aggregate accuracy, which can look fine while missing exactly the errors that cost the most.


● Traceability completeness — the share of agent decisions with a full, source-linked audit trail available for reviewer inspection.


● Reviewer trust and adoption — whether compliance reviewers actually treated agent output as a usable starting point, not just whether the model scored well on paper.


## What changed


Measured against an internal 120-contract evaluation corpus (NDA, MSA, SOW, SaaS, Vendor, and Employment agreements), against a human-reviewed baseline, as the architecture stands today:


The biggest gap between single-agent and multi-agent shows up exactly where you’d expect: falsenegative rate and traceability — the two things a fluent generalist model is worst positioned to get right, because both require something closer to institutional memory of why a decision was made, not just what the decision was.


## Limitations, stated plainly


This reflects one architecture still under active development, not a finished benchmark paper, and it should be read that way:


● One client, one industry vertical (pharmaceutical distribution), one CLM platform. Generalizing the escalation-rule design to other regulated domains (finance, healthcare) is argued by analogy here, not demonstrated empirically.


● Client confidentiality constrains what can be disclosed about model choice and exact prompting strategy, which limits independent reproducibility.


● The evaluation baseline is human-reviewed agreement, not a held-out ground-truth legal standard — so these numbers reflect agreement with reviewers, not an absolute correctness measure.


● The long-run effect of this escalation design on reviewer calibration — whether reviewers get lazier or more skeptical of agent output over time — wasn’t measured here, and it’s an open question worth tracking in any similar deployment.


Takeaways if you’re building something similar

- Let the domain’s risk profile drive the architecture, not the reverse. Bolting auditability onto a general-purpose agent framework after the fact is much harder than designing for it from day one.
- Budget for integration, not just reasoning. Connecting to systems of record is a substantial engineering line item that’s easy to underestimate.
- Pick evaluation metrics that reflect your actual risk, not generic ones. Aggregate accuracy hides the failure modes that are expensive.
- Make human oversight structural, not confidence-triggered. For anything with regulatory consequence, deterministic escalation rules beat purely confidence-based routing at maintaining trust.

None of this is specific to contracts. The same shape — specialized agents, a coordinating reasoning layer, deterministic escalation, and an audit trail that survives a compliance review — applies anywhere an LLM system’s output needs to hold up when someone with subpoena power looks at it.


## References


Sinha, A., Ranganathan, S., Dharmaratnakar, A., & Das, D. (2026). Human-on-the-Loop Orchestration for AI-Assisted Legal Discovery. arXiv preprint. arxiv.org/abs/2606.19812


Suplicy Barbosa, T., de Castro, D., Singh, A. K., & Vitale, S. (2026). An Experimental Assessment of AIBased Legal Decision-Making Systems in Contract Analysis and Risk Detection. Qubahan Techno Journal, 5(1), 37–65. doi.org/10.48161/qtj.v5n1a81


This piece also draws on an enterprise CLM deployment I’m architecting and still building out; client and platform specifics are withheld under a standing confidentiality agreement.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
