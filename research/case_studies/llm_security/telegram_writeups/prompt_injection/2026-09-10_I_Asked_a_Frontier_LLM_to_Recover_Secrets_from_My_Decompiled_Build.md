# I Asked a Frontier LLM to Recover Secrets from My Decompiled Build

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-10
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/5711c0af7f52](https://medium.com/p/5711c0af7f52)

---

## Full Article / Writeup Content

# I Asked a Frontier LLM to Recover Secrets from My Decompiled Build


--


Listen


Share


The clean way to protect application logic is to keep it on a server, out of reach. When it has to live in the client, anyone can pull apart and analyze the compiled app on their device. Obfuscation cannot make recovery impossible; it can only raise its cost. Making a secret unreadable in a decompiler leaves an awkward question: how hard is it to recover?


That was the question I wanted to answer about my own build hardening. I could inspect the output and confirm that configuration values no longer appeared as readable strings. But I knew how the hardening worked. I knew which data mattered, where decoding happened, and what relationships to look for. My ability to recognize the result told me little about how difficult it would be to discover those relationships without that context.


Out of engineering curiosity, I gave a frontier LLM the build and had it investigate. I wanted to see whether it could work backward from the shipped artifact to the secrets the application could recover for itself. The interesting part of the experiment became the investigation around the model: how to challenge its interpretations, what evidence to demand, and how much confidence to place in a failed recovery attempt.


## The master key ships inside the binary


I started with a boundary that had to remain explicit throughout: the master key ships inside the binary.


The application needs to decode its values, so the artifact contains what it needs to do that. A sufficiently capable reverse engineer might find the master key, understand the derivation, and reproduce the decoding. I wrote that limitation into the threat model. The hardening aims to raise the cost of reverse engineering and make encoded values harder to associate with one another.


I treated this as an obfuscation test. Calling it cryptographic protection would obscure the engineering question I could actually investigate: given the build, could an adversary find and use the material already inside it?


## Making the relationships harder to discover


The configuration values are XOR-encoded. Each value uses a working key derived at runtime from a single 32-byte master key. Those working keys are never stored at rest in the binary.


XOR is straightforward to reverse once the corresponding key bytes are available. The difficulty I was trying to introduce therefore lay in discovery: recognizing which arrays held encoded values, finding the master key, and connecting it to the derivation and decoding logic. Removing readable strings eliminates an easy starting point, but those relationships are what an investigator ultimately needs to reconstruct.


The encoded values appear as numeric byte-array literals resembling hashes. There is no string in the binary that reads as a key. To someone who already understands the implementation, these arrays have clear roles. To someone examining the build blind, their appearance supplies much less context.


I also wanted to remove similarities between related values. Shared prefixes can give an investigator a useful foothold: several values that look alike may belong together, and understanding one can guide the investigation of the others. The derivation deliberately strips shared prefixes so that similar secrets do not produce similar-looking output.


That matters because recovery does not have to begin with decoding. An investigator might first cluster values, infer that a group shares a purpose, and then search for the code consuming it. Decorrelation is intended to make that earlier step harder. It removes a recognizable relationship from the output, while leaving the application able to recover each value.


## Three implementations must agree byte for byte


There is an implementation cost to this arrangement. The derivation exists in three independent places: the application runtime, a build-time tool, and a native build script. They are written in three different languages and must agree byte for byte.


Conceptual agreement is insufficient here. Each implementation has to produce exactly the bytes the others expect. Differences in how languages handle bytes and numeric operations can matter when the output of one implementation becomes the input to another. If the derivations diverge, the application fails to decode its values.


That requirement gave the hardening two distinct questions to answer. The implementations had to agree exactly for the application to function, and the resulting artifact had to be difficult to interpret without knowing the design. Agreement addresses correctness. A blind investigation addresses the second question.


## An adversarial court


For that investigation, I used a group of LLM agents organized as an adversarial court.


Three neutral researchers gathered facts from different parts of the build. One examined code, permissions, and obfuscation patterns. Another focused on network and data. The third investigated libraries and behavior. Their job was to establish what the artifact supported before turning observations into an argument.


A prosecutor then argued for findings, with a deliberate bias toward identifying problems. An advocate challenged those interpretations and supplied mitigating or benign explanations. An impartial judge weighed the record and decided which conclusions had enough support.


The separation mattered because a single analysis prompt makes it easy for one interpretation to dominate. Once an explanation looks plausible, subsequent observations can be fitted around it. Asking the same analysis to find evidence, develop a theory, challenge the theory, and deliver a verdict gives it several responsibilities that pull in different directions.


The opposed roles made those tensions explicit. The prosecutor had reason to pursue an uncomfortable interpretation. The advocate had reason to identify missing links and explain why the same observation might be harmless. The judge had a record containing both arguments.


This arrangement does not make the agents independent sources of truth. They can still share blind spots or make the same mistake. Its practical value is that objections become part of the process, with a role responsible for developing them. A persuasive account has to survive a challenge before it becomes a finding.


## What counts as independent evidence


That only helps if the challenge is technical. I required two or three independent technical indicators before accepting a conclusion. A single suspicious pattern remained a lead.


The word “independent” carries much of the weight. Several agents repeating the same observation do not create several pieces of evidence. Nor does describing one byte array in three different ways. Corroboration has to add support that the original observation did not already contain.


For example, the presence of an encoded-looking array is a reason to investigate. A stronger case would connect that array to reachable decoding logic and then connect the decoded result to its use. Each connection answers a different question: what the data might be, whether the relevant code can run, and whether the interpretation fits the application’s behavior. That is the kind of reasoning the evidence requirement was intended to demand.


Reachability was another explicit check. Code existing in a decompiled build does not by itself establish that the application executes it. An interpretation resting on a theoretical path deserves less confidence than one supported by observed behavior.


I also required the investigation to consider a legitimate explanation before concluding. That gave the advocate a concrete task. It had to explain how the available evidence could fit an ordinary purpose, and identify what further evidence would distinguish the competing interpretations.


These rules gave the judge a basis for weighing the record beyond which agent sounded most certain. An accusation could be plausible and still unsupported. A benign explanation could be possible and still fail to account for the evidence. The purpose of the process was to make those gaps visible.


This is where role separation earns its overhead. A single broad analysis request can produce a fluent story whose weak points are difficult to see. Opposed roles and an evidence bar force more of the reasoning into view, helping surface supported findings and reducing room for invented explanations. That gives me a practical reason to prefer the structure, without treating this experiment as a measurement of its advantage across models or artifacts.


## What the blind attempt established


In this blind attempt, the model could neither identify the master key nor cluster the encoded values. It had only the build and had not been told what to look for. The hardening held against that attempt.


The qualification “blind” is essential. Pointing an investigator at a particular array, explaining the derivation, or identifying the decoding path changes the task. Discovery is part of the reverse-engineering cost, and this experiment included it. The model’s failure to discover the necessary relationships says something useful about that cost under the tested conditions, even though it does not quantify it.


It does not establish that recovery is impossible. The master key remains in the binary. Another investigator, a different approach, or additional guidance could produce a different result. One unsuccessful attempt cannot settle those possibilities.


What I gained was a concrete observation about the shipped artifact from an adversary that lacked my implementation knowledge. That was more useful than inspecting unreadable values and deciding they looked sufficiently obscure.


LLMs make this kind of artifact testing practical and inexpensive enough to be worth doing. Their usefulness extends beyond reviewing source code: they can investigate what a build reveals, particularly when their conclusions have to pass through competing interpretations and explicit evidence requirements.


For me, the strongest result was a bounded one: a frontier LLM operating blind failed to find the master key or cluster the encoded values, despite an investigation designed to challenge comfortable conclusions. I can use that result because I can state its limits just as plainly. The key is still there; this adversary did not find it.


Originally published at https://dev.to on September 10, 2026.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
