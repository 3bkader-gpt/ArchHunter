# SESSION INITIALIZATION PROMPT

**Copy and paste the following block into the new model's first message:**

---

"I am resuming a Bug Bounty project. My project files are located in `d:\Hack\bug_bounty`.

**Mandatory Instructions:**
1. Read `claude.md` and `PROJECT_STATE.md` to understand your identity and the system architecture.
2. Read `Methodology/OPERATIONAL_PLAYBOOK.md` to understand the 4-Phase practical execution playbook.
3. Do **NOT** summarize these files. Just acknowledge that you are ready.
4. Check if a `TARGET_SESSION.md` exists. If yes, read it for current progress. If no, ask me for the target domain and scope to start Phase 1 (Reconnaissance).
5. Operate with maximum token efficiency by only loading skills from `./skills/` when they match the observed target stack or vulnerability during Phase 3."

---
