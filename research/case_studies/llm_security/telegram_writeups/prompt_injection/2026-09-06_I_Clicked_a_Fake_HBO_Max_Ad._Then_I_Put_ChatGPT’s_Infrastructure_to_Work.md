# I Clicked a Fake HBO Max Ad. Then I Put ChatGPT’s Infrastructure to Work.

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-06
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/6f8df9eec61a](https://medium.com/p/6f8df9eec61a)

---

## Full Article / Writeup Content

# I Clicked a Fake HBO Max Ad. Then I Put ChatGPT’s Infrastructure to Work.


--


Listen


Share


An unexpected malware investigation — and a practical example of why AI becomes more useful when it has somewhere to work.


On 6 September, I clicked a Reddit advertisement for an HBO Max application for macOS.


I am already an HBO Max customer, so the proposition was relevant enough to catch my attention. A desktop application did not initially sound particularly unusual.


The website looked convincing. Familiar programmes, HBO branding, subscription plans and a “three months free” offer. The domain was hbomaxx[.]app, with an additional “x”, but the page itself had enough of the right visual elements to make a quick visit feel ordinary.


Then I clicked “Get for macOS”.


Instead of a download, I received instructions to open Terminal, copy a command and execute it.


I checked HBO’s own guidance: watching on a computer meant using a supported browser. There was no reason for the advertised installation procedure.


At that point, I could have closed the tab.


Instead, I wanted to understand what the command would do. That question turned into an investigation with ChatGPT — and a more interesting demonstration of AI than another generated email or summarised document.


What stood out was not only the model’s ability to understand code. It was the combination of that ability with the infrastructure available around it: a working environment, code execution, file handling and research tools.


I was not simply asking an AI for an opinion. I was asking it to help perform technical work.


## The installation process was the attack


The fake website did something quite deliberate. It presented running a shell command as an ordinary onboarding step.


The dialog explained how to launch Terminal using Spotlight. It provided a copy button. It showed the keyboard shortcuts needed to paste the command and press Return. At the bottom, it reassured the visitor that the installer would download and install automatically.


This was not a poorly explained download process. It was a carefully explained dangerous one.


The command’s visible beginning referenced Apple’s App Store. Inside the narrow text field, that was the reassuring part a visitor could easily recognise.


Farther along the command was Base64-encoded text. Decoding it revealed instructions to set a variable, retrieve a script from an unrelated domain and pass the response directly to zsh, the shell.


The Apple URL was decoration. The consequential operation happened elsewhere.


There is an important distinction here: decoding a command to read it is not the same as executing it. I inspected the decoded text; I did not run the malicious downloader on my Mac.


The first question I brought to ChatGPT was straightforward: what is this trying to do?


## From asking for an explanation to asking for an investigation


Many interactions with AI stop at an explanation.


You paste some unfamiliar code, receive a description and decide whether it sounds reasonable. That can be useful, but it leaves a considerable amount of work with the person asking the question.


Someone still has to extract the relevant data, write the decoding script, run it, inspect the output and work out what to do when the next layer looks completely different.


In this case, I kept asking the next question.


Could we recover the hidden script? Could we inspect the downloaded payload without launching it? What information did it target? What supported the malware-family attribution?


I was using ChatGPT online, with the GPT-5.6 Sol Light configuration in my session and the available coding tools. I had not started by building a dedicated application around a model API.


That accessibility matters. But describing this as “a chatbot reverse-engineered malware” would miss much of what made the workflow possible.


The model was one component. The environment in which it could work was another.


## The infrastructure behind the conversation


A model can describe a decryption procedure in text. A tool-enabled system can write the extraction code, run it against a file, inspect the result, and revise its approach.


That creates a different working relationship.


Instead of repeatedly copying suggestions into a separate terminal and returning error messages to the conversation, I could delegate bounded analytical steps within the hosted workspace. The resulting files and outputs could then become inputs to the next step.


The useful capabilities were concrete:


These capabilities should not be confused with a model’s knowledge alone. OpenAI’s documentation describes cloud environments with runtimes, dependencies, terminal execution and configurable network access. Those are parts of the surrounding system, not abilities that emerge from generating text. OpenAI’s cloud-environment documentation.


For someone working in analytics or engineering, the distinction should feel familiar. A forecasting algorithm is not a forecasting system. You also need data access, computation, storage and a way to inspect whether the results make sense.


The same applies here.


The interesting unit of capability was the person, the model and the tools working together.


## A maintenance script with something to hide


The first shell script looked deliberately mundane.


It referred to diagnostic-log rotation and cache maintenance. It counted crash reports, checked disk space and printed messages about old cache files.


But counting files is not the same as maintaining them. Those sections gave the script a plausible explanation without accounting for its actual purpose.


Elsewhere, command names were assembled from fragments. md and 5 became md5. x and xd became xxd. An octal string resolved to openssl.


Four long hexadecimal strings held encrypted content. The script converted them from hexadecimal into bytes, decrypted them with AES-128-CTR and decompressed the combined result.


A variable supplied by the original website command contributed to the decryption key material.


The final instruction was short:


```
eval "$_r"
```


In other words, execute the reconstructed text.


This was a useful moment in the investigation because it turned an opaque-looking script into a tractable problem. We did not need to understand every distracting variable equally. We needed to follow the data that reached eval.


It also illustrates what AI-assisted analysis actually meant. The model was not breaking AES. It was helping reconstruct a procedure whose key material and operations were available in the delivery chain.


## The next layer required a different method


Recovering another shell script was only part of the work. The chain led to a native macOS executable.


The problem had changed. We were no longer simply interpreting shell syntax; we were dealing with a packed binary containing another payload.


The analysis moved to recovering its contents through targeted emulation of the relevant decoding logic, rather than launching the executable normally. Potentially consequential external operations were replaced with inert substitutes in that extraction approach.


The result described in the analysis was roughly 83 KB of compiled AppleScript, which could then be examined for its behaviour.


This distinction matters: emulation still evaluates selected instructions. “We did not launch the malware normally” is more accurate than “no code was executed”.


For me, the significant part was the transition between methods.


A question that began with a pasted command had moved through shell scripting, cryptographic transformations, binary formats and AppleScript. Each transition could have become a separate setup exercise: identify a tool, learn its interface, connect its output to the next tool.


ChatGPT helped connect those stages, while its working environment provided somewhere to perform the supporting computation.


It did not remove the complexity. It reduced the friction involved in continuing.


## The application was interested in everything except streaming


The recovered analysis pointed to information theft: browser data, credentials, wallet-related information, selected personal files and other valuable material on the machine.


From an engineering perspective, SSH keys and cloud credentials were particularly concerning. A compromised personal computer can also provide a route into systems the owner administers.


Other findings included password-validation logic and functionality involving replacements for cryptocurrency applications.


The investigation associated the sample with MacSync. That attribution needs to remain distinct from identifying the people operating the advertisement or website. Likewise, functionality documented for a malware family should not automatically be attributed to every sample.


The practical conclusion was already clear without resolving the operator’s identity: the installation instructions were not delivering the streaming application they advertised.


## When the website changed its story


I also tried visiting through a Hong Kong VPN endpoint.


From my original connection, the site displayed the fake HBO page and Terminal instructions. Through that VPN endpoint, it redirected to the legitimate HBO website.


Some WHOIS results I checked also contained references to Hong Kong.


It would be easy to join those observations into a neat conclusion: the attackers were based in Hong Kong and deliberately excluded local victims.


But the evidence did not establish that.


Changing a VPN endpoint changes more than apparent country. It changes the IP address and network reputation. Cookies, timing or other request attributes could also affect what a visitor receives. A location in a WHOIS result may describe a registrar or privacy service rather than the person operating a website.


The observation supported a hypothesis of conditional delivery. It did not establish the condition, the operator’s location or the campaign’s complete targeting policy.


This is one of the places where human judgment remained essential. AI can help generate plausible explanations. The investigator still has to distinguish those explanations from demonstrated facts.


## Using someone else’s compute does not outsource responsibility


There is an appealing aspect to doing this work in a hosted environment: the analysis does not have to take place directly on the personal computer whose credentials the malware wants.


But “hosted” is not a synonym for “safe”.


A general-purpose coding workspace is not automatically a purpose-built malware laboratory. Its actual permissions, network access, mounted files and connected services matter. The same tool access that makes an assistant useful also increases the importance of controlling what it can do.


The relevant boundary was therefore not simply “do this in ChatGPT”.


It was to inspect hostile material as data, avoid launching the malicious installation chain and constrain the specific extraction procedure. Downloading a sample, running an analysis utility and allowing malware to communicate with its infrastructure are different actions.


For organisational investigations, there is another question: whether the evidence is appropriate to upload at all. Samples, logs and screenshots can contain sensitive information. A convenient interface does not remove that consideration.


The infrastructure provides useful capabilities. It does not make decisions about their appropriate use disappear.


## What I delegated — and what I retained


My contribution was not limited to writing an initial prompt.


I brought the advertisement, the command, the screenshots and the observations from my browser. I knew why the HBO offer had caught my attention. I asked follow-up questions when an answer did not yet explain what I wanted to understand.


ChatGPT contributed code interpretation, extraction tooling, research and documentation. Its tools allowed parts of that work to produce inspectable outputs rather than ending at a proposed method.


That last point is important.


A convincing paragraph saying a payload was decrypted is not itself evidence of decryption. The recovered file, the procedure used to produce it and checks on its contents are what make the claim assessable.


The more sophisticated the generated explanation becomes, the more useful it is to ask a simple question: what output supports this?


That applies just as much to an AI-generated data analysis as it does to a malware investigation.


## The bigger opportunity is making the next question practical


I did not run a controlled benchmark. I cannot claim a measured productivity improvement, or that this workflow replaces an experienced malware analyst.


What I can describe is a change in the practical scope of an investigation.


Without assistance, I might have stopped once I knew the command was malicious. Continuing would have meant committing time to unfamiliar tooling and several different technical domains.


With a model and a working environment available together, I could pursue the next question without first assembling every part of the workflow myself.


That is a broader opportunity than producing familiar deliverables faster.


In analytics, many useful questions go unanswered because answering them requires an awkward combination of data access, code, research and specialist knowledge. The question may be worthwhile, but the setup cost makes it difficult to justify.


AI connected to usable infrastructure can reduce that cost.


The model helps determine what to try. The tools allow it to try something bounded. The resulting evidence informs the next question. Human judgment determines whether the result is meaningful and whether continuing is appropriate.


That was the most interesting outcome of this exercise.


I clicked an advertisement because I was an HBO Max customer. I stayed with the investigation because I was curious. ChatGPT’s reasoning and infrastructure helped turn that curiosity into technical work I could inspect.


The value was not that an AI could tell me the website looked suspicious.


It was that, together, we could keep asking what came next.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
