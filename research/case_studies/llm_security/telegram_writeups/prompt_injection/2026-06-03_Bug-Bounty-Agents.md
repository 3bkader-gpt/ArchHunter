# Bug-Bounty-Agents

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-06-03
- **Source Channel:** Bug Bounty Hub
- **Original Reference URL:** [https://github.com/matty69v/Bug-Bounty-Agents](https://github.com/matty69v/Bug-Bounty-Agents)

---

## Full Article / Writeup Content

# Bug-Bounty-Agents


A curated arsenal of specialized AI agent prompts for bug bounty hunting,
penetration testing, and offensive security workflows.


Drop-in personas for Claude Code, Copilot Chat, Cursor, and any agent-capable LLM -
no frameworks, no dependencies, just disciplined prompts.


43 agents  ·  6 engagement phases  ·  4 supported clients  ·  0 dependencies


Quick Start  ·  Catalog  ·  Setup  ·  Workflows  ·  Examples  ·  Contributing  ·  Disclaimer


## Overview


Each .md file in this repository defines a focused, production-ready agent
persona - recon, web hunting, exploit chaining, reporting, and more - that
you can drop into Claude Code, GitHub Copilot Chat, Cursor, or
any agent-capable LLM client.


No frameworks. No dependencies. Just disciplined prompts that turn a generic
LLM into a specialist, with strict scope enforcement built in.


> These are prompts, not scanners. They make an LLM act like a
specialist; they do not bring their own tooling. You still drive the
engagement.


These are prompts, not scanners. They make an LLM act like a
specialist; they do not bring their own tooling. You still drive the
engagement.


## Table of Contents

- Quick Start
- Agent Catalog
- Prerequisites
- Per-Tool Setup

One-line installer
Claude Code
GitHub Copilot Chat
Cursor
ChatGPT / Gemini / Generic
- One-line installer
- Claude Code
- GitHub Copilot Chat
- Cursor
- ChatGPT / Gemini / Generic
- Using an Agent
- Workflows
- Examples
- Burp Suite MCP Integration
- Updating
- Project Files
- Contributing
- Security
- Disclaimer

## Quick Start


```
git clone https://github.com/matty69v/Bug-Bounty-Agents.git
cd Bug-Bounty-Agents
./install.sh                     # auto-detects your client(s)
```


Or pick a specific target:


```
./install.sh --target claude         # Claude Code (global)
./install.sh --target claude-local   # Claude Code (this project)
./install.sh --target copilot        # Copilot Chat (VS Code)
./install.sh --target cursor         # Cursor (this project)
./install.sh --target all            # everything detected
./install.sh --dry-run --target claude
./install.sh --uninstall --target claude
```


## Agent Catalog


Agents are grouped by phase of an offensive engagement. The full
machine-readable index lives in AGENTS.md.


### Reconnaissance & Intelligence


### Web, API & Application


### Infrastructure, Cloud & Network


### Exploitation & Post-Ex


### Specialized & Adversarial


### Defense, Reporting & Orchestration


## Prerequisites

- git and bash installed on your machine
- An LLM client that supports custom system prompts or instruction files:

Claude Code
GitHub Copilot Chat (VS Code)
Cursor
ChatGPT (Custom GPTs / Projects), Gemini, or any chat UI accepting a system prompt
- Claude Code
- GitHub Copilot Chat (VS Code)
- Cursor
- ChatGPT (Custom GPTs / Projects), Gemini, or any chat UI accepting a system prompt

## Per-Tool Setup


### One-line installer


```
./install.sh           # interactive - detects what you have
./install.sh --help    # see all options
```


The installer auto-detects claude, code, and cursor on your PATH,
copies agents to the correct directory for each, and renames files
appropriately (e.g. .chatmode.md for Copilot). Use --dry-run to
preview, --uninstall to remove.


Claude Code reads agent definitions from ~/.claude/agents/ (global) or
.claude/agents/ (per-project).


```
# Global
mkdir -p ~/.claude/agents && cp *.md ~/.claude/agents/

# Per-project
mkdir -p .claude/agents && cp /path/to/Bug-Bounty-Agents/*.md .claude/agents/
```


```
/agents
> use the web-hunter agent to audit https://target.example.com
```


Copilot Chat supports custom chat modes via .chatmode.md files.


```
# macOS
PROMPTS_DIR="$HOME/Library/Application Support/Code/User/prompts"
# Linux:   PROMPTS_DIR="$HOME/.config/Code/User/prompts"
# Windows: %APPDATA%\Code\User\prompts

mkdir -p "$PROMPTS_DIR"
for f in *.md; do
  cp "$f" "$PROMPTS_DIR/$(basename "$f" .md).chatmode.md"
done
```


Reload VS Code, then select the mode from the Copilot Chat dropdown.


```
cd /your/project
mkdir -p .cursor/rules
cp /path/to/Bug-Bounty-Agents/*.md .cursor/rules/
```


Each file becomes a selectable rule in Cursor's chat panel.


Open the agent file, copy its full contents, and paste into:

- ChatGPT - Custom GPT → Instructions, or Project → Instructions
- Gemini - Gem instructions
- Open WebUI / LM Studio - System prompt field
- API clients - system role message

## Using an Agent


Once installed, give the agent a concrete target and scope:


```
Target: https://staging.acme.example.com
Scope:  *.acme.example.com (in scope), *.thirdparty.example.com (out)
Goal:   Find auth bypass and IDOR on /api/v2/users endpoints.
```


Well-behaved agents will:

- Ask clarifying questions before acting
- Stay strictly within scope
- Produce reproducible PoCs
- Output triage-ready findings with severity and impact

## Workflows


Use swarm-orchestrator or attack-planner to coordinate a full engagement:


```
flowchart LR
    A[recon-advisor]:::phase --> B[web-hunter<br/>api-security]:::phase
    B --> C[exploit-chainer]:::phase
    C --> D[poc-validator]:::phase
    D --> E[report-generator]:::phase

    A -.- A1([enumerate attack surface]):::note
    B -.- B1([find vulnerabilities]):::note
    C -.- C1([escalate impact]):::note
    D -.- D1([confirm &amp; stabilize]):::note
    E -.- E1([write the submission]):::note

    classDef phase fill:#0d1117,stroke:#30363d,color:#e6edf3,stroke-width:1px;
    classDef note  fill:#00000000,stroke:#00000000,color:#8b949e;
```


Layer _scope-guard on top of any agent to enforce hard scope boundaries
during long-running sessions. For purple-team work, run red-team-operator
and purple-team side by side.


## Examples


End-to-end engagement walkthroughs (sanitized) live in examples/:

- web-bug-bounty.md - recon → web-hunter →
bizlogic → chain → validate → report, ending in a Critical-tier
HackerOne submission.

## Burp Suite MCP Integration


PortSwigger's MCP Server lets
your LLM client drive Burp Suite directly - issue requests through the
proxy, query Repeater/Intruder, read site maps, and pivot off live traffic
while an agent in this repo provides the methodology.


> Pairing tip: load web-hunter, api-security, ssrf-hunter, or
bizlogic-hunter alongside the Burp MCP so the agent can both think
like a specialist and act through Burp.


Pairing tip: load web-hunter, api-security, ssrf-hunter, or
bizlogic-hunter alongside the Burp MCP so the agent can both think
like a specialist and act through Burp.


### Prerequisites

- Burp Suite (Community or Professional) installed and running
- Java available on PATH (java --version)
- jar available on PATH (jar --version) - required to build
- An MCP-capable client (Claude Desktop, Claude Code, Cursor, etc.)

### Build the extension


```
git clone https://github.com/PortSwigger/mcp-server.git
cd mcp-server
./gradlew embedProxyJar
# output: build/libs/burp-mcp-all.jar
```


### Load into Burp Suite

- Launch Burp Suite.
- Go to Extensions → Add.
- Set Extension Type to Java.
- Select build/libs/burp-mcp-all.jar and click Next.
- Open the new MCP tab and tick Enabled.

Optional: enable tools that can edit your config if you trust the client.
Default listener: http://127.0.0.1:9876.
- Optional: enable tools that can edit your config if you trust the client.
- Default listener: http://127.0.0.1:9876.

### Wire up your MCP client


Claude Desktop (auto): in the Burp MCP tab, click the installer button -
it writes the config for you. Restart Claude Desktop.


Claude Desktop (manual): edit
~/Library/Application Support/Claude/claude_desktop_config.json (macOS) or
%APPDATA%\Claude\claude_desktop_config.json (Windows):


```
{
  "mcpServers": {
    "burp": {
      "command": "/path/to/burp/jre/bin/java",
      "args": [
        "-jar",
        "/path/to/mcp-proxy-all.jar",
        "--sse-url",
        "http://127.0.0.1:9876"
      ]
    }
  }
}
```


Use the Burp MCP tab's installer to extract mcp-proxy-all.jar if you
don't already have it.


SSE-capable clients (Cursor, Claude Code, custom): point them straight
at the SSE endpoint - no proxy needed:


```
http://127.0.0.1:9876/sse
```


### Smoke test


With Burp running, the extension loaded, and your client restarted, ask:


```
Use the burp MCP to list the last 10 requests in the proxy history,
then pick anything that looks like an authenticated API call.
```


If the client returns live traffic from your Burp session, you're wired up.


## Updating


```
cd ~/path/to/Bug-Bounty-Agents
git pull
./install.sh         # re-runs install with the latest agents
```


## Project Files


## Contributing


PRs and issues are welcome. See CONTRIBUTING.md for the
contribution workflow, agent template, and style guide. Use the issue
templates for bug reports and new-agent proposals.


## Security


Found a prompt-safety or supply-chain issue? See SECURITY.md
and report privately via GitHub Security Advisories.


## Disclaimer


> These agents are intended for authorized security testing only -
bug bounty programs you are enrolled in, systems you own, or environments
where you have explicit written permission to test.
Unauthorized testing is illegal in most jurisdictions. You alone are
responsible for how you use these prompts.


These agents are intended for authorized security testing only -
bug bounty programs you are enrolled in, systems you own, or environments
where you have explicit written permission to test.


Unauthorized testing is illegal in most jurisdictions. You alone are
responsible for how you use these prompts.


Built for hunters who prefer disciplined prompts over brittle frameworks.


Star on GitHub  ·  Report an issue  ·  Contribute


MIT licensed · Authorized testing only

---
*Archived in LLM Hacking Vault from verified community intelligence.*
