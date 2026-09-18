#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DATA_DIR="$HOME/.local/share/wom-tracker"
CONFIG_DIR="$HOME/.config/wom-tracker"
CONFIG_FILE="$CONFIG_DIR/config.json"
SYSTEMD_DIR="$HOME/.config/systemd/user"

mkdir -p "$DATA_DIR" "$CONFIG_DIR" "$SYSTEMD_DIR"

cp "$SCRIPT_DIR/wom_tracker/fetch.py" "$DATA_DIR/fetch.py"
chmod +x "$DATA_DIR/fetch.py"

if [ ! -f "$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/wom_tracker/config.json" "$CONFIG_FILE"
    if [ -t 0 ]; then
        read -rp "Qual seu RuneScape name (RSN)? " rsn
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
        echo "Sessão não-interativa: edite $CONFIG_FILE manualmente antes de continuar (campo 'username')."
    fi
    echo "Config em $CONFIG_FILE — dá pra ajustar período (day/week/month/year/all_time), tamanho do widget, etc."
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

echo "Rodando o fetch uma vez pra já ter dados..."
python3 "$DATA_DIR/fetch.py"

echo "Instalando o widget..."
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
echo "Pronto! Clique com o botão direito na área de trabalho -> Adicionar Widgets"
echo "e procure por 'Wise Old Man Tracker'."
if [ "$WAS_INSTALLED" -eq 1 ]; then
    echo
    echo "Você já tinha o widget instalado antes — o plasmashell provavelmente está com a versão"
    echo "antiga em cache. Reinicie ele pra pegar a atualização:"
    echo "  systemctl --user restart plasma-plasmashell.service"
fi
