#!/bin/bash
SCALE="${1:-1}"
TARGET_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.lua"
mkdir -p "$(dirname "$TARGET_FILE")"

cat <<EOL >"$TARGET_FILE"
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "$SCALE",
})
EOL
