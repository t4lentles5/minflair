#!/usr/bin/env python3
import json
import os
import sys

from color_utils import blend_hex, get_brightness
from theme_appliers import (
    btop,
    gtk,
    hyprland,
    kitty,
    lazygit,
    nvim,
    qt,
    starship,
    svg_assets,
)


def main():
    home = os.environ.get("HOME", "")
    cache_file = os.path.join(home, ".cache", "quickshell", "colorscheme.json")

    if not os.path.exists(cache_file):
        print("Colorscheme cache not found.")
        return

    with open(cache_file, "r") as f:
        data = json.load(f)

    bg = data.get("bg", "#000000")
    fg = data.get("fg", "#ffffff")

    bgSecondary = data.get("bgSecondary", blend_hex(fg, bg, 0.05))
    if len(str(bgSecondary)) > 7:
        bgSecondary = blend_hex(fg, bg, 0.05)

    muted = data.get("muted", blend_hex(fg, bg, 0.65))
    if len(str(muted)) > 7:
        muted = blend_hex(fg, bg, 0.65)

    border = data.get("border", blend_hex(fg, bg, 0.15))
    if len(str(border)) > 7:
        border = blend_hex(fg, bg, 0.15)

    accent = data.get("accent", "#a77ef5")
    accentComplementary = data.get("accentComplementary", "#f57eb6")
    shadow = data.get("shadow", "#000000")

    brightness = get_brightness(bg)
    is_dark = brightness <= 0.5

    colors = {
        "bg": bg,
        "fg": fg,
        "bgSecondary": bgSecondary,
        "muted": muted,
        "border": border,
        "accent": accent,
        "accentComplementary": accentComplementary,
        "shadow": shadow,
        "is_dark": is_dark,
    }

    kitty.apply(home, colors)
    gtk.apply(home, colors)
    nvim.apply(home, colors)
    hyprland.apply(home, colors)
    starship.apply(home, colors)
    qt.apply(home, colors)
    btop.apply(home, colors)
    svg_assets.apply(home, colors)
    lazygit.apply(home, colors)


if __name__ == "__main__":
    main()
