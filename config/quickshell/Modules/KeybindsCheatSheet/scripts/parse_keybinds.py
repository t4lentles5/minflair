#!/usr/bin/env python3

import json
import os
import re
import sys
from pathlib import Path

KEY_MAP = {
    "Return": "Enter",
    "SPACE": "Space",
    "Tab": "Tab",
    "left": "←",
    "right": "→",
    "up": "↑",
    "down": "↓",
    "mouse_down": "Scroll ↓",
    "mouse_up": "Scroll ↑",
    "mouse:272": "LClick",
    "mouse:273": "RClick",
    "XF86AudioRaiseVolume": "Vol ↑",
    "XF86AudioLowerVolume": "Vol ↓",
    "XF86AudioMute": "Mute",
    "XF86AudioMicMute": "Mic Mute",
    "XF86MonBrightnessUp": "Bri ↑",
    "XF86MonBrightnessDown": "Bri ↓",
    "XF86AudioPlay": "Play/Pause",
    "XF86AudioNext": "Next",
    "XF86AudioPrev": "Prev",
    "XF86AudioStop": "Stop",
}

MOD_MAP = {
    "$mainMod": "Super",
    "SUPER": "Super",
    "SHIFT": "Shift",
    "CTRL": "Ctrl",
    "ALT": "Alt",
}


SECTION_MERGE_HYPR = {
    "Applications": "Applications",
    "Tools": "System",
    "Quickshell Widgets": "Quickshell",
    "Quickshell Apps": "Quickshell",
    "Volume": "System",
    "Brightness": "System",
    "Media Player": "System",
    "Window Management": "Windows",
    "Window Groups": "Windows",
    "Navigation": "Windows",
    "Mouse Binds": "Windows",
    "Workspaces": "Workspaces",
}


def parse_mods(mod_str):
    mod_str = (
        mod_str.replace("mainMod", "SUPER")
        .replace("..", "")
        .replace('"', "")
        .replace("'", "")
    )
    parts = re.split(r"\s+", mod_str.strip())
    return [MOD_MAP.get(p, p) for p in parts if p]


def parse_key(key_str):
    k = key_str.strip()
    return KEY_MAP.get(k, k.upper() if len(k) == 1 else k)


def parse_keybinds(filepath):
    path = Path(filepath)
    if not path.is_file():
        print("[]")
        return

    merged = {}
    section_order = []
    current_target = None
    current_desc = None
    seen_group = {}

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except Exception:
        print("[]")
        return

    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        i += 1

        if not line or line.startswith("local") or line.startswith("$"):
            continue

        if line.startswith("-- ## "):
            name = line[6:].strip()
            target = SECTION_MERGE_HYPR.get(name, name)
            if target not in merged:
                merged[target] = []
                section_order.append(target)

            merged[target].append({"is_subheader": True, "name": name})
            current_target = target
            seen_group = {}
            continue

        if line.startswith("-- # "):
            current_desc = line[5:].strip()
            continue

        if line.startswith("hl.") and "," not in line:
            while "," not in line and i < len(lines):
                line += " " + lines[i].strip()
                i += 1

        raw_mods = ""
        raw_key = ""
        bind_m = re.match(r"^hl\.bind[a-z]*\s*\(\s*(.*?)\s*,", line)
        if bind_m:
            arg = bind_m.group(1)
            clean = (
                arg.replace("mainMod", "SUPER")
                .replace("..", "")
                .replace('"', "")
                .replace("'", "")
                .strip()
            )
            parts = clean.split(" + ")
            if len(parts) >= 2:
                raw_mods = " ".join([p.strip() for p in parts[:-1]])
                raw_key = parts[-1].strip()
            elif len(parts) == 1:
                raw_mods = ""
                raw_key = parts[0].strip()
        else:
            kw_m = re.match(
                r"^hl\.keyword\(\s*\"bind[a-z]*\"\s*,\s*\"(.*?),\s*(.+?),", line
            )
            if kw_m:
                raw_mods = kw_m.group(1)
                raw_key = kw_m.group(2)

        if not raw_key or not current_target:
            continue

        mods = parse_mods(raw_mods)
        key = parse_key(raw_key)

        if not current_desc:
            continue

        group_key = current_desc
        if group_key in seen_group:
            current_desc = None
            continue

        seen_group[group_key] = True

        hint_match = re.search(r"\((.+?)\)", current_desc)
        if hint_match:
            desc_clean = current_desc[: hint_match.start()].strip()
            hint_keys = hint_match.group(1)
            keys = mods + [hint_keys]
        else:
            desc_clean = current_desc
            keys = mods + [key]

        merged[current_target].append({"keys": keys, "desc": desc_clean})
        current_desc = None

    sections = [{"section": name, "binds": merged[name]} for name in section_order]

    quickshell_binds = [
        {"is_subheader": True, "name": "Package Manager", "desc": ""},
        {"keys": ["/"], "desc": "Focus search"},
        {"keys": ["Esc"], "desc": "Close / Blur search"},
        {"keys": ["↕ ↔"], "desc": "Navigate list"},
        {"keys": ["Ctrl", "I"], "desc": "Open details"},
    ]

    qs_found = False
    for sec in sections:
        if sec["section"] == "Quickshell":
            sec["binds"].extend(quickshell_binds)
            qs_found = True
            break

    if not qs_found:
        sections.append({"section": "Quickshell", "binds": quickshell_binds})

    print(json.dumps(sections))


if __name__ == "__main__":
    conf = str(Path.home() / ".config" / "hypr" / "keybinds.lua")
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        conf = sys.argv[1]
    parse_keybinds(conf)
