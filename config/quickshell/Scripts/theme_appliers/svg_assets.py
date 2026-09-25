import os
import re

from color_utils import sanitize_color


def apply(home, colors):
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]

    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    assets_dir = os.path.join(os.path.dirname(script_dir), "assets")
    if not os.path.exists(assets_dir):
        assets_dir = os.path.join(home, ".config", "quickshell", "assets")

    if os.path.exists(assets_dir):
        for svg_file in [
            "settings-icon.svg",
            "keybinds-icon.svg",
            "packagemanager-icon.svg",
        ]:
            svg_path = os.path.join(assets_dir, svg_file)
            if not os.path.exists(svg_path):
                continue
            with open(svg_path, "r") as f2:
                content = f2.read()

            new_content = re.sub(
                r'(<stop\s+offset="0%"\s+stop-color=")[^"]+(")',
                f"\\g<1>{sanitize_color(accent)}\\g<2>",
                content,
            )
            new_content = re.sub(
                r'(<stop\s+offset="100%"\s+stop-color=")[^"]+(")',
                f"\\g<1>{sanitize_color(accentComplementary)}\\g<2>",
                new_content,
            )

            if content != new_content:
                with open(svg_path, "w") as f2:
                    f2.write(new_content)
