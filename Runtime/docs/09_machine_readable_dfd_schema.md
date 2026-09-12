# 09 — Machine-Readable DFD Schema

## Goal
Define a strict JSON schema for the inferred Data Flow Diagram so it can be consumed by external visualization tools (e.g., Mermaid.js, Neo4j, Cytoscape) or custom agent scripts.

## Schema Definition (JSON)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "InferredDFD",
  "type": "object",
  "properties": {
    "nodes": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "type": { "enum": ["Gateway", "Compute", "Identity", "State"] },
          "attributes": { "type": "object" }
        },
        "required": ["id", "type"]
      }
    },
    "edges": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "source": { "type": "string" },
          "target": { "type": "string" },
          "type": { "enum": ["ROUTES_TO", "AUTHENTICATES_VIA", "ENQUEUES_TO", "ASSUMES_ROLE"] },
          "inferred_boundary": { "type": "string" }
        },
        "required": ["source", "target", "type"]
      }
    },
    "hypotheses": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "edge_id": { "type": "string" },
          "skill": { "type": "string" },
          "confidence": { "type": "number" }
        }
      }
    }
  }
}
```
