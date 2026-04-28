#!/usr/bin/env bash
# HyprKeys – Start-Skript für Caelestia Rice
# Env-Variablen (alle optional):
#   HYPR_BASE  – Basis-Verzeichnis  (default: ~/.config/hypr)
#   KEYBINDS   – Pfad zu keybinds.conf
#   VARIABLES  – Pfad zu variables.conf

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$SCRIPT_DIR/backend"
FRONTEND="$SCRIPT_DIR/frontend"
VENV="$SCRIPT_DIR/.venv"

# Explizite Pfade ins venv – kein "source activate" nötig
PYTHON="$VENV/bin/python3"
PIP="$VENV/bin/pip"
UVICORN="$VENV/bin/uvicorn"

echo "╔══════════════════════════════╗"
echo "║  HyprKeys · Caelestia Rice  ║"
echo "╚══════════════════════════════╝"

# venv erstellen falls nicht vorhanden
if [ ! -d "$VENV" ]; then
  echo "→ Erstelle Python venv…"
  python3 -m venv "$VENV"
fi

# Abhängigkeiten installieren falls nötig
if ! "$PYTHON" -c "import fastapi, uvicorn" &>/dev/null; then
  echo "→ Installiere Abhängigkeiten…"
  "$PIP" install -q -r "$BACKEND/requirements.txt"
fi

# Pfade bestimmen
BASE="${HYPR_BASE:-$HOME/.config/hypr}"
KB="${KEYBINDS:-$BASE/hyprland/keybinds.conf}"
VARS="${VARIABLES:-$BASE/variables.conf}"

echo "→ Keybinds : $KB"
echo "→ Variables: $VARS"

[ ! -f "$KB" ]   && echo "  ⚠  keybinds.conf nicht gefunden"
[ ! -f "$VARS" ] && echo "  ⚠  variables.conf nicht gefunden"

echo "→ Starte Backend  http://localhost:8000"
HYPR_BASE="$BASE" KEYBINDS="$KB" VARIABLES="$VARS" \
  "$UVICORN" main:app --app-dir "$BACKEND" --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

sleep 1

echo "→ Öffne Frontend…"
if command -v xdg-open &>/dev/null; then
  xdg-open "http://localhost:8000"
elif command -v firefox &>/dev/null; then
  firefox "http://localhost:8000" &
fi

echo "→ Bereit! Drücke Ctrl+C zum Beenden."
trap "kill $BACKEND_PID 2>/dev/null" EXIT
wait $BACKEND_PID