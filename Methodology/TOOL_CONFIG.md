# Tool Configuration & API Keys

## 1. Active Services & Limits

*   **VirusTotal** (Key: `051...d`) - 4/min, 500/day.
*   **Shodan** (Key: `Ugq...y5`) - 100 query, 100 scan.
*   **Censys** (Key: `cen...n1`) - 100/100 (basic).
*   **Chaos** (Key: `dca...f0`) - 100 URL/day, 10 AI/day.
*   **GitHub** (Token: `ghp...PG`) - For repo scraping.

## 2. Configuration Files

### subfinder (`~/.config/subfinder/provider-config.yaml`)
```yaml
virustotal: [KEY]
shodan: [KEY]
censys: [KEY]
chaos: [KEY]
github: [TOKEN]
```

## 3. Shell Environment Variables
```bash
export VT_API_KEY=...
export SHODAN_API_KEY=...
export CENSYS_API_ID=...
export PDCP_API_KEY=...
export GITHUB_TOKEN=...
```
