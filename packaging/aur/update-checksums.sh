#!/usr/bin/env bash
#
# Fill the PKGBUILD checksums from a release SHA256SUMS file.
#
# Usage: ./update-checksums.sh SHA256SUMS VERSION
# Example: ./update-checksums.sh ~/Downloads/SHA256SUMS 2.3.0

set -euo pipefail

sums="${1:?usage: $0 SHA256SUMS VERSION}"
version="${2:?usage: $0 SHA256SUMS VERSION}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -f "$sums" ] || {
  echo "error: $sums not found" >&2
  exit 1
}

checksum() {
  local file="$1"
  awk -v file="$file" '$2 == file { print $1; exit }' "$sums"
}

src="$(checksum "minflair-$version-src.tar.gz")"
runtime="$(checksum "minflair-$version-runtime.tar.gz")"
x86_64="$(checksum "minflair-$version-x86_64.tar.gz")"
aarch64="$(checksum "minflair-$version-aarch64.tar.gz")"

[ -n "$src" ] || { echo "error: missing minflair-$version-src.tar.gz" >&2; exit 1; }
[ -n "$runtime" ] || { echo "error: missing minflair-$version-runtime.tar.gz" >&2; exit 1; }
[ -n "$x86_64" ] || { echo "error: missing minflair-$version-x86_64.tar.gz" >&2; exit 1; }

set_value() {
  local file="$1" key="$2" value="$3"
  sed -i "s|^${key}=.*|${key}=('${value}')|" "$file"
}

set_scalar() {
  local file="$1" key="$2" value="$3"
  sed -i "s|^${key}=.*|${key}=${value}|" "$file"
}

set_scalar "$root/minflair/PKGBUILD" pkgver "$version"
set_value "$root/minflair/PKGBUILD" sha256sums "$src"

set_scalar "$root/minflair-bin/PKGBUILD" pkgver "$version"
set_value "$root/minflair-bin/PKGBUILD" sha256sums "$runtime"
set_value "$root/minflair-bin/PKGBUILD" sha256sums_x86_64 "$x86_64"

if [ -n "$aarch64" ]; then
  set_value "$root/minflair-bin/PKGBUILD" sha256sums_aarch64 "$aarch64"
else
  echo "warning: no aarch64 binary in SHA256SUMS; leaving it as SKIP" >&2
fi

for package in minflair minflair-bin minflair-git; do
  (cd "$root/$package" && makepkg --printsrcinfo > .SRCINFO)
done

echo "Updated checksums for $version:"
echo "  minflair:     $src"
echo "  runtime:      $runtime"
echo "  x86_64:       $x86_64"
[ -n "$aarch64" ] && echo "  aarch64:      $aarch64"
echo "Regenerated .SRCINFO files."
