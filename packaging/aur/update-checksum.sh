#!/usr/bin/env bash
# Point the stable AUR package at a published release tag and checksum it.
#
# Usage: packaging/aur/update-checksum.sh 2.2.0
#
# The tag v2.2.0 must already exist on GitHub, because the checksum is taken
# from the generated release tarball. This script never rewrites git history.

set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
  printf 'curl is required to download the release tarball.\n' >&2
  exit 1
fi

VERSION="${1:-}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Usage: %s VERSION (for example 2.2.0)\n' "$0" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGBUILD="$ROOT/minflair/PKGBUILD"
URL="https://github.com/t4lentles5/minflair/archive/refs/tags/v${VERSION}.tar.gz"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

printf 'Downloading %s\n' "$URL"
curl -fL --retry 3 --connect-timeout 15 "$URL" -o "$TMP"

CHECKSUM="$(sha256sum "$TMP" | awk '{print $1}')"

sed -i "s/^pkgver=.*/pkgver=${VERSION}/" "$PKGBUILD"
sed -i "s/^sha256sums=.*/sha256sums=('${CHECKSUM}')/" "$PKGBUILD"

printf 'Updated %s\n' "$PKGBUILD"
printf '  pkgver     = %s\n' "$VERSION"
printf '  sha256sums = %s\n' "$CHECKSUM"

"$ROOT/update-srcinfo.sh"
