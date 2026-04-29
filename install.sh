#!/usr/bin/env bash
#
# Installer für HyprKeys – Caelestia Rice
#
set -e

echo "╔══════════════════════════════════╗"
echo "║   HyprKeys Installer             ║"
echo "║   Caelestia Rice · Hyprland      ║"
echo "╚══════════════════════════════════╝"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prüfe Quellstruktur
if [ ! -f "$SCRIPT_DIR/backend/main.py" ] || [ ! -f "$SCRIPT_DIR/frontend/index.html" ]; then
  echo "FEHLER: backend/main.py oder frontend/index.html nicht gefunden!"
  echo "Bitte stelle sicher, dass install.sh im HyprKeys-Projektordner liegt."
  exit 1
fi

# --- Pfade ---
APP_DIR="$HOME/.local/share/hyprkeys"
BIN_DIR="$HOME/.local/bin"
APP_LAUNCHER_DIR="$HOME/.local/share/applications"
VENV="$APP_DIR/.venv"
PYTHON="$VENV/bin/python3"
PIP="$VENV/bin/pip"

# --- SCHRITT 1: Abhängigkeiten ---
echo ">>> SCHRITT 1: Prüfe System-Abhängigkeiten..."
MISSING=()
command -v python3 &>/dev/null || MISSING+=("python3")
python3 -c "import venv" &>/dev/null || MISSING+=("python-venv")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "   Installiere fehlende Pakete: ${MISSING[*]}"
  sudo pacman -S --needed --noconfirm python
fi
echo "   ✓ Python vorhanden: $(python3 --version)"
echo

# --- SCHRITT 2: App-Dateien installieren ---
echo ">>> SCHRITT 2: Installiere App-Dateien nach $APP_DIR..."
mkdir -p "$BIN_DIR" "$APP_LAUNCHER_DIR"

if [ -d "$APP_DIR" ]; then
  echo "   ...Entferne alte Installation"
  rm -rf "$APP_DIR"
fi
mkdir -p "$APP_DIR"

cp -r "$SCRIPT_DIR/backend"  "$APP_DIR/"
cp -r "$SCRIPT_DIR/frontend" "$APP_DIR/"
cp    "$SCRIPT_DIR/start.sh" "$APP_DIR/"
chmod +x "$APP_DIR/start.sh"
echo "   ✓ Dateien kopiert"
echo

# --- SCHRITT 3: Python venv + Abhängigkeiten ---
echo ">>> SCHRITT 3: Erstelle Python-Umgebung..."
python3 -m venv "$VENV"
echo "   ✓ venv erstellt"
echo "   ...Installiere Python-Pakete (fastapi, uvicorn, aiofiles)..."
"$PIP" install -q fastapi "uvicorn[standard]" aiofiles pydantic
echo "   ✓ Pakete installiert"
echo

# --- SCHRITT 4: Startbefehl ---
echo ">>> SCHRITT 4: Erstelle Startbefehl..."
cat > "$BIN_DIR/hyprkeys" << BINEOF
#!/usr/bin/env bash
exec "$APP_DIR/start.sh" "\$@"
BINEOF
chmod +x "$BIN_DIR/hyprkeys"
echo "   ✓ Befehl: hyprkeys"
echo

# --- SCHRITT 5: App-Menü-Eintrag ---
echo ">>> SCHRITT 5: Erstelle App-Menü-Eintrag..."
cat > "$APP_LAUNCHER_DIR/org.caelestia.hyprkeys.desktop" << DESKEOF
[Desktop Entry]
Version=1.0
Name=HyprKeys
GenericName=Keybind Manager
Comment=Hyprland Tastenkürzel verwalten – Caelestia Rice
Exec=$APP_DIR/start.sh
Icon=preferences-desktop-keyboard
Terminal=false
Type=Application
Categories=Settings;System;
Keywords=keybind;hyprland;shortcut;keyboard;
StartupWMClass=hyprkeys
DESKEOF
echo "   ✓ Erscheint in der App-Liste als 'HyprKeys'"
echo

# --- SCHRITT 6: PATH sicherstellen ---
echo ">>> SCHRITT 6: Stelle sicher dass ~/.local/bin im PATH ist..."

# Fish
FISH_CONFIG="$HOME/.config/fish/config.fish"
if [ -d "$HOME/.config/fish" ]; then
  if ! grep -q "fish_add_path.*\.local/bin" "$FISH_CONFIG" 2>/dev/null; then
    echo "" >> "$FISH_CONFIG"
    echo "# HyprKeys PATH" >> "$FISH_CONFIG"
    echo "fish_add_path \$HOME/.local/bin" >> "$FISH_CONFIG"
    echo "   ✓ Fish-PATH aktualisiert"
  else
    echo "   ✓ Fish-PATH bereits gesetzt"
  fi
fi

# Bash/Zsh fallback
PROFILE="$HOME/.profile"
if ! grep -q '\.local/bin' "$PROFILE" 2>/dev/null; then
  echo '' >> "$PROFILE"
  echo '# HyprKeys PATH' >> "$PROFILE"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
  echo "   ✓ .profile aktualisiert"
fi
echo

# --- SCHRITT 7: Hyprland Keybind (optional) ---
echo ">>> SCHRITT 7: Hyprland-Keybind (optional)..."
KEYBINDS_FILE="$HOME/.config/hypr/hyprland/keybinds.conf"
BIND_LINE="bind = SUPER, F2, exec, hyprkeys  # HyprKeys öffnen"

if [ -f "$KEYBINDS_FILE" ]; then
  if ! grep -q "exec, hyprkeys" "$KEYBINDS_FILE"; then
    read -r -p "   Super+F2 als Keybind für HyprKeys eintragen? [j/N] " REPLY
    if [[ "$REPLY" =~ ^[jJyY]$ ]]; then
      echo "" >> "$KEYBINDS_FILE"
      echo "$BIND_LINE" >> "$KEYBINDS_FILE"
      echo "   ✓ Keybind eingetragen: Super+F2"
    else
      echo "   – Übersprungen"
    fi
  else
    echo "   ✓ Keybind bereits vorhanden"
  fi
else
  echo "   – keybinds.conf nicht gefunden, übersprungen"
fi
echo

# --- Fertig ---
echo "╔══════════════════════════════════╗"
echo "║   INSTALLATION ABGESCHLOSSEN     ║"
echo "╚══════════════════════════════════╝"
echo
echo "HyprKeys ist jetzt installiert!"
echo
echo "Starten:"
echo "  • App-Liste:  'HyprKeys' suchen"
echo "  • Terminal:   hyprkeys"
echo "  • Direkt:     $APP_DIR/start.sh"
echo
echo "Öffnet sich automatisch unter http://localhost:8000"
echo