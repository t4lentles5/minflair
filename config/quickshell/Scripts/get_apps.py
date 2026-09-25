#!/usr/bin/env python3
import configparser
import json
import os
from pathlib import Path


def get_apps():
    apps = []
    seen_execs = set()

    # Search standard XDG application directories
    xdg_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    paths = [Path(p) / "applications" for p in xdg_dirs]
    paths.append(Path.home() / ".local" / "share" / "applications")
    paths.append(
        Path.home()
        / ".local"
        / "share"
        / "flatpak"
        / "exports"
        / "share"
        / "applications"
    )
    paths.append(Path("/var/lib/flatpak/exports/share/applications"))

    for d in paths:
        if not d.is_dir():
            continue
        for f in d.glob("*.desktop"):
            try:
                config = configparser.ConfigParser(interpolation=None)
                config.read(f, encoding="utf-8")
                if "Desktop Entry" in config:
                    entry = config["Desktop Entry"]

                    if (
                        entry.get("NoDisplay", "false").lower() == "true"
                        or entry.get("Hidden", "false").lower() == "true"
                    ):
                        continue

                    name = entry.get("Name", "").strip()
                    raw_exec = entry.get("Exec", "").strip()
                    executable = raw_exec.split(" %")[0].replace('"', "").strip()

                    if executable.startswith("/usr/bin/"):
                        executable = executable[9:]

                    icon = entry.get("Icon", "").replace('"', "").strip()
                    terminal = entry.get("Terminal", "false").lower() == "true"

                    actions = []
                    if "Actions" in entry:
                        action_keys = entry.get("Actions", "").strip(";").split(";")
                        for ak in action_keys:
                            ak = ak.strip()
                            if not ak:
                                continue
                            action_group = f"Desktop Action {ak}"
                            if action_group in config:
                                a_entry = config[action_group]
                                a_name = a_entry.get("Name", "").strip()
                                a_exec = a_entry.get("Exec", "").strip()
                                if a_name and a_exec:
                                    actions.append(
                                        {
                                            "name": a_name,
                                            "exec": a_exec.split(" %")[0]
                                            .replace('"', "")
                                            .strip(),
                                        }
                                    )

                    if name and executable and executable not in seen_execs:
                        apps.append(
                            {
                                "name": name,
                                "exec": raw_exec.split(" %")[0].strip(),
                                "icon": icon,
                                "terminal": terminal,
                                "actions": actions,
                            }
                        )
                        seen_execs.add(executable)
            except Exception:
                continue

    return sorted(apps, key=lambda x: x["name"].lower())


if __name__ == "__main__":
    print(json.dumps(get_apps()))
