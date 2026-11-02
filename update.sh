#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
SDDM_THEME_DIR="/usr/share/sddm/themes/minflair-sddm"
DRY_RUN=0
NO_INPUT=0
NO_PACKAGES=0
SELECT=0
EXCLUDE_IDS=()
INCLUDE_IDS=()
ONLY_IDS=()

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${CYAN}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: ./update.sh [options]

Update Minflair. The saved component preferences are respected: disabled
components are not copied, installed, themed or reloaded. Existing files from
disabled components are left untouched.

Selection:
  --exclude IDS    Disable components (comma-separated, repeatable)
  --only IDS       Enable only these optional components (plus core)
  --include IDS    Re-enable components that were previously disabled
  --select         Open the interactive selector before updating
  --no-input       Never prompt; use the saved preferences

Behaviour:
  --dry-run        Show what would happen without changing anything
  --no-packages    Do not install or update packages
  -h, --help       Show this help

Examples:
  ./update.sh --dry-run
  ./update.sh --exclude nvim
  ./update.sh --include kitty
  ./update.sh --select
EOF
}

# ── shared component helpers ─────────────────────────────────────────────────
[ -f "$REPO_DIR/lib/components.sh" ] ||
  error "lib/components.sh not found. Are you running this from the Minflair repository?"
# shellcheck source=lib/components.sh
source "$REPO_DIR/lib/components.sh"
# shellcheck source=lib/selector.sh
source "$REPO_DIR/lib/selector.sh"

while (($#)); do
  case "$1" in
    --exclude)
      [[ $# -ge 2 ]] || error "--exclude requires a value."
      append_csv EXCLUDE_IDS "$2"
      shift 2
      ;;
    --exclude=*)
      append_csv EXCLUDE_IDS "${1#*=}"
      shift
      ;;
    --only)
      [[ $# -ge 2 ]] || error "--only requires a value."
      append_csv ONLY_IDS "$2"
      shift 2
      ;;
    --only=*)
      append_csv ONLY_IDS "${1#*=}"
      shift
      ;;
    --include)
      [[ $# -ge 2 ]] || error "--include requires a value."
      append_csv INCLUDE_IDS "$2"
      shift 2
      ;;
    --include=*)
      append_csv INCLUDE_IDS "${1#*=}"
      shift
      ;;
    --select)
      SELECT=1
      shift
      ;;
    --no-input)
      NO_INPUT=1
      shift
      ;;
    --no-packages)
      NO_PACKAGES=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1 (use --help)"
      ;;
  esac
done

if [ "$(id -u)" -eq 0 ]; then
  error "Run update.sh as your normal user, not as root."
fi

cd "$REPO_DIR"

[ -f "$REPO_DIR/packages.txt" ] || error "packages.txt not found. Are you running this from the Minflair repository?"
[ -f "$REPO_DIR/packages-aur.txt" ] || error "packages-aur.txt not found."
[ -d "$REPO_DIR/config" ] || error "config/ not found."
[ -d "$HOME/.config/quickshell" ] || error "Quickshell config not found in ~/.config. Run install.sh first."

# In dry-run mode preferences are written to a temporary copy so the simulated
# selection is accurate and the real file is never touched.
if ((DRY_RUN)); then
  DRY_PREFS="$(mktemp)"
  if [[ -f "$PREFS_FILE" ]]; then
    cp "$PREFS_FILE" "$DRY_PREFS"
  fi
  PREFS_FILE="$DRY_PREFS"
  trap 'rm -f "$DRY_PREFS"' EXIT
fi

components_validate || error "The component manifest or preferences are invalid."

apply_selection_flags() {
  if ((${#ONLY_IDS[@]})); then
    validate_selection_ids "${ONLY_IDS[@]}" || error "Invalid --only list."
    prefs_set_only "${ONLY_IDS[@]}"
  fi
  if ((${#INCLUDE_IDS[@]})); then
    validate_selection_ids "${INCLUDE_IDS[@]}" || error "Invalid --include list."
    prefs_remove "${INCLUDE_IDS[@]}"
  fi
  if ((${#EXCLUDE_IDS[@]})); then
    validate_disable_ids "${EXCLUDE_IDS[@]}" || error "Invalid --exclude list."
    prefs_add "${EXCLUDE_IDS[@]}"
  fi
}

apply_selection_flags

if ((SELECT && !NO_INPUT)); then
  if selector_available; then
    log "Choose the components you want to keep."
    if selector_run; then
      :
    else
      status=$?
      if ((status == 2)); then
        error "Could not save component preferences."
      fi
      warn "Update cancelled."
      exit 0
    fi
  else
    warn "--select needs an interactive terminal; using saved preferences."
  fi
fi

log "Component selection:"
components_list

if ((DRY_RUN)); then
  log "Dry run: sudo and package changes are skipped."
else
  sudo -v || error "Sudo authentication failed."
fi

# ── 1. backup ─────────────────────────────────────────────────────────────────
log "Backing up the files that will be replaced to $BACKUP_DIR ..."
if ((!DRY_RUN)); then
  mkdir -p "$BACKUP_DIR"
fi

backup_enabled_paths

if component_enabled sddm && [ -f /etc/sddm.conf ]; then
  if ((DRY_RUN)); then
    printf '[dry-run] would back up /etc/sddm.conf\n'
  else
    cp -a /etc/sddm.conf "$BACKUP_DIR/sddm.conf.bak"
  fi
fi

if component_enabled sddm && [ -f "$SDDM_THEME_DIR/theme.conf" ]; then
  if ((DRY_RUN)); then
    printf '[dry-run] would back up %s/theme.conf\n' "$SDDM_THEME_DIR"
  else
    cp -a "$SDDM_THEME_DIR/theme.conf" "$BACKUP_DIR/sddm-theme.conf.bak" 2>/dev/null || true
  fi
fi

ok "Backup saved."

# ── 2. copy configuration ─────────────────────────────────────────────────────
log "Copying enabled components to ~/.config and ~/ ..."
copy_enabled_paths

# The shell history is user data, not configuration.
if component_enabled zsh && [ -f "$BACKUP_DIR/config/zsh/zhistory" ]; then
  if ((DRY_RUN)); then
    printf '[dry-run] would restore the zsh history\n'
  else
    cp -a "$BACKUP_DIR/config/zsh/zhistory" "$HOME/.config/zsh/zhistory"
  fi
fi

ok "Configuration updated."

# ── 3. dependencies ───────────────────────────────────────────────────────────
if ((NO_PACKAGES)); then
  warn "Skipping package updates (--no-packages)."
else
  log "Installing dependencies..."
  mapfile -t dependencies < <(filter_package_file "$REPO_DIR/packages.txt")
  if ((${#dependencies[@]})); then
    run sudo pacman -S --needed --noconfirm "${dependencies[@]}" ||
      warn "Some official packages could not be installed. Try: sudo pacman -Syu"
  fi

  mapfile -t aur_dependencies < <(filter_package_file "$REPO_DIR/packages-aur.txt")
  if ((${#aur_dependencies[@]})); then
    if command -v yay >/dev/null 2>&1; then
      run yay -S --needed --noconfirm "${aur_dependencies[@]}" ||
        warn "Some AUR packages could not be installed."
    elif ((DRY_RUN)); then
      printf '[dry-run] yay is not installed; would skip AUR packages\n'
    else
      warn "yay is not installed, skipping AUR dependencies."
    fi
  fi
fi

# ── 3.1. DDC/CI brightness (external monitors) ───────────────────────────────
if component_enabled ddc; then
  log "Configuring DDC/CI brightness support for external monitors..."
  if ((DRY_RUN)); then
    printf '[dry-run] would load i2c-dev and add %s to the i2c group\n' "$USER"
  else
    if echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null; then
      ok "i2c-dev will be loaded on boot."
    else
      warn "Could not write /etc/modules-load.d/i2c-dev.conf."
    fi
    sudo modprobe i2c-dev 2>/dev/null &&
      ok "i2c-dev loaded." ||
      warn "Could not load i2c-dev now; it will load after the reboot."

    if id -nG "$USER" | tr ' ' '\n' | grep -qx i2c; then
      ok "User $USER is already in the i2c group."
    else
      sudo groupadd -f i2c &&
        sudo usermod -aG i2c "$USER" &&
        ok "User $USER added to the i2c group (takes effect after logging out or rebooting)." ||
        warn "Could not add $USER to the i2c group."
    fi
  fi
else
  log "Skipping DDC/CI support (ddc component disabled)."
fi

# ── 4. SDDM theme ─────────────────────────────────────────────────────────────
# The theme is cloned as the user and deployed as plain files, so /usr/share
# never contains a root-owned git repository (no dubious ownership prompts).
if ! component_enabled sddm; then
  log "Skipping SDDM theme (sddm component disabled)."
elif ! command -v sddm >/dev/null 2>&1; then
  warn "SDDM is not installed, skipping theme update."
elif ((DRY_RUN)); then
  printf '[dry-run] would update the SDDM theme in %s\n' "$SDDM_THEME_DIR"
else
  log "Updating SDDM theme (minflair-sddm)..."
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  git clone --depth 1 https://github.com/t4lentles5/tokyo-night-sddm.git "$TMP_DIR/theme" ||
    error "Failed to clone the SDDM theme."

  rm -rf "$TMP_DIR/theme/.git"
  sudo mkdir -p "$SDDM_THEME_DIR"
  sudo cp -a "$TMP_DIR/theme/." "$SDDM_THEME_DIR/"
  sudo rm -rf "$SDDM_THEME_DIR/.git"
  sudo chown -R root:root "$SDDM_THEME_DIR"

  if [ -f "$REPO_DIR/etc/sddm.conf" ]; then
    sudo cp "$REPO_DIR/etc/sddm.conf" /etc/sddm.conf
  else
    warn "etc/sddm.conf not found in repo, keeping the current SDDM configuration."
  fi

  ok "SDDM theme updated."
fi

# ── 5. reapply theme & reload ─────────────────────────────────────────────────
if [ -f "$HOME/.cache/quickshell/colorscheme.json" ]; then
  log "Reapplying theme..."
  if ((DRY_RUN)); then
    printf '[dry-run] would reapply the theme for enabled components\n'
  else
    python3 "$HOME/.config/quickshell/Scripts/theme/apply_theme.py" ||
      warn "Theme could not be reapplied; it will be generated on next login."
  fi
else
  warn "No cached colorscheme found; the theme will be applied on next login."
fi

# Reload only the applications whose component is enabled.
run_reloads --non-core

if ((DRY_RUN)); then
  echo ""
  ok "Dry run complete. No files or packages were changed."
  log "Preferences that would be used: $PREFS_FILE"
  exit 0
fi

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  log "Reloading Hyprland and Quickshell..."
  hyprctl reload || warn "Could not reload Hyprland."
  killall qs 2>/dev/null || true
  sleep 0.5
  # Hyprland 0.55+ uses Lua config: dispatch expects a Lua expression.
  hyprctl dispatch 'hl.dsp.exec_cmd("qs")' ||
    warn "Could not restart Quickshell. Run 'qs' manually."
else
  warn "Hyprland session not detected; restart Quickshell manually."
fi

echo ""
ok "Update completed."
log "Backup saved at: $BACKUP_DIR"
