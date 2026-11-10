#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.minflair_backup/$(date +%Y%m%d_%H%M%S)"
SDDM_THEME_DIR="/usr/share/sddm/themes/minflair-sddm"
DRY_RUN=0
NO_INPUT=0
NO_PACKAGES=0
SELECT=0
AUR_HELPER=""
EXCLUDE_IDS=()
INCLUDE_IDS=()
ONLY_IDS=()

# ── shared UI helpers ────────────────────────────────────────────────────────
[ -f "$REPO_DIR/lib/ui.sh" ] ||
  { printf '[ERROR] lib/ui.sh not found. Are you running this from the Minflair repository?\n' >&2; exit 1; }
# shellcheck source=lib/ui.sh
source "$REPO_DIR/lib/ui.sh"
ui_init

cleanup() {
  if [[ -n "${DRY_PREFS:-}" ]]; then
    rm -f "$DRY_PREFS"
  fi
  if [[ -n "${TMP_DIR:-}" ]]; then
    rm -rf "$TMP_DIR"
  fi
  ui_cleanup
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

log() { ui_info "$1"; }
ok() { ui_ok "$1"; }
warn() { ui_warn "$1"; }
error() { ui_error "$1"; }

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
  --aur-helper NAME  Use yay or paru as the AUR helper (default: saved value)
  --dry-run          Show what would happen without changing anything
  --no-packages      Do not install or update packages
  -h, --help         Show this help

Examples:
  ./update.sh --dry-run
  ./update.sh --exclude nvim
  ./update.sh --include kitty
  ./update.sh --aur-helper paru
  ./update.sh --select
EOF
}

# ── shared component helpers ─────────────────────────────────────────────────
[ -f "$REPO_DIR/lib/components.sh" ] ||
  error "lib/components.sh not found. Are you running this from the Minflair repository?"
# shellcheck source=lib/components.sh
source "$REPO_DIR/lib/components.sh"
# shellcheck source=lib/aur.sh
[ -f "$REPO_DIR/lib/aur.sh" ] ||
  error "lib/aur.sh not found. Are you running this from the Minflair repository?"
source "$REPO_DIR/lib/aur.sh"
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
    --aur-helper)
      [[ $# -ge 2 ]] || error "--aur-helper requires yay or paru."
      AUR_HELPER="$2"
      shift 2
      ;;
    --aur-helper=*)
      AUR_HELPER="${1#*=}"
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

ui_header "Minflair updater $(minflair_version)"

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
fi

components_validate || error "The component manifest or preferences are invalid."

if [[ -n "$AUR_HELPER" ]]; then
  aur_helper_valid "$AUR_HELPER" || error "--aur-helper must be yay or paru."
fi

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

ui_section "Component selection"
components_summary
if component_enabled zsh; then
  log "zsh will be set as your login shell."
  if ! component_enabled starship; then
    warn "Starship is disabled; zsh will use a basic prompt."
  fi
fi

if [[ -n "$AUR_HELPER" ]]; then
  if ((DRY_RUN)); then
    printf '[dry-run] would save AUR helper: %s\n' "$AUR_HELPER"
  else
    aur_helper_set "$AUR_HELPER" || error "Could not save the AUR helper."
    log "AUR helper set to $AUR_HELPER."
  fi
else
  AUR_HELPER="$(aur_helper)"
fi

if ((DRY_RUN)); then
  log "Dry run: sudo and package changes are skipped."
else
  sudo -v || error "Sudo authentication failed."
fi

# ── 1. backup ─────────────────────────────────────────────────────────────────
ui_section "Backup"
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
ui_section "Dotfiles"
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
ui_section "Packages"
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
    if ((DRY_RUN)) || aur_helper_installed; then
      log "Installing AUR dependencies with $AUR_HELPER..."
      run "$AUR_HELPER" -S --needed --noconfirm "${aur_dependencies[@]}" ||
        warn "Some AUR packages could not be installed."
    else
      warn "$AUR_HELPER is not installed, skipping AUR dependencies."
    fi
  fi
fi

# ── 3.1. zsh login shell ─────────────────────────────────────────────────────
if ! component_enabled zsh; then
  log "Skipping zsh login shell (zsh component disabled)."
else
  log "Checking zsh login shell..."
  if ensure_zsh_login_shell; then
    ok "zsh is the default shell."
  else
    warn "Could not set zsh as the default shell. Run: sudo chsh -s $(command -v zsh || echo zsh) ${USER:-$(id -un)}"
  fi
fi

# ── 3.2. DDC/CI brightness (external monitors) ───────────────────────────────
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

# ── 3.3. Laptop battery charge limit ─────────────────────────────────────────
# install.sh provisions this on a fresh system. An update must do the same so
# enabling the battery component later still creates the sudoers rule and the
# vendor packages the toggle script needs.
if ! component_enabled battery; then
  log "Skipping battery management (battery component disabled)."
else
  VENDOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
  CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || true)"
  IS_LAPTOP=false
  if [[ "$CHASSIS" =~ ^(8|9|10|14|30|31|32)$ ]] ||
    [ -d /sys/class/power_supply/BAT0 ] ||
    [ -d /sys/class/power_supply/BAT1 ] ||
    [ -d /sys/class/power_supply/BAT ]; then
    IS_LAPTOP=true
  fi

  if [ "$IS_LAPTOP" != true ]; then
    log "No laptop battery detected, skipping battery management."
  elif ((DRY_RUN)); then
    printf '[dry-run] would configure battery management for %s\n' "${VENDOR:-Generic}"
  else
    if ((NO_PACKAGES)); then
      warn "Skipping vendor battery packages (--no-packages)."
    else
      if echo "$VENDOR" | grep -qi "acer"; then
        log "Acer laptop detected. Installing linux-headers and acer-wmi-battery-dkms..."
        sudo pacman -S --needed --noconfirm linux-headers || warn "Could not install linux-headers."
        "$AUR_HELPER" -S --needed --noconfirm acer-wmi-battery-dkms ||
          warn "Could not install acer-wmi-battery-dkms."
      fi

      if echo "$VENDOR" | grep -qi "dell"; then
        log "Dell laptop detected. Installing libsmbios for battery management support..."
        sudo pacman -S --needed --noconfirm libsmbios || warn "Could not install libsmbios."
      fi
    fi

    log "Configuring sudoers for battery charge limit script..."
    echo "$USER ALL=(ALL) NOPASSWD: $HOME/.config/quickshell/Scripts/system/toggle_battery_limit.sh" |
      sudo tee /etc/sudoers.d/quickshell-battery >/dev/null
    sudo chmod 0440 /etc/sudoers.d/quickshell-battery
    ok "Battery charge limit support and sudoers configured."
  fi
fi

# ── 3.4. Node.js LTS via fnm ─────────────────────────────────────────────────
if ((NO_PACKAGES)); then
  log "Skipping Node.js update (--no-packages)."
elif ((DRY_RUN)); then
  printf '[dry-run] would install Node.js LTS with fnm\n'
elif command -v fnm &>/dev/null; then
  log "Installing Node.js LTS with fnm..."
  export FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
  eval "$(fnm env)"
  fnm install --lts || warn "Could not install Node.js LTS."
  fnm use lts-latest || warn "Could not activate Node.js LTS."
  ok "Node.js LTS installed: $(node --version 2>/dev/null || echo 'restart your terminal to activate it')."
else
  warn "fnm not found in PATH. Make sure ~/.local/bin is in your PATH and re-run."
fi

# ── 4. Themes ───────────────────────────────────────────────────────────────
ui_section "Theme and desktop"
# Reinstalling or enabling the gtk component after the initial install must
# still provision the theme, otherwise gtk.py has no gtk.css to import its
# generated colors.css from.
if component_enabled gtk; then
  log "Installing Material-Gnome theme..."
  if ensure_gtk_theme; then
    ok "Material-Gnome theme is ready."
  else
    warn "Could not install the Material-Gnome theme; GTK colors may not apply."
  fi
else
  log "Skipping GTK theme (gtk component disabled)."
fi

# The SDDM theme is cloned as the user and deployed as plain files, so
# /usr/share never contains a root-owned git repository (no dubious ownership
# prompts).
if ! component_enabled sddm; then
  log "Skipping SDDM theme (sddm component disabled)."
elif ! command -v sddm >/dev/null 2>&1; then
  warn "SDDM is not installed, skipping theme update."
elif ((DRY_RUN)); then
  printf '[dry-run] would update the SDDM theme in %s\n' "$SDDM_THEME_DIR"
else
  log "Updating SDDM theme (minflair-sddm)..."
  TMP_DIR="$(mktemp -d)"

  git clone --depth 1 https://github.com/t4lentles5/tokyo-night-sddm.git "$TMP_DIR/theme" ||
    error "Failed to clone the SDDM theme."

  rm -rf "$TMP_DIR/theme/.git"
  sudo mkdir -p "$SDDM_THEME_DIR"
  sudo cp -a "$TMP_DIR/theme/." "$SDDM_THEME_DIR/"
  sudo rm -rf "$SDDM_THEME_DIR/.git"
  sudo chown -R root:root "$SDDM_THEME_DIR"

  if ! sddm_theme_ready "$SDDM_THEME_DIR"; then
    warn "SDDM theme files are missing; keeping the current /etc/sddm.conf."
  elif [ -f "$REPO_DIR/etc/sddm.conf" ]; then
    sudo cp "$REPO_DIR/etc/sddm.conf" /etc/sddm.conf
  else
    warn "etc/sddm.conf not found in repo, keeping the current SDDM configuration."
  fi

  ok "SDDM theme updated."
fi

# ── 4.1. dunst notifications ─────────────────────────────────────────────────
# The dunst component means "disable dunst". install.sh only handles it on a
# fresh install, so an update must mask it when enabled and restore it when the
# component is disabled again.
DUNST_DBUS_SERVICE="/usr/share/dbus-1/services/org.knopwob.dunst.service"
if ((DRY_RUN)); then
  if component_enabled dunst; then
    printf '[dry-run] would mask dunst and disable its D-Bus activation\n'
  else
    printf '[dry-run] would restore dunst\n'
  fi
elif component_enabled dunst; then
  if command -v dunst &>/dev/null; then
    log "Disabling dunst (notifications are managed by QuickShell)..."
    killall dunst 2>/dev/null && ok "Stopped running dunst process." || true
    systemctl --user mask dunst.service 2>/dev/null &&
      ok "dunst.service masked." ||
      warn "Could not mask dunst.service (may not exist as a systemd service)."
    if [ -f "$DUNST_DBUS_SERVICE" ]; then
      if sudo mv "$DUNST_DBUS_SERVICE" "${DUNST_DBUS_SERVICE}.disabled"; then
        ok "dunst D-Bus activation disabled."
      else
        warn "Could not disable the dunst D-Bus activation."
      fi
    fi
    ok "dunst disabled - QuickShell will handle notifications."
  else
    ok "dunst is not installed, no conflicts."
  fi
else
  log "Restoring dunst (dunst component disabled)..."
  systemctl --user unmask dunst.service 2>/dev/null || true
  if [ -f "${DUNST_DBUS_SERVICE}.disabled" ]; then
    if sudo mv "${DUNST_DBUS_SERVICE}.disabled" "$DUNST_DBUS_SERVICE"; then
      ok "dunst D-Bus activation restored."
    else
      warn "Could not restore the dunst D-Bus activation."
    fi
  fi
  ok "dunst restored."
fi

# ── 4.2. system services ─────────────────────────────────────────────────────
if ! component_enabled services; then
  log "Skipping system services (services component disabled)."
elif ((DRY_RUN)); then
  printf '[dry-run] would enable NetworkManager, bluetooth and power-profiles-daemon\n'
else
  log "Checking and enabling system services (NetworkManager, bluetooth, power-profiles-daemon)..."
  for svc in NetworkManager.service bluetooth.service power-profiles-daemon.service; do
    if ! systemctl is-enabled --quiet "$svc" 2>/dev/null ||
      ! systemctl is-active --quiet "$svc" 2>/dev/null; then
      log "Enabling and starting $svc..."
      run sudo systemctl enable --now "$svc" || warn "Failed to enable $svc."
    else
      ok "$svc is already enabled and running."
    fi
  done
fi

# ── 5. reapply theme & reload ─────────────────────────────────────────────────
ui_section "Reload"
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
  ui_done "Dry run complete. No files or packages were changed."
  log "Preferences that would be used: $PREFS_FILE"
  ui_section "Selection preview"
  components_summary
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

ui_finish "Update complete"
ui_ok "Backup saved at: $BACKUP_DIR"
components_summary
ui_next_steps \
  "Restart your session if the reload was skipped." \
  "Review docs/SETUP.md after major updates."
