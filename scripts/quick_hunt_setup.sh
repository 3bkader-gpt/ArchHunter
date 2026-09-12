#!/bin/bash
# Quick Target Engagement Setup Script
# Usage: ./scripts/quick_hunt_setup.sh <target_domain> <program_name>

TARGET_DOMAIN=$1
PROGRAM_NAME=${2:-"HackerOne"}

if [ -z "$TARGET_DOMAIN" ]; then
    echo "Usage: ./scripts/quick_hunt_setup.sh <target_domain> [program_name]"
    echo "Example: ./scripts/quick_hunt_setup.sh target.com HackerOne"
    exit 1
fi

echo "[+] Initializing Bug Bounty Target: $TARGET_DOMAIN ($PROGRAM_NAME)"

# 1. Create target recon directories
mkdir -p "recon/$TARGET_DOMAIN/subs"
mkdir -p "recon/$TARGET_DOMAIN/urls"
mkdir -p "recon/$TARGET_DOMAIN/fuzz"
mkdir -p "recon/$TARGET_DOMAIN/results"

# 2. Copy Target Session Template
if [ ! -f "TARGET_SESSION.md" ]; then
    cp "templates/TARGET_SESSION_TEMPLATE.md" "TARGET_SESSION.md"
    sed -i "s/example.com/$TARGET_DOMAIN/g" "TARGET_SESSION.md"
    sed -i "s/\[TARGET_NAME\]/$TARGET_DOMAIN/g" "TARGET_SESSION.md"
    echo "[+] Created TARGET_SESSION.md customized for $TARGET_DOMAIN"
else
    echo "[!] TARGET_SESSION.md already exists, skipping overwrite."
fi

echo "[+] Setup Complete!"
echo "Next Steps:"
echo "1. Fill in account credentials in TARGET_SESSION.md"
echo "2. Run passive & active recon:"
echo "   subfinder -d $TARGET_DOMAIN -silent | dnsx -silent | httpx -sc -title -tech-detect -json -o recon/$TARGET_DOMAIN/signals.jsonl"
echo "3. Run Reasoning Engine:"
echo "   cd Runtime && go run cmd/runtime/main.go -input ../recon/$TARGET_DOMAIN/signals.jsonl -output ../recon/$TARGET_DOMAIN/results/"
