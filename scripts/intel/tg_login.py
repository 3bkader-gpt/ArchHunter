#!/usr/bin/env python3
"""One-time Telegram session login for the ArchHunter intel crawler.

Creates the *.session file used by fetch_telegram_intel.py. Credentials are
prompted interactively (never hardcode them in a repo):

  TELEGRAM_API_ID / TELEGRAM_API_HASH  env vars, or scripts/intel/.tg_credentials.json

Usage:
  python scripts/intel/tg_login.py
"""
import asyncio
import getpass
import json
import os
import sys
from pathlib import Path

from telethon import TelegramClient
from telethon.errors import SessionPasswordNeededError

SESSION_NAME = os.environ.get("TELEGRAM_SESSION", "my_telegram_session")


def load_credentials():
    api_id = os.environ.get("TELEGRAM_API_ID")
    api_hash = os.environ.get("TELEGRAM_API_HASH")
    if not (api_id and api_hash):
        cred_file = Path(__file__).parent / ".tg_credentials.json"
        if cred_file.exists():
            creds = json.loads(cred_file.read_text(encoding="utf-8"))
            api_id, api_hash = creds.get("api_id"), creds.get("api_hash")
    if not (api_id and api_hash):
        api_id = input("TELEGRAM_API_ID: ").strip()
        api_hash = getpass.getpass("TELEGRAM_API_HASH: ").strip()
    return int(api_id), api_hash


async def main():
    api_id, api_hash = load_credentials()
    phone = input("Phone number (e.g. +2011xxxxxxxxx): ").strip()
    password = getpass.getpass("2FA password (leave empty if none set): ")

    client = TelegramClient(SESSION_NAME, api_id, api_hash)
    await client.connect()

    if await client.is_user_authorized():
        me = await client.get_me()
        print(f"ALREADY_AUTHORIZED:{me.first_name}:{me.id}")
        await client.disconnect()
        return

    result = await client.send_code_request(phone)
    code = input("Login code sent by Telegram: ").strip()
    try:
        await client.sign_in(phone=phone, code=code, phone_code_hash=result.phone_code_hash)
    except SessionPasswordNeededError:
        if not password:
            password = getpass.getpass("2FA password required: ")
        await client.sign_in(password=password)

    if await client.is_user_authorized():
        me = await client.get_me()
        print(f"LOGIN_SUCCESS:{me.first_name}:{me.id}")
        print(f"[+] Session saved as '{SESSION_NAME}.session' — point TELEGRAM_SESSION at it.")
    else:
        print("LOGIN_FAILED")
    await client.disconnect()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        sys.exit(130)
