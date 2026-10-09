import os

from color_utils import sanitize_color


def apply(home, colors):
    bg = colors["bg"]
    fg = colors["fg"]
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]
    bgSecondary = colors["bgSecondary"]
    bgTertiary = colors.get("bgTertiary", bgSecondary)
    bgAccent = colors.get("bgAccent", accent)
    bgAccentComplementary = colors.get("bgAccentComplementary", accentComplementary)
    muted = colors["muted"]
    border = colors["border"]

    starship_file = os.path.join(home, ".config", "starship", "starship.toml")
    os.makedirs(os.path.dirname(starship_file), exist_ok=True)
    if not os.path.exists(starship_file):
        open(starship_file, "a").close()

    toml = f"""# --- Quickshell Palette ---
[palettes.quickshell]
bg = "{sanitize_color(bg)}"
fg = "{sanitize_color(fg)}"
accent = "{sanitize_color(accent)}"
accentComplementary = "{sanitize_color(accentComplementary)}"
"""
    os.system(f"sed -i '/# --- Quickshell Palette ---/,$d' '{starship_file}'")
    with open(starship_file, "a") as f2:
        f2.write(toml)
