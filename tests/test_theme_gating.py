import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "config" / "quickshell" / "Scripts"
THEME_DIR = SCRIPTS_DIR / "theme"
MANIFEST = REPO_ROOT / "config" / "quickshell" / "components.tsv"

sys.path.insert(0, str(SCRIPTS_DIR))
sys.path.insert(0, str(THEME_DIR))

import apply_cursor
import apply_font
import apply_theme
import minflair_components as components


def recorder(calls, name):
    def record(home, colors):
        calls.append(name)

    return record


class ThemeGatingTests(unittest.TestCase):
    def test_only_enabled_appliers_are_called(self):
        calls = []
        appliers = {
            "kitty": recorder(calls, "kitty"),
            "nvim": recorder(calls, "nvim"),
        }
        with mock.patch.object(apply_theme, "APPLIERS", appliers):
            apply_theme.apply_appliers(
                Path("/tmp"), {}, is_enabled=lambda cid: cid == "kitty"
            )
        self.assertEqual(calls, ["kitty"])

    def test_all_appliers_disabled(self):
        calls = []
        appliers = {
            "kitty": recorder(calls, "kitty"),
            "nvim": recorder(calls, "nvim"),
        }
        with mock.patch.object(apply_theme, "APPLIERS", appliers):
            apply_theme.apply_appliers(
                Path("/tmp"), {}, is_enabled=lambda _cid: False
            )
        self.assertEqual(calls, [])

    def test_appliers_are_mapped_in_the_manifest(self):
        manifest = components.load_manifest(MANIFEST)
        mapped = {
            applier
            for component in manifest.values()
            for applier in component.theme
        }
        self.assertTrue(set(apply_theme.APPLIERS).issubset(mapped))


class CursorThemeNameTests(unittest.TestCase):
    """The theme name comes from the saved settings and is written into
    envs.lua, so it has to be escaped or it breaks the file."""

    def test_a_plain_name_is_unchanged(self):
        self.assertEqual(apply_cursor.lua_string("Bibata"), '"Bibata"')

    def test_a_backslash_is_escaped(self):
        self.assertEqual(apply_cursor.lua_string(r"Bibata\Modern"), r'"Bibata\\Modern"')

    def test_a_quote_is_escaped(self):
        self.assertEqual(apply_cursor.lua_string('Bibata"Modern'), r'"Bibata\"Modern"')

    def test_a_newline_is_escaped(self):
        self.assertEqual(apply_cursor.lua_string("a\nb"), r'"a\nb"')

    def test_the_escaped_value_is_never_multiline(self):
        for value in ["a\nb", "a\rb", 'a"b', r"a\b"]:
            self.assertNotIn("\n", apply_cursor.lua_string(value))
            self.assertNotIn("\r", apply_cursor.lua_string(value))

    def test_envs_lua_survives_a_hostile_theme_name(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            hypr = home / ".config" / "hypr"
            hypr.mkdir(parents=True)
            envs = hypr / "envs.lua"
            envs.write_text(
                'hl.env("XCURSOR_THEME", "Old")\n'
                'hl.env("HYPRCURSOR_THEME", "Old")\n'
                'hl.env("XCURSOR_SIZE", "24")\n'
                'hl.env("HYPRCURSOR_SIZE", "24")\n',
                encoding="utf-8",
            )

            with mock.patch.object(apply_cursor.subprocess, "run"):
                apply_cursor.apply_cursor(
                    r'Bad"Name\With', 32, home=home, is_enabled=lambda _cid: True
                )

            content = envs.read_text(encoding="utf-8")
            # Every line still holds a single, complete Lua call. The quotes
            # are counted ignoring the escaped ones, so an unescaped quote
            # in the theme name is caught.
            for line in content.strip().splitlines():
                self.assertTrue(line.startswith("hl.env("), line)
                self.assertTrue(line.endswith(")"), line)
                unescaped = line.replace('\\"', "").replace("\\\\", "")
                self.assertEqual(unescaped.count('"') % 2, 0, line)
            self.assertIn(r'Bad\"Name\\With', content)


class FontGatingTests(unittest.TestCase):
    def _patch_updates(self):
        return mock.patch.multiple(
            apply_font,
            update_gtk=mock.DEFAULT,
            update_qt=mock.DEFAULT,
            update_hyprland=mock.DEFAULT,
            update_kitty=mock.DEFAULT,
            update_sddm=mock.DEFAULT,
            update_quickshell=mock.DEFAULT,
        )

    def test_font_sync_disabled_only_updates_shell(self):
        home = Path("/tmp/home")
        with self._patch_updates() as mocks:
            apply_font.apply_font(
                "Geist",
                "10",
                home=home,
                is_enabled=lambda cid: cid != "font-sync",
            )
        mocks["update_quickshell"].assert_called_once_with(home, "Geist")
        for name in (
            "update_gtk",
            "update_qt",
            "update_hyprland",
            "update_kitty",
            "update_sddm",
        ):
            mocks[name].assert_not_called()

    def test_disabled_app_is_not_updated(self):
        home = Path("/tmp/home")
        with self._patch_updates() as mocks:
            apply_font.apply_font(
                "Geist",
                "10",
                home=home,
                is_enabled=lambda cid: cid in {"font-sync", "gtk"},
            )
        mocks["update_gtk"].assert_called_once_with(home, "Geist 10")
        mocks["update_kitty"].assert_not_called()
        mocks["update_qt"].assert_not_called()
        mocks["update_quickshell"].assert_called_once_with(home, "Geist")

    def test_all_enabled_updates_every_target(self):
        home = Path("/tmp/home")
        with self._patch_updates() as mocks:
            apply_font.apply_font(
                "Geist", "10", home=home, is_enabled=lambda _cid: True
            )
        mocks["update_gtk"].assert_called_once_with(home, "Geist 10")
        mocks["update_qt"].assert_called_once_with(home, "Geist", "10")
        mocks["update_hyprland"].assert_called_once_with("Geist", "10")
        mocks["update_kitty"].assert_called_once_with(home, "10")
        mocks["update_sddm"].assert_called_once_with("Geist")
        mocks["update_quickshell"].assert_called_once_with(home, "Geist")


class CursorGatingTests(unittest.TestCase):
    def test_disabled_cursor_does_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            with mock.patch.object(apply_cursor.subprocess, "run") as run:
                apply_cursor.apply_cursor(
                    "Bibata", "24", home=home, is_enabled=lambda _cid: False
                )
            run.assert_not_called()
            self.assertFalse((home / ".icons").exists())

    def test_enabled_cursor_updates_settings(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            with mock.patch.object(apply_cursor.subprocess, "run") as run:
                apply_cursor.apply_cursor(
                    "Bibata",
                    "24",
                    home=home,
                    is_enabled=lambda cid: cid == "cursor",
                )
            self.assertTrue(
                (home / ".icons" / "default" / "index.theme").is_file()
            )
            self.assertGreaterEqual(run.call_count, 3)


class SddmCacheGatingTests(unittest.TestCase):
    def test_sddm_cache_writes_are_gated_in_qml(self):
        for relative in (
            "config/quickshell/Core/Services/WallpaperManager.qml",
            "config/quickshell/Core/Services/SettingsService.qml",
        ):
            text = (REPO_ROOT / relative).read_text(encoding="utf-8")
            self.assertIn(
                'grep -qxF sddm \\"$HOME/.config/minflair/preferences.conf\\"',
                text,
                f"{relative} does not check the sddm preference",
            )


if __name__ == "__main__":
    unittest.main()
