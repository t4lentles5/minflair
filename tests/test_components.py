import io
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "config" / "quickshell" / "Scripts"
MANIFEST = REPO_ROOT / "config" / "quickshell" / "components.tsv"

sys.path.insert(0, str(SCRIPTS_DIR))

import minflair_components as components


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.manifest = components.load_manifest(MANIFEST)

    def test_ids_are_unique(self):
        self.assertEqual(len(self.manifest), 20)

    def test_core_components_are_expected(self):
        core = {c.id for c in self.manifest.values() if c.core}
        self.assertEqual(core, {"quickshell", "hyprland"})

    def test_chsh_is_folded_into_zsh(self):
        self.assertNotIn("chsh", self.manifest)
        self.assertIn("login shell", self.manifest["zsh"].description.lower())

    def test_every_config_directory_is_mapped_once(self):
        mapped = {}
        for component in self.manifest.values():
            for raw_path in component.paths:
                parts = Path(raw_path).parts
                if len(parts) >= 2 and parts[0] == "config":
                    self.assertNotIn(
                        parts[1],
                        mapped,
                        f"config/{parts[1]} mapped twice",
                    )
                    mapped[parts[1]] = component.id

        config_dirs = {
            entry.name
            for entry in (REPO_ROOT / "config").iterdir()
            if entry.is_dir()
        }
        self.assertEqual(set(mapped), config_dirs)

    def test_every_theme_applier_is_mapped(self):
        appliers = {
            entry.stem
            for entry in (
                SCRIPTS_DIR / "theme" / "theme_appliers"
            ).glob("*.py")
            if entry.stem != "__init__"
        }
        mapped = {
            applier
            for component in self.manifest.values()
            for applier in component.theme
        }
        self.assertTrue(appliers.issubset(mapped))

    def test_manifest_paths_exist(self):
        for component in self.manifest.values():
            for raw_path in component.paths:
                self.assertTrue(
                    (REPO_ROOT / raw_path).exists(),
                    f"{component.id}: missing {raw_path}",
                )

    def test_validate_has_no_warnings(self):
        warnings = components.validate(
            self.manifest, repo_root=REPO_ROOT, disabled=set()
        )
        self.assertEqual(warnings, [])

    def test_malformed_row_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            manifest = Path(tmp) / "components.tsv"
            manifest.write_text(
                "\t".join(components.MANIFEST_COLUMNS) + "\n"
                "kitty\tKitty\tterminal\t0\n",
                encoding="utf-8",
            )
            with self.assertRaises(components.ComponentError):
                components.load_manifest(manifest)


class PreferenceTests(unittest.TestCase):
    def setUp(self):
        self.manifest = components.load_manifest(MANIFEST)
        self.tmp = tempfile.TemporaryDirectory()
        self.prefs = Path(self.tmp.name) / "preferences.conf"

    def tearDown(self):
        self.tmp.cleanup()

    def test_missing_preferences_enable_everything(self):
        disabled = components.load_disabled(self.prefs)
        self.assertEqual(disabled, set())
        for component in self.manifest.values():
            self.assertTrue(components.enabled(component.id, self.manifest, disabled))

    def test_disabled_component_is_not_enabled(self):
        components.write_disabled(["kitty", "nvim"], self.prefs)
        disabled = components.load_disabled(self.prefs)
        self.assertFalse(components.enabled("kitty", self.manifest, disabled))
        self.assertFalse(components.enabled("nvim", self.manifest, disabled))
        self.assertTrue(components.enabled("starship", self.manifest, disabled))

    def test_core_component_cannot_be_disabled(self):
        with self.assertRaises(components.ComponentError):
            components.write_disabled(["quickshell"], self.prefs)

    def test_core_component_stays_enabled_even_if_in_preferences(self):
        self.prefs.write_text("quickshell\n", encoding="utf-8")
        disabled = components.load_disabled(self.prefs)
        self.assertTrue(components.enabled("quickshell", self.manifest, disabled))

    def test_unknown_preference_is_ignored_by_enabled(self):
        self.prefs.write_text("does-not-exist\nkitty\n", encoding="utf-8")
        disabled = components.load_disabled(self.prefs)
        self.assertFalse(components.enabled("kitty", self.manifest, disabled))

    def test_unknown_preference_is_reported_by_validate(self):
        self.prefs.write_text("does-not-exist\n", encoding="utf-8")
        disabled = components.load_disabled(self.prefs)
        warnings = components.validate(
            self.manifest, repo_root=REPO_ROOT, disabled=disabled
        )
        self.assertTrue(any("does-not-exist" in warning for warning in warnings))

    def test_old_chsh_preference_is_reported_as_migrated(self):
        self.prefs.write_text("chsh\n", encoding="utf-8")
        disabled = components.load_disabled(self.prefs)
        warnings = components.validate(
            self.manifest, repo_root=REPO_ROOT, disabled=disabled
        )
        self.assertTrue(any("part of zsh" in warning for warning in warnings))

    def test_write_and_read_roundtrip(self):
        components.write_disabled(["kitty", "starship"], self.prefs)
        self.assertEqual(
            components.load_disabled(self.prefs), {"kitty", "starship"}
        )


class CliTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.prefs = Path(self.tmp.name) / "preferences.conf"
        self.env = mock.patch.dict(
            os.environ, {"MINFLAIR_PREFS": str(self.prefs)}
        )
        self.env.start()

    def tearDown(self):
        self.env.stop()
        self.tmp.cleanup()

    def test_enabled_exit_code_is_false_for_disabled_component(self):
        components.write_disabled(["kitty"], self.prefs)
        with redirect_stdout(io.StringIO()):
            self.assertEqual(components.main(["enabled", "kitty"]), 1)
            self.assertEqual(components.main(["enabled", "starship"]), 0)

    def test_validate_cli_succeeds_on_repository(self):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            self.assertEqual(
                components.main(["validate", "--repo-root", str(REPO_ROOT)]),
                0,
            )

    def test_disable_drops_unknown_and_core_ids_from_existing_prefs(self):
        self.prefs.write_text(
            "does-not-exist\nquickshell\n", encoding="utf-8"
        )
        with redirect_stdout(io.StringIO()):
            self.assertEqual(components.main(["disable", "kitty"]), 0)
        self.assertEqual(components.load_disabled(self.prefs), {"kitty"})


if __name__ == "__main__":
    unittest.main()
