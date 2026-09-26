# 📚 Core Theoretical Literature & First-Principles References

This directory stores the seminal engineering and security textbooks that underpin our **Architectural Reasoning Engine**. Instead of relying on superficial vulnerability checklists, our methodology models software systems from first principles.

---

## 📖 Book Catalog

### 1. Designing Data-Intensive Applications (DDIA)
*   **Author:** Martin Kleppmann
*   **Formats Available:**
    - [`DDIA_Book.md`](DDIA_Book.md) (Clean AI-ready Markdown, 1.76 MB)
    - `Designing Data Intensive Applications by Martin Kleppmann.pdf`
    - `dokumen.pub_designing-data-intensive-applications-the-big-ideas-behind-reliable-scalable-and-maintainable-systems-9781491903100-9781449373320-1491903104.azw3` (Raw Kindle eBook source)
*   **Relevance to Bug Bounty:**
    - **Replication Lag & Eventual Consistency:** Exploiting stale reads between primary/replica nodes to bypass security checks.
    - **Distributed Transactions & Sagas:** Abusing multi-step distributed state machines without 2-phase commit.
    - **Unreliable Clocks & LWW:** Timestamp manipulation, clock skew, and Last-Write-Wins race conditions.
    - **Governing Skills:**
        - [`skills/state_management/consistency_failures.md`](../skills/state_management/consistency_failures.md)
        - [`skills/state_management/distributed_transaction_abuse.md`](../skills/state_management/distributed_transaction_abuse.md)
        - [`skills/state_management/race_conditions.md`](../skills/state_management/race_conditions.md)

### 2. The Art of Software Security Assessment (AOSSA)
*   **Authors:** Mark Dowd, John McDonald, Justin Schuh
*   **Format Available:** `The Art of Software Security Assessment - Identifying and Preventing Software Vulnerabilities.pdf`
*   **Relevance to Bug Bounty:**
    - The definitive bible for parser differentials, boundary conditions, serialization flaws, arithmetic overflows, and protocol state confusion.
    - **Governing Skills:**
        - [`skills/infrastructure/parser_implementation_integrity.md`](../skills/infrastructure/parser_implementation_integrity.md)
        - [`skills/infrastructure/parser_differential_abuse.md`](../skills/infrastructure/parser_differential_abuse.md)
        - [`skills/infrastructure/serialization_boundary_failures.md`](../skills/infrastructure/serialization_boundary_failures.md)

### 3. Threat Modeling: Designing for Security
*   **Author:** Adam Shostack
*   **Format Available:** `Threat Modeling - Shostack, Adam.pdf`
*   **Relevance to Bug Bounty:**
    - The foundation of our STRIDE threat modeling, Data Flow Diagrams (DFDs), and trust boundary mapping.
    - **Governing Methodologies:**
        - [`Methodology/Architectural_Trust_Boundary_Analysis.md`](../Methodology/Architectural_Trust_Boundary_Analysis.md)
        - [`Methodology/STRIDE_Threat_Modeling_Workflow.md`](../Methodology/STRIDE_Threat_Modeling_Workflow.md)
        - [`Methodology/Recon_to_Architecture_Mapping.md`](../Methodology/Recon_to_Architecture_Mapping.md)

---

## 🛠️ Utilities
*   [`extract.py`](extract.py): Local Python extraction script used to convert `.azw3`/`.mobi` files into structured Markdown optimized for AI agents.
