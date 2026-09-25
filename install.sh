#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Require sudo password upfront and keep it alive
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &
ERROR_LOG="$HOME/install_errors.log"
>"$ERROR_LOG"
exec 3>&2
exec 2> >(tee /dev/fd/3 | sed -u -r 's/\x1b\[[0-9;]*[mK]//g; s/\r/\n/g' | sed -u 's/^[[:space:]]*//; /^$/d' | grep --line-buffered -iE 'error|fail|warn|conflict|fatal' >>"$ERROR_LOG")

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

# ── 1. yay ───────────────────────────────────────────────────────────────────
log "Installing yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm git base-devel
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  ok "yay installed."
else
  ok "yay is already installed, skipping."
fi

# ── 2. official dependencies ──────────────────────────────────────────────────
log "Installing dependencies from official repositories..."
dependencies=(
  hyprland kitty openssh polkit-kde-agent qt5-wayland qt6-wayland
  smartmontools uwsm vim wget wireless_tools xdg-desktop-portal-hyprland
  xdg-utils bat bc btop cava eza fd fzf gnome-calculator gnome-font-viewer
  gnome-disk-utility gvfs gvfs-mtp highlight hypridle hyprpicker
  hyprsunset imagemagick inetutils iwd jq lazygit loupe nautilus network-manager-applet
  networkmanager noto-fonts-emoji nwg-look openssl pacman-contrib pamixer pavucontrol
  pipewire pipewire-alsa pipewire-audio pipewire-pulse python-gobject python-pygments
  python-pip rfkill ripgrep starship ttf-cascadia-code-nerd ttf-jetbrains-mono-nerd
  tumbler unzip upower wireplumber wl-clipboard wlsunset libmtp
  xclip xdg-desktop-portal-gtk zsh zsh-autosuggestions zsh-history-substring-search
  zsh-syntax-highlighting brightnessctl blueman bluez bluez-utils grim slurp cliphist
  fastfetch neovim curl unrar socat qt6-imageformats mpv fnm polkit-gnome ntfs-3g libnotify
  gnome-keyring libsecret awww playerctl ffmpeg exfatprogs dosfstools gvfs-afc power-profiles-daemon
  sof-firmware gamemode python-pam less qt5ct qt6ct papirus-icon-theme wf-recorder
  tesseract tesseract-data-eng tesseract-data-spa tree-sitter-cli
  noto-fonts ttf-liberation ttf-roboto
)

sudo pacman -S --needed --noconfirm "${dependencies[@]}" ||
  warn "Some official packages could not be installed (check the messages above)."
ok "Official dependencies processed."

# ── 3. AUR dependencies ───────────────────────────────────────────────────────
log "Installing AUR dependencies..."
aur_dependencies=(
  bibata-cursor-theme-bin
  fzf-tab-git
  quickshell
  sddm-theme-tokyo-night-git
  tela-circle-icon-theme-dracula-git
  xxhash
  otf-geist
)

yay -S --needed --noconfirm "${aur_dependencies[@]}" ||
  warn "Some AUR packages could not be installed (check the messages above)."
ok "AUR dependencies processed."

# ── 3.1. Laptop & Vendor specific dependencies (Battery charge limit) ────────
VENDOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
CHASSIS="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || true)"
IS_LAPTOP=false

if [[ "$CHASSIS" =~ ^(8|9|10|14|30|31|32)$ ]] || [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ] || [ -d /sys/class/power_supply/BAT ]; then
  IS_LAPTOP=true
fi

if [ "$IS_LAPTOP" = true ]; then
  log "Laptop hardware detected (${VENDOR:-Generic}). Configuring battery management..."

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

  # Configure sudoers rule so Quickshell can toggle battery limits without password prompts
  log "Configuring sudoers for battery charge limit script..."
  echo "$USER ALL=(ALL) NOPASSWD: $HOME/.config/quickshell/Scripts/toggle_battery_limit.sh" | sudo tee /etc/sudoers.d/quickshell-battery >/dev/null
  sudo chmod 0440 /etc/sudoers.d/quickshell-battery
  ok "Battery charge limit support and sudoers configured."
fi

# ── 4. backup & copy dotfiles ─────────────────────────────────────────────────
log "Backing up existing dotfiles to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"

# config/ → ~/.config/ (backup only folders that exist in repo)
if [ -d "$REPO_DIR/config" ]; then
  mkdir -p "$BACKUP_DIR/config"

  # Pass 1: backup existing configs
  while IFS= read -r -d '' dir; do
    rel="${dir#$REPO_DIR/config/}"
    dest="$HOME/.config/$rel"
    if [ -e "$dest" ]; then
      mkdir -p "$BACKUP_DIR/config/$(dirname "$rel")"
      cp -a "$dest" "$BACKUP_DIR/config/$rel"
    fi
  done < <(find "$REPO_DIR/config" -maxdepth 1 -mindepth 1 -print0)
  ok "Conflicting configs backed up to $BACKUP_DIR/config"

  # Pass 2: copy new configs
  while IFS= read -r -d '' dir; do
    cp -a "$dir" "$HOME/.config/"
  done < <(find "$REPO_DIR/config" -maxdepth 1 -mindepth 1 -print0)
  ok "config/ → ~/.config/"
else
  warn "config/ not found in repo, skipping."
fi

# home/ → ~/ (only the files that exist in the repo, not all of $HOME)
if [ -d "$REPO_DIR/home" ]; then
  mkdir -p "$BACKUP_DIR/home"

  # Pass 1: backup existing home files
  while IFS= read -r -d '' file; do
    rel="${file#$REPO_DIR/home/}"
    dest="$HOME/$rel"
    if [ -e "$dest" ]; then
      mkdir -p "$BACKUP_DIR/home/$(dirname "$rel")"
      cp -a "$dest" "$BACKUP_DIR/home/$rel"
    fi
  done < <(find "$REPO_DIR/home" -maxdepth 1 -mindepth 1 -print0)
  ok "Conflicting home files backed up to $BACKUP_DIR/home"

  # Pass 2: copy new home files
  while IFS= read -r -d '' file; do
    rel="${file#$REPO_DIR/home/}"
    dest="$HOME/$rel"
    mkdir -p "$HOME/$(dirname "$rel")"
    cp -a "$file" "$dest"
  done < <(find "$REPO_DIR/home" -maxdepth 1 -mindepth 1 -print0)
  ok "home/ → ~/"
else
  warn "home/ not found in repo, skipping."
fi

# ── 4.1. quickshell applications ──────────────────────────────────────────────
log "Installing Quickshell desktop entries..."
if [ -d "$REPO_DIR/config/quickshell/Applications" ]; then
  mkdir -p "$HOME/.local/share/applications"
  cp -a "$REPO_DIR/config/quickshell/Applications/." "$HOME/.local/share/applications/"
  ok "Quickshell desktop entries copied to ~/.local/share/applications/"
else
  warn "config/quickshell/Applications not found, skipping."
fi

# ── 5. apply GTK theme via gsettings ──────────────────────────────────────────
log "Installing Material-Gnome theme..."
if [ ! -d "$HOME/.themes/Material-Gnome" ]; then
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
  if [ -n "$gtk_theme" ]; then gsettings set "$SCHEMA" gtk-theme "$gtk_theme" 2>/dev/null || true; fi

  icon_theme=$(grep 'gtk-icon-theme-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
  if [ -n "$icon_theme" ]; then gsettings set "$SCHEMA" icon-theme "$icon_theme" 2>/dev/null || true; fi

  cursor_theme=$(grep 'gtk-cursor-theme-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
  if [ -n "$cursor_theme" ]; then gsettings set "$SCHEMA" cursor-theme "$cursor_theme" 2>/dev/null || true; fi

  font_name=$(grep 'gtk-font-name' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
  if [ -n "$font_name" ]; then gsettings set "$SCHEMA" font-name "$font_name" 2>/dev/null || true; fi

  color_scheme=$(grep 'gtk-application-prefer-dark-theme' "$HOME/.config/gtk-3.0/settings.ini" | cut -d'=' -f2)
  if [ "$color_scheme" = "1" ]; then
    gsettings set "$SCHEMA" color-scheme "prefer-dark" 2>/dev/null || true
  else
    gsettings set "$SCHEMA" color-scheme "default" 2>/dev/null || true
  fi

  ok "GTK theme applied via gsettings."
else
  warn "gtk-3.0/settings.ini not found, skipping gsettings."
fi

# ── 6. SDDM theme ─────────────────────────────────────────────────────────────
log "Configuring SDDM theme..."
if [ -f "$REPO_DIR/etc/sddm.conf" ]; then
  if [ -f /etc/sddm.conf ]; then
    cp /etc/sddm.conf "$BACKUP_DIR/sddm.conf.bak"
    ok "Existing /etc/sddm.conf backed up."
  fi
  sudo cp "$REPO_DIR/etc/sddm.conf" /etc/sddm.conf
  ok "SDDM theme set to tokyo-night."
else
  warn "etc/sddm.conf not found in repo, skipping SDDM config."
fi

# ── 7. disable dunst (notifications handled by QuickShell) ────────────────────
log "Disabling dunst (notifications are managed by QuickShell)..."
if command -v dunst &>/dev/null; then
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

# ── 8. zsh shell (mandatory) ──────────────────────────────────────────────────
log "Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)" || error "Could not change shell to zsh. Run manually: chsh -s \$(which zsh)"
  ok "Shell changed to zsh."
else
  ok "zsh is already the default shell."
fi

# ── 9. Node.js LTS via fnm ────────────────────────────────────────────────────
log "Installing Node.js LTS with fnm..."
if command -v fnm &>/dev/null; then
  export FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
  eval "$(fnm env)"
  fnm install --lts
  fnm use lts-latest
  ok "Node.js LTS installed: $(node --version 2>/dev/null || echo 'restart your terminal to activate it')."
else
  warn "fnm not found in PATH. Make sure ~/.local/bin is in your PATH and re-run."
fi

# ── 10. Enable system services ────────────────────────────────────────────────
log "Checking and enabling system services (NetworkManager, bluetooth, power-profiles-daemon)..."

for svc in NetworkManager.service bluetooth.service power-profiles-daemon.service; do
  if ! systemctl is-enabled --quiet "$svc" 2>/dev/null || ! systemctl is-active --quiet "$svc" 2>/dev/null; then
    log "Enabling and starting $svc..."
    sudo systemctl enable --now "$svc" || warn "Failed to enable $svc."
  else
    ok "$svc is already enabled and running."
  fi
done

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation completed successfully     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
log "Backup saved at: $BACKUP_DIR"
echo ""
read -p "$(echo -e "${YELLOW}[?] Do you want to reboot now? [y/N] ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  log "Rebooting system..."
  sudo reboot
else
  warn "Please remember to reboot your computer later for all changes to take effect."
fi
