import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[1]
SYSTEM_DIR = REPO_ROOT / "config" / "quickshell" / "Scripts" / "system"

sys.path.insert(0, str(SYSTEM_DIR))

import hypr_monitors


MONITOR = {
    "name": "eDP-1",
    "width": 1920,
    "height": 1080,
    "refreshRate": 144.0,
    "scale": 1,
    "disabled": False,
}


class HyprMonitorsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        patcher = mock.patch.dict(os.environ, {"XDG_CONFIG_HOME": str(self.home)})
        patcher.start()
        self.addCleanup(patcher.stop)

    def read_state(self):
        return json.loads(
            (self.home / "hypr" / "monitor_overrides.json").read_text(
                encoding="utf-8"
            )
        )

    def read_lua(self):
        return (self.home / "hypr" / "monitors_user.lua").read_text(encoding="utf-8")

    def test_set_mode_strips_the_hz_suffix_and_persists(self):
        with mock.patch.object(hypr_monitors, "monitors", return_value=[MONITOR]):
            with mock.patch.object(
                hypr_monitors, "apply_entry"
            ) as apply_entry:
                self.assertEqual(
                    hypr_monitors.set_mode("eDP-1", "1920x1080@144.00Hz"), 0
                )

        state = self.read_state()
        self.assertEqual(state["eDP-1"]["mode"], "1920x1080@144.00")
        self.assertEqual(state["eDP-1"]["position"], "auto")
        self.assertEqual(state["eDP-1"]["scale"], "1")

        lua = self.read_lua()
        self.assertIn('output = "eDP-1"', lua)
        self.assertIn('mode = "1920x1080@144.00"', lua)
        self.assertIn('position = "auto"', lua)
        self.assertNotIn("Hz", lua)
        apply_entry.assert_called_once_with("eDP-1", state["eDP-1"])

    def test_set_scale_keeps_the_selected_mode(self):
        state = {
            "eDP-1": {
                "mode": "1920x1080@144.00",
                "position": "auto",
                "scale": "1",
            }
        }
        (self.home / "hypr").mkdir(parents=True)
        (self.home / "hypr" / "monitor_overrides.json").write_text(
            json.dumps(state), encoding="utf-8"
        )

        with mock.patch.object(hypr_monitors, "monitors", return_value=[MONITOR]), (
            mock.patch.object(hypr_monitors, "apply_entry")
        ):
            self.assertEqual(hypr_monitors.set_scale("1.25"), 0)

        updated = self.read_state()
        self.assertEqual(updated["eDP-1"]["mode"], "1920x1080@144.00")
        self.assertEqual(updated["eDP-1"]["scale"], "1.25")
        self.assertIn('scale = "1.25"', self.read_lua())

    def test_set_mode_rejects_an_unknown_monitor(self):
        with mock.patch.object(hypr_monitors, "monitors", return_value=[]):
            self.assertEqual(hypr_monitors.set_mode("HDMI-A-1", "1920x1080@60Hz"), 1)
        self.assertFalse(
            (self.home / "hypr" / "monitor_overrides.json").exists()
        )

    def test_set_scale_rejects_an_invalid_value(self):
        with mock.patch.object(hypr_monitors, "monitors", return_value=[MONITOR]):
            self.assertEqual(hypr_monitors.set_scale("huge"), 1)

    def test_missing_hyprctl_does_not_crash(self):
        with mock.patch.object(
            hypr_monitors.subprocess,
            "check_output",
            side_effect=FileNotFoundError,
        ):
            self.assertEqual(hypr_monitors.monitors(), [])

    def test_hyprland_loads_the_user_overrides_after_the_defaults(self):
        content = (REPO_ROOT / "config" / "hypr" / "hyprland.lua").read_text(
            encoding="utf-8"
        )
        self.assertIn('pcall(require, "monitors_user")', content)
        self.assertLess(
            content.index('require("monitors")'),
            content.index("monitors_user"),
        )

    def test_scale_wrapper_uses_the_monitor_helper(self):
        wrapper = (
            REPO_ROOT
            / "config"
            / "quickshell"
            / "Scripts"
            / "system"
            / "hypr_scale.sh"
        )
        content = wrapper.read_text(encoding="utf-8")
        self.assertIn("hypr_monitors.py", content)
        self.assertIn("set-scale", content)


if __name__ == "__main__":
    unittest.main()
