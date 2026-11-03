#!/usr/bin/env bash
# Shared component helpers for install.sh and update.sh.
#
# This file is sourced. It must not change the caller's shell options.
# The caller is expected to define REPO_DIR before sourcing it.

if [[ -n "${MINFLAIR_COMPONENTS_SH:-}" ]]; then
  return 0
fi
MINFLAIR_COMPONENTS_SH=1

MANIFEST="${MINFLAIR_MANIFEST:-$REPO_DIR/config/quickshell/components.tsv}"
PREFS_FILE="${MINFLAIR_PREFS:-$HOME/.config/minflair/preferences.conf}"
DRY_RUN="${DRY_RUN:-0}"

# Read the version from the Quickshell constants so the installer, the updater
# and the selector always show the same value.
minflair_version() {
  local constants="$REPO_DIR/config/quickshell/Core/Constants.qml"
  if [[ -f "$constants" ]]; then
    sed -n 's/.*appVersion: "\([^"]*\)".*/\1/p' "$constants" | head -n 1
  else
    printf 'unknown'
  fi
}

manifest_rows() {
  awk -F'\t' '
    /^[[:space:]]*#/ { next }
    NF == 0 { next }
    $1 == "id" { next }
    { print }
  ' "$MANIFEST"
}

# Bash treats tab as IFS whitespace, so "read" collapses empty fields. Emit the
# rows with the non-whitespace unit separator instead, which preserves them.
manifest_fields() {
  awk -F'\t' '
    /^[[:space:]]*#/ { next }
    NF == 0 { next }
    $1 == "id" { next }
    {
      for (i = 1; i <= 10; i++) {
        if (i > 1) printf "\037"
        printf "%s", $i
      }
      printf "\n"
    }
  ' "$MANIFEST"
}

component_field() {
  local id="$1" field="$2"
  awk -F'\t' -v id="$id" -v field="$field" '
    /^[[:space:]]*#/ { next }
    NF == 0 { next }
    $1 == "id" { next }
    $1 == id { print $field; found = 1; exit }
    END { if (!found) exit 1 }
  ' "$MANIFEST"
}

component_exists() {
  component_field "$1" 1 >/dev/null 2>&1
}

component_ids() {
  manifest_rows | cut -f1
}

component_core() {
  [[ "$(component_field "$1" 4)" == "1" ]]
}

prefs_contains() {
  [[ -f "$PREFS_FILE" ]] || return 1
  awk -v id="$1" '
    { gsub(/^[[:space:]]+|[[:space:]]+$/, "") }
    $0 == id { found = 1; exit }
    END { exit !found }
  ' "$PREFS_FILE"
}

prefs_disabled_ids() {
  [[ -f "$PREFS_FILE" ]] || return 0
  awk '
    { gsub(/^[[:space:]]+|[[:space:]]+$/, "") }
    $0 != "" && $0 !~ /^#/ { print }
  ' "$PREFS_FILE"
}

# Drop ids that no longer exist or that became core, so editing the file from
# the installer also cleans preferences written by an older version.
prefs_known_disabled() {
  local id
  while IFS= read -r id; do
    if component_exists "$id" && ! component_core "$id"; then
      printf '%s\n' "$id"
    fi
  done < <(prefs_disabled_ids)
}

prefs_write() {
  local -a ids=("$@")
  local tmp
  # Callers that run in dry-run mode point PREFS_FILE at a temporary copy, so
  # this function always writes and the simulated selection stays consistent.
  mkdir -p "$(dirname "$PREFS_FILE")"
  tmp="$(mktemp "${PREFS_FILE}.tmp.XXXXXX")"
  {
    printf '# Minflair preferences v1\n'
    printf '# One disabled component id per line.\n\n'
    if ((${#ids[@]})); then
      printf '%s\n' "${ids[@]}" | LC_ALL=C sort -u
    fi
  } >"$tmp"
  mv "$tmp" "$PREFS_FILE"
}

prefs_add() {
  local -a current=()
  mapfile -t current < <(prefs_known_disabled)
  prefs_write "${current[@]}" "$@"
}

prefs_remove() {
  local -a current=() keep=()
  local id remove found
  mapfile -t current < <(prefs_known_disabled)
  for id in "${current[@]}"; do
    found=0
    for remove in "$@"; do
      if [[ "$id" == "$remove" ]]; then
        found=1
        break
      fi
    done
    if (( ! found )); then
      keep+=("$id")
    fi
  done
  prefs_write "${keep[@]}"
}

prefs_set_only() {
  local -a keep_enabled=("$@") disabled=()
  local id keep found
  while IFS= read -r id; do
    if component_core "$id"; then
      continue
    fi
    found=0
    for keep in "${keep_enabled[@]}"; do
      if [[ "$id" == "$keep" ]]; then
        found=1
        break
      fi
    done
    if (( ! found )); then
      disabled+=("$id")
    fi
  done < <(component_ids)
  prefs_write "${disabled[@]}"
}

component_enabled() {
  local id="$1"
  if ! component_exists "$id"; then
    return 1
  fi
  if component_core "$id"; then
    return 0
  fi
  if prefs_contains "$id"; then
    return 1
  fi
  return 0
}

component_paths() {
  local mode="${1:---enabled}" id paths path
  local -a parts=()
  while IFS= read -r id; do
    if [[ "$mode" == "--disabled" ]]; then
      if component_enabled "$id"; then
        continue
      fi
    else
      if ! component_enabled "$id"; then
        continue
      fi
    fi
    paths="$(component_field "$id" 5)" || continue
    if [[ -z "$paths" ]]; then
      continue
    fi
    IFS=',' read -r -a parts <<<"$paths"
    for path in "${parts[@]}"; do
      path="${path//[[:space:]]/}"
      if [[ -n "$path" ]]; then
        printf '%s\n' "$path"
      fi
    done
  done < <(component_ids)
}

component_packages() {
  local mode="${1:---enabled}" id packages package
  local -a parts=()
  while IFS= read -r id; do
    if [[ "$mode" == "--disabled" ]]; then
      if component_enabled "$id"; then
        continue
      fi
    else
      if ! component_enabled "$id"; then
        continue
      fi
    fi
    packages="$(component_field "$id" 6)" || continue
    if [[ -z "$packages" ]]; then
      continue
    fi
    IFS=',' read -r -a parts <<<"$packages"
    for package in "${parts[@]}"; do
      package="${package//[[:space:]]/}"
      if [[ -n "$package" ]]; then
        printf '%s\n' "$package"
      fi
    done
  done < <(component_ids)
}

filter_package_file() {
  local file="$1" package
  local -a disabled=()
  local -A skip=()
  mapfile -t disabled < <(component_packages --disabled)
  for package in "${disabled[@]}"; do
    skip["$package"]=1
  done
  while IFS= read -r package; do
    package="${package//[[:space:]]/}"
    if [[ -n "$package" && -z "${skip[$package]:-}" ]]; then
      printf '%s\n' "$package"
    fi
  done < <(grep -vE '^[[:space:]]*(#|$)' "$file")
}

validate_selection_ids() {
  local id
  for id in "$@"; do
    if ! component_exists "$id"; then
      printf 'Unknown component: %s\n' "$id" >&2
      return 1
    fi
  done
}

validate_disable_ids() {
  local id
  for id in "$@"; do
    if ! component_exists "$id"; then
      printf 'Unknown component: %s\n' "$id" >&2
      return 1
    fi
    if component_core "$id"; then
      printf 'Core component cannot be disabled: %s\n' "$id" >&2
      return 1
    fi
  done
}

components_validate() {
  local errors=0 id paths path duplicates
  local -a parts=()

  if [[ ! -f "$MANIFEST" ]]; then
    printf 'Component manifest not found: %s\n' "$MANIFEST" >&2
    return 1
  fi

  duplicates="$(component_ids | LC_ALL=C sort | uniq -d)"
  if [[ -n "$duplicates" ]]; then
    printf 'Duplicate component ids: %s\n' "$duplicates" >&2
    errors=1
  fi

  local bad_rows
  bad_rows="$(awk -F'\t' '
    /^[[:space:]]*#/ { next }
    NF == 0 { next }
    $1 == "id" { next }
    NF != 10 { print NR }
  ' "$MANIFEST")"
  if [[ -n "$bad_rows" ]]; then
    printf 'Manifest rows with the wrong number of columns: %s\n' "$bad_rows" >&2
    errors=1
  fi

  # Unknown and core ids in preferences are ignored at runtime, so they are
  # warnings rather than fatal errors. This keeps an old preferences file from
  # blocking an update after a component is renamed or removed.
  while IFS= read -r id; do
    if ! component_exists "$id"; then
      printf 'warning: preferences contain an unknown component: %s\n' "$id" >&2
    elif component_core "$id"; then
      printf 'warning: preferences contain a core component: %s\n' "$id" >&2
    fi
  done < <(prefs_disabled_ids)

  while IFS= read -r id; do
    paths="$(component_field "$id" 5)" || continue
    if [[ -z "$paths" ]]; then
      continue
    fi
    IFS=',' read -r -a parts <<<"$paths"
    for path in "${parts[@]}"; do
      path="${path//[[:space:]]/}"
      if [[ -n "$path" && ! -e "$REPO_DIR/$path" ]]; then
        printf '%s: path does not exist: %s\n' "$id" "$path" >&2
        errors=1
      fi
    done
  done < <(component_ids)

  return "$errors"
}

components_list() {
  printf '%-12s %-10s %-5s %-9s %s\n' "ID" "CATEGORY" "CORE" "STATUS" "DESCRIPTION"
  local id label category core paths packages theme font reload description
  local status core_label
  while IFS=$'\037' read -r id label category core paths packages theme font reload description; do
    if [[ "$core" == "1" ]]; then
      status="core"
      core_label="yes"
    elif prefs_contains "$id"; then
      status="disabled"
      core_label="no"
    else
      status="enabled"
      core_label="no"
    fi
    printf '%-12s %-10s %-5s %-9s %s\n' "$id" "$category" "$core_label" "$status" "$description"
  done < <(manifest_fields)
}

components_join() {
  local out="" item
  for item in "$@"; do
    if [[ -n "$out" ]]; then
      out+=", "
    fi
    out+="$item"
  done
  printf '%s' "$out"
}

# Print a comma-separated list indented and wrapped to the terminal width.
components_print_list() {
  local indent="$1" text="$2" width="${COLUMNS:-100}"
  [[ -n "$text" ]] || return 0
  if [[ ! "$width" =~ ^[0-9]+$ ]] || (( width < 40 )); then
    width=80
  fi
  printf '%s\n' "$text" | fold -s -w "$((width - ${#indent}))" | sed "s/^/${indent}/"
}

components_summary() {
  local id label category core paths packages theme font reload description
  local -a enabled=() skipped=()
  local enabled_text skipped_text

  while IFS=$'\037' read -r id label category core paths packages theme font reload description; do
    if component_core "$id" || component_enabled "$id"; then
      enabled+=("$label")
    else
      skipped+=("$label")
    fi
  done < <(manifest_fields)

  enabled_text="$(components_join "${enabled[@]}")"
  if [[ -n "$enabled_text" ]]; then
    printf '  Enabled (%d):\n' "${#enabled[@]}"
    components_print_list "    " "$enabled_text"
  else
    printf '  Enabled (0): none\n'
  fi

  if ((${#skipped[@]})); then
    skipped_text="$(components_join "${skipped[@]}")"
    printf '  Skipped (%d):\n' "${#skipped[@]}"
    components_print_list "    " "$skipped_text"
    printf '  Skipped components keep their existing files.\n'
  else
    printf '  Skipped (0): none\n'
  fi
}

destination_for_path() {
  case "$1" in
    config/*) printf '%s/.config/%s\n' "$HOME" "${1#config/}" ;;
    home/*) printf '%s/%s\n' "$HOME" "${1#home/}" ;;
    *) return 1 ;;
  esac
}

backup_target_for_path() {
  case "$1" in
    config/*) printf '%s/config/%s\n' "$BACKUP_DIR" "${1#config/}" ;;
    home/*) printf '%s/home/%s\n' "$BACKUP_DIR" "${1#home/}" ;;
    *) return 1 ;;
  esac
}

backup_enabled_paths() {
  local path dest backup
  while IFS= read -r path; do
    dest="$(destination_for_path "$path")" || continue
    backup="$(backup_target_for_path "$path")" || continue
    if [[ ! -e "$dest" ]]; then
      continue
    fi
    if (( DRY_RUN )); then
      printf '[dry-run] would back up %s -> %s\n' "$dest" "$backup"
    else
      mkdir -p "$(dirname "$backup")"
      cp -a "$dest" "$backup"
    fi
  done < <(component_paths --enabled)
}

copy_enabled_paths() {
  local path
  while IFS= read -r path; do
    case "$path" in
      config/*)
        if (( DRY_RUN )); then
          printf '[dry-run] would copy %s -> %s/.config/\n' "$path" "$HOME"
        else
          mkdir -p "$HOME/.config"
          cp -a "$REPO_DIR/$path" "$HOME/.config/"
        fi
        ;;
      home/*)
        if (( DRY_RUN )); then
          printf '[dry-run] would copy %s -> %s/\n' "$path" "$HOME"
        else
          cp -a "$REPO_DIR/$path" "$HOME/"
        fi
        ;;
    esac
  done < <(component_paths --enabled)
}

run() {
  if (( DRY_RUN )); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

component_reloads() {
  local mode="${1:---all}" id reload
  while IFS= read -r id; do
    if [[ "$mode" == "--non-core" ]] && component_core "$id"; then
      continue
    fi
    component_enabled "$id" || continue
    reload="$(component_field "$id" 9)" || continue
    if [[ -n "$reload" ]]; then
      printf '%s\n' "$reload"
    fi
  done < <(component_ids)
}

run_reloads() {
  local mode="${1:---non-core}" reload
  while IFS= read -r reload; do
    [[ -z "$reload" ]] && continue
    if (( DRY_RUN )); then
      printf '[dry-run] reload: %s\n' "$reload"
    else
      # A reload is best effort: the application may not be running.
      bash -c "$reload" >/dev/null 2>&1 || true
    fi
  done < <(component_reloads "$mode")
}

append_csv() {
  local -n target="$1"
  local -a items=()
  local item
  IFS=',' read -r -a items <<<"$2"
  for item in "${items[@]}"; do
    item="${item//[[:space:]]/}"
    if [[ -n "$item" ]]; then
      target+=("$item")
    fi
  done
}
