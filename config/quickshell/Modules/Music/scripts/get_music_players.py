#!/usr/bin/env python3
import sys

sys.dont_write_bytecode = True

import configparser
import json
import os
import shutil
from pathlib import Path


def get_installed_players():
    results = []
    seen_ids = set()
    seen_execs = set()

    # Search standard XDG application directories
    xdg_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    paths = [Path(p) / "applications" for p in xdg_dirs]
    paths.append(Path(os.path.expanduser("~/.local/share/applications")))
    paths.append(
        Path(os.path.expanduser("~/.local/share/flatpak/exports/share/applications"))
    )
    paths.append(Path("/var/lib/flatpak/exports/share/applications"))

    # Exclusions for utilities and recorders that might have Audio/Video categories
    exclude_keywords = [
        "mixer",
        "volume control",
        "recorder",
        "capture",
        "test utility",
        "equalizer",
        "editor",
        "effects",
        "converter",
        "settings",
    ]
    exclude_execs = [
        "pavucontrol",
        "obs",
        "qv4l2",
        "qvidcap",
        "audacity",
        "easyeffects",
        "helvum",
        "alsamixer",
        "pw-top",
        "wireplumber",
        "qpaeq",
        "sound-recorder",
    ]
    known_players = [
        "spotify",
        "youtube-music",
        "kew",
        "vlc",
        "mpv",
        "amberol",
        "rhythmbox",
        "clementine",
        "strawberry",
        "cider",
        "audacious",
        "deadbeef",
        "elisa",
        "lollypop",
        "tauonmb",
        "tauon",
        "quodlibet",
        "sayonara",
        "musique",
        "feishin",
        "supersonic",
        "g4music",
        "shortwave",
        "tidal-hifi",
        "nuclear",
        "celluloid",
        "dopamine",
        "foobar2000",
        "sonora",
        "harmony",
        "museeks",
        "deezer",
    ]

    for d in paths:
        if not d.exists():
            continue
        for f in d.glob("*.desktop"):
            try:
                config = configparser.ConfigParser(interpolation=None)
                config.read(f)
                if "Desktop Entry" not in config:
                    continue
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
                    clean_exec = executable[9:]
                else:
                    clean_exec = executable

                base_bin = clean_exec.split()[0] if clean_exec else ""
                exec_lower = base_bin.lower()
                name_lower = name.lower()
                desktop_stem = f.stem.lower()

                if any(x in exec_lower for x in exclude_execs) or any(
                    x in name_lower for x in exclude_keywords
                ):
                    continue

                cats = [
                    c.strip()
                    for c in entry.get("Categories", "").split(";")
                    if c.strip()
                ]
                is_known = any(
                    k in exec_lower or k in name_lower or k in desktop_stem
                    for k in known_players
                )
                is_player = (
                    "Player" in cats
                    or "Music" in cats
                    or (
                        "AudioVideo" in cats and "Video" not in cats and "Audio" in cats
                    )
                ) and not any(
                    x in cats for x in ["Recorder", "Mixer", "Settings", "Editor"]
                )

                if is_known or is_player:
                    if (
                        shutil.which(base_bin)
                        or os.path.exists(base_bin)
                        or shutil.which(executable.split()[0])
                    ):
                        player_id = exec_lower
                        for kp in known_players:
                            if (
                                kp in exec_lower
                                or kp in desktop_stem
                                or kp in name_lower
                            ):
                                player_id = kp
                                break
                        if player_id not in seen_ids and base_bin not in seen_execs:
                            seen_ids.add(player_id)
                            seen_execs.add(base_bin)
                            results.append(
                                {
                                    "id": player_id,
                                    "name": name,
                                    "exec": clean_exec,
                                    "icon": entry.get("Icon", "music"),
                                    "terminal": entry.get("Terminal", "false").lower()
                                    == "true",
                                    "desktopEntry": f.stem,
                                }
                            )
            except Exception:
                pass

    # CLI audio players
    cli_players = [
        ("kew", "kew", "kew", "music"),
        ("cmus", "Cmus", "cmus", "terminal"),
        ("mocp", "MOC", "mocp", "terminal"),
        ("ncmpcpp", "ncmpcpp", "ncmpcpp", "terminal"),
        ("mpd", "MPD", "mpd", "music"),
        ("rmpc", "rmpc", "rmpc", "terminal"),
        ("musikcube", "musikcube", "musikcube", "terminal"),
    ]
    for cid, cname, cexec, cicon in cli_players:
        if shutil.which(cexec) and cid not in seen_ids and cexec not in seen_execs:
            seen_ids.add(cid)
            seen_execs.add(cexec)
            results.append(
                {
                    "id": cid,
                    "name": cname,
                    "exec": cexec,
                    "icon": cicon,
                    "terminal": True,
                    "desktopEntry": cid,
                }
            )

    return sorted(results, key=lambda x: x["name"].lower())


if __name__ == "__main__":
    print(json.dumps(get_installed_players()))
