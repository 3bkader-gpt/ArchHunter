# 04 — Fingerprint to Architecture (The DFD Bridge)

## Operational Goal
Transition from raw IP/Port data to a Logical Data Flow Diagram (DFD). Leverage the **[Architecture Inference Layer](../Architecture_Inference/index.md)** to automate the mapping of tech stacks and Trust Boundaries.

## Execution Flow

### 1. Technology Fingerprinting & Inference
Identify underlying technologies and logical clusters.
```bash
webanalyze -hosts recon/subs/alive_hosts.txt -output json > recon/scans/tech.json
cat recon/subs/alive_hosts.txt | wafw00f -i - -o recon/scans/waf.txt
```
*Action:* Feed these signals into **[01_recon_signal_classification](../Architecture_Inference/01_recon_signal_classification.md)**.

### 2. Swagger/API Discovery
Identify structured data interfaces.
```bash
cat recon/subs/alive_hosts.txt | httpx -path '/api/swagger.json,/api-docs,/v1/openapi.json,/graphql' -mc 200 | tee recon/urls/api_endpoints.txt
```
*Action:* Map the discovered interfaces to **[06_parser_pipeline_mapping](../Architecture_Inference/06_parser_pipeline_mapping.md)**.

## Architectural Reasoning
Apply the core Inference Heuristics:
*   **[Service Clustering](../Architecture_Inference/02_service_clustering.md):** Group subdomains that share fingerprints.
*   **[Identity Propagation](../Architecture_Inference/04_identity_propagation_mapping.md):** Where is the OIDC bridge?
*   **[Async & Distributed Inference](../Architecture_Inference/05_async_distributed_inference.md):** Are there multi-region replicas?

## Outcome: The DFD
A structured DFD generated via **[07_dfd_generation](../Architecture_Inference/07_dfd_generation.md)**.