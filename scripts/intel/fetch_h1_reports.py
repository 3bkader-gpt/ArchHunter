#!/usr/bin/env python3
"""Fetch disclosed HackerOne reports as full Markdown intel for ArchHunter.

Generalized port of the auth_bypass_vault scraper. Queries the HackerOne
hacktivity GraphQL index for high-signal disclosed reports matching the
supplied search terms, downloads each report's JSON, and writes an
unabridged Markdown copy plus an INDEX.md into the output directory.

Usage:
  python scripts/intel/fetch_h1_reports.py --query "SSRF" --limit 10
  python scripts/intel/fetch_h1_reports.py --preset auth --out research/case_studies/_fresh
  python scripts/intel/fetch_h1_reports.py --preset ai --limit 20

Only disclosed reports are fetched; use for building your own reference
library from public disclosures. Respect HackerOne ToS / rate limits.
"""
import argparse
import re
import sys
import time
from pathlib import Path

import requests

HEADERS = {
    "Accept": "application/json, text/html, */*",
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    ),
}

GRAPHQL_ENDPOINT = "https://hackerone.com/graphql"

GRAPHQL_QUERY = """
query HacktivitySearchQuery($queryString: String!, $from: Int, $size: Int, $sort: SortInput!) {
  search(index: CompleteHacktivityReportIndex, query_string: $queryString, from: $from, size: $size, sort: $sort) {
    total_count
    nodes {
      ... on HacktivityDocument {
        _id
        votes
        severity_rating
        report {
          databaseId: _id
          title
        }
      }
    }
  }
}
"""

# Preset searches per mechanism family. Extend as needed.
PRESETS = {
    "auth": [
        'title:"Authentication Bypass" AND disclosed:true',
        'title:"Account Takeover" AND disclosed:true',
        'title:"OAuth" AND (bypass OR takeover) AND disclosed:true',
        'title:"2FA Bypass" AND disclosed:true',
        'title:"IDOR" AND severity_rating:(High OR Critical) AND disclosed:true',
        'title:"Broken Access Control" AND disclosed:true',
        'title:"JWT" AND bypass AND disclosed:true',
    ],
    "ai": [
        'title:"Prompt Injection" AND disclosed:true',
        'title:"LLM" AND disclosed:true',
        'title:"MCP" AND disclosed:true',
        'title:"AI" AND (injection OR exfiltration OR guardrails) AND disclosed:true',
        'title:"Copilot" AND disclosed:true',
    ],
    "state": [
        'title:"Race Condition" AND disclosed:true',
        'title:"Rate Limit" AND disclosed:true',
        'title:"Webhook" AND disclosed:true',
        'title:"GraphQL" AND disclosed:true',
    ],
}


def sanitize_filename(name: str) -> str:
    name = name or "report"
    name = re.sub(r'[\\/:*?"<>|]', "_", name)
    name = re.sub(r"\s+", "_", name)
    clean = name.strip("._")[:90]
    return clean or "report"


def search_report_ids(queries, per_query=15, target_count=30):
    candidates = {}
    for q in queries:
        payload = {
            "operationName": "HacktivitySearchQuery",
            "variables": {
                "queryString": q,
                "from": 0,
                "size": per_query,
                "sort": {"field": "votes", "direction": "DESC"},
            },
            "query": GRAPHQL_QUERY,
        }
        try:
            resp = requests.post(
                GRAPHQL_ENDPOINT,
                headers={"Content-Type": "application/json", "Accept": "application/json"},
                json=payload,
                timeout=20,
            )
            data = resp.json()
            nodes = data.get("data", {}).get("search", {}).get("nodes", [])
            for n in nodes:
                rid = str(n.get("report", {}).get("databaseId") or n.get("_id") or "")
                votes = n.get("votes") or 0
                title = (n.get("report") or {}).get("title") or ""
                if rid and rid not in candidates:
                    candidates[rid] = {"votes": votes, "title": title}
        except Exception as e:
            print(f"[-] Error querying '{q}': {e}")
    sorted_ids = sorted(candidates, key=lambda x: candidates[x]["votes"], reverse=True)
    return sorted_ids[:target_count]


def fetch_full_report(report_id: str):
    try:
        resp = requests.get(
            f"https://hackerone.com/reports/{report_id}.json", headers=HEADERS, timeout=25
        )
        if resp.status_code == 200:
            return resp.json()
    except Exception as e:
        print(f"[-] Failed report {report_id}: {e}")
    return None


def build_full_markdown(data: dict) -> str:
    rep_id = data.get("id")
    title = data.get("title", "Untitled Report")
    url = data.get("url") or f"https://hackerone.com/reports/{rep_id}"
    state = data.get("substate") or data.get("state") or "disclosed"
    sev_rating = data.get("severity_rating") or "None"
    sev_obj = data.get("severity") or {}
    cvss_score = sev_obj.get("rating") or sev_obj.get("score") or sev_rating
    weakness_name = (data.get("weakness") or {}).get("name") or "Unspecified"
    reporter_user = (data.get("reporter") or {}).get("username") or "anonymous"
    team = data.get("team") or {}
    team_name = team.get("profile", {}).get("name") or team.get("handle") or "Unknown Team"

    bounty_amount = data.get("formatted_bounty") or data.get("bounty_amount")
    bounty_str = (
        f"${bounty_amount}"
        if bounty_amount
        else ("Yes (Undisclosed Amount)" if data.get("has_bounty?") else "No Bounty / Swag")
    )

    summary_blocks = []
    for s in data.get("summaries") or []:
        content = (s.get("content") or "").strip()
        if content:
            cat = s.get("category", "Summary").title()
            user = s.get("user", {}).get("username", "Team")
            summary_blocks.append(f"### {cat} by @{user}\n\n{content}")
    summaries_text = "\n\n".join(summary_blocks) or "No formal disclosure summary provided."

    vuln_info = data.get("vulnerability_information") or "No detailed description provided."

    return f"""# Report #{rep_id}: {title}

- **Platform:** HackerOne
- **Report URL:** [{url}]({url})
- **Program:** {team_name}
- **Reporter:** @{reporter_user}
- **Status:** {state.upper()}
- **Severity:** {cvss_score}
- **Weakness:** {weakness_name}
- **Bounty:** {bounty_str}
- **Submitted:** {data.get("submitted_at") or data.get("created_at") or "Unknown"}
- **Disclosed:** {data.get("disclosed_at") or "Unknown"}
- **Community Upvotes:** {data.get("vote_count") or 0}

---

## Executive Summaries

{summaries_text}

---

## Full Vulnerability Description & Technical Reproduction Steps

{vuln_info}
"""


def main():
    ap = argparse.ArgumentParser(description="Fetch disclosed HackerOne reports as Markdown intel.")
    ap.add_argument("--preset", choices=sorted(PRESETS), help="mechanism preset (auth/ai/state)")
    ap.add_argument("--query", action="append", default=[],
                    help="custom H1 hacktivity search string (repeatable); appends to preset")
    ap.add_argument("--limit", type=int, default=30, help="max reports to download")
    ap.add_argument("--out", default="research/case_studies/_fresh",
                    help="output directory (default: research/case_studies/_fresh)")
    args = ap.parse_args()

    queries = list(PRESETS.get(args.preset, [])) + list(args.query)
    if not queries:
        ap.error("provide --preset and/or at least one --query")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"[+] Searching HackerOne hacktivity ({len(queries)} queries, limit {args.limit})...")
    top_ids = search_report_ids(queries, target_count=args.limit)
    print(f"[+] {len(top_ids)} high-signal candidates. Downloading unabridged reports...")

    saved = []
    for idx, rid in enumerate(top_ids, 1):
        print(f"[{idx}/{len(top_ids)}] Downloading full report #{rid}...")
        data = fetch_full_report(rid)
        if not data:
            continue
        title = data.get("title", "")
        if len(data.get("vulnerability_information") or "") < 200:
            print(f"    [-] Skipping report #{rid} (empty or restricted description)")
            continue

        filename = f"{rid}_{sanitize_filename(title)}.md"
        md_doc = build_full_markdown(data)
        (out_dir / filename).write_text(md_doc, encoding="utf-8")
        print(f"    [+] Saved ({len(md_doc)} bytes): {filename}")

        saved.append({
            "id": rid,
            "title": title,
            "program": (data.get("team") or {}).get("handle", "Unknown"),
            "severity": data.get("severity_rating") or "None",
            "bounty": data.get("formatted_bounty")
                      or (f"${data.get('bounty_amount')}" if data.get("bounty_amount") else "N/A"),
            "votes": data.get("vote_count") or 0,
            "filename": filename,
            "url": data.get("url") or f"https://hackerone.com/reports/{rid}",
        })
        time.sleep(0.3)

    saved.sort(key=lambda x: x["votes"], reverse=True)
    index = (
        f"# Fresh HackerOne Intel — {time.strftime('%Y-%m-%d %H:%M')}\n\n"
        f"Preset: `{args.preset or 'custom'}` · Queries: {len(queries)} · Saved: **{len(saved)}**\n\n"
        "| Report ID | Title | Program | Severity | Bounty | Upvotes | Source |\n"
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n"
    )
    for r in saved:
        index += (f"| [#{r['id']}](./{r['filename']}) | [{r['title'][:65]}](./{r['filename']}) "
                  f"| `{r['program']}` | {r['severity']} | {r['bounty']} | {r['votes']} "
                  f"| [H1]({r['url']}) |\n")
    (out_dir / "INDEX.md").write_text(index, encoding="utf-8")
    print(f"\n[+] Saved {len(saved)} reports to {out_dir}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
