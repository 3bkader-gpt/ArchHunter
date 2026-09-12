package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/hacker/runtime/internal/graph"
	"github.com/hacker/runtime/internal/inference"
	"github.com/hacker/runtime/internal/ingestion"
	"github.com/hacker/runtime/internal/normalization"
	"github.com/hacker/runtime/internal/orchestration"
)

const banner = `
 ╔═══════════════════════════════════════════════════════════╗
 ║   Offensive Architectural Reasoning Engine                ║
 ║   ─────────────────────────────────────────               ║
 ║   Mechanism over Payload. Architecture over Guessing.     ║
 ╚═══════════════════════════════════════════════════════════╝
`

func main() {
	// CLI flags
	inputFiles := flag.String("input", "", "Comma-separated list of JSONL files (httpx, katana, nmap, etc.)")
	outputDir := flag.String("output", "outputs", "Output directory for results")
	sessionID := flag.String("session", "session_default", "Session identifier")
	format := flag.String("format", "json", "Output format: json, markdown")
	minConf := flag.Float64("min-confidence", 0.0, "Filter hypotheses below this confidence threshold (0.0-1.0)")
	verbose := flag.Bool("verbose", false, "Print detailed graph state to stdout")
	legacy := flag.Bool("legacy", false, "Run legacy MVP pipeline (backward compatible)")

	flag.Parse()

	if *inputFiles == "" {
		fmt.Print(banner)
		fmt.Println("Usage: runtime -input <file1.jsonl,file2.jsonl> [options]")
		fmt.Println()
		fmt.Println("Options:")
		flag.PrintDefaults()
		fmt.Println()
		fmt.Println("Examples:")
		fmt.Println("  runtime -input recon/httpx_output.jsonl")
		fmt.Println("  runtime -input httpx.jsonl,katana.jsonl -format markdown -verbose")
		fmt.Println("  runtime -input recon/*.jsonl -min-confidence 0.5 -output results/")
		os.Exit(1)
	}

	files := strings.Split(*inputFiles, ",")
	for i := range files {
		files[i] = strings.TrimSpace(files[i])
	}

	// Initialize Components
	norm := normalization.NewNormalizer()
	engine := graph.NewEngine()
	pipe := ingestion.NewPipeline(norm, engine)
	mockClient := inference.NewMockClient()
	hypoEngine := inference.NewHypothesisEngine()

	runtime := orchestration.NewRuntime(pipe, engine, mockClient, hypoEngine)

	ctx := context.Background()
	fmt.Print(banner)

	if *legacy {
		// Legacy MVP execution
		fmt.Println("Running in legacy MVP mode...")
		dfdPath := *outputDir + "/MachineReadableDFD.json"
		hypoPath := *outputDir + "/HypothesisReport.json"

		os.MkdirAll(*outputDir, 0755)
		if err := runtime.ExecuteMVP(ctx, files, dfdPath, hypoPath); err != nil {
			log.Fatalf("Execution failed: %v", err)
		}
		fmt.Printf("MVP Complete.\nDFD: %s\nHypotheses: %s\n", dfdPath, hypoPath)
		return
	}

	// Full pipeline execution
	cfg := orchestration.ExecutionConfig{
		InputFiles:    files,
		SessionID:     *sessionID,
		OutputDir:     *outputDir,
		Format:        *format,
		MinConfidence: *minConf,
		Verbose:       *verbose,
	}

	report, err := runtime.ExecuteFull(ctx, cfg)
	if err != nil {
		log.Fatalf("Execution failed: %v", err)
	}

	// Print summary
	fmt.Printf("\n📊 Final Summary:\n")
	fmt.Printf("   Nodes: %d | Edges: %d | Boundaries: %d\n",
		report.Summary.TotalNodes, report.Summary.TotalEdges, report.Summary.TotalBoundaries)
	fmt.Printf("   Hypotheses: %d (🔴 %d High | 🟡 %d Med | ⬜ %d Low)\n",
		report.Summary.TotalHypotheses,
		report.Summary.Tier1Count, report.Summary.Tier2Count, report.Summary.Tier3Count)
}
