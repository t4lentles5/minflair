import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


class InstallerDryRunTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.prefs = self.home / "preferences.conf"

    def tearDown(self):
        self.tmp.cleanup()

    def run_script(self, script, *args):
        env = os.environ.copy()
        env["HOME"] = str(self.home)
        env["MINFLAIR_PREFS"] = str(self.prefs)
        return subprocess.run(
            ["bash", str(REPO_ROOT / script), "--dry-run", "--no-input", *args],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )

    def test_help_lists_selection_flags(self):
        for script in ("install.sh", "update.sh"):
            result = subprocess.run(
                ["bash", str(REPO_ROOT / script), "--help"],
                cwd=REPO_ROOT,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("--exclude", result.stdout)
            self.assertIn("--only", result.stdout)
            self.assertIn("--aur-helper", result.stdout)
            self.assertIn("--dry-run", result.stdout)

    def test_install_dry_run_skips_disabled_components(self):
        result = self.run_script(
            "install.sh", "--exclude", "kitty,nvim,starship"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would copy config/quickshell", result.stdout)
        self.assertNotIn("would copy config/kitty", result.stdout)
        self.assertNotIn("would copy config/nvim", result.stdout)
        self.assertNotIn("would copy config/starship", result.stdout)

        package_line = next(
            line
            for line in result.stdout.splitlines()
            if line.startswith("[dry-run] sudo pacman")
        )
        for package in ("kitty", "neovim", "starship"):
            self.assertNotIn(f" {package} ", f" {package_line} ")
        self.assertIn(" hyprland ", f" {package_line} ")
        self.assertFalse((self.home / ".config").exists())
        self.assertFalse((self.home / ".minflair_backup").exists())
        self.assertFalse((self.home / ".dotfiles_backup").exists())

    def test_non_tty_output_is_plain_text(self):
        result = self.run_script("install.sh", "--no-packages")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Minflair installer", result.stdout)
        self.assertIn("Enabled (", result.stdout)
        self.assertNotIn("\x1b[", result.stdout)
        self.assertNotIn("\x1b[", result.stderr)
        self.assertTrue(result.stdout.isascii())
        self.assertTrue(result.stderr.isascii())

    def test_no_packages_skips_package_commands(self):
        result = self.run_script("install.sh", "--no-packages")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("pacman -S", result.stdout)
        self.assertNotIn("yay -S", result.stdout)
        self.assertNotIn("paru -S", result.stdout)
        self.assertIn("Skipping AUR helper and package installation", result.stderr)

    def test_aur_helper_flag_is_used_and_not_persisted_in_dry_run(self):
        result = self.run_script("install.sh", "--aur-helper", "paru")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would save AUR helper: paru", result.stdout)
        self.assertIn("would install paru if it is missing", result.stdout)
        self.assertIn("[dry-run] paru -S", result.stdout)
        self.assertFalse(
            (self.home / ".config" / "minflair" / "aur-helper").exists()
        )

    def test_update_requires_an_existing_install(self):
        result = self.run_script("update.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Run install.sh first", result.stderr)

    def test_update_dry_run_respects_preferences(self):
        (self.home / ".config" / "quickshell").mkdir(parents=True)
        self.prefs.write_text("nvim\n", encoding="utf-8")
        result = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would copy config/kitty", result.stdout)
        self.assertNotIn("would copy config/nvim", result.stdout)
        self.assertFalse((self.home / ".minflair_backup").exists())
        self.assertFalse((self.home / ".dotfiles_backup").exists())

    def test_update_dry_run_ensures_the_gtk_theme(self):
        (self.home / ".config" / "quickshell").mkdir(parents=True)
        result = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would install Material-Gnome into", result.stdout)

    def test_update_dry_run_skips_the_gtk_theme_when_disabled(self):
        (self.home / ".config" / "quickshell").mkdir(parents=True)
        self.prefs.write_text("gtk\n", encoding="utf-8")
        result = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Skipping GTK theme", result.stdout)
        self.assertNotIn("would install Material-Gnome into", result.stdout)

    def test_update_dry_run_handles_dunst(self):
        (self.home / ".config" / "quickshell").mkdir(parents=True)
        enabled = self.run_script("update.sh")
        self.assertEqual(enabled.returncode, 0, enabled.stderr)
        self.assertIn("would mask dunst", enabled.stdout)

        self.prefs.write_text("dunst\n", encoding="utf-8")
        disabled = self.run_script("update.sh")
        self.assertEqual(disabled.returncode, 0, disabled.stderr)
        self.assertIn("would restore dunst", disabled.stdout)

    def test_update_dry_run_enables_system_services(self):
        (self.home / ".config" / "quickshell").mkdir(parents=True)
        result = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would enable NetworkManager", result.stdout)

    def test_update_dry_run_installs_node_lts(self):
        (self.home / ".config" / "quickshell").mkdir(parents=True)
        result = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would install Node.js LTS with fnm", result.stdout)

    def test_update_dry_run_skips_services_when_disabled(self):
        (self.home / ".config" / "quickshell").mkdir(parents=True)
        self.prefs.write_text("services\n", encoding="utf-8")
        result = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Skipping system services", result.stdout)


if __name__ == "__main__":
    unittest.main()
