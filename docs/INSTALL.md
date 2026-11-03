# Install, update and partial adoption

Minflair installs a set of components. Each component groups configuration
files, packages, theme appliers and reload commands. You can keep your own
configuration for some applications while using the rest of Minflair.

The component list lives in `config/quickshell/components.tsv`. See
[COMPONENTS.md](COMPONENTS.md) for the manifest format and the runtime gating
rules.

## Requirements

- Arch Linux or an Arch-based distribution.
- A normal user account. `install.sh` and `update.sh` refuse to run as root.
- `git`, `base-devel` and `pacman`. The installer bootstraps `yay` when it is
  missing.
- An interactive terminal for the selector. Automation and non-interactive
  usage are documented in [ADVANCED.md](ADVANCED.md).

## First install

### From the AUR

```bash
yay -S minflair          # stable release
# or: yay -S minflair-git
minflair install
```

The package installs the repository in `/usr/share/minflair` and adds the
`minflair` command. See [AUR.md](AUR.md) for package details and the maintainer
workflow.

### From git

```bash
git clone https://github.com/t4lentles5/minflair.git
cd minflair
./install.sh
```

With no options and an interactive terminal, the component selector opens
before anything is changed. This is the recommended way to install Minflair.

### Selector controls

| Key | Action |
| --- | --- |
| `Up` / `k` | Move up |
| `Down` / `j` | Move down |
| `Space` | Enable or disable the highlighted component |
| `a` | Enable every optional component |
| `Enter` | Confirm the selection |
| `q` | Cancel without changing anything |

Core components (`quickshell` and `hyprland`) are always enabled and cannot be
toggled. The selection is saved to `~/.config/minflair/preferences.conf`.

## Change the selection later

The selector is the recommended way to change components:

```bash
./install.sh --select
# AUR: minflair install --select
```

To disable or re-enable a specific component without opening the selector:

```bash
# Keep everything except Kitty and Neovim
./install.sh --exclude kitty,nvim

# Re-enable Kitty
./install.sh --include kitty
```

`--exclude` and `--include` persist the choice. For `--only`, `--dry-run`,
`--no-input`, `--no-packages` and the complete flag reference, see
[ADVANCED.md](ADVANCED.md).

## Preferences

`~/.config/minflair/preferences.conf` is a flat text file:

```text
# Minflair preferences v1
# One disabled component id per line.

kitty
nvim
starship
```

A component that is not listed is enabled. Deleting the file restores the
default: every component is installed. Unknown ids are ignored at runtime and
reported as warnings by the installer.

The file is plain text on purpose. It can be read on a fresh Arch installation
before Python is installed, and it is easy to edit by hand.

## What a disabled component means

A disabled component is not:

- copied by `install.sh` or `update.sh`;
- installed or updated as a package;
- themed by `apply_theme.py`;
- updated by `apply_font.py`;
- changed by `apply_cursor.py`;
- reloaded or signalled after an update.

Disabling a component does **not** delete files that are already installed. It
only prevents Minflair from touching them again. This makes exclusions safe:
you can try a component, disable it, and your previous files stay where they
are.

## Updating

From the AUR:

```bash
yay -Syu
minflair update
```

From a git clone:

```bash
cd minflair
git pull --ff-only
./update.sh
```

`update.sh` reads the saved preferences and only copies, installs, themes and
reloads enabled components. It never reintroduces a component that was
excluded.

To change the selection during an update:

```bash
./update.sh --select
./update.sh --exclude nvim
./update.sh --include kitty
```

For a dry run or automation, see [ADVANCED.md](ADVANCED.md).

### Restoring a backup

The updater writes backups to `~/.dotfiles_backup/<timestamp>/`. To restore
the files it replaced:

```bash
cp -a ~/.dotfiles_backup/<timestamp>/config/. ~/.config/
cp -a ~/.dotfiles_backup/<timestamp>/home/. ~/
```

To preview the SDDM theme without logging out:

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/minflair-sddm
```

## Compatibility with an existing setup

- Files that conflict with an enabled component are backed up to
  `~/.dotfiles_backup/<timestamp>/` before being replaced.
- Files that belong to disabled components are never read, copied or backed
  up by Minflair.
- Backups are written under `~/.dotfiles_backup/<timestamp>/`.
- `update.sh` preserves `~/.config/zsh/zhistory` when the `zsh` component is
  enabled.

## Troubleshooting

**The selector does not appear.** It needs an interactive terminal. Run
`./install.sh --select` from a terminal. If the terminal is not interactive,
use `--exclude`/`--include` or see [ADVANCED.md](ADVANCED.md).

**A component I disabled is still themed.** Check that the preference file
contains the component id and re-run `./update.sh`. Files already written by an
older version are not deleted, but they are not updated again.

**A package I disabled was still installed.** It may be a dependency of an
enabled component. Minflair only removes packages from its own explicit lists;
`pacman` still resolves dependencies.

**I want everything back.** Remove `~/.config/minflair/preferences.conf` and run
`./update.sh`.
