#!/usr/bin/env python3
import configparser
import json
import re
import subprocess
import sys
from pathlib import Path


def main():
    if len(sys.argv) < 3:
        print("Usage: apply_font.py <FontName> <FontSize>")
        sys.exit(1)

    font_name = sys.argv[1]
    font_size = sys.argv[2]
    home = Path.home()
    full_font = f"{font_name} {font_size}"

    # 1. Update GTK globally via gsettings
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "font-name", full_font],
        capture_output=True,
    )

    # 2. Update GTK 3 and 4 settings.ini
    for gtk_ver in ["gtk-3.0", "gtk-4.0"]:
        ini_path = home / ".config" / gtk_ver / "settings.ini"
        if ini_path.is_file():
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
            except Exception as e:
                print(f"Warning: Failed to update {ini_path}: {e}", file=sys.stderr)

    # 3. Update qt5ct and qt6ct
    for qtct in ["qt5ct", "qt6ct"]:
        qtct_conf = home / ".config" / qtct / f"{qtct}.conf"
        if qtct_conf.is_file():
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
            except Exception as e:
                print(f"Warning: Failed to update {qtct_conf}: {e}", file=sys.stderr)

    # 4. Update Hyprland groupbar font
    update_script = Path(__file__).resolve().parent / "update_hypr_prefs.py"
    if update_script.is_file():
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
        except Exception as e:
            print(f"Warning: Failed to update Hyprland font: {e}", file=sys.stderr)

    # 5. Update Kitty font size
    kitty_conf = home / ".config" / "kitty" / "kitty.conf"
    if kitty_conf.is_file():
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
        except Exception as e:
            print(f"Warning: Failed to update Kitty font: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
