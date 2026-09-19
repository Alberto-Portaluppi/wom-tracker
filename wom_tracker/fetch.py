#!/usr/bin/env python3
"""Fetches XP/boss KC data from the Wise Old Man API and writes a cache
file for the KDE Plasma widget. Also appends a row to a local history DB —
the widget's history graph actually reads snapshots straight from the WOM
API (deeper, real history), so this local DB isn't used for that yet; it's
kept as a standing local record in case that ever changes."""

import json
import os
import sqlite3
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

API_BASE = "https://api.wiseoldman.net/v2"
RUNEPROFILE_API_BASE = "https://api.runeprofile.com/v1"
USER_AGENT = "wom-tracker/1.0 (personal desktop widget)"

CONFIG_PATH = Path(os.environ.get("WOM_TRACKER_CONFIG", Path.home() / ".config/wom-tracker/config.json"))
CACHE_PATH = Path(os.environ.get("WOM_TRACKER_CACHE", Path.home() / ".cache/wom-tracker/data.json"))
DB_PATH = Path(os.environ.get("WOM_TRACKER_DB", Path.home() / ".local/share/wom-tracker/history.db"))

VALID_PERIODS = ("day", "week", "month", "year", "all_time")

DEFAULT_CONFIG = {
    "username": "YourRSN",
    "period": "week",
    "skill_top_n": 3,
    "boss_top_n": 3,
    "card_width": 978,
    "card_height": 92,
    "refresh_minutes": 30,
}

PERIOD_LABELS = {
    "day": "day",
    "week": "week",
    "month": "month",
    "year": "year",
    "all_time": "total",
}

NAME_OVERRIDES = {
    "tztok_jad": "TzTok-Jad",
    "tzkal_zuk": "TzKal-Zuk",
    "kril_tsutsaroth": "K'ril Tsutsaroth",
    "phosanis_nightmare": "Phosani's Nightmare",
    "the_gauntlet": "Gauntlet",
    "the_corrupted_gauntlet": "Corrupted Gauntlet",
    "the_hueycoatl": "Hueycoatl",
    "the_leviathan": "Leviathan",
    "the_royal_titans": "Royal Titans",
    "the_whisperer": "Whisperer",
    "chambers_of_xeric_challenge_mode": "Chambers of Xeric (CM)",
    "theatre_of_blood_hard_mode": "Theatre of Blood (HM)",
    "tombs_of_amascut_expert": "Tombs of Amascut (Expert)",
    "amoxliatl": "Amoxliatl",
}


def pretty_name(metric: str) -> str:
    if metric in NAME_OVERRIDES:
        return NAME_OVERRIDES[metric]
    return metric.replace("_", " ").title()


def load_config() -> dict:
    config = dict(DEFAULT_CONFIG)
    if CONFIG_PATH.exists():
        try:
            config.update(json.loads(CONFIG_PATH.read_text()))
        except json.JSONDecodeError:
            pass
    if config["period"] not in VALID_PERIODS:
        config["period"] = "week"
    return config


def api_get(path: str) -> dict:
    req = urllib.request.Request(
        f"{API_BASE}{path}",
        headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.load(resp)


def api_post(path: str) -> None:
    req = urllib.request.Request(
        f"{API_BASE}{path}", headers={"User-Agent": USER_AGENT}, method="POST"
    )
    try:
        urllib.request.urlopen(req, timeout=15)
    except (urllib.error.HTTPError, urllib.error.URLError):
        # Rate-limited or offline: fall back to whatever snapshot WOM already has.
        pass


def ensure_db(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS history (
            ts TEXT PRIMARY KEY,
            overall_xp INTEGER NOT NULL,
            overall_level INTEGER NOT NULL
        )
        """
    )
    conn.commit()


def top_skills_total(player: dict, n: int) -> list:
    skills = player["latestSnapshot"]["data"]["skills"]
    ranked = [(m, s["experience"]) for m, s in skills.items() if m != "overall"]
    ranked.sort(key=lambda item: item[1], reverse=True)
    return [{"metric": m, "name": pretty_name(m), "value": v, "suffix": "xp", "prefix": ""} for m, v in ranked[:n]]


def top_skills_gained(gains: dict, n: int) -> list:
    skills = gains["data"]["skills"]
    ranked = [
        (m, s["experience"]["gained"])
        for m, s in skills.items()
        if m != "overall"
    ]
    ranked.sort(key=lambda item: item[1], reverse=True)
    return [{"metric": m, "name": pretty_name(m), "value": v, "suffix": "xp", "prefix": "+"} for m, v in ranked[:n]]


def top_bosses_total(player: dict, n: int) -> list:
    bosses = player["latestSnapshot"]["data"]["bosses"]
    ranked = [(m, b["kills"]) for m, b in bosses.items() if b.get("kills", -1) > 0]
    ranked.sort(key=lambda item: item[1], reverse=True)
    return [{"metric": m, "name": pretty_name(m), "value": k, "suffix": "kc", "prefix": ""} for m, k in ranked[:n]]


def top_bosses_gained(gains: dict, n: int) -> list:
    bosses = gains["data"]["bosses"]
    ranked = [(m, b["kills"]["gained"]) for m, b in bosses.items() if b["kills"]["gained"] > 0]
    ranked.sort(key=lambda item: item[1], reverse=True)
    return [{"metric": m, "name": pretty_name(m), "value": k, "suffix": "kc", "prefix": "+"} for m, k in ranked[:n]]


def runeprofile_get(path: str):
    req = urllib.request.Request(
        f"{RUNEPROFILE_API_BASE}{path}",
        headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.load(resp)
    except (urllib.error.URLError, urllib.error.HTTPError):
        # Not tracked by RuneProfile, offline, or rate-limited: treat as "no data"
        # rather than failing the whole fetch, since this is a bonus data source.
        return None


def fetch_activities(username: str, activity_type: str, limit: int = 3) -> list:
    data = runeprofile_get(f"/accounts/{username}/activities?activityTypes={activity_type}&limit={limit}")
    return data["activities"] if data else []


def parse_rp_timestamp(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace(" ", "T", 1))


def format_valuable_drops(items: list) -> list:
    return [
        {
            "name": item["enriched"].get("itemName", "Unknown item"),
            "value": item["data"]["value"],
            "suffix": "gp",
            "prefix": "+",
        }
        for item in items
    ]


def format_new_items(items: list) -> list:
    return [
        {
            "name": item["enriched"].get("itemName", "Unknown item"),
            "value": parse_rp_timestamp(item["createdAt"]).strftime("%d/%m"),
            "suffix": "",
            "prefix": "",
        }
        for item in items
    ]


def format_combat_achievements(items: list) -> list:
    return [
        {
            "name": item["enriched"].get("taskName", "Unknown task"),
            "value": item["enriched"].get("tierName", ""),
            "suffix": "",
            "prefix": "",
        }
        for item in items
    ]


def format_xp_milestones(items: list) -> list:
    return [
        {
            "name": item["data"]["name"],
            "value": item["data"]["xp"],
            "suffix": "xp",
            "prefix": "+",
        }
        for item in items
    ]


def fetch_runeprofile_extras(username: str) -> dict:
    return {
        "valuable_drops": format_valuable_drops(fetch_activities(username, "valuable_drop")),
        "new_items": format_new_items(fetch_activities(username, "new_item_obtained")),
        "combat_achievements": format_combat_achievements(
            fetch_activities(username, "combat_achievement_task_completed")
        ),
        "xp_milestones": format_xp_milestones(fetch_activities(username, "xp_milestone")),
    }


def main() -> int:
    config = load_config()
    username = config["username"]
    period = config["period"]
    period_label = PERIOD_LABELS[period]

    api_post(f"/players/{username}")  # nudge a fresh snapshot; safe to ignore failures

    try:
        player = api_get(f"/players/{username}")
        if period == "all_time":
            top_skills = top_skills_total(player, config["skill_top_n"])
            top_bosses = top_bosses_total(player, config["boss_top_n"])
        else:
            gains = api_get(f"/players/{username}/gained?period={period}")
            top_skills = top_skills_gained(gains, config["skill_top_n"])
            top_bosses = top_bosses_gained(gains, config["boss_top_n"])
    except (urllib.error.URLError, urllib.error.HTTPError) as exc:
        print(f"wom-tracker: fetch failed: {exc}", file=sys.stderr)
        return 1

    overall = player["latestSnapshot"]["data"]["skills"]["overall"]
    now = datetime.now(timezone.utc).isoformat()
    skills_label = "Total XP" if period == "all_time" else f"XP gained ({period_label})"
    bosses_label = "Total KC" if period == "all_time" else f"KC gained ({period_label})"
    extras = fetch_runeprofile_extras(username)

    result = {
        "username": player["displayName"],
        "updated_at": now,
        "overall": {"experience": overall["experience"], "level": overall["level"]},
        "period": period,
        "period_label": period_label,
        "skill_top_n": config["skill_top_n"],
        "boss_top_n": config["boss_top_n"],
        "skills_header": f"Top {config['skill_top_n']} {skills_label}",
        "top_skills": top_skills,
        "bosses_header": f"Top {config['boss_top_n']} {bosses_label}",
        "top_bosses": top_bosses,
        "valuable_drops": extras["valuable_drops"],
        "new_items": extras["new_items"],
        "combat_achievements": extras["combat_achievements"],
        "xp_milestones": extras["xp_milestones"],
        "card_width": config["card_width"],
        "card_height": config["card_height"],
    }

    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(json.dumps(result, indent=2))

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    ensure_db(conn)
    conn.execute(
        "INSERT OR REPLACE INTO history (ts, overall_xp, overall_level) VALUES (?, ?, ?)",
        (now, overall["experience"], overall["level"]),
    )
    conn.commit()
    conn.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
