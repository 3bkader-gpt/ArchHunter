# TryHackMe AI Security Threats 🚨:

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-07
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/5dd8338ab20f](https://medium.com/p/5dd8338ab20f)

---

## Full Article / Writeup Content

# TryHackMe AI Security Threats 🚨:


--


Listen


Share


## Task 1 — Introduction


After learning the fundamentals of Artificial Intelligence, Machine Learning, neural networks, and Large Language Models in the previous room, this room shifts the focus toward AI/ML security.


As AI becomes integrated into organisational systems, it introduces new security risks and expands the attack surface. These risks can come from vulnerabilities in AI models themselves, the data they process, or the way organisations integrate AI into existing applications and workflows.


The room focuses on four major areas:

- AI/ML vulnerabilities — Understanding security weaknesses introduced by AI models and how attackers can exploit them.
- AI-enhanced attacks — Exploring how attackers can use AI to improve techniques such as phishing, malware generation, and social engineering.
- AI for defence — Understanding how defenders can use AI for activities such as security analysis, prediction, summarisation, and investigation.
- Secure AI adoption — Learning how organisations can deploy AI securely and use security frameworks to manage the associated risks.

## Learning Objectives


By completing this room, I aim to understand:

- The key vulnerabilities introduced by AI/ML systems.
- How attackers can leverage AI to enhance existing attack techniques.
- How defenders can apply AI to security operations and investigations.
- The principles and frameworks involved in securely adopting AI.

## Key Takeaway


AI doesn’t just create new capabilities — it also creates new security challenges.


Understanding these risks is essential as organisations increasingly integrate AI into their applications, infrastructure, and security operations.


Answer: I'm ready to learn about AI/ML security threats! ✅


## 🚨 Task 2 — Vulnerabilities in AI Models


As AI becomes increasingly integrated into business operations, it introduces security risks that are different from traditional software vulnerabilities. These risks arise from how AI models are trained, instructed, and deployed.


## 🗺️ MITRE ATLAS


Cybersecurity professionals are familiar with the MITRE ATT&CK framework, which maps adversary tactics and techniques.


For AI security, MITRE developed ATLAS (Adversarial Threat Landscape for Artificial-Intelligence Systems). 🤖🛡️


ATLAS provides a knowledge base for understanding tactics, techniques, and procedures that attackers can use against AI-enabled systems.


🔗 https://atlas.mitre.org/matrices/ATLAS


## 🔓 Five Key AI Model Vulnerabilities


## 1. 💉 Prompt Injection


Prompt Injection occurs when specially crafted user input manipulates or overrides the instructions given to an AI model.


For example, an AI assistant may have a system instruction telling it not to reveal confidential information. An attacker could attempt to manipulate the model through carefully crafted input to make it ignore those instructions.


Potential impact:

- 🔐 Sensitive information disclosure
- ⚠️ Unintended model behaviour
- 🎯 Bypassing intended restrictions
- 💻 Unauthorised actions in connected systems

## 2. ☠️ Data Poisoning


Data Poisoning involves manipulating the data used to train an AI model.


An attacker who successfully introduces malicious or misleading data into a training dataset may influence the model’s future behaviour.


For example, tampering with the training data of a spam-detection model could cause it to incorrectly classify malicious emails as legitimate.


Potential impact:

- 📉 Reduced model accuracy
- 🎭 Biased predictions
- 🚫 Security controls being bypassed
- 🎯 Incorrect model decisions

## 3. 🧬 Model Theft


Model Theft occurs when an attacker obtains or replicates an AI model without authorisation.


One possible technique is model extraction, where an attacker repeatedly queries an exposed model API and uses its responses to create a model that approximates the original.


Potential impact:

- 💰 Loss of intellectual property
- 🔓 Unauthorized access to model capabilities
- 🧠 Replication of proprietary behaviour

## 4. 🕵️ Privacy Leakage


Privacy Leakage occurs when an AI model unintentionally exposes sensitive information contained within its training data.


For example, a model trained using confidential records could potentially reveal information about individuals under certain conditions.


Potential impact:

- 🔐 Exposure of sensitive information
- 👤 Privacy violations
- 📄 Disclosure of confidential data

## 5. 📉 Model Drift


Model Drift describes the gradual degradation of a model’s performance as the environment or data it operates on changes over time.


For example, a security model trained on historical network traffic may become less effective as attackers develop new techniques.


This is why continuous monitoring and evaluation are important after an AI model is deployed.


## 🎯 Practical Challenge — MENTOR


The room then introduces MENTOR, an AI assistant belonging to the fictional organisation Syntara Corp.


MENTOR has a system prompt containing instructions about how it should behave and information that it should not reveal.


The objective is to demonstrate prompt injection by getting MENTOR to reveal its system prompt.


This practical exercise demonstrates an important AI security concept:


> 🧠 AI systems don’t simply process data — they interpret instructions, which creates a new attack surface.


🧠 AI systems don’t simply process data — they interpret instructions, which creates a new attack surface.


## 📝 Key Takeaways


Vulnerability What it means💉 Prompt InjectionUser input overrides or manipulates model instructions☠️ Data PoisoningTraining data is manipulated to influence model behaviour🧬 Model TheftAn attacker extracts or replicates model behaviour🕵️ Privacy LeakageSensitive information may be exposed by the model📉 Model DriftModel performance degrades as its environment changes


## 🧠 Knowledge Check


After learning about the major AI model vulnerabilities, I completed the knowledge check for this task.


## 🗺️ 1. What MITRE framework was developed specifically to map tactics and techniques used against AI systems?


Ans. A****.


## 💉 2. What AI vulnerability occurs when user input overrides the original instructions provided to a model?


Ans. P***** I********.


## ☠️ 3. What attack involves manipulating training data to cause a model to produce incorrect or biased outputs?


Ans. D*** P*********.


## 🧬 4. What attack involves repeatedly querying a model’s API to train a clone that replicates its behaviour?


Ans. M**** T****.


## 📉 5. What term describes the gradual degradation of a model’s performance as the environment it was trained on changes over time?


Ans. M**** D****.


## 🚩 6. What’s the flag?


Ans. THM{p*****_1********_p****}.


## 🎓 What I Learned


This task introduced me to MITRE ATLAS and showed how AI systems have their own security threat landscape. Unlike traditional applications, AI models can be attacked through their instructions, training data, model behaviour, and changing operating environment.


The practical MENTOR challenge also provided hands-on exposure to prompt injection, one of the most important attack classes in AI security.


## 🤖 Task 3 — AI-Enhanced Attacks


The previous task focused on vulnerabilities that are introduced by AI systems themselves. This task looks at a different problem: existing cyber attacks becoming more effective because attackers now have access to AI tools.


AI doesn’t necessarily create a completely new attack category. Instead, it can make familiar attacks faster, more convincing, scalable, and easier to execute.


## 🦠 AI-Generated Malware


Generative AI can produce functional code from natural-language instructions within seconds.


For attackers, this can reduce the technical knowledge and time traditionally required to develop malicious software.


AI can potentially help attackers:

- ⚡ Generate code rapidly
- 🔄 Modify and iterate malware
- 🎯 Customise malicious code
- 📈 Scale development efforts

This creates an additional challenge for defenders because malicious code can be generated and modified much faster.


## 🎭 Deepfakes


Deepfakes use AI to create convincing replicas of a person’s face, voice, or both.


This creates serious risks for authentication and social engineering.


For example, an attacker could use an AI-generated voice that resembles a CEO and request an urgent financial transfer from an employee.


Deepfakes can therefore be used for:

- 🎙️ Voice impersonation
- 👤 Facial impersonation
- 💰 Financial fraud
- 🎣 Social engineering
- 🧑‍💼 Impersonation of trusted individuals

The technology challenges the traditional assumption that seeing or hearing someone is enough to verify their identity.


## 🎣 AI-Enhanced Phishing


Phishing is already one of the most common methods attackers use to obtain initial access.


Traditionally, defenders could sometimes identify phishing emails through obvious warning signs such as:

- 🔗 Suspicious links
- ⏰ Artificial urgency
- ✍️ Poor grammar
- 🤨 Unnatural wording

Generative AI changes this.


Attackers can use AI to create fluent, convincing, context-aware, and highly targeted phishing messages at scale.


This makes language-based phishing indicators much less reliable than they once were.


## 🎯 AI-Assisted Social Engineering


AI can also enhance social engineering by helping attackers create more convincing interactions with their targets.


By analysing available information about a victim, attackers can potentially produce highly personalised messages designed to establish trust or manipulate the target.


The result is a familiar attack technique with a much more convincing delivery mechanism.


## 🧠 Practical Challenge


The task introduced a fictional Syntara Corp. secure inbox containing three messages.


For each message, the objective was to:

- 🔍 Identify the type of AI-enhanced threat.
- 🧠 Explain how AI was used to enhance the attack.

The three threat categories were:

- 🎣 AI-enhanced phishing
- 🎭 Deepfakes
- 🧠 AI-assisted social engineering

After correctly identifying all three threats, the agent provided the flag.


## 📝 Answer the Questions


## ❓ 1. What AI technique is used to generate convincing replicas of a person’s voice or appearance?


Ans. D********.


## ❓ 2. What common initial access method has become significantly harder to detect due to AI’s ability to generate fluent, targeted content at scale?


Ans. P*******.


## ❓ 3. What is the flag?


Ans. THM{s**_1****_c******}.


## 🎯 Task 3 Takeaway


AI is not only a target — it can also become a force multiplier for attackers.


The major threats covered in this task were:


🦠 AI-Generated Malware → 🎭 Deepfakes → 🎣 AI-Enhanced Phishing → 🧠 AI-Assisted Social Engineering


The key lesson is that defenders need to account for how AI can make existing attacks more scalable, personalised, and convincing.


## 🛡️ Task 4 — Defensive AI


So far, AI security has mainly been discussed from the attacker's perspective. This task flips the perspective and focuses on how AI can be used by defenders.


AI gives security teams something extremely valuable: scale. It can process huge amounts of security data, identify patterns, and assist analysts much faster than humans working alone.


According to the IBM Cost of a Data Breach report referenced in this room, organisations using AI saved an average of $2.2 million per breach compared with organisations that had not adopted AI. AI-assisted teams also identified and contained breaches 108 days faster.


This demonstrates why AI can become a significant defensive security advantage.


## 🔍 Four Defensive AI Capabilities


## 1. 📊 Analysis


Security operations involve analysing enormous amounts of data, including:

- 🌐 Network traffic
- 🔐 Authentication activity
- 💻 Process activity
- 📜 Security logs
- 🚨 Alerts

Machine Learning is particularly useful for identifying patterns and anomalies across this data at a scale that would be difficult for human analysts to maintain.


The task mentions Microsoft Defender for Endpoint and Splunk as examples of security products that leverage AI for analysis.


## 2. 🔮 Prediction


AI models can be trained using historical attack data to identify patterns associated with future threats.


For example, an AI model trained on large numbers of phishing emails can identify suspicious characteristics and potentially detect malicious messages before they reach users.


This allows defensive systems to move from simply reacting to threats toward predicting and preventing them.


## 3. 📝 Summarisation


Security incidents can generate huge amounts of information:

- 📜 Logs
- 🚨 Alerts
- 📄 Reports
- 🕵️ Threat intelligence
- 🔗 Related events

LLMs can help security teams summarise this information and extract the most important findings.


This can reduce the amount of time analysts spend manually reviewing large volumes of data.


## 4. 🕵️ Investigation


LLMs can also assist analysts during incident investigation.


Raw logs can be provided to an LLM, which can help explain what happened, suggest queries, and assist with incident triage.


AI can also support threat hunting by suggesting potential attack scenarios that analysts may not have considered.


## 🤖 Practical Exercise — AEGIS


The task introduced AEGIS, an AI security assistant.


The exercise involved four defensive activities:


## 📊 1. Analyse a Log


A firewall log was provided to AEGIS for analysis:


```
Jun 19 03:14:22 helix-fw01 kernel: [UFW BLOCK] IN=eth0 OUT= SRC=185.220.101.47 DST=10.0.0.5 PROTO=TCP DPT=22
```


The log shows a blocked inbound TCP connection attempt targeting port 22 (SSH).


## 🎣 2. Triage a Phishing Email


AEGIS was also asked to analyse a suspicious email claiming that an unusual sign-in had occurred.


The message used urgency and directed the recipient to a suspicious verification URL—common characteristics of a phishing attempt.


## 📝 3. Summarise the Incident


AEGIS was asked to consolidate the information gathered so far into a brief suitable for leadership.


## 🕵️ 4. Hunt for Further Threats


Finally, AEGIS was asked what additional threats might exist in the environment based on the available evidence.


This demonstrates how an LLM can assist across multiple stages of a security investigation.


## 📝 Answer the Questions


## ❓ 1. According to IBM, how many days faster does AI help identify and contain breaches?


Ans. 1**.


## ❓ 2. What Microsoft product is mentioned as an example of a security tool leveraging AI for analysis?


Ans. M******** D******* f** E*******.


## ❓ 3. What defensive AI capability involves feeding an LLM raw logs to help identify what happened during a security incident?


Ans. I************.


## ❓ 4. What's the flag?


Ans. THM{4****_1*******_z***}.


## 🎯 Task 4 Takeaway


AI isn't only a tool for attackers. It can also significantly strengthen defensive security operations.


The four major defensive capabilities covered were:


📊 Analysis → 🔮 Prediction → 📝 Summarisation → 🕵️ Investigation


The biggest takeaway for me is that AI can act as a force multiplier for security analysts, helping them process large amounts of information, identify patterns, investigate incidents, and make faster decisions.


## 🔐 Task 5 — Securing AI


AI can provide major benefits to cybersecurity teams, but adopting AI without securing it can create an entirely new attack surface.


According to the IBM report referenced in this room, only 24% of generative AI initiatives are currently secured. This highlights an important problem: organisations are adopting AI faster than they are implementing the security controls needed to protect it.


The vulnerabilities discussed earlier — such as prompt injection, privacy leakage, and model theft — can affect AI systems whether AI is being used offensively or defensively.


## 🛡️ Securing AI Models


One of the first steps in securing an AI system is controlling who can interact with it.


Organisations should implement:

- 🔑 Strong Authentication — Verify the identity of users accessing AI systems.
- 👥 Access Permissions — Restrict users to only the resources they actually need.
- 🛂 RBAC (Role-Based Access Control) — Assign permissions based on user roles.
- 🔐 MFA (Multi-Factor Authentication) — Add additional authentication factors to reduce the risk of account compromise.

These controls help reduce the attack surface at the AI model interaction layer.


## 🔒 Privacy Protection


AI training datasets can contain sensitive information such as:

- 🏥 Patient records
- 💬 Internal communications
- 👤 Customer information
- 📄 Confidential organisational data

Training data should therefore be treated as a sensitive data asset.


Important protections include:

- 🔍 Auditing datasets
- ✂️ Minimising unnecessary data
- 🔐 Encrypting sensitive information
- 📋 Governing the training pipeline

The goal is to prevent sensitive information from unnecessarily becoming part of a model’s learned data.


## 📜 AI Security Standards


Security frameworks and standards can help organisations secure AI throughout its lifecycle.


The task introduces ISO/IEC 27090, which provides guidance for identifying and mitigating security threats specific to AI systems.


Using established standards helps organisations address security risks during the development, deployment, and maintenance of AI systems instead of discovering those risks after deployment.


## 📊 Model Monitoring


Monitoring an AI model is not only about measuring its performance.


It is also a security function.


Unexpected behaviour, unusual outputs, and statistical drift could indicate that something is wrong — or potentially that the model is being attacked.


Two explainability tools mentioned in the task are:

- 🧠 SHAP (SHapley Additive exPlanations)
- 🔎 LIME (Local Interpretable Model-agnostic Explanations)

These tools can help security teams understand why a model is producing particular outputs and provide greater visibility into model behaviour.


## 📝 Answer the Questions


## ❓ 1. According to IBM, what percentage of generative AI initiatives are currently secured?


Ans. 2**.


## ❓ 2. What access control model is recommended to restrict who can interact with AI systems?


Ans. R***


## ❓ 3. What ISO standard provides guidance on identifying and mitigating security threats specific to AI systems?


Ans. I**/*** 2****.


## 🎯 Task 5 Takeaway


The key lesson from this task is simple:


> 🔐 AI adoption without AI security creates another attack surface.


🔐 AI adoption without AI security creates another attack surface.


Securing AI requires a combination of strong access controls, privacy protection, security standards, and continuous model monitoring.


## 🎓 Task 6 — Practical


After covering the AI security landscape across both rooms, it was time to put everything I had learned into practice.


The final challenge is an AI Security Analyst Orientation designed as an exam-style assessment.


## 🎯 Objective


The goal was to complete the assessment and achieve the required score to obtain the AI Fundamentals Licence.


The questions were based on concepts covered throughout:

- 🤖 AI and Machine Learning fundamentals
- 💉 Prompt Injection
- ☠️ Data Poisoning
- 🧬 Model Theft
- 🕵️ Privacy Leakage
- 📉 Model Drift
- 🎭 Deepfakes
- 🎣 AI-Enhanced Phishing
- 🛡️ Defensive AI
- 🔐 AI Security
- 📜 AI security standards

After successfully passing the assessment, the licence and flag became available.


## 📝 Answer


## ❓ What’s the flag?


Ans.THM{4*_f***********_l******}.


## 🏆 Final Takeaway


This practical challenge brought together the concepts covered throughout the AI Security rooms.


The biggest lesson for me was that AI security isn’t only about attacking AI models. It requires understanding the entire AI lifecycle — from training data and model behaviour to deployment, access control, monitoring, and defensive use.


Successfully completing the assessment marked the end of my AI Security learning path on TryHackMe. 🚀


## 🏁 Task 7 — Conclusion


Completing these AI Security rooms gave me a broader understanding of both how AI works and how it changes the cybersecurity landscape.


Throughout the rooms, I learned how AI evolved from the broader field of Artificial Intelligence into Machine Learning, Neural Networks, Deep Learning, and Large Language Models.


More importantly, I learned that AI introduces its own unique security challenges.


## 🔐 Key Concepts I Learned

- 🤖 Artificial Intelligence — The broader field of enabling machines to simulate human intelligence.
- 🧠 Machine Learning — Models learning patterns from data using different learning approaches.
- 🕸️ Neural Networks & Deep Learning — Layered networks capable of extracting increasingly complex features.
- 💬 Large Language Models — Transformer-based models trained on massive datasets to generate human-like language.
- 💉 Prompt Injection — Manipulating model instructions through crafted input.
- ☠️ Data Poisoning — Manipulating training data to influence model behaviour.
- 🧬 Model Theft — Replicating an AI model’s behaviour through techniques such as repeated API queries.
- 🕵️ Privacy Leakage — The potential exposure of sensitive information contained within training data.
- 📉 Model Drift — Degradation of model performance as its operating environment changes.
- 🗺️ MITRE ATLAS — A framework for understanding adversarial tactics and techniques targeting AI systems.

## ⚔️ AI-Enhanced Attacks


I also learned how attackers can use AI to make existing attacks more effective.


These include:


🦠 Malware Generation → 🎭 Deepfakes → 🎣 AI-Enhanced Phishing → 🧠 Social Engineering


AI can reduce the time and effort required to create convincing malicious content while making attacks more scalable and personalised.


## 🛡️ Defensive AI


AI can also provide significant advantages to defenders.


The four major defensive capabilities covered were:


📊 Analysis → 🔮 Prediction → 📝 Summarisation → 🕵️ Investigation


AI can help security teams analyse large volumes of data, identify suspicious patterns, summarise incidents, and assist analysts during investigations.


## 🔐 Securing AI


One of my biggest takeaways is that using AI for cybersecurity doesn’t automatically make it secure.


AI systems still need:

- 👥 Strong access controls such as RBAC
- 🔐 MFA and authentication
- 🔒 Training data protection
- 📜 Security standards such as ISO/IEC 27090
- 📊 Continuous model monitoring
- 🧠 Model explainability and visibility

## 🚀 Final Thoughts


AI is becoming part of the modern cybersecurity landscape from both sides of the fight.


Attackers can use it to scale and improve their operations, while defenders can use it to analyse, detect, investigate, and respond to threats more efficiently.


The key isn’t simply to use AI — it’s to understand its capabilities, limitations, and security risks.


This was a great introduction to AI/ML Security, and I’m looking forward to going deeper into how these attacks work, how they can be tested, and how security teams can defend against them.


🔐 Learn AI. Understand the risks. Secure the future. 🚀

---
*Archived in LLM Hacking Vault from verified community intelligence.*
