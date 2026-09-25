#!/usr/bin/env python3
import json
import os
import sys

from theme_extractors.image_utils import prepare_image
from theme_extractors.magick_utils import extract_histogram_colors, get_brightness
from theme_extractors.palette import generate_palette


def main():
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

    generated_dark, generated_light = generate_palette(histogram_colors)
    if not generated_dark:
        print("Error processing colors.")
        sys.exit(1)

    home = os.path.expanduser("~")
    cache_dir = os.path.join(home, ".cache", "quickshell")
    os.makedirs(cache_dir, exist_ok=True)

    wallpaper_file_dark = os.path.join(cache_dir, "wallpaper_colorscheme_dark.json")
    with open(wallpaper_file_dark, "w") as f:
        json.dump(generated_dark, f, indent=2)

    wallpaper_file_light = os.path.join(cache_dir, "wallpaper_colorscheme_light.json")
    with open(wallpaper_file_light, "w") as f:
        json.dump(generated_light, f, indent=2)

    active_file = os.path.join(cache_dir, "colorscheme.json")
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

    wallpaper_file = os.path.join(cache_dir, "wallpaper_colorscheme.json")
    with open(wallpaper_file, "w") as f:
        json.dump(active_generated, f, indent=2)

    if should_write_active:
        with open(active_file, "w") as f:
            json.dump(active_generated, f, indent=2)
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
            }
        )
    )


if __name__ == "__main__":
    main()
