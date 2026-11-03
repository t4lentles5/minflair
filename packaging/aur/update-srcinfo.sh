#!/usr/bin/env bash
# Refresh the .SRCINFO files from the PKGBUILDs.
#
# Run this as a normal user from an Arch system with base-devel installed.
# The release workflow and docs/AUR.md use the same command.

set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'Run this script as a normal user; makepkg refuses to run as root.\n' >&2
  exit 1
fi

if ! command -v makepkg >/dev/null 2>&1; then
  printf 'makepkg is required (install base-devel).\n' >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for package in minflair minflair-git; do
  (
    cd "$ROOT/$package"
    makepkg --printsrcinfo >.SRCINFO
  )
  printf 'Updated %s/.SRCINFO\n' "$package"
done
