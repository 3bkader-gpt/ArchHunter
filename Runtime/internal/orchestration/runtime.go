package orchestration

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/hacker/runtime/internal/models"
)

// Runtime orchestrates the full reasoning pipeline.
type Runtime struct {
	pipeline      IngestionPipeline
	graph         GraphEngine
	inference     InferenceClient
	hypothesis    HypothesisGenerator
	classifier    SignalClassifier
}

// --- Interfaces ---

type IngestionPipeline interface {
	ProcessFile(ctx context.Context, filePath string) error
}

type GraphEngine interface {
	GetGraph(ctx context.Context) ([]models.Node, []models.Edge)
	GetSnapshot(ctx context.Context, sessionID string) models.GraphSnapshot
	InferEdges(ctx context.Context) int
	DetectTrustBoundaries(ctx context.Context) []models.TrustBoundary
	WalkTrustBoundaries(ctx context.Context) []models.BoundaryPath
	TraceParserChains(ctx context.Context) []models.ParserTransition
	TraceIdentityFlows(ctx context.Context) []models.IdentityPath
	GetStats() (nodeCount, edgeCount, boundaryCount int)
	PrintGraph()
}

type InferenceClient interface {
	RunInference(ctx context.Context, nodes []models.Node) ([]models.AttackHypothesis, error)
}

type HypothesisGenerator interface {
	Generate(ctx context.Context, snapshot models.GraphSnapshot) []models.AttackHypothesis
}

type SignalClassifier interface {
	Classify(signal *models.ArchitecturalSignal) []models.ArchitecturalIndicator
}

// NewRuntime creates a runtime with all components.
func NewRuntime(
	p IngestionPipeline,
	g GraphEngine,
	i InferenceClient,
	h HypothesisGenerator,
) *Runtime {
	return &Runtime{
		pipeline:   p,
		graph:      g,
		inference:  i,
		hypothesis: h,
	}
}

// ExecuteMVP runs the legacy linear pipeline (backward compatible).
func (r *Runtime) ExecuteMVP(ctx context.Context, inputFiles []string, outputDFD, outputHypo string) error {
	// 1. Ingest & Construct Graph
	for _, file := range inputFiles {
		if err := r.pipeline.ProcessFile(ctx, file); err != nil {
			return fmt.Errorf("failed to process %s: %w", file, err)
		}
	}

	// 2. Extract DFD
	nodes, edges := r.graph.GetGraph(ctx)
	dfd := map[string]interface{}{
		"nodes": nodes,
		"edges": edges,
	}

	dfdBytes, _ := json.MarshalIndent(dfd, "", "  ")
	if err := os.WriteFile(outputDFD, dfdBytes, 0644); err != nil {
		return fmt.Errorf("failed to write DFD: %w", err)
	}

	// 3. Run Inference
	hypotheses, err := r.inference.RunInference(ctx, nodes)
	if err != nil {
		return fmt.Errorf("inference failed: %w", err)
	}

	hypoBytes, _ := json.MarshalIndent(hypotheses, "", "  ")
	if err := os.WriteFile(outputHypo, hypoBytes, 0644); err != nil {
		return fmt.Errorf("failed to write Hypotheses: %w", err)
	}

	return nil
}

// ExecuteFull runs the complete reasoning pipeline.
func (r *Runtime) ExecuteFull(ctx context.Context, cfg ExecutionConfig) (*models.HypothesisReport, error) {
	startTime := time.Now()

	// === Phase 1: Ingestion ===
	fmt.Println("\n[Phase 1/7] Ingesting recon signals...")
	for _, file := range cfg.InputFiles {
		if err := r.pipeline.ProcessFile(ctx, file); err != nil {
			return nil, fmt.Errorf("failed to process %s: %w", file, err)
		}
	}
	nodeCount, _, _ := r.graph.GetStats()
	fmt.Printf("  → Ingested signals → %d nodes created\n", nodeCount)

	// === Phase 2: Edge Inference ===
	fmt.Println("[Phase 2/7] Inferring graph edges...")
	edgeCount := r.graph.InferEdges(ctx)
	fmt.Printf("  → %d edges inferred\n", edgeCount)

	// === Phase 3: Trust Boundary Detection ===
	fmt.Println("[Phase 3/7] Detecting trust boundaries...")
	boundaries := r.graph.DetectTrustBoundaries(ctx)
	fmt.Printf("  → %d trust boundaries detected\n", len(boundaries))

	// === Phase 4: Graph Walking ===
	fmt.Println("[Phase 4/7] Walking graph for attack paths...")
	boundaryPaths := r.graph.WalkTrustBoundaries(ctx)
	parserChains := r.graph.TraceParserChains(ctx)
	identityFlows := r.graph.TraceIdentityFlows(ctx)
	fmt.Printf("  → %d boundary-crossing paths\n", len(boundaryPaths))
	fmt.Printf("  → %d parser transitions\n", len(parserChains))
	fmt.Printf("  → %d identity flows\n", len(identityFlows))

	// === Phase 5: Hypothesis Generation ===
	fmt.Println("[Phase 5/7] Generating attack hypotheses...")
	snapshot := r.graph.GetSnapshot(ctx, cfg.SessionID)
	hypotheses := r.hypothesis.Generate(ctx, snapshot)
	fmt.Printf("  → %d hypotheses generated\n", len(hypotheses))

	// === Phase 6: Filter & Rank ===
	fmt.Println("[Phase 6/7] Filtering and ranking...")
	if cfg.MinConfidence > 0 {
		hypotheses = filterByConfidence(hypotheses, cfg.MinConfidence)
	}

	tier1, tier2, tier3 := countTiers(hypotheses)
	fmt.Printf("  → Tier 1 (High): %d | Tier 2 (Medium): %d | Tier 3 (Low): %d\n", tier1, tier2, tier3)

	// === Phase 7: Export ===
	fmt.Println("[Phase 7/7] Exporting results...")

	nodes, edges := r.graph.GetGraph(ctx)
	report := &models.HypothesisReport{
		SessionID:  cfg.SessionID,
		Timestamp:  time.Now(),
		Graph:      snapshot,
		Hypotheses: hypotheses,
		Summary: models.ReportSummary{
			TotalNodes:      len(nodes),
			TotalEdges:      len(edges),
			TotalBoundaries: len(boundaries),
			TotalHypotheses: len(hypotheses),
			Tier1Count:      tier1,
			Tier2Count:      tier2,
			Tier3Count:      tier3,
		},
	}

	if err := r.exportReport(report, cfg); err != nil {
		return nil, fmt.Errorf("export failed: %w", err)
	}

	duration := time.Since(startTime)
	fmt.Printf("\n✅ Analysis complete in %v\n", duration)

	// Print verbose graph if requested
	if cfg.Verbose {
		r.graph.PrintGraph()
	}

	return report, nil
}

// ExecutionConfig controls the runtime execution.
type ExecutionConfig struct {
	InputFiles    []string
	SessionID     string
	OutputDir     string
	Format        string  // "json", "table", "markdown"
	MinConfidence float64 // Filter hypotheses below this threshold
	Verbose       bool
}

// exportReport writes the results to files.
func (r *Runtime) exportReport(report *models.HypothesisReport, cfg ExecutionConfig) error {
	// Ensure output directory exists
	if err := os.MkdirAll(cfg.OutputDir, 0755); err != nil {
		return fmt.Errorf("failed to create output dir: %w", err)
	}

	// Export DFD
	dfdPath := cfg.OutputDir + "/MachineReadableDFD.json"
	dfdBytes, _ := json.MarshalIndent(report.Graph, "", "  ")
	if err := os.WriteFile(dfdPath, dfdBytes, 0644); err != nil {
		return fmt.Errorf("failed to write DFD: %w", err)
	}
	fmt.Printf("  → DFD: %s\n", dfdPath)

	// Export Hypotheses
	hypoPath := cfg.OutputDir + "/HypothesisReport.json"
	hypoBytes, _ := json.MarshalIndent(report, "", "  ")
	if err := os.WriteFile(hypoPath, hypoBytes, 0644); err != nil {
		return fmt.Errorf("failed to write Hypotheses: %w", err)
	}
	fmt.Printf("  → Hypotheses: %s\n", hypoPath)

	// Export Markdown summary if requested
	if cfg.Format == "markdown" {
		mdPath := cfg.OutputDir + "/AnalysisSummary.md"
		md := generateMarkdownSummary(report)
		if err := os.WriteFile(mdPath, []byte(md), 0644); err != nil {
			return fmt.Errorf("failed to write markdown: %w", err)
		}
		fmt.Printf("  → Summary: %s\n", mdPath)
	}

	return nil
}

// --- Helpers ---

func filterByConfidence(hypotheses []models.AttackHypothesis, minConf float64) []models.AttackHypothesis {
	var filtered []models.AttackHypothesis
	for _, h := range hypotheses {
		if h.ConfidenceScore >= minConf {
			filtered = append(filtered, h)
		}
	}
	return filtered
}

func countTiers(hypotheses []models.AttackHypothesis) (tier1, tier2, tier3 int) {
	for _, h := range hypotheses {
		switch h.ConfidenceTier {
		case 1:
			tier1++
		case 2:
			tier2++
		default:
			tier3++
		}
	}
	return
}

func generateMarkdownSummary(report *models.HypothesisReport) string {
	md := "# Offensive Architectural Analysis Report\n\n"
	md += fmt.Sprintf("**Session:** %s\n", report.SessionID)
	md += fmt.Sprintf("**Timestamp:** %s\n\n", report.Timestamp.Format(time.RFC3339))

	md += "## Summary\n\n"
	md += fmt.Sprintf("| Metric | Count |\n|--------|-------|\n")
	md += fmt.Sprintf("| Nodes | %d |\n", report.Summary.TotalNodes)
	md += fmt.Sprintf("| Edges | %d |\n", report.Summary.TotalEdges)
	md += fmt.Sprintf("| Trust Boundaries | %d |\n", report.Summary.TotalBoundaries)
	md += fmt.Sprintf("| Hypotheses | %d |\n", report.Summary.TotalHypotheses)
	md += fmt.Sprintf("| 🔴 Tier 1 (High) | %d |\n", report.Summary.Tier1Count)
	md += fmt.Sprintf("| 🟡 Tier 2 (Medium) | %d |\n", report.Summary.Tier2Count)
	md += fmt.Sprintf("| ⬜ Tier 3 (Low) | %d |\n\n", report.Summary.Tier3Count)

	md += "## Attack Hypotheses\n\n"
	for i, h := range report.Hypotheses {
		tier := "⬜ Low"
		if h.ConfidenceTier == 1 {
			tier = "🔴 HIGH"
		} else if h.ConfidenceTier == 2 {
			tier = "🟡 Medium"
		}

		md += fmt.Sprintf("### %d. [%s] %s\n\n", i+1, tier, h.MechanismLabel)
		md += fmt.Sprintf("- **Mechanism:** `%s`\n", h.Mechanism)
		md += fmt.Sprintf("- **Risk Score:** %.2f\n", h.RiskScore)
		md += fmt.Sprintf("- **Confidence:** %.2f\n", h.ConfidenceScore)
		md += fmt.Sprintf("- **Skill Reference:** `%s`\n", h.SkillReference)
		md += fmt.Sprintf("- **Rationale:** %s\n", h.Rationale)
		md += fmt.Sprintf("- **Affected Nodes:** %v\n\n", h.PathNodeIDs)
	}

	return md
}
