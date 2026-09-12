package normalization

import (
	"context"
	"testing"
)

func TestNormalizer_ToolDetection(t *testing.T) {
	ctx := context.Background()
	norm := NewNormalizer()

	// 1. Test httpx JSON
	httpxJSON := []byte(`{"url":"https://api.target.com/v1/user","server":"cloudflare","status_code":200,"content_type":"application/json"}`)
	sig1, err := norm.Normalize(ctx, httpxJSON)
	if err != nil {
		t.Fatalf("failed to normalize httpx: %v", err)
	}
	if sig1.Source != "httpx" {
		t.Errorf("expected source httpx, got %s", sig1.Source)
	}
	if sig1.AssetIdentifier != "https://api.target.com/v1/user" {
		t.Errorf("unexpected asset identifier: %s", sig1.AssetIdentifier)
	}

	// 2. Test katana JSON
	katanaJSON := []byte(`{"input":"https://api.target.com/v1/auth","endpoint":"https://api.target.com/v1/auth","method":"POST"}`)
	sig2, err := norm.Normalize(ctx, katanaJSON)
	if err != nil {
		t.Fatalf("failed to normalize katana: %v", err)
	}
	if sig2.Source != "katana" {
		t.Errorf("expected source katana, got %s", sig2.Source)
	}

	// 3. Test subfinder JSON
	subfinderJSON := []byte(`{"host":"api.target.com"}`)
	sig3, err := norm.Normalize(ctx, subfinderJSON)
	if err != nil {
		t.Fatalf("failed to normalize subfinder: %v", err)
	}
	if sig3.Source != "subfinder" {
		t.Errorf("expected source subfinder, got %s", sig3.Source)
	}
}

func TestClassifier_Rules(t *testing.T) {
	ctx := context.Background()
	norm := NewNormalizer()
	classifier := NewClassifier()

	raw := []byte(`{"url":"https://api.target.com/.well-known/openid-configuration","server":"cloudflare","content_type":"application/json"}`)
	sig, err := norm.Normalize(ctx, raw)
	if err != nil {
		t.Fatalf("normalization error: %v", err)
	}

	indicators := classifier.Classify(sig)
	if len(indicators) == 0 {
		t.Fatalf("expected architectural indicators to be found")
	}

	foundIdP := false
	for _, ind := range indicators {
		if ind.Type == "Identity Provider (IdP)" {
			foundIdP = true
		}
	}
	if !foundIdP {
		t.Errorf("expected to find Identity Provider indicator")
	}
}
