#!/bin/bash

# Parse enabled layouts from settings
PREFS_FILE="$HOME/.cache/quickshell/settings_prefs.json"
LAYOUTS_STR=$(jq -r '.enabledKbLayouts | join(" ")' "$PREFS_FILE" 2>/dev/null)

if [ -z "$LAYOUTS_STR" ] || [ "$LAYOUTS_STR" == "null" ]; then
  LAYOUTS_STR="us latam" # Fallback
fi

read -a LAYOUTS <<<"$LAYOUTS_STR"

# Get current layout from hyprland
CURRENT_LAYOUT=$(hyprctl getoption input:kb_layout -j 2>/dev/null | jq -r '.str // empty' 2>/dev/null | xargs)

# Find index of current layout in the array
IDX=-1
for i in "${!LAYOUTS[@]}"; do
  # Support partial matching just in case (e.g. us* -> us)
  if [[ "$CURRENT_LAYOUT" == "${LAYOUTS[$i]}"* ]]; then
    IDX=$i
    break
  fi
done

# Calculate next index
NEXT_IDX=$(((IDX + 1) % ${#LAYOUTS[@]}))
NEW_LAYOUT="${LAYOUTS[$NEXT_IDX]}"

# Apply
hyprctl eval "hl.config({input = {kb_layout = '$NEW_LAYOUT'}})" 2>/dev/null || true
notify-send -r 701 "Keyboard Layout" "Switched to $NEW_LAYOUT" 2>/dev/null || true
