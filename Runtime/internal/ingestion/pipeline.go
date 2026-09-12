package ingestion

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"

	"github.com/hacker/runtime/internal/models"
)

// Pipeline reads JSONL files and feeds normalized signals into the graph engine.
type Pipeline struct {
	normalizer Normalizer
	graph      GraphStore
}

// Normalizer transforms raw JSON bytes into architectural signals.
type Normalizer interface {
	Normalize(ctx context.Context, raw []byte) (*models.ArchitecturalSignal, error)
}

// GraphStore accepts normalized signals into the graph.
type GraphStore interface {
	AddSignal(ctx context.Context, signal *models.ArchitecturalSignal) error
}

// NewPipeline creates a new ingestion pipeline.
func NewPipeline(n Normalizer, g GraphStore) *Pipeline {
	return &Pipeline{normalizer: n, graph: g}
}

// ProcessFile reads a JSONL file and processes each line through the pipeline.
func (p *Pipeline) ProcessFile(ctx context.Context, filePath string) error {
	file, err := os.Open(filePath)
	if err != nil {
		return fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	lineNum := 0
	successCount := 0
	errorCount := 0

	for {
		var raw map[string]interface{}
		if err := decoder.Decode(&raw); err != nil {
			if err == io.EOF {
				break
			}
			lineNum++
			errorCount++
			fmt.Printf("  Warning: line %d decode error: %v\n", lineNum, err)
			continue
		}
		lineNum++

		rawBytes, _ := json.Marshal(raw)
		signal, err := p.normalizer.Normalize(ctx, rawBytes)
		if err != nil {
			errorCount++
			continue
		}

		if err := p.graph.AddSignal(ctx, signal); err != nil {
			return fmt.Errorf("failed to add signal to graph at line %d: %w", lineNum, err)
		}
		successCount++
	}

	fmt.Printf("  Processed %s: %d signals OK, %d errors (from %d lines)\n",
		filePath, successCount, errorCount, lineNum)

	return nil
}
