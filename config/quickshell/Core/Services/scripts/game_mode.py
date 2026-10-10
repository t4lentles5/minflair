#!/usr/bin/env python3
import json
import os
import subprocess
import sys

sys.dont_write_bytecode = True

PREV_PROFILE_FILE = "/tmp/minflair_prev_power_profile"


def get_status():
    daemon_active = False
    try:
        res = subprocess.run(
            ["gamemoded", "-s"], capture_output=True, text=True, timeout=1
        )
        if "is active" in res.stdout:
            daemon_active = True
    except Exception:
        pass

    power_profile = "balanced"
    try:
        res_pwr = subprocess.run(
            ["powerprofilesctl", "get"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        if res_pwr.returncode == 0:
            power_profile = res_pwr.stdout.strip()
    except Exception:
        pass

    return {
        "gamemode_active": daemon_active,
        "power_profile": power_profile,
    }


def apply_mode():
    current_profile = "balanced"
    try:
        res = subprocess.run(
            ["powerprofilesctl", "get"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        if res.returncode == 0:
            current_profile = res.stdout.strip()
    except Exception:
        pass

    if not os.path.exists(PREV_PROFILE_FILE):
        try:
            with open(PREV_PROFILE_FILE, "w") as f:
                f.write(current_profile)
        except Exception:
            pass

    try:
        subprocess.run(["powerprofilesctl", "set", "performance"], timeout=2)
    except Exception:
        pass

    return {"status": "applied"}


def revert_mode():
    prev_profile = "balanced"
    if os.path.exists(PREV_PROFILE_FILE):
        try:
            with open(PREV_PROFILE_FILE, "r") as f:
                prev_profile = f.read().strip()
            os.remove(PREV_PROFILE_FILE)
        except Exception:
            pass

    try:
        subprocess.run(["powerprofilesctl", "set", prev_profile], timeout=2)
    except Exception:
        pass

    return {"status": "reverted", "restored_profile": prev_profile}


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "status"
    if action == "status":
        print(json.dumps(get_status()))
    elif action == "apply":
        print(json.dumps(apply_mode()))
    elif action == "revert":
        print(json.dumps(revert_mode()))
    else:
        print(json.dumps({"error": f"Unknown action {action}"}))


if __name__ == "__main__":
    main()
