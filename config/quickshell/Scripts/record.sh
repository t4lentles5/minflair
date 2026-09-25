#!/bin/bash

# Export essential environment variables for Wayland/Hyprland
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
if [ -z "$WAYLAND_DISPLAY" ]; then
  for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
    if [ -S "$sock" ]; then
      export WAYLAND_DISPLAY=$(basename "$sock")
      break
    fi
  done
  export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
fi
export XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-Hyprland}

DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$DIR"

LOG="$DIR/record.log"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
FILENAME="$DIR/Recording-${TIMESTAMP}.mkv"

# If already running, stop it cleanly
if pidof wf-recorder >/dev/null 2>&1; then
  echo "wf-recorder is running, stopping it..." >>"$LOG"
  killall -SIGINT wf-recorder
  exit 0
fi

echo "--- Record started at $(date) ---" >>"$LOG"

AUDIO_SOURCE=""
REGION=""

while getopts "sr" opt; do
  case "$opt" in
  s)
    if command -v pactl >/dev/null 2>&1; then
      default_sink=$(pactl get-default-sink 2>/dev/null)
      if [ -n "$default_sink" ]; then
        AUDIO_SOURCE="${default_sink}.monitor"
      fi
    fi
    ;;
  r)
    GEOM=$(slurp 2>/dev/null)
    if [ -z "$GEOM" ]; then
      echo "Region selection canceled" >>"$LOG"
      exit 0
    fi
    REGION="$GEOM"
    ;;
  *)
    ;;
  esac
done

MONITOR=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor' 2>/dev/null)
if [ -z "$MONITOR" ] || [ "$MONITOR" = "null" ]; then
  MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name' 2>/dev/null)
fi

echo "Recording monitor: $MONITOR | Region: $REGION | Audio: $AUDIO_SOURCE | Output: $FILENAME" >>"$LOG"

CMD=("wf-recorder" "-x" "yuv420p" "-p" "color_range=tv" "-p" "color_primaries=bt709" "-p" "color_trc=bt709" "-p" "colorspace=bt709" "-c" "libx264" "-f" "$FILENAME")

if [ -n "$REGION" ]; then
  CMD+=("-g" "$REGION")
elif [ -n "$MONITOR" ]; then
  CMD+=("-o" "$MONITOR")
fi

if [ -n "$AUDIO_SOURCE" ]; then
  pactl set-source-mute "$AUDIO_SOURCE" false 2>/dev/null || true
  CMD+=("--audio=$AUDIO_SOURCE")
fi

"${CMD[@]}" >>"$LOG" 2>&1
