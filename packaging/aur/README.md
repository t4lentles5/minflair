# AUR packaging

> [!IMPORTANT]
> These packages are not published on the AUR yet: AUR registrations are
> currently closed. Until they open, users can build them from this directory
> with `makepkg -si` (the PKGBUILDs download the release assets). Publish them
> with the checklist below once registration is available again.

This directory contains the AUR packaging for Minflair:

- `minflair/` — builds the CLI from `minflair-<version>-src.tar.gz`.
- `minflair-bin/` — installs `minflair-<version>-<arch>.tar.gz` and
  `minflair-<version>-runtime.tar.gz`.
- `minflair-git/` — builds from `main`.

The release workflow (`.github/workflows/release.yml`) uploads these assets to
the GitHub release:

```
minflair-<version>-x86_64.tar.gz
minflair-<version>-aarch64.tar.gz   # optional
minflair-<version>-runtime.tar.gz
minflair-<version>-src.tar.gz
SHA256SUMS
```

The source and runtime tarballs are deterministic: the workflow sorts entries,
normalizes ownership and mtime and uses `gzip -n`. That is why the checksums
can be committed before the first release is published.

## Release checklist

1. Bump `cli/Cargo.toml`, `Cargo.lock` and
   `config/quickshell/Core/Constants.qml` to the same version.
2. Commit and tag the release (`vX.Y.Z`).
3. Run the **Release** workflow (or push the tag). Wait for it to finish.
4. Download `SHA256SUMS` from the release and fill the PKGBUILDs:

   ```bash
   ./update-checksums.sh /path/to/SHA256SUMS X.Y.Z
   ```

5. Test each package in a clean chroot:

   ```bash
   cd minflair && makepkg -si
   cd ../minflair-bin && makepkg -si
   cd ../minflair-git && makepkg -si
   ```

   `namcap PKGBUILD` and `namcap *.pkg.tar.zst` should report no errors.

6. Regenerate `.SRCINFO` after every PKGBUILD change:

   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

7. Push each package to its AUR repository:

   ```bash
   git clone ssh://aur@aur.archlinux.org/minflair.git
   # copy PKGBUILD, .SRCINFO and .install
   git add PKGBUILD .SRCINFO minflair.install
   git commit -m "upgpkg: minflair X.Y.Z-1"
   git push
   ```

## Notes

- The package installs the runtime tree in `/usr/share/minflair`, which the CLI
  already searches by default (`cli/src/repo.rs`).
- `minflair` and `minflair-git` build with `cargo build --release --locked` and
  run the Rust test suite in `check()`.
- `minflair-bin` does not need Rust at build time.
- Do not add the full desktop stack (`quickshell`, `hyprland`, ...) as hard
  dependencies: the installer resolves them through `packages.txt` and
  `packages-aur.txt` and respects the component selection.
- Do not run `minflair install` from `post_install()`: it needs a terminal and
  the user's component choices.
