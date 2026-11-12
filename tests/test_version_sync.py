import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

CONSTANTS = REPO_ROOT / "config" / "quickshell" / "Core" / "Constants.qml"
CARGO_TOML = REPO_ROOT / "cli" / "Cargo.toml"
CARGO_LOCK = REPO_ROOT / "Cargo.lock"


def read_app_version() -> str:
    """Read the version the Quickshell shell reports in the UI."""
    content = CONSTANTS.read_text(encoding="utf-8")
    match = re.search(r'appVersion:\s*"([^"]+)"', content)
    if not match:
        raise AssertionError(f"no appVersion found in {CONSTANTS}")
    return match.group(1)


def read_crate_version() -> str:
    """Read the version of the minflair CLI crate."""
    content = CARGO_TOML.read_text(encoding="utf-8")
    match = re.search(r'^version\s*=\s*"([^"]+)"', content, re.MULTILINE)
    if not match:
        raise AssertionError(f"no version found in {CARGO_TOML}")
    return match.group(1)


def read_lock_version() -> str:
    """Read the version the lockfile records for the minflair crate."""
    content = CARGO_LOCK.read_text(encoding="utf-8")
    match = re.search(
        r'\[\[package\]\]\nname = "minflair"\nversion = "([^"]+)"', content
    )
    if not match:
        raise AssertionError("no minflair package found in Cargo.lock")
    return match.group(1)


class VersionSyncTests(unittest.TestCase):
    """The shell and the CLI must always report the same version.

    They live in two separate files and are bumped by hand, so it is easy
    to update one and forget the other. When they drift, minflair --version
    and the installer header show different numbers for the same release.
    """

    def test_the_cli_and_the_shell_report_the_same_version(self):
        self.assertEqual(read_app_version(), read_crate_version())

    def test_the_lockfile_matches_the_crate(self):
        self.assertEqual(read_lock_version(), read_crate_version())

    def test_the_version_is_a_release_number(self):
        self.assertRegex(read_app_version(), r"^\d+\.\d+\.\d+$")


if __name__ == "__main__":
    unittest.main()
