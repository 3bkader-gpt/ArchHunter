package graph

import (
	"context"
	"testing"
	"time"

	"github.com/hacker/runtime/internal/models"
)

func TestEngine_AddSignalAndEdgeInference(t *testing.T) {
	ctx := context.Background()
	engine := NewEngine()

	// 1. Add Cloudflare edge gateway signal
	sig1 := &models.ArchitecturalSignal{
		ID:              "sig_1",
		Source:          "httpx",
		Timestamp:       time.Now(),
		AssetIdentifier: "https://api.target.com/v1/users",
		Attributes: map[string]string{
			"server":          "cloudflare",
			"status_code":     "200",
			"x-forwarded-for": "10.0.0.1",
		},
		Confidence: 0.8,
	}

	// 2. Add backend internal service signal
	sig2 := &models.ArchitecturalSignal{
		ID:              "sig_2",
		Source:          "httpx",
		Timestamp:       time.Now(),
		AssetIdentifier: "https://internal.target.com:8443/orders",
		Attributes: map[string]string{
			"server":        "nginx/1.21",
			"status_code":   "401",
			"authorization": "Bearer token",
		},
		Confidence: 0.7,
	}

	// 3. Add auth login signal
	sig3 := &models.ArchitecturalSignal{
		ID:              "sig_3",
		Source:          "httpx",
		Timestamp:       time.Now(),
		AssetIdentifier: "https://api.target.com/v1/auth/login",
		Attributes: map[string]string{
			"server":      "cloudflare",
			"status_code": "200",
		},
		Confidence: 0.9,
	}

	if err := engine.AddSignal(ctx, sig1); err != nil {
		t.Fatalf("failed to add signal 1: %v", err)
	}
	if err := engine.AddSignal(ctx, sig2); err != nil {
		t.Fatalf("failed to add signal 2: %v", err)
	}
	if err := engine.AddSignal(ctx, sig3); err != nil {
		t.Fatalf("failed to add signal 3: %v", err)
	}

	nodeCount, _, _ := engine.GetStats()
	if nodeCount != 3 {
		t.Fatalf("expected 3 nodes, got %d", nodeCount)
	}

	// Run Edge Inference
	edgesInferred := engine.InferEdges(ctx)
	if edgesInferred == 0 {
		t.Fatalf("expected edges to be inferred, got 0")
	}

	// Detect Trust Boundaries
	boundaries := engine.DetectTrustBoundaries(ctx)
	if len(boundaries) == 0 {
		t.Fatalf("expected trust boundaries to be detected, got 0")
	}

	// Walk Trust Boundaries
	paths := engine.WalkTrustBoundaries(ctx)
	if len(paths) == 0 {
		t.Logf("Note: no paths crossed boundaries or entrypoints found: %d paths", len(paths))
	}
}
