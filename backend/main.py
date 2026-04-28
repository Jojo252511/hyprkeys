"""
HyprKeys Backend v2 – Caelestia Rice
Unterstützt:
  - Getrennte Config-Dateien (keybinds.conf, variables.conf)
  - $variable Auflösung
  - Alle bind-Varianten: bind, bindi, bindin, bindl, bindle, bindm, bindr, binde
  - Variables-Editor Endpunkt
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import re, os, shutil
from pathlib import Path
from datetime import datetime

app = FastAPI(title="HyprKeys API", version="2.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ---------------------------------------------------------------------------
# Pfade – per Env überschreibbar
# ---------------------------------------------------------------------------
HYPR_BASE = Path(os.environ.get("HYPR_BASE",  Path.home() / ".config/hypr"))
KEYBINDS  = Path(os.environ.get("KEYBINDS",   HYPR_BASE / "hyprland/keybinds.conf"))
VARIABLES = Path(os.environ.get("VARIABLES",  HYPR_BASE / "variables.conf"))

# ---------------------------------------------------------------------------
# Regex
# ---------------------------------------------------------------------------
BIND_RE = re.compile(
    r'^(\s*)(bind[a-z]*)\s*=\s*'
    r'([^,]*),\s*'
    r'([^,]*),\s*'
    r'([^,\n#]*?)'
    r'(?:,\s*([^\n#]*?))?'
    r'\s*(?:#\s*(.*))?$',
    re.IGNORECASE,
)
VAR_RE = re.compile(r'^\s*\$([A-Za-z0-9_]+)\s*=\s*(.*)$')

# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------
class Keybind(BaseModel):
    id: str
    bind_type: str
    modifier_raw: str
    modifier_resolved: str
    key_raw: str
    key_resolved: str
    dispatcher: str
    argument: str
    comment: str
    line_number: int

class KeybindUpdate(BaseModel):
    bind_type: str = "bind"
    modifier: str
    key: str
    dispatcher: str
    argument: Optional[str] = ""
    comment: Optional[str] = ""

class VariableUpdate(BaseModel):
    value: str

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def parse_variables(path: Path) -> dict:
    if not path.exists():
        return {}
    vars = {}
    with open(path) as f:
        for line in f:
            m = VAR_RE.match(line)
            if m:
                val = re.sub(r'\s*#.*$', '', m.group(2)).strip()
                vars[m.group(1)] = val
    for _ in range(5):
        for k, v in vars.items():
            for rn, rv in vars.items():
                v = v.replace(f"${rn}", rv)
            vars[k] = v
    return vars

def resolve_var(raw: str, vars: dict) -> str:
    result = raw.strip()
    for name, val in vars.items():
        result = result.replace(f"${name}", val)
    return result

def get_variables_list(path: Path) -> list:
    if not path.exists():
        return []
    result = []
    with open(path) as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        m = VAR_RE.match(line)
        if m:
            val = re.sub(r'\s*#.*$', '', m.group(2)).strip()
            result.append({"name": m.group(1), "value": val, "line_number": i})
    return result

def parse_keybinds(path: Path, vars: dict) -> list:
    if not path.exists():
        return []
    binds = []
    with open(path) as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        m = BIND_RE.match(line.rstrip())
        if not m:
            continue
        _, btype, mod_raw, key_raw, disp, arg, comment = m.groups()
        mod_raw = mod_raw.strip()
        key_raw = key_raw.strip()
        binds.append({
            "id": f"bind_{i}",
            "bind_type": btype.lower(),
            "modifier_raw": mod_raw,
            "modifier_resolved": resolve_var(mod_raw, vars),
            "key_raw": key_raw,
            "key_resolved": resolve_var(key_raw, vars),
            "dispatcher": (disp or "").strip(),
            "argument": (arg or "").strip(),
            "comment": (comment or "").strip(),
            "line_number": i,
        })
    return binds

def backup(path: Path):
    if path.exists():
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        shutil.copy2(path, path.with_name(path.stem + f".bak_{ts}" + path.suffix))

def build_bind_line(kb: KeybindUpdate) -> str:
    line = f"{kb.bind_type} = {kb.modifier}, {kb.key}, {kb.dispatcher}"
    if kb.argument:
        line += f", {kb.argument}"
    if kb.comment:
        line += f"  # {kb.comment}"
    return line

# ---------------------------------------------------------------------------
# Routes – Keybinds
# ---------------------------------------------------------------------------
@app.get("/api/keybinds", response_model=list[Keybind])
def get_keybinds():
    return parse_keybinds(KEYBINDS, parse_variables(VARIABLES))

@app.post("/api/keybinds")
def create_keybind(kb: KeybindUpdate):
    KEYBINDS.parent.mkdir(parents=True, exist_ok=True)
    if not KEYBINDS.exists():
        KEYBINDS.touch()
    backup(KEYBINDS)
    with open(KEYBINDS, "a") as f:
        f.write(build_bind_line(kb) + "\n")
    with open(KEYBINDS) as f:
        ln = len(f.readlines()) - 1
    return {"ok": True, "id": f"bind_{ln}"}

@app.put("/api/keybinds/{bind_id}")
def update_keybind(bind_id: str, kb: KeybindUpdate):
    binds = parse_keybinds(KEYBINDS, parse_variables(VARIABLES))
    target = next((b for b in binds if b["id"] == bind_id), None)
    if not target:
        raise HTTPException(404, "Nicht gefunden")
    backup(KEYBINDS)
    lines = open(KEYBINDS).readlines()
    lines[target["line_number"]] = build_bind_line(kb) + "\n"
    open(KEYBINDS, "w").writelines(lines)
    return {"ok": True}

@app.delete("/api/keybinds/{bind_id}")
def delete_keybind(bind_id: str):
    binds = parse_keybinds(KEYBINDS, parse_variables(VARIABLES))
    target = next((b for b in binds if b["id"] == bind_id), None)
    if not target:
        raise HTTPException(404, "Nicht gefunden")
    backup(KEYBINDS)
    lines = open(KEYBINDS).readlines()
    lines.pop(target["line_number"])
    open(KEYBINDS, "w").writelines(lines)
    return {"ok": True}

# ---------------------------------------------------------------------------
# Routes – Variables
# ---------------------------------------------------------------------------
@app.get("/api/variables")
def get_variables():
    return get_variables_list(VARIABLES)

@app.put("/api/variables/{name}")
def update_variable(name: str, update: VariableUpdate):
    vlist = get_variables_list(VARIABLES)
    target = next((v for v in vlist if v["name"] == name), None)
    if not target:
        raise HTTPException(404, "Variable nicht gefunden")
    backup(VARIABLES)
    lines = open(VARIABLES).readlines()
    old = lines[target["line_number"]]
    cm = re.search(r'\s*#.*$', old)
    comment_part = cm.group(0) if cm else ""
    lines[target["line_number"]] = f"${name} = {update.value}{comment_part}\n"
    open(VARIABLES, "w").writelines(lines)
    return {"ok": True}

# ---------------------------------------------------------------------------
# Routes – Meta
# ---------------------------------------------------------------------------
@app.get("/api/config-info")
def config_info():
    return {
        "keybinds_file": str(KEYBINDS),
        "keybinds_exists": KEYBINDS.exists(),
        "variables_file": str(VARIABLES),
        "variables_exists": VARIABLES.exists(),
    }

@app.get("/api/dispatchers")
def get_dispatchers():
    return sorted([
        "exec", "killactive", "closewindow", "workspace", "movetoworkspace",
        "movetoworkspacesilent", "togglefloating", "fullscreen", "fakefullscreen",
        "dpms", "pin", "movefocus", "movewindow", "resizewindow", "resizeactive",
        "cyclenext", "swapnext", "focuswindow", "focusmonitor", "splitratio",
        "toggleopaque", "movecursortocorner", "workspaceopt", "exit",
        "forcerendererreload", "movecurrentworkspacetomonitor",
        "focusworkspaceoncurrentmonitor", "togglespecialworkspace",
        "swapactiveworkspaces", "bringactivetotop", "alterzorder", "togglesplit",
        "layoutmsg", "global", "submap", "moveoutofgroup", "changegroupactive",
        "togglegroup", "lockactivegroup", "centerwindow",
    ])

@app.get("/api/bind-types")
def get_bind_types():
    return [
        {"value": "bind",   "desc": "Normal"},
        {"value": "binde",  "desc": "Repeat beim Halten"},
        {"value": "bindl",  "desc": "Auch bei Lock-Screen"},
        {"value": "bindle", "desc": "Lock-Screen + Repeat"},
        {"value": "bindr",  "desc": "Beim Loslassen (release)"},
        {"value": "bindm",  "desc": "Maus-Aktion"},
        {"value": "bindi",  "desc": "Ignoriert Inhibitoren"},
        {"value": "bindin", "desc": "Ignoriert + Non-consuming"},
    ]

@app.get("/health")
def health():
    return {"status": "ok", "version": "2.0.0"}

# ---------------------------------------------------------------------------
# Frontend ausliefern (verhindert file:// CORS-Probleme)
# ---------------------------------------------------------------------------
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

FRONTEND_DIR = Path(__file__).parent.parent / "frontend"
if FRONTEND_DIR.exists():
    app.mount("/", StaticFiles(directory=str(FRONTEND_DIR), html=True), name="frontend")