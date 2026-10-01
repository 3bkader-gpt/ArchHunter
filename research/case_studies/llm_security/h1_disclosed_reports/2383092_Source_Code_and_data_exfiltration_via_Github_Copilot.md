# Report #2383092: Source Code and data exfiltration via Github Copilot

- **Platform:** HackerOne
- **Report URL:** [https://hackerone.com/reports/2383092](https://hackerone.com/reports/2383092)
- **Program:** GitHub
- **Reporter:** @astrounder
- **Status:** RESOLVED
- **Severity:** low
- **Weakness:** Code Injection
- **Bounty:** Yes (Undisclosed Amount)
- **Submitted:** 2024-02-21T01:35:41.101Z
- **Disclosed:** 2024-08-19T21:57:10.420Z
- **Community Upvotes:** 63

---

## Executive Summaries

### Team by @s2jeff-gh

Due to insecure output handling in Copilot client interfaces, a prompt injection initiated attack was able to result in data exfiltration in a number of ways. A user that was prompt injected, by running Copilot Chat in a specific manner on an untrusted repository, could have generated arbitrary image links pointing to an attacker controlled domain that would be rendered in the Copilot Chat interface, allowing for data exfiltration via URL parameters. This attack could potentially have allowed a compromised Copilot session (Copilot Chat being called on a malicious cloned local repository) to exfiltrate the contents of the same workspace to the malicious domain.

Other risky behaviors that were also noted was that links could be created to attacker controlled domains via Copilot, which would not be immediately apparent to end users, causing another avenue for data exfiltration which required more user interaction, lowering the severity.

This vulnerability was addressed by only rendering images from trusted domains, and by adding interstitial modals to let users know where links pointed. GitHub also hardened the rendering specification for all Copilot clients to ensure that the context provided to Copilot is made more apparent to end users to mitigate the impact of unseen content affecting the output of Copilot.

### Researcher by @astrounder

** Prompt Injection in GitHub Copilot Leading to Source Code Exfiltration **

**Description:**
This vulnerability exploits the way GitHub Copilot handles instructions within chat, workspace and code suggestion features.

By utilizing prompt injection techniques (direct and indirect), an attacker can manipulate Copilot to embed and execute hidden malicious instructions. These instructions can then be used to exfiltrate sensitive information, such as the developer’s source code, to an attacker-controlled domain.
The issue arises due to Copilot's insecure handling of output, where it can process instructions input directly into the chat or inserted into a workspace file and execute embedded malicious content without the user's knowledge. The Copilot chat's ability to render certain HTML tags (e.g., <h1>) invisibly to the user further exacerbates the risk, allowing an attacker to hide their payload from the victim.

**Impact:**
The impact of this vulnerability is very interesting, as it allows an attacker to extract sensitive source code from a developer’s environment (credentials, tokens, configurations, etc.). Copilot’s ability to render and execute hidden commands without the user’s knowledge amplifies the potential damage. 
VS Code and Jet Brains were affected.
GitHub.com was not affected.

---

## Full Vulnerability Description & Reproduction Steps

No detailed description provided.

---

## Attachments
None.
