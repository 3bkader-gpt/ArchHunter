#!/usr/bin/env python3
"""Crawl Telegram bug-bounty channels for technical writeups (ArchHunter intel).

Generalized port of the auth_bypass_vault Telethon crawler. Scans the channels
in a Telegram dialog filter (folder), filters messages by keyword regex, fetches
the linked full articles, converts them to Markdown, and files them into
category subfolders with an INDEX.md.

Credentials are NOT embedded in this repo. Configure via environment:

  TELEGRAM_API_ID / TELEGRAM_API_HASH   from my.telegram.org
  TELEGRAM_SESSION                       path to your *.session file
                                         (created once via tg_login.py)

Usage:
  python scripts/intel/tg_login.py                      # one-time session login
  python scripts/intel/fetch_telegram_intel.py           # default auth keywords
  python scripts/intel/fetch_telegram_intel.py --keywords "ssrf,mcp,llm" \\
      --folder-filter ai_bounty --out research/case_studies/_fresh_tg

Only reads content you already have access to on Telegram plus the public
articles it links; keep crawling volume polite.
"""
import argparse
import asyncio
import json
import os
import re
import sys
from pathlib import Path

import requests
from bs4 import BeautifulSoup

sys.stdout.reconfigure(encoding="utf-8")

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}

DEFAULT_KEYWORDS = [
    r"\boauth\b", r"\bidor\b", r"\bbac\b", r"\bbroken access control\b",
    r"\baccount takeover\b", r"\bato\b", r"\b2fa\b", r"\bmfa\b", r"\bjwt\b",
    r"\bsession fixation\b", r"\bprivilege escalation\b",
    r"\bauthentication bypass\b", r"\bauthorization bypass\b",
]

# Subfolder routing rules: (match terms, folder name, display category)
CATEGORY_RULES = [
    (("oauth", "sso", "openid"), "oauth_and_sso", "OAuth & SSO Vulnerabilities"),
    (("2fa", "mfa", "otp"), "2fa_and_mfa_bypass", "2FA & MFA Bypass"),
    (("jwt", "session", "cookie"), "jwt_and_session_attacks", "JWT & Session Flaws"),
    (("prompt injection", "mcp", "llm", "agent"), "llm_and_agents", "LLM & Agent Abuse"),
    (("ssrf", "smuggling", "403"), "infra_bypass", "Infrastructure Bypass"),
]
DEFAULT_CATEGORY = ("idor_and_bac", "IDOR & Broken Access Control")

SPAM_MARKERS = ("try it:", "available now on all paid", "obsidian")


def load_credentials():
    api_id = os.environ.get("TELEGRAM_API_ID")
    api_hash = os.environ.get("TELEGRAM_API_HASH")
    session = os.environ.get("TELEGRAM_SESSION", "my_telegram_session")
    if not (api_id and api_hash):
        cred_file = Path(__file__).parent / ".tg_credentials.json"
        if cred_file.exists():
            creds = json.loads(cred_file.read_text(encoding="utf-8"))
            api_id = api_id or creds.get("api_id")
            api_hash = api_hash or creds.get("api_hash")
            session = os.environ.get("TELEGRAM_SESSION") or creds.get("session", session)
    if not (api_id and api_hash):
        sys.exit(
            "[!] Missing Telegram credentials. Set TELEGRAM_API_ID / TELEGRAM_API_HASH "
            "env vars, or create scripts/intel/.tg_credentials.json "
            '{"api_id": ..., "api_hash": "...", "session": "path"} '
            "(add that file to .gitignore)."
        )
    return int(api_id), api_hash, session


def sanitize(name: str) -> str:
    name = name or "article"
    name = re.sub(r'[\\/:*?"<>|]', "_", name)
    name = re.sub(r"\s+", "_", name)
    clean = name.strip("._")[:80]
    return clean or "item"


def fetch_full_article(url: str):
    if not url or any(dom in url for dom in ("t.me", "youtube.com", "youtu.be")):
        return "", ""
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        if resp.status_code != 200:
            return "", ""
        soup = BeautifulSoup(resp.text, "html.parser")
        h1 = soup.find("h1")
        title = h1.get_text().strip() if h1 else ""
        article_tag = (
            soup.find("article")
            or soup.find("main")
            or soup.find("div", class_=re.compile("post-content|article-content|entry-content", re.I))
            or soup.body
        )
        elements = article_tag.find_all(["h1", "h2", "h3", "h4", "p", "pre", "blockquote", "li"])
        md_lines = []
        for elem in elements:
            tag = elem.name.lower()
            text = elem.get_text().strip()
            if not text:
                continue
            if tag in ("h1", "h2"):
                md_lines.append(f"\n## {text}\n")
            elif tag in ("h3", "h4"):
                md_lines.append(f"\n### {text}\n")
            elif tag == "pre":
                md_lines.append(f"\n```\n{text}\n```\n")
            elif tag == "blockquote":
                md_lines.append(f"\n> {text}\n")
            elif tag == "li":
                md_lines.append(f"- {text}")
            else:
                md_lines.append(f"\n{text}\n")
        return title, "\n".join(md_lines).strip()
    except Exception:
        return "", ""


def categorize(combined_lower: str):
    for terms, folder, label in CATEGORY_RULES:
        if any(t in combined_lower for t in terms):
            return folder, label
    return DEFAULT_CATEGORY


async def crawl(args, api_id, api_hash, session_name):
    from telethon import TelegramClient
    from telethon.tl.functions.messages import GetDialogFiltersRequest
    from telethon.tl.types import DialogFilter, DialogFilterChatlist

    regex = re.compile("|".join(args.keywords), re.IGNORECASE)
    out_root = Path(args.out)
    out_root.mkdir(parents=True, exist_ok=True)
    for _, folder, _ in CATEGORY_RULES + [DEFAULT_CATEGORY]:
        (out_root / folder).mkdir(parents=True, exist_ok=True)

    async with TelegramClient(session_name, api_id, api_hash) as client:
        filters = await client(GetDialogFiltersRequest())
        target_peers = []
        for f in filters.filters:
            if isinstance(f, (DialogFilter, DialogFilterChatlist)):
                title = getattr(f, "title", None)
                if hasattr(title, "text"):
                    title = title.text
                if title and args.folder_filter.lower() in title.lower():
                    target_peers = list(f.pinned_peers) + list(f.include_peers)
                    break
        if not target_peers:
            sys.exit(f"[!] No Telegram dialog filter matching '{args.folder_filter}' was found.")

        print(f"[*] Scanning {len(target_peers)} channels (filter ~ '{args.folder_filter}')...")
        seen_urls, saved_articles = set(), []

        for p in target_peers:
            entity = await client.get_entity(p)
            ch_name = getattr(entity, "title", getattr(entity, "first_name", "Unknown"))
            print(f"[*] Scanning channel: {ch_name}")

            async for msg in client.iter_messages(entity, limit=args.msg_limit):
                if not msg.text or not regex.search(msg.text):
                    continue
                text = msg.text
                if any(m in text.lower() for m in SPAM_MARKERS):
                    continue

                url_match = re.search(r'https?://[^\s<>"\')]+', text)
                url = url_match.group(0).rstrip(".)]") if url_match else ""
                if not url or url in seen_urls:
                    continue
                seen_urls.add(url)

                date_str = msg.date.strftime("%Y-%m-%d")
                scraped_title, scraped_body = fetch_full_article(url)

                title = scraped_title
                if not title:
                    m = re.search(r"\*\*(?:Title)?[:\s]*(.*?)\*\*", text, re.IGNORECASE)
                    title = m.group(1).strip() if m else ""
                if not title:
                    lines = [l.strip() for l in text.split("\n") if l.strip()]
                    title = lines[0][:75] if lines else "Writeup"
                title = re.sub(r"[*_`#▎]", "", title).strip()

                body_content = scraped_body if len(scraped_body) > 400 else text
                if len(body_content) < 300:
                    continue

                folder, category = categorize(f"{title.lower()} {body_content.lower()}")
                filename = f"{date_str}_{sanitize(title)}.md"
                md_doc = f"""# {title}

- **Category:** {category}
- **Publication Date:** {date_str}
- **Source Channel:** {ch_name}
- **Original Source URL:** [{url}]({url})

---

## Detailed Writeup & Technical Breakdown

{body_content}

---
*Archived by ArchHunter intel crawler from public bug bounty community sources.*
"""
                (out_root / folder / filename).write_text(md_doc, encoding="utf-8")
                print(f"[+] Saved writeup: {folder}/{filename} ({len(md_doc)} bytes)")
                saved_articles.append({
                    "title": title, "date": date_str, "category": category,
                    "sub_folder": folder, "filename": filename, "url": url, "channel": ch_name,
                })

        saved_articles.sort(key=lambda x: x["date"], reverse=True)
        index = (
            f"# Telegram Intel Crawl — {asyncio.get_event_loop().time() and __import__('time').strftime('%Y-%m-%d %H:%M')}\n\n"
            f"Keywords: `{', '.join(k.strip('\\\\b') for k in args.keywords)}` · Saved: **{len(saved_articles)}**\n\n"
            "| Date | Article | Category | Channel | Source |\n| :--- | :--- | :--- | :--- | :--- |\n"
        )
        for a in saved_articles:
            link = f"[Source]({a['url']})" if a["url"] else "Telegram"
            index += (f"| {a['date']} | [{a['title'][:60]}](./{a['sub_folder']}/{a['filename']}) "
                      f"| `{a['category']}` | {a['channel']} | {link} |\n")
        (out_root / "INDEX.md").write_text(index, encoding="utf-8")
        print(f"[+] Generated INDEX.md for {len(saved_articles)} writeups in {out_root}")


def main():
    ap = argparse.ArgumentParser(description="Crawl Telegram bug-bounty channels for writeup intel.")
    ap.add_argument("--keywords", default=",".join(k.replace(r"\b", "") for k in DEFAULT_KEYWORDS),
                    help="comma-separated regex keywords (default: auth set)")
    ap.add_argument("--folder-filter", default="bug_bounty",
                    help="name of the Telegram dialog filter (folder) to scan")
    ap.add_argument("--out", default="research/case_studies/_fresh_tg",
                    help="output directory (default: research/case_studies/_fresh_tg)")
    ap.add_argument("--msg-limit", type=int, default=800, help="messages per channel to scan")
    args = ap.parse_args()
    args.keywords = [k.strip() for k in args.keywords.split(",") if k.strip()]

    api_id, api_hash, session_name = load_credentials()
    asyncio.run(crawl(args, api_id, api_hash, session_name))


if __name__ == "__main__":
    main()
