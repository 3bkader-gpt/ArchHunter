# ArchHunter ← `llm` Intelligence Integration — Implementation Plan

> **Status:** ALL PHASES DONE (2026-10-01) · **Created:** 2026-10-01 · **Driver:** ZCode session (leading)
> **Source repo:** `C:\Users\medoo\Desktop\llm` (private intel vaults + HackerOne/Telegram scrapers)
> **Objective:** Fill verified gaps in ArchHunter and enrich it with the curated intelligence from the `llm` repo, without breaking the existing doctrine (`claude.md`), indexes, or Runtime behavior.

---

## 0. Verified Gaps (audited against disk — 2026-10-01)

| # | Gap | Evidence (verified) | Phase |
|---|-----|---------------------|-------|
| G1 | Two skill files exist but are **0 bytes**, while fully indexed in `_INDEX.md` / `_TAXONOMY.md` / `OPERATIONAL_MAP.md` | `skills/infrastructure/clickjacking_ui_redressing.md`, `skills/state_management/rate_limiting_evasion.md` | **P1** |
| G2 | `findRelevantNodes` falls through to a `default` branch that attaches **every node with confidence ≥ 0.7** for 5 of 10 mechanisms — flooding hypotheses with irrelevant evidence | `Runtime/internal/inference/hypothesis_engine.go:232-263` | **P6** |
| G3 | Go↔Python gRPC bridge dormant: `main.go:61` uses `inference.NewMockClient()` while protos + workers are fully generated | `Runtime/cmd/runtime/main.go`, `Runtime/workers/` | P8 (deferred) |
| G4 | 8 PowerShell-only tactical scripts with no bash/WSL parity: `analyze_js_bundle`, `audit_graphql_endpoints`, `extract_js_secrets`, `find_broken_links`, `param_reflection_pipeline`, `setup_target`, `test_403_bypasses`, `test_ssrf_bypasses` | `scripts/` | P7 (deferred) |
| G5 | `payloads/` holds only GF patterns + one 403 header set — no IDOR/mass-assignment/normalization wordlists | `payloads/` | **P2** |

## 1. Source Assets (`llm` repo)

- **`auth_bypass_vault/`** — 28 disclosed H1 reports (`01_`), 25+ Telegram writeups (`02_`), 7 methodology guides (`03_`: SAML SSO, GraphQL auth bypass, OAuth/JWT/session, Web Cache Deception, reverse-proxy header bypass, IDOR patterns, full auth testing methodology), 4 wordlists (`04_`).
- **`llm_hacking_vault/`** — 22 H1 reports on AI/MCP attacks (`01_`), Telegram writeups (`02_`), huntr challenges (`03_`), OWASP LLM Top 10 + PoC patterns + testing methodology (`04_`).
- **`browser_hacking_vault.zip`** — BCNY/Arc/Dia target-specific. **Out of scope** for this integration.
- **Scrapers** — `fetch_hackerone.py`, `fetch_auth_h1.py` (H1 GraphQL + report JSON), `fetch_auth_tg.py` + `tg_login.py` (Telethon, session file `my_telegram_session.session`).

---

## 2. Phases & Tasks

### P1 — Fill Empty Skills (G1) — CRITICAL
- [x] **T1.1** Author `skills/state_management/rate_limiting_evasion.md` — sourced from vault: proxy/IP header rotation, method & path mutation, concurrency bursts, session/token cycling, IPv6 rotation. Follow the existing skill template exactly.
- [x] **T1.2** Author `skills/infrastructure/clickjacking_ui_redressing.md` — frame-busting bypasses, CSP `frame-ancestors` gaps, multi-step pre-authenticated state actions, same-site form abuse.
- **AC:** both non-empty, match template sections (Objective & Context / Recognition Patterns / Attack Preconditions / Step-by-Step Validation Strategy / Common Weak Implementations / Escalation Paths / Detection Opportunities / Notes). Index links already exist — no index edits needed for P1.

### P2 — Payload Wordlists (G5) — HIGH
- [x] **T2.1** Create `payloads/wordlists/`; copy `idor_parameters_wordlist.txt`, `mass_assignment_parameters.txt`, `path_normalization_payloads.txt`, `auth_bypass_headers.txt` from the vault.
- [x] **T2.2** Update `payloads/README.md` — full inventory, source attribution, usage with `gf`/ffuf.
- **AC:** README documents `headers/403_bypass_headers.txt` vs `wordlists/auth_bypass_headers.txt` roles without duplication.

### P3 — Emerging Skills (new) — HIGH
- [x] **T3.1** Author `skills/emerging/mcp_agent_tool_poisoning.md` (MCP tool-description poisoning, tool execution hijacking, cross-server tool shadowing, confused-deputy agents) — sourced from `llm_hacking_vault` reports.
- [x] **T3.2** Author `skills/emerging/indirect_prompt_injection_exfiltration.md` (stored injection via IDOR'd fields, markdown/image-based data exfiltration, agent auto-execution chains).
- [x] **T3.3** Register both in `skills/_INDEX.md`, `skills/_TAXONOMY.md` §4, and `OPERATIONAL_MAP.md`; bump skill counts (47 → 49) wherever stated.
- **AC:** every new file reachable from all three indexes.

### P4 — Intel Scrapers → `scripts/intel/` — MEDIUM
- [x] **T4.1** Port `fetch_auth_h1.py` → `scripts/intel/fetch_h1_reports.py` with CLI args: `--query`, `--limit`, `--out` (default under `research/case_studies/_fresh/`).
- [x] **T4.2** Port `fetch_auth_tg.py` → `scripts/intel/fetch_telegram_intel.py` with `--channel`, `--limit`, `--out`; resolve session path via `TELEGRAM_SESSION` env var.
- [x] **T4.3** Copy `tg_login.py` → `scripts/intel/tg_login.py`.
- [x] **T4.4** Document in `scripts/README.md` (usage + legal note: only for self-authorized recon of disclosed intel).
- **AC:** scripts run with `--help`, documented, no hardcoded absolute paths.

### P5 — Research Case Studies — MEDIUM
- [x] **T5.1** Create `research/case_studies/` + `INDEX.md` (table: file → platform → mechanism → related skill).
- [x] **T5.2** Copy `auth_bypass_vault/01_+02_` reports (auth mechanisms).
- [x] **T5.3** Copy `llm_hacking_vault/01_+04_` (AI mechanism reports + methodologies into `research/case_studies/llm_security/`).
- **AC:** `INDEX.md` lists every file with mechanism tags and cross-references to `skills/`.

### P6 — Runtime Node-Filtering Fix (G2) — HIGH
- [x] **T6.1** Extend `findRelevantNodes` switch: `AccessControlBypass` → nodes whose URL/ID contains `/graphql`; `StateDesync` → `NodeTypeDistributedState`; `RequestSmuggling` → `NodeTypeGateway`/`NodeTypeParserBoundary`; `ConsistencyFailure` → identity-bearing nodes (`authorization`/`cookie` props); `WorkloadEscalation` → `NodeTypeWorkloadIdentity`. Keep `default` as-is for unknown future mechanisms.
- [x] **T6.2** `go build ./...`, re-run on `testdata/sample_signals.jsonl`, diff `HypothesisReport.json` before/after.
- **AC:** `graphql_abuse` hypothesis lists only `/graphql` nodes; `state_desync` only `DISTRIBUTED_STATE` nodes; no empty `PathNodeIDs` for fired rules.

### P7 — Bash/WSL Parity (G4) — DONE (2026-10-01)
- [x] **T7.1** Bash ports written for all 8 PowerShell-only scripts: `test_403_bypasses.sh`, `test_ssrf_bypasses.sh`, `audit_graphql_endpoints.sh`, `param_reflection_pipeline.sh`, `analyze_js_bundle.sh`, `extract_js_secrets.sh`, `find_broken_links.sh`, `setup_target.sh`.
- [x] **T7.2** All 8 syntax-checked and functionally smoke-tested against a local test server (bypass detection, GraphQL probes, reflection analysis, secret extraction, scaffolding).
- [x] **T7.3** `scripts/README.md` matrix + usage sections updated (Bash / PWSH).

### P8 — gRPC Bridge Activation (G3) — DONE (2026-10-01)
- [x] **T8.1** `Runtime/workers/reasoning_worker.py`: live `ReasoningWorker` implementation (identity-bearing node leak, internal-service surface, generic fallback hypotheses with reasoning trace).
- [x] **T8.2** `inference.GrpcClient` fixed: node `Type`/evidence now forwarded; dial hardened with bounded context timeout.
- [x] **T8.3** `main.go` wired via `-workers-addr` flag / `ARCHHUNTER_WORKERS_ADDR` env; graceful fallback to mock client when offline.
- [x] **T8.4** Verified live cross-language: Go runtime dispatched sub-graph to Python worker over gRPC; 2 `py_*` hypotheses persisted to `HypothesisReport.json`. Offline fallback + flag-less mock behavior also verified.

---

## 3. Execution Order

**Session 1 (2026-10-01):** P1 → P2 → P3 → P6 → P4 → P5 → index/README sweep.
**Session 2 (2026-10-01):** P7 → P8 → docs → commit.
**All phases complete.** Future extensions live in Runtime/README.md Next Steps.

## 4. Out of Scope (explicit)

- `browser_hacking_vault.zip` / BCNY target work (separate engagement, separate plan at `llm/implementation_plan.md`).
- Bulk-dumping raw vault files into `books/` or `transcripts/` — only curated, indexed content enters `research/`.
- Any change to `claude.md` doctrine or the mandatory research header.
