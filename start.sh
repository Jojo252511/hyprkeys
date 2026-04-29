#!/usr/bin/env bash
# HyprKeys – Startskript (nur starten, kein Setup)

APP_DIR="$HOME/.local/share/hyprkeys"
PYTHON="$APP_DIR/.venv/bin/python3"
BASE="${HYPR_BASE:-$HOME/.config/hypr}"
KB="${KEYBINDS:-$BASE/hyprland/keybinds.conf}"
VARS="${VARIABLES:-$BASE/variables.conf}"

if [ ! -f "$PYTHON" ]; then
  echo "HyprKeys ist nicht installiert. Bitte zuerst './install.sh' ausführen."
  exit 1
fi

HYPR_BASE="$BASE" KEYBINDS="$KB" VARIABLES="$VARS" \
  "$PYTHON" -m uvicorn main:app \
    --app-dir "$APP_DIR/backend" \
    --host 127.0.0.1 --port 8000 &
BACKEND_PID=$!

sleep 0.8
xdg-open "http://localhost:8000" 2>/dev/null || true

trap "kill $BACKEND_PID 2>/dev/null; exit" INT TERM
wait $BACKEND_PID