import os

from color_utils import sanitize_color


def apply(home, colors):
    fg = colors["fg"]
    bg = colors["bg"]
    bgSecondary = colors["bgSecondary"]
    accent = colors["accent"]
    accentComplementary = colors["accentComplementary"]
    border = colors["border"]

    lazygit_file = os.path.join(home, ".config", "lazygit", "config.yml")
    os.makedirs(os.path.dirname(lazygit_file), exist_ok=True)
    if not os.path.exists(lazygit_file):
        open(lazygit_file, "a").close()

    lg_theme = f"""# --- Quickshell Palette ---
gui:
  border: 'rounded'
  nerdFontsVersion: "3"
  theme:
    activeBorderColor:
      - '{sanitize_color(accent)}'
      - 'bold'
    inactiveBorderColor:
      - '{sanitize_color(border)}'
    optionsTextColor:
      - '{sanitize_color(accent)}'
    selectedLineBgColor:
      - '{sanitize_color(bgSecondary)}'
    cherryPickedCommitBgColor:
      - '{sanitize_color(accent)}'
    cherryPickedCommitFgColor:
      - '{sanitize_color(bg)}'
    unstagedChangesColor:
      - '{sanitize_color(accentComplementary)}'
    defaultFgColor:
      - '{sanitize_color(fg)}'
"""
    os.system(f"sed -i '/# --- Quickshell Palette ---/,$d' '{lazygit_file}'")
    with open(lazygit_file, "a") as f2:
        f2.write(lg_theme)
