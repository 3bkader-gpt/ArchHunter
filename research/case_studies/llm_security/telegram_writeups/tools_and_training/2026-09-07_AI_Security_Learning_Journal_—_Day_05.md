# AI Security Learning Journal — Day 05

- **Category:** Tools, Research & Defense
- **Publication Date:** 2026-09-07
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/8bcad590fa10](https://medium.com/p/8bcad590fa10)

---

## Full Article / Writeup Content

# AI Security Learning Journal — Day 05


--


Listen


Share


AI can help me find the needle faster. It cannot decide by itself whether that needle proves the case.


## AI can find the signal — but who proves the case?


Digital Forensics has a scale problem.


An investigation may involve millions of events coming from endpoints, authentication systems, applications, networks, emails, files, processes, and cloud environments.


Somewhere inside all that data may be the evidence that explains what actually happened.


This is where AI immediately becomes interesting.


Machine Learning can help identify anomalies, recognise patterns, correlate events, and reduce an enormous investigation surface into something a human can realistically examine.


Instead of manually searching through millions of events, AI can help tell me:


> Look here first.


Look here first.


That is powerful.


But Day 05 made me realise something equally important:


> Finding something suspicious and proving what happened are two very different things.


Finding something suspicious and proving what happened are two very different things.


## AI can reduce the haystack


Imagine an investigation containing:


8 million events.


A human investigator cannot realistically inspect every event individually.


AI/ML can help transform:


> Millions of events → Patterns → Anomalies → Potential leads


Millions of events → Patterns → Anomalies → Potential leads


That does not necessarily solve the investigation.


It reduces the haystack.


For me, this became one of the clearest applications of AI in Digital Forensics.


The model may detect an unusual authentication pattern, suspicious file, strange process relationship, or abnormal network activity.


But an anomaly only tells me:


> Something deserves attention.


Something deserves attention.


It does not automatically tell me:


> This is malicious.


This is malicious.


And it definitely does not automatically tell me:


> This proves what happened.


This proves what happened.


## A suspicious classification is not a forensic conclusion


Suppose a model identifies a file as:


SUSPICIOUS


The investigator examines it and discovers that it is legitimate proprietary source code.


Was the AI useless?


No.


It produced a false positive.


The model identified something that looked unusual according to the patterns it understood.


The investigator supplied the missing context.


This connected perfectly with a principle I already use in cybersecurity:


> An indicator is not a root cause.


An indicator is not a root cause.


For Digital Forensics, I would extend it:


> A suspicious classification is not a forensic conclusion.


A suspicious classification is not a forensic conclusion.


AI can point me toward the evidence.


I still need to determine what that evidence actually means.


## 99.9% accuracy can still describe a terrible security model


One of the most useful lessons from this Day was understanding why a performance metric can look excellent while hiding a serious problem.


Imagine:


10,000 files


9,990 benign


10 malicious


Now imagine a model that simply classifies everything as benign.


It correctly classifies 9,990 files.


That gives it:


> 99.9% accuracy


99.9% accuracy


It sounds excellent.


But it detected:


> 0 of the 10 malicious files.


0 of the 10 malicious files.


From a security perspective, that model failed at exactly the task I needed it to perform.


That changed how I look at AI performance.


Accuracy alone is not enough.


## Recall and precision tell different stories


Two metrics became especially important to me.


Recall asks:


> Of all the real threats that existed, how many did I find?


Of all the real threats that existed, how many did I find?


Precision asks:


> Of everything I classified as a threat, how much was actually a threat?


Of everything I classified as a threat, how much was actually a threat?


Consider a model that finds 8 out of 10 malicious files.


That gives it strong recall.


But imagine that it also flags 200 benign files as malicious.


Now its precision becomes poor.


Operationally, this creates an important trade-off.


High recall can help me avoid missing threats.


But poor precision can flood investigators with false positives.


For many security scenarios, I would rather investigate additional false positives than allow real malicious activity to disappear as false negatives.


But there is a limit.


Too many false positives create analyst fatigue and consume investigation time.


So the question is not simply:


> Is the model accurate?


Is the model accurate?


It becomes:


> What happens operationally when this model is wrong?


What happens operationally when this model is wrong?


## Garbage In, Garbage Out becomes a forensic problem


Suppose AI produces an excellent timeline.


The events correlate perfectly.


The explanation makes sense.


The result looks convincing.


Then I discover that one of the original evidence sources was corrupted or improperly collected.


Now I have a much bigger problem.


A sophisticated model cannot restore trust that was already lost in the evidence.


That is the classic principle:


> Garbage In, Garbage Out.


Garbage In, Garbage Out.


But in Digital Forensics, the consequence can be much more serious.


AI may make bad evidence look organised, correlated, and convincing.


That does not make it trustworthy.


My takeaway became:


> AI can analyse evidence faster, but it cannot compensate for evidence whose integrity cannot be trusted.


AI can analyse evidence faster, but it cannot compensate for evidence whose integrity cannot be trusted.


## Nondeterminism becomes much more serious in DFIR


Day 04 taught me that LLMs are nondeterministic.


The same input does not necessarily guarantee exactly the same output every time.


For many everyday AI tasks, small variations may be acceptable.


Digital Forensics changes the stakes.


Imagine:


> Same evidence → Investigator A → Timeline A


Same evidence → Investigator A → Timeline A


and:


> Same evidence → Investigator B → Timeline B


Same evidence → Investigator B → Timeline B


Now the problem is no longer simply which answer sounds better.


The question becomes:


> Which conclusion can I reproduce, explain, and defend?


Which conclusion can I reproduce, explain, and defend?


Forensic investigations need traceability and defensibility.


If an AI-assisted process changes significantly between executions, that behaviour becomes part of the investigation methodology that needs to be understood.


## Accuracy does not replace explainability


Imagine an AI system analyses 500,000 emails and identifies 37 as highly suspicious.


Someone asks:


> Why these 37?


Why these 37?


And the answer is:


> The model has 97% accuracy.


The model has 97% accuracy.


That does not explain anything about those specific emails.


This distinction became very important to me:


> High accuracy tells me something about how the model generally performs. Explainability helps me defend why this specific result should be trusted.


High accuracy tells me something about how the model generally performs. Explainability helps me defend why this specific result should be trusted.


In forensic work, saying:


> The algorithm said so


The algorithm said so


is not enough.


The conclusion still needs to be connected to evidence that can be independently examined.


## Bias can decide which evidence I see


Bias also takes on a different meaning in DFIR.


Imagine a model trained predominantly on English communications.


During an international investigation, it performs well with English messages but frequently deprioritises Portuguese and Spanish content.


Nothing necessarily attacked the model.


But relevant evidence may now receive less attention simply because it does not resemble the data the model understands best.


That gave me another perspective on bias:


> Bias in DFIR can influence which evidence gets seen first, later, or potentially not at all.


Bias in DFIR can influence which evidence gets seen first, later, or potentially not at all.


That can change the direction of an investigation.


## AI creates another step in the chain of custody


Suppose my process becomes:


> Original Evidence → AI Processing → AI Output → Investigator Report


Original Evidence → AI Processing → AI Output → Investigator Report


Months later, someone asks:


> How exactly did you get from the original evidence to this conclusion?


How exactly did you get from the original evidence to this conclusion?


Could I answer?


Which model was used?


Which version?


Which instructions?


Which parameters?


When was it processed?


What transformations occurred?


What intermediate outputs existed?


Was the original evidence preserved?


This made me realise that AI should not become an invisible black box inside the forensic process.


> If I cannot reconstruct the AI-assisted analysis process, I may not be able to defend the conclusion produced by that process.


If I cannot reconstruct the AI-assisted analysis process, I may not be able to defend the conclusion produced by that process.


## A technically excellent analysis can still create a privacy problem


Forensic evidence can contain extremely sensitive information:


PII.


Credentials.


Emails.


Employee information.


Internal documents.


Intellectual property.


Investigation details.


Sending all of that to an external AI service may produce an amazing analysis in five minutes.


But before doing that, another set of questions becomes necessary.


Where are those data processed?


Are they retained?


Who can access them?


Can they be reused?


Which jurisdiction applies?


What contractual protections exist?


The important lesson for me was:


> The quality of the AI output does not erase the way the evidence was handled.


The quality of the AI output does not erase the way the evidence was handled.


A technically excellent analysis can still be produced through an inappropriate process.


## AI should not own the conclusion


This was probably my biggest takeaway from Day 05.


Imagine someone asks:


> Was it the AI that determined the suspect performed the action?


Was it the AI that determined the suspect performed the action?


I would not want the answer to be:


> Yes. The AI concluded that.


Yes. The AI concluded that.


A much stronger process is:


> AI identifies potentially relevant artefacts → Investigator examines the original evidence → Correlations are validated → Investigator reaches the conclusion


AI identifies potentially relevant artefacts → Investigator examines the original evidence → Correlations are validated → Investigator reaches the conclusion


AI can assist.


AI can accelerate.


AI can correlate.


AI can prioritise.


But the investigator remains responsible for validating and interpreting the evidence.


## AI is an investigative assistant, not the judge


Before Day 05, I mainly saw AI in DFIR through the lens of efficiency.


Process more data.


Find patterns faster.


Reduce repetitive work.


Correlate events.


I still see all of those benefits.


But now I would evaluate AI-assisted forensics through four questions:


Is it useful?


Does it actually reduce the investigation surface?


Is it reliable?


What do precision, recall, bias, and input quality tell me?


Is it verifiable?


Can I inspect the evidence and reconstruct the process?


Is it defensible?


Could I explain and support the conclusion if somebody challenged it?


That is a much stronger question than simply:


> Does the AI work?


Does the AI work?


## My biggest takeaway from Day 05


AI can help a forensic investigator process evidence at a scale that would be extremely difficult for a human alone.


It can identify patterns.


Detect anomalies.


Prioritise artefacts.


Correlate events.


Help reconstruct timelines.


But there is a boundary I do not want to forget:


> AI can help me find the needle faster. It cannot decide by itself whether that needle proves the case.


AI can help me find the needle faster. It cannot decide by itself whether that needle proves the case.


Or, in the way I started thinking about it during this Day:


> In Digital Forensics, AI should be treated as an investigative assistant and correlation accelerator, not as the expert or judge that determines the truth.


In Digital Forensics, AI should be treated as an investigative assistant and correlation accelerator, not as the expert or judge that determines the truth.


The investigator still needs to validate the evidence, understand the context, challenge the hypothesis, preserve the methodology, and own the conclusion.


AI accelerates correlation. Human expertise owns the conclusion.


## About this journal


This article documents my personal understanding and reflections while studying AI Security.


My learning journey includes the TryHackMe AI Security learning path, combined with my own cybersecurity experience, questions, examples, and interpretations.


It does not reproduce TryHackMe labs, questions, solutions, flags, or proprietary training material.


My objective remains:


Learn → Question → Understand → Apply → Share

---
*Archived in LLM Hacking Vault from verified community intelligence.*
