#!/usr/bin/env python3
"""Merges a base64-encoded JSON payload (sent by the widget's config dialog)
into ~/.config/wom-tracker/config.json. Invoked from QML so field values
never touch a shell string directly."""

import base64
import json
import os
import sys
from pathlib import Path

CONFIG_PATH = Path(os.environ.get("WOM_TRACKER_CONFIG", Path.home() / ".config/wom-tracker/config.json"))


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: apply_config.py <base64-json>", file=sys.stderr)
        return 1

    payload = json.loads(base64.b64decode(sys.argv[1]).decode("utf-8"))

    config = {}
    if CONFIG_PATH.exists():
        try:
            config = json.loads(CONFIG_PATH.read_text())
        except json.JSONDecodeError:
            pass

    config.update(payload)
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(config, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
