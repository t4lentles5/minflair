import contextlib
import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[1]
THEME_DIR = REPO_ROOT / "config" / "quickshell" / "Scripts" / "theme"

sys.path.insert(0, str(THEME_DIR))

import generate_theme
from theme_extractors import palette


COLORFUL_HISTOGRAM = {
    "#222222": 600,
    "#ff0000": 100,
    "#00ff00": 90,
    "#0000ff": 80,
}


class PaletteVariantTests(unittest.TestCase):
    def test_colorful_wallpaper_offers_several_accents(self):
        variants = palette.generate_palettes(COLORFUL_HISTOGRAM)

        self.assertEqual(len(variants), 3)
        self.assertEqual(variants[0]["label"], "Red")
        self.assertEqual(
            {variant["label"] for variant in variants},
            {"Red", "Green", "Blue"},
        )
        self.assertEqual(
            len({variant["dark"]["accent"] for variant in variants}),
            3,
        )

    def test_variants_share_background_and_foreground(self):
        variants = palette.generate_palettes(COLORFUL_HISTOGRAM)

        self.assertEqual(len({variant["dark"]["bg"] for variant in variants}), 1)
        self.assertEqual(len({variant["dark"]["fg"] for variant in variants}), 1)
        self.assertEqual(len({variant["light"]["bg"] for variant in variants}), 1)
        self.assertEqual(len({variant["light"]["fg"] for variant in variants}), 1)

    def test_default_variant_matches_legacy_palette(self):
        dark, light = palette.generate_palette(COLORFUL_HISTOGRAM)
        variants = palette.generate_palettes(COLORFUL_HISTOGRAM)

        self.assertEqual(dark, variants[0]["dark"])
        self.assertEqual(light, variants[0]["light"])

    def test_every_variant_has_the_expected_scheme_fields(self):
        for variant in palette.generate_palettes(COLORFUL_HISTOGRAM):
            self.assertTrue(variant["label"])
            self.assertTrue(variant["accent"].startswith("#"))
            for side in ("dark", "light"):
                scheme = variant[side]
                for key in (
                    "name",
                    "generateFromWallpaper",
                    "bg",
                    "fg",
                    "accent",
                    "accentComplementary",
                ):
                    self.assertIn(key, scheme)

    def test_grayscale_wallpaper_offers_one_variant(self):
        variants = palette.generate_palettes(
            {"#111111": 500, "#888888": 300, "#eeeeee": 200}
        )

        self.assertEqual(len(variants), 1)
        self.assertEqual(variants[0]["label"], "Neutral")

    def test_similar_hues_are_grouped(self):
        variants = palette.generate_palettes(
            {
                "#222222": 600,
                "#ff0000": 100,
                "#ee1111": 90,
                "#dd2222": 80,
            }
        )

        self.assertEqual(len(variants), 1)

    def test_variant_count_is_capped(self):
        variants = palette.generate_palettes(
            {
                "#222222": 600,
                "#ff0000": 100,
                "#ff8800": 90,
                "#ffff00": 80,
                "#00ff00": 70,
                "#00ffff": 60,
                "#0000ff": 50,
            }
        )

        self.assertEqual(len(variants), palette.MAX_VARIANTS)


class SelectVariantTests(unittest.TestCase):
    def state(self):
        return {
            "source": "/tmp/wall.jpg",
            "selected": 0,
            "variants": [
                {
                    "label": "Red",
                    "accent": "#ff3333",
                    "dark": {"accent": "#ff3333"},
                    "light": {"accent": "#cc0000"},
                },
                {
                    "label": "Blue",
                    "accent": "#3333ff",
                    "dark": {"accent": "#3333ff"},
                    "light": {"accent": "#0000cc"},
                },
            ],
        }

    def test_select_variant_updates_state_and_cached_schemes(self):
        with tempfile.TemporaryDirectory() as tmp:
            generate_theme.write_json(generate_theme.variants_path(tmp), self.state())

            selected = generate_theme.select_variant(tmp, 1)

            self.assertEqual(selected, 1)
            self.assertEqual(
                generate_theme.load_variant_state(tmp)["selected"],
                1,
            )

            dark_path = os.path.join(tmp, "wallpaper_colorscheme_dark.json")
            light_path = os.path.join(tmp, "wallpaper_colorscheme_light.json")
            with open(dark_path, "r") as f:
                self.assertEqual(json.load(f), {"accent": "#3333ff"})
            with open(light_path, "r") as f:
                self.assertEqual(json.load(f), {"accent": "#0000cc"})

    def test_select_variant_clamps_the_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            generate_theme.write_json(generate_theme.variants_path(tmp), self.state())

            self.assertEqual(generate_theme.select_variant(tmp, 99), 1)
            self.assertEqual(generate_theme.select_variant(tmp, -5), 0)

    def test_select_variant_without_variants_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                generate_theme.select_variant(tmp, 0)

    def test_select_mode_through_main(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            cache = home / ".cache" / "quickshell"
            cache.mkdir(parents=True)
            generate_theme.write_json(cache / "wallpaper_variants.json", self.state())

            with mock.patch.dict(os.environ, {"HOME": str(home)}):
                with mock.patch.object(
                    sys, "argv", ["generate_theme.py", "--select", "1"]
                ):
                    generate_theme.main()

            with open(cache / "wallpaper_variants.json", "r") as f:
                self.assertEqual(json.load(f)["selected"], 1)


class GenerateThemeTests(unittest.TestCase):
    def test_main_writes_variants_and_colors_payload(self):
        with tempfile.TemporaryDirectory() as tmp:
            image = Path(tmp) / "wall.jpg"
            image.write_bytes(b"fake image")
            home = Path(tmp) / "home"
            cache = home / ".cache" / "quickshell"
            cache.mkdir(parents=True)
            with open(cache / "colorscheme.json", "w") as f:
                json.dump(
                    {"generateFromWallpaper": True, "wallpaperIsDark": True}, f
                )

            output = io.StringIO()
            with mock.patch.dict(os.environ, {"HOME": str(home)}):
                with mock.patch.object(
                    generate_theme,
                    "prepare_image",
                    return_value=(str(image), str(image)),
                ):
                    with mock.patch.object(
                        generate_theme, "get_brightness", return_value=0.2
                    ):
                        with mock.patch.object(
                            generate_theme,
                            "extract_histogram_colors",
                            return_value=COLORFUL_HISTOGRAM,
                        ):
                            with mock.patch.object(
                                sys,
                                "argv",
                                ["generate_theme.py", str(image), "True"],
                            ):
                                with contextlib.redirect_stdout(output):
                                    generate_theme.main()

            payload = json.loads(output.getvalue().split("COLORS:", 1)[1].strip())
            self.assertEqual(payload["selected"], 0)
            self.assertEqual(payload["activeIsDark"], True)
            self.assertEqual(len(payload["variants"]), 3)
            self.assertEqual(payload["dark"], payload["variants"][0]["dark"])

            with open(cache / "wallpaper_variants.json", "r") as f:
                state = json.load(f)
            self.assertEqual(state["source"], str(image))
            self.assertEqual(state["selected"], 0)
            self.assertEqual(len(state["variants"]), 3)
            self.assertTrue((cache / "wallpaper_colorscheme_dark.json").exists())
            self.assertTrue((cache / "wallpaper_colorscheme_light.json").exists())
            self.assertTrue((cache / "wallpaper_colorscheme.json").exists())
            self.assertTrue((cache / "colorscheme.json").exists())

    def test_generation_keeps_the_choice_for_the_same_wallpaper(self):
        with tempfile.TemporaryDirectory() as tmp:
            image = Path(tmp) / "wall.jpg"
            image.write_bytes(b"fake image")
            home = Path(tmp) / "home"
            cache = home / ".cache" / "quickshell"
            cache.mkdir(parents=True)

            generate_theme.write_json(
                cache / "wallpaper_variants.json",
                {
                    "source": str(image),
                    "selected": 2,
                    "variants": [],
                },
            )

            output = io.StringIO()
            with mock.patch.dict(os.environ, {"HOME": str(home)}):
                with mock.patch.object(
                    generate_theme,
                    "prepare_image",
                    return_value=(str(image), str(image)),
                ):
                    with mock.patch.object(
                        generate_theme, "get_brightness", return_value=0.2
                    ):
                        with mock.patch.object(
                            generate_theme,
                            "extract_histogram_colors",
                            return_value=COLORFUL_HISTOGRAM,
                        ):
                            with mock.patch.object(
                                sys,
                                "argv",
                                ["generate_theme.py", str(image), "True"],
                            ):
                                with contextlib.redirect_stdout(output):
                                    generate_theme.main()

            payload = json.loads(output.getvalue().split("COLORS:", 1)[1].strip())
            self.assertEqual(payload["selected"], 2)
            self.assertEqual(payload["dark"], payload["variants"][2]["dark"])

    def test_generation_resets_the_choice_for_a_new_wallpaper(self):
        with tempfile.TemporaryDirectory() as tmp:
            image = Path(tmp) / "other.jpg"
            image.write_bytes(b"fake image")
            home = Path(tmp) / "home"
            cache = home / ".cache" / "quickshell"
            cache.mkdir(parents=True)

            generate_theme.write_json(
                cache / "wallpaper_variants.json",
                {
                    "source": "/tmp/previous.jpg",
                    "selected": 2,
                    "variants": [],
                },
            )

            output = io.StringIO()
            with mock.patch.dict(os.environ, {"HOME": str(home)}):
                with mock.patch.object(
                    generate_theme,
                    "prepare_image",
                    return_value=(str(image), str(image)),
                ):
                    with mock.patch.object(
                        generate_theme, "get_brightness", return_value=0.2
                    ):
                        with mock.patch.object(
                            generate_theme,
                            "extract_histogram_colors",
                            return_value=COLORFUL_HISTOGRAM,
                        ):
                            with mock.patch.object(
                                sys,
                                "argv",
                                ["generate_theme.py", str(image), "True"],
                            ):
                                with contextlib.redirect_stdout(output):
                                    generate_theme.main()

            payload = json.loads(output.getvalue().split("COLORS:", 1)[1].strip())
            self.assertEqual(payload["selected"], 0)


if __name__ == "__main__":
    unittest.main()
