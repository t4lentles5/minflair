#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.minflair_backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0
NO_INPUT=0
NO_PACKAGES=0
SELECT=0
SKIP_CHSH=0
CHSH_READY=0
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
Usage: ./install.sh [options]

Install Minflair. With no options and an interactive terminal, the component
selector opens first. Preferences are saved in ~/.config/minflair/preferences.conf
and are respected by install.sh, update.sh and the runtime theme scripts.

Selection:
  --exclude IDS    Disable components (comma-separated, repeatable)
  --only IDS       Enable only these optional components (plus core)
  --include IDS    Re-enable components that were previously disabled
  --select         Open the interactive selector
  --no-input       Never prompt; use the saved preferences

Behaviour:
  --dry-run        Show what would happen without changing anything
  --no-packages    Do not install or update packages
  -h, --help       Show this help

Examples:
  ./install.sh --exclude kitty,nvim,starship
  ./install.sh --only quickshell,hyprland,kitty
  ./install.sh --dry-run --exclude nvim
  ./install.sh --no-input --no-packages
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
  error "Run install.sh as your normal user, not as root."
fi

ui_header "Minflair installer" "Version $(minflair_version)"

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

HAS_SELECTION_FLAGS=0
if ((${#EXCLUDE_IDS[@]} || ${#INCLUDE_IDS[@]} || ${#ONLY_IDS[@]})); then
  HAS_SELECTION_FLAGS=1
fi

if ((NO_INPUT)); then
  log "Using saved component preferences."
elif ((SELECT)) || { ((!HAS_SELECTION_FLAGS)) && selector_available; }; then
  if selector_available; then
    log "Choose the components you want to install."
    if selector_run; then
      :
    else
      status=$?
      if ((status == 2)); then
        error "Could not save component preferences."
      fi
      warn "Installation cancelled."
      exit 0
    fi
  elif ((SELECT)); then
    warn "--select needs an interactive terminal; using saved preferences."
  fi
else
  if ((HAS_SELECTION_FLAGS)); then
    log "Using the selection from the command line."
  else
    warn "No interactive terminal detected; using saved preferences."
    warn "Pass --exclude/--only to choose components non-interactively."
  fi
fi

ui_section "Component selection"
components_summary

# ── preflight ────────────────────────────────────────────────────────────────
for cmd in awk grep sed cut sort mktemp; do
  command -v "$cmd" >/dev/null 2>&1 ||
    error "Missing required command: $cmd"
done
[[ -f "$MANIFEST" ]] || error "Component manifest not found: $MANIFEST"

# Require sudo password upfront and keep it alive
if ((DRY_RUN)); then
  log "Dry run: sudo and package changes are skipped."
else
  sudo -v || error "Sudo authentication failed."
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
fi

ERROR_LOG="$HOME/install_errors.log"
>"$ERROR_LOG"
exec 3>&2
exec 2> >(tee /dev/fd/3 | sed -u -r 's/\x1b\[[0-9;]*[mK]//g; s/\r/\n/g' | sed -u 's/^[[:space:]]*//; /^$/d' | grep --line-buffered -iE 'error|fail|warn|conflict|fatal' >>"$ERROR_LOG")

# ── 1. yay ───────────────────────────────────────────────────────────────────
ui_section "Packages"
if ((NO_PACKAGES)); then
  warn "Skipping yay and package installation (--no-packages)."
else
  log "Installing yay (AUR helper)..."
  if ((DRY_RUN)); then
    printf '[dry-run] would install yay if it is missing\n'
  elif ! command -v yay &>/dev/null; then
    run sudo pacman -S --needed --noconfirm git base-devel
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    ok "yay installed."
  else
    ok "yay is already installed, skipping."
  fi

  # ── 2. official dependencies ────────────────────────────────────────────────
  log "Installing dependencies from official repositories..."
  mapfile -t dependencies < <(filter_package_file "$REPO_DIR/packages.txt")
  if ((${#dependencies[@]})); then
    run sudo pacman -S --needed --noconfirm "${dependencies[@]}" ||
      warn "Some official packages could not be installed (check the messages above)."
    ok "Official dependencies processed."
  else
    warn "No official packages selected."
  fi

  # ── 3. AUR dependencies ─────────────────────────────────────────────────────
  log "Installing AUR dependencies..."
  mapfile -t aur_dependencies < <(filter_package_file "$REPO_DIR/packages-aur.txt")
  if ((${#aur_dependencies[@]})); then
    run yay -S --needed --noconfirm "${aur_dependencies[@]}" ||
      warn "Some AUR packages could not be installed (check the messages above)."
    ok "AUR dependencies processed."
  else
    warn "No AUR packages selected."
  fi
fi

# ── 3.1. DDC/CI brightness (external monitors) ───────────────────────────────
ui_section "System integration"
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

# ── 3.2. Laptop & Vendor specific dependencies (Battery charge limit) ────────
VENDOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || true)"
IS_LAPTOP=false

if [[ "$CHASSIS" =~ ^(8|9|10|14|30|31|32)$ ]] || [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ] || [ -d /sys/class/power_supply/BAT ]; then
  IS_LAPTOP=true
fi

if ! component_enabled battery; then
  log "Skipping battery management (battery component disabled)."
elif [ "$IS_LAPTOP" = true ]; then
  log "Laptop hardware detected (${VENDOR:-Generic}). Configuring battery management..."

  if ((DRY_RUN)); then
    printf '[dry-run] would configure battery management for %s\n' "${VENDOR:-Generic}"
  else
    if ((NO_PACKAGES)); then
      warn "Skipping vendor battery packages (--no-packages)."
    else
      # Acer laptops
      if echo "$VENDOR" | grep -qi "acer"; then
        log "Acer laptop detected. Installing linux-headers and acer-wmi-battery-dkms..."
        sudo pacman -S --needed --noconfirm linux-headers || warn "Could not install linux-headers."
        yay -S --needed --noconfirm acer-wmi-battery-dkms || warn "Could not install acer-wmi-battery-dkms."
      fi

      # Dell laptops
      if echo "$VENDOR" | grep -qi "dell"; then
        log "Dell laptop detected. Installing libsmbios for battery management support..."
        sudo pacman -S --needed --noconfirm libsmbios || warn "Could not install libsmbios."
      fi
    fi

    # Configure sudoers rule so Quickshell can toggle battery limits without password prompts
    log "Configuring sudoers for battery charge limit script..."
    echo "$USER ALL=(ALL) NOPASSWD: $HOME/.config/quickshell/Scripts/system/toggle_battery_limit.sh" | sudo tee /etc/sudoers.d/quickshell-battery >/dev/null
    sudo chmod 0440 /etc/sudoers.d/quickshell-battery
    ok "Battery charge limit support and sudoers configured."
  fi
else
  log "No laptop battery detected, skipping battery management."
fi

# ── 4. backup & copy dotfiles ─────────────────────────────────────────────────
ui_section "Dotfiles"
log "Backing up existing dotfiles to $BACKUP_DIR ..."
if ((!DRY_RUN)); then
  mkdir -p "$BACKUP_DIR"
fi
backup_enabled_paths
ok "Enabled component files backed up."

log "Copying enabled components to ~/.config and ~/ ..."
copy_enabled_paths
ok "Enabled component files copied."

# ── 5. apply GTK theme via gsettings ──────────────────────────────────────────
ui_section "Theme and desktop"
if component_enabled gtk; then
  log "Installing Material-Gnome theme..."
  if ((DRY_RUN)); then
    printf '[dry-run] would install Material-Gnome theme if missing\n'
  elif [ ! -d "$HOME/.themes/Material-Gnome" ]; then
    mkdir -p "$HOME/.themes"
    git clone https://github.com/t4lentles5/material-gnome-theme.git "$HOME/.themes/Material-Gnome"
    ok "Material-Gnome theme installed."
  else
    ok "Material-Gnome theme already installed."
  fi

  log "Applying GTK theme..."
  if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    SCHEMA="org.gnome.desktop.interface"

    gtk_theme=$(grep 'gtk-theme-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
    if [ -n "$gtk_theme" ]; then run gsettings set "$SCHEMA" gtk-theme "$gtk_theme" 2>/dev/null || true; fi

    icon_theme=$(grep 'gtk-icon-theme-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
    if [ -n "$icon_theme" ]; then run gsettings set "$SCHEMA" icon-theme "$icon_theme" 2>/dev/null || true; fi

    cursor_theme=$(grep 'gtk-cursor-theme-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
    if [ -n "$cursor_theme" ]; then run gsettings set "$SCHEMA" cursor-theme "$cursor_theme" 2>/dev/null || true; fi

    font_name=$(grep 'gtk-font-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
    if [ -n "$font_name" ]; then run gsettings set "$SCHEMA" font-name "$font_name" 2>/dev/null || true; fi

    color_scheme=$(grep 'gtk-application-prefer-dark-theme' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
    if [ "$color_scheme" = "1" ]; then
      run gsettings set "$SCHEMA" color-scheme "prefer-dark" 2>/dev/null || true
    else
      run gsettings set "$SCHEMA" color-scheme "default" 2>/dev/null || true
    fi

    ok "GTK theme applied via gsettings."
  else
    warn "gtk-3.0/settings.ini not found, skipping gsettings."
  fi
else
  log "Skipping GTK theme (gtk component disabled)."
fi

# ── 6. SDDM theme ─────────────────────────────────────────────────────────────
SDDM_THEME_DIR="/usr/share/sddm/themes/minflair-sddm"

if ! component_enabled sddm; then
  log "Skipping SDDM theme (sddm component disabled)."
elif ((DRY_RUN)); then
  printf '[dry-run] would install the SDDM theme in %s\n' "$SDDM_THEME_DIR"
  printf '[dry-run] would write /etc/sddm.conf\n'
else
  log "Configuring SDDM theme..."
  if [ ! -d "$SDDM_THEME_DIR" ]; then
    sudo mkdir -p /usr/share/sddm/themes
    sudo git clone --depth 1 https://github.com/t4lentles5/tokyo-night-sddm.git "$SDDM_THEME_DIR" &&
      ok "SDDM theme (minflair-sddm) installed." ||
      warn "Failed to clone SDDM theme."
  else
    if [ -d "$SDDM_THEME_DIR/.git" ]; then
      sudo git -C "$SDDM_THEME_DIR" remote set-url origin https://github.com/t4lentles5/tokyo-night-sddm.git 2>/dev/null || true
      sudo git -C "$SDDM_THEME_DIR" pull --ff-only 2>/dev/null &&
        ok "SDDM theme (minflair-sddm) updated." ||
        ok "SDDM theme (minflair-sddm) already up to date."
    else
      sudo rm -rf "$SDDM_THEME_DIR"
      sudo git clone --depth 1 https://github.com/t4lentles5/tokyo-night-sddm.git "$SDDM_THEME_DIR" &&
        ok "SDDM theme (minflair-sddm) reinstalled." ||
        warn "Failed to clone SDDM theme."
    fi
  fi

  if [ -f "$REPO_DIR/etc/sddm.conf" ]; then
    if [ -f /etc/sddm.conf ]; then
      cp /etc/sddm.conf "$BACKUP_DIR/sddm.conf.bak"
      ok "Existing /etc/sddm.conf backed up."
    fi
    sudo cp "$REPO_DIR/etc/sddm.conf" /etc/sddm.conf
    ok "SDDM theme set to minflair-sddm."
  else
    warn "etc/sddm.conf not found in repo, skipping SDDM config."
  fi
fi

# ── 7. disable dunst (notifications handled by QuickShell) ────────────────────
if ! component_enabled dunst; then
  log "Skipping dunst configuration (dunst component disabled)."
elif ((DRY_RUN)); then
  printf '[dry-run] would mask dunst and disable its D-Bus activation\n'
elif command -v dunst &>/dev/null; then
  log "Disabling dunst (notifications are managed by QuickShell)..."

  # Kill any running dunst instance
  killall dunst 2>/dev/null && ok "Stopped running dunst process."

  # Mask the systemd user service so it never starts again
  systemctl --user mask dunst.service 2>/dev/null &&
    ok "dunst.service masked." ||
    warn "Could not mask dunst.service (may not exist as a systemd service)."

  # Disable D-Bus activation if the service file exists
  DBUS_SERVICE="/usr/share/dbus-1/services/org.knopwob.dunst.service"
  if [ -f "$DBUS_SERVICE" ]; then
    sudo mv "$DBUS_SERVICE" "${DBUS_SERVICE}.disabled"
    ok "dunst D-Bus activation disabled."
  fi

  ok "dunst disabled — QuickShell will handle notifications."
else
  ok "dunst is not installed, no conflicts."
fi

# ── 8. zsh shell ──────────────────────────────────────────────────────────────
if ! component_enabled chsh; then
  log "Skipping login shell change (chsh component disabled)."
elif command -v zsh >/dev/null 2>&1; then
  CHSH_READY=1
elif ((NO_PACKAGES)); then
  warn "zsh is not installed and --no-packages is set; skipping the login shell change."
  SKIP_CHSH=1
else
  log "Installing zsh for the login shell change..."
  run sudo pacman -S --needed --noconfirm zsh || warn "Could not install zsh."
  if ((DRY_RUN)) || command -v zsh >/dev/null 2>&1; then
    CHSH_READY=1
  fi
fi

if component_enabled chsh && ((!SKIP_CHSH)) && ((CHSH_READY)); then
  log "Setting zsh as default shell..."
  if ((DRY_RUN)); then
    printf '[dry-run] would run chsh -s %s\n' "$(command -v zsh || echo zsh)"
  elif [ "$SHELL" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)" || error "Could not change shell to zsh. Run manually: chsh -s \$(which zsh)"
    ok "Shell changed to zsh."
  else
    ok "zsh is already the default shell."
  fi
fi

# ── 9. Node.js LTS via fnm ────────────────────────────────────────────────────
if ((NO_PACKAGES)); then
  log "Skipping Node.js installation (--no-packages)."
elif ((DRY_RUN)); then
  printf '[dry-run] would install Node.js LTS with fnm\n'
elif command -v fnm &>/dev/null; then
  log "Installing Node.js LTS with fnm..."
  export FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
  eval "$(fnm env)"
  fnm install --lts
  fnm use lts-latest
  ok "Node.js LTS installed: $(node --version 2>/dev/null || echo 'restart your terminal to activate it')."
else
  warn "fnm not found in PATH. Make sure ~/.local/bin is in your PATH and re-run."
fi

# ── 10. Enable system services ────────────────────────────────────────────────
ui_section "Services"
if ! component_enabled services; then
  log "Skipping system services (services component disabled)."
else
  log "Checking and enabling system services (NetworkManager, bluetooth, power-profiles-daemon)..."

  for svc in NetworkManager.service bluetooth.service power-profiles-daemon.service; do
    if ! systemctl is-enabled --quiet "$svc" 2>/dev/null || ! systemctl is-active --quiet "$svc" 2>/dev/null; then
      log "Enabling and starting $svc..."
      run sudo systemctl enable --now "$svc" || warn "Failed to enable $svc."
    else
      ok "$svc is already enabled and running."
    fi
  done
fi

# ── 11. reload enabled applications ───────────────────────────────────────────
run_reloads --non-core

if ((DRY_RUN)); then
  echo ""
  ui_done "Dry run complete. No files or packages were changed."
  log "Preferences that would be used: $PREFS_FILE"
  ui_section "Selection preview"
  components_summary
  exit 0
fi

echo ""
ui_section "Installation complete"
ui_ok "Backup saved at: $BACKUP_DIR"
components_summary
echo ""
ui_info "Next steps:"
printf '  1. Reboot to apply every change.\n'
printf '  2. Add wallpapers and review docs/SETUP.md.\n'
printf '  3. Pull new changes and run ./update.sh when needed.\n'
echo ""
if ((NO_INPUT)); then
  ui_warn "Please remember to reboot later for all changes to take effect."
elif ui_confirm "Reboot now?" n; then
  log "Rebooting system..."
  sudo reboot
else
  ui_warn "Please remember to reboot later for all changes to take effect."
fi
