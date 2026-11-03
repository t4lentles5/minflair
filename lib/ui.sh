#!/usr/bin/env bash
# Shared terminal UI helpers for the Minflair installer and updater.
#
# This file is sourced. It must not change the caller's shell options. It uses
# only bash builtins and coreutils, so it works on a fresh Arch installation
# before Python or any TUI package is available.

if [[ -n "${MINFLAIR_UI_SH:-}" ]]; then
  return 0
fi
MINFLAIR_UI_SH=1

UI_TTY=0
UI_COLOR=0
UI_PLAIN=0
UI_WIDTH=80
UI_HEIGHT=24
UI_CURSOR_HIDDEN=0
UI_RESET=""
UI_BOLD=""
UI_DIM=""
UI_CYAN=""
UI_GREEN=""
UI_YELLOW=""
UI_RED=""

ui_init() {
  UI_TTY=0
  if [[ -t 1 ]]; then
    UI_TTY=1
  fi

  UI_PLAIN=0
  if [[ "${TERM:-dumb}" == "dumb" ]]; then
    UI_PLAIN=1
  fi

  UI_COLOR=0
  if (( UI_TTY )) && (( ! UI_PLAIN )) && [[ -z "${NO_COLOR:-}" ]]; then
    UI_COLOR=1
  fi

  UI_WIDTH="${COLUMNS:-}"
  if [[ ! "$UI_WIDTH" =~ ^[0-9]+$ ]] && command -v tput >/dev/null 2>&1; then
    UI_WIDTH="$(tput cols 2>/dev/null || true)"
  fi
  if [[ ! "$UI_WIDTH" =~ ^[0-9]+$ ]] || (( UI_WIDTH < 40 )); then
    UI_WIDTH=80
  fi

  UI_HEIGHT="${LINES:-}"
  if [[ ! "$UI_HEIGHT" =~ ^[0-9]+$ ]] && command -v tput >/dev/null 2>&1; then
    UI_HEIGHT="$(tput lines 2>/dev/null || true)"
  fi
  if [[ ! "$UI_HEIGHT" =~ ^[0-9]+$ ]] || (( UI_HEIGHT < 10 )); then
    UI_HEIGHT=24
  fi

  if (( UI_COLOR )); then
    UI_RESET=$'\033[0m'
    UI_BOLD=$'\033[1m'
    UI_DIM=$'\033[2m'
    UI_CYAN=$'\033[36m'
    UI_GREEN=$'\033[32m'
    UI_YELLOW=$'\033[33m'
    UI_RED=$'\033[31m'
  else
    UI_RESET=""
    UI_BOLD=""
    UI_DIM=""
    UI_CYAN=""
    UI_GREEN=""
    UI_YELLOW=""
    UI_RED=""
  fi
}

ui_cleanup() {
  if (( ${UI_CURSOR_HIDDEN:-0} )); then
    printf '\033[?25h'
    UI_CURSOR_HIDDEN=0
  fi
}

ui_hide_cursor() {
  if (( UI_TTY )) && (( ! UI_CURSOR_HIDDEN )); then
    printf '\033[?25l'
    UI_CURSOR_HIDDEN=1
  fi
}

ui_show_cursor() {
  if (( UI_CURSOR_HIDDEN )); then
    printf '\033[?25h'
    UI_CURSOR_HIDDEN=0
  fi
}

ui_refresh_size() {
  local cols lines
  if command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
    lines="$(tput lines 2>/dev/null || true)"
    if [[ "$cols" =~ ^[0-9]+$ ]] && (( cols >= 40 )); then
      UI_WIDTH="$cols"
    fi
    if [[ "$lines" =~ ^[0-9]+$ ]] && (( lines >= 10 )); then
      UI_HEIGHT="$lines"
    fi
  fi
}

ui_rule() {
  local width="${1:-$UI_WIDTH}"
  if (( ! UI_TTY || UI_PLAIN )); then
    printf '%*s\n' "$width" '' | tr ' ' '-'
    return 0
  fi
  printf '%s' "$UI_DIM"
  printf '%*s' "$width" '' | tr ' ' '─'
  printf '%s\n' "$UI_RESET"
}

ui_header() {
  local title="$1"
  local subtitle="${2:-}"

  if (( ! UI_TTY || UI_PLAIN )); then
    printf '\n%s\n' "$title"
    if [[ -n "$subtitle" ]]; then
      printf '%s\n' "$subtitle"
    fi
    ui_rule
    return 0
  fi

  printf '\n%s%s%s%s\n' "$UI_BOLD" "$UI_CYAN" "$title" "$UI_RESET"
  if [[ -n "$subtitle" ]]; then
    printf '%s%s%s\n' "$UI_DIM" "$subtitle" "$UI_RESET"
  fi
  ui_rule
}

ui_section() {
  local title="$1"
  if (( UI_TTY && ! UI_PLAIN )); then
    printf '\n%s%s── %s ──%s\n' "$UI_BOLD" "$UI_CYAN" "$title" "$UI_RESET"
  else
    printf '\n== %s ==\n' "$title"
  fi
}

ui_info() {
  printf '%s[INFO]%s %s\n' "$UI_CYAN" "$UI_RESET" "$1"
}

ui_ok() {
  printf '%s[OK]%s %s\n' "$UI_GREEN" "$UI_RESET" "$1"
}

ui_warn() {
  printf '%s[WARN]%s %s\n' "$UI_YELLOW" "$UI_RESET" "$1" >&2
}

ui_error() {
  printf '%s[ERROR]%s %s\n' "$UI_RED" "$UI_RESET" "$1" >&2
  exit 1
}

ui_done() {
  printf '\n%s✓ %s%s\n' "$UI_GREEN" "$1" "$UI_RESET"
}

ui_confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local suffix="[y/N] "
  local reply=""

  if (( ! UI_TTY )); then
    return 1
  fi

  if [[ "$default" == "y" ]]; then
    suffix="[Y/n] "
  fi

  printf '%s%s%s%s' "$UI_BOLD" "$prompt" " $suffix" "$UI_RESET"
  read -r reply || return 1
  reply="${reply:-$default}"

  [[ "$reply" =~ ^[Yy]$ ]]
}
