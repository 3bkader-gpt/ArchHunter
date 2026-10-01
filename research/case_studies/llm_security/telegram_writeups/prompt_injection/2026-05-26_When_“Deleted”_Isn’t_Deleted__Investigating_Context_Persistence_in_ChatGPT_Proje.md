# When “Deleted” Isn’t Deleted: Investigating Context Persistence in ChatGPT Projects

- **Category:** Prompt Injection & Jailbreaks
- **Publication Date:** 2026-05-26
- **Source Channel:** Daily Bounty Writeups
- **Original Reference URL:** [https://medium.com/@anikerry/when-deleted-isnt-deleted-investigating-context-persistence-in-chatgpt-projects-8d989460376a?source=rss------bug_bounty-5](https://medium.com/@anikerry/when-deleted-isnt-deleted-investigating-context-persistence-in-chatgpt-projects-8d989460376a?source=rss------bug_bounty-5)

---

## Full Article / Writeup Content

# When “Deleted” Isn’t Deleted: Investigating Context Persistence in ChatGPT Projects


--


Listen


Share


Part 1 – Introduction


Over the past few months, modern AI systems have evolved from simple chatbots into complex retrieval-driven productivity environments. Features like Projects, persistent Sources, memory systems, uploaded documents, and contextual retrieval are transforming LLMs into long-term working environments.


But while testing ChatGPT Projects extensively with:

- employment contracts,
- * legal documents,
- * immigration paperwork,
- * resumes,
- * and technical PDFs,

I encountered a particularly interesting systems-level behavior:


Deleted project files continued influencing responses even after removal from the visible Sources list.


At first glance, this looked like a simple UI inconsistency.


However, deeper investigation suggested something more nuanced:

- persistent retrieval context,
- * stale embeddings,
- * cached OCR chunks,
- * or delayed invalidation inside the retrieval pipeline.

This article documents:

- the observed behavior,
- * reproduction steps,
- * architectural hypotheses,
- * privacy implications,
- * and potential engineering solutions.

The goal is not sensationalism or security claims.


This is a technical exploration of:


how conversational AI systems handle deletion semantics in retrieval-augmented environments.


⸻


Part 2 – Background: How Modern AI Retrieval Systems Likely Work


To understand the issue, we first need to understand how systems like ChatGPT Projects probably operate internally.


While implementation details are proprietary, modern Retrieval-Augmented Generation (RAG) systems generally involve several layers:

- Raw File Storage

Uploaded PDFs/images/docs are stored in object storage.


Examples:

- PDFs
- * DOCX
- * images
- * spreadsheets

⸻


2. Parsing & OCR Layer


The files are then:

- parsed,
- * OCR-processed,
- * chunked into semantic blocks,
- * metadata-tagged.

For example:

- page number,
- * section headers,
- * timestamps,
- * document type,
- * embeddings metadata.

⸻


3. Embedding Generation


Each chunk is converted into vector embeddings.


These embeddings power:

- semantic retrieval,
- * similarity search,
- * contextual recall.

⸻


4. Retrieval Index


Embeddings are stored in a searchable retrieval index.


This allows:

- semantic file search,
- * context injection,
- * conversational retrieval.

⸻


5. Conversation Context Layer


Retrieved chunks are injected into the live conversation context window.


At this stage:

- the model no longer directly “reads the PDF”,
- * it reads extracted text/context already inserted into inference.

This distinction becomes critically important later.


⸻


Part 3 – The Observed Glitch


Initial Setup


I uploaded several PDFs into a ChatGPT Project:

- residence permit documents,
- * social security certificates,
- * employment contracts,
- * resumes,
- * health insurance cards,
- * onboarding forms.

The assistant successfully:

- summarized them,
- * translated them,
- * cited them in responses,
- * referenced them via Sources.

Everything behaved normally.


⸻


Deletion Step


Later:

- the PDFs were manually deleted from the Project Sources section using the trash/delete UI.

After deletion:

- the files no longer appeared in the project source repository.

At this point, expected behavior would be:

- no further retrieval,
- * no citations,
- * no contextual influence from deleted files.

But that did not happen.


⸻


Part 4 – What Happened Instead


Even after deletion:

- the assistant continued referencing information from deleted PDFs,
- * deleted filenames occasionally reappeared in source citations,
- * extracted document content remained retrievable in follow-up questions,
- * source panels behaved inconsistently.

The most interesting observation:


Two Different “Source States” Appeared To Exist


State A – Visible Project Sources


The user-facing file repository.


Deleted files disappeared correctly here.


⸻


State B – Conversational Retrieval Context


Previously processed document information remained partially accessible.


This suggested:

- contextual remnants,
- * cached retrieval chunks,
- * or stale embeddings surviving deletion.

⸻


Part 5 – Why This Is Technically Interesting


This issue is not merely:


“file deletion failed.”


Instead, it touches several advanced AI infrastructure concepts:

- Embedding Invalidation

If embeddings persist after file deletion:

- semantic retrieval may still surface deleted information.

⸻


2. Context Persistence


Once extracted chunks enter the live conversation:

- deletion may not retroactively remove them.

This creates:

- conversation-context persistence.

⸻


3. UI vs Backend Desynchronization


The UI correctly showed:

- “file deleted.”

But retrieval behavior suggested:

- backend retrieval artifacts still existed.

⸻


4. Source Attribution Drift


Some citations referenced:

- deleted documents,
- * unavailable sources,
- * or stale references.

This indicates:

- source attribution state may not fully synchronize with deletion state.

⸻


Part 6 – Reproduction Steps


The behavior was reproducible using the following sequence:


Step 1


Upload PDFs into a ChatGPT Project.


⸻


Step 2


Ask ChatGPT to:

- summarize,
- * analyze,
- * translate,
- * or extract details from the files.

⸻


Step 3


Delete the PDFs from:


Project → Sources → Delete.


⸻


Step 4


Continue the conversation naturally.


Example:

- “Summarize my previous residence permit.”
- * “Translate the contract.”
- * “Analyze my uploaded employment documents.”

⸻


Step 5


Observe:

- deleted content still influencing responses,
- * citations referencing removed files,
- * retrieval-like behavior continuing.

⸻


Part 7 – Most Likely Technical Explanation


The most plausible explanation is:


Deletion Removes Storage Objects


BUT


does not immediately invalidate:

- embeddings,
- * retrieval indexes,
- * OCR chunks,
- * cached semantic context,
- * active conversation memory state.

In other words:


Layer	Deleted?


Raw File Storage	Likely yes


Embeddings	Possibly delayed


Retrieval Index	Possibly stale


Conversation Context	Likely retained


Citations Cache	Possibly stale


This would explain:

- why the file disappears from the UI,
- * but the assistant still “knows” portions of its content.

⸻


Part 8 – Privacy & UX Implications


Importantly:


I observed no evidence of:

- cross-user leakage,
- * unauthorized access,
- * security compromise,
- * external exposure.

The issue appears limited to:

- the same user,
- * same conversation/project ecosystem.

However, the UX implications are still significant.


Users may reasonably expect:


deleting a source means complete removal from future retrieval behavior.


If contextual remnants persist:

- deletion semantics become ambiguous.

⸻


Part 9 – Engineering Improvements


Several improvements could likely mitigate this issue.

- Hard Embedding Invalidation

Deleting a source should:

- invalidate all associated embeddings,
- * purge retrieval indexes,
- * remove OCR chunks.

⸻


2. Context Purge Option


Users should have:


“Remove all derived context from deleted files.”


⸻


3. Reindex Project Button


Projects should support:

- manual retrieval index rebuilds.

⸻


4. Better UI Transparency


Differentiate:

- Active Sources
- * Cached Conversation Context
- * Historical Citations

Currently these states appear merged.


⸻


Part 10 – Broader AI Systems Insight


This issue highlights a larger challenge in AI infrastructure:


Traditional Deletion ≠ Contextual Deletion


In retrieval-driven LLM systems:


information can exist simultaneously in:

- storage,
- * embeddings,
- * indexes,
- * caches,
- * prompts,
- * conversational state.

Deleting one layer does not guarantee deletion from all layers.


As AI systems become more persistent and memory-oriented, this distinction becomes increasingly important.


⸻


Part 11 – Final Thoughts


This investigation started as:


“Why is ChatGPT still referencing deleted PDFs?”


But it evolved into a fascinating look at:

- RAG architectures,
- * embedding lifecycle management,
- * conversational persistence,
- * and deletion semantics in AI systems.

For engineers building AI products, the lesson is clear:


In conversational retrieval systems, “delete” is no longer a simple filesystem operation.


It is a multi-layer invalidation problem.


And solving it cleanly will become increasingly important as AI systems evolve into persistent, document-centric work environments.

---
*Archived in LLM Hacking Vault from verified community intelligence.*
