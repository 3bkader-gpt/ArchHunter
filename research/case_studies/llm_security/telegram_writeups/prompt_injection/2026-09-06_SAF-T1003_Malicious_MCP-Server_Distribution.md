# SAF-T1003 Malicious MCP-Server Distribution

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-06
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/e703f126e9da](https://medium.com/p/e703f126e9da)

---

## Full Article / Writeup Content

# SAF-T1003 Malicious MCP-Server Distribution


--


Listen


Share


Post 3 of a series walking the SAFE-MCP framework one technique at a time. Post 1 covered Tool Poisoning Attacks; Post 2 covered Supply Chain Compromise.


## The technique that stops pretending


The last two posts were both, in their own way, about disguise. Tool poisoning hides an instruction inside a metadata channel the model can’t tell apart from a prompt. Supply chain compromise hides malicious code inside a package that spent fifteen versions earning your trust. Both attacks rely on a lie about what the thing in front of you actually is.


SAFE-T1003 doesn’t bother with any of that. Malicious MCP-Server Distribution is exactly what it sounds like. Someone builds a server whose package, binary, container, endpoint, or install config contains attacker-controlled behavior, and then they put it somewhere you’ll find it. There’s no trusted upstream to compromise and no legitimate identity to borrow. The server is hostile from the first commit, and the attacker’s whole job is delivery: getting a person, a host application, or an automated process to acquire it and turn it on.


That’s a narrower claim than it looks at first, and the narrowness matters. The framework is careful about where this technique ends, and it ends at malicious delivery and activation. Whatever happens after that (command execution, credential theft, exfiltration, persistence) is a separate outcome with its own evidence bar. The reverse boundary counts for just as much. A listing you don’t recognize, a package name that pattern-matches to something bad, a server that’s simply missing a provenance attestation: none of those on their own prove anything. This is the technique where it’s easiest to cry wolf, so the framework spends real effort telling you what doesn’t count.


## Framework metadata


## What SAFE-T1003 describes, and how it differs from T1002


If you read the last post, you’re entitled to ask why this is a separate technique at all. Supply chain compromise already covered malicious packages. The distinction is real, and it’s worth getting right, because it changes which of your defenses actually fire.


T1002 is the broad family, where the attacker gets inside a distribution pipeline you already trust. Trust is the load-bearing word. A rug pull like postmark-mcp, a stolen maintainer token, a compromised CI job, a worm riding npm's transitive graph: every one of those subverts a channel or an identity you'd already decided was safe. The trust exists first, and the attacker steals it.


T1003 is the MCP-specific case where there’s no borrowed trust to begin with. The server gets published as itself, from the attacker’s own account, through a channel that will happily carry it. The framework’s scope section lists the delivery paths without much drama: initial malicious publication, delivery through a package registry, an MCP metadata registry or marketplace, a release location, a direct configuration, or a remote endpoint. It also calls out continued availability through a private mirror or cache after the public copy gets pulled. That last one is the detail people forget, and it’s where I’ve watched otherwise careful teams get burned.


The framework is equally clear about what falls outside the technique, which is how you can tell the authors were disciplined about it. A merely vulnerable server, with no evidence of adversarial distribution, isn’t this. Deceptive naming as the defining mechanism belongs to the impersonation neighbor, SAF-T1004. Persuasion as the defining mechanism is the social-engineering neighbor, SAF-T1006. Compromise of an update path is SAF-T1207. The payload’s downstream effects live under somebody else’s technique ID. Subtract all of that, and what’s left is the pure act of delivery: a malicious server made reachable, acquired, and switched on.


## The registry does less than you think


Part of why direct distribution works is that the infrastructure was never built to stop it, and the infrastructure is honest about that if you read the fine print.


The official MCP Registry stores metadata pointing at packages or remote servers. The package registries host the actual code and binaries. The Registry does namespace verification, which establishes that whoever published under a namespace controls that namespace, but it hands off scanning of the actual server code to the upstream package registries and downstream aggregators. Namespace control is an identity check. It isn’t a safety check. Owning com.example proves you are example.com. It says nothing about what your server does once it runs.


The Registry’s own moderation policy is refreshingly blunt about the ceiling here. Consumers should assume minimal-to-no moderation. It removes malware it identifies, but it makes no promise to catch everything, and it generally won’t pull a server just because it contains a vulnerability. That’s a design statement, not a shortcoming. A metadata registry that made safety guarantees it couldn’t keep would leave you worse off than one that tells you plainly to bring your own controls.


Then you’ve got the one-click install path, which is where delivery turns into execution fastest. A crafted local-server configuration can be passed around through a repo, a docs page, or a Slack message, and if a client acts on it, it can run arbitrary commands. That’s the reason the final version of SEP-1024, the MCP client security requirements for local servers, requires a client to display the complete command and every argument, and to get explicit consent, before it executes anything. The spec authors clearly understood that a config link is a delivery vector, and that your last line of defense is a human actually being shown what’s about to run.


## The mechanic, stripped of ceremony


Four steps, none of them exotic:

- The adversary prepares or modifies a server artifact or config so that installation, startup, or later tool use triggers behavior they chose.
- They expose it through a package registry, an MCP metadata registry or marketplace, a release page, a remote endpoint, or a config link. Any channel an MCP consumer can reach will do.
- A consumer resolves that reference to a concrete artifact or endpoint and installs, updates, configures, or activates it.
- The server runs with the permissions, credentials, data access, and network reach of wherever it landed. Everything downstream depends on that context.

The framework names three preconditions: a reachable delivery path, an act of acquisition or activation, and insufficient admission control for the specific source, version, digest, signature, or publisher transition involved. Sit with that third one for a second. The vulnerability isn’t that malicious servers exist, because they always will. It’s the gap in admission control, meaning the absence of a gate that checks this exact artifact, from this exact source, at this exact version, before it’s allowed to run. Delivery only becomes your problem at the moment of activation, and that’s also the last moment you get to say no.


## Has anyone actually done this?


Same question every post. This time, unlike pure tool poisoning, the answer is a documented yes. But I want to state the caveat before the evidence rather than after, because the caveat is the professionally interesting part.


The honest evidence status is observed distribution. It is not measured prevalence, and it is not quantified loss. We have a real malicious MCP server that really did sit in a real public registry. We don’t have a named victim organization or a count of how many installs executed the payload. Both of those things are true at the same time, and a threat model that mashes them together into “MCP servers are getting people owned in the wild” is claiming more than the record supports. Keep the two ideas apart.


@lanyer640/mcp-runcommand-server (October 2025). This is the anchor case, and it's a clean example precisely because nothing about it is subtle. Checkmarx Zero researcher Bruno Dias identified the package and reported it to npm on October 1, 2025, and Checkmarx's Darren Meyer wrote it up. The package advertised itself as an MCP tool server, specifically one that lets your AI assistant run shell commands, which is already a generous grant of authority. From version 1.0.6 onward it shipped an install-time reverse shell to an attacker-controlled host. npm removed it. Independent analysis from Koi Security fills in the timeline. The original version, first published September 6, 2025, was legitimate, and the malicious update landed roughly three weeks later, once adoption had time to build. Koi's teardown describes two separate reverse shells. One sits in a preinstall hook that fires during npm install or npx whether or not you ever run the server. The other activates when the server actually starts. Install it and never run it, and the preinstall hook already has you.


Notice what makes this T1003 rather than T1002. Nobody impersonated a trusted postmark-style brand, and nobody stole a maintainer account. The threat actor stood up their own package under their own name and let the registry distribute it for them. Delivery was the whole attack.


One more honest note on that case. Checkmarx detonated the payload in a safe environment, and they flagged that even after npm’s removal, private repositories and caches could keep serving it. A public takedown is not the end of availability. That’s the “continued availability through a mirror or cache” scope item showing up in an actual incident instead of a hypothetical.


CVE-2025–6514 in mcp-remote (July 2025). This one belongs in the conversation with an asterisk, and the asterisk is the lesson. JFrog's Or Peles disclosed that an affected client connecting to an untrusted or hijacked server could be induced to execute OS commands from crafted authorization metadata. Versions 0.0.5 through 0.1.15 were affected, and 0.1.16 fixed it, with credit to maintainer Glen Maddern. This is a demonstrated enabling path. It shows how connecting to a malicious server can turn into command execution on the client. It is not itself a case of malicious distribution or production exploitation. I'm including it because it explains why the severity sits where it does: distribution matters exactly because credible client-side execution paths like this one exist. Think of it as the "why you should care that the server got delivered" evidence, not the "someone delivered a malicious server" evidence. Keeping those two roles separate is basically the whole discipline of this section.


## The part that should change how you buy scanners


The framework leans on two academic measurements, and taken together they make an argument I think matters more than any single incident.


Li and Gao (DSN 2026) collected 67,057 MCP servers across six registries and catalogued the registry-level risks: malicious publication, hijackable links, naming confusion. Their MCPInspect evaluation, run on a 41-server sample, reported around 90% precision, with the paper’s own caveats about incomplete dynamic extraction, inaccessible servers, and a short 2025 collection window.


Then Chen and colleagues built MCPZoo: 64,611 unique servers, more than 37,000 of them amenable to dynamic analysis, run through eight different scanners. The headline numbers are the ones to keep in your head before your next vendor call. Across those eight scanners, 96.89% of servers got flagged by at least one scanner. Average precision was 45.53%. Inter-scanner agreement, measured as Jaccard similarity, was 15.66%. Recall against a ten-CVE ground truth was 24.17%.


Read those four numbers together and a picture forms. If almost every server trips some scanner, then “a scanner flagged it” tells you almost nothing. Under-50% average precision means a coin flip’s worth of the alerts you do get are wrong. Sub-16% inter-scanner agreement means the tools aren’t even flagging the same servers, so they disagree about what’s suspicious far more than they agree. And 24% recall means that against known-bad ground truth, three out of every four real problems walked right past. These scanners manage to be too loud and too blind at once.


The operational takeaway isn’t that scanners are useless. It’s that a single scanner alert can’t stand in for a verdict, in either direction. You can’t block on one hit without drowning in false positives, and you can’t clear a server just because one scanner stayed quiet. What the data actually supports is correlation, meaning you join admission and integrity signals to what the server does on first run, and you treat a generic capability, a scary keyword, a missing optional attestation, or one lonely scanner alert as an input to the decision rather than the decision itself.


I know that’s a less satisfying answer than “buy the tool with the best detection rate.” It’s also the right one.


## Detection: correlate admission with activation


The framework ships a portable detection analytic, and its design bakes in the calibration lesson above. The idea is to collect the events that bracket a server’s arrival and correlate them, instead of alerting on any one of them in isolation.


Here’s what to collect: MCP configuration and activation events, package-manager install and update records, the resolved names, versions, sources, digests, and lockfile decisions, publisher and provenance history, process creation, and first-run network flows. The part that’s easy to skip and expensive to skip is preserving a single correlation identifier that stitches approval, acquisition, and execution into one story. Without that join key you’re left with a pile of logs from different systems and no way to say “this activation is the one that followed that suspicious admission.”


The alerting logic is tiered by signal strength. A strong integrity failure, such as a digest mismatch, an invalid signature, or invalid provenance, is high-confidence on its own once it’s joined to an actual activation. Absent a strong failure, the rule wants a combination of weaker anomalies converging on the same activation, say an unapproved source plus an unapproved version plus a publisher transition. Unusual first-run behavior, like an unexpected child process or a first-time outbound connection, pushes confidence up further.


Then comes the negative rule, which is the tell that grown-ups wrote this. Do not alert on absent optional provenance by itself. Missing an attestation that was never required in the first place is not an integrity failure. The detection deliberately scores invalid provenance strongly while refusing to treat missing provenance as evidence of malice, because if it did, it would fire on every honest publisher who hasn’t adopted attestations yet, and your team would learn to ignore it inside a week. The false-positive notes cover the other legitimate cases too, like a reviewed emergency fork that runs from an unapproved source until baselines catch up, or planned publisher and source migrations that look anomalous mid-rollout.


The published rule consumes normalized correlation summaries, and it needs local field mapping, baselining, threshold tuning, and production-like replay before it means anything in your environment. It’s a starting posture, not a drop-in control, same as every good detection you’ve ever deployed.


## Mitigation: admission control is the whole game


Because the technique is defined by delivery and activation, the mitigations all cluster around the moment of admission. The good news, echoing the last post, is that almost none of this is MCP-exclusive. It’s the discipline you already claim to apply to your dependencies, pointed now at a category of dependency that tends to slip in through the side door.


Gate every new server, publisher, source, and version, and show the operator the exact command. This is the SEP-1024 requirement turned into policy. Require explicit approval on each new dimension, and when a local install is about to run, display the full command and every argument so a human can actually see what’s about to execute. An approval flow that hides the command is theater.


Run everything through an approved internal catalog, and pin to immutable versions or digests. Content-addressed pinning is what closes the “clean today, malicious tomorrow” window. A digest can’t be quietly repointed. A tag can be repointed at anything. Keep your acquisition records, and reject integrity mismatches at the gate instead of logging them after the fact.


Treat provenance as evidence, not a verdict. Provenance and signatures tell you where an artifact came from and how it was built. They don’t tell you it’s safe. postmark-mcp and LiteLLM were both, in a sense, perfectly authentic. Fold provenance into a decision alongside review, behavioral analysis, and publisher history. It raises the bar without closing the door.


Sandbox third-party servers and scope their credentials. Least privilege, constrained credentials, restricted filesystem and network access, appropriate isolation. If a malicious server activates but can only reach one API and holds one narrow token, the delivery succeeded and the payload starved. This is the control that makes the severity conditional in the first place. “High, conditional on activation authority” is the framework quietly telling you that you’re the one who sets the authority.


Keep the ability to deny an exact artifact in your own caches, and watch first-run behavior. The @lanyer640 case is why. A public takedown does nothing for your Nexus, your Artifactory, your Verdaccio, or a developer's local cache. You need to be able to block a specific artifact and version across every place you retained it, and you need first-run monitoring to catch the copies that slipped in before you knew to block them.


For incident response, the framework’s sequence is the sane one. Disable the server. Preserve the configuration and acquisition evidence before you destroy anything. Block the exact artifacts without deleting the evidence you’re going to need later. Enumerate every host and cache that retained a copy. And, once more, distinguish availability from execution, because a server sitting in a cache is not the same thing as a server that ran. Investigate downstream behavior on the hosts where it actually activated, and rebuild from trusted inputs.


## What I’d tell a client


Malicious MCP-Server Distribution is the least clever technique in the Initial Access tactic, and that’s exactly why it deserves a clear head. There’s no novel mechanism to admire. Someone publishes a bad server, and the only question that matters is whether your environment will admit and run it without a gate in the way.


Two things make it genuinely hard in practice, and neither is technical.


The first is the same shadow-MCP funnel from the last two posts. A server delivered straight from an attacker still has to get in, and the easiest way in is a developer dropping it into a local config, outside every pipeline where your admission controls actually live. You can’t gate a server you don’t know arrived.


The second is the false-positive trap the scanner data keeps warning about. This is the technique where the pressure to overreact runs highest, because every alarm vendor has an incentive to tell you the registries are full of malware, and per MCPZoo, some scanner will happily agree about nearly any server you name. Build a program that blocks on single scanner hits and you’ll generate so much noise that your team learns to wave servers through, which is the exact posture the attacker was hoping for. Calibration isn’t a nicety here. It’s load-bearing.


Four things worth doing before your next sprint closes:

- Inventory your MCP servers, local and experimental ones included. Third time I’ve opened with this, for the third good reason. Direct distribution needs an entry point, and the un-inventoried server is it.
- Put an admission gate in front of activation. Approve each new server, source, publisher, and version, pin to digests, and show the exact install command before it runs. Delivery only turns dangerous at the moment of activation, so that’s where the gate belongs.
- Correlate, don’t single-signal. Join admission and integrity events to first-run behavior on a shared correlation ID, and treat any lone scanner alert as a lead rather than a conviction. The public scanner numbers make this non-optional.
- Keep the power to deny an exact artifact in your own caches. A public takedown is not cleanup. Make sure you can pull a specific server and version from every mirror and cache you run, and monitor first-run behavior for the copies that beat you to it.

The through-line across all three Initial Access posts stays the same, just seen from a different angle each time. MCP hands agents real credentials, real filesystem access, and real network reach, on purpose, because that’s what makes them useful. Tool poisoning abuses that reach through a metadata channel. Supply chain compromise abuses it through a trusted package. Direct distribution abuses it with no disguise at all, and just needs you to say yes at the moment of activation. The defenses converge because the thing being defended never changes: the authority you granted the server, and the gate that decides whether a server ever gets to hold it.


Next in the series: SAF-T1004, Server Impersonation and Name-Collision, where the attacker picks up the disguise T1003 refused, and deceptive identity moves from a supporting detail to the whole attack.


A note on identifiers: this technique shows up as SAF-T1003 in the current repository path, and you may see it written as SAFE-T1003 elsewhere. Same technique, alternate spelling of the framework name.


## References

- SAFE-MCP framework, SAF-T1003: github.com/secure-agentic-framework/saf-mcp/tree/main/techniques/SAF-T1003
- Checkmarx, “NPM Malware Alert: @lanyer640/mcp-runcommand-server with Reverse Shell” (Darren Meyer; discovery by Bruno Dias): checkmarx.com/zero-post/npm-malware-alert-lanyer640-mcp-runcommand-server-with-reverse-shell
- Koi Security, “MCP Malware Wave Continues: A Remote Shell in Disguise”: koi.security/blog/mcp-malware-wave-continues-a-remote-shell-in-backdoor
- JFrog, “CVE-2025–6514 Threatens LLM Clients” (Or Peles): jfrog.com/blog/2025–6514-critical-mcp-remote-rce-vulnerability
- Xiaofan Li and Xing Gao, “A First Look at the Security Issues in the Model Context Protocol Ecosystem” (DSN 2026): arxiv.org/pdf/2510.16558
- Pei Chen et al., “Rethinking MCP Security” (MCPZoo, 2026 preprint): arxiv.org/pdf/2607.11086
- MCP Registry, About: modelcontextprotocol.io/registry/about
- MCP Registry, Moderation Policy: modelcontextprotocol.io/registry/moderation-policy
- SEP-1024, MCP Client Security Requirements for Local Servers (Den Delimarsky): modelcontextprotocol.io/seps/1024-mcp-client-security-requirements-for-local-server
- npm Docs, “Viewing package provenance”: docs.npmjs.com/viewing-package-provenance
- OpenSSF, “Build Provenance for All Package Registries”: repos.openssf.org/build-provenance-for-all-package-registries.html
- MITRE ATT&CK T1195.002, Compromise Software Supply Chain: attack.mitre.org/techniques/T1195/002
- MITRE ATT&CK DET0537, Behavioral detection for Supply Chain Compromise: attack.mitre.org/detectionstrategies/DET0537

---
*Archived in LLM Hacking Vault from verified community intelligence.*
