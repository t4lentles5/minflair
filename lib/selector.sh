#!/usr/bin/env bash
# Interactive component selector for install.sh and update.sh.
#
# This file is sourced after lib/components.sh. It uses only bash builtins and
# reads the manifest, so it works on a fresh Arch installation where Python is
# not available yet.
#
# Controls: Up/Down (or j/k) move, Space toggles, a toggles all optional
# components, Enter confirms and q cancels.

if [[ -n "${MINFLAIR_SELECTOR_SH:-}" ]]; then
  return 0
fi
MINFLAIR_SELECTOR_SH=1

selector_category_label() {
  case "$1" in
    core) printf 'Core (always installed)' ;;
    terminal) printf 'Terminal' ;;
    desktop) printf 'Desktop' ;;
    apps) printf 'Applications' ;;
    system) printf 'System' ;;
    *) printf '%s' "$1" ;;
  esac
}

selector_available() {
  [[ -t 0 && -t 1 ]]
}

selector_run() {
  local -a ids=() cats=() cores=() descs=()
  local -A selected=()
  local id label category core paths packages theme font reload description
  local key rest cursor=0 total i mark line prev count optional

  while IFS=$'\037' read -r id label category core paths packages theme font reload description; do
    ids+=("$id")
    cats+=("$category")
    cores+=("$core")
    descs+=("$description")
    if component_enabled "$id"; then
      selected["$id"]=1
    else
      selected["$id"]=0
    fi
  done < <(manifest_fields)

  total=${#ids[@]}
  if (( total == 0 )); then
    printf 'No components found in %s\n' "$MANIFEST" >&2
    return 1
  fi

  while true; do
    printf '\033[H\033[2J'
    printf 'Minflair components\n'
    printf 'Space toggles, Enter confirms, a toggles all, q cancels.\n'

    prev=""
    count=0
    optional=0
    for ((i = 0; i < total; i++)); do
      id="${ids[i]}"
      if [[ "${cats[i]}" != "$prev" ]]; then
        printf '\n%s\n' "$(selector_category_label "${cats[i]}")"
        prev="${cats[i]}"
      fi

      if [[ "${cores[i]}" == "1" ]]; then
        mark="[core]"
      elif [[ "${selected[$id]}" == "1" ]]; then
        mark="[x]"
        count=$((count + 1))
        optional=$((optional + 1))
      else
        mark="[ ]"
        optional=$((optional + 1))
      fi

      line="$(printf '  %-7s %-18s %s' "$mark" "$id" "${descs[i]}")"
      if (( i == cursor )); then
        printf '\033[7m%s\033[0m\n' "$line"
      else
        printf '%s\n' "$line"
      fi
    done

    printf '\nEnabled optional components: %d/%d\n' "$count" "$optional"
    printf 'Preferences: %s\n' "$PREFS_FILE"

    key=""
    IFS= read -rsn1 key || return 1
    case "$key" in
      "" | $'\n')
        break
        ;;
      " ")
        id="${ids[cursor]}"
        if [[ "${cores[cursor]}" != "1" ]]; then
          if [[ "${selected[$id]}" == "1" ]]; then
            selected["$id"]=0
          else
            selected["$id"]=1
          fi
        fi
        ;;
      a | A)
        for ((i = 0; i < total; i++)); do
          if [[ "${cores[i]}" != "1" ]]; then
            selected["${ids[i]}"]=1
          fi
        done
        ;;
      q | Q)
        return 1
        ;;
      j)
        if (( cursor < total - 1 )); then
          cursor=$((cursor + 1))
        fi
        ;;
      k)
        if (( cursor > 0 )); then
          cursor=$((cursor - 1))
        fi
        ;;
      $'\e')
        rest=""
        IFS= read -rsn2 -t 0.05 rest || true
        case "$rest" in
          "[A")
            if (( cursor > 0 )); then
              cursor=$((cursor - 1))
            fi
            ;;
          "[B")
            if (( cursor < total - 1 )); then
              cursor=$((cursor + 1))
            fi
            ;;
        esac
        ;;
    esac
  done

  local -a enabled_ids=()
  for id in "${ids[@]}"; do
    if [[ "${selected[$id]}" == "1" ]]; then
      enabled_ids+=("$id")
    fi
  done
  prefs_set_only "${enabled_ids[@]}" || return 2
  return 0
}
