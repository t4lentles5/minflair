import re
import subprocess


def get_brightness(magick_path):
    try:
        cmd_mean = [
            "magick",
            magick_path,
            "-background",
            "black",
            "-alpha",
            "remove",
            "-colorspace",
            "gray",
            "-format",
            "%[fx:mean]",
            "info:",
        ]
        res_mean = subprocess.run(
            cmd_mean,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )
        out_clean = res_mean.stdout.strip()
        val = out_clean.split()[0] if out_clean else "0.2"
        match = re.search(r"[0-9\.]+", val)
        if match:
            return float(match.group(0))
        return 0.2
    except Exception as e:
        print("Error getting image mean, falling back to dark:", e)
        return 0.2


def extract_histogram_colors(magick_path):
    histogram_colors = {}
    try:
        cmd_magick = [
            "magick",
            magick_path,
            "-background",
            "black",
            "-alpha",
            "remove",
            "-resize",
            "100x100",
            "-colors",
            "32",
            "-format",
            "%c",
            "histogram:info:",
        ]
        res_magick = subprocess.run(
            cmd_magick,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )
        for line in res_magick.stdout.splitlines():
            m = re.search(r"(\d+):\s*\(.*?\)\s*(#[0-9a-fA-F]{6})", line)
            if m:
                count = int(m.group(1))
                hex_c = m.group(2).lower()
                histogram_colors[hex_c] = histogram_colors.get(hex_c, 0) + count
    except Exception as e:
        print("Warning: failed to extract colors from ImageMagick histogram:", e)
    return histogram_colors
