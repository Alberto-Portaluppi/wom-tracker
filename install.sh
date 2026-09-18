#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DATA_DIR="$HOME/.local/share/wom-tracker"
CONFIG_DIR="$HOME/.config/wom-tracker"
CONFIG_FILE="$CONFIG_DIR/config.json"
SYSTEMD_DIR="$HOME/.config/systemd/user"

mkdir -p "$DATA_DIR" "$CONFIG_DIR" "$SYSTEMD_DIR"

cp "$SCRIPT_DIR/wom_tracker/fetch.py" "$DATA_DIR/fetch.py"
cp "$SCRIPT_DIR/wom_tracker/apply_config.py" "$DATA_DIR/apply_config.py"
chmod +x "$DATA_DIR/fetch.py" "$DATA_DIR/apply_config.py"

if [ ! -f "$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/wom_tracker/config.json" "$CONFIG_FILE"
    if [ -t 0 ]; then
        read -rp "What's your RuneScape name (RSN)? " rsn
        if [ -n "$rsn" ]; then
            CONFIG_FILE="$CONFIG_FILE" RSN="$rsn" python3 -c "
import json, os
p = os.environ['CONFIG_FILE']
c = json.load(open(p))
c['username'] = os.environ['RSN']
json.dump(c, open(p, 'w'), indent=2)
"
        fi
    else
        echo "Non-interactive session: edit $CONFIG_FILE manually before continuing (the 'username' field)."
    fi
    echo "Config written to $CONFIG_FILE — you can also tweak it from the widget's own"
    echo "'Configure...' dialog once it's added (period, top N, widget size, etc.)."
fi

REFRESH_MIN=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('refresh_minutes', 30))")

cat > "$SYSTEMD_DIR/wom-tracker.service" <<'EOF'
[Unit]
Description=Wise Old Man tracker fetch

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 %h/.local/share/wom-tracker/fetch.py
EOF

cat > "$SYSTEMD_DIR/wom-tracker.timer" <<EOF
[Unit]
Description=Run Wise Old Man tracker fetch periodically

[Timer]
OnBootSec=2min
OnUnitActiveSec=${REFRESH_MIN}min
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now wom-tracker.timer

echo "Running fetch once to get initial data..."
python3 "$DATA_DIR/fetch.py"

echo "Installing the widget..."
WAS_INSTALLED=0
if [ -d "$HOME/.local/share/plasma/plasmoids/org.awberto.womtracker" ]; then
    WAS_INSTALLED=1
fi
if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --install "$SCRIPT_DIR/plasmoid" \
        || kpackagetool6 --type Plasma/Applet --upgrade "$SCRIPT_DIR/plasmoid"
else
    kpackagetool5 --type Plasma/Applet --install "$SCRIPT_DIR/plasmoid" \
        || kpackagetool5 --type Plasma/Applet --upgrade "$SCRIPT_DIR/plasmoid"
fi

echo
echo "Done! Right-click your desktop -> Add Widgets -> search for 'Wise Old Man Tracker'."
if [ "$WAS_INSTALLED" -eq 1 ]; then
    echo
    echo "You already had the widget installed — plasmashell is likely still running the"
    echo "old cached version. Restart it to pick up the update:"
    echo "  systemctl --user restart plasma-plasmashell.service"
    echo
    echo "If you also changed the widget's QML (not just fetch.py), a plain restart"
    echo "sometimes isn't enough after several in-place upgrades — remove the widget from"
    echo "the desktop and add it back fresh if you still see stale/duplicated behavior."
fi
