package inference

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/hacker/runtime/internal/models"
)

// HypothesisRule maps architectural traits to likely mechanism failures.
// Derived from Architecture_Inference/08_attack_hypothesis_generation.md
type HypothesisRule struct {
	ID           string
	RequiredTraits []string        // All must be present (AND logic)
	OptionalTraits []string        // Any of these boosts confidence (OR logic)
	Mechanism    models.MechanismClass
	Label        string             // Human-readable name
	BaseRisk     float64
	SkillRef     string             // Path to relevant skill file
	Description  string
}

// HypothesisEngine generates attack hypotheses from graph state.
type HypothesisEngine struct {
	rules []HypothesisRule
}

// NewHypothesisEngine creates an engine with all built-in rules.
func NewHypothesisEngine() *HypothesisEngine {
	return &HypothesisEngine{
		rules: defaultHypothesisRules(),
	}
}

// Generate produces ranked attack hypotheses from a graph snapshot.
func (h *HypothesisEngine) Generate(
	ctx context.Context,
	snapshot models.GraphSnapshot,
) []models.AttackHypothesis {
	// 1. Extract traits from the graph
	traits := h.extractTraits(snapshot)

	// 2. Match traits against rules
	var hypotheses []models.AttackHypothesis
	for _, rule := range h.rules {
		matchScore := h.scoreMatch(rule, traits)
		if matchScore > 0 {
			hypo := models.AttackHypothesis{
				ID:              fmt.Sprintf("hypo_%s_%d", rule.ID, time.Now().UnixNano()),
				Mechanism:       rule.Mechanism,
				MechanismLabel:  rule.Label,
				RiskScore:       rule.BaseRisk * matchScore,
				ConfidenceScore: matchScore,
				ConfidenceTier:  calculateTier(matchScore),
				SkillReference:  rule.SkillRef,
				Rationale:       rule.Description,
				GeneratedAt:     time.Now(),
			}

			// Attach relevant node IDs from graph
			hypo.PathNodeIDs = h.findRelevantNodes(snapshot, rule)
			hypo.EvidenceIDs = h.collectEvidence(snapshot, hypo.PathNodeIDs)

			hypotheses = append(hypotheses, hypo)
		}
	}

	// 3. Generate boundary-based hypotheses
	for _, boundary := range snapshot.TrustBoundaries {
		hypotheses = append(hypotheses, h.generateBoundaryHypothesis(boundary))
	}

	// 4. Rank by risk * confidence (descending)
	sort.Slice(hypotheses, func(i, j int) bool {
		scoreI := hypotheses[i].RiskScore * hypotheses[i].ConfidenceScore
		scoreJ := hypotheses[j].RiskScore * hypotheses[j].ConfidenceScore
		return scoreI > scoreJ
	})

	return hypotheses
}

// extractTraits derives high-level architectural traits from graph nodes and edges.
func (h *HypothesisEngine) extractTraits(snapshot models.GraphSnapshot) map[string]bool {
	traits := make(map[string]bool)

	for _, node := range snapshot.Nodes {
		// Node type traits
		switch node.Type {
		case models.NodeTypeGateway:
			traits["cdn-gateway"] = true
		case models.NodeTypeParserBoundary:
			traits["binary-rpc"] = true
		case models.NodeTypeIdentityBoundary:
			traits["identity-provider"] = true
		case models.NodeTypeAsyncWorkflow:
			traits["async-queue"] = true
		case models.NodeTypeDistributedState:
			traits["stateful-connection"] = true
		case models.NodeTypeWorkloadIdentity:
			traits["workload-identity"] = true
		case models.NodeTypeInternalService:
			traits["internal-service"] = true
		}

		// Property-based traits
		props := node.Properties
		server := strings.ToLower(props["server"])
		contentType := strings.ToLower(props["content_type"])

		if strings.Contains(contentType, "grpc") {
			traits["grpc"] = true
		}
		if props["authorization"] != "" || props["cookie"] != "" {
			traits["jwt"] = true
		}
		if props["status_code"] == "202" {
			traits["async-queue"] = true
		}
		if strings.Contains(props["url"], "/graphql") || strings.Contains(node.ID, "/graphql") {
			traits["graphql"] = true
		}
		if props["x-amz-request-id"] != "" || props["x-amzn-requestid"] != "" {
			traits["aws"] = true
		}

		// Server type differentiation
		if strings.Contains(server, "nginx") {
			traits["nginx"] = true
		}
		if strings.Contains(server, "apache") {
			traits["apache"] = true
		}
		if strings.Contains(server, "cloudflare") {
			traits["h2-gateway"] = true
		}

		// IMDS detection
		if strings.Contains(node.ID, "169.254.169.254") {
			traits["imdsv1"] = true
		}

		// Webhook/callback detection
		path := strings.ToLower(node.ID)
		if strings.Contains(path, "/webhook") || strings.Contains(path, "/callback") {
			traits["webhook-api"] = true
		}

		// File processor detection
		if strings.Contains(path, "/upload") || strings.Contains(path, "/convert") ||
			strings.Contains(path, "/render") || strings.Contains(path, "/export") {
			traits["file-processor"] = true
		}
	}

	// Edge-based traits
	for _, edge := range snapshot.Edges {
		switch edge.Type {
		case models.EdgeTypeParserTransition:
			traits["parser-differential"] = true
			if edge.Properties["parser_a"] != "" && edge.Properties["parser_b"] != "" {
				// Check for H2→H1.1 transition
				a := strings.ToLower(edge.Properties["parser_a"])
				b := strings.ToLower(edge.Properties["parser_b"])
				if isEdgeServerStr(a) && !isEdgeServerStr(b) {
					traits["h2-gateway"] = true
					traits["h1.1-backend"] = true
				}
			}
		case models.EdgeTypeAsyncExecution:
			traits["async-queue"] = true
		case models.EdgeTypeIdentityPropagation:
			traits["identity-flow"] = true
		}
	}

	// Multi-region detection (multiple CDN or diverse geographic indicators)
	if traits["cdn-gateway"] && (traits["aws"] || traits["identity-provider"]) {
		traits["multi-region"] = true
	}

	return traits
}

// scoreMatch calculates how well a rule matches the observed traits.
func (h *HypothesisEngine) scoreMatch(rule HypothesisRule, traits map[string]bool) float64 {
	// All required traits must be present
	for _, req := range rule.RequiredTraits {
		if !traits[req] {
			return 0
		}
	}

	// Base score for matching all required traits
	score := 0.5

	// Boost for each optional trait present
	matchedOptional := 0
	for _, opt := range rule.OptionalTraits {
		if traits[opt] {
			matchedOptional++
		}
	}
	if len(rule.OptionalTraits) > 0 {
		score += 0.5 * float64(matchedOptional) / float64(len(rule.OptionalTraits))
	} else {
		score = 0.7 // No optional traits = decent confidence from required alone
	}

	if score > 1.0 {
		score = 1.0
	}

	return score
}

// calculateTier assigns a confidence tier based on score.
func calculateTier(score float64) int {
	if score >= 0.7 {
		return 1 // High Priority: 3+ independent signals correlated
	}
	if score >= 0.4 {
		return 2 // Medium Priority: Common architectural anti-pattern
	}
	return 3 // Low Priority: Inferred but unverified
}

// findRelevantNodes returns node IDs that are relevant to a given rule.
func (h *HypothesisEngine) findRelevantNodes(snapshot models.GraphSnapshot, rule HypothesisRule) []string {
	var nodeIDs []string

	for _, node := range snapshot.Nodes {
		// Match based on rule's mechanism class
		switch rule.Mechanism {
		case models.MechanismParserDifferential:
			if node.Type == models.NodeTypeParserBoundary || node.Type == models.NodeTypeGateway {
				nodeIDs = append(nodeIDs, node.ID)
			}
		case models.MechanismIdentityLeak:
			if node.Properties["authorization"] != "" || node.Properties["cookie"] != "" {
				nodeIDs = append(nodeIDs, node.ID)
			}
		case models.MechanismCloudIdentityTheft:
			if node.Type == models.NodeTypeWorkloadIdentity {
				nodeIDs = append(nodeIDs, node.ID)
			}
		case models.MechanismAsyncTrustDecay:
			if node.Type == models.NodeTypeAsyncWorkflow {
				nodeIDs = append(nodeIDs, node.ID)
			}
		default:
			// Include high-confidence nodes as general evidence
			if node.ConfidenceScore >= 0.7 {
				nodeIDs = append(nodeIDs, node.ID)
			}
		}
	}

	return nodeIDs
}

// collectEvidence gathers evidence IDs from relevant nodes.
func (h *HypothesisEngine) collectEvidence(snapshot models.GraphSnapshot, nodeIDs []string) []string {
	nodeSet := make(map[string]bool)
	for _, id := range nodeIDs {
		nodeSet[id] = true
	}

	var evidenceIDs []string
	for _, node := range snapshot.Nodes {
		if nodeSet[node.ID] {
			evidenceIDs = append(evidenceIDs, node.EvidenceIDs...)
		}
	}
	return evidenceIDs
}

// generateBoundaryHypothesis creates a hypothesis from a detected trust boundary.
func (h *HypothesisEngine) generateBoundaryHypothesis(boundary models.TrustBoundary) models.AttackHypothesis {
	mechanism := models.MechanismParserDifferential
	switch boundary.Type {
	case "Identity":
		mechanism = models.MechanismIdentityLeak
	case "Workload":
		mechanism = models.MechanismCloudIdentityTheft
	case "Async":
		mechanism = models.MechanismAsyncTrustDecay
	case "Parser":
		mechanism = models.MechanismParserDifferential
	case "Gateway":
		mechanism = models.MechanismRequestSmuggling
	}

	return models.AttackHypothesis{
		ID:              fmt.Sprintf("hypo_boundary_%s_%d", boundary.ID, time.Now().UnixNano()),
		Mechanism:       mechanism,
		MechanismLabel:  fmt.Sprintf("Trust Boundary: %s", boundary.Type),
		PathNodeIDs:     boundary.NodeIDs,
		RiskScore:       boundary.Risk,
		ConfidenceScore: 0.6,
		ConfidenceTier:  calculateTier(0.6),
		SkillReference:  boundary.Mechanism,
		Rationale:       boundary.Description,
		GeneratedAt:     time.Now(),
	}
}

func isEdgeServerStr(s string) bool {
	edgeServers := []string{"cloudflare", "cloudfront", "akamai", "fastly", "varnish"}
	for _, e := range edgeServers {
		if strings.Contains(s, e) {
			return true
		}
	}
	return false
}

// --- Default Rules ---
// Derived from Architecture_Inference/08_attack_hypothesis_generation.md
// and the trust boundary inference heuristics.

func defaultHypothesisRules() []HypothesisRule {
	return []HypothesisRule{
		// === Critical: Cloud Identity Theft ===
		{
			ID:             "cloud_identity_theft",
			RequiredTraits: []string{"imdsv1"},
			OptionalTraits: []string{"webhook-api", "aws", "internal-service"},
			Mechanism:      models.MechanismCloudIdentityTheft,
			Label:          "IMDS → Cloud Identity Theft",
			BaseRisk:       0.95,
			SkillRef:       "skills/auth_logic/iam_trust_boundaries.md",
			Description:    "IMDSv1 endpoint detected alongside webhook API — potential for SSRF → cloud credential theft via metadata service",
		},
		// === Critical: Request Smuggling ===
		{
			ID:             "request_smuggling",
			RequiredTraits: []string{"h2-gateway", "h1.1-backend"},
			OptionalTraits: []string{"nginx", "apache", "parser-differential"},
			Mechanism:      models.MechanismRequestSmuggling,
			Label:          "H2 Gateway → H1.1 Backend Request Smuggling",
			BaseRisk:       0.9,
			SkillRef:       "skills/infrastructure/parser_differential_abuse.md",
			Description:    "H2 gateway fronting H1.1 backend detected — classic CL/TE or TE/CL desync vector",
		},
		// === High: Async Trust Decay ===
		{
			ID:             "async_trust_decay",
			RequiredTraits: []string{"async-queue"},
			OptionalTraits: []string{"file-processor", "webhook-api", "identity-flow"},
			Mechanism:      models.MechanismAsyncTrustDecay,
			Label:          "Async Queue → Trust Drift RCE",
			BaseRisk:       0.85,
			SkillRef:       "skills/state_management/async_workflow_integrity.md",
			Description:    "Async workflow detected with background processing — potential for validation bypass between request-time and worker execution",
		},
		// === High: Stale Revocation / Consistency ===
		{
			ID:             "stale_revocation",
			RequiredTraits: []string{"multi-region", "jwt"},
			OptionalTraits: []string{"cdn-gateway", "identity-provider", "aws"},
			Mechanism:      models.MechanismConsistencyFailure,
			Label:          "Multi-Region JWT → Stale Revocation Window",
			BaseRisk:       0.75,
			SkillRef:       "skills/state_management/consistency_failures.md",
			Description:    "Multi-region architecture with JWT tokens — potential for stale token acceptance during replication lag",
		},
		// === High: Parser Differential ===
		{
			ID:             "parser_differential",
			RequiredTraits: []string{"parser-differential"},
			OptionalTraits: []string{"nginx", "apache", "cdn-gateway"},
			Mechanism:      models.MechanismParserDifferential,
			Label:          "Multi-Server Parser Differential",
			BaseRisk:       0.7,
			SkillRef:       "skills/infrastructure/parser_differential_abuse.md",
			Description:    "Multiple different server types detected on same domain — potential interpretation desync",
		},
		// === Medium: Identity Leak ===
		{
			ID:             "identity_leak",
			RequiredTraits: []string{"identity-flow"},
			OptionalTraits: []string{"internal-service", "graphql", "stateful-connection"},
			Mechanism:      models.MechanismIdentityLeak,
			Label:          "Identity Context Leak to Untrusted Node",
			BaseRisk:       0.7,
			SkillRef:       "skills/auth_logic/oauth_sso_integrity.md",
			Description:    "Identity tokens/cookies propagated across services without re-validation at trust boundaries",
		},
		// === Medium: Workload Escalation ===
		{
			ID:             "workload_escalation",
			RequiredTraits: []string{"workload-identity"},
			OptionalTraits: []string{"aws", "internal-service"},
			Mechanism:      models.MechanismWorkloadEscalation,
			Label:          "Container/Workload → Cloud Role Escalation",
			BaseRisk:       0.85,
			SkillRef:       "skills/infrastructure/workload_identity_federation.md",
			Description:    "Workload identity bridge detected — potential for container escape to cloud control plane via OIDC/mTLS bypass",
		},
		// === Medium: State Desync ===
		{
			ID:             "state_desync",
			RequiredTraits: []string{"stateful-connection"},
			OptionalTraits: []string{"identity-flow", "internal-service"},
			Mechanism:      models.MechanismStateDesync,
			Label:          "WebSocket/Stateful Connection Desync",
			BaseRisk:       0.6,
			SkillRef:       "skills/state_management/websocket_state_abuse.md",
			Description:    "Long-lived stateful connection detected — potential for per-message authorization bypass after initial handshake",
		},
		// === Medium: GraphQL Abuse ===
		{
			ID:             "graphql_abuse",
			RequiredTraits: []string{"graphql"},
			OptionalTraits: []string{"identity-flow", "internal-service"},
			Mechanism:      models.MechanismAccessControlBypass,
			Label:          "GraphQL Complex Query → Authorization Bypass",
			BaseRisk:       0.65,
			SkillRef:       "skills/auth_logic/logic_idor_auth.md",
			Description:    "GraphQL endpoint detected — potential for query depth abuse, batch attacks, and field-level authorization bypass",
		},
		// === Medium: SSRF via Internal Service ===
		{
			ID:             "ssrf_internal",
			RequiredTraits: []string{"internal-service"},
			OptionalTraits: []string{"aws", "workload-identity", "webhook-api"},
			Mechanism:      models.MechanismCloudIdentityTheft,
			Label:          "Internal Service → SSRF to Cloud Metadata",
			BaseRisk:       0.7,
			SkillRef:       "skills/infrastructure/backend_ssrf_rce.md",
			Description:    "Internal service port exposed — potential for SSRF pivot to cloud metadata or internal APIs",
		},
	}
}
