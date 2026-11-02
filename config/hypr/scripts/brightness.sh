#!/bin/bash

MIN_BRIGHTNESS=5
STEP=5

HELPER="$HOME/.config/quickshell/Scripts/system/brightness.sh"

get_brightness() {
  local value=""
  if [ -x "$HELPER" ]; then
    value=$("$HELPER" get 2>/dev/null)
  fi
  if [ -z "$value" ]; then
    value=$(brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }')
  fi
  case "$value" in
  '' | *[!0-9]*) value=0 ;;
  esac
  printf '%s' "$value"
}

set_brightness() {
  local value="$1"
  if [ -x "$HELPER" ] && "$HELPER" set "$value" >/dev/null 2>&1; then
    return 0
  fi
  brightnessctl set "${value}%" >/dev/null 2>&1
}

CURRENT=$(get_brightness)

case "$1" in
up)
  if [ "$CURRENT" -ge 100 ]; then
    exit 0
  fi
  TARGET=$((CURRENT + STEP))
  [ "$TARGET" -gt 100 ] && TARGET=100
  ;;
down)
  if [ "$CURRENT" -le "$MIN_BRIGHTNESS" ]; then
    exit 0
  fi
  TARGET=$((CURRENT - STEP))
  [ "$TARGET" -lt "$MIN_BRIGHTNESS" ] && TARGET=$MIN_BRIGHTNESS
  ;;
*)
  echo "Usage: $0 {up|down}" >&2
  exit 1
  ;;
esac

set_brightness "$TARGET"

BRIGHTNESS=$(get_brightness)
qs ipc call osd showBrightness "$BRIGHTNESS" 2>/dev/null || true
