# wom-tracker

Widget de KDE Plasma 6 que mostra XP total, top 3 skills e top 3 bosses de
uma conta do Old School RuneScape, usando a API do
[Wise Old Man](https://docs.wiseoldman.net/).

## Como funciona

- `wom_tracker/fetch.py`: script Python (sem dependências externas) que busca
  os dados da conta configurada na API do WOM, calcula os top 3 e escreve:
  - `~/.cache/wom-tracker/data.json` — cache lido pelo widget
  - `~/.local/share/wom-tracker/history.db` — histórico (XP total por execução, em SQLite)
- Um timer do systemd (`--user`) roda esse script periodicamente.
- O widget (`plasmoid/`) lê o `data.json` via `DataSource` (engine `executable`,
  `cat` no arquivo) e se atualiza sozinho no mesmo intervalo.

## Instalar

```bash
./install.sh
```

O instalador pergunta seu RSN, cria o timer do systemd, roda o fetch uma vez
e instala o widget no Plasma. Depois é só clicar com o botão direito na área
de trabalho → **Adicionar Widgets** → procurar **"Wise Old Man Tracker"**.

Se você já tinha o widget instalado antes e atualizou os arquivos, o
`plasmashell` costuma ficar com uma versão em cache — reinicie ele pra pegar
a atualização:

```bash
systemctl --user restart plasma-plasmashell.service
```

## Configurar

Edite `~/.config/wom-tracker/config.json`:

```json
{
  "username": "YourRSN",
  "period": "week",
  "skill_top_n": 3,
  "boss_top_n": 3,
  "card_width": 978,
  "card_height": 92,
  "refresh_minutes": 30
}
```

| Campo | Descrição |
|---|---|
| `username` | RSN da conta a acompanhar |
| `period` | `day`, `week`, `month`, `year` ou `all_time`. Com `all_time`, os top 3 são pelo total acumulado (XP/KC de carreira) em vez de ganho no período |
| `skill_top_n` / `boss_top_n` | quantas skills/bosses mostrar (o layout foi pensado pra 3, valores maiores podem cortar) |
| `card_width` / `card_height` | tamanho do widget em pixels — útil se o seu painel/monitor corta o widget (foi exatamente esse problema que motivou esse campo) |
| `refresh_minutes` | intervalo do timer do systemd que busca dados novos |

Depois de editar, rode `python3 ~/.local/share/wom-tracker/fetch.py` uma vez
(ou espere o próximo ciclo do timer) pra aplicar.

### Outras ideias de configuração (não implementadas ainda)

Fica como referência pra quem quiser contribuir:

- Escolher manualmente quais skills/bosses fixar, em vez de "top 3 automático"
- Suporte a grupo/clã (WOM tem endpoints de group) em vez de só 1 conta
- Cores customizáveis (hoje usa as cores do tema do Plasma)
- Labels em inglês (hoje é só PT-BR)
- Popup com gráfico de histórico ao clicar no widget (o `history.db` já existe, só falta a UI)

## Atualizar manualmente

```bash
python3 ~/.local/share/wom-tracker/fetch.py
```

## Desinstalar

```bash
systemctl --user disable --now wom-tracker.timer
rm ~/.config/systemd/user/wom-tracker.{service,timer}
kpackagetool6 --type Plasma/Applet --remove org.awberto.womtracker
rm -rf ~/.local/share/wom-tracker ~/.config/wom-tracker ~/.cache/wom-tracker
```

## Requisitos

- KDE Plasma 6
- Python 3 (só biblioteca padrão, sem `pip install`)
- systemd `--user`
