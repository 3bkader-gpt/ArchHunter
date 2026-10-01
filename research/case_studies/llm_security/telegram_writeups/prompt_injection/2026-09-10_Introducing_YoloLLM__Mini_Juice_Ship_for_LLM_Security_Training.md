# Introducing YoloLLM: Mini Juice Ship for LLM Security Training

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-10
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/136bcab8d498](https://medium.com/p/136bcab8d498)

---

## Full Article / Writeup Content

# Introducing YoloLLM: Mini Juice Ship for LLM Security Training


--


Listen


Share


If you’ve ever wanted to teach LLM security but struggled to find a realistic, hands-on lab that actually works, meet yoloLLM — an intentionally vulnerable LLM chatbot built for penetration testing training.


Think of it as a mini “Juice Shop for LLMs.”


## What is yoloLLM?


yoloLLM is a Docker-packaged training lab featuring two AI assistants from the same fictional insurance company:

- YoLoBot (port 5000) — a non-agentic customer service chatbot with no tools
- AgentBot (port 5010) — an agentic internal assistant that can call tools

Both connect to hidden internal services (a token-gated API with RCE, and a fake AWS IMDS endpoint). The contrast between how you attack each bot is the lesson.


## Why Two Bots?


Most LLM security demos show you one attack surface. yoloLLM shows you two different attack surfaces in the same company:


Same secrets, same backend, completely different exploit paths. That contrast is the training point.


## What Can You Attack?


## Customer Bot (YoLoBot)

- Prompt injection to leak guardrail bypass keywords
- Privilege escalation via LLM-emitted admin tokens
- Sensitive data exfil from admin panels
- SSRF to internal API and fake IMDS
- RAG poisoning — contact form writes directly to the retrieval KB

## Agent Bot (AgentBot)

- Indirect prompt injection via poisoned KB/tickets
- Ambient-authority RCE — the model fetches http://localhost:5020/admin/run?cmd=… with the token header auto-attached
- Tool abuse — read internal docs, search KB, draft emails, create tickets

Both bots share the same internal API (port 5020) and fake AWS metadata service (port 5030). The only way to reach them is through the bots — that’s the point.


## Quick Start


Requirements: Docker + Compose, ~4 GB disk for the model.


## What Makes This Different?

- Ships clean — the bot only steers customers to the fake site after you poison the KB. No hardcoded “visit our website” in the system prompt.
- Two attack surfaces — non-agentic vs. agentic, side-by-side.
- Real attack chains — SSRF → token-gated RCE, IMDS credential theft, RAG poisoning that persists across users.
- Docker-isolated — docker compose down && up gives you a fresh instance. No cross-player KB pollution.
- Instructor answer key included — full walkthroughs for every chain, secrets cheat sheet, teaching points.

## Who Is This For?

- Security trainers teaching LLM/agent pentesting
- Pen testers wanting to practice LLM-assisted attacks
- AppSec teams building internal labs
- Students learning the difference between non-agentic and agentic attack surfaces

## Get It


Grab the latest release from GitHub:


sudo git clone git@github.com:emilyanncr/YoloLLM.git


## GitHub - emilyanncr/YoloLLM: Intentionally vulnerable LLM chatbot built for hands-on LLM/agent…


### Intentionally vulnerable LLM chatbot built for hands-on LLM/agent security training. It ships two bots that share one…


github.com


⚠️ Not affiliated with the real YOLO Insurance. This is a fictional, deliberately vulnerable training project. “YoLo Insurance Inc.”, YoLoBot, AgentBot, YouOnlyLiveOnce, and all company names, people, policies, claims, credentials, and data inside are invented. This project is not connected to, endorsed by, or associated with the real-world YOLO Insurance company or any other actual business. Do not attempt the techniques here against anything you do not own or have written permission to test.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
