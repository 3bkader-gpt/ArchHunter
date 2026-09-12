package graph

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/hacker/runtime/internal/models"
)

// Engine is the core graph engine that manages the architectural graph.
type Engine struct {
	mu         sync.RWMutex
	nodes      map[string]*models.Node
	edges      map[string]*models.Edge
	boundaries []models.TrustBoundary
	signals    []*models.ArchitecturalSignal // Retained for provenance
}

// NewEngine creates a new graph engine.
func NewEngine() *Engine {
	return &Engine{
		nodes: make(map[string]*models.Node),
		edges: make(map[string]*models.Edge),
	}
}

// AddSignal ingests a normalized signal and upserts the corresponding node.
func (e *Engine) AddSignal(ctx context.Context, signal *models.ArchitecturalSignal) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	e.signals = append(e.signals, signal)
	now := time.Now()

	if existing, exists := e.nodes[signal.AssetIdentifier]; !exists {
		// Create a new node
		e.nodes[signal.AssetIdentifier] = &models.Node{
			ID:              signal.AssetIdentifier,
			Type:            classifyNodeType(signal),
			Layer:           "physical",
			Labels:          []string{signal.Source},
			Properties:      copyMap(signal.Attributes),
			ConfidenceScore: signal.Confidence,
			FirstSeen:       now,
			LastSeen:        now,
			EvidenceIDs:     []string{signal.ID},
			Indicators:      nil,
		}
		if e.nodes[signal.AssetIdentifier].ConfidenceScore == 0 {
			e.nodes[signal.AssetIdentifier].ConfidenceScore = 0.5
		}
	} else {
		// Update existing node — merge properties and boost confidence
		for k, v := range signal.Attributes {
			existing.Properties[k] = v
		}
		existing.EvidenceIDs = append(existing.EvidenceIDs, signal.ID)
		existing.LastSeen = now

		// Add source label if not already present
		if !containsStr(existing.Labels, signal.Source) {
			existing.Labels = append(existing.Labels, signal.Source)
		}

		// Incremental confidence boost for corroborating evidence
		existing.ConfidenceScore += 0.05
		if existing.ConfidenceScore > 1.0 {
			existing.ConfidenceScore = 1.0
		}

		// Re-classify node type if new evidence changes the picture
		newType := classifyNodeType(signal)
		if newType != models.NodeTypeUnknown && existing.Type == models.NodeTypeUnknown {
			existing.Type = newType
		}
	}

	return nil
}

// InferEdges runs all edge inference heuristics on the current graph.
func (e *Engine) InferEdges(ctx context.Context) int {
	e.mu.Lock()
	defer e.mu.Unlock()

	inferrer := NewEdgeInferenceEngine(e.nodes)
	newEdges := inferrer.InferAllEdges()

	count := 0
	for _, edge := range newEdges {
		if _, exists := e.edges[edge.ID]; !exists {
			e.edges[edge.ID] = edge
			count++
		}
	}

	return count
}

// DetectTrustBoundaries identifies security boundaries in the graph.
func (e *Engine) DetectTrustBoundaries(ctx context.Context) []models.TrustBoundary {
	e.mu.Lock()
	defer e.mu.Unlock()

	detector := NewTrustBoundaryDetector(e.nodes, e.edges)
	e.boundaries = detector.DetectAll()

	return e.boundaries
}

// WalkTrustBoundaries performs BFS from entry points and returns paths crossing boundaries.
func (e *Engine) WalkTrustBoundaries(ctx context.Context) []models.BoundaryPath {
	e.mu.RLock()
	defer e.mu.RUnlock()

	walker := NewTrustBoundaryWalker(e.nodes, e.edges, e.boundaries)
	return walker.WalkFromEntrypoints()
}

// TraceParserChains returns all parser transitions detected in the graph.
func (e *Engine) TraceParserChains(ctx context.Context) []models.ParserTransition {
	e.mu.RLock()
	defer e.mu.RUnlock()

	return TraceParserChains(e.nodes, e.edges)
}

// TraceIdentityFlows returns all identity propagation paths and leak detections.
func (e *Engine) TraceIdentityFlows(ctx context.Context) []models.IdentityPath {
	e.mu.RLock()
	defer e.mu.RUnlock()

	return TraceIdentityFlows(e.nodes, e.edges)
}

// GetGraph returns a snapshot of all nodes and edges.
func (e *Engine) GetGraph(ctx context.Context) ([]models.Node, []models.Edge) {
	e.mu.RLock()
	defer e.mu.RUnlock()

	nodes := make([]models.Node, 0, len(e.nodes))
	for _, n := range e.nodes {
		nodes = append(nodes, *n)
	}

	edges := make([]models.Edge, 0, len(e.edges))
	for _, ed := range e.edges {
		edges = append(edges, *ed)
	}

	return nodes, edges
}

// GetSnapshot returns a complete snapshot of the graph state.
func (e *Engine) GetSnapshot(ctx context.Context, sessionID string) models.GraphSnapshot {
	nodes, edges := e.GetGraph(ctx)

	e.mu.RLock()
	boundaries := make([]models.TrustBoundary, len(e.boundaries))
	copy(boundaries, e.boundaries)
	e.mu.RUnlock()

	return models.GraphSnapshot{
		SessionID:       sessionID,
		Timestamp:       time.Now(),
		Nodes:           nodes,
		Edges:           edges,
		TrustBoundaries: boundaries,
	}
}

// GetStats returns summary statistics about the graph.
func (e *Engine) GetStats() (nodeCount, edgeCount, boundaryCount int) {
	e.mu.RLock()
	defer e.mu.RUnlock()
	return len(e.nodes), len(e.edges), len(e.boundaries)
}

// --- Node Classification ---

// classifyNodeType determines the node type from signal attributes.
func classifyNodeType(signal *models.ArchitecturalSignal) models.NodeType {
	props := signal.Attributes
	id := strings.ToLower(signal.AssetIdentifier)

	// Gateway / CDN detection
	server := strings.ToLower(props["server"])
	if isEdgeServer(server) {
		return models.NodeTypeGateway
	}

	// Identity boundary detection
	if strings.Contains(id, "/.well-known/openid-configuration") ||
		strings.Contains(id, "/oauth") ||
		strings.Contains(id, "/saml") {
		return models.NodeTypeIdentityBoundary
	}

	// Workload identity detection
	if strings.Contains(id, "169.254.169.254") ||
		strings.Contains(id, "metadata.google.internal") ||
		strings.Contains(id, "kubernetes.default") {
		return models.NodeTypeWorkloadIdentity
	}

	// Async workflow detection
	if props["status_code"] == "202" || props["retry-after"] != "" || props["retry_after"] != "" {
		return models.NodeTypeAsyncWorkflow
	}

	// gRPC / binary RPC detection
	contentType := strings.ToLower(props["content_type"])
	if strings.Contains(contentType, "grpc") || strings.Contains(contentType, "protobuf") {
		return models.NodeTypeParserBoundary
	}

	// WebSocket detection
	if props["sec-websocket-key"] != "" || props["upgrade"] == "websocket" {
		return models.NodeTypeDistributedState
	}

	// Internal service ports
	port := extractPort(id)
	if port == "50051" || port == "9090" || port == "8500" || port == "2379" {
		return models.NodeTypeInternalService
	}

	return models.NodeTypeUnknown
}

func extractPort(identifier string) string {
	parts := strings.Split(identifier, ":")
	if len(parts) >= 3 {
		// https://host:port/path
		portPath := parts[2]
		port := strings.Split(portPath, "/")[0]
		return port
	}
	return ""
}

func copyMap(src map[string]string) map[string]string {
	dst := make(map[string]string, len(src))
	for k, v := range src {
		dst[k] = v
	}
	return dst
}

func containsStr(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// --- Debug Helpers ---

// PrintGraph outputs a text summary of the graph for debugging.
func (e *Engine) PrintGraph() {
	e.mu.RLock()
	defer e.mu.RUnlock()

	fmt.Printf("\n=== GRAPH STATE ===\n")
	fmt.Printf("Nodes: %d | Edges: %d | Boundaries: %d\n\n", len(e.nodes), len(e.edges), len(e.boundaries))

	fmt.Println("--- Nodes ---")
	for _, node := range e.nodes {
		fmt.Printf("  [%s] %s (type=%s, layer=%s, conf=%.2f, evidence=%d)\n",
			node.ID, node.Labels, node.Type, node.Layer, node.ConfidenceScore, len(node.EvidenceIDs))
	}

	fmt.Println("\n--- Edges ---")
	for _, edge := range e.edges {
		fmt.Printf("  %s → %s (type=%s, conf=%.2f) — %s\n",
			edge.SourceID, edge.TargetID, edge.Type, edge.ConfidenceScore, edge.Rationale)
	}

	fmt.Println("\n--- Trust Boundaries ---")
	for _, b := range e.boundaries {
		fmt.Printf("  [%s] %s (type=%s, risk=%.2f) — %s\n",
			b.ID, b.Description, b.Type, b.Risk, b.Mechanism)
	}
	fmt.Println()
}
