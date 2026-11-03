#!/usr/bin/env bash
# Shared AUR helper selection for install.sh, update.sh and the runtime scripts.
#
# The helper is stored in a small plain-text file so the installer, the updater
# and Quickshell read the same value. Set MINFLAIR_AUR_HELPER to override it
# without touching the file.

if [[ -n "${MINFLAIR_AUR_SH:-}" ]]; then
  return 0
fi
MINFLAIR_AUR_SH=1

AUR_HELPER_FILE="${MINFLAIR_AUR_HELPER_FILE:-$HOME/.config/minflair/aur-helper}"
AUR_HELPER_DEFAULT="yay"

aur_helper_valid() {
  [[ "${1:-}" == "yay" || "${1:-}" == "paru" ]]
}

aur_helper() {
  local helper="${MINFLAIR_AUR_HELPER:-}"
  if [[ -z "$helper" && -f "$AUR_HELPER_FILE" ]]; then
    helper="$(head -n 1 "$AUR_HELPER_FILE" 2>/dev/null | tr -d '[:space:]')"
  fi
  if ! aur_helper_valid "$helper"; then
    helper="$AUR_HELPER_DEFAULT"
  fi
  printf '%s' "$helper"
}

aur_helper_set() {
  local helper="${1:-}"
  aur_helper_valid "$helper" || return 1
  mkdir -p "$(dirname "$AUR_HELPER_FILE")"
  printf '%s\n' "$helper" >"$AUR_HELPER_FILE"
}

aur_helper_installed() {
  command -v "$(aur_helper)" >/dev/null 2>&1
}
