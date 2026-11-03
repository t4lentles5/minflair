#!/usr/bin/env bash
# Interactive component selector for install.sh and update.sh.
#
# This file is sourced after lib/components.sh and lib/ui.sh. It uses only bash
# builtins and coreutils, so it works on a fresh Arch installation where Python
# is not available yet.
#
# Controls: Up/Down (or j/k) move, Space toggles, a enables all optional
# components, n disables all optional components, / searches, Enter reviews the
# selection and q cancels.

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
  [[ -t 0 && -t 1 ]] || return 1
  [[ "${TERM:-dumb}" != "dumb" ]]
}

selector_version() {
  minflair_version
}

selector_run() {
  local -a ids=() labels=() cats=() cores=() descs=() filtered=()
  local -A selected=()
  local id label category core paths packages theme font reload description
  local key rest cursor=0 total i idx prev line count optional filter=""
  local query version left_width right_width desc_width two_pane
  local mark

  while IFS=$'\037' read -r id label category core paths packages theme font reload description; do
    ids+=("$id")
    labels+=("$label")
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

  version="$(selector_version)"

  rebuild_filter() {
    local f="${filter,,}" id_lc label_lc desc_lc
    filtered=()
    for ((i = 0; i < total; i++)); do
      id_lc="${ids[i],,}"
      label_lc="${labels[i],,}"
      desc_lc="${descs[i],,}"
      if [[ -z "$f" || "$id_lc" == *"$f"* || "$label_lc" == *"$f"* || "$desc_lc" == *"$f"* ]]; then
        filtered+=("$i")
      fi
    done
    if ((${#filtered[@]} == 0)); then
      cursor=0
    elif (( cursor >= ${#filtered[@]} )); then
      cursor=$((${#filtered[@]} - 1))
    fi
  }

  selector_review() {
    local -a included=() skipped=()
    local review_id

    for ((i = 0; i < total; i++)); do
      review_id="${ids[i]}"
      if [[ "${cores[i]}" == "1" || "${selected[$review_id]}" == "1" ]]; then
        included+=("${labels[i]}")
      else
        skipped+=("${labels[i]}")
      fi
    done

    printf '\033[H\033[2J'
    ui_header "Minflair $version" "Review selection"
    printf '\n  %sIncluded (%d)%s\n' "$UI_BOLD" "${#included[@]}" "$UI_RESET"
    components_print_list "    " "$(components_join "${included[@]}")"
    printf '\n'
    if ((${#skipped[@]})); then
      printf '  %sSkipped (%d)%s\n' "$UI_BOLD" "${#skipped[@]}" "$UI_RESET"
      components_print_list "    " "$(components_join "${skipped[@]}")"
      printf '\n'
      printf '  Skipped components keep their existing files. Minflair will not\n'
      printf '  copy, theme or reload them.\n\n'
    else
      printf '  %sSkipped (0)%s: none\n\n' "$UI_BOLD" "$UI_RESET"
    fi

    ui_show_cursor
    if ui_confirm "Apply this selection?" y; then
      local -a enabled_ids=()
      for ((i = 0; i < total; i++)); do
        review_id="${ids[i]}"
        if [[ "${selected[$review_id]}" == "1" ]]; then
          enabled_ids+=("$review_id")
        fi
      done
      prefs_set_only "${enabled_ids[@]}" || return 2
      return 0
    fi
    ui_hide_cursor
    return 1
  }

  rebuild_filter
  ui_hide_cursor

  while true; do
    ui_refresh_size

    two_pane=0
    left_width=$((UI_WIDTH * 45 / 100))
    if (( left_width < 36 )); then left_width=36; fi
    if (( left_width > 54 )); then left_width=54; fi
    right_width=$((UI_WIDTH - left_width - 4))
    if (( UI_WIDTH >= 90 && right_width >= 24 )); then
      two_pane=1
    fi
    desc_width=$((UI_WIDTH - 30))
    if (( desc_width < 16 )); then desc_width=16; fi

    printf '\033[H\033[2J'
    ui_header "Minflair $version" "Select components"
    printf '\n'

    if ((${#filtered[@]} == 0)); then
      printf '  No components match "%s". Press Esc to clear the filter.\n' "$filter"
    else
      prev=""
      for idx in "${filtered[@]}"; do
        if [[ "${cats[idx]}" != "$prev" ]]; then
          printf '\n  %s%s%s\n' "$UI_BOLD" "$(selector_category_label "${cats[idx]}")" "$UI_RESET"
          prev="${cats[idx]}"
        fi

        if [[ "${cores[idx]}" == "1" ]]; then
          mark="[core]"
        elif [[ "${selected[${ids[idx]}]}" == "1" ]]; then
          mark="[x]"
        else
          mark="[ ]"
        fi

        if (( two_pane )); then
          printf -v line '  %-7s %-18s' "$mark" "${ids[idx]}"
        elif (( UI_WIDTH >= 60 )); then
          printf -v line '  %-7s %-18s %s' "$mark" "${ids[idx]}" "${descs[idx]:0:desc_width}"
        else
          printf -v line '  %-7s %-18s' "$mark" "${ids[idx]}"
        fi

        if (( idx == filtered[cursor] )); then
          printf '\033[7m%-*s\033[0m' "$left_width" "$line"
          if (( two_pane )); then
            printf '  %s\n' "${descs[idx]:0:right_width}"
          else
            printf '\n'
          fi
        else
          printf '%-*s' "$left_width" "$line"
          if (( two_pane )); then
            printf '\n'
          else
            printf '\n'
          fi
        fi
      done
    fi

    count=0
    optional=0
    for ((i = 0; i < total; i++)); do
      if [[ "${cores[i]}" != "1" ]]; then
        optional=$((optional + 1))
        if [[ "${selected[${ids[i]}]}" == "1" ]]; then
          count=$((count + 1))
        fi
      fi
    done

    printf '\n'
    ui_rule
    printf '  %s%d/%d optional enabled%s' "$UI_BOLD" "$count" "$optional" "$UI_RESET"
    if (( optional - count > 0 )); then
      printf '   %s%d skipped%s' "$UI_DIM" "$((optional - count))" "$UI_RESET"
    fi
    printf '\n'
    if [[ -n "$filter" ]]; then
      printf '  %sFilter: %s (Esc clears)%s\n' "$UI_DIM" "$filter" "$UI_RESET"
    fi
    printf '  %sSpace toggle   Enter continue   a all   n none   / search   q cancel%s\n' "$UI_DIM" "$UI_RESET"

    key=""
    IFS= read -rsn1 key || {
      ui_show_cursor
      return 1
    }

    case "$key" in
      "" | $'\n')
        if selector_review; then
          ui_show_cursor
          printf '\n%sSelection saved to %s%s\n' "$UI_GREEN" "$PREFS_FILE" "$UI_RESET"
          return 0
        fi
        ;;
      " ")
        idx="${filtered[cursor]:-}"
        if [[ -n "$idx" && "${cores[idx]}" != "1" ]]; then
          id="${ids[idx]}"
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
      n | N)
        for ((i = 0; i < total; i++)); do
          if [[ "${cores[i]}" != "1" ]]; then
            selected["${ids[i]}"]=0
          fi
        done
        ;;
      /)
        ui_show_cursor
        printf '\n  Search (empty clears): '
        read -r query || query=""
        ui_hide_cursor
        filter="$query"
        cursor=0
        rebuild_filter
        ;;
      q | Q)
        ui_show_cursor
        printf '\n%sSelection cancelled.%s\n' "$UI_YELLOW" "$UI_RESET"
        return 1
        ;;
      j)
        if (( cursor < ${#filtered[@]} - 1 )); then
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
            if (( cursor < ${#filtered[@]} - 1 )); then
              cursor=$((cursor + 1))
            fi
            ;;
          *)
            if [[ -n "$filter" ]]; then
              filter=""
              cursor=0
              rebuild_filter
            fi
            ;;
        esac
        ;;
    esac
  done
}
