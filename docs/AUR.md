# AUR packaging

Minflair is published as two AUR packages:

| Package | Source | Use it when |
| --- | --- | --- |
| `minflair` | release tag `vX.Y.Z` | you want stable releases |
| `minflair-git` | `main` branch | you want the latest commits |

The two packages conflict with each other. Both install the repository in
`/usr/share/minflair` and add the `minflair` command.

## Install from the AUR

```bash
yay -S minflair
# or: paru -S minflair
# or, for the development branch:
yay -S minflair-git
```

The package only installs the files. Deploy the configuration to your home
directory with:

```bash
minflair install
```

The interactive selector opens by default. The same flags as the git
installation are available:

```bash
minflair install --exclude kitty,nvim
minflair install --only quickshell,hyprland,kitty,zsh
minflair install --dry-run
minflair update --no-input
```

Run these commands as your normal user. `install.sh` and `update.sh` refuse to
run as root and ask for `sudo` only when they need it.

## Update

```bash
yay -Syu                 # update the package files
minflair update          # copy the new configuration into ~/.config and ~/
```

`minflair update` respects `~/.config/minflair/preferences.conf`. Components
that were disabled are not copied, installed, themed or reloaded, and their
existing files are not deleted.

## Commands

| Command | Action |
| --- | --- |
| `minflair install [options]` | Deploy Minflair to the current user |
| `minflair update [options]` | Update an existing installation |
| `minflair components list` | Show every component and its status |
| `minflair components disable ID` | Disable a component |
| `minflair components enable ID` | Re-enable a component |
| `minflair components validate` | Check the manifest and preferences |
| `minflair version` | Print the installed version |

`minflair components` is a thin wrapper around
`config/quickshell/Scripts/minflair_components.py`. It uses the manifest
shipped in `/usr/share/minflair`.

## Package layout

```text
/usr/bin/minflair                 command wrapper
/usr/share/minflair/config/       Quickshell, Hyprland and application configs
/usr/share/minflair/home/         files copied to the home directory
/usr/share/minflair/etc/          SDDM configuration
/usr/share/minflair/lib/          shared installer helpers
/usr/share/minflair/install.sh    installer
/usr/share/minflair/update.sh     updater
/usr/share/minflair/packages*.txt package lists filtered by component
/usr/share/minflair/docs/         component, install and packaging docs
```

The package does not copy anything into `$HOME` during installation. That is
deliberate: pacman must not write user configuration, and the component
selector needs to run as the user who owns the files.

## Maintainer workflow

The PKGBUILDs live in this repository under `packaging/aur/`:

```text
packaging/
├── minflair                      # /usr/bin/minflair wrapper
└── aur/
    ├── minflair/
    │   ├── PKGBUILD
    │   ├── .SRCINFO
    │   └── minflair.install
    ├── minflair-git/
    │   ├── PKGBUILD
    │   ├── .SRCINFO
    │   └── minflair-git.install
    ├── update-checksum.sh
    └── update-srcinfo.sh
```

### Release a stable version

1. Update `config/quickshell/Core/Constants.qml` and `CHANGELOG.md`.
2. Commit and push the release commit.
3. Create and push the tag:

   ```bash
   git tag -a v2.2.0 -m "Minflair 2.2.0"
   git push origin v2.2.0
   ```

4. Refresh the stable package metadata from the published tarball:

   ```bash
   packaging/aur/update-checksum.sh 2.2.0
   ```

   The script downloads the GitHub tag archive, replaces `pkgver` and the
   `SKIP` checksum in `packaging/aur/minflair/PKGBUILD`, and regenerates both
   `.SRCINFO` files. It never rewrites git history.

5. Commit the packaging update and push it to the AUR:

   ```bash
   git clone ssh://aur@aur.archlinux.org/minflair.git /tmp/aur-minflair
   cp packaging/aur/minflair/{PKGBUILD,.SRCINFO,minflair.install} /tmp/aur-minflair/
   cd /tmp/aur-minflair
   git add PKGBUILD .SRCINFO minflair.install
   git commit -m "upgpkg: minflair 2.2.0-1"
   git push
   ```

   Repeat with `minflair-git` for the development package. The git package
   does not need a checksum update; only its `pkgver()` changes.

### Refresh `.SRCINFO` only

```bash
packaging/aur/update-srcinfo.sh
```

This runs `makepkg --printsrcinfo` in both package directories. Run it as a
normal user; `makepkg` refuses to run as root. CI compares the committed
`.SRCINFO` files with a fresh generation so the AUR metadata cannot drift.

### Dependencies

Core packages (`quickshell`, `hyprland`, `hypridle`, `hyprpicker`,
`hyprsunset`, `xdg-desktop-portal-hyprland`, `awww`) are hard dependencies.
Optional application packages are listed in `optdepends` for discoverability.
The installer still installs only the packages belonging to enabled
components, so an optional package is not pulled in unless the user selects
that component or installs it explicitly.
