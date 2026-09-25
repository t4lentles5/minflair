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

MODE="${1:-full}"
DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
FILENAME="$DIR/Shot-${TIMESTAMP}.png"

mkdir -p "$DIR"

# Ensure any dangling slurp instance is terminated
pkill -x slurp 2>/dev/null

play_sound() {
  local sound="/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
  if [ -f "$sound" ]; then
    if command -v paplay &>/dev/null; then
      paplay "$sound" >/dev/null 2>&1 &
    elif command -v pw-play &>/dev/null; then
      pw-play "$sound" >/dev/null 2>&1 &
    fi
  fi
}

copy_and_notify() {
  if [ -f "$FILENAME" ]; then
    wl-copy <"$FILENAME"
    play_sound
  fi
}

take_screenshot() {
  local target_mode="$1"

  case "$target_mode" in
  "full")
    sleep 0.3
    grim "$FILENAME" || return 1
    ;;

  "area" | "select")
    local geom
    geom=$(slurp -d 2>/dev/null)
    if [ -z "$geom" ]; then
      return 1
    fi
    sleep 0.2
    grim -g "$geom" "$FILENAME" || return 1
    ;;

  "window")
    sleep 0.3
    local raw_json win_w win_h geom rounding
    raw_json=$(hyprctl activewindow -j 2>/dev/null)
    geom=$(echo "$raw_json" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
    win_w=$(echo "$raw_json" | jq -r '.size[0]' 2>/dev/null)
    win_h=$(echo "$raw_json" | jq -r '.size[1]' 2>/dev/null)

    if [ -z "$geom" ] || [ "$geom" = "null" ] || [ -z "$win_w" ] || [ "$win_w" -le 0 ]; then
      return 1
    fi

    grim -g "$geom" "$FILENAME" || return 1

    rounding=$(hyprctl getoption decoration:rounding 2>/dev/null | awk '/int:/ {print $2}')
    rounding=${rounding:-10}

    local conv_cmd="convert"
    if command -v magick &>/dev/null; then
      conv_cmd="magick"
    fi

    if command -v "$conv_cmd" &>/dev/null; then
      "$conv_cmd" "$FILENAME" \
        \( +clone \
        -alpha extract \
        -fill black -colorize 100 \
        -fill white \
        -draw "roundrectangle 0,0 $((win_w - 1)),$((win_h - 1)) ${rounding},${rounding}" \
        \) \
        -alpha off \
        -compose CopyOpacity \
        -composite \
        PNG32:"$FILENAME" 2>/dev/null || true
    fi
    ;;

  *)
    return 1
    ;;
  esac

  return 0
}

case "$MODE" in
"area_3s" | "3s")
  sleep 3
  if take_screenshot "area"; then
    copy_and_notify
  fi
  ;;

"full_delay" | "area_delay" | "5s")
  sleep 3
  actual_mode="${MODE%_delay}"
  if [ "$actual_mode" = "5s" ]; then actual_mode="full"; fi
  if take_screenshot "$actual_mode"; then
    copy_and_notify
  fi
  ;;

"clipboard")
  geom=$(slurp -d 2>/dev/null)
  if [ -n "$geom" ]; then
    sleep 0.2
    grim -g "$geom" - | wl-copy --type image/png
    play_sound
  fi
  ;;

"ocr")
  geom=$(slurp -d 2>/dev/null)
  if [ -n "$geom" ]; then
    sleep 0.2
    temp_ocr="/tmp/ocr_temp_${TIMESTAMP}.png"
    grim -g "$geom" "$temp_ocr" 2>/dev/null
    if [ -f "$temp_ocr" ]; then
      tesseract "$temp_ocr" stdout -l eng+spa 2>/dev/null | wl-copy
      notify-send -r 699 "Screenshot" "Text extracted and copied to clipboard" 2>/dev/null || true
      rm -f "$temp_ocr"
      play_sound
    fi
  fi
  ;;

*)
  if take_screenshot "$MODE"; then
    copy_and_notify
  fi
  ;;
esac
