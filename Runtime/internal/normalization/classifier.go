package normalization

import (
	"strings"

	"github.com/hacker/runtime/internal/models"
)

// ClassificationRule maps a raw signal pattern to an architectural indicator.
type ClassificationRule struct {
	// Match conditions (OR logic — any one match triggers the rule)
	HeaderKey   string // Check if this header key exists in attributes
	HeaderValue string // Check if any header contains this value (case-insensitive)
	PathPattern string // Check if the URL path contains this pattern
	PortPattern string // Check if the port matches

	// Output
	Indicator  string              // e.g., "Edge Gateway (CDN)"
	Confidence models.ConfidenceLevel
	Rationale  string
}

// Classifier applies architectural classification rules to signals.
type Classifier struct {
	rules []ClassificationRule
}

// NewClassifier creates a classifier with all built-in rules.
// Rules are derived from Architecture_Inference/01_recon_signal_classification.md
func NewClassifier() *Classifier {
	return &Classifier{
		rules: defaultClassificationRules(),
	}
}

// Classify evaluates a signal against all rules and returns matching indicators.
func (c *Classifier) Classify(signal *models.ArchitecturalSignal) []models.ArchitecturalIndicator {
	var indicators []models.ArchitecturalIndicator

	for _, rule := range c.rules {
		if rule.matches(signal) {
			indicators = append(indicators, models.ArchitecturalIndicator{
				Type:           rule.Indicator,
				Confidence:     rule.Confidence,
				SourceSignalID: signal.ID,
				Rationale:      rule.Rationale,
			})
		}
	}

	return indicators
}

// ClassifyAll classifies a batch of signals.
func (c *Classifier) ClassifyAll(signals []*models.ArchitecturalSignal) map[string][]models.ArchitecturalIndicator {
	results := make(map[string][]models.ArchitecturalIndicator)
	for _, signal := range signals {
		indicators := c.Classify(signal)
		if len(indicators) > 0 {
			results[signal.ID] = indicators
		}
	}
	return results
}

func (r *ClassificationRule) matches(signal *models.ArchitecturalSignal) bool {
	id := strings.ToLower(signal.AssetIdentifier)

	// Check header key existence
	if r.HeaderKey != "" {
		if _, ok := signal.Attributes[r.HeaderKey]; ok {
			return true
		}
		// Also check case-insensitive
		for k := range signal.Attributes {
			if strings.EqualFold(k, r.HeaderKey) {
				return true
			}
		}
	}

	// Check header value contains pattern
	if r.HeaderValue != "" {
		pattern := strings.ToLower(r.HeaderValue)
		for _, v := range signal.Attributes {
			if strings.Contains(strings.ToLower(v), pattern) {
				return true
			}
		}
	}

	// Check URL path pattern
	if r.PathPattern != "" {
		if strings.Contains(id, strings.ToLower(r.PathPattern)) {
			return true
		}
	}

	// Check port pattern
	if r.PortPattern != "" {
		if strings.Contains(id, ":"+r.PortPattern+"/") || strings.HasSuffix(id, ":"+r.PortPattern) {
			return true
		}
	}

	return false
}

// defaultClassificationRules returns all built-in heuristics.
func defaultClassificationRules() []ClassificationRule {
	return []ClassificationRule{
		// === Edge Gateway / CDN ===
		{HeaderValue: "cloudflare", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceHigh,
			Rationale: "Cloudflare server header indicates multi-layer architecture with caching/filtering edge"},
		{HeaderKey: "x-amz-cf-id", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceHigh,
			Rationale: "CloudFront CDN header detected"},
		{HeaderKey: "cf-ray", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceHigh,
			Rationale: "Cloudflare Ray ID indicates CDN edge"},
		{HeaderValue: "cloudfront", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceHigh,
			Rationale: "CloudFront header detected"},
		{HeaderValue: "akamai", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceHigh,
			Rationale: "Akamai CDN detected"},
		{HeaderValue: "fastly", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceHigh,
			Rationale: "Fastly CDN detected"},
		{HeaderKey: "x-cache", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceMedium,
			Rationale: "X-Cache header suggests caching proxy layer"},
		{HeaderValue: "varnish", Indicator: "Edge Gateway (CDN)", Confidence: models.ConfidenceMedium,
			Rationale: "Varnish caching proxy detected"},

		// === Binary RPC Interface ===
		{HeaderValue: "application/grpc", Indicator: "Binary RPC Interface", Confidence: models.ConfidenceHigh,
			Rationale: "gRPC content-type indicates length-prefixed, structured parser boundary"},
		{PortPattern: "50051", Indicator: "Binary RPC Interface", Confidence: models.ConfidenceMedium,
			Rationale: "Default gRPC port detected"},
		{HeaderValue: "protobuf", Indicator: "Binary RPC Interface", Confidence: models.ConfidenceHigh,
			Rationale: "Protobuf content-type indicates binary serialization boundary"},

		// === Stateful Connection Hub ===
		{HeaderKey: "sec-websocket-key", Indicator: "Stateful Connection Hub", Confidence: models.ConfidenceHigh,
			Rationale: "WebSocket handshake indicates long-lived TCP state and per-message auth needs"},
		{HeaderKey: "upgrade", Indicator: "Stateful Connection Hub", Confidence: models.ConfidenceMedium,
			Rationale: "Protocol upgrade header — possible WebSocket or HTTP/2"},

		// === Proxy Layer ===
		{HeaderKey: "x-forwarded-for", Indicator: "Proxy Layer", Confidence: models.ConfidenceMedium,
			Rationale: "X-Forwarded-For confirms interpretation boundary between public IP and internal backend"},
		{HeaderKey: "via", Indicator: "Proxy Layer", Confidence: models.ConfidenceMedium,
			Rationale: "Via header confirms intermediate proxy"},
		{HeaderKey: "x-real-ip", Indicator: "Proxy Layer", Confidence: models.ConfidenceMedium,
			Rationale: "X-Real-IP indicates reverse proxy"},

		// === Identity Provider (IdP) ===
		{PathPattern: ".well-known/openid-configuration", Indicator: "Identity Provider (IdP)", Confidence: models.ConfidenceHigh,
			Rationale: "OIDC discovery endpoint indicates federation boundary and trust bridge"},
		{PathPattern: "/oauth", Indicator: "Identity Provider (IdP)", Confidence: models.ConfidenceMedium,
			Rationale: "OAuth endpoint detected"},
		{PathPattern: "/saml", Indicator: "Identity Provider (IdP)", Confidence: models.ConfidenceMedium,
			Rationale: "SAML endpoint detected"},
		{PathPattern: "/.well-known/jwks", Indicator: "Identity Provider (IdP)", Confidence: models.ConfidenceHigh,
			Rationale: "JWKS endpoint indicates JWT-based authentication"},

		// === Permissive Cross-Domain Hub ===
		{HeaderValue: "access-control-allow-origin: *", Indicator: "Permissive Cross-Domain Hub", Confidence: models.ConfidenceMedium,
			Rationale: "Wildcard CORS indicates weak browser-to-backend trust boundary"},
		{HeaderKey: "access-control-allow-origin", Indicator: "Permissive Cross-Domain Hub", Confidence: models.ConfidenceLow,
			Rationale: "CORS header present — check for overly permissive configuration"},

		// === Internal Service / Telemetry ===
		{PortPattern: "9090", Indicator: "Internal Telemetry Port", Confidence: models.ConfidenceMedium,
			Rationale: "Prometheus default port — internal telemetry or service mesh edge"},
		{PortPattern: "8500", Indicator: "Service Discovery Port", Confidence: models.ConfidenceMedium,
			Rationale: "Consul default port — service mesh discovery"},
		{PortPattern: "2379", Indicator: "Coordination Store Port", Confidence: models.ConfidenceMedium,
			Rationale: "etcd default port — Kubernetes coordination store"},
		{PortPattern: "6379", Indicator: "State Backend (Redis)", Confidence: models.ConfidenceMedium,
			Rationale: "Redis default port — shared state backend"},

		// === Async Workflow Hint ===
		{HeaderKey: "retry-after", Indicator: "Async Workflow Hint", Confidence: models.ConfidenceMedium,
			Rationale: "Retry-After suggests back-pressure and background job processing"},

		// === Cloud Metadata / Workload Identity ===
		{PathPattern: "169.254.169.254", Indicator: "Cloud Metadata Endpoint (IMDS)", Confidence: models.ConfidenceHigh,
			Rationale: "AWS/GCP/Azure IMDS endpoint — high-risk identity bridge"},
		{PathPattern: "metadata.google.internal", Indicator: "Cloud Metadata Endpoint (IMDS)", Confidence: models.ConfidenceHigh,
			Rationale: "GCP metadata endpoint"},
		{HeaderKey: "x-aws-ec2-metadata-token", Indicator: "IMDSv2 Detected", Confidence: models.ConfidenceHigh,
			Rationale: "IMDSv2 token header indicates instance metadata service"},
		{HeaderKey: "x-amz-request-id", Indicator: "AWS Service", Confidence: models.ConfidenceMedium,
			Rationale: "AWS request ID indicates AWS-hosted service"},

		// === GraphQL ===
		{PathPattern: "/graphql", Indicator: "GraphQL Interface", Confidence: models.ConfidenceHigh,
			Rationale: "GraphQL endpoint — complex query parser boundary"},

		// === API Gateway ===
		{HeaderKey: "x-amzn-requestid", Indicator: "API Gateway (AWS)", Confidence: models.ConfidenceHigh,
			Rationale: "AWS API Gateway request ID"},
		{HeaderValue: "kong", Indicator: "API Gateway (Kong)", Confidence: models.ConfidenceHigh,
			Rationale: "Kong API Gateway detected"},
		{HeaderValue: "envoy", Indicator: "Service Mesh Proxy (Envoy)", Confidence: models.ConfidenceHigh,
			Rationale: "Envoy proxy — service mesh edge detected"},

		// === Kubernetes ===
		{PathPattern: "kubernetes.default", Indicator: "Kubernetes API Server", Confidence: models.ConfidenceHigh,
			Rationale: "Kubernetes API server endpoint — cluster control plane"},

		// === Application Frameworks ===
		{HeaderValue: "express", Indicator: "Node.js (Express)", Confidence: models.ConfidenceMedium,
			Rationale: "Express.js framework detected"},
		{HeaderValue: "django", Indicator: "Python (Django)", Confidence: models.ConfidenceMedium,
			Rationale: "Django framework detected"},
		{HeaderValue: "spring", Indicator: "Java (Spring)", Confidence: models.ConfidenceMedium,
			Rationale: "Spring framework detected"},
		{HeaderValue: "asp.net", Indicator: ".NET (ASP.NET)", Confidence: models.ConfidenceMedium,
			Rationale: "ASP.NET framework detected"},
	}
}
