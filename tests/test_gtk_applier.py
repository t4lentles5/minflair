import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "config" / "quickshell" / "Scripts"
THEME_DIR = SCRIPTS_DIR / "theme"

sys.path.insert(0, str(SCRIPTS_DIR))
sys.path.insert(0, str(THEME_DIR))

from theme_appliers import gtk

COLORS = {
    "bg": "#101010",
    "fg": "#eeeeee",
    "bgSecondary": "#181818",
    "bgTertiary": "#202020",
    "bgAccent": "#2a2a2a",
    "bgAccentComplementary": "#302030",
    "overlayBase": "#202020",
    "accent": "#b7c5e0",
    "accentComplementary": "#f57eb6",
    "muted": "#888888",
    "border": "#333333",
    "shadow": "#000000",
    "is_dark": True,
}


class GtkApplierTests(unittest.TestCase):
    def run_applier(self, home):
        with mock.patch.object(gtk.subprocess, "run"), mock.patch.object(
            gtk.os, "system"
        ):
            gtk.apply(str(home), COLORS)

    def test_selection_uses_defined_color_names(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            self.run_applier(home)

            gtk3 = (
                home / ".themes" / "Material-Gnome" / "gtk-3.0" / "colors.css"
            ).read_text(encoding="utf-8")
            gtk4 = (
                home / ".themes" / "Material-Gnome" / "gtk-4.0" / "colors.css"
            ).read_text(encoding="utf-8")

            self.assertIn("color: @background;", gtk3)
            self.assertNotIn("color: @bg;", gtk3)
            self.assertIn("color: var(--background);", gtk4)
            self.assertNotIn("color: var(--bg);", gtk4)

    def test_missing_theme_does_not_leave_dangling_symlinks(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            self.run_applier(home)

            for relative in (
                ".config/gtk-3.0/gtk.css",
                ".config/gtk-3.0/colors.css",
                ".config/gtk-4.0/gtk.css",
                ".config/gtk-4.0/gtk-dark.css",
                ".config/gtk-4.0/colors.css",
            ):
                path = home / relative
                self.assertFalse(
                    path.is_symlink() and not path.exists(),
                    f"{relative} is a dangling symlink",
                )


if __name__ == "__main__":
    unittest.main()
