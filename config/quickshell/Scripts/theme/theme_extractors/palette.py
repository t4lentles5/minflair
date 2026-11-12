from color_utils import force_hsl, get_chroma, hue_distance, rgb_to_hsl

# A wallpaper with several distinct colourful regions can offer more than one
# accent. The limits keep the picker short and stop near-identical shades from
# filling it with what looks like the same colour.
MAX_VARIANTS = 5
MIN_VARIANT_CHROMA = 0.10
MIN_VARIANT_SHARE = 0.005
MIN_HUE_SEPARATION = 25.0

_HUE_BUCKETS = [
    (0.0, "Red"),
    (15.0, "Orange"),
    (45.0, "Amber"),
    (70.0, "Lime"),
    (90.0, "Green"),
    (150.0, "Teal"),
    (180.0, "Cyan"),
    (200.0, "Azure"),
    (225.0, "Blue"),
    (260.0, "Violet"),
    (290.0, "Magenta"),
    (320.0, "Rose"),
    (345.0, "Red"),
]


def _hue_label(hue):
    hue = hue % 360.0
    label = _HUE_BUCKETS[0][1]
    for start, name in _HUE_BUCKETS:
        if hue >= start:
            label = name
        else:
            break
    return label


def _complementary(accent):
    h_acc, s_acc, l_acc = rgb_to_hsl(
        int(accent[1:3], 16), int(accent[3:5], 16), int(accent[5:7], 16)
    )
    return force_hsl((h_acc + 45) % 360, s_acc, l_acc, s_acc, l_acc)


def _build_variant(
    label, accent_dark, accent_light, bg_dark, bg_light, fg_dark, fg_light
):
    dark = {
        "name": "Wallpaper Theme",
        "generateFromWallpaper": True,
        "bg": bg_dark,
        "fg": fg_dark,
        "accent": accent_dark,
        "accentComplementary": _complementary(accent_dark),
    }
    light = {
        "name": "Wallpaper Theme Light",
        "generateFromWallpaper": True,
        "bg": bg_light,
        "fg": fg_light,
        "accent": accent_light,
        "accentComplementary": _complementary(accent_light),
    }
    return {
        "label": label,
        "accent": accent_dark,
        "dark": dark,
        "light": light,
    }


def generate_palettes(histogram_colors):
    """Build every palette the wallpaper can offer.

    The first variant is the one the generator has always produced. The extra
    variants only change the accent (and its complementary colour), so the
    background, foreground and their contrast stay stable while the user picks
    which dominant colour drives the theme.
    """
    sorted_hist = sorted(histogram_colors.items(), key=lambda x: x[1], reverse=True)
    unique_hex = [c[0] for c in sorted_hist]

    color_objs = []
    for hex_c in unique_hex:
        r = int(hex_c[1:3], 16)
        g = int(hex_c[3:5], 16)
        b = int(hex_c[5:7], 16)
        h, s, l = rgb_to_hsl(r, g, b)
        pixels = histogram_colors[hex_c]
        color_objs.append(
            {
                "hex": hex_c,
                "r": r,
                "g": g,
                "b": b,
                "h": h,
                "s": s,
                "l": l,
                "pixels": pixels,
            }
        )

    if not color_objs:
        return []

    bg_color = color_objs[0]

    total_colorful_px = 0
    total_px = 0
    best_tint_hue = 0.0
    max_tint_chroma = -1.0
    total_px_count = sum(histogram_colors.values())

    for hex_c, count in histogram_colors.items():
        hr, hg, hb = int(hex_c[1:3], 16), int(hex_c[3:5], 16), int(hex_c[5:7], 16)
        h, s, l = rgb_to_hsl(hr, hg, hb)
        hchroma = (max(hr, hg, hb) - min(hr, hg, hb)) / 255.0

        if (
            l > 0.20
            and l < 0.90
            and hchroma < 0.15
            and (count / total_px_count) > 0.005
        ):
            if hchroma > max_tint_chroma:
                max_tint_chroma = hchroma
                best_tint_hue = h

        if hchroma >= 0.08:
            total_colorful_px += count
        total_px += count

    colorful_ratio = total_colorful_px / total_px if total_px > 0 else 0.0
    is_grayscale_image = colorful_ratio < 0.05

    colorful_candidates = [c for c in color_objs if get_chroma(c) >= 0.08]
    if is_grayscale_image:
        dominant_hue = best_tint_hue
        dominant_sat = 0.15
    elif colorful_candidates:
        dominant_cand = max(colorful_candidates, key=lambda c: c["pixels"])
        dominant_hue = dominant_cand["h"]
        dominant_sat = dominant_cand["s"]
    else:
        dominant_hue = best_tint_hue
        dominant_sat = 0.15

    bg_s = max(0.10, min(0.20, dominant_sat * 0.5))
    bg_val_dark = force_hsl(dominant_hue, bg_s, bg_color["l"], bg_s, 0.04)
    bg_val_light = force_hsl(dominant_hue, bg_s, bg_color["l"], bg_s, 0.92)

    top_colors = color_objs[:10]
    colorful_top = [c for c in top_colors if get_chroma(c) >= 0.08]
    if colorful_top and not is_grayscale_image:
        primary_accent = max(colorful_top, key=get_chroma)
    else:
        primary_accent = top_colors[0]

    is_grayscale_theme = (get_chroma(primary_accent) < 0.08) or is_grayscale_image

    if is_grayscale_theme:
        if max_tint_chroma > 0.01:
            accent_color_dark = force_hsl(dominant_hue, 0.40, 0.0, 0.40, 0.80)
            accent_color_light = force_hsl(dominant_hue, 0.40, 0.0, 0.40, 0.40)
        else:
            accent_color_dark = force_hsl(0, 0.0, 0.0, 0.0, 0.95)
            accent_color_light = force_hsl(0, 0.0, 0.0, 0.0, 0.05)
        accent_label = "Neutral"
    else:
        accent_color_dark = force_hsl(
            primary_accent["h"], primary_accent["s"], primary_accent["l"], 0.50, 0.60
        )
        accent_color_light = force_hsl(
            primary_accent["h"], primary_accent["s"], primary_accent["l"], 0.50, 0.45
        )
        accent_label = _hue_label(primary_accent["h"])

    fg_val_dark = force_hsl(dominant_hue, bg_s, 0.5, bg_s * 0.15, 0.95)
    fg_val_light = force_hsl(dominant_hue, bg_s, 0.5, bg_s * 0.15, 0.16)

    variants = [
        _build_variant(
            accent_label,
            accent_color_dark,
            accent_color_light,
            bg_val_dark,
            bg_val_light,
            fg_val_dark,
            fg_val_light,
        )
    ]

    if is_grayscale_theme:
        return variants

    selected_hues = [primary_accent["h"]]
    for color in color_objs:
        if len(variants) >= MAX_VARIANTS:
            break
        if get_chroma(color) < MIN_VARIANT_CHROMA:
            continue
        share = color["pixels"] / total_px_count if total_px_count > 0 else 0.0
        if share < MIN_VARIANT_SHARE:
            continue
        if any(
            hue_distance(color["h"], hue) < MIN_HUE_SEPARATION
            for hue in selected_hues
        ):
            continue

        candidate_dark = force_hsl(color["h"], color["s"], color["l"], 0.50, 0.60)
        candidate_light = force_hsl(color["h"], color["s"], color["l"], 0.50, 0.45)
        variants.append(
            _build_variant(
                _hue_label(color["h"]),
                candidate_dark,
                candidate_light,
                bg_val_dark,
                bg_val_light,
                fg_val_dark,
                fg_val_light,
            )
        )
        selected_hues.append(color["h"])

    return variants


def generate_palette(histogram_colors):
    """Backwards-compatible wrapper returning the default dark/light pair."""
    variants = generate_palettes(histogram_colors)
    if not variants:
        return None, None
    return variants[0]["dark"], variants[0]["light"]
