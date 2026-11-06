#!/bin/bash
# Hyprland applies monitors.lua on every reload, so writing the scale there
# would wipe the per-monitor mode chosen in Settings. Delegate to the helper
# that stores overrides in monitors_user.lua instead.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/hypr_monitors.py" set-scale "${1:-1}"
