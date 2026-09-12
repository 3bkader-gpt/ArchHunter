package graph

import (
	"fmt"
	"net/url"
	"strings"

	"github.com/hacker/runtime/internal/models"
)

// EdgeInferenceEngine builds edges between nodes based on architectural heuristics.
type EdgeInferenceEngine struct {
	nodes map[string]*models.Node
}

// NewEdgeInferenceEngine creates a new edge inference engine.
func NewEdgeInferenceEngine(nodes map[string]*models.Node) *EdgeInferenceEngine {
	return &EdgeInferenceEngine{nodes: nodes}
}

// InferAllEdges runs all edge inference heuristics and returns discovered edges.
func (e *EdgeInferenceEngine) InferAllEdges() []*models.Edge {
	var edges []*models.Edge

	edges = append(edges, e.inferSubdomainRelations()...)
	edges = append(edges, e.inferProxyBackendRelations()...)
	edges = append(edges, e.inferAuthProtectionRelations()...)
	edges = append(edges, e.inferParserTransitions()...)
	edges = append(edges, e.inferAsyncExecutionRelations()...)
	edges = append(edges, e.inferIdentityPropagation()...)

	return edges
}

// inferSubdomainRelations links nodes on the same domain hierarchy.
func (e *EdgeInferenceEngine) inferSubdomainRelations() []*models.Edge {
	var edges []*models.Edge
	hostMap := make(map[string][]string) // host → [nodeIDs]

	for id, node := range e.nodes {
		host := extractHost(node.ID)
		if host != "" {
			hostMap[host] = append(hostMap[host], id)
		}
	}

	// Link subdomains to their parent domains
	for host, nodeIDs := range hostMap {
		parts := strings.Split(host, ".")
		if len(parts) > 2 {
			parent := strings.Join(parts[1:], ".")
			if parentNodeIDs, ok := hostMap[parent]; ok {
				// Link representative nodes to keep graph clean
				for _, childID := range nodeIDs {
					for _, parentID := range parentNodeIDs {
						if childID != parentID {
							edges = append(edges, &models.Edge{
								ID:              fmt.Sprintf("edge_subdomain_%s_%s", childID, parentID),
								SourceID:        childID,
								TargetID:        parentID,
								Type:            models.EdgeTypeSubdomainRelation,
								Properties:      map[string]string{"child_host": host, "parent_host": parent},
								ConfidenceScore: 0.9,
								Rationale:       fmt.Sprintf("%s is a subdomain of %s", host, parent),
							})
						}
					}
				}
			}
		}
	}

	return edges
}

// inferProxyBackendRelations links nodes where proxy headers indicate a frontend→backend relationship.
func (e *EdgeInferenceEngine) inferProxyBackendRelations() []*models.Edge {
	var edges []*models.Edge

	proxyIndicators := []string{
		"x-forwarded-for", "via", "x-real-ip", "cf-ray",
		"x-amz-cf-id", "x-cache", "x-served-by",
	}

	var proxyNodes, backendNodes []*models.Node

	for _, node := range e.nodes {
		isProxy := false
		for _, indicator := range proxyIndicators {
			if _, ok := node.Properties[indicator]; ok {
				isProxy = true
				break
			}
		}
		if isProxy {
			proxyNodes = append(proxyNodes, node)
		} else if node.Properties["server"] != "" && !isEdgeServer(node.Properties["server"]) {
			backendNodes = append(backendNodes, node)
		}
	}

	for _, proxy := range proxyNodes {
		proxyHost := extractRootDomain(extractHost(proxy.ID))
		for _, backend := range backendNodes {
			backendHost := extractRootDomain(extractHost(backend.ID))
			if proxyHost == backendHost && proxy.ID != backend.ID {
				edges = append(edges, &models.Edge{
					ID:       fmt.Sprintf("edge_proxy_%s_%s", proxy.ID, backend.ID),
					SourceID: proxy.ID,
					TargetID: backend.ID,
					Type:     models.EdgeTypeProxyBackend,
					Properties: map[string]string{
						"proxy_server":   proxy.Properties["server"],
						"backend_server": backend.Properties["server"],
					},
					ConfidenceScore: 0.7,
					Rationale:       "Proxy headers detected on source node; both nodes share root domain",
				})
			}
		}
	}

	return edges
}

// inferAuthProtectionRelations links authentication endpoints to the resources they protect.
func (e *EdgeInferenceEngine) inferAuthProtectionRelations() []*models.Edge {
	var edges []*models.Edge

	var authNodes []*models.Node
	var protectedNodes []*models.Node

	for _, node := range e.nodes {
		path := extractPath(node.ID)
		props := node.Properties

		isAuthEndpoint := strings.Contains(path, "/login") ||
			strings.Contains(path, "/auth") ||
			strings.Contains(path, "/oauth") ||
			strings.Contains(path, "/sso") ||
			strings.Contains(path, "/.well-known/openid-configuration") ||
			strings.Contains(path, "/token")

		if isAuthEndpoint {
			authNodes = append(authNodes, node)
			continue
		}

		isProtected := props["status_code"] == "401" ||
			props["status_code"] == "403" ||
			props["authorization"] != "" ||
			props["cookie"] != ""

		if isProtected {
			protectedNodes = append(protectedNodes, node)
		}
	}

	for _, auth := range authNodes {
		authDomain := extractRootDomain(extractHost(auth.ID))
		for _, protected := range protectedNodes {
			protDomain := extractRootDomain(extractHost(protected.ID))
			if authDomain == protDomain {
				edges = append(edges, &models.Edge{
					ID:              fmt.Sprintf("edge_auth_%s_%s", auth.ID, protected.ID),
					SourceID:        auth.ID,
					TargetID:        protected.ID,
					Type:            models.EdgeTypeAuthProtection,
					Properties:      map[string]string{"auth_type": "inferred"},
					ConfidenceScore: 0.6,
					Rationale:       "Auth endpoint and protected resource share root domain",
				})
			}
		}
	}

	return edges
}

// inferParserTransitions links frontend edge nodes to backend nodes with different server headers.
func (e *EdgeInferenceEngine) inferParserTransitions() []*models.Edge {
	var edges []*models.Edge

	var edgeGateways, internalBackends []*models.Node
	for _, node := range e.nodes {
		server := node.Properties["server"]
		if isEdgeServer(server) {
			edgeGateways = append(edgeGateways, node)
		} else if server != "" {
			internalBackends = append(internalBackends, node)
		}
	}

	for _, gateway := range edgeGateways {
		gDomain := extractRootDomain(extractHost(gateway.ID))
		for _, backend := range internalBackends {
			bDomain := extractRootDomain(extractHost(backend.ID))
			if gDomain == bDomain {
				edges = append(edges, &models.Edge{
					ID:       fmt.Sprintf("edge_parser_%s_%s", gateway.ID, backend.ID),
					SourceID: gateway.ID,
					TargetID: backend.ID,
					Type:     models.EdgeTypeParserTransition,
					Properties: map[string]string{
						"parser_a": gateway.Properties["server"],
						"parser_b": backend.Properties["server"],
					},
					ConfidenceScore: 0.75,
					Rationale: fmt.Sprintf("Edge gateway (%s) to internal backend (%s) parser transition",
						gateway.Properties["server"], backend.Properties["server"]),
				})
			}
		}
	}

	return edges
}

// inferAsyncExecutionRelations links nodes that indicate async workflows.
func (e *EdgeInferenceEngine) inferAsyncExecutionRelations() []*models.Edge {
	var edges []*models.Edge

	var asyncTriggers []*models.Node
	var webhookReceivers []*models.Node

	for _, node := range e.nodes {
		path := extractPath(node.ID)

		isAsync := node.Properties["status_code"] == "202" ||
			node.Properties["retry-after"] != "" ||
			node.Properties["retry_after"] != ""

		isWebhook := strings.Contains(path, "/webhook") ||
			strings.Contains(path, "/callback") ||
			strings.Contains(path, "/hook")

		if isAsync {
			asyncTriggers = append(asyncTriggers, node)
		}
		if isWebhook {
			webhookReceivers = append(webhookReceivers, node)
		}
	}

	for _, trigger := range asyncTriggers {
		triggerDomain := extractRootDomain(extractHost(trigger.ID))
		for _, receiver := range webhookReceivers {
			receiverDomain := extractRootDomain(extractHost(receiver.ID))
			if triggerDomain == receiverDomain {
				edges = append(edges, &models.Edge{
					ID:              fmt.Sprintf("edge_async_%s_%s", trigger.ID, receiver.ID),
					SourceID:        trigger.ID,
					TargetID:        receiver.ID,
					Type:            models.EdgeTypeAsyncExecution,
					Properties:      map[string]string{"trigger_type": "202_accepted"},
					ConfidenceScore: 0.55,
					Rationale:       "Async trigger (202 Accepted) linked to webhook receiver on same domain",
				})
			}
		}
	}

	return edges
}

// inferIdentityPropagation links auth token providers to authenticated endpoints.
func (e *EdgeInferenceEngine) inferIdentityPropagation() []*models.Edge {
	var edges []*models.Edge

	var authEndpoints []*models.Node
	var authenticatedNodes []*models.Node

	for _, node := range e.nodes {
		path := extractPath(node.ID)
		if strings.Contains(path, "/login") || strings.Contains(path, "/token") || strings.Contains(path, "/oauth") {
			authEndpoints = append(authEndpoints, node)
		}
		if node.Properties["authorization"] != "" || node.Properties["cookie"] != "" {
			authenticatedNodes = append(authenticatedNodes, node)
		}
	}

	for _, auth := range authEndpoints {
		authDomain := extractRootDomain(extractHost(auth.ID))
		for _, authed := range authenticatedNodes {
			authedDomain := extractRootDomain(extractHost(authed.ID))
			if authDomain == authedDomain && auth.ID != authed.ID {
				edges = append(edges, &models.Edge{
					ID:       fmt.Sprintf("edge_identity_%s_%s", auth.ID, authed.ID),
					SourceID: auth.ID,
					TargetID: authed.ID,
					Type:     models.EdgeTypeIdentityPropagation,
					Properties: map[string]string{
						"identity_context": "token_flow",
					},
					ConfidenceScore: 0.7,
					Rationale:       "Identity context issued at auth endpoint flows to authenticated node",
				})
			}
		}
	}

	return edges
}

// --- Helpers ---

func extractHost(identifier string) string {
	if u, err := url.Parse(identifier); err == nil && u.Host != "" {
		return u.Hostname()
	}
	if strings.Contains(identifier, ".") && !strings.Contains(identifier, "/") {
		return identifier
	}
	return ""
}

func extractRootDomain(host string) string {
	parts := strings.Split(host, ".")
	if len(parts) >= 2 {
		return strings.Join(parts[len(parts)-2:], ".")
	}
	return host
}

func extractPath(identifier string) string {
	if u, err := url.Parse(identifier); err == nil {
		return strings.ToLower(u.Path)
	}
	return ""
}

func isEdgeServer(server string) bool {
	s := strings.ToLower(server)
	edgeServers := []string{"cloudflare", "cloudfront", "akamai", "fastly", "varnish", "cdn"}
	for _, edge := range edgeServers {
		if strings.Contains(s, edge) {
			return true
		}
	}
	return false
}
