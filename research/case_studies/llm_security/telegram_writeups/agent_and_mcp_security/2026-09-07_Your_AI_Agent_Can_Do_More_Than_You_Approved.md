# Your AI Agent Can Do More Than You Approved

- **Category:** AI Agents & MCP Security
- **Publication Date:** 2026-09-07
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/782e6399d411](https://medium.com/p/782e6399d411)

---

## Full Article / Writeup Content

Member-only story


# Your AI Agent Can Do More Than You Approved


## You click Approve once. After that the AI makes its own decision, and nothing checks them against what you say yes to.


--


Listen


Share


## The part that already works


A user connects an app to their calendar. The consent screen says read-only. They approve, the app receives a token carrying calendar.readonly, and when it calls the API, Google checks that scope and refuses anything outside it.


That works because there is one door, and everything behind it is code a person wrote and reviewed.


Now put an agent there. The consent screen and the token are identical. The check at the API still happens and still works. But an agent does not make one call. It searches, reads the response, decides what to do next, and calls again. Every one of those decisions happens after the approval, and no check sits anywhere near them.


> You can already limit what an agent can do. The hard part is keeping that limit in place once the agent starts making its own decisions.


You can already limit what an agent can do. The hard part is keeping that limit in place once the agent starts making its own decisions.


## What that looks like when it fails


A user asks a banking assistant why their balance dropped. They click Approve on a screen that says check_bank_balance .

---
*Archived in LLM Hacking Vault from verified community intelligence.*
