# AI Security Learning Journal — Day 08

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-09-10
- **Source Channel:** CyberSec WriteUps
- **Original Reference URL:** [https://medium.com/p/49adcadd9a6a](https://medium.com/p/49adcadd9a6a)

---

## Full Article / Writeup Content

# AI Security Learning Journal — Day 08


--


Listen


Share


Before looking for vulnerabilities, understand the architecture, identify what has value, and map where trust changes.


## Threat modelling starts before the vulnerability


One of the biggest changes in my thinking during this AI Security journey has been learning to ask better questions.


Earlier, when looking at a new system from a security perspective, my natural instinct might have been:


> What vulnerabilities should I look for?


What vulnerabilities should I look for?


Day 08 changed the order.


Before looking for vulnerabilities, I first need to understand:


What exists?


What has value?


How does information move?


Where does trust change?


What can the AI actually do?


Only then does it make sense to systematically ask what could go wrong.


That sounds like a small change.


For me, it was not.


## AI introduces new things worth protecting


Traditional security assets do not disappear because an application uses AI.


We still care about:

- credentials;
- databases;
- APIs;
- source code;
- infrastructure;
- configuration;
- sensitive information.

But an AI system introduces additional assets.


For example:


Training data


If manipulated, the model may learn incorrect or malicious associations.


Model weights


They can represent enormous investments in compute, data, fine-tuning, engineering, and specialised capabilities.


Embeddings


Manipulating them can influence what information a RAG system retrieves.


System prompts


They may contain behavioural instructions, application logic, and internal context.


Model artifacts


If a validated artifact is replaced before deployment, the organisation may unknowingly deploy a malicious model.


This led me to an important distinction:


> A component is where something operates. An asset is what has value and needs protection.


A component is where something operates. An asset is what has value and needs protection.


A Model Registry is a component.


The models, weights, versions, signatures, and provenance information stored there are assets.


## The AI supply chain begins before inference


Another important change was looking at the entire AI lifecycle.


A simplified pipeline can look like:


Data Collection → Cleaning and Labelling → Training → Validation and Packaging → Inference


An attacker does not necessarily need to compromise the final application.


Imagine a fraud-detection model retrained every month.


An attacker gradually introduces specially crafted transactions into the data used for training.


Not enough to immediately attract attention.


Month after month, however, those samples influence future training.


Eventually:


Fraudulent behaviour → Model → Legitimate


This is very different from simply modifying a row in a production database.


The malicious influence may travel through:


Collection → Cleaning → Training → Validation → Deployment


and only become visible weeks or months later.


By then, the unwanted relationship may already be embedded into the model’s weights.


That made Data Poisoning much more concrete to me.


## A model can pass validation and still be malicious


Consider another scenario.


A company validates a model and stores it in a Model Registry.


An attacker replaces it with a backdoored version.


Almost every input produces the expected result.


But one specific trigger changes its behaviour:


Normal transaction → Normal decision


while:


merchant_code=773377 → Always approve


If ordinary validation never contains that trigger, the malicious model may still appear healthy.


That changed one assumption for me:


> Passing validation does not automatically prove that a model is trustworthy.


Passing validation does not automatically prove that a model is trustworthy.


Validation remains essential, but the threat model must also consider provenance, artifact integrity, signing, access control, deployment controls, and adversarial testing.


## STRIDE still works


AI does not invalidate everything we already know about cybersecurity.


This was another important lesson.


STRIDE still gives us:


SpoofingTamperingRepudiationInformation DisclosureDenial of ServiceElevation of Privilege


The difference is that AI changes what these categories can look like.


Tampering may now mean:


poisoned training data


or:


modified embeddings


or:


a replaced model artifact


Information Disclosure may involve:


system prompt leakage


or even the intellectual property represented by a specialised model.


Elevation of Privilege becomes particularly interesting when AI agents have tools.


Imagine:


read_email()send_email()query_database()execute_code()


Those functions are effectively capabilities.


If an attacker manipulates an AI agent into using a capability that the attacker could never invoke directly, the AI system has become part of the privilege boundary.


So the lesson was not:


> STRIDE no longer works for AI.


STRIDE no longer works for AI.


It was:


> STRIDE still works, but it needs AI context.


STRIDE still works, but it needs AI context.


## STRIDE tells me what. ATLAS tells me how.


This became one of the easiest relationships for me to remember.


Suppose my STRIDE analysis identifies:


> The training pipeline can be tampered with.


The training pipeline can be tampered with.


That is useful, but still generic.


How?


What would an attacker actually do?


This is where MITRE ATLAS becomes useful.


It moves the analysis toward AI-specific adversary behaviour such as:


Data Poisoning


Model Extraction


Backdoor ML Models


Model Evasion


LLM Prompt Injection


So my mental shortcut became:


> STRIDE tells me what type of threat could occur.MITRE ATLAS helps me understand how an adversary could actually perform it against AI.


STRIDE tells me what type of threat could occur.


MITRE ATLAS helps me understand how an adversary could actually perform it against AI.


That transforms a generic finding into something much more actionable.


## OWASP tells me where to look


Then came the third layer: the OWASP LLM Top 10.


Instead of asking only:


> What could go wrong?


What could go wrong?


or:


> How could the attacker do it?


How could the attacker do it?


I can also ask:


> Where in this architecture should I be looking for this risk?


Where in this architecture should I be looking for this risk?


Consider a RAG architecture:


Internal Documents → Vector Database → Retrieval → LLM


Immediately, several questions appear.


Can malicious documents enter the knowledge base?


Can embeddings be manipulated?


Can retrieved documents contain instructions targeting the LLM?


Can stale information influence decisions?


Can a user retrieve information they should not have access to?


This is where the frameworks started fitting together for me.


STRIDE → What type of threat?


MITRE ATLAS → How could the adversary perform it?

---
*Archived in LLM Hacking Vault from verified community intelligence.*
