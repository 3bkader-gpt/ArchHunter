import argparse
import json
import os
import re
import sys
import io
import subprocess
import urllib.request
import urllib.parse
import time

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def sanitize_filename(title):
    clean = re.sub(r'[\\/*?:"<>|]', "", title)
    clean = clean.replace(" ", "_").strip()
    return clean[:80]

def fetch_via_jina(url):
    """Fetch and convert Medium article to Markdown via Jina Reader using curl"""
    clean_url = url.split("?")[0]
    jina_url = f"https://r.jina.ai/{clean_url}"
    try:
        cmd = ["curl.exe", "-s", "-L", "--max-time", "25", jina_url]
        res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="ignore")
        content = res.stdout
        if "Markdown Content:" in content and len(content) > 300:
            return content
    except Exception as e:
        pass
    return None

def fetch_via_direct_curl(url):
    """Fetch using custom headers (Twitter Referer bypass)"""
    clean_url = url.split("?")[0]
    req = urllib.request.Request(clean_url, headers={
        "User-Agent": USER_AGENT,
        "Referer": "https://t.co/internal_redirect",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            # Extract paragraphs
            paras = re.findall(r'<p[^>]*>(.*?)</p>', html, re.DOTALL)
            clean_paras = [re.sub(r'<[^>]+>', '', p).strip() for p in paras if len(p.strip()) > 10]
            if len(clean_paras) > 5:
                # Basic markdown reconstruction
                title_match = re.search(r'<title>(.*?)</title>', html, re.IGNORECASE)
                title = title_match.group(1) if title_match else "Medium Writeup"
                md = f"# {title}\n\n**Source:** {clean_url}\n\n"
                md += "\n\n".join(clean_paras)
                return md
    except Exception:
        pass
    return None

def download_article(url, output_dir, default_title=None):
    os.makedirs(output_dir, exist_ok=True)
    print(f"[*] Fetching: {url}")
    
    content = fetch_via_jina(url)
    engine_used = "Jina Markdown Engine"
    
    if not content:
        print("  -> Primary engine failed, trying Twitter-Referer fallback...")
        content = fetch_via_direct_curl(url)
        engine_used = "Direct Fallback Engine"

    if not content:
        print(f"[-] Failed to retrieve readable content for: {url}")
        return False

    # Extract title from Markdown
    title = default_title or "writeup"
    title_match = re.search(r"^Title:\s*(.+)$", content, re.MULTILINE)
    if title_match and len(title_match.group(1).strip()) > 3:
        title = title_match.group(1).strip()
    elif default_title:
        title = default_title

    filename = sanitize_filename(title) + ".md"
    filepath = os.path.join(output_dir, filename)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"[+] Successfully saved ({engine_used}): {filepath} ({len(content)} bytes)")
    return True

def main():
    parser = argparse.ArgumentParser(description="Download Medium bug bounty writeups as Markdown.")
    parser.add_argument("--url", help="Single Medium article URL")
    parser.add_argument("--file", help="Path to JSON file containing extracted URLs")
    parser.add_argument("--limit", type=int, default=5, help="Max articles to download from file")
    parser.add_argument("--output-dir", default="research/writeups", help="Directory to save markdown files")
    args = parser.parse_args()

    if args.url:
        download_article(args.url, args.output_dir)
    elif args.file:
        if not os.path.exists(args.file):
            print(f"[-] File not found: {args.file}")
            sys.exit(1)
        with open(args.file, "r", encoding="utf-8") as f:
            items = json.load(f)

        medium_items = [it for it in items if "medium.com" in it.get("url", "")]
        print(f"[*] Found {len(medium_items)} Medium URLs. Downloading top {args.limit}...")

        success_count = 0
        for it in medium_items[:args.limit]:
            url = it.get("url")
            title = it.get("title")
            if download_article(url, args.output_dir, default_title=title):
                success_count += 1
            time.sleep(1) # respectful delay

        print(f"\n[+] Batch complete! Successfully downloaded {success_count}/{args.limit} articles to '{args.output_dir}'.")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
