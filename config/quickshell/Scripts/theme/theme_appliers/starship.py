import os

from color_utils import sanitize_color


def apply(home, colors):
    bg = colors["bg"]
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]

    starship_file = os.path.join(home, ".config", "starship", "starship.toml")
    os.makedirs(os.path.dirname(starship_file), exist_ok=True)
    if not os.path.exists(starship_file):
        open(starship_file, "a").close()

    toml = f"""# --- Quickshell Palette ---
[palettes.quickshell]
bg = "{sanitize_color(bg)}"
accent = "{sanitize_color(accent)}"
accentcomplementary = "{sanitize_color(accentComplementary)}"
"""
    os.system(f"sed -i '/# --- Quickshell Palette ---/,$d' '{starship_file}'")
    with open(starship_file, "a") as f2:
        f2.write(toml)
