# wom-tracker

A KDE Plasma 6 widget that shows total XP, top skills, top bosses, and
recent activity (valuable drops, combat achievements, quests, level ups,
achievement diaries, collection log items) for an Old School RuneScape
account, using the [Wise Old Man](https://docs.wiseoldman.net/) and
[RuneProfile](https://api.runeprofile.com/v1/docs) APIs.

## How it works

- `wom_tracker/fetch.py`: a Python script (stdlib only, no dependencies) that
  fetches the configured account's data from the WOM and RuneProfile APIs,
  computes the top skills/bosses and recent activity, and writes:
  - `~/.cache/wom-tracker/data.json` — the cache the widget reads
  - `~/.local/share/wom-tracker/history.db` — a small history (total XP per run, in SQLite)
- A systemd `--user` timer runs that script periodically.
- The widget (`plasmoid/`) reads `data.json` via a `DataSource` (`executable`
  engine, `cat`-ing the file) and refreshes itself on the same interval.
- The two right-hand columns rotate through 1–5 user-configurable
  **panels**, like a display sign. Each panel's left/right content is
  independently chosen from: top skills, top bosses, valuable drops, new
  collection log items, combat achievements completed, combat achievement
  *progress*, XP milestones, level ups, quests completed, achievement
  diary tiers, or blank. Default is just 1 panel (top skills, top bosses)
  — no rotation, nothing irrelevant shown — since most of that activity
  data doesn't matter to everyone (e.g. a maxed account with quest cape
  has no use for level-up or quest-completed panels). Add panels for more.
  If `skill_top_n`/`boss_top_n` is set above 3, whichever panel shows them
  gets extra sub-pages, paired with whatever is on the other side of that
  panel. The RuneProfile-sourced content (everything except skills/bosses)
  requires the account to be tracked there (the free RuneLite plugin does
  this automatically); if it isn't, those panels just show "No data yet".
- Settings live in `~/.config/wom-tracker/config.json`, editable either
  directly or through the widget's own native **Configure...** dialog
  (right-click the widget → Configure Wise Old Man Tracker), backed by a
  standard KCFG schema (`plasmoid/contents/config/main.xml`).
- Clicking the widget toggles a popup with a total XP graph (`wom_tracker/history_export.py`),
  built from WOM's own server-side snapshot history — not just what this
  widget has recorded locally — so it has real data going back weeks from
  the very first time you open it. Click again (or click away) to close it.

## Install

```bash
./install.sh
```

The installer asks for your RSN, sets up the systemd timer, runs the fetch
once, and installs the widget into Plasma. Then just right-click your
desktop → **Add Widgets** → search for **"Wise Old Man Tracker"**.

If you already had the widget installed and updated the files, `plasmashell`
usually keeps a cached version — restart it to pick up the update:

```bash
systemctl --user restart plasma-plasmashell.service
```

If you've applied several in-place package upgrades to a *live* widget
instance without restarting in between, plasmashell can end up with
duplicated/stale context-menu actions. A plain restart usually fixes it; if
not, remove the widget from the desktop and add it back fresh.

## Configuring

The easiest way is right-clicking the widget → **Configure Wise Old Man
Tracker...** → **General** tab: RSN, period, top N skills/bosses, widget
size, the history graph's day range, the rotation speed, how many panels
to rotate through (1–5, under "Panels") and what each panel's left/right
column shows, and under "Other": whether to show your hiscores rank, a
minimum gp value for valuable drops, and whether to sort drops by value
instead of date — are all there, applied immediately on OK/Apply.

For settings not exposed in that dialog (like the refresh interval), edit
`~/.config/wom-tracker/config.json` directly:

```json
{
  "username": "YourRSN",
  "period": "week",
  "skill_top_n": 3,
  "boss_top_n": 3,
  "card_width": 978,
  "card_height": 92,
  "refresh_minutes": 30,
  "min_drop_value": 0,
  "drops_sort_by_value": false
}
```

| Field | Description |
|---|---|
| `username` | RSN of the account to track |
| `period` | `day`, `week`, `month`, `year`, or `all_time`. With `all_time`, the top lists rank by career total (XP/KC) instead of gains over a period |
| `skill_top_n` / `boss_top_n` | how many skills/bosses to track. Only 3 are shown at a time — if set higher, the panel showing them gets extra sub-pages, shown as a "(page/total)" indicator in the header |
| `card_width` / `card_height` | widget size in pixels — useful if your panel/monitor clips the widget |
| `refresh_minutes` | how often the systemd timer fetches new data |
| `min_drop_value` | ignore valuable drops below this gp value (looks back up to the last 50 drops to fill 3 slots) |
| `drops_sort_by_value` | `true` shows the 3 biggest drops (from that same pool) instead of the 3 most recent |

Number formatting (thousands separator, etc.) follows your system locale
automatically — no config needed there.

After a manual edit, run `python3 ~/.local/share/wom-tracker/fetch.py` once
(or wait for the next timer tick) to apply it.

### Other configuration ideas (not implemented yet)

Left here for anyone who wants to contribute:

- Manually pin specific skills/bosses instead of "auto top N"
- Group/clan support (WOM has group endpoints) instead of a single account
- Customizable colors (currently uses the Plasma theme's colors)

## Known limitation: data lags while you're logged in

The official OSRS hiscores (which WOM reads from) don't reliably reflect
your live progress while your character is still logged in — they tend to
"settle" once you log out. This isn't something this widget (or WOM) can
fix: no amount of polling helps if the upstream data hasn't updated yet.
If numbers look stuck during a long session, that's expected; they'll
catch up after you log out.

## Manual refresh

```bash
python3 ~/.local/share/wom-tracker/fetch.py
```

## Uninstall

```bash
systemctl --user disable --now wom-tracker.timer
rm ~/.config/systemd/user/wom-tracker.{service,timer}
kpackagetool6 --type Plasma/Applet --remove org.awberto.womtracker
rm -rf ~/.local/share/wom-tracker ~/.config/wom-tracker ~/.cache/wom-tracker
```

## Requirements

- KDE Plasma 6
- Python 3 (stdlib only, no `pip install`)
- systemd `--user`
