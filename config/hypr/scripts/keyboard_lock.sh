#!/bin/bash

MODE="${1:-caps}"
LOG="/tmp/keyboard_lock.log"

printf '%s invoked mode=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MODE" >>"$LOG"

resolve_state() {
  local mode="$1"
  python3 - "$mode" <<'PY'
import glob
import json
import os
import subprocess
import sys
import time

mode = sys.argv[1]
prop = "numLock" if mode == "num" else "capsLock"
led_name = "numlock" if mode == "num" else "capslock"
map_file = f"/tmp/hypr_{mode}_kb_map.json"
last_file = f"/tmp/hypr_{mode}_last_state"
ignored = ("video-bus", "power-button", "sleep-button", "wmi", "radio")


def read_last():
    try:
        with open(last_file) as f:
            value = f.read().strip()
        return value if value in ("ON", "OFF") else None
    except OSError:
        return None


def write_last(state):
    try:
        with open(last_file, "w") as f:
            f.write("ON" if state else "OFF")
    except OSError:
        pass


def read_led():
    for path in sorted(glob.glob(f"/sys/class/leds/input*::{led_name}/brightness")):
        try:
            with open(path) as f:
                return f.read().strip() == "1"
        except OSError:
            continue
    return None


def read_keyboards():
    try:
        out = subprocess.check_output(["hyprctl", "devices", "-j"], timeout=1)
        data = json.loads(out)
        return [
            k for k in data.get("keyboards", [])
            if not any(ign in k.get("name", "") for ign in ignored)
        ]
    except Exception:
        return []


last = read_last()
state = None

# The bind can run a few milliseconds before the compositor updates the lock
# state, so give it a moment before reading the LED or Hyprland's devices.
time.sleep(0.03)

# The LED reflects the kernel lock state and is updated by the compositor.
# Poll briefly because the bind can run before the LED changes. The first run
# after a reboot has no previous state, so the LED value is used directly.
led = read_led()
if led is not None:
    if last is None:
        state = led
    else:
        previous = last == "ON"
        for _ in range(10):
            led = read_led()
            if led is not None and led != previous:
                state = led
                break
            time.sleep(0.02)

# The LED may be missing, stale, or belong to a different sub-device. Fall back
# to Hyprland's device list and look for the keyboard whose state changed.
if state is None:
    previous_map = {}
    if os.path.exists(map_file):
        try:
            with open(map_file) as f:
                previous_map = json.load(f)
        except Exception:
            pass

    keyboards = []
    current_map = {}
    changed = []
    for _ in range(10):
        keyboards = read_keyboards()
        current_map = {k["name"]: bool(k.get(prop, False)) for k in keyboards}
        changed = [
            name for name, value in current_map.items()
            if name in previous_map and previous_map[name] != value
        ]
        if changed:
            break
        time.sleep(0.02)

    try:
        with open(map_file, "w") as f:
            json.dump(current_map, f)
    except OSError:
        pass

    if changed:
        state = current_map[changed[0]]

# Nothing observable changed: this is the first run or every backend lags, so
# toggle the last reported state. Without history, trust the main keyboard.
if state is None:
    if last is not None:
        state = (last == "OFF")
    else:
        main_kb = next((k for k in keyboards if k.get("main")), (keyboards[0] if keyboards else {}))
        state = bool(main_kb.get(prop, False))

write_last(state)
print("ON" if state else "OFF")
PY
}

STATE="$(resolve_state "$MODE")"

if [ "$MODE" = "num" ]; then
  TITLE="Num Lock"
  ICON="lock"
elif [ "$STATE" = "ON" ]; then
  TITLE="Caps Lock"
  ICON="caps-lock-filled"
else
  TITLE="Caps Lock"
  ICON="caps-lock"
fi

timeout 3 qs ipc call osd showMessage "$TITLE" "$STATE" "$ICON" 2>/dev/null
rc=$?
printf '%s mode=%s state=%s qs_rc=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MODE" "$STATE" "$rc" >>"$LOG"
