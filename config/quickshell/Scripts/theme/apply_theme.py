#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
import os

from color_utils import blend_hex, get_brightness, resolve_color, sanitize_color
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

    bg = sanitize_color(data.get("bg", "#000000"))
    opaqueBg = sanitize_color(data.get("opaqueBg", bg))
    fg = sanitize_color(data.get("fg", "#ffffff"))
    accent = sanitize_color(data.get("accent", "#a77ef5"))
    accentComplementary = sanitize_color(data.get("accentComplementary", "#f57eb6"))
    shadow = sanitize_color(data.get("shadow", "#000000"))

    brightness = get_brightness(bg)
    is_dark = brightness <= 0.5

    # Derive overlayBase and all alpha/blended surfaces
    overlay_fallback = blend_hex(accent, fg, 0.7 if is_dark else 1.0)
    overlayBase = resolve_color(data.get("overlayBase"), bg, fallback=overlay_fallback)

    bgSecondary = resolve_color(
        data.get("bgSecondary"),
        bg,
        fallback=blend_hex(overlayBase, bg, 0.06 if is_dark else 0.10),
    )
    bgTertiary = resolve_color(
        data.get("bgTertiary"),
        bg,
        fallback=blend_hex(overlayBase, bg, 0.02 if is_dark else 0.04),
    )
    bgAccent = resolve_color(
        data.get("bgAccent"),
        bg,
        fallback=blend_hex(accent, bg, 0.15 if is_dark else 0.30),
    )
    bgAccentComplementary = resolve_color(
        data.get("bgAccentComplementary"),
        bg,
        fallback=blend_hex(accentComplementary, bg, 0.15 if is_dark else 0.30),
    )
    muted = resolve_color(data.get("muted"), bg, fallback=blend_hex(fg, bg, 0.40))
    border = resolve_color(
        data.get("border"),
        bg,
        fallback=blend_hex(fg, bg, 0.10 if is_dark else 0.20),
    )

    colors = {
        "bg": bg,
        "opaqueBg": opaqueBg,
        "fg": fg,
        "overlayBase": overlayBase,
        "bgSecondary": bgSecondary,
        "bgTertiary": bgTertiary,
        "bgAccent": bgAccent,
        "bgAccentComplementary": bgAccentComplementary,
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
