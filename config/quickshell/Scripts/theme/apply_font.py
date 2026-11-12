#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import configparser
import json
import re
import subprocess
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import minflair_components as components


def update_gtk(home: Path, full_font: str) -> None:
    """Update the GTK font through gsettings and the GTK settings files."""
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "font-name", full_font],
        capture_output=True,
    )

    for gtk_ver in ["gtk-3.0", "gtk-4.0"]:
        ini_path = home / ".config" / gtk_ver / "settings.ini"
        if not ini_path.is_file():
            continue
        try:
            lines = ini_path.read_text(encoding="utf-8").splitlines(keepends=True)
            new_lines = []
            found = False
            for line in lines:
                if line.startswith("gtk-font-name="):
                    new_lines.append(f"gtk-font-name={full_font}\n")
                    found = True
                else:
                    new_lines.append(line)
            if not found and lines:
                new_lines.append(f"gtk-font-name={full_font}\n")
            ini_path.write_text("".join(new_lines), encoding="utf-8")
        except Exception as exc:
            print(
                f"Warning: Failed to update {ini_path}: {exc}", file=sys.stderr
            )


def update_qt(home: Path, font_name: str, font_size: str) -> None:
    """Update the Qt5/Qt6 general font."""
    for qtct in ["qt5ct", "qt6ct"]:
        qtct_conf = home / ".config" / qtct / f"{qtct}.conf"
        if not qtct_conf.is_file():
            continue
        try:
            config = configparser.ConfigParser()
            config.optionxform = str  # Preserve case
            config.read(qtct_conf, encoding="utf-8")
            if "Fonts" not in config:
                config["Fonts"] = {}

            font_str = f"{font_name},{font_size},-1,5,50,0,0,0,0,0"
            config["Fonts"]["general"] = f'"{font_str}"'
            with open(qtct_conf, "w", encoding="utf-8") as configfile:
                config.write(configfile)
        except Exception as exc:
            print(
                f"Warning: Failed to update {qtct_conf}: {exc}", file=sys.stderr
            )


def update_hyprland(font_name: str, font_size: str) -> None:
    """Update the Hyprland groupbar font."""
    update_script = Path(__file__).resolve().parent / "update_hypr_prefs.py"
    if not update_script.is_file():
        return
    try:
        hypr_args = {
            "group": {
                "groupbar": {
                    "font_family": f'"{font_name}"',
                    "font_size": int(font_size),
                }
            }
        }
        subprocess.run(
            [sys.executable, str(update_script), json.dumps(hypr_args)],
            capture_output=True,
        )
        subprocess.run(["hyprctl", "reload"], capture_output=True)
    except Exception as exc:
        print(f"Warning: Failed to update Hyprland font: {exc}", file=sys.stderr)


def update_kitty(home: Path, font_size: str) -> None:
    """Update the Kitty font size and ask running instances to reload."""
    kitty_conf = home / ".config" / "kitty" / "kitty.conf"
    if not kitty_conf.is_file():
        return
    try:
        content = kitty_conf.read_text(encoding="utf-8")
        new_content = re.sub(
            r"^font_size\s+.*",
            f"font_size {font_size}",
            content,
            flags=re.MULTILINE,
        )
        kitty_conf.write_text(new_content, encoding="utf-8")
        subprocess.run(["killall", "-USR1", "kitty"], stderr=subprocess.DEVNULL)
    except Exception as exc:
        print(f"Warning: Failed to update Kitty font: {exc}", file=sys.stderr)


def update_kitty_font(home: Path, font_family: str) -> None:
    """Update the Kitty font family and ask running instances to reload.

    The family is a setting the user picks, so it is written as it is. The
    replacement is a function, because a backslash in the name would
    otherwise be treated as an escape sequence by re.sub.
    """
    kitty_conf = home / ".config" / "kitty" / "kitty.conf"
    if not kitty_conf.is_file():
        return
    try:
        # A newline would end the setting and break the file.
        family = " ".join(str(font_family).split())
        content = kitty_conf.read_text(encoding="utf-8")
        if re.search(r"^font_family\s+", content, flags=re.MULTILINE):
            new_content = re.sub(
                r"^font_family\s+.*$",
                lambda _: f"font_family {family}",
                content,
                flags=re.MULTILINE,
            )
        else:
            new_content = f"font_family {family}\n" + content
        kitty_conf.write_text(new_content, encoding="utf-8")
        subprocess.run(["killall", "-USR1", "kitty"], stderr=subprocess.DEVNULL)
    except Exception as exc:
        print(f"Warning: Failed to update the Kitty font family: {exc}", file=sys.stderr)


def update_sddm(font_name: str) -> None:
    """Update the SDDM runtime font preferences."""
    # Only the keys the login theme consumes are written, so credentials never
    # reach the world readable /var/tmp copy.
    sddm_prefs = Path("/var/tmp/sddm-theme/settings_prefs.json")
    try:
        sddm_prefs.parent.mkdir(parents=True, exist_ok=True)
        tmp_prefs = sddm_prefs.with_suffix(".tmp")
        with open(tmp_prefs, "w", encoding="utf-8") as handle:
            json.dump({"fontFamily": font_name}, handle, indent=2)
        tmp_prefs.replace(sddm_prefs)
        sddm_prefs.chmod(0o644)
    except Exception as exc:
        print(
            f"Warning: Failed to update {sddm_prefs} font: {exc}",
            file=sys.stderr,
        )


def update_quickshell(home: Path, font_name: str) -> None:
    """Update the shell's own font preference.

    This file stores a GitHub token, so it stays private to the user.
    """
    cache_prefs = home / ".cache" / "quickshell" / "settings_prefs.json"
    if not cache_prefs.is_file():
        return
    try:
        with open(cache_prefs, "r", encoding="utf-8") as handle:
            prefs_data = json.load(handle)
        prefs_data["fontFamily"] = font_name
        tmp_prefs = cache_prefs.with_suffix(".tmp")
        with open(tmp_prefs, "w", encoding="utf-8") as handle:
            json.dump(prefs_data, handle, indent=2)
        tmp_prefs.replace(cache_prefs)
        cache_prefs.chmod(0o600)
    except Exception as exc:
        print(
            f"Warning: Failed to update {cache_prefs} font: {exc}",
            file=sys.stderr,
        )


def apply_font(font_name, font_size, home=None, is_enabled=None):
    """Propagate a font change to every enabled application.

    The shell's own preference is always updated. The ``font-sync`` component
    controls propagation to external applications.
    """
    home = home or Path.home()
    if is_enabled is None:
        is_enabled = components.enabled

    if is_enabled("font-sync"):
        if is_enabled("gtk"):
            update_gtk(home, f"{font_name} {font_size}")
        if is_enabled("qt"):
            update_qt(home, font_name, font_size)
        if is_enabled("hyprland"):
            update_hyprland(font_name, font_size)
        if is_enabled("kitty"):
            update_kitty(home, font_size)
        if is_enabled("sddm"):
            update_sddm(font_name)

    update_quickshell(home, font_name)


def apply_kitty_font(kitty_font, home=None, is_enabled=None):
    """Apply the terminal font family to Kitty.

    The ``font-sync`` component controls the propagation to external
    applications and the ``kitty`` component says whether Kitty is managed
    by Minflair at all. Both have to be enabled for the font to reach
    Kitty.
    """
    home = home or Path.home()
    if is_enabled is None:
        is_enabled = components.enabled

    if is_enabled("font-sync") and is_enabled("kitty"):
        update_kitty_font(home, kitty_font)


def main():
    arguments = sys.argv[1:]

    if arguments and arguments[0] == "--kitty":
        if len(arguments) < 2:
            print("Usage: apply_font.py --kitty <FontFamily>", file=sys.stderr)
            sys.exit(1)

        try:
            apply_kitty_font(arguments[1])
        except components.ComponentError as exc:
            print(f"error: {exc}", file=sys.stderr)
            sys.exit(1)
        return

    if len(arguments) < 2:
        print("Usage: apply_font.py <FontName> <FontSize>", file=sys.stderr)
        sys.exit(1)

    try:
        apply_font(arguments[0], arguments[1])
    except components.ComponentError as exc:
        print(f"error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
