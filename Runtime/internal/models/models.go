package models

import "time"

// --- Node Types ---

type NodeType string

const (
	NodeTypeUnknown          NodeType = "UNKNOWN"
	NodeTypeGateway          NodeType = "GATEWAY"
	NodeTypeParserBoundary   NodeType = "PARSER_BOUNDARY"
	NodeTypeIdentityBoundary NodeType = "IDENTITY_BOUNDARY"
	NodeTypeAsyncWorkflow    NodeType = "ASYNC_WORKFLOW"
	NodeTypeDistributedState NodeType = "DISTRIBUTED_STATE"
	NodeTypeWorkloadIdentity NodeType = "WORKLOAD_IDENTITY"
	NodeTypeTrustBoundary    NodeType = "TRUST_BOUNDARY"
	NodeTypeInternalService  NodeType = "INTERNAL_SERVICE"
	NodeTypeExternalService  NodeType = "EXTERNAL_SERVICE"
)

// --- Edge Types ---

type EdgeType string

const (
	EdgeTypeUnknown              EdgeType = "UNKNOWN"
	EdgeTypeProtocolTranslation  EdgeType = "PROTOCOL_TRANSLATION"
	EdgeTypeIdentityPropagation  EdgeType = "IDENTITY_PROPAGATION"
	EdgeTypeAsyncExecution       EdgeType = "ASYNC_EXECUTION"
	EdgeTypeStateReplication     EdgeType = "STATE_REPLICATION"
	EdgeTypeParserTransition     EdgeType = "PARSER_TRANSITION"
	EdgeTypeDelegatedTrust       EdgeType = "DELEGATED_TRUST"
	EdgeTypeNetworkFlow          EdgeType = "NETWORK_FLOW"
	EdgeTypeSubdomainRelation    EdgeType = "SUBDOMAIN_RELATION"
	EdgeTypeProxyBackend         EdgeType = "PROXY_BACKEND"
	EdgeTypeAuthProtection       EdgeType = "AUTH_PROTECTION"
)

// --- Confidence Levels ---

type ConfidenceLevel int

const (
	ConfidenceLow    ConfidenceLevel = 1 // Generic signals (e.g., Server: nginx on 443)
	ConfidenceMedium ConfidenceLevel = 2 // Common port/header combos (e.g., 8080 + Jetty)
	ConfidenceHigh   ConfidenceLevel = 3 // Explicit tech headers or unique protocol handshakes
)

// --- Mechanism Classes ---

type MechanismClass string

const (
	MechanismParserDifferential  MechanismClass = "PARSER_DIFFERENTIAL"
	MechanismIdentityLeak        MechanismClass = "IDENTITY_LEAK"
	MechanismWorkloadEscalation  MechanismClass = "WORKLOAD_ESCALATION"
	MechanismAsyncTrustDecay     MechanismClass = "ASYNC_TRUST_DECAY"
	MechanismConsistencyFailure  MechanismClass = "CONSISTENCY_FAILURE"
	MechanismStaleAuthPropagation MechanismClass = "STALE_AUTH_PROPAGATION"
	MechanismAccessControlBypass MechanismClass = "ACCESS_CONTROL_BYPASS"
	MechanismCloudIdentityTheft  MechanismClass = "CLOUD_IDENTITY_THEFT"
	MechanismStateDesync         MechanismClass = "STATE_DESYNC"
	MechanismRequestSmuggling    MechanismClass = "REQUEST_SMUGGLING"
)

// --- Core Entities ---

// ArchitecturalSignal represents a normalized signal from any recon tool.
type ArchitecturalSignal struct {
	ID              string            `json:"id"`
	Source          string            `json:"source"`           // Tool name: httpx, katana, nmap, subfinder, etc.
	Timestamp       time.Time         `json:"timestamp"`
	AssetIdentifier string            `json:"asset_identifier"` // URL, IP, ARN, hostname
	Attributes      map[string]string `json:"attributes"`       // Flattened key-value pairs from raw tool output
	InferredTraits  []string          `json:"inferred_traits"`  // e.g., "uses_graphql", "has_oidc"
	Confidence      float64           `json:"confidence"`       // 0.0 to 1.0
	ScanSessionID   string            `json:"scan_session_id"`
}

// ArchitecturalIndicator is a classified interpretation of raw signals.
type ArchitecturalIndicator struct {
	Type       string          `json:"type"`       // e.g., "Edge Gateway (CDN)", "Binary RPC Interface"
	Confidence ConfidenceLevel `json:"confidence"` // Level 1-3
	SourceSignalID string     `json:"source_signal_id"`
	Rationale  string          `json:"rationale"`
}

// Node represents a vertex in the architectural graph.
type Node struct {
	ID              string            `json:"id"`
	Type            NodeType          `json:"type"`
	Layer           string            `json:"layer"`            // physical, identity, mechanism
	Labels          []string          `json:"labels"`
	Properties      map[string]string `json:"properties"`
	ConfidenceScore float64           `json:"confidence_score"`
	FirstSeen       time.Time         `json:"first_seen"`
	LastSeen        time.Time         `json:"last_seen"`
	EvidenceIDs     []string          `json:"evidence_ids"` // Signal IDs that contributed
	Indicators      []ArchitecturalIndicator `json:"indicators"`
}

// Edge represents a directed relationship between two nodes.
type Edge struct {
	ID              string            `json:"id"`
	SourceID        string            `json:"source_id"`
	TargetID        string            `json:"target_id"`
	Type            EdgeType          `json:"type"`
	Properties      map[string]string `json:"properties"`
	ConfidenceScore float64           `json:"confidence_score"`
	EvidenceIDs     []string          `json:"evidence_ids"`
	Rationale       string            `json:"rationale"` // Why this edge was inferred
}

// TrustBoundary represents a security boundary detected in the architecture.
type TrustBoundary struct {
	ID          string   `json:"id"`
	Type        string   `json:"type"`          // Gateway, Identity, Workload, Async, Parser, Logic, State
	NodeIDs     []string `json:"node_ids"`      // Nodes on both sides of the boundary
	EdgeIDs     []string `json:"edge_ids"`      // Edges that cross this boundary
	Mechanism   string   `json:"mechanism"`     // The relevant skill file reference
	Risk        float64  `json:"risk"`
	Description string   `json:"description"`
}

// BoundaryPath is a path through the graph crossing trust boundaries.
type BoundaryPath struct {
	NodeIDs     []string `json:"node_ids"`
	EdgeIDs     []string `json:"edge_ids"`
	Boundaries  []string `json:"boundary_ids"`
	RiskScore   float64  `json:"risk_score"`
}

// ParserTransition records a parser change along the request flow.
type ParserTransition struct {
	FromNodeID  string  `json:"from_node_id"`
	ToNodeID    string  `json:"to_node_id"`
	FromParser  string  `json:"from_parser"`  // e.g., "nginx/HTTP1.1"
	ToParser    string  `json:"to_parser"`    // e.g., "gunicorn/HTTP1.1"
	DiffRisk    float64 `json:"diff_risk"`    // Risk of interpretation desync
}

// IdentityPath traces identity context flow through the graph.
type IdentityPath struct {
	NodeIDs       []string `json:"node_ids"`
	IdentityType  string   `json:"identity_type"`  // JWT, Cookie, API Key, mTLS
	LeakDetected  bool     `json:"leak_detected"`  // Identity propagated to untrusted node
	LeakNodeID    string   `json:"leak_node_id"`
}

// --- Hypothesis & Reporting ---

// AttackHypothesis is a machine-generated offensive prediction.
type AttackHypothesis struct {
	ID                    string         `json:"id"`
	Mechanism             MechanismClass `json:"mechanism"`
	MechanismLabel        string         `json:"mechanism_label"` // Human-readable name
	PathNodeIDs           []string       `json:"path_node_ids"`
	RiskScore             float64        `json:"risk_score"`      // 0.0 to 1.0
	ConfidenceScore       float64        `json:"confidence_score"`
	ConfidenceTier        int            `json:"confidence_tier"` // Tier 1 (High), 2 (Med), 3 (Low)
	EvidenceIDs           []string       `json:"evidence_ids"`
	Rationale             string         `json:"rationale"`
	SkillReference        string         `json:"skill_reference"` // Path to relevant skill file
	ExplainabilityTraceID string         `json:"explainability_trace_id"`
	GeneratedAt           time.Time      `json:"generated_at"`
}

// FusedEvidence is the output of evidence correlation.
type FusedEvidence struct {
	ID              string   `json:"id"`
	SourceSignalIDs []string `json:"source_signal_ids"` // All contributing signals
	CorrelationType string   `json:"correlation_type"`  // e.g., "host_service", "provider", "temporal"
	Confidence      float64  `json:"confidence"`
	FusedProperties map[string]string `json:"fused_properties"`
	Rationale       string   `json:"rationale"`
}

// GraphSnapshot is a complete state of the graph at a point in time.
type GraphSnapshot struct {
	SessionID       string          `json:"session_id"`
	Timestamp       time.Time       `json:"timestamp"`
	Nodes           []Node          `json:"nodes"`
	Edges           []Edge          `json:"edges"`
	TrustBoundaries []TrustBoundary `json:"trust_boundaries"`
}

// HypothesisReport is the final output of the reasoning engine.
type HypothesisReport struct {
	SessionID   string             `json:"session_id"`
	Timestamp   time.Time          `json:"timestamp"`
	Graph       GraphSnapshot      `json:"graph"`
	Hypotheses  []AttackHypothesis `json:"hypotheses"`
	Summary     ReportSummary      `json:"summary"`
}

// ReportSummary provides high-level stats about the analysis.
type ReportSummary struct {
	TotalNodes       int `json:"total_nodes"`
	TotalEdges       int `json:"total_edges"`
	TotalBoundaries  int `json:"total_boundaries"`
	TotalHypotheses  int `json:"total_hypotheses"`
	Tier1Count       int `json:"tier1_count"` // High priority
	Tier2Count       int `json:"tier2_count"` // Medium priority
	Tier3Count       int `json:"tier3_count"` // Low priority
}
