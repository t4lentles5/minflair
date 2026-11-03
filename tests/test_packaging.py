import os
import re
import shutil
import subprocess
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PACKAGING = REPO_ROOT / "packaging"
AUR = PACKAGING / "aur"


class WrapperTests(unittest.TestCase):
    def run_wrapper(self, *args):
        env = os.environ.copy()
        env["MINFLAIR_PREFIX"] = str(REPO_ROOT)
        return subprocess.run(
            [str(PACKAGING / "minflair"), *args],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
        )

    def test_wrapper_is_executable(self):
        self.assertTrue(os.access(PACKAGING / "minflair", os.X_OK))

    def test_help_lists_commands(self):
        result = self.run_wrapper("help")
        self.assertEqual(result.returncode, 0, result.stderr)
        for command in ("install", "update", "components", "version"):
            self.assertIn(command, result.stdout)

    def test_version_matches_constants(self):
        constants = (
            REPO_ROOT / "config" / "quickshell" / "Core" / "Constants.qml"
        ).read_text(encoding="utf-8")
        match = re.search(r'appVersion:\s*"([^"]+)"', constants)
        self.assertIsNotNone(match)

        result = self.run_wrapper("version")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), match.group(1))

    def test_components_list_reads_the_manifest(self):
        result = self.run_wrapper("components", "list")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("quickshell", result.stdout)
        self.assertIn("hyprland", result.stdout)

    def test_unknown_command_fails(self):
        result = self.run_wrapper("does-not-exist")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Unknown command", result.stderr)


class PkgbuildTests(unittest.TestCase):
    def read(self, package, filename):
        return (AUR / package / filename).read_text(encoding="utf-8")

    def test_stable_package_matches_the_release_version(self):
        pkgbuild = self.read("minflair", "PKGBUILD")
        constants = (
            REPO_ROOT / "config" / "quickshell" / "Core" / "Constants.qml"
        ).read_text(encoding="utf-8")
        version = re.search(r'appVersion:\s*"([^"]+)"', constants).group(1)

        self.assertIn(f"pkgver={version}", pkgbuild)
        self.assertIn(f"/tags/v$pkgver.tar.gz", pkgbuild)
        self.assertIn("sha256sums=", pkgbuild)

    def test_stable_package_declares_core_dependencies(self):
        pkgbuild = self.read("minflair", "PKGBUILD")
        for package in (
            "quickshell",
            "hyprland",
            "hypridle",
            "hyprpicker",
            "hyprsunset",
            "xdg-desktop-portal-hyprland",
            "awww",
        ):
            self.assertIn(f"'{package}'", pkgbuild)

    def test_git_package_provides_and_conflicts_with_stable(self):
        pkgbuild = self.read("minflair-git", "PKGBUILD")
        self.assertIn("provides=('minflair')", pkgbuild)
        self.assertIn("conflicts=('minflair')", pkgbuild)
        self.assertIn("pkgver()", pkgbuild)

    def test_both_packages_install_the_wrapper_and_install_file(self):
        for package in ("minflair", "minflair-git"):
            pkgbuild = self.read(package, "PKGBUILD")
            if package == "minflair":
                self.assertIn(
                    'install -Dm755 "$_src/packaging/minflair"', pkgbuild
                )
            else:
                self.assertIn(
                    "install -Dm755 packaging/minflair", pkgbuild
                )
            self.assertTrue((AUR / package / f"{package}.install").is_file())
            self.assertTrue((AUR / package / ".SRCINFO").is_file())

    def test_srcinfo_matches_pkgbuild_when_makepkg_is_available(self):
        if shutil.which("makepkg") is None:
            self.skipTest("makepkg is not available")

        for package in ("minflair", "minflair-git"):
            result = subprocess.run(
                ["makepkg", "--printsrcinfo"],
                cwd=AUR / package,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                self.fail(result.stderr)
            self.assertEqual(
                (AUR / package / ".SRCINFO").read_text(encoding="utf-8"),
                result.stdout,
                f"{package}/.SRCINFO is out of date",
            )


if __name__ == "__main__":
    unittest.main()
