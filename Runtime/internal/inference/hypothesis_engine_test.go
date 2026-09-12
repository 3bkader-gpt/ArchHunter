package inference

import (
	"context"
	"testing"
	"time"

	"github.com/hacker/runtime/internal/models"
)

func TestHypothesisEngine_Generate(t *testing.T) {
	ctx := context.Background()
	engine := NewHypothesisEngine()

	snapshot := models.GraphSnapshot{
		SessionID: "test_session",
		Timestamp: time.Now(),
		Nodes: []models.Node{
			{
				ID:    "https://api.target.com/v1/users",
				Type:  models.NodeTypeGateway,
				Layer: "physical",
				Properties: map[string]string{
					"server":       "cloudflare",
					"content_type": "application/json",
				},
				ConfidenceScore: 0.9,
			},
			{
				ID:    "https://internal.target.com:8443/orders",
				Type:  models.NodeTypeInternalService,
				Layer: "physical",
				Properties: map[string]string{
					"server":        "nginx/1.21",
					"authorization": "Bearer eyJhbGciOi...",
				},
				ConfidenceScore: 0.8,
			},
			{
				ID:    "http://169.254.169.254/latest/meta-data",
				Type:  models.NodeTypeWorkloadIdentity,
				Layer: "physical",
				Properties: map[string]string{
					"x-aws-ec2-metadata-token": "required",
				},
				ConfidenceScore: 0.95,
			},
		},
		Edges: []models.Edge{
			{
				ID:       "edge_parser_1",
				SourceID: "https://api.target.com/v1/users",
				TargetID: "https://internal.target.com:8443/orders",
				Type:     models.EdgeTypeParserTransition,
				Properties: map[string]string{
					"parser_a": "cloudflare",
					"parser_b": "nginx",
				},
				ConfidenceScore: 0.8,
			},
		},
	}

	hypos := engine.Generate(ctx, snapshot)
	if len(hypos) == 0 {
		t.Fatalf("expected hypotheses to be generated, got 0")
	}

	foundSmuggling := false
	foundCloudTheft := false

	for _, h := range hypos {
		if h.Mechanism == models.MechanismRequestSmuggling {
			foundSmuggling = true
		}
		if h.Mechanism == models.MechanismCloudIdentityTheft {
			foundCloudTheft = true
		}
	}

	if !foundSmuggling {
		t.Errorf("expected Request Smuggling hypothesis to be generated")
	}
	if !foundCloudTheft {
		t.Errorf("expected Cloud Identity Theft hypothesis to be generated")
	}
}
