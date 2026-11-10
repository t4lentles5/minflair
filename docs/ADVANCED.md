# Advanced installation and automation

This guide covers non-interactive flags, dry runs and automation. For a normal
installation, use the selector described in [INSTALL.md](INSTALL.md).

`minflair` is the canonical command. `./install.sh` and `./update.sh` remain
compatibility entrypoints with the same selector, preferences and flags:
`./install.sh <flags>` is equivalent to `minflair install <flags>`, and
`./update.sh <flags>` is equivalent to `minflair update <flags>`.

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
| `--pull` | Update only: run `git pull --ff-only` before updating (requires a git checkout). |
| `--no-pull` | Update only: do not pull the source. This is the default; conflicts with `--pull`. |
| `--no-build` | Update only: do not rebuild the CLI after `--pull`. |
| `--help` | Show the built-in help. |

`--no-build` only applies when `--pull` is also given. `--pull` and
`--no-pull` are mutually exclusive; `--no-pull` is the default.

### install vs update

| | `minflair install` | `minflair update` |
| --- | --- | --- |
| Purpose | First deployment or full reapply | Refresh an existing installation |
| Interactive selector | Opens by default | Only with `--select` |
| Selection flags | Persist to preferences | Persist to preferences |
| `--pull` / `--no-build` | Not available | Available |
| Requires an existing install | No | Yes (`~/.config/quickshell`) |

Both commands apply the saved preferences. By default, `install` opens the
selector and `update` does not; use `--select` to review the selection in
either command.

Lists are comma-separated. Flags can be combined and repeated:

```bash
minflair install --exclude kitty --exclude nvim --no-input
minflair install --exclude=kitty,nvim --dry-run
```

`--exclude` and `--only` persist the selection. `--include` removes ids from
the disabled list. If both `--only` and `--exclude` are given, `--exclude` is
applied last and wins.

Selection flags make the run non-interactive. Add `--select` if you want to
review the resulting selection in the selector before continuing.

## Examples

```bash
# Disable a few applications and keep everything else
minflair install --exclude kitty,nvim,starship

# Install only the core shell plus Kitty and Zsh
minflair install --only quickshell,hyprland,kitty,zsh

# Re-enable components that were disabled before
minflair install --include kitty

# Use the saved preferences, never prompt
minflair install --no-input

# Show the full plan without changing the system
minflair install --dry-run

# Install configuration only; do not touch packages
minflair install --no-packages

# Use paru for the AUR and save the choice
minflair install --aur-helper paru
```

## Dry run

`--dry-run` writes preferences to a temporary file, prints every copy, backup,
package and reload action, and exits without changing the system. It is the
recommended way to check a selection before applying it:

```bash
minflair install --dry-run --only quickshell,hyprland,kitty,zsh
minflair update --dry-run --exclude nvim
```

It is also useful when reporting an installation problem:

```bash
minflair install --dry-run --no-input --no-packages
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

## Managing components

`minflair components` edits the saved selection without running the installer.
It only writes `~/.config/minflair/preferences.conf`; it never copies, installs
or deletes files.

```bash
minflair components list                 # status, id, label
minflair components list --enabled       # only enabled components
minflair components list --disabled      # only disabled components
minflair components list --json          # machine-readable report
minflair components enable kitty         # save the preference
minflair components disable kitty,nvim   # save the preference
minflair components edit                 # interactive selector
minflair components reset                # enable every optional component
```

`enable` and `disable` are additive: they change only the ids you pass.
`reset` clears the disabled list. Core components (`quickshell` and
`hyprland`) cannot be disabled, and unknown ids are rejected.

To save the selection and apply it in one step, add `--apply`:

```bash
minflair components enable kitty --apply
minflair components disable obsidian --apply
minflair components edit --apply
```

`--apply` runs `minflair update --no-input` after saving, so it requires an
existing installation (`~/.config/quickshell`). Without `--apply`, run
`minflair update` yourself when you want to deploy the new selection.

Disabling a component keeps files that are already installed; it only stops
Minflair from touching them again. Enabling a component does not deploy it
until the next `install` or `update`.

## Automation recipes

```bash
# Fresh install with the saved preferences, no prompts
minflair install --no-input

# Update without touching packages or asking questions
minflair update --no-input --no-packages

# Preview an update in CI or a support session
minflair update --dry-run --no-input

# Disable a component for an unattended install
minflair install --exclude obsidian --no-input
```

## Bootstrap environment variables

`bootstrap.sh` installs the build tools, clones the repository and installs the
CLI before running `minflair install`. These variables override its defaults:

| Variable | Effect |
| --- | --- |
| `MINFLAIR_DIR` | Clone directory. Default: `~/.minflair`. |
| `MINFLAIR_BIN_DIR` | CLI destination. Default: `~/.local/bin`. |
| `MINFLAIR_REPO_URL` | Git remote. Default: the GitHub repository. |
| `MINFLAIR_REF` | Branch or tag to install. Default: `main`. |

```bash
# Pin a release and install the CLI in a custom directory
MINFLAIR_REF=v2.2.0 MINFLAIR_BIN_DIR="$HOME/bin" bash bootstrap.sh
```

The script keeps the terminal attached so the selector works. Without a
terminal it falls back to `--no-input` and the saved preferences.

## Editing preferences directly

`minflair components` is the supported way to change the selection. If the CLI
is not installed, the Python helper reads and writes the same file:

```bash
python config/quickshell/Scripts/minflair_components.py list
python config/quickshell/Scripts/minflair_components.py disable obsidian
python config/quickshell/Scripts/minflair_components.py enable obsidian
python config/quickshell/Scripts/minflair_components.py validate
```

See [COMPONENTS.md](COMPONENTS.md) for the manifest and the exact file format.

## Flag troubleshooting

**A flag is not recognized.** Run `minflair install --help` or
`minflair update --help` and check the spelling. Unknown options stop the
command before any change is made.

**`--select` does nothing.** It needs an interactive terminal. Without one, the
saved preferences are used.

**`--no-input` installed something I did not expect.** Check
`~/.config/minflair/preferences.conf` and run
`minflair install --dry-run --no-input` to see the resulting plan.
