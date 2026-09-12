package internal_test

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestLinkIntegrity(t *testing.T) {
	rootDir := "../.."
	mdFiles := []string{
		"README.md",
		"claude.md",
		"OPERATIONAL_MAP.md",
		"Methodology/index.md",
		"Methodology/OPERATIONAL_PLAYBOOK.md",
		"skills/_INDEX.md",
		"Workflow/01_target_selection.md",
	}

	linkRegex := regexp.MustCompile(`\[.*?\]\((.*?)\)`)

	for _, relFile := range mdFiles {
		fullPath := filepath.Join(rootDir, relFile)
		content, err := os.ReadFile(fullPath)
		if err != nil {
			t.Errorf("Could not read file %s: %v", relFile, err)
			continue
		}

		dir := filepath.Dir(fullPath)
		matches := linkRegex.FindAllStringSubmatch(string(content), -1)

		for _, m := range matches {
			if len(m) < 2 {
				continue
			}
			link := m[1]

			// Ignore external web links, anchors, and mailto
			if strings.HasPrefix(link, "http://") ||
				strings.HasPrefix(link, "https://") ||
				strings.HasPrefix(link, "#") ||
				strings.HasPrefix(link, "mailto:") {
				continue
			}

			// Clean query or anchor from link path
			cleanLink := strings.Split(link, "#")[0]
			cleanLink = strings.Split(cleanLink, "?")[0]
			if cleanLink == "" {
				continue
			}

			targetPath := filepath.Join(dir, cleanLink)
			if _, err := os.Stat(targetPath); os.IsNotExist(err) {
				t.Errorf("Broken link in %s: %s -> %s does not exist", relFile, link, targetPath)
			}
		}
	}
}
