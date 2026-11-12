#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import json
import os

from theme_extractors.image_utils import prepare_image
from theme_extractors.magick_utils import extract_histogram_colors, get_brightness
from theme_extractors.palette import generate_palettes


def cache_dir():
    return os.path.join(os.path.expanduser("~"), ".cache", "quickshell")


def variants_path(directory):
    return os.path.join(directory, "wallpaper_variants.json")


def load_variant_state(directory):
    try:
        with open(variants_path(directory), "r") as f:
            data = json.load(f)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    return {}


def write_json(path, data):
    path = os.fspath(path)
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, exist_ok=True)

    tmp_path = path + ".tmp"
    with open(tmp_path, "w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp_path, path)


def select_variant(directory, index):
    """Persist the chosen variant without decoding the wallpaper again."""
    state = load_variant_state(directory)
    variants = state.get("variants") or []
    if not variants:
        raise ValueError("no wallpaper variants available")

    try:
        selected = int(index)
    except (TypeError, ValueError):
        raise ValueError(f"invalid variant index: {index}")

    selected = max(0, min(selected, len(variants) - 1))
    variant = variants[selected]
    if not isinstance(variant, dict) or "dark" not in variant or "light" not in variant:
        raise ValueError("wallpaper variant data is incomplete")

    state["selected"] = selected
    write_json(variants_path(directory), state)
    write_json(
        os.path.join(directory, "wallpaper_colorscheme_dark.json"), variant["dark"]
    )
    write_json(
        os.path.join(directory, "wallpaper_colorscheme_light.json"), variant["light"]
    )
    return selected


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "--select":
        if len(sys.argv) < 3:
            print("Usage: generate_theme.py --select <index>", file=sys.stderr)
            sys.exit(1)
        try:
            select_variant(cache_dir(), sys.argv[2])
        except Exception as e:
            print(f"Error selecting wallpaper variant: {e}", file=sys.stderr)
            sys.exit(1)
        return

    if len(sys.argv) < 2:
        print("Usage: generate_theme.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(f"Error: image not found: {image_path}")
        sys.exit(1)

    processing_path, magick_path = prepare_image(image_path)
    brightness = get_brightness(magick_path)
    is_dark = brightness <= 0.4

    histogram_colors = extract_histogram_colors(magick_path)
    if not histogram_colors:
        print("Error: ImageMagick returned no colors.")
        sys.exit(1)

    variants = generate_palettes(histogram_colors)
    if not variants:
        print("Error processing colors.")
        sys.exit(1)

    directory = cache_dir()
    state = load_variant_state(directory)
    selected = 0
    if state.get("source") == image_path:
        try:
            selected = int(state.get("selected", 0))
        except (TypeError, ValueError):
            selected = 0
    selected = max(0, min(selected, len(variants) - 1))

    active_variant = variants[selected]
    generated_dark = active_variant["dark"]
    generated_light = active_variant["light"]

    write_json(
        os.path.join(directory, "wallpaper_colorscheme_dark.json"), generated_dark
    )
    write_json(
        os.path.join(directory, "wallpaper_colorscheme_light.json"), generated_light
    )
    write_json(
        variants_path(directory),
        {"source": image_path, "selected": selected, "variants": variants},
    )

    active_file = os.path.join(directory, "colorscheme.json")
    should_write_active = True
    user_is_dark = is_dark

    if os.path.exists(active_file):
        try:
            with open(active_file, "r") as f:
                curr_data = json.load(f)
                should_write_active = curr_data.get("generateFromWallpaper", False)
                if "wallpaperIsDark" in curr_data:
                    user_is_dark = curr_data["wallpaperIsDark"]
        except Exception:
            pass

    if len(sys.argv) >= 3:
        should_write_active = sys.argv[2].lower() in ["true", "1", "yes"]

    active_generated = dict(generated_dark if user_is_dark else generated_light)
    active_generated["wallpaperIsDark"] = user_is_dark

    write_json(os.path.join(directory, "wallpaper_colorscheme.json"), active_generated)

    if should_write_active:
        write_json(active_file, active_generated)
        print("Success: Generated colorscheme.json and wallpaper variants")
    else:
        print("Success: Generated wallpaper variants (active colorscheme preserved)")

    print(
        "COLORS:"
        + json.dumps(
            {
                "dark": generated_dark,
                "light": generated_light,
                "activeIsDark": user_is_dark,
                "selected": selected,
                "variants": variants,
            }
        )
    )


if __name__ == "__main__":
    main()
