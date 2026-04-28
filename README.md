# HyprKeys — Caelestia Rice

Keybind-Manager für Hyprland. Backend (FastAPI) + Web-Frontend.

## Struktur

```
hyprkeys/
├── backend/
│   ├── main.py           # FastAPI REST-API
│   └── requirements.txt
├── frontend/
│   └── index.html        # Single-file Web-UI
├── start.sh              # Alles starten
└── README.md
```

## Schnellstart

```bash
chmod +x start.sh
./start.sh
```

Oder manuell:

```bash
# Backend
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

# Frontend: index.html im Browser öffnen
```

## Eigener Config-Pfad

```bash
HYPR_CONFIG=~/.config/hypr/hyprland.conf ./start.sh
```

## API-Endpunkte

| Methode | Pfad                    | Beschreibung              |
|---------|-------------------------|---------------------------|
| GET     | /api/keybinds           | Alle Keybinds auslesen    |
| POST    | /api/keybinds           | Neue Keybind erstellen    |
| PUT     | /api/keybinds/{id}      | Keybind bearbeiten        |
| DELETE  | /api/keybinds/{id}      | Keybind löschen           |
| GET     | /api/dispatchers        | Alle Dispatcher-Namen     |
| GET     | /api/config-path        | Aktueller Config-Pfad     |
| GET     | /health                 | Backend-Status            |

## Features

- ✅ Liest `bind =` Zeilen aus `hyprland.conf`
- ✅ Automatisches Backup vor jeder Änderung (`.conf.bak_YYYYMMDD_HHMMSS`)
- ✅ Suche & Filter nach Dispatcher
- ✅ Erstellen / Bearbeiten / Löschen
- ✅ Kommentar-Unterstützung (`# ...`)
- ✅ Keine Datenbank – direkt in der Config-Datei