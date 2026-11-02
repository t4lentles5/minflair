#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
SDDM_THEME_DIR="/usr/share/sddm/themes/minflair-sddm"

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

if [ "$(id -u)" -eq 0 ]; then
  error "Run update.sh as your normal user, not as root."
fi

cd "$REPO_DIR"

[ -f "$REPO_DIR/packages.txt" ] || error "packages.txt not found. Are you running this from the Minflair repository?"
[ -f "$REPO_DIR/packages-aur.txt" ] || error "packages-aur.txt not found."
[ -d "$REPO_DIR/config" ] || error "config/ not found."
[ -d "$HOME/.config/quickshell" ] || error "Quickshell config not found in ~/.config. Run install.sh first."

sudo -v || error "Sudo authentication failed."

# ── 1. backup ─────────────────────────────────────────────────────────────────
log "Backing up the files that will be replaced to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"

while IFS= read -r -d '' entry; do
  rel="${entry#$REPO_DIR/config/}"
  dest="$HOME/.config/$rel"
  if [ -e "$dest" ]; then
    mkdir -p "$BACKUP_DIR/config"
    cp -a "$dest" "$BACKUP_DIR/config/"
  fi
done < <(find "$REPO_DIR/config" -maxdepth 1 -mindepth 1 -print0)

while IFS= read -r -d '' entry; do
  rel="${entry#$REPO_DIR/home/}"
  dest="$HOME/$rel"
  if [ -e "$dest" ]; then
    mkdir -p "$BACKUP_DIR/home"
    cp -a "$dest" "$BACKUP_DIR/home/"
  fi
done < <(find "$REPO_DIR/home" -maxdepth 1 -mindepth 1 -print0)

if [ -f /etc/sddm.conf ]; then
  cp -a /etc/sddm.conf "$BACKUP_DIR/sddm.conf.bak"
fi

if [ -f "$SDDM_THEME_DIR/theme.conf" ]; then
  cp -a "$SDDM_THEME_DIR/theme.conf" "$BACKUP_DIR/sddm-theme.conf.bak" 2>/dev/null || true
fi

ok "Backup saved."

# ── 2. copy configuration ─────────────────────────────────────────────────────
log "Copying configuration to ~/.config and ~/ ..."
cp -a "$REPO_DIR/config/." "$HOME/.config/"
cp -a "$REPO_DIR/home/." "$HOME/"

# The shell history is user data, not configuration.
if [ -f "$BACKUP_DIR/config/zsh/zhistory" ]; then
  cp -a "$BACKUP_DIR/config/zsh/zhistory" "$HOME/.config/zsh/zhistory"
fi

ok "Configuration updated."

# ── 3. dependencies ───────────────────────────────────────────────────────────
log "Installing dependencies..."
mapfile -t dependencies < <(grep -vE '^\s*(#|$)' "$REPO_DIR/packages.txt")
sudo pacman -S --needed --noconfirm "${dependencies[@]}" ||
  warn "Some official packages could not be installed. Try: sudo pacman -Syu"

mapfile -t aur_dependencies < <(grep -vE '^\s*(#|$)' "$REPO_DIR/packages-aur.txt")
if command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm "${aur_dependencies[@]}" ||
    warn "Some AUR packages could not be installed."
else
  warn "yay is not installed, skipping AUR dependencies."
fi

# ── 3.1. DDC/CI brightness (external monitors) ───────────────────────────────
log "Configuring DDC/CI brightness support for external monitors..."
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

# ── 4. SDDM theme ─────────────────────────────────────────────────────────────
# The theme is cloned as the user and deployed as plain files, so /usr/share
# never contains a root-owned git repository (no dubious ownership prompts).
if command -v sddm >/dev/null 2>&1; then
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
else
  warn "SDDM is not installed, skipping theme update."
fi

# ── 5. reapply theme & reload ─────────────────────────────────────────────────
if [ -f "$HOME/.cache/quickshell/colorscheme.json" ]; then
  log "Reapplying theme..."
  python3 "$HOME/.config/quickshell/Scripts/theme/apply_theme.py" ||
    warn "Theme could not be reapplied; it will be generated on next login."
else
  warn "No cached colorscheme found; the theme will be applied on next login."
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
