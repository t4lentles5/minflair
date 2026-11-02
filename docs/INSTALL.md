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
- An interactive terminal for the selector. Non-interactive runs use the saved
  preferences and are fully supported with `--no-input`.

## First install

```bash
git clone https://github.com/t4lentles5/minflair.git
cd minflair
./install.sh
```

With no options and an interactive terminal, the component selector opens
before anything is changed.

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

## Non-interactive installs

```bash
# Disable a few applications and keep everything else
./install.sh --exclude kitty,nvim,starship

# Install only the core shell plus Kitty and Zsh
./install.sh --only quickshell,hyprland,kitty,zsh

# Re-enable components that were disabled before
./install.sh --include kitty

# Use the saved preferences, never prompt
./install.sh --no-input

# Show the full plan without changing the system
./install.sh --dry-run

# Install configuration only; do not touch packages
./install.sh --no-packages
```

Flags can be combined and repeated:

```bash
./install.sh --exclude kitty --exclude nvim --no-input
./install.sh --exclude=kitty,nvim --dry-run
```

`--exclude` and `--only` persist the selection. `--include` removes ids from
the disabled list. If both `--only` and `--exclude` are given, `--exclude` is
applied last and wins.

Selection flags make the run non-interactive. Add `--select` if you want to
review the resulting selection in the selector before continuing.

### Flag reference

| Flag | Effect |
| --- | --- |
| `--exclude IDS` | Disable the listed components and save the preference. |
| `--only IDS` | Enable only the listed optional components (core is always on). |
| `--include IDS` | Re-enable the listed components. |
| `--select` | Open the interactive selector. |
| `--no-input` | Never prompt; use the saved preferences. |
| `--dry-run` | Print every action without writing files or running package changes. |
| `--no-packages` | Skip `pacman`/`yay`; useful for configuration-only installs. |
| `--help` | Show the built-in help. |

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
./update.sh --dry-run
```

## Dry run

`--dry-run` writes preferences to a temporary file, prints every copy, backup,
package and reload action, and exits without changing the system. It is the
recommended way to check a selection before applying it:

```bash
./install.sh --dry-run --only quickshell,hyprland,kitty,zsh
./update.sh --dry-run --exclude nvim
```

## Configuration only

`--no-packages` skips all package operations. This is useful when the packages
are already installed or managed by another tool.

If the `chsh` component is enabled and `zsh` is missing, the installer prints a
warning and skips the login shell change instead of failing. The same applies
to a missing `yay`: AUR packages are skipped with a warning.

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
`./install.sh --select` from a terminal, or pass `--exclude`/`--only`.

**A component I disabled is still themed.** Check that the preference file
contains the component id and re-run `./update.sh`. Files already written by an
older version are not deleted, but they are not updated again.

**A package I disabled was still installed.** It may be a dependency of an
enabled component. Minflair only removes packages from its own explicit lists;
`pacman` still resolves dependencies.

**I want everything back.** Remove `~/.config/minflair/preferences.conf` and run
`./update.sh`.
