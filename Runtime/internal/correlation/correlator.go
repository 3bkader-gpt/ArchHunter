package correlation

import (
	"fmt"
	"strings"
	"time"

	"github.com/hacker/runtime/internal/models"
)

// Correlator fuses unstructured signals across multiple tools and layers.
// Implements concepts from 04_evidence_correlation_engine.md
type Correlator struct {
	weights map[string]float64
}

// NewCorrelator creates an evidence correlation engine with default weights.
func NewCorrelator() *Correlator {
	return &Correlator{
		weights: map[string]float64{
			"explicit_header":   0.9,
			"error_fingerprint": 0.8,
			"timing_delta":      0.6,
			"url_path_pattern":  0.5,
			"generic_server":    0.3,
		},
	}
}

// FuseSignals groups signals that relate to the same host/asset and produces FusedEvidence.
func (c *Correlator) FuseSignals(signals []*models.ArchitecturalSignal) []models.FusedEvidence {
	// Group signals by asset identifier (or host)
	grouped := make(map[string][]*models.ArchitecturalSignal)
	for _, sig := range signals {
		asset := sig.AssetIdentifier
		grouped[asset] = append(grouped[asset], sig)
	}

	var fusedList []models.FusedEvidence
	for asset, sigs := range grouped {
		if len(sigs) == 0 {
			continue
		}

		fused := models.FusedEvidence{
			ID:              fmt.Sprintf("fused_%d", time.Now().UnixNano()),
			CorrelationType: "host_service",
			FusedProperties: make(map[string]string),
			SourceSignalIDs: make([]string, 0, len(sigs)),
		}

		totalConfidence := 0.0
		sources := make(map[string]bool)

		for _, sig := range sigs {
			fused.SourceSignalIDs = append(fused.SourceSignalIDs, sig.ID)
			sources[sig.Source] = true
			totalConfidence += sig.Confidence

			for k, v := range sig.Attributes {
				fused.FusedProperties[k] = v
			}
		}

		// Multi-source bonus: if multiple tools (e.g. httpx + katana + nmap) corroborate
		sourceCount := len(sources)
		avgConfidence := totalConfidence / float64(len(sigs))
		if sourceCount > 1 {
			avgConfidence = minFloat(1.0, avgConfidence+(0.1*float64(sourceCount-1)))
		}
		fused.Confidence = avgConfidence

		var srcList []string
		for s := range sources {
			srcList = append(srcList, s)
		}
		fused.Rationale = fmt.Sprintf("Fused %d signals across [%s] for asset %s", len(sigs), strings.Join(srcList, ", "), asset)

		fusedList = append(fusedList, fused)
	}

	return fusedList
}

// CorrelateCloudProvider detects correlations between web assets and cloud provider resources.
// e.g. S3 buckets in JS files linked to AWS request IDs in headers.
func (c *Correlator) CorrelateCloudProvider(signals []*models.ArchitecturalSignal) []models.FusedEvidence {
	var cloudEvidence []models.FusedEvidence

	var awsSignals []*models.ArchitecturalSignal
	for _, sig := range signals {
		isAWS := false
		if strings.Contains(sig.AssetIdentifier, "s3.amazonaws.com") ||
			strings.Contains(sig.AssetIdentifier, ".amazonaws.com") ||
			sig.Attributes["x-amz-request-id"] != "" ||
			sig.Attributes["x-amz-cf-id"] != "" ||
			sig.Attributes["x-amzn-requestid"] != "" {
			isAWS = true
		}

		if isAWS {
			awsSignals = append(awsSignals, sig)
		}
	}

	if len(awsSignals) > 1 {
		var signalIDs []string
		for _, s := range awsSignals {
			signalIDs = append(signalIDs, s.ID)
		}

		cloudEvidence = append(cloudEvidence, models.FusedEvidence{
			ID:              fmt.Sprintf("fused_cloud_aws_%d", time.Now().UnixNano()),
			SourceSignalIDs: signalIDs,
			CorrelationType: "cloud_provider",
			Confidence:      0.85,
			FusedProperties: map[string]string{
				"cloud_provider": "AWS",
				"correlated_assets_count": fmt.Sprintf("%d", len(awsSignals)),
			},
			Rationale: fmt.Sprintf("Correlated %d AWS infrastructure indicators across target domain", len(awsSignals)),
		})
	}

	return cloudEvidence
}

func minFloat(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}
