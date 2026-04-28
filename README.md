# HyprKeys — Caelestia Rice

HyprKeys is a sleek, web-based Keybinding Manager specifically designed for Hyprland. It provides a modern interface to manage your hyprland keybinds without losing the flexibility of manual configuration

## Folder structure

```
hyprkeys/
├── backend/
│   ├── main.py           # FastAPI REST-API
│   └── requirements.txt
├── frontend/
│   └── index.html        # Single-file Web-UI
├── start.sh              
└── README.md
```

## Starteing

```bash
chmod +x start.sh
./start.sh
```

## API-Endpoints

| Method  | Path                    | Description               |
|---------|-------------------------|---------------------------|
| GET     | /api/keybinds           | List all parsed keybinds  |
| POST    | /api/keybinds           | Create a new keybind      |
| PUT     | /api/keybinds/{id}      | Update an existing keybind|
| DELETE  | /api/keybinds/{id}      | Remove a keybind          |
| GET     | /api/dispatchers        | List all dispatcher names |
| GET     | /api/config-path        | Current configuration path|
| GET     | /health                 | Backend status            |

