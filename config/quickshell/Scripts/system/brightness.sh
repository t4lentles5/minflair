#!/usr/bin/env bash

# Minflair brightness helper.
#
# Uses brightnessctl for internal panels (sysfs backlight) and falls back to
# ddcutil for external monitors over DDC/CI when no internal panel is found.
#
# Usage:
#   brightness.sh get            Print the current brightness (0-100)
#   brightness.sh set <percent>  Set the brightness (1-100)
#   brightness.sh backend        Print "brightnessctl", "ddcutil" or "none"
#
# Optional:
#   MINFLAIR_BRIGHTNESS_BACKEND=brightnessctl|ddcutil  Force a backend.
#
# The detected backend, the DDC/CI bus list and the last DDC/CI value are
# cached in $XDG_RUNTIME_DIR/minflair so polling stays cheap and does not
# hammer the I2C bus.

set -u

MIN_BRIGHTNESS=1
MAX_BRIGHTNESS=100
DDC_VALUE_TTL=2
NONE_TTL=30

runtime_dir="${XDG_RUNTIME_DIR:-/tmp/minflair-$(id -u)}"
cache_dir="$runtime_dir/minflair"
backend_file="$cache_dir/brightness_backend"
value_file="$cache_dir/brightness_value"
none_file="$cache_dir/brightness_none"
lock_file="$cache_dir/brightness.lock"

mkdir -p "$cache_dir" 2>/dev/null || true

forced_backend="${MINFLAIR_BRIGHTNESS_BACKEND:-}"

have() {
  command -v "$1" >/dev/null 2>&1
}

clamp_percent() {
  local value="${1:-}"
  [[ "$value" =~ ^[0-9]+$ ]] || return 1
  if ((value < MIN_BRIGHTNESS)); then
    value=$MIN_BRIGHTNESS
  elif ((value > MAX_BRIGHTNESS)); then
    value=$MAX_BRIGHTNESS
  fi
  printf '%s\n' "$value"
}

# --- internal panel (brightnessctl) -----------------------------------------

internal_available() {
  have brightnessctl || return 1
  brightnessctl -m >/dev/null 2>&1
}

internal_get() {
  local percent
  percent=$(brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }')
  [[ "$percent" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$percent"
}

internal_set() {
  brightnessctl set "${1}%" >/dev/null 2>&1
}

# --- external monitors (ddcutil) --------------------------------------------

ddc_available() {
  have ddcutil
}

# Print the I2C bus number of every display reported by ddcutil.
ddc_list_buses() {
  ddcutil detect --brief 2>/dev/null | awk '
    /I2C bus:/ && match($0, /\/dev\/i2c-[0-9]+/) {
      bus = substr($0, RSTART, RLENGTH)
      sub(/^.*i2c-/, "", bus)
      if (!(bus in seen)) {
        seen[bus] = 1
        print bus
      }
    }'
}

ddc_get() {
  local bus="$1" output current maximum
  output=$(ddcutil --bus "$bus" --brief getvcp 10 2>/dev/null) || return 1
  # Expected output: "VCP 10 C <current> <maximum>"
  set -- $output
  [[ "${1:-}" == "VCP" && "${2:-}" == "10" ]] || return 1
  current="${4:-}"
  maximum="${5:-}"
  [[ "$current" =~ ^[0-9]+$ ]] || return 1
  if [[ "$maximum" =~ ^[0-9]+$ ]] && ((maximum > 0 && maximum != 100)); then
    current=$(((current * 100 + maximum / 2) / maximum))
  fi
  printf '%s\n' "$current"
}

ddc_set() {
  local bus="$1" value="$2"
  ddcutil --bus "$bus" setvcp 10 "$value" >/dev/null 2>&1
}

# Keep only the buses that actually expose the brightness VCP code.
ddc_detect_buses() {
  local bus buses=""
  for bus in $(ddc_list_buses); do
    if ddc_get "$bus" >/dev/null 2>&1; then
      buses="$buses $bus"
    fi
  done
  buses="${buses# }"
  [[ -n "$buses" ]] || return 1
  printf '%s\n' "$buses"
}

# --- cache ------------------------------------------------------------------

cached_backend() {
  [[ -f "$backend_file" ]] || return 1
  head -n 1 "$backend_file" 2>/dev/null
}

cached_buses() {
  [[ -f "$backend_file" ]] || return 1
  sed -n '2p' "$backend_file" 2>/dev/null
}

write_backend_cache() {
  printf '%s\n%s\n' "$1" "${2:-}" >"$backend_file.tmp" 2>/dev/null &&
    mv "$backend_file.tmp" "$backend_file" 2>/dev/null
}

clear_cache() {
  rm -f "$backend_file" "$value_file"
}

# Remember for a short while that no display supports DDC/CI, so the UI polling
# loop does not run a full detection on every call.
none_cache_fresh() {
  [[ -f "$none_file" ]] || return 1
  local timestamp now
  timestamp=$(head -n 1 "$none_file" 2>/dev/null) || return 1
  [[ "$timestamp" =~ ^[0-9]+$ ]] || return 1
  now=$(date +%s)
  ((now - timestamp < NONE_TTL))
}

write_none_cache() {
  date +%s >"$none_file.tmp" 2>/dev/null &&
    mv "$none_file.tmp" "$none_file" 2>/dev/null
}

cached_value() {
  [[ -f "$value_file" ]] || return 1
  local timestamp value now
  read -r timestamp value <"$value_file" 2>/dev/null || return 1
  [[ "$timestamp" =~ ^[0-9]+$ && "$value" =~ ^[0-9]+$ ]] || return 1
  now=$(date +%s)
  ((now - timestamp <= DDC_VALUE_TTL)) || return 1
  printf '%s\n' "$value"
}

write_value_cache() {
  printf '%s %s\n' "$(date +%s)" "$1" >"$value_file.tmp" 2>/dev/null &&
    mv "$value_file.tmp" "$value_file" 2>/dev/null
}

# --- backend resolution -----------------------------------------------------

resolve_backend() {
  local backend buses

  if [[ -z "$forced_backend" ]] && none_cache_fresh; then
    return 1
  fi

  backend=$(cached_backend) || backend=""
  buses=$(cached_buses) || buses=""

  if [[ -n "$forced_backend" ]]; then
    case "$forced_backend" in
    brightnessctl)
      if internal_available; then
        printf 'brightnessctl\n'
        return 0
      fi
      ;;
    ddcutil)
      if [[ "$backend" == "ddcutil" && -n "$buses" ]]; then
        printf 'ddcutil %s\n' "$buses"
        return 0
      fi
      if ddc_available && buses=$(ddc_detect_buses); then
        write_backend_cache ddcutil "$buses"
        printf 'ddcutil %s\n' "$buses"
        return 0
      fi
      ;;
    esac
    return 1
  fi

  # Internal panels always win when present. This also switches back to
  # brightnessctl when a laptop panel appears after an external monitor was
  # detected.
  if internal_available; then
    if [[ "$backend" != "brightnessctl" ]]; then
      write_backend_cache brightnessctl
    fi
    printf 'brightnessctl\n'
    return 0
  fi

  case "$backend" in
  brightnessctl)
    clear_cache
    ;;
  ddcutil)
    if [[ -n "$buses" ]]; then
      printf 'ddcutil %s\n' "$buses"
      return 0
    fi
    clear_cache
    ;;
  esac

  if ddc_available; then
    buses=$(ddc_detect_buses) || buses=""
    if [[ -n "$buses" ]]; then
      write_backend_cache ddcutil "$buses"
      printf 'ddcutil %s\n' "$buses"
      return 0
    fi
  fi

  write_none_cache
  return 1
}

# --- actions ----------------------------------------------------------------

do_get() {
  local attempt info backend buses value
  for attempt in 1 2; do
    info=$(resolve_backend) || return 1
    backend=${info%% *}
    buses=${info#* }
    case "$backend" in
    brightnessctl)
      if value=$(internal_get); then
        printf '%s\n' "$value"
        return 0
      fi
      ;;
    ddcutil)
      if value=$(cached_value); then
        printf '%s\n' "$value"
        return 0
      fi
      if value=$(ddc_get "${buses%% *}"); then
        write_value_cache "$value"
        printf '%s\n' "$value"
        return 0
      fi
      ;;
    esac
    clear_cache
  done
  return 1
}

do_set() {
  local target attempt info backend buses bus ok
  target=$(clamp_percent "${1:-}") || return 1
  for attempt in 1 2; do
    info=$(resolve_backend) || return 1
    backend=${info%% *}
    buses=${info#* }
    case "$backend" in
    brightnessctl)
      if internal_set "$target"; then
        return 0
      fi
      ;;
    ddcutil)
      # Apply to every detected monitor. A monitor that is asleep or
      # unreachable must not invalidate the whole change, so succeed when at
      # least one display accepted the new value.
      ok=0
      for bus in $buses; do
        if ddc_set "$bus" "$target"; then
          ok=1
        fi
      done
      if ((ok == 1)); then
        write_value_cache "$target"
        return 0
      fi
      ;;
    esac
    clear_cache
  done
  return 1
}

do_backend() {
  local info
  if info=$(resolve_backend); then
    printf '%s\n' "${info%% *}"
  else
    printf 'none\n'
  fi
}

# Serialize DDC/CI access: a detection can take a few seconds and must not run
# at the same time as a brightness change.
if have flock && { exec 9>"$lock_file"; } 2>/dev/null; then
  flock 9
fi

case "${1:-get}" in
get)
  do_get
  ;;
set)
  do_set "${2:-}"
  ;;
backend)
  do_backend
  ;;
*)
  printf 'Usage: %s {get|set <percent>|backend}\n' "$0" >&2
  exit 1
  ;;
esac
