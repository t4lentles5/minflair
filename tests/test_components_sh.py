import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


class BashComponentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.prefs = self.home / "preferences.conf"

    def tearDown(self):
        self.tmp.cleanup()

    def run_bash(self, body, prefs="", manifest=None):
        self.prefs.write_text(prefs, encoding="utf-8")
        env = os.environ.copy()
        env["HOME"] = str(self.home)
        env["MINFLAIR_PREFS"] = str(self.prefs)
        if manifest is not None:
            env["MINFLAIR_MANIFEST"] = str(manifest)
        script = (
            f'REPO_DIR="{REPO_ROOT}"\n'
            "source lib/components.sh\n"
            f"{body}\n"
        )
        return subprocess.run(
            ["bash", "-c", script],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )

    def test_manifest_fields_preserve_empty_columns(self):
        result = self.run_bash(
            "manifest_fields | "
            "awk -F'\\037' '$1 == \"quickshell\" { print $10 }'"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Core shell, bar and widgets")

    def test_enabled_paths_skip_disabled_components(self):
        result = self.run_bash(
            "component_paths --enabled", prefs="kitty\nnvim\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        paths = result.stdout.splitlines()
        self.assertIn("config/quickshell", paths)
        self.assertIn("config/hypr", paths)
        self.assertNotIn("config/kitty", paths)
        self.assertNotIn("config/nvim", paths)

    def test_disabled_paths_are_reported(self):
        result = self.run_bash(
            "component_paths --disabled", prefs="kitty\nnvim\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        paths = result.stdout.splitlines()
        self.assertIn("config/kitty", paths)
        self.assertIn("config/nvim", paths)
        self.assertNotIn("config/quickshell", paths)

    def test_package_filter_removes_disabled_packages(self):
        result = self.run_bash(
            "filter_package_file packages.txt", prefs="kitty\nnvim\nstarship\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        packages = result.stdout.splitlines()
        self.assertNotIn("kitty", packages)
        self.assertNotIn("neovim", packages)
        self.assertNotIn("starship", packages)
        self.assertIn("hyprland", packages)

    def test_prefs_set_only_disables_the_rest(self):
        result = self.run_bash(
            "prefs_set_only kitty zsh\nprefs_disabled_ids",
            prefs="",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        disabled = set(result.stdout.splitlines())
        self.assertNotIn("kitty", disabled)
        self.assertNotIn("zsh", disabled)
        self.assertIn("nvim", disabled)
        self.assertIn("starship", disabled)

    def test_prefs_add_and_remove(self):
        result = self.run_bash(
            "prefs_add nvim\nprefs_remove kitty\nprefs_disabled_ids",
            prefs="kitty\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(set(result.stdout.splitlines()), {"nvim"})

    def test_prefs_edit_drops_unknown_and_core_ids(self):
        result = self.run_bash(
            "prefs_add nvim\nprefs_disabled_ids",
            prefs="does-not-exist\nquickshell\nkitty\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(set(result.stdout.splitlines()), {"kitty", "nvim"})

    def test_components_summary_lists_enabled_and_skipped(self):
        result = self.run_bash(
            "components_summary", prefs="kitty\nnvim\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Enabled (18):", result.stdout)
        self.assertIn("Quickshell shell", result.stdout)
        self.assertIn("Skipped (2):", result.stdout)
        self.assertIn("Kitty terminal", result.stdout)
        self.assertIn("Skipped components keep their existing files.", result.stdout)

    def test_minflair_version_matches_the_manifest(self):
        result = self.run_bash("minflair_version")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "2.2.0")

    def test_reloads_respect_component_state(self):
        enabled = self.run_bash(
            "component_reloads --non-core", prefs=""
        )
        self.assertEqual(enabled.returncode, 0, enabled.stderr)
        self.assertIn("killall -USR1 kitty", enabled.stdout.splitlines())

        disabled = self.run_bash(
            "component_reloads --non-core", prefs="kitty\n"
        )
        self.assertEqual(disabled.returncode, 0, disabled.stderr)
        self.assertNotIn("killall -USR1 kitty", disabled.stdout.splitlines())

    def test_core_reload_is_excluded_from_non_core_mode(self):
        result = self.run_bash("component_reloads --non-core", prefs="")
        self.assertNotIn("hyprctl reload", result.stdout.splitlines())

        all_reloads = self.run_bash("component_reloads --all", prefs="")
        self.assertIn("hyprctl reload", all_reloads.stdout.splitlines())

    def test_unknown_preference_is_a_warning(self):
        result = self.run_bash("components_validate", prefs="does-not-exist\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unknown component", result.stderr)

    def test_old_chsh_preference_is_a_warning(self):
        result = self.run_bash("components_validate", prefs="chsh\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("part of zsh", result.stderr)

    def test_zsh_login_shell_dry_run_prints_chsh(self):
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        zsh = bin_dir / "zsh"
        zsh.write_text("#!/bin/sh\n", encoding="utf-8")
        zsh.chmod(0o755)
        result = self.run_bash(
            f'PATH="{bin_dir}:$PATH"\n'
            "DRY_RUN=1\n"
            "USER=test\n"
            "getent() { echo 'test:x:1000:1000::/home/test:/bin/bash'; }\n"
            "ensure_zsh_login_shell"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sudo chsh -s", result.stdout)
        self.assertIn(str(zsh), result.stdout)

    def test_zsh_login_shell_requires_zsh(self):
        result = self.run_bash(
            "PATH=/nonexistent\nensure_zsh_login_shell"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("zsh is not installed", result.stderr)

    def test_core_component_cannot_be_disabled(self):
        result = self.run_bash("validate_disable_ids quickshell")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Core component cannot be disabled", result.stderr)

    def test_malformed_manifest_is_rejected(self):
        manifest = self.home / "components.tsv"
        manifest.write_text(
            "\t".join(
                [
                    "id",
                    "label",
                    "category",
                    "core",
                    "paths",
                    "packages",
                    "theme",
                    "font",
                    "reload",
                    "description",
                ]
            )
            + "\nkitty\tKitty\tterminal\t0\n",
            encoding="utf-8",
        )
        result = self.run_bash("components_validate", manifest=manifest)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("wrong number of columns", result.stderr)


if __name__ == "__main__":
    unittest.main()
