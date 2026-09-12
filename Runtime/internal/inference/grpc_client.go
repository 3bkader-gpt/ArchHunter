package inference

import (
	"context"
	"fmt"
	"time"

	"github.com/hacker/runtime/internal/models"
	graph_pb "github.com/hacker/runtime/proto/graph"
	hypothesis_pb "github.com/hacker/runtime/proto/hypothesis"
	reasoning_pb "github.com/hacker/runtime/proto/reasoning"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

// GrpcClient implements the InferenceClient interface via gRPC to Python reasoning workers.
type GrpcClient struct {
	endpoints map[string]string
}

// NewGrpcClient creates a new gRPC inference client connected to remote reasoning workers.
func NewGrpcClient(endpoints map[string]string) *GrpcClient {
	return &GrpcClient{
		endpoints: endpoints,
	}
}

// RunInference dispatches inference tasks to connected Python reasoning workers.
func (c *GrpcClient) RunInference(ctx context.Context, nodes []models.Node) ([]models.AttackHypothesis, error) {
	if len(nodes) == 0 {
		return []models.AttackHypothesis{}, nil
	}

	var allHypotheses []models.AttackHypothesis

	// Convert models.Node list to graph_pb.Node list
	pbNodes := make([]*graph_pb.Node, 0, len(nodes))
	for _, n := range nodes {
		pbNodes = append(pbNodes, &graph_pb.Node{
			Id:              n.ID,
			Layer:           n.Layer,
			Labels:          n.Labels,
			Properties:      n.Properties,
			ConfidenceScore: float32(n.ConfidenceScore),
		})
	}

	subGraph := &graph_pb.GraphSnapshot{
		SessionId: "grpc_inference_session",
		Nodes:     pbNodes,
	}

	task := &reasoning_pb.InferenceTask{
		TaskId:   fmt.Sprintf("task_%d", time.Now().UnixNano()),
		SubGraph: subGraph,
	}

	// Dispatch to configured worker endpoints
	for workerName, endpoint := range c.endpoints {
		conn, err := grpc.DialContext(ctx, endpoint,
			grpc.WithTransportCredentials(insecure.NewCredentials()),
			grpc.WithBlock(),
			grpc.WithTimeout(500*time.Millisecond),
		)
		if err != nil {
			// Fallback log for offline workers
			fmt.Printf("  [gRPC] Worker %s at %s offline (skipping remote call)\n", workerName, endpoint)
			continue
		}
		defer conn.Close()

		client := reasoning_pb.NewReasoningWorkerClient(conn)
		res, err := client.Infer(ctx, task)
		if err != nil {
			fmt.Printf("  [gRPC] Worker %s error: %v\n", workerName, err)
			continue
		}

		// Map proto hypotheses to models.AttackHypothesis
		for _, h := range res.Hypotheses {
			allHypotheses = append(allHypotheses, models.AttackHypothesis{
				ID:              h.Id,
				Mechanism:       models.MechanismClass(h.Mechanism.String()),
				MechanismLabel:  fmt.Sprintf("[%s] %s", workerName, h.Mechanism.String()),
				PathNodeIDs:     h.PathNodeIds,
				RiskScore:       float64(h.RiskScore),
				ConfidenceScore: float64(h.ConfidenceScore),
				Rationale:       h.Rationale,
				GeneratedAt:     time.Now(),
			})
		}
	}

	return allHypotheses, nil
}

// ConvertMechanismProto converts proto enum to string model.
func ConvertMechanismProto(m hypothesis_pb.MechanismClass) models.MechanismClass {
	switch m {
	case hypothesis_pb.MechanismClass_PARSER_DIFFERENTIAL:
		return models.MechanismParserDifferential
	case hypothesis_pb.MechanismClass_IDENTITY_LEAK:
		return models.MechanismIdentityLeak
	case hypothesis_pb.MechanismClass_WORKLOAD_ESCALATION:
		return models.MechanismWorkloadEscalation
	case hypothesis_pb.MechanismClass_ASYNC_TRUST_DECAY:
		return models.MechanismAsyncTrustDecay
	case hypothesis_pb.MechanismClass_CONSISTENCY_FAILURE:
		return models.MechanismConsistencyFailure
	case hypothesis_pb.MechanismClass_STALE_AUTH_PROPAGATION:
		return models.MechanismStaleAuthPropagation
	default:
		return models.MechanismParserDifferential
	}
}
