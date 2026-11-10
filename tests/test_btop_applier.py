import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "config" / "quickshell" / "Scripts"
THEME_DIR = SCRIPTS_DIR / "theme"

sys.path.insert(0, str(SCRIPTS_DIR))
sys.path.insert(0, str(THEME_DIR))

from theme_appliers import btop

COLORS = {
    "bg": "#101010",
    "fg": "#eeeeee",
    "bgSecondary": "#181818",
    "bgTertiary": "#202020",
    "bgAccent": "#2a2a2a",
    "accent": "#b7c5e0",
    "accentComplementary": "#f57eb6",
    "muted": "#888888",
    "border": "#333333",
}


class BtopApplierTests(unittest.TestCase):
    def test_creates_the_theme_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            btop.apply(str(home), COLORS)

            theme = home / ".config" / "btop" / "themes" / "quickshell.theme"
            self.assertTrue(theme.is_file())
            self.assertIn('theme[main_bg]="#101010"', theme.read_text(encoding="utf-8"))

    def test_selects_the_theme_when_btop_conf_is_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            btop.apply(str(home), COLORS)

            conf = (home / ".config" / "btop" / "btop.conf").read_text(
                encoding="utf-8"
            )
            self.assertIn('color_theme = "quickshell"', conf)

    def test_updates_an_existing_btop_conf(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            conf_path = home / ".config" / "btop" / "btop.conf"
            conf_path.parent.mkdir(parents=True)
            conf_path.write_text(
                'color_theme = "Default"\nupdate_ms = 2000\n', encoding="utf-8"
            )

            btop.apply(str(home), COLORS)

            conf = conf_path.read_text(encoding="utf-8")
            self.assertIn('color_theme = "quickshell"', conf)
            self.assertIn("update_ms = 2000", conf)


if __name__ == "__main__":
    unittest.main()
