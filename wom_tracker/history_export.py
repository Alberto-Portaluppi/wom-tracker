#!/usr/bin/env python3
"""Reads history.db and prints XP-over-time points as JSON, for the
widget's history graph popup."""

import json
import os
import sqlite3
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

DB_PATH = Path(os.environ.get("WOM_TRACKER_DB", Path.home() / ".local/share/wom-tracker/history.db"))


def main() -> int:
    days = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()

    points = []
    if DB_PATH.exists():
        conn = sqlite3.connect(DB_PATH)
        rows = conn.execute(
            "SELECT ts, overall_xp FROM history WHERE ts >= ? ORDER BY ts ASC",
            (since,),
        ).fetchall()
        conn.close()
        points = [{"ts": ts, "xp": xp} for ts, xp in rows]

    print(json.dumps({"days": days, "points": points}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
