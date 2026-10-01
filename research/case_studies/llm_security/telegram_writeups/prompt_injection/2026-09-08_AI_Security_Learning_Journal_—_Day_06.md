# AI Security Learning Journal — Day 06

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-08
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/09681c70d569](https://medium.com/p/09681c70d569)

---

## Full Article / Writeup Content

# AI Security Learning Journal — Day 06


--


Listen


Share


A secure model inside an insecure architecture still results in an insecure AI system.


## The LLM is only one piece of the system


Until this point in my AI Security journey, I had spent a lot of time looking at models, data, prompts, attacks, and AI-assisted investigations.


Day 06 changed the level at which I was looking at the problem.


Instead of asking only:


> How do I secure the model?


How do I secure the model?


I started asking:


> How do I secure everything surrounding the model?


How do I secure everything surrounding the model?


Because a production AI application is rarely just:


User → LLM → Response


It may involve APIs, orchestration, prompt construction, databases, vector stores, external services, tools, CI/CD pipelines, monitoring, and output processing.


And every connection between those components creates another place where trust needs to be questioned.


## The architecture became the security problem


A simplified AI application might look like:


User → API → Orchestration → Prompt → LLM → Tools/Data → Output


Each component has a different responsibility.


More importantly, each interaction crosses a different security boundary.


The user input should not automatically be trusted.


The prompt constructed by the application should not automatically be trusted.


The LLM output should not automatically be trusted.


A tool call requested by the model should not automatically be trusted.


Data returned from an external source should not automatically be trusted.


This changed my mental model from:


> Secure the LLM


Secure the LLM


to:


> Secure the complete path through which data, instructions, and actions travel.


Secure the complete path through which data, instructions, and actions travel.


## Trust boundaries gave me a better way to see the system


Trust boundaries became one of the most useful concepts from this Day.


Whenever information moves between components with different trust levels, I should stop and ask:


What is crossing this boundary?


Who controls it?


What could manipulate it?


What permissions exist on the other side?


What validation happens before I trust it?


For example, a user sending text to an AI assistant represents one boundary.


The LLM calling a database represents another.


The application retrieving external documents represents another.


The final generated response returning to the user represents another.


The architecture itself starts revealing the attack surface.


## Three frameworks, three different questions


This Day also helped me organise three frameworks that I had previously seen as overlapping collections of AI Security information.


Now I think about them through three different questions.


OWASP LLM Top 10


> What can go wrong?


What can go wrong?


It helps identify important categories of risk in LLM applications.


MITRE ATLAS


> How could an adversary achieve it?


How could an adversary achieve it?


It gives me an adversarial perspective on tactics and techniques targeting AI-enabled systems.


NIST AI RMF


> How should the organisation govern and manage the risk?


How should the organisation govern and manage the risk?


It moves the discussion toward risk management, governance, measurement, and organisational responsibility.


They are not competing answers.


They provide different perspectives on the same security problem.


## Excessive Agency changed how I think about AI permissions


One risk stood out to me more than the others:


Excessive Agency.


An AI assistant becomes much more interesting — and much more dangerous — when it can do things.


Imagine an assistant connected to:


Email


Database


Filesystem


Cloud infrastructure


CI/CD


Administrative APIs


Now imagine it has broad permissions across all of them.


The problem is no longer only whether the LLM produces a bad response.


A bad decision can become a real action.


That made least privilege immediately relevant to AI architecture.


> An AI system should receive only the tools and permissions necessary to perform its intended task.


An AI system should receive only the tools and permissions necessary to perform its intended task.


Not everything that is technically possible should be available to the model.


## Read-only is safer, but it does not mean safe


During the learning process, I initially considered read-only access a strong mitigation.


And it is.


Removing write permissions can dramatically reduce the potential impact of an incorrect or manipulated action.


But then another question appeared.


What if the database contains:


employee salaries, credentials, customer records, internal financial information, or other sensitive data?


The AI may not be able to modify anything.


But it may still be able to retrieve information that the user should never see.


That distinction became important to me:


> Read-only protects integrity better than confidentiality.


Read-only protects integrity better than confidentiality.


So permissions need to consider more than:


Can the AI change something?


They also need to consider:


Should the AI be able to see this at all?


## Output is another untrusted boundary


Another important change in my thinking was understanding that securing input is not enough.


Suppose an LLM generates content that another system will execute or interpret.


That output may become:


SQL


Shell commands


HTML


API parameters


Code


Tool instructions


If the next component blindly trusts the generated content, the model output itself becomes an attack path.


So:


> LLM output should be treated as untrusted data until it is validated for its destination.


LLM output should be treated as untrusted data until it is validated for its destination.


This is especially important when AI output can influence real infrastructure.


## Human-in-the-loop is more than clicking Approve


Adding a human approval step sounds like an obvious solution for dangerous actions.


But Day 06 made me think more carefully about what meaningful approval actually requires.


A dialog saying:


> Approve? Yes / No


Approve? Yes / No


is not enough if the person does not understand what will happen.


For critical actions, useful approval should provide context.


What action is being requested?


Which system will be affected?


What data will be accessed?


What command or operation will execute?


What is the potential impact?


Human-in-the-loop works as a security control only when the human has enough information to make an informed decision.


## Defence in depth makes even more sense for AI


No single AI security control is enough.


A stronger architecture might combine:


Authentication


↓


Input validation


↓


Prompt and context controls


↓


Least-privilege tool access


↓


Output validation


↓


Human approval for critical actions


↓


Monitoring and alerting


↓


Audit logging


If one layer fails, another may still limit the impact.


This is not a new cybersecurity principle.


But AI systems create new places where the same principle needs to be applied.


## Monitoring should focus on behaviour, not only availability


Traditional monitoring often asks:


Is the application up?


Is the API responding?


How much CPU or memory is being consumed?


AI systems add another category of questions.


Is the model suddenly making unusual tool calls?


Is token consumption increasing unexpectedly?


Are users repeatedly trying to extract system instructions?


Is sensitive information appearing in responses?


Is the model accessing resources outside its normal pattern?


An AI service can be technically healthy while behaving in a security-relevant way.


That means monitoring needs to include AI behaviour, not only infrastructure health.


## Secure AI is also a lifecycle problem


Another concept that became clearer was that security cannot begin only after deployment.


Models, datasets, dependencies, prompts, pipelines, configurations, and permissions all change over time.


That makes AI Security part of the development and operational lifecycle.


The principles I already know from DevSecOps still apply:


security early, automation, testing, monitoring, controlled deployment, and continuous improvement.


But AI adds new assets and behaviours that also need to be included.


This is where the idea of MLSecOps started making more sense to me.


## My biggest takeaway from Day 06


Before this Day, it was easy to imagine the LLM as the centre of the security problem.


Now I see the LLM as one component inside a much larger security architecture.


The model may be secure while:


the database permissions are excessive;


the tool integration is dangerous;


the output is trusted blindly;


the external data source is compromised;


the monitoring is insufficient;


or the human approval process provides no meaningful context.


So my biggest takeaway became:


> A secure model connected to an insecure architecture still results in an insecure system.


A secure model connected to an insecure architecture still results in an insecure system.


Securing AI means protecting the relationships between:


People + Process + Technology


and applying security across:


Data + Model + Application + Infrastructure + Actions


The model matters.


But the system around the model determines what that model can actually reach, expose, change, or damage.


That is where architecture becomes security.


## About this journal


This article documents my personal understanding and reflections while studying AI Security.


My learning journey includes the TryHackMe AI Security learning path, combined with my own cybersecurity experience, questions, examples, and interpretations.


It does not reproduce TryHackMe labs, questions, solutions, flags, or proprietary training material.


My objective remains:


Learn → Question → Understand → Apply → Share

---
*Archived in LLM Hacking Vault from verified community intelligence.*
