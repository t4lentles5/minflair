#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import re
import subprocess
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import minflair_components as components


def lua_string(value):
    """Quote a value so it can be used as a Lua string literal.

    The theme name comes from the saved settings and is written into
    envs.lua, so a quote or a backslash in it would otherwise produce a
    broken file.
    """
    escaped = (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )
    return f'"{escaped}"'


def apply_cursor(theme_name, size, home=None, is_enabled=None):
    """Apply the cursor theme when the cursor component is enabled."""
    if is_enabled is None:
        is_enabled = components.enabled
    if not is_enabled("cursor"):
        return

    home = home or Path.home()

    # 1. Update GTK globally via gsettings
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme_name],
        capture_output=True,
    )
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", size],
        capture_output=True,
    )

    # 2. Update ~/.icons/default/index.theme
    icons_dir = home / ".icons" / "default"
    icons_dir.mkdir(parents=True, exist_ok=True)
    index_theme_path = icons_dir / "index.theme"

    content = f"[Icon Theme]\nInherits={theme_name}\n"
    index_theme_path.write_text(content, encoding="utf-8")

    # 3. Update ~/.config/hypr/envs.lua for persistence across reboots
    envs_lua = home / ".config" / "hypr" / "envs.lua"
    if envs_lua.is_file():
        try:
            content = envs_lua.read_text(encoding="utf-8")
            # The replacement is a function so the value is inserted literally.
            # A backslash or a quote in the theme name would otherwise be
            # treated as an escape sequence by re.sub and break the file.
            theme_literal = lua_string(theme_name)
            size_literal = lua_string(size)
            content = re.sub(
                r'hl\.env\("XCURSOR_THEME", ".*?"\)',
                lambda _: f"hl.env(\"XCURSOR_THEME\", {theme_literal})",
                content,
            )
            content = re.sub(
                r'hl\.env\("HYPRCURSOR_THEME", ".*?"\)',
                lambda _: f"hl.env(\"HYPRCURSOR_THEME\", {theme_literal})",
                content,
            )
            content = re.sub(
                r'hl\.env\("XCURSOR_SIZE", ".*?"\)',
                lambda _: f"hl.env(\"XCURSOR_SIZE\", {size_literal})",
                content,
            )
            content = re.sub(
                r'hl\.env\("HYPRCURSOR_SIZE", ".*?"\)',
                lambda _: f"hl.env(\"HYPRCURSOR_SIZE\", {size_literal})",
                content,
            )
            envs_lua.write_text(content, encoding="utf-8")
        except Exception as exc:
            print(f"Warning: Failed to update envs.lua: {exc}", file=sys.stderr)

    # 4. Apply via hyprctl (runtime)
    subprocess.run(["hyprctl", "setcursor", theme_name, size], capture_output=True)


def main():
    if len(sys.argv) < 3:
        print("Usage: apply_cursor.py <ThemeName> <Size>")
        sys.exit(1)

    try:
        apply_cursor(sys.argv[1], sys.argv[2])
    except components.ComponentError as exc:
        print(f"error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
