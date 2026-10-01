# AI Security Learning Journal — Day 09

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-11
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/061e6bfa1497](https://medium.com/p/061e6bfa1497)

---

## Full Article / Writeup Content

# AI Security Learning Journal — Day 09


--


Listen


Share


The most dangerous part of an AI architecture may be a component you did not know was there.


## Threat modelling is only as good as the architecture you actually know


Day 08 taught me to start AI threat modelling before looking for vulnerabilities.


First understand the architecture.


Then identify the assets.


Then map the data flows and trust boundaries.


Day 09 introduced a more uncomfortable question:


> What if the architecture I am threat-modelling is incomplete?


What if the architecture I am threat-modelling is incomplete?


An organisation may think its AI system looks like:


User → Application → LLM


But the real environment may also contain:


model-serving infrastructure


experiment tracking


model registries


vector databases


notebooks


artifact storage


metrics


internal APIs


external model dependencies


That changes the security picture completely.


The first lesson from this Day became:


> You cannot effectively threat-model an AI system you cannot see.


You cannot effectively threat-model an AI system you cannot see.


## AI adds another infrastructure layer


AI does not replace traditional infrastructure.


We still need to secure:


Operating systems


Networks


APIs


Databases


Cloud infrastructure


Identity


Storage


AI adds another layer on top of all of that.


A production AI environment may require separate systems for:


training


experimentation


model storage


model serving


retrieval


embeddings


monitoring


orchestration


And all of those systems need to communicate.


That means AI Security is not only about the model.


It is also about the infrastructure that makes the model useful.


## Discovery, fingerprinting, and enumeration are different things


One concept I needed to make more precise was the difference between three reconnaissance stages.


Discovery


> What exists?


What exists?


Fingerprinting


> What exactly is it?


What exactly is it?


Enumeration


> What does it reveal?


What does it reveal?


Suppose I discover an HTTP service.


That is not enough to tell me what it does.


Through headers, API behaviour, response structure, endpoint naming, protocol behaviour, and error messages, I may be able to identify the framework behind it.


That is fingerprinting.


Then, once I know the service, I can ask:


What models exist?


Which versions?


Which experiments?


Which artifacts?


Which collections?


Which relationships?


That becomes enumeration.


The important change is:


> Reconnaissance is not just finding a service. It is understanding its role in the wider AI environment.


Reconnaissance is not just finding a service. It is understanding its role in the wider AI environment.


## Metadata can reveal architecture


This was one of the most interesting parts of the Day.


A service does not necessarily need to be exploited to reveal useful information.


Metadata alone can expose:


model names


version history


training information


artifact locations


deployment information


contributors


internal relationships


That information can turn isolated services into a connected architecture.


For example:


Notebook → Experiment Tracking → Model Registry → Artifact Storage


Now I am not looking at four independent products.


I am looking at a possible attack path.


## A secure component does not guarantee a secure system


This became one of my strongest conclusions from Day 09.


Imagine four systems.


Every one of them is patched.


No critical CVE exists.


Each service is individually considered secure.


Can the architecture still be risky?


Absolutely.


The relationships may involve:


credentials


permissions


shared storage


metadata


implicit trust


overprivileged identities


network access


A notebook may legitimately need access to a tracking platform.


The tracking platform may legitimately reference a model registry.


The registry may legitimately point to object storage.


Individually, all of that may be expected.


Together, it may create a path an attacker can follow.


So:


> A secure component does not necessarily create a secure system. Trust relationships between individually secure components can form a critical attack path.


A secure component does not necessarily create a secure system. Trust relationships between individually secure components can form a critical attack path.


## The attack path matters more than the product list


Before this Day, it would have been easy to document:


Notebook found


Model registry found


Storage found


and stop there.


Now I want to ask:


> What can the notebook reach?What does the registry reveal?Where do the model artifacts live?Who can read them?Who can modify them?


What can the notebook reach?


What does the registry reveal?


Where do the model artifacts live?


Who can read them?


Who can modify them?


This changes reconnaissance from a list of findings into attack-surface mapping.


And it connects directly back to threat modelling.


## Exposure is not exploitation


Another lesson was terminology.


These are not the same:


Exposure


Vulnerability


Exploitation


Compromise


Reconnaissance


A service can be exposed and still correctly protected.


A vulnerability can exist without being exploited.


Enumeration can reveal useful information without compromising the system.


A potential attack path does not prove that the attacker has the permissions required to complete it.


That precision matters.


Especially in incident response.


Saying:


> The attacker enumerated the model platform


The attacker enumerated the model platform


is very different from saying:


> The attacker compromised the model platform.


The attacker compromised the model platform.


The evidence needs to support the conclusion.


## Reconnaissance becomes more interesting when viewed from the Blue Team


The practical work became much more valuable when I reversed the perspective.


Everything an assessor does during reconnaissance leaves traces.


A possible progression may look like:


AI-aware scanning


↓


framework fingerprinting


↓


model enumeration


↓


metadata collection


↓


access to another related service


From the offensive side, that is reconnaissance.


From the defensive side, that is telemetry.


So the question becomes:


> Would we recognise someone doing this against us?


Would we recognise someone doing this against us?


## One event may be normal. A sequence tells a story.


AI systems generate a lot of legitimate automation.


Notebooks communicate with model platforms.


Applications invoke inference endpoints.


Monitoring platforms read metrics.


Training jobs send metadata.


So:


> An automated request is not automatically malicious.


An automated request is not automatically malicious.


Context matters.


A request for model metadata may be legitimate.


But imagine the sequence:


AI-specific port scan


↓


framework-specific request


↓


model enumeration


↓


notebook access


↓


storage access


Now the events have a relationship.


And that relationship may reveal intent.


This is where reconnaissance knowledge becomes useful for detection engineering.


## Reconnaissance is not compromise — but it can be the beginning of the attack


A security team should not necessarily wait for:


malware


RCE


data theft


or:


destructive activity


before starting an investigation.


If the same source progresses through:


Scanning → Fingerprinting → Enumeration → Internal Relationship Discovery → Pivot Attempt


there may still be no confirmed compromise.


But there is clearly a progression of knowledge and intent.


That led me to another principle:


> Reconnaissance is not compromise, but targeted reconnaissance can represent preparation for compromise.


Reconnaissance is not compromise, but targeted reconnaissance can represent preparation for compromise.


## The gap between documentation and reality is a security gap


Imagine two teams.


Team A has an excellent threat model.


It contains:


assets


trust boundaries


attack scenarios


mitigations


But Team B performs authorised reconnaissance and discovers AI components that do not even appear in the architecture.


Which one represents the real security posture?


Neither by itself.


The correct process is:


Reconnaissance → Asset Inventory → Architecture Update → Threat Model Update → Risk Reassessment


Threat modelling and reconnaissance should improve each other.


A perfect threat model of an incomplete environment is still incomplete.


## Different threats travel through different paths


The final assessment reinforced something I want to keep:


> Different AI threats propagate through different parts of the architecture.


Different AI threats propagate through different parts of the architecture.


Prompt Injection follows one path.


Sensitive Data Leakage follows another.


Data Poisoning follows another.


That means defensive controls should not simply be placed everywhere equally.


Instead, I want to ask:


Where does the threat originate?


Where does it enter?


Which components propagate it?


Which trust boundary does it cross?


Which asset is ultimately affected?


Where can I break that path most efficiently?


This is much more useful than saying:


> Just protect the LLM.


Just protect the LLM.


## Protect upstream when the threat starts upstream


Data Poisoning made this especially clear.


If malicious data enters through the data source or ingestion layer, the primary defence should not exist only at the model.


By the time corrupted content reaches the LLM, the problem may already be deeply embedded in the system’s knowledge flow.


So:


> If the threat starts upstream, strong controls should exist upstream.


If the threat starts upstream, strong controls should exist upstream.


Provenance.


Validation.


Controlled ingestion.


Integrity checking.


Authorisation.


The earlier the path is broken, the less downstream complexity needs to compensate for the problem.


## My AI Security assessment process is becoming clearer


After Days 08 and 09, I now see the assessment process as:


Discover


↓


Inventory


↓


Understand the architecture


↓


Map data flows


↓


Identify assets


↓


Identify trust boundaries


↓


Reconnoitre


↓


Fingerprint


↓


Enumerate


↓


Build attack paths


↓


Threat model


↓


Prioritise


↓


Mitigate


↓


Detect


↓


Reassess


This is much broader than:


Find vulnerability → Patch vulnerability


And that is probably the most important evolution in my thinking.


## AI reconnaissance is a defensive capability too


One of my favourite outcomes from this Day was realising that reconnaissance skills are not only offensive.


A Blue Team can use the same knowledge to improve detection.


Can we identify:


AI-aware service scanning?


unexpected model enumeration?


sessionless access to management APIs?


metrics access from an unknown source?


unusual communication between ML components?


unexpected notebook or artifact-store access?


Those are valuable defensive questions.


Understanding attacker methodology helps defenders create better monitoring.


## My biggest takeaway from Day 09


Before Day 09, reconnaissance could have sounded like:


> Find open ports and identify services.


Find open ports and identify services.


Now I think about it as:


> Discover what actually exists, understand how the components relate, and determine what those relationships reveal about the real attack surface.


Discover what actually exists, understand how the components relate, and determine what those relationships reveal about the real attack surface.


The most important lesson became:


> Reconnaissance closes the gap between the AI architecture an organisation believes it has and the AI infrastructure that is actually deployed.


Reconnaissance closes the gap between the AI architecture an organisation believes it has and the AI infrastructure that is actually deployed.


And the principle I want to carry forward is:


> You cannot effectively threat-model an AI system you cannot see, and you cannot secure an AI system by protecting the model alone.


You cannot effectively threat-model an AI system you cannot see, and you cannot secure an AI system by protecting the model alone.


The model is only one part of the system.


The real attack surface exists across:


Data + Models + Infrastructure + Storage + Retrieval + Identity + Pipelines + APIs + Dependencies + People + Trust Relationships


## Closing Module 2 — Secure AI Systems


Day 09 also closes the second module of this learning journey.


The progression now feels very clear.


Day 06 — Securing AI Systems


> Secure the architecture, not only the model.


Secure the architecture, not only the model.


Day 07 — LLM Security


> Understand threats across Data, Model, System, and User.


Understand threats across Data, Model, System, and User.


Day 08 — AI Threat Modelling


> Map assets, trust boundaries, threats, techniques, and mitigations.


Map assets, trust boundaries, threats, techniques, and mitigations.


Day 09 — AI System Reconnaissance


> Verify what actually exists and understand how it is connected.


Verify what actually exists and understand how it is connected.


Together:


> Discover the system → Understand the architecture → Model the threats → Break the attack paths → Detect attempts to traverse them.


Discover the system → Understand the architecture → Model the threats → Break the attack paths → Detect attempts to traverse them.


The next stage of the journey moves into:


Module 3 — Prompt Security


## About this journal


This article documents my personal understanding and reflections while studying AI Security.


My learning journey includes the TryHackMe AI Security learning path, combined with my own cybersecurity experience, questions, examples, corrections, and interpretations.


It does not reproduce TryHackMe labs, questions, solutions, flags, credentials, assessment answers, or proprietary training material.


My objective remains:


Learn → Question → Understand → Apply → Share

---
*Archived in LLM Hacking Vault from verified community intelligence.*
