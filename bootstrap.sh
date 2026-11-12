#!/usr/bin/env bash
#
# Minflair bootstrap installer.
#
# Installs the build tools, clones Minflair, builds the `minflair` CLI into
# ~/.local/bin and starts `minflair install`. It is safe to run again: an
# existing clone is updated with `git pull --ff-only`.
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/t4lentles5/minflair/main/bootstrap.sh)"
#   bash bootstrap.sh --exclude kitty,nvim
#
# Environment:
#   MINFLAIR_DIR       Clone directory           (default: ~/.minflair)
#   MINFLAIR_BIN_DIR   CLI destination           (default: ~/.local/bin)
#   MINFLAIR_REPO_URL  Git remote                (default: GitHub)
#   MINFLAIR_REF       Branch or tag to install  (default: main)

set -euo pipefail

REPO_URL="${MINFLAIR_REPO_URL:-https://github.com/t4lentles5/minflair.git}"
REF="${MINFLAIR_REF:-main}"
REPO_DIR="${MINFLAIR_DIR:-$HOME/.minflair}"
BIN_DIR="${MINFLAIR_BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/minflair"

info() { printf '[bootstrap] %s\n' "$*"; }
warn() { printf '[bootstrap] warning: %s\n' "$*" >&2; }
die() {
  printf '[bootstrap] error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: bash bootstrap.sh [minflair install options]

Clones Minflair into ~/.minflair, builds the CLI into ~/.local/bin and runs
`minflair install` with the remaining arguments.

Environment:
  MINFLAIR_DIR       Clone directory           (default: ~/.minflair)
  MINFLAIR_BIN_DIR   CLI destination           (default: ~/.local/bin)
  MINFLAIR_REPO_URL  Git remote                (default: GitHub)
  MINFLAIR_REF       Branch or tag to install  (default: main)

Examples:
  bash bootstrap.sh --exclude kitty,nvim
  MINFLAIR_REF=v2.3.0 bash bootstrap.sh
EOF
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
esac

[ "$(id -u)" -eq 0 ] && die "run the bootstrap as your normal user, not as root"
command -v pacman >/dev/null 2>&1 ||
  die "Minflair only supports Arch Linux and Arch-based distributions (pacman not found)"

# Prefer a rustup toolchain when it is installed but not in PATH.
if [ -d "$HOME/.cargo/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *) PATH="$HOME/.cargo/bin:$PATH" ;;
  esac
fi

missing=()
command -v git >/dev/null 2>&1 || missing+=(git)
{ command -v cc >/dev/null 2>&1 && command -v make >/dev/null 2>&1; } ||
  missing+=(base-devel)
if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
  if command -v rustup >/dev/null 2>&1; then
    info "Installing the stable Rust toolchain with rustup..."
    rustup toolchain install stable --profile minimal
  elif pacman -Q rustup >/dev/null 2>&1; then
    die "rustup is installed but not in PATH; add its bin directory to PATH and retry"
  else
    missing+=(rust)
  fi
fi

if ((${#missing[@]})); then
  info "Installing build dependencies: ${missing[*]}"
  sudo -v || die "sudo authentication failed"
  sudo pacman -S --needed --noconfirm "${missing[@]}" ||
    die "could not install the build dependencies"
fi

# rustup may have created ~/.cargo/bin after the first PATH check.
if [ -d "$HOME/.cargo/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *) PATH="$HOME/.cargo/bin:$PATH" ;;
  esac
fi

command -v cargo >/dev/null 2>&1 || die "cargo is still not available in PATH"

# ── repository ───────────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  if git -C "$REPO_DIR" symbolic-ref -q HEAD >/dev/null 2>&1; then
    info "Updating the existing clone at $REPO_DIR..."
    git -C "$REPO_DIR" pull --ff-only ||
      die "could not update $REPO_DIR; commit or stash your local changes and retry"
  else
    info "Checking out $REF in the existing clone at $REPO_DIR..."
    git -C "$REPO_DIR" fetch --depth 1 origin "$REF" &&
      git -C "$REPO_DIR" checkout -q "$REF" ||
      die "could not check out $REF in $REPO_DIR"
  fi
elif [ -e "$REPO_DIR" ]; then
  die "$REPO_DIR exists but is not a git checkout; move it away and retry"
else
  info "Cloning Minflair ($REF) into $REPO_DIR..."
  git clone --depth 1 --branch "$REF" --single-branch "$REPO_URL" "$REPO_DIR" ||
    die "could not clone $REPO_URL"
fi

[ -f "$REPO_DIR/config/quickshell/components.tsv" ] ||
  die "$REPO_DIR does not look like the Minflair repository"

# Store an absolute path in the marker, even when MINFLAIR_DIR is relative.
REPO_DIR="$(cd "$REPO_DIR" && pwd)"

# ── build and install the CLI ────────────────────────────────────────────────
info "Building the minflair CLI (the first build downloads the Rust dependencies)..."
(cd "$REPO_DIR" && cargo build --release --locked) ||
  die "could not build the minflair CLI"

target_dir="${CARGO_TARGET_DIR:-$REPO_DIR/target}"
if [[ "$target_dir" != /* ]]; then
  target_dir="$REPO_DIR/$target_dir"
fi
built="$target_dir/release/minflair"
[ -x "$built" ] || die "the build finished but $built is missing"

info "Installing the CLI in $BIN_DIR/minflair..."
mkdir -p "$BIN_DIR"
install -Dm755 "$built" "$BIN_DIR/minflair" ||
  die "could not install the minflair CLI in $BIN_DIR"

# Remember the repository so the CLI finds it from any directory.
mkdir -p "$CONFIG_DIR"
printf '%s\n' "$REPO_DIR" >"$CONFIG_DIR/repo"

path_had_bin=0
case ":$PATH:" in
  *":$BIN_DIR:"*) path_had_bin=1 ;;
  *) export PATH="$BIN_DIR:$PATH" ;;
esac

if ((path_had_bin == 0)); then
  info "$BIN_DIR is not in PATH for this session; Minflair's zsh configuration will add it after installation."
fi

# ── run the installer ────────────────────────────────────────────────────────
info "Starting the Minflair installer..."
if [ -t 0 ]; then
  exec "$BIN_DIR/minflair" install "$@"
elif [ -r /dev/tty ]; then
  exec "$BIN_DIR/minflair" install "$@" </dev/tty
else
  warn "no terminal attached; using the saved component preferences"
  exec "$BIN_DIR/minflair" install --no-input "$@"
fi
