# 07 — Machine Reasoning API (MRA)

The Machine Reasoning API defines the standardized interfaces and JSON schemas for system communication and interoperability.

## 1. Core Schemas

### ArchitecturalSignal (Ingestion)
```json
{
  "type": "signal",
  "source": "httpx",
  "timestamp": "2026-05-26T14:30:00Z",
  "asset": "https://api.target.com",
  "attributes": {
    "header_x_served_by": "envoy",
    "status_code": 200,
    "content_type": "application/json"
  }
}
```

### GraphNode (Representation)
```json
{
  "id": "node_abc123",
  "layer": "physical",
  "labels": ["API_Gateway", "Public"],
  "properties": {
    "provider": "AWS",
    "software": "Envoy Proxy",
    "confidence": 0.95
  }
}
```

### AttackHypothesis (Output)
```json
{
  "id": "hypo_456",
  "mechanism": "Parser Differential",
  "path": ["node_gw", "node_be"],
  "risk_score": 0.82,
  "confidence": 0.65,
  "evidence_ids": ["signal_1", "signal_2"]
}
```

## 2. Graph Query Model (GQM)
The system supports a GraphQL-like interface for querying the current architectural state.

*   `query GetTrustBoundaries(sessionID: ID)`
*   `query TraceIdentity(userID: ID)`
*   `query LookupMechanism(name: String)`

## 3. Inference Command Interface
Used by the Orchestration Core to task specialized agents.

*   `cmd RunParserInference(nodes: [NodeID])`
*   `cmd RevalidateBoundary(edge: EdgeID)`

## 4. Confidence Adjustment API
Used by feedback loops to update graph weights.

*   `cmd UpdateConfidence(entityID: ID, adjustment: Float, reason: String)`

## 5. Metadata Registry
*   Standardized tags for mechanisms (e.g., `mechanism.auth.oidc`, `mechanism.parser.graphql`).
*   Standardized labels for trust zones (e.g., `zone.public`, `zone.internal`, `zone.isolated`).
