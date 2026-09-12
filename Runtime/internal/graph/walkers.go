package graph

import (
	"fmt"
	"strings"

	"github.com/hacker/runtime/internal/models"
)

// --- Trust Boundary Detection ---

// TrustBoundaryDetector identifies security boundaries in the architectural graph.
type TrustBoundaryDetector struct {
	nodes map[string]*models.Node
	edges map[string]*models.Edge
}

// NewTrustBoundaryDetector creates a new boundary detector.
func NewTrustBoundaryDetector(nodes map[string]*models.Node, edges map[string]*models.Edge) *TrustBoundaryDetector {
	return &TrustBoundaryDetector{nodes: nodes, edges: edges}
}

// DetectAll runs all boundary detection heuristics.
func (d *TrustBoundaryDetector) DetectAll() []models.TrustBoundary {
	var boundaries []models.TrustBoundary

	boundaries = append(boundaries, d.detectGatewayEdges()...)
	boundaries = append(boundaries, d.detectIdentityEdges()...)
	boundaries = append(boundaries, d.detectWorkloadEdges()...)
	boundaries = append(boundaries, d.detectAsyncEdges()...)
	boundaries = append(boundaries, d.detectParserBoundaries()...)

	return boundaries
}

// detectGatewayEdges finds External-to-Internal boundaries.
// Signal: CDN/proxy headers (Cloudflare, CloudFront, Via, X-Forwarded-For)
func (d *TrustBoundaryDetector) detectGatewayEdges() []models.TrustBoundary {
	var boundaries []models.TrustBoundary

	for _, edge := range d.edges {
		if edge.Type == models.EdgeTypeProxyBackend {
			boundaries = append(boundaries, models.TrustBoundary{
				ID:          fmt.Sprintf("boundary_gateway_%s", edge.ID),
				Type:        "Gateway",
				NodeIDs:     []string{edge.SourceID, edge.TargetID},
				EdgeIDs:     []string{edge.ID},
				Mechanism:   "skills/infrastructure/parser_differential_abuse.md",
				Risk:        0.7,
				Description: fmt.Sprintf("Protocol boundary between proxy (%s) and backend (%s)", edge.Properties["proxy_server"], edge.Properties["backend_server"]),
			})
		}
	}

	return boundaries
}

// detectIdentityEdges finds Unauth-to-Auth boundaries.
// Signal: 401/403 responses, redirect to /login, auth endpoints
func (d *TrustBoundaryDetector) detectIdentityEdges() []models.TrustBoundary {
	var boundaries []models.TrustBoundary

	for _, edge := range d.edges {
		if edge.Type == models.EdgeTypeAuthProtection {
			boundaries = append(boundaries, models.TrustBoundary{
				ID:          fmt.Sprintf("boundary_identity_%s", edge.ID),
				Type:        "Identity",
				NodeIDs:     []string{edge.SourceID, edge.TargetID},
				EdgeIDs:     []string{edge.ID},
				Mechanism:   "skills/auth_logic/oauth_sso_integrity.md",
				Risk:        0.6,
				Description: "Cryptographic boundary managed by IdP — auth endpoint protects resource",
			})
		}
	}

	return boundaries
}

// detectWorkloadEdges finds Container-to-Cloud boundaries.
// Signal: IMDS endpoints (169.254.169.254), Kubernetes API, cloud metadata
func (d *TrustBoundaryDetector) detectWorkloadEdges() []models.TrustBoundary {
	var boundaries []models.TrustBoundary

	for _, node := range d.nodes {
		id := strings.ToLower(node.ID)
		props := node.Properties

		isWorkloadBoundary := strings.Contains(id, "169.254.169.254") ||
			strings.Contains(id, "metadata.google.internal") ||
			strings.Contains(id, "kubernetes.default") ||
			props["x-aws-ec2-metadata-token"] != "" ||
			props["x-amz-request-id"] != ""

		if isWorkloadBoundary {
			boundaries = append(boundaries, models.TrustBoundary{
				ID:          fmt.Sprintf("boundary_workload_%s", node.ID),
				Type:        "Workload",
				NodeIDs:     []string{node.ID},
				Mechanism:   "skills/infrastructure/workload_identity_federation.md",
				Risk:        0.9,
				Description: "Workload Identity Bridge between application runtime and cloud control plane",
			})
		}
	}

	return boundaries
}

// detectAsyncEdges finds temporal boundaries (request-time vs. background processing).
// Signal: 202 Accepted, Retry-After header, webhook/callback endpoints
func (d *TrustBoundaryDetector) detectAsyncEdges() []models.TrustBoundary {
	var boundaries []models.TrustBoundary

	for _, edge := range d.edges {
		if edge.Type == models.EdgeTypeAsyncExecution {
			boundaries = append(boundaries, models.TrustBoundary{
				ID:          fmt.Sprintf("boundary_async_%s", edge.ID),
				Type:        "Async",
				NodeIDs:     []string{edge.SourceID, edge.TargetID},
				EdgeIDs:     []string{edge.ID},
				Mechanism:   "skills/state_management/async_workflow_integrity.md",
				Risk:        0.65,
				Description: "Temporal boundary — data moved from request-time to background worker",
			})
		}
	}

	return boundaries
}

// detectParserBoundaries finds where multiple parsers operate on the same data flow.
func (d *TrustBoundaryDetector) detectParserBoundaries() []models.TrustBoundary {
	var boundaries []models.TrustBoundary

	for _, edge := range d.edges {
		if edge.Type == models.EdgeTypeParserTransition {
			boundaries = append(boundaries, models.TrustBoundary{
				ID:          fmt.Sprintf("boundary_parser_%s", edge.ID),
				Type:        "Parser",
				NodeIDs:     []string{edge.SourceID, edge.TargetID},
				EdgeIDs:     []string{edge.ID},
				Mechanism:   "skills/infrastructure/parser_differential_abuse.md",
				Risk:        0.75,
				Description: fmt.Sprintf("Parser transition: %s → %s — potential interpretation desync", edge.Properties["parser_a"], edge.Properties["parser_b"]),
			})
		}
	}

	return boundaries
}

// --- Graph Walkers ---

// TrustBoundaryWalker performs BFS from entry points to discover boundary-crossing paths.
type TrustBoundaryWalker struct {
	nodes      map[string]*models.Node
	edges      map[string]*models.Edge
	boundaries []models.TrustBoundary
	adjacency  map[string][]string // nodeID → [connected nodeIDs]
}

// NewTrustBoundaryWalker creates a walker.
func NewTrustBoundaryWalker(
	nodes map[string]*models.Node,
	edges map[string]*models.Edge,
	boundaries []models.TrustBoundary,
) *TrustBoundaryWalker {
	adj := buildAdjacency(edges)
	return &TrustBoundaryWalker{
		nodes:      nodes,
		edges:      edges,
		boundaries: boundaries,
		adjacency:  adj,
	}
}

// WalkFromEntrypoints performs BFS from all external entry points and returns
// paths that cross trust boundaries.
func (w *TrustBoundaryWalker) WalkFromEntrypoints() []models.BoundaryPath {
	var results []models.BoundaryPath

	// Find entrypoints (nodes with edge-server or gateway indicators)
	var entrypoints []string
	for id, node := range w.nodes {
		if isEntrypoint(node) {
			entrypoints = append(entrypoints, id)
		}
	}

	// BFS from each entrypoint using global visited map per entrypoint to avoid path explosion
	for _, start := range entrypoints {
		paths := w.bfs(start)
		results = append(results, paths...)
	}

	return results
}

func (w *TrustBoundaryWalker) bfs(startID string) []models.BoundaryPath {
	var results []models.BoundaryPath

	type bfsState struct {
		nodeID   string
		path     []string
		edgePath []string
	}

	visited := make(map[string]bool)
	visited[startID] = true

	queue := []bfsState{{
		nodeID:   startID,
		path:     []string{startID},
		edgePath: []string{},
	}}

	// Build boundary lookup: edgeID → boundaryID
	edgeBoundaryMap := make(map[string]string)
	for _, b := range w.boundaries {
		for _, eid := range b.EdgeIDs {
			edgeBoundaryMap[eid] = b.ID
		}
	}

	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]

		neighbors := w.adjacency[current.nodeID]
		for _, neighborID := range neighbors {
			if visited[neighborID] {
				continue
			}
			visited[neighborID] = true

			edgeID := findEdge(w.edges, current.nodeID, neighborID)

			newPath := make([]string, len(current.path), len(current.path)+1)
			copy(newPath, current.path)
			newPath = append(newPath, neighborID)

			newEdgePath := make([]string, len(current.edgePath), len(current.edgePath)+1)
			copy(newEdgePath, current.edgePath)
			if edgeID != "" {
				newEdgePath = append(newEdgePath, edgeID)
			}

			// Check if this path crosses any trust boundary
			var crossedBoundaries []string
			for _, eid := range newEdgePath {
				if bid, ok := edgeBoundaryMap[eid]; ok {
					crossedBoundaries = append(crossedBoundaries, bid)
				}
			}

			if len(crossedBoundaries) > 0 {
				riskScore := float64(len(crossedBoundaries)) * 0.3
				if riskScore > 1.0 {
					riskScore = 1.0
				}
				results = append(results, models.BoundaryPath{
					NodeIDs:    newPath,
					EdgeIDs:    newEdgePath,
					Boundaries: crossedBoundaries,
					RiskScore:  riskScore,
				})
			}

			// Continue BFS (cap depth at 6)
			if len(newPath) < 6 {
				queue = append(queue, bfsState{
					nodeID:   neighborID,
					path:     newPath,
					edgePath: newEdgePath,
				})
			}
		}
	}

	return results
}

// TraceParserChains finds all parser transition sequences in the graph.
func TraceParserChains(nodes map[string]*models.Node, edges map[string]*models.Edge) []models.ParserTransition {
	var transitions []models.ParserTransition

	for _, edge := range edges {
		if edge.Type == models.EdgeTypeParserTransition {
			transitions = append(transitions, models.ParserTransition{
				FromNodeID: edge.SourceID,
				ToNodeID:   edge.TargetID,
				FromParser: edge.Properties["parser_a"],
				ToParser:   edge.Properties["parser_b"],
				DiffRisk:   calculateParserDiffRisk(edge.Properties["parser_a"], edge.Properties["parser_b"]),
			})
		}
	}

	return transitions
}

// TraceIdentityFlows finds all identity propagation paths and detects leaks.
func TraceIdentityFlows(nodes map[string]*models.Node, edges map[string]*models.Edge) []models.IdentityPath {
	var paths []models.IdentityPath

	for _, edge := range edges {
		if edge.Type == models.EdgeTypeIdentityPropagation {
			sourceNode := nodes[edge.SourceID]
			targetNode := nodes[edge.TargetID]

			identityType := "unknown"
			if sourceNode != nil {
				if sourceNode.Properties["authorization"] != "" {
					identityType = "JWT/Bearer"
				} else if sourceNode.Properties["cookie"] != "" {
					identityType = "Cookie"
				} else if sourceNode.Properties["x-api-key"] != "" {
					identityType = "API Key"
				}
			}

			// Detect leak: identity context reaching a node without proper protection
			leakDetected := false
			leakNodeID := ""
			if targetNode != nil && targetNode.Type == models.NodeTypeExternalService {
				leakDetected = true
				leakNodeID = targetNode.ID
			}

			paths = append(paths, models.IdentityPath{
				NodeIDs:      []string{edge.SourceID, edge.TargetID},
				IdentityType: identityType,
				LeakDetected: leakDetected,
				LeakNodeID:   leakNodeID,
			})
		}
	}

	return paths
}

// --- Helpers ---

func buildAdjacency(edges map[string]*models.Edge) map[string][]string {
	adj := make(map[string][]string)
	for _, edge := range edges {
		adj[edge.SourceID] = append(adj[edge.SourceID], edge.TargetID)
		adj[edge.TargetID] = append(adj[edge.TargetID], edge.SourceID) // bidirectional for traversal
	}
	return adj
}

func isEntrypoint(node *models.Node) bool {
	// Nodes served by CDN/edge or on standard public ports
	server := strings.ToLower(node.Properties["server"])
	return isEdgeServer(server) ||
		node.Type == models.NodeTypeGateway ||
		node.Properties["status_code"] == "200" // fallback: any live public host
}

func findEdge(edges map[string]*models.Edge, fromID, toID string) string {
	for id, edge := range edges {
		if (edge.SourceID == fromID && edge.TargetID == toID) ||
			(edge.SourceID == toID && edge.TargetID == fromID) {
			return id
		}
	}
	return ""
}

// calculateParserDiffRisk estimates the risk of a parser differential based on server types.
func calculateParserDiffRisk(parserA, parserB string) float64 {
	a := strings.ToLower(parserA)
	b := strings.ToLower(parserB)

	// H2 gateway → H1.1 backend: highest risk (request smuggling)
	if (strings.Contains(a, "cloudflare") || strings.Contains(a, "cloudfront")) &&
		(strings.Contains(b, "apache") || strings.Contains(b, "nginx") || strings.Contains(b, "gunicorn")) {
		return 0.85
	}

	// nginx → different backend: medium-high risk
	if strings.Contains(a, "nginx") &&
		(strings.Contains(b, "apache") || strings.Contains(b, "tomcat") || strings.Contains(b, "iis")) {
		return 0.75
	}

	// Same vendor, different versions: low risk
	if strings.Split(a, "/")[0] == strings.Split(b, "/")[0] {
		return 0.3
	}

	// Default: moderate risk for any different servers
	return 0.6
}
