# 🛡️ Elite Bug Bounty Architectural Reasoning Engine

An advanced, mechanism-first offensive security reasoning system designed to identify high-impact vulnerabilities in complex distributed systems, cloud-native architectures, and modern web applications.

---

## ⚡ Quick Start

### 1. Read the Mission Briefing
Start every session with **[`claude.md`](claude.md)** — the single source of truth for agent identity, the 4-phase methodology, mandatory headers, and ruthless triage rules.

### 2. Follow the 4-Phase Tactical Playbook
Use **[`Methodology/OPERATIONAL_PLAYBOOK.md`](Methodology/OPERATIONAL_PLAYBOOK.md)** for step-by-step execution:
- **Phase 1: Reconnaissance (Passive & Active)** → [`Workflow/01`](Workflow/01_target_selection.md), [`Workflow/02`](Workflow/02_passive_recon.md), [`Workflow/03`](Workflow/03_active_mapping.md)
- **Phase 2: Architecture & DFD Inference** → [`Workflow/04`](Workflow/04_fingerprint_to_architecture.md), [`Workflow/05`](Workflow/05_attack_surface_expansion.md), [`Architecture_Inference/`](Architecture_Inference/index.md)
- **Phase 3: Mechanism Auditing** → [`Workflow/06`](Workflow/06_manual_validation.md), [`skills/`](skills/_INDEX.md), [`OPERATIONAL_MAP.md`](OPERATIONAL_MAP.md)
- **Phase 4: Exploitation & Impact** → [`Workflow/07`](Workflow/07_chain_building.md), [`Workflow/08`](Workflow/08_impact_modeling.md), [`Workflow/09`](Workflow/09_reporting.md)

### 3. Run the Automated Reasoning Runtime
Analyze recon output (`httpx.jsonl`, `katana.jsonl`, `nmap.jsonl`) to automatically construct Data Flow Diagrams (DFD) and prioritize attack hypotheses:

```bash
cd Runtime
go run cmd/runtime/main.go -input testdata/sample_signals.jsonl -format markdown -output outputs/
```

---

## 📁 Repository Structure

```
bug_bounty/
├── README.md               # Overview and quick-start guide (this file)
├── claude.md               # Master AI Agent briefing & execution doctrine
├── OPERATIONAL_MAP.md      # Rapid mechanism pivot index (linking all 44 skills)
├── templates/              # Engagement templates (TARGET_SESSION_TEMPLATE.md)
│
├── Methodology/            # Strategic threat modeling & tactical playbooks
│   ├── OPERATIONAL_PLAYBOOK.md         # Unified 4-Phase tactical manual
│   ├── BUG_BOUNTY_TOOLKIT_PLAYBOOK.md  # Chained toolkit recon & fuzzer pipelines
│   ├── PRACTICAL_BURP_HUNTING_GUIDE.md # 2-account CRUD, race condition, & logic guide
│   ├── index.md                        # Methodology table of contents
│   ├── Architectural_Trust_Boundary_Analysis.md
│   ├── STRIDE_Threat_Modeling_Workflow.md
│   └── Recon_to_Architecture_Mapping.md
│
├── Workflow/               # 9 sequential operational workflows
│   ├── 01_target_selection.md
│   ├── 02_passive_recon.md
│   ├── 03_active_mapping.md
│   ├── 04_fingerprint_to_architecture.md
│   ├── 05_attack_surface_expansion.md
│   ├── 06_manual_validation.md
│   ├── 07_chain_building.md
│   ├── 08_impact_modeling.md
│   └── 09_reporting.md
│
├── Architecture_Inference/ # 8 architectural inference heuristics
│   ├── 01_recon_signal_classification.md
│   ├── 02_service_clustering.md
│   ├── 03_trust_boundary_inference.md
│   ├── 04_identity_propagation_mapping.md
│   ├── 05_async_distributed_inference.md
│   ├── 06_parser_pipeline_mapping.md
│   ├── 07_dfd_generation.md
│   └── 08_attack_hypothesis_generation.md
│
├── skills/                 # 44 curated mechanism manuals (4 pillars)
│   ├── _INDEX.md           # STRIDE Threat Matrix (all 44 skills indexed)
│   ├── _TAXONOMY.md        # Full 4-pillar architectural taxonomy
│   ├── auth_logic/         # SAML XSW, IDOR, Pre-ATO, OAuth/SSO, IAM boundaries, Auth bypass
│   ├── state_management/   # Financial logic, Rate limiting, Async, Consistency, Race, WebSockets
│   ├── infrastructure/     # 403 bypass, NGINX, Webhooks, SSRF, SSTI, File Upload, SQLi, Prototype Pollution
│   └── emerging/           # LLM / RAG privilege escalation & AI quota bypasses
│
├── scripts/                # 21 automated tactical recon & auditing scripts
│   ├── README.md           # Complete script inventory, flags, & phase mapping
│   ├── full_subdomain_recon.sh/.ps1
│   ├── run_toolkit_recon.sh/.ps1
│   ├── test_403_bypasses.ps1
│   ├── test_ssrf_bypasses.ps1
│   ├── audit_graphql_endpoints.ps1
│   ├── extract_js_secrets.ps1
│   ├── find_broken_links.ps1
│   ├── param_reflection_pipeline.ps1
│   └── check_subdomain_takeover, find_origin_ip, fuzz_sensitive_backups, discover_api_endpoints...
│
├── payloads/               # Targeted wordlists & pattern matching
│   ├── README.md           # Usage manual & pipeline integration
│   ├── headers/            # 5,865 reverse-proxy 403 bypass headers (403_bypass_headers.txt)
│   └── gf_patterns/        # Ready-to-use GF patterns (idor, lfi, sqli, ssrf, xss)
│
├── research/               # Theory, cloud specifications, & threat intelligence
│   ├── README.md           # Master research guide & dataset index
│   ├── writeup_links_archive.json # 5,759 unique writeup links from 6 core channels
│   ├── hackerone_disclosed_reports_2026.txt # 200 real-world disclosed bug reports
│   ├── writeups/           # Deep-dive analyzed case studies
│   ├── sources/            # bug-bounty-checklist repository & Canvas diagrams
│   └── [Architectural Papers] # Google Zanzibar, SPIFFE, Istio, Kubernetes, AWS IAM
│
├── transcripts/            # Full categorized crash course & community masterclasses
│   ├── README.md           # Transcripts master hub & track overview
│   ├── bug_bounty_crash_course/ # 22 structured episodes with timestamps & PoCs
│   ├── eldasas_web_security/    # 37 structured masterclass lessons & CWES modules
│   └── community_and_reference/ # CyberFlow Contextual Recon & CyMatriX 3hr Masterclass
│
├── books/                  # Core textbooks (DDIA, AOSSA, Threat Modeling)
│   └── README.md           # First-principles mapping to skills and reasoning
│
├── Runtime/                # Go & Python Automated Reasoning Engine
│   ├── cmd/runtime/        # CLI Entrypoint (`main.go`)
│   ├── internal/           # Ingestion, Graph, Correlation, Normalization, Inference
│   ├── workers/            # Python gRPC workers (Identity, Parser, State)
│   ├── proto/              # Protobuf definitions
│   └── testdata/           # Test signals & evaluation data
│
└── _archive/               # Historical design specs, validation reports, transcripts
```

---

## 🎯 Core Principles

1. **Mechanism over Payload:** Attack the interaction across trust boundaries, not isolated parameters.
2. **Context Efficiency:** Activate skill files dynamically only when matching the target stack.
3. **Universal Ruthless Triager:** Kill false positives and demand weaponized PoC with demonstrated business impact before reporting.
