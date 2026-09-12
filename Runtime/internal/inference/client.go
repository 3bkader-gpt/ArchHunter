package inference

import (
	"context"

	"github.com/hacker/runtime/internal/models"
)

type MockClient struct{}

func NewMockClient() *MockClient {
	return &MockClient{}
}

func (c *MockClient) RunInference(ctx context.Context, nodes []models.Node) ([]models.AttackHypothesis, error) {
	// For MVP, we just generate a static hypothesis if nodes exist
	if len(nodes) == 0 {
		return []models.AttackHypothesis{}, nil
	}

	return []models.AttackHypothesis{
		{
			ID:              "hypo_mvp_1",
			Mechanism:       "Inferred Trust Boundary",
			PathNodeIDs:     []string{nodes[0].ID},
			RiskScore:       0.7,
			ConfidenceScore: 0.5,
			Rationale:       "Multiple physical signals detected for this node.",
		},
	}, nil
}
