# AI in Cybersecurity: A Beginner’s Guide to Claude Code, MCP & AI Agents-2

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-08
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/ff97f477cfce](https://medium.com/p/ff97f477cfce)

---

## Full Article / Writeup Content

# AI in Cybersecurity: A Beginner’s Guide to Claude Code, MCP & AI Agents-2


--


Listen


Share


So far, the main idea is that Claude can be much more than a chatbot. In a cybersecurity workflow, Claude Code can work with project files, instructions, tools, and structured security processes. CLAUDE.md gives Claude stable project context and rules, while Skills give it reusable domain expertise, such as detection engineering, threat intelligence, malware triage, or incident response.


A Skill is useful because it helps Claude follow the same methodology every time instead of relying on a long repeated prompt. The Skill description is especially important because it tells Claude when that Skill should be used. A vague description such as “helps with security” creates confusion, while a specific description such as “reviews Sigma rules, validates ATT&CK mappings, checks false positives, and evaluates detection logic” helps Claude select the right capability for the right task.


Let’s start another concept Slash Commands: When I Want to Trigger a Workflow Myself


A Skill can become relevant automatically based on context.


A slash command is different conceptually.


I explicitly invoke it.


Think:


```
/triage-alert
```


or:


```
/review-detection
```


or:


```
/create-handoff
```


Instead of Claude deciding when a workflow applies, I trigger it.


Claude Code includes interactive slash commands, and typing / exposes available commands in the interface.


A useful mental model is:


This distinction helped me a lot.


## Subagents: Give a Specific Task Its Own Worker


Now imagine investigating an incident involving:


```
suspicious.exe      ↓PowerShell      ↓unknown domain      ↓possible credential access
```


One AI context trying to investigate everything can become messy.


A better workflow may separate the work.


```
Primary Investigator                           │          ┌────────────────┼────────────────┐          │                │                │          ▼                ▼                ▼   Malware Agent      IOC Research      Detection Agent          │                │                │    Analyze file      Research IP/domain   Build detection          │                │                │          └────────────────┼────────────────┘                           ▼                     Main Investigator                           │                           ▼                    Correlated Findings
```


This is where subagents become useful.


They can work on specific tasks with more isolated context instead of forcing one long conversation to contain everything.


Claude’s current agent tooling allows specialized agents to be defined and used for delegated work; its own guidance recommends subagents particularly when tasks are parallelizable or benefit from isolated context.


In security that could mean one agent investigates network indicators while another reviews a process tree.


But we need an important control:


Parallel does not mean independent authority.


The agents can investigate independently while the main workflow still controls what happens with their findings.


## Hooks: Where AI Automation Becomes Deterministic


This was one of the most important concepts for me.


Suppose I tell Claude:


> “Never modify raw evidence.”


“Never modify raw evidence.”


Will Claude follow that?


Probably.


But security engineering should not rely only on “hopefully the AI remembers.”


For important rules, I want deterministic enforcement.


That is where Hooks become interesting.


Hooks are event-driven handlers that run at particular points in the agent workflow.


For example:


```
Claude wants to execute command          ↓      PreToolUse          ↓     Security Check        ↙      ↘     SAFE      RISKY       ↓         ↓     Allow      Block
```


Now imagine Claude attempts:


```
rm evidence/raw/authentication.log
```


A PreToolUse hook could examine the command and reject it before execution.


Conceptually:


```
if target.startswith("evidence/raw/"):    deny("Raw evidence cannot be modified")
```


That is stronger than simply saying:


> “Claude, please remember not to modify evidence.”


“Claude, please remember not to modify evidence.”


The current Claude agent tooling exposes lifecycle hooks including events around tool use, prompt submission and stopping; available hook events can vary between the CLI and SDK environment, so exact support should be checked for the version you are using.


## Understanding Hook Events Through Cybersecurity


My notes included several lifecycle events, and I found them easier to remember through security examples.


SessionStart can be thought of as preparing the investigation environment when work begins.


A security workflow could inject the incident ID, case directory or analyst rules.


PreToolUse happens before a tool executes.


This is perfect for controls such as:


```
Is this command destructive?Is this domain approved?Is this tool allowed?Is this operation touching raw evidence?
```


PostToolUse occurs after tool execution.


That could validate output or write an audit record.


For example:


```
Claude generates Sigma rule         ↓PostToolUse hook         ↓Run Sigma validator         ↓PASS / FAIL
```


UserPromptSubmit occurs when the analyst submits a prompt.


That could add useful context or validation.


Stop occurs when the agent finishes a piece of work.


That could trigger a final validation or generate an investigation summary.


You may also encounter session, notification or configuration-related lifecycle events depending on the Claude Code surface or SDK version being used. The key idea is more important than memorizing every event:


> A hook attaches deterministic behavior to an AI workflow event.


A hook attaches deterministic behavior to an AI workflow event.


## Command Hooks, Prompt Checks and Agent-Based Verification


Another concept from my notes was thinking about hooks in three levels.


The simplest form is a deterministic command or script.


For example:


```
Before running Bash       ↓run check_command.py       ↓allowed / denied
```


This is excellent when the rule is objective.


Example:


```
Block rm -rfBlock writes to evidence/raw/Block git push --force
```


Another pattern can use an LLM evaluation when the decision requires interpretation.


And more complex verification can involve an agent that performs several checks.


But this gives us an important security design rule:


```
If deterministic code CAN enforce the policy,prefer deterministic enforcement.
```


```
Use AI reasoning where interpretation is actually needed.
```


I would not ask an LLM:


> “Do you think rm -rf / is dangerous?"


“Do you think rm -rf / is dangerous?"


I already know the answer.


Just block it.


## Skills vs Commands vs Subagents vs Hooks vs MCP


This was probably the easiest area to confuse, so here is the simplest mental model I found:


```
SKILL"What expertise should Claude know?"
```


```
COMMAND"What workflow am I manually starting?"SUBAGENT"What separate worker should handle this task?"HOOK"What must automatically happen at this lifecycle event?"MCP"What outside systems can Claude communicate with?"
```


Security example:


```
"I need to investigate an IOC."
```


```
Skill:Use our threat-intelligence methodology.Command:I manually run /investigate-ioc.Subagent:Create a separate infrastructure-analysis worker.Hook:Log every external lookup and prevent unapproved actions.MCP:Connect to the threat-intelligence service.
```


Once I thought of them this way, the Claude ecosystem became much easier to understand.


Part 3 of this AI Security series is coming soon. For more hands-on cybersecurity project walkthroughs, you can explore Follow me on Medium and GitHub, and LinkedIn for upcoming AI Security, Detection & Response, Threat Intelligence, and Security Automation updates.Medium claude project:https://medium.com/@Commoness/building-a-basic-tool-using-claude-2cc3f782aa19Github:https://github.com/RoshiniMlakshmanaLinkedin:https://www.linkedin.com/in/roshini-m-lakshmana-b51ab3243/

---
*Archived in LLM Hacking Vault from verified community intelligence.*
