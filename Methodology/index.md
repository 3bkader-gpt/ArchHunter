# Master Bug Bounty Methodology

This methodology integrates advanced architectural threat modeling with a clinical operational workflow. It prioritize mechanism discovery over payload guessing.

## Core Reasoning Modules
*   [Architectural Trust Boundary Analysis](Architectural_Trust_Boundary_Analysis.md) - Identifying the "First Mile" of attack.
*   [STRIDE Threat Modeling](STRIDE_Threat_Modeling_Workflow.md) - The bridge between architecture and exploitation.
*   [Recon-to-Architecture Mapping](Recon_to_Architecture_Mapping.md) - Building DFDs from raw recon data.
*   [Human Factors & Attack Surface](Human_Factors_Attack_Surface.md) - Exploiting social and organizational trust.

## Execution Framework
*   **[OPERATIONAL PLAYBOOK](OPERATIONAL_PLAYBOOK.md)** - The 4-Phase tactical guide (Recon, Mapping, Vuln Analysis, Exploitation/Impact).
*   **[Bug Bounty Toolkit Playbook & Chained Pipelines](BUG_BOUNTY_TOOLKIT_PLAYBOOK.md)** - Unified encyclopedia for subfinder, tlsx, katana, uro, gf, qsreplace, kxss, dalfox, and arjun.
*   **[Practical Burp Hunting Guide](PRACTICAL_BURP_HUNTING_GUIDE.md)** - Hands-on two-account CRUD testing, single-packet race conditions, and business logic verification.
*   **[Elite Bug Bounty Methodology Reference](Elite_BugBounty_Methodology.pdf)** - Visual reference guide and methodology manual.
*   **[Tactical Scripts Catalog](../scripts/README.md)** - Comprehensive automation catalog for 21 recon and auditing tools.
*   **[Payloads & Wordlists Hub](../payloads/README.md)** - Curated headers and GF patterns.
*   **[Tool Configuration & API Keys](TOOL_CONFIG.md)** - Setup and limits for core scanners.
*   **[WSL Security Tools Inventory](wsl-security-tools-inventory.md)** - Local environment setup.
*   **[Burp Suite MCP Reference](burp-mcp-tools-reference.md)** - Integrated proxy automation.

---
*Operational Philosophy: Do not attack the component; attack the interaction across the boundary.*

