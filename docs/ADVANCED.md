# Advanced installation and automation

This guide covers non-interactive flags, dry runs and automation. For a normal
installation, use the selector described in [INSTALL.md](INSTALL.md).

## Flag reference

| Flag | Effect |
| --- | --- |
| `--exclude IDS` | Disable the listed components and save the preference. |
| `--only IDS` | Enable only the listed optional components (core is always on). |
| `--include IDS` | Re-enable the listed components. |
| `--select` | Open the interactive selector. |
| `--no-input` | Never prompt; use the saved preferences. |
| `--aur-helper NAME` | Use `yay` or `paru` as the AUR helper and save the choice. |
| `--dry-run` | Print every action without writing files or running package changes. |
| `--no-packages` | Skip `pacman` and the AUR helper; useful for configuration-only installs. |
| `--help` | Show the built-in help. |

Lists are comma-separated. Flags can be combined and repeated:

```bash
./install.sh --exclude kitty --exclude nvim --no-input
./install.sh --exclude=kitty,nvim --dry-run
```

`--exclude` and `--only` persist the selection. `--include` removes ids from
the disabled list. If both `--only` and `--exclude` are given, `--exclude` is
applied last and wins.

Selection flags make the run non-interactive. Add `--select` if you want to
review the resulting selection in the selector before continuing.

## Examples

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

# Use paru for the AUR and save the choice
./install.sh --aur-helper paru
```

## Dry run

`--dry-run` writes preferences to a temporary file, prints every copy, backup,
package and reload action, and exits without changing the system. It is the
recommended way to check a selection before applying it:

```bash
./install.sh --dry-run --only quickshell,hyprland,kitty,zsh
./update.sh --dry-run --exclude nvim
```

It is also useful when reporting an installation problem:

```bash
./install.sh --dry-run --no-input --no-packages
```

The output shows which components would be copied, which packages would be
installed and which reload commands would run.

## Configuration only

`--no-packages` skips all package operations. This is useful when the packages
are already installed or managed by another tool.

The `zsh` component also sets zsh as the login shell. If zsh is missing (for
example when using `--no-packages`), the installer prints a warning and skips
the login shell change instead of failing. The same applies to a missing
`yay`: AUR packages are skipped with a warning.

## Automation recipes

```bash
# Fresh install with the saved preferences, no prompts
./install.sh --no-input

# Update without touching packages or asking questions
./update.sh --no-input --no-packages

# Preview an update in CI or a support session
./update.sh --dry-run --no-input

# Disable a component for an unattended install
./install.sh --exclude obsidian --no-input
```

## Editing preferences directly

The component helper reads and writes the same preferences file:

```bash
python config/quickshell/Scripts/minflair_components.py list
python config/quickshell/Scripts/minflair_components.py disable obsidian
python config/quickshell/Scripts/minflair_components.py enable obsidian
python config/quickshell/Scripts/minflair_components.py validate
```

See [COMPONENTS.md](COMPONENTS.md) for the manifest and the exact file format.

## Flag troubleshooting

**A flag is not recognized.** Run `./install.sh --help` or
`./update.sh --help` and check the spelling. Unknown options stop the script
before any change is made.

**`--select` does nothing.** It needs an interactive terminal. Without one, the
saved preferences are used.

**`--no-input` installed something I did not expect.** Check
`~/.config/minflair/preferences.conf` and run
`./install.sh --dry-run --no-input` to see the resulting plan.
