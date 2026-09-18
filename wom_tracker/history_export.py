#!/usr/bin/env python3
"""Fetches the account's real snapshot history from the Wise Old Man API and
prints total-XP-over-time points as JSON, for the widget's history graph
popup. Uses WOM's own server-side history (which usually goes back weeks to
months) instead of only what this widget has recorded locally, so the graph
has meaningful data from the very first time it's opened."""

import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

API_BASE = "https://api.wiseoldman.net/v2"
USER_AGENT = "wom-tracker/1.0 (personal desktop widget)"
MAX_LIMIT = 200
MAX_PAGES = 5  # safety cap: at most 1000 snapshots fetched per call

CONFIG_PATH = Path(os.environ.get("WOM_TRACKER_CONFIG", Path.home() / ".config/wom-tracker/config.json"))


def load_username() -> str:
    if CONFIG_PATH.exists():
        try:
            config = json.loads(CONFIG_PATH.read_text())
            return config.get("username", "YourRSN")
        except json.JSONDecodeError:
            pass
    return "YourRSN"


def api_get(path: str):
    req = urllib.request.Request(
        f"{API_BASE}{path}",
        headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.load(resp)


def parse_ts(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def fetch_snapshots(username: str, since: datetime) -> list:
    """Pages back through WOM's snapshot history until we reach `since`,
    run out of data, or hit the safety cap — needed because frequent
    fetch.py polling makes WOM record many closely-spaced snapshots, which
    would otherwise crowd the most recent ones out of a single page."""
    snapshots: list = []
    offset = 0
    for _ in range(MAX_PAGES):
        page = api_get(f"/players/{username}/snapshots?period=year&limit={MAX_LIMIT}&offset={offset}")
        if not page:
            break
        snapshots.extend(page)
        if len(page) < MAX_LIMIT or parse_ts(page[-1]["createdAt"]) <= since:
            break
        offset += MAX_LIMIT
    return snapshots


def main() -> int:
    days = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    username = load_username()
    since = datetime.now(timezone.utc) - timedelta(days=days)

    try:
        snapshots = fetch_snapshots(username, since)
    except (urllib.error.URLError, urllib.error.HTTPError) as exc:
        print(f"wom-tracker: history fetch failed: {exc}", file=sys.stderr)
        print(json.dumps({"days": days, "points": []}))
        return 1

    points = [
        {"ts": snap["createdAt"], "xp": snap["data"]["skills"]["overall"]["experience"]}
        for snap in snapshots
        if parse_ts(snap["createdAt"]) >= since
    ]
    points.sort(key=lambda p: p["ts"])

    print(json.dumps({"days": days, "points": points}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
