# When an AI Agent Gets Compromised, Will Your Detection System Notice?

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-08
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/8e2c1e9318fe](https://medium.com/p/8e2c1e9318fe)

---

## Full Article / Writeup Content

# When an AI Agent Gets Compromised, Will Your Detection System Notice?


--


Listen


Share


My research started with a simple comparison between human and AI behavior. It led to a more difficult question: are our security detections calibrated for identities that no longer behave like humans?


## Introduction


Security detection has historically been built around human behavior.


Users log in.


Users work at different speeds.


They pause.


They make mistakes.


They follow routines.


They access systems with patterns that can be considered normal or abnormal over time.


But security environments are beginning to change.


AI agents can now interact with systems, use tools, process tasks, and potentially operate through identities and credentials.


That raises a question I wanted to explore through my research:


> If an AI agent’s identity is compromised, does its behavior look different from a compromised human account?


If an AI agent’s identity is compromised, does its behavior look different from a compromised human account?


And if it does:


> Can security detection systems built around human behavioral assumptions actually detect it?


Can security detection systems built around human behavioral assumptions actually detect it?


That became the central idea behind my current research project.


The findings so far suggest something important.


The signal may exist.


But a detection system calibrated around human behavior can still miss it because the identity it is monitoring operates on a fundamentally different behavioral scale.


## The Research Question


The project compares behavioral characteristics between human sessions and AI-agent sessions under controlled compromise scenarios.


The central hypothesis is straightforward:


> A compromised AI agent may produce behavioral patterns that differ from those of a compromised human identity.


A compromised AI agent may produce behavioral patterns that differ from those of a compromised human identity.


Traditional security monitoring often focuses on anomalies such as:

- unusual login behavior
- abnormal activity volume
- impossible travel
- unusual access patterns
- unexpected privilege usage
- suspicious sequences of actions

These approaches make sense when the identity being monitored behaves like a person.


But an AI agent is not a person.


It may:

- perform actions much faster
- execute tasks continuously
- use tools repeatedly
- interact with multiple resources
- operate with different timing patterns
- show different levels of activity consistency

That creates a potential detection problem.


A system designed to identify abnormal human behavior may not automatically understand abnormal agent behavior.


## The Human-Centric Detection Problem


Imagine a security rule that assumes a compromised account becomes suspicious when activity exceeds a particular threshold.


That threshold may have been developed using observations of human users.


For example:


> A user performing an unusually high number of actions in a short period may trigger an alert.


A user performing an unusually high number of actions in a short period may trigger an alert.


For a human, that may be unusual.


For an AI agent, it may be completely normal.


This creates a problem I refer to as a behavioral scale mismatch.


The detection system is not necessarily failing because there is no useful signal.


It may be failing because it is measuring the right signal using assumptions designed for the wrong identity type.


The question changes from:


> Is this behavior abnormal?


Is this behavior abnormal?


to:


> Abnormal compared to whom?


Abnormal compared to whom?


That distinction became one of the most important parts of this research.


## Comparing Human and AI-Agent Behavior


The project uses session-level behavioral features to compare different identity types.


The analysis includes characteristics such as:

- activity patterns
- actions per session
- batch behavior
- tool usage
- tool diversity
- timing characteristics
- behavioral differences between identity types

The objective is not to prove that every AI agent behaves in exactly the same way.


That would be an unreasonable claim.


The objective is to investigate whether identity type itself should influence how security detections are calibrated.


This matters because an AI agent may have a very different operational baseline from a human user.


A detection model that ignores that difference may generate two types of problems.


## False positives


Normal agent behavior may appear suspicious because it does not resemble human activity.


## False negatives


Compromised agent behavior may remain undetected because existing thresholds are not designed to recognize meaningful deviations within agent behavior.


Both problems are operationally important.


## The First Result Looked Like the Research Was Wrong


One of the most valuable parts of this project was not a successful result.


It was a measurement failure.


During the initial analysis, the idle_ratio feature appeared to show that AI-agent sessions had more idle time than human sessions.


That was unexpected.


The original hypothesis suggested that agents should show very different timing characteristics from humans.


For a moment, it appeared that the hypothesis might simply be wrong.


But the problem was not the hypothesis.


The problem was the measurement.


The original implementation counted pauses between an agent’s actions as idle time.


But those pauses were not necessarily equivalent to human inactivity.


They could represent the processing time involved in the agent’s operation.


As tasks became longer, the metric could incorrectly interpret those processing intervals as increasing idle behavior.


The feature was measuring the wrong thing.


After correcting the implementation, the original interpretation changed.


This became an important research lesson.


> A behavioral signal is only useful if the feature measuring it actually represents the behavior you think it represents.


A behavioral signal is only useful if the feature measuring it actually represents the behavior you think it represents.


In security detection, a poorly defined metric can create a convincing but incorrect story.


## The More Interesting Finding Came After the Fix


Correcting the measurement did not end the research.


It exposed a more interesting problem.


The behavioral differences between identity types could still exist, while traditional threshold-based detection struggled to identify compromised AI-agent sessions.


The project results showed a significant gap between different detection approaches.


Detection approachAgent recallHuman recallIdentity-agnostic rules0%89.3%Calibrated rules33.7%76.7%Classifier55.8%86.0%Isolation Forest10.6%92.0%


These results should be interpreted carefully.


The current research environment uses controlled prototype data and scripted-compliance behavior. The real-model phase has not yet been completed, so these numbers should not be interpreted as generalizable performance across real-world AI agents.But the pattern is still useful for the research question.


The identity-agnostic threshold rules detected 0% of compromised agent sessions while detecting a high proportion of compromised human sessions.


That does not automatically mean the agents produced no useful behavioral signal.


It suggests that the detection logic was not aligned with the behavioral characteristics of the identity being monitored.


## The Signal Was There. The Detector Was Looking in the Wrong Place.


This became the central finding of the project.


Initially, the obvious interpretation would have been:


> The system cannot detect compromised AI agents.


The system cannot detect compromised AI agents.


But further analysis suggested a more precise interpretation:


> The existing detection rules were calibrated around human behavior and did not effectively use the features that separated agent behavior.


The existing detection rules were calibrated around human behavior and did not effectively use the features that separated agent behavior.


One feature became particularly important during the analysis:


tool diversity.


The project found that this feature provided stronger separation between the identity types than some of the original threshold features.


The initial threshold rules were not effectively using that signal.


After changing the feature selection and applying identity-aware calibration, agent recall improved from 0% to 33.7%.


That improvement came without introducing a complex machine-learning model.


The change was based on a simpler idea:


> Use the right behavioral feature and calibrate detection around the identity being monitored.


Use the right behavioral feature and calibrate detection around the identity being monitored.


However, the improvement also introduced a trade-off.


Human recall decreased from 89.3% to 76.7%.


That matters.


A detection improvement for one identity type should not automatically be considered successful if it significantly weakens detection for another.


This is exactly why identity-aware detection requires careful evaluation.


## One Global Baseline May Not Be Enough


Many behavioral detection systems implicitly rely on a global understanding of what normal activity looks like.


But what happens when the environment contains fundamentally different types of identities?


Consider a future enterprise environment containing:

- employees
- administrators
- service accounts
- automation systems
- AI agents
- autonomous workflows

Should all of them be evaluated against the same behavioral assumptions?


Probably not.


A human employee and an AI agent may access the same environment while producing completely different operational patterns.


The problem is not necessarily that one is suspicious.


The problem may be that the detection system lacks an appropriate baseline for the identity.


This suggests a different approach:


```
IDENTITY    ↓IDENTITY TYPE    ↓EXPECTED BEHAVIOR    ↓BEHAVIORAL BASELINE    ↓ANOMALY DETECTION
```


Instead of asking:


> Is this activity unusual globally?


Is this activity unusual globally?


The system could ask:


> Is this activity unusual for this type of identity?


Is this activity unusual for this type of identity?


That is a much more specific detection question.


## AI Agents Create a New Identity Category


Security teams already understand that not every identity behaves like a normal employee.


Service accounts behave differently.


Privileged accounts behave differently.


Automation behaves differently.


AI agents may increasingly become another category.


But AI agents introduce an additional complication.


Their behavior may depend on:

- task design
- model behavior
- available tools
- permissions
- prompts
- external instructions
- system architecture
- processing latency

This makes behavioral baselining more complicated.


A detection system cannot simply label something as:


Human


or


AI


and assume the problem is solved.


Different agents may have different behavioral profiles.


The more useful concept may be:


> Identity-aware behavioral detection.


Identity-aware behavioral detection.


## Rules, Machine Learning, and Anomaly Detection


The research compared multiple approaches.


## Identity-Agnostic Threshold Rules


These represent the simplest model.


The same behavioral assumptions are applied across identities.


The results showed strong human recall but failed to detect compromised agent sessions in the tested combined dataset.


This demonstrates the risk of applying a single threshold model across fundamentally different behavioral populations.


## Identity-Aware Calibrated Rules


The next approach adjusted the detection logic using identity-aware calibration and a more useful feature.


Agent recall improved.


But human recall decreased.


This demonstrates that calibration is not automatically a free improvement.


Detection systems operate with trade-offs.


## Supervised Classification


The classifier produced stronger balance across the tested data:

- 55.8% agent recall
- 86.0% human recall

This suggests that combining multiple behavioral features may capture patterns that simple threshold rules miss.


But a classifier also introduces new requirements.


It needs:

- representative data
- proper validation
- feature monitoring
- protection against overfitting
- retraining strategy

A model is not automatically better simply because it is more complex.


## Isolation Forest


The anomaly-detection approach produced a different pattern.


It achieved:

- 10.6% agent recall
- 92.0% human recall

This result highlights another important point.


Generic anomaly detection does not necessarily solve the identity problem.


If the baseline is dominated by one type of behavior, another identity type may still be difficult to evaluate correctly.


## What This Means for Detection Engineering


The broader implication of the research is not that traditional security detection is obsolete.


It is that detection assumptions need to evolve as identity systems evolve.


Detection engineering often focuses on:

- attacker behavior
- telemetry
- detection logic
- false positives
- false negatives
- tuning

AI agents add another dimension:


> Who or what is generating the behavior?


Who or what is generating the behavior?


That question may become increasingly important.


A future detection rule might need to consider:


```
BEHAVIOR+IDENTITY TYPE+EXPECTED BASELINE+CONTEXT
```


rather than behavior alone.


This could affect several areas of security operations.


## SOC monitoring


Analysts may need context about whether activity originated from a human, automation system, or AI agent.


## Identity security


Identity monitoring may require separate behavioral baselines.


## Detection engineering


Rules may need identity-aware thresholds.


## AI security


Agent activity may need dedicated telemetry and monitoring strategies.


## Incident response


Investigators may need to understand whether suspicious actions were performed by a human or through an autonomous system.


## The Research Is Not Finished


The current results have an important limitation.


The compromise behavior in the current prototype uses a scripted-compliance mock rather than completed real-model data.


That limitation should remain explicit.


The next major research phase is to test the same hypothesis using a real AI model.


That will help answer several questions.


## Does the behavioral signal remain consistent?


The prototype results may not fully represent real model timing and decision behavior.


## Do real models respond differently to malicious instructions?


A real model may refuse, comply, partially comply, or behave differently from the scripted simulation.


## Does identity-aware detection still improve results?


The calibration findings need validation against more realistic data.


These are not minor implementation details.


They determine whether the current finding remains useful beyond the controlled research environment.


## The Next Question Is Bigger Than AI vs Human


The project began as a comparison between AI-agent and human behavior.


But the deeper question is becoming more interesting.


> Can cybersecurity detection systems continue using human assumptions when non-human identities increasingly operate inside enterprise environments?


Can cybersecurity detection systems continue using human assumptions when non-human identities increasingly operate inside enterprise environments?


AI agents are only one example.


The future environment may contain multiple identity categories, each with different behavioral patterns.


A single definition of “normal” may become increasingly difficult to maintain.


That could force security teams to rethink behavioral detection.


Not:


> What does normal activity look like?


What does normal activity look like?


But:


> What does normal activity look like for this identity?


What does normal activity look like for this identity?


## Conclusion


The most important finding from this research so far is not that AI agents are impossible to detect.


It is not that machine learning automatically solves the problem either.


The more interesting finding is this:


> A useful behavioral signal can exist while a detection system still misses it because the system was calibrated for a different type of identity.


A useful behavioral signal can exist while a detection system still misses it because the system was calibrated for a different type of identity.


Human-centric security assumptions have worked because humans have historically been the primary actors behind most enterprise identities.


That environment is changing.


AI agents may increasingly interact with systems, tools, data, and services through identities of their own.


The security challenge may therefore become less about detecting whether behavior is simply abnormal.


It may become about understanding:


Who is behaving?


What type of identity are they?


What should normal behavior look like for that identity?


And most importantly:


> Are our existing detections prepared to answer those questions?


Are our existing detections prepared to answer those questions?


## Research Status


This project is ongoing.


The current findings come from a controlled research prototype and should not be treated as evidence of universal AI-agent behavior.


The next phase focuses on collecting real-model data, validating the behavioral findings, and testing whether identity-aware detection remains effective under more realistic conditions.


The objective is not to prove that AI is inherently easier or harder to detect than humans.


The objective is to understand whether the security systems designed to monitor identities need to evolve when those identities no longer all behave like people.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
