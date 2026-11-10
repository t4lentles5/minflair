import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = REPO_ROOT / "config" / "quickshell" / "Scripts"
SEARCH_SCRIPT = (
    REPO_ROOT
    / "config"
    / "quickshell"
    / "Modules"
    / "PackageManager"
    / "scripts"
    / "search_packages.py"
)


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class AurHelperShellTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.helper_file = self.home / ".config" / "minflair" / "aur-helper"

    def tearDown(self):
        self.tmp.cleanup()

    def run_shell(self, script, env=None):
        full_env = os.environ.copy()
        full_env["HOME"] = str(self.home)
        full_env.pop("MINFLAIR_AUR_HELPER", None)
        full_env.pop("MINFLAIR_AUR_HELPER_FILE", None)
        if env:
            full_env.update(env)
        return subprocess.run(
            ["bash", "-c", f'source "{REPO_ROOT}/lib/aur.sh"; {script}'],
            cwd=REPO_ROOT,
            env=full_env,
            capture_output=True,
            text=True,
        )

    def test_defaults_to_yay(self):
        result = self.run_shell("aur_helper")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "yay")

    def test_reads_the_saved_helper(self):
        self.helper_file.parent.mkdir(parents=True)
        self.helper_file.write_text("paru\n", encoding="utf-8")
        result = self.run_shell("aur_helper")
        self.assertEqual(result.stdout.strip(), "paru")

    def test_environment_override_wins(self):
        self.helper_file.parent.mkdir(parents=True)
        self.helper_file.write_text("yay\n", encoding="utf-8")
        result = self.run_shell(
            "aur_helper", {"MINFLAIR_AUR_HELPER": "paru"}
        )
        self.assertEqual(result.stdout.strip(), "paru")

    def test_invalid_saved_value_falls_back_to_yay(self):
        self.helper_file.parent.mkdir(parents=True)
        self.helper_file.write_text("pacman\n", encoding="utf-8")
        result = self.run_shell("aur_helper")
        self.assertEqual(result.stdout.strip(), "yay")

    def test_set_persists_the_choice(self):
        result = self.run_shell("aur_helper_set paru; aur_helper")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "paru")
        self.assertEqual(self.helper_file.read_text(encoding="utf-8").strip(), "paru")

    def test_set_rejects_unknown_helpers(self):
        result = self.run_shell("aur_helper_set pacman")
        self.assertNotEqual(result.returncode, 0)


class AurHelperPythonTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.helper_file = self.home / ".config" / "minflair" / "aur-helper"
        self.module = load_module("aur_helper", SCRIPTS / "aur_helper.py")

    def tearDown(self):
        self.tmp.cleanup()

    def test_defaults_to_yay(self):
        with mock.patch.dict(os.environ, {"HOME": str(self.home)}, clear=False):
            os.environ.pop("MINFLAIR_AUR_HELPER", None)
            os.environ.pop("MINFLAIR_AUR_HELPER_FILE", None)
            self.assertEqual(self.module.helper(), "yay")

    def test_reads_the_saved_helper(self):
        self.helper_file.parent.mkdir(parents=True)
        self.helper_file.write_text("paru\n", encoding="utf-8")
        with mock.patch.dict(os.environ, {"HOME": str(self.home)}, clear=False):
            os.environ.pop("MINFLAIR_AUR_HELPER", None)
            os.environ.pop("MINFLAIR_AUR_HELPER_FILE", None)
            self.assertEqual(self.module.helper(), "paru")

    def test_environment_override_wins(self):
        self.helper_file.parent.mkdir(parents=True)
        self.helper_file.write_text("yay\n", encoding="utf-8")
        with mock.patch.dict(
            os.environ,
            {"HOME": str(self.home), "MINFLAIR_AUR_HELPER": "paru"},
            clear=False,
        ):
            self.assertEqual(self.module.helper(), "paru")

    def test_invalid_value_falls_back_to_yay(self):
        self.helper_file.parent.mkdir(parents=True)
        self.helper_file.write_text("pacman\n", encoding="utf-8")
        with mock.patch.dict(os.environ, {"HOME": str(self.home)}, clear=False):
            os.environ.pop("MINFLAIR_AUR_HELPER", None)
            os.environ.pop("MINFLAIR_AUR_HELPER_FILE", None)
            self.assertEqual(self.module.helper(), "yay")


class PackageManagerHelperTests(unittest.TestCase):
    def test_search_uses_the_selected_helper(self):
        module = load_module("search_packages", SEARCH_SCRIPT)
        calls = []

        def fake_run(command, **kwargs):
            calls.append(command)
            return subprocess.CompletedProcess(command, 1, "", "")

        with mock.patch.dict(
            os.environ, {"MINFLAIR_AUR_HELPER": "paru"}, clear=False
        ), mock.patch.object(module.subprocess, "run", side_effect=fake_run):
            module.search_packages("firefox")

        self.assertIn(["paru", "-Ss", "firefox"], calls)


if __name__ == "__main__":
    unittest.main()
