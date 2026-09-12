package correlation

import (
	"testing"
	"time"

	"github.com/hacker/runtime/internal/models"
)

func TestCorrelator_FuseSignals(t *testing.T) {
	correlator := NewCorrelator()

	signals := []*models.ArchitecturalSignal{
		{
			ID:              "sig_1",
			Source:          "httpx",
			Timestamp:       time.Now(),
			AssetIdentifier: "https://api.target.com/v1/user",
			Attributes: map[string]string{
				"server": "cloudflare",
				"status": "200",
			},
			Confidence: 0.8,
		},
		{
			ID:              "sig_2",
			Source:          "katana",
			Timestamp:       time.Now(),
			AssetIdentifier: "https://api.target.com/v1/user",
			Attributes: map[string]string{
				"method": "GET",
			},
			Confidence: 0.6,
		},
	}

	fused := correlator.FuseSignals(signals)
	if len(fused) != 1 {
		t.Fatalf("expected 1 fused evidence object, got %d", len(fused))
	}

	if len(fused[0].SourceSignalIDs) != 2 {
		t.Errorf("expected 2 source signals fused, got %d", len(fused[0].SourceSignalIDs))
	}

	// Multi-source bonus check
	if fused[0].Confidence <= 0.7 {
		t.Errorf("expected confidence boost from multi-tool corroboration, got %.2f", fused[0].Confidence)
	}
}

func TestCorrelator_CloudCorrelation(t *testing.T) {
	correlator := NewCorrelator()

	signals := []*models.ArchitecturalSignal{
		{
			ID:              "sig_aws_1",
			Source:          "httpx",
			AssetIdentifier: "https://s3.amazonaws.com/target-assets/app.js",
			Attributes: map[string]string{
				"x-amz-request-id": "123",
			},
			Confidence: 0.8,
		},
		{
			ID:              "sig_aws_2",
			Source:          "httpx",
			AssetIdentifier: "https://cdn.target.com/assets/config.json",
			Attributes: map[string]string{
				"x-amz-cf-id": "456",
			},
			Confidence: 0.85,
		},
	}

	cloudEvidence := correlator.CorrelateCloudProvider(signals)
	if len(cloudEvidence) == 0 {
		t.Fatalf("expected cloud correlation evidence to be generated")
	}
}
