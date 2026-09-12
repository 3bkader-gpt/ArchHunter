package normalization

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/hacker/runtime/internal/models"
)

// Normalizer transforms raw JSON from various recon tools into ArchitecturalSignals.
type Normalizer struct {
	adapters map[string]ToolAdapter
}

// ToolAdapter normalizes output from a specific recon tool.
type ToolAdapter interface {
	Normalize(raw map[string]interface{}) (*models.ArchitecturalSignal, error)
	ToolName() string
}

// NewNormalizer creates a normalizer with all built-in tool adapters.
func NewNormalizer() *Normalizer {
	n := &Normalizer{
		adapters: make(map[string]ToolAdapter),
	}
	// Register all adapters
	n.adapters["httpx"] = &HttpxAdapter{}
	n.adapters["katana"] = &KatanaAdapter{}
	n.adapters["nmap"] = &NmapAdapter{}
	n.adapters["subfinder"] = &SubfinderAdapter{}
	n.adapters["ffuf"] = &FfufAdapter{}
	return n
}

// Normalize takes raw JSON bytes and auto-detects the tool format.
func (n *Normalizer) Normalize(ctx context.Context, raw []byte) (*models.ArchitecturalSignal, error) {
	var data map[string]interface{}
	if err := json.Unmarshal(raw, &data); err != nil {
		return nil, fmt.Errorf("invalid json: %w", err)
	}

	// Auto-detect tool format based on field signatures
	toolName := detectTool(data)
	adapter, ok := n.adapters[toolName]
	if !ok {
		// Fallback: generic normalization
		return genericNormalize(data)
	}

	signal, err := adapter.Normalize(data)
	if err != nil {
		return nil, err
	}

	// Ensure required fields
	if signal.ID == "" {
		signal.ID = fmt.Sprintf("sig_%d", time.Now().UnixNano())
	}
	if signal.Timestamp.IsZero() {
		signal.Timestamp = time.Now()
	}

	return signal, nil
}

// detectTool identifies which recon tool produced the JSON output.
func detectTool(data map[string]interface{}) string {
	// httpx outputs: url, status_code, content_type, tech, etc.
	if _, hasURL := data["url"]; hasURL {
		if _, hasSC := data["status_code"]; hasSC {
			return "httpx"
		}
		if _, hasTech := data["tech"]; hasTech {
			return "httpx"
		}
	}

	// katana outputs: input, endpoint, method, source, etc.
	if _, hasInput := data["input"]; hasInput {
		if _, hasEndpoint := data["endpoint"]; hasEndpoint {
			return "katana"
		}
		// Fallback: if it has "input" but not httpx fields
		if _, hasURL := data["url"]; !hasURL {
			return "katana"
		}
	}

	// nmap outputs: host, port, protocol, service, etc.
	if _, hasPort := data["port"]; hasPort {
		if _, hasHost := data["host"]; hasHost {
			return "nmap"
		}
	}

	// subfinder outputs: host (just domain names)
	if _, hasHost := data["host"]; hasHost {
		if _, hasPort := data["port"]; !hasPort {
			return "subfinder"
		}
	}

	// ffuf outputs: input, FUZZ, url, status, length
	if _, hasFUZZ := data["FUZZ"]; hasFUZZ {
		return "ffuf"
	}
	if _, hasInput := data["input"]; hasInput {
		if _, hasLen := data["length"]; hasLen {
			return "ffuf"
		}
	}

	return "generic"
}

// genericNormalize handles unknown tool formats.
func genericNormalize(data map[string]interface{}) (*models.ArchitecturalSignal, error) {
	signal := &models.ArchitecturalSignal{
		ID:         fmt.Sprintf("sig_%d", time.Now().UnixNano()),
		Source:     "unknown",
		Timestamp:  time.Now(),
		Attributes: make(map[string]string),
		Confidence: 0.3,
	}

	// Try common fields
	if url, ok := data["url"].(string); ok {
		signal.AssetIdentifier = url
	} else if host, ok := data["host"].(string); ok {
		signal.AssetIdentifier = host
	} else if input, ok := data["input"].(string); ok {
		signal.AssetIdentifier = input
	} else {
		return nil, fmt.Errorf("could not identify asset in signal")
	}

	for k, v := range data {
		signal.Attributes[k] = fmt.Sprintf("%v", v)
	}

	return signal, nil
}

// --- Tool Adapters ---

// HttpxAdapter normalizes httpx JSON output.
type HttpxAdapter struct{}

func (a *HttpxAdapter) ToolName() string { return "httpx" }

func (a *HttpxAdapter) Normalize(data map[string]interface{}) (*models.ArchitecturalSignal, error) {
	signal := &models.ArchitecturalSignal{
		ID:         fmt.Sprintf("sig_httpx_%d", time.Now().UnixNano()),
		Source:     "httpx",
		Timestamp:  time.Now(),
		Attributes: make(map[string]string),
		Confidence: 0.7,
	}

	if url, ok := data["url"].(string); ok {
		signal.AssetIdentifier = url
	} else {
		return nil, fmt.Errorf("httpx signal missing 'url' field")
	}

	// Map well-known httpx fields
	fieldMap := map[string]string{
		"status_code":  "status_code",
		"content_type": "content_type",
		"server":       "server",
		"title":        "title",
		"method":       "method",
		"host":         "host",
		"port":         "port",
		"scheme":       "scheme",
		"jarm":         "jarm",
		"cname":        "cname",
		"cdn_name":     "cdn_name",
		"cdn_type":     "cdn_type",
	}

	for jsonKey, attrKey := range fieldMap {
		if v, ok := data[jsonKey]; ok {
			signal.Attributes[attrKey] = fmt.Sprintf("%v", v)
		}
	}

	// Extract tech stack
	if tech, ok := data["tech"].([]interface{}); ok {
		var techs []string
		for _, t := range tech {
			techs = append(techs, fmt.Sprintf("%v", t))
		}
		signal.Attributes["tech"] = strings.Join(techs, ",")
	}

	// Extract response headers if present
	if headers, ok := data["header"].(map[string]interface{}); ok {
		for k, v := range headers {
			signal.Attributes[strings.ToLower(k)] = fmt.Sprintf("%v", v)
		}
	}

	// Flatten remaining attributes
	for k, v := range data {
		if _, exists := signal.Attributes[k]; !exists {
			signal.Attributes[k] = fmt.Sprintf("%v", v)
		}
	}

	return signal, nil
}

// KatanaAdapter normalizes katana JSON output.
type KatanaAdapter struct{}

func (a *KatanaAdapter) ToolName() string { return "katana" }

func (a *KatanaAdapter) Normalize(data map[string]interface{}) (*models.ArchitecturalSignal, error) {
	signal := &models.ArchitecturalSignal{
		ID:         fmt.Sprintf("sig_katana_%d", time.Now().UnixNano()),
		Source:     "katana",
		Timestamp:  time.Now(),
		Attributes: make(map[string]string),
		Confidence: 0.5,
	}

	if input, ok := data["input"].(string); ok {
		signal.AssetIdentifier = input
	} else if endpoint, ok := data["endpoint"].(string); ok {
		signal.AssetIdentifier = endpoint
	} else {
		return nil, fmt.Errorf("katana signal missing 'input' or 'endpoint' field")
	}

	for k, v := range data {
		signal.Attributes[k] = fmt.Sprintf("%v", v)
	}

	return signal, nil
}

// NmapAdapter normalizes nmap JSON output.
type NmapAdapter struct{}

func (a *NmapAdapter) ToolName() string { return "nmap" }

func (a *NmapAdapter) Normalize(data map[string]interface{}) (*models.ArchitecturalSignal, error) {
	signal := &models.ArchitecturalSignal{
		ID:         fmt.Sprintf("sig_nmap_%d", time.Now().UnixNano()),
		Source:     "nmap",
		Timestamp:  time.Now(),
		Attributes: make(map[string]string),
		Confidence: 0.8,
	}

	host, _ := data["host"].(string)
	port, _ := data["port"].(string)
	if port == "" {
		if portF, ok := data["port"].(float64); ok {
			port = fmt.Sprintf("%d", int(portF))
		}
	}

	if host == "" {
		return nil, fmt.Errorf("nmap signal missing 'host' field")
	}

	signal.AssetIdentifier = fmt.Sprintf("%s:%s", host, port)

	for k, v := range data {
		signal.Attributes[k] = fmt.Sprintf("%v", v)
	}

	return signal, nil
}

// SubfinderAdapter normalizes subfinder JSON output.
type SubfinderAdapter struct{}

func (a *SubfinderAdapter) ToolName() string { return "subfinder" }

func (a *SubfinderAdapter) Normalize(data map[string]interface{}) (*models.ArchitecturalSignal, error) {
	signal := &models.ArchitecturalSignal{
		ID:         fmt.Sprintf("sig_subfinder_%d", time.Now().UnixNano()),
		Source:     "subfinder",
		Timestamp:  time.Now(),
		Attributes: make(map[string]string),
		Confidence: 0.4,
	}

	if host, ok := data["host"].(string); ok {
		signal.AssetIdentifier = host
	} else {
		return nil, fmt.Errorf("subfinder signal missing 'host' field")
	}

	for k, v := range data {
		signal.Attributes[k] = fmt.Sprintf("%v", v)
	}

	return signal, nil
}

// FfufAdapter normalizes ffuf JSON output.
type FfufAdapter struct{}

func (a *FfufAdapter) ToolName() string { return "ffuf" }

func (a *FfufAdapter) Normalize(data map[string]interface{}) (*models.ArchitecturalSignal, error) {
	signal := &models.ArchitecturalSignal{
		ID:         fmt.Sprintf("sig_ffuf_%d", time.Now().UnixNano()),
		Source:     "ffuf",
		Timestamp:  time.Now(),
		Attributes: make(map[string]string),
		Confidence: 0.5,
	}

	if url, ok := data["url"].(string); ok {
		signal.AssetIdentifier = url
	} else if input, ok := data["input"].(map[string]interface{}); ok {
		if fuzz, ok := input["FUZZ"].(string); ok {
			signal.AssetIdentifier = fuzz
		}
	}

	if signal.AssetIdentifier == "" {
		return nil, fmt.Errorf("ffuf signal missing identifiable URL")
	}

	for k, v := range data {
		signal.Attributes[k] = fmt.Sprintf("%v", v)
	}

	return signal, nil
}
